**Date:** 2026-04-05
**Author:** mfalagan
**Journal:** J3

# Boot File Service Setup

This document describes how to set up a network-accessible USB mass-storage emulator on a Raspberry Pi Zero 2w running Raspberry Pi OS Lite. The system exposes a FAT32-backed disk image through two interfaces:
1. an `rsync` endpoint for network-based file transfer
2. a USB mass-storage device for direct attachment

This guide assumes:
- a Raspberry Pi Zero 2w
- Raspberry Pi OS Lite
- network connectivity
- SSH access to a privileged user

In the examples below, the board is reachable as `petdrive.mockernel.local` and the administrative user is `admin`. Replace these values as needed.

The relevant filesystem layout is:
```text
/petdrive/
├── drive/               # mounted FAT32 filesystem used by rsync
├── drive.img            # backing disk image
├── handler/             # queued rsync handler and helper hooks
└── publisher/           # USB mass-storage publisher control script
```

The relevant service names are:
- `petdrive-handler.service`
- `petdrive-publisher.service`

## 0. Project Domain Emulation

This step is not specific to the boot file service itself, but it is useful for the project’s naming scheme.

mDNS is designed primarily for single-label `.local` names such as `hostname.local`. In practice, Avahi can be configured to advertise a different domain so that a host such as `petdrive.local` becomes reachable as `petdrive.mockernel.local`, emulating a project domain.

SSH into the Pi using its current hostname:

```bash
ssh admin@petdrive.local
```

Edit the Avahi daemon configuration:

```bash
sudoedit /etc/avahi/avahi-daemon.conf
```

Locate the `domain-name` entry, uncomment it, and set:

```ini
domain-name=mockernel.local
```

Restart Avahi:

```bash
sudo systemctl restart avahi-daemon
```

Reconnect to the Pi through the new domain:

```bash
ssh admin@petdrive.mockernel.local
```
> SSH should succeed using `petdrive.mockernel.local`.

## 1. Base System Setup

### 1.1. Set Up the Project Infrastructure

Update the system and install the required utilities:

```bash
sudo apt update
sudo apt full-upgrade -y
sudo apt install -y rsync dosfstools util-linux python3
sudo apt autoremove -y
```

Create the directory hierarchy:

```bash
sudo mkdir -p /petdrive/drive

sudo chown -R root:root /petdrive
sudo chmod 0755 /petdrive
```

Create a 2 GiB sparse image file and format it as FAT32:

```bash
sudo truncate -s 2G /petdrive/drive.img
sudo mkfs.vfat -F 32 -n "PETDRIVE" /petdrive/drive.img
```
> A 2 GiB image is sufficient for the examples in this guide. Adjust the size if the use case requires more capacity.

### 1.2. Loop-Mount the Image

Edit the file systems table:

```bash
sudoedit /etc/fstab
```

Append the line:

```ini
/petdrive/drive.img  /petdrive/drive  vfat  loop,uid=root,gid=root,umask=022,nofail  0  0
```
> This mounts the image through a loop device at boot and presents it as a writable FAT32 filesystem owned by root.

Reboot:

```bash
sudo reboot
```

### 1.3. Verify the Mount

Reconnect over SSH and verify the mounted filesystem:

```bash
mount | grep '/petdrive/drive'
df -h /petdrive/drive
findmnt /petdrive/drive
```

The following should hold:
- `mount | grep '/petdrive/drive'` prints a line showing `/petdrive/drive.img` mounted on `/petdrive/drive`
- `df -h /petdrive/drive` reports a 2.0 GiB `vfat` filesystem
- `findmnt /petdrive/drive` reports a source of the form `/dev/loop<N>` with filesystem type `vfat`

## 2. rsync Daemon Setup

This section establishes a direct `rsync` daemon serving `/petdrive/drive/`. This initial daemon is later replaced by the queued handler, but it is useful as a baseline to validate the mounted image and the network file-transfer path.

---

### 2.1. Configure the rsync Daemon

Create the daemon configuration:

```bash
sudoedit /etc/rsyncd.conf
```

Write:

```ini
uid = root
gid = root
use chroot = yes
log file = /var/log/rsyncd.log
pid file = /run/rsyncd.pid
timeout = 0

[drive]
    path = /petdrive/drive
    comment = FAT32 drive
    read only = false
    list = yes
```
> This exports a single module named `drive`, backed by `/petdrive/drive/`.

Enable and start the service:

```bash
sudo systemctl enable --now rsync
```

### 2.2. Verify the Daemon

Run the following status checks:

```bash
sudo systemctl status rsync
systemctl is-enabled rsync
ss -ltnp | grep ':873'
rsync rsync://localhost/
```

The following should hold:
- `systemctl status rsync` reports `active (running)`
- `systemctl is-enabled rsync` reports `enabled`
- `ss -ltnp | grep ':873'` shows a listener on TCP port 873
- `rsync rsync://localhost/` lists the `drive` module

Create a local test payload and send it through the daemon:

```bash
mkdir -p ~/rsync-test
echo "hello via rsync" > ~/rsync-test/hello.txt
rsync -rtv ~/rsync-test/ rsync://localhost/drive/
rm -rf ~/rsync-test
```

Inspect the backing drive:

```bash
ls -l /petdrive/drive
cat /petdrive/drive/hello.txt
```

The following should hold:
- `ls -l /petdrive/drive` shows `hello.txt`
- `cat /petdrive/drive/hello.txt` prints `hello via rsync`

> Use `-rtv` rather than the usual `-a` for FAT-backed targets. The `-a` option attempts to preserve Unix metadata that FAT32 does not support.

### 2.3. Test a Remote Transfer

From the host machine:

```bash
mkdir -p ~/rsync-test
echo "hello from the host" > ~/rsync-test/hello.txt
rsync -rtv ~/rsync-test/ rsync://petdrive.mockernel.local/drive/
rm -rf ~/rsync-test
```

Back on the Pi:

```bash
ls -l /petdrive/drive
cat /petdrive/drive/hello.txt
```

The following should hold:
- `ls -l /petdrive/drive` shows `hello.txt`
- `cat /petdrive/drive/hello.txt` prints `hello from the host`

## 3. Queued Handler

At this point, `rsync` writes are handled directly by the daemon. That is insufficient once the same disk image is also exposed over USB mass storage. The system needs a coordination layer that:

1. disables USB exposure before writes
2. serves the `rsync` request
3. re-enables USB exposure after writes complete
4. serializes concurrent access

This coordination layer is implemented as a long-lived handler service.

---

The mounted directory `/petdrive/drive/` and the USB-exported storage both refer to the same image file, `/petdrive/drive.img`. Concurrent unsynchronized access through both paths is unsafe. Even if the host and the Pi are each internally consistent, simultaneous mutation from two independent interfaces risks corruption or stale views.

The handler addresses this by wrapping `rsync` with explicit image transition hooks:
- `image-lock`: prepares the image for local write access
- `image-free`: enables USB access to the image after updates

The current guide uses placeholder implementations first, then later wires them to the publisher service.

---

### 3.1. Create the Handler Infrastructure

Create the handler subtree:

```bash
sudo mkdir -p /petdrive/handler
sudo chown -R root:root /petdrive/handler
sudo chmod 0755 /petdrive/handler
```

Create the two placeholder scripts:

```bash
sudo tee /petdrive/handler/image-lock >/dev/null <<'EOF'
#!/bin/sh
set -eu
exit 0
EOF

sudo tee /petdrive/handler/image-free >/dev/null <<'EOF'
#!/bin/sh
set -eu
exit 0
EOF

sudo chmod 0755 /petdrive/handler/image-lock
sudo chmod 0755 /petdrive/handler/image-free
```
> These scripts are intentionally no-ops at this stage. Their interfaces are established now so the handler can be tested independently of the USB publisher.

### 3.2. Create the Handler Service

Create a local `rsync` configuration file:

```bash
sudo cp /etc/rsyncd.conf /petdrive/handler/rsyncd.conf
sudo chown root:root /petdrive/handler/rsyncd.conf
sudo chmod 0644 /petdrive/handler/rsyncd.conf
```
> Keeping a handler-local copy avoids coupling the handler to the global daemon configuration.

Create the handler file:

```bash
sudoedit /petdrive/handler/handler.py
```

The handler implementation is provided in this repository as [Resource 1](./J3A1R1-drive-controller.py).

Set executable permissions:

```bash
sudo chmod 0755 /petdrive/handler/handler.py
```

Create the `systemd` unit:

```bash
sudoedit /etc/systemd/system/petdrive-handler.service
```

Write:

```ini
[Unit]
Description=Queued rsync handler
After=network.target

[Service]
Type=simple
ExecStart=/petdrive/handler/handler.py
Restart=always
RestartSec=1
User=root
Group=root
WorkingDirectory=/petdrive/handler
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### 3.3. Replace the Direct `rsync` Daemon

Disable the original daemon so port 873 is available:

```bash
sudo systemctl disable --now rsync
```

Reload `systemd`, then enable and start the handler:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now petdrive-handler
```

### 3.4. Verify Handler-Mediated Transfers

From the host:

```bash
mkdir -p ~/rsync-test
echo "hello through the queued handler" > ~/rsync-test/hello.txt
rsync -rtv ~/rsync-test/ rsync://petdrive.mockernel.local/drive/
rm -rf ~/rsync-test
```

Back on the Pi:

```bash
ls -l /petdrive/drive
cat /petdrive/drive/hello.txt
journalctl -u petdrive-handler -n 20 --no-pager
```

The following should hold:
- `ls -l /petdrive/drive` shows `hello.txt`
- `cat /petdrive/drive/hello.txt` prints `hello through the queued handler`
- `journalctl` shows the handler servicing the request

> To exercise connection queuing behavior, the repository also includes [Resource 2](./J3A1R2-rsync-storm.sh), a script that can be used to issue many concurrent `rsync` requests.

## 4. USB Mass-Storage Device Emulation

This section finally exposes the image as a USB mass storage device. Using the handler hooks, its lifecycle can be managed so as to forbid reads over USB with simultaneous writes vioa network. This mechanism has the added advantage of forcing the USB host to re-enumerate the device after any modifications to the backing store, flushing its cache and showing the updated contents.

---

### 4.1. Enable USB Device Support

Edit the Raspberry Pi boot configuration:

```bash
sudoedit /boot/firmware/config.txt
```

Under the `[all]` section, add:

```ini
dtoverlay=dwc2
```

Reboot:

```bash
sudo reboot
```

### 4.2. Verify USB Controller Exposure

Reconnect and verify that a USB publisher controller is present:

```bash
ls -1 /sys/class/udc
```

At least one entry should be listed.

### 4.3. Create the Publisher Infrastructure

Create the publisher subtree:

```bash
sudo mkdir -p /petdrive/publisher
sudo chown -R root:root /petdrive/publisher
sudo chmod 0755 /petdrive/publisher
```

Create the publisher script:

```bash
sudoedit /petdrive/publisher/petdrive-publisher.sh
```

The control script is provided in this repository as [Resource 3](./J3A1R3-drive-device.sh).

Set executable permissions:

```bash
sudo chmod 0755 /petdrive/publisher/petdrive-publisher.sh
```

### 4.4. Create the Publisher Service

Create the `systemd` unit:

```bash
sudoedit /etc/systemd/system/petdrive-publisher.service
```

Write:

```ini
[Unit]
Description=Expose /petdrive/drive.img as a USB mass-storage gadget
After=local-fs.target
RequiresMountsFor=/petdrive
ConditionPathExists=/petdrive/drive.img

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/petdrive/publisher/petdrive-publisher.sh up
ExecStop=/petdrive/publisher/petdrive-publisher.sh down

[Install]
WantedBy=multi-user.target
```
> This unit models the publisher as a persistent on/off state managed through `systemd`.

### 4.5. Connect the Handler Hooks to the Publisher

Replace the placeholder hook scripts with service transitions:

```bash
sudo tee /petdrive/handler/image-lock >/dev/null <<'EOF'
#!/bin/sh
set -eu
exec systemctl stop petdrive-publisher
EOF

sudo tee /petdrive/handler/image-free >/dev/null <<'EOF'
#!/bin/sh
set -eu
sync
exec systemctl start petdrive-publisher
EOF
```

Reload `systemd` then enable and start the controller:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now petdrive-publisher
```

### 4.6. Validate End-to-End Behavior

Connect the publisher to the host. It should enumerate as a USB mass-storage device.

Then, from the host, perform a transfer:

```bash
mkdir -p ~/rsync-test
echo "hello into USB" > ~/rsync-test/hello.txt
rsync -rtv --delete ~/rsync-test/ rsync://petdrive.mockernel.local/drive/
rm -rf ~/rsync-test
```

During the transfer, the following should be observed:
1. the publisher disconnects
2. the handler performs the update
3. the publisher reconnects
4. the host observes the refreshed contents