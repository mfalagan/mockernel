#!/bin/sh
set -eu

G=/sys/kernel/config/usb_gadget/drive
CFG=c.1
FUNC=mass_storage.usb0
IMAGE=/petdrive/drive.img

udc_name() {
    ls /sys/class/udc | head -n1
}

ensure_prereqs() {
    modprobe libcomposite

    if ! mountpoint -q /sys/kernel/config; then
        mount -t configfs none /sys/kernel/config
    fi

    [ -f "$IMAGE" ]
    [ -n "$(udc_name)" ]
}

gadget_exists() {
    [ -d "$G" ] &&
    [ -d "$G/functions/$FUNC" ] &&
    [ -L "$G/configs/$CFG/$FUNC" ]
}

create_gadget() {
    mkdir -p "$G"
    cd "$G"

    mkdir -p strings/0x409
    mkdir -p configs/"$CFG"/strings/0x409
    mkdir -p functions/"$FUNC"

    printf '%s\n' 0x1d6b > idVendor
    printf '%s\n' 0x0104 > idProduct

    head -c 16 /etc/machine-id > strings/0x409/serialnumber
    printf '\n' >> strings/0x409/serialnumber
    printf '%s\n' "mockernel" > strings/0x409/manufacturer
    printf '%s\n' "drive" > strings/0x409/product

    printf '%s\n' "Mass Storage" > configs/"$CFG"/strings/0x409/configuration
    printf '%s\n' 250 > configs/"$CFG"/MaxPower

    printf '%s\n' 1 > functions/"$FUNC"/lun.0/ro
    printf '%s\n' 1 > functions/"$FUNC"/lun.0/removable
    printf '%s\n' "$IMAGE" > functions/"$FUNC"/lun.0/file

    if [ ! -L "configs/$CFG/$FUNC" ]; then
        ln -s "functions/$FUNC" "configs/$CFG/"
    fi
}

ensure_gadget() {
    if gadget_exists; then
        return
    fi

    create_gadget
}

attach_gadget() {
    current="$(cat "$G/UDC" 2>/dev/null || true)"
    if [ -n "$current" ]; then
        exit 0
    fi

    printf '%s\n' "$(udc_name)" > "$G/UDC"
}

detach_gadget() {
    if [ -e "$G/UDC" ]; then
        printf '%s\n' > "$G/UDC"
    fi
}

status_gadget() {
    printf 'udc: %s\n' "$(cat "$G/UDC" 2>/dev/null || true)"
    printf 'backing file: %s\n' "$(cat "$G/functions/$FUNC/lun.0/file" 2>/dev/null || true)"
    printf 'read-only: %s\n' "$(cat "$G/functions/$FUNC/lun.0/ro" 2>/dev/null || true)"
    printf 'removable: %s\n' "$(cat "$G/functions/$FUNC/lun.0/removable" 2>/dev/null || true)"
}

case "${1:-}" in
    up)
        ensure_prereqs
        ensure_gadget
        attach_gadget
        ;;
    down)
        detach_gadget
        ;;
    status)
        status_gadget
        ;;
    *)
        echo "usage: $0 {up|down|status}" >&2
        exit 2
        ;;
esac