**Date:** 2026-04-01
**Author:** mfalagan
**Milestone:** M0

I have always gravitated toward embedded projects. Despite having a few ones on my shoulders, I have never tried to set up a serious development environment. Looking back at all the hours of pen-and-paper execution and UART-print debugging, it would probably have paid off within a week.

Primarily motivated by the intent to take this whole project seriously, but also in the interest of my future self, I have actually spent some time thinking the setup through.

The Pi 5 has two main advantages I would like to leverage for this setup; *network boot*, and *serial wire debug*. With the former, I envision setting up a TFTP server that serves the latest compilation to the Pi on each boot. With the latter, one can debug on the actual hardware.

---

Unfortunately, we have hit our first roadblock...

Turns out the setup I was aiming for relies heavily on the physical setup. The Pi's network boot needs to be in the same level two segment of the network as the server. The debug probe need to be connected via USB to the host running OpenOCD. This aspect is generally very thinly implemented in most virtualization frameworks, I experimented with Colima and OrbStack. This means a normative approach is either terribly host-dependent on this leg, or a painful, sketchy implementation at best, and impossible at worst.

This leaves me with my plan B, making each host- or implementation-dependent part modular, and leaving it as **homework for the user** to set up in each particular environment. I plan on exposing the following services over LAN:
- **boot media:** access to the boot drive can be provided over FTP
- **serial:** access to the Pi's UART can be provided over RFC
- **debugging** Access to the Pi's SWD can be provided by OpenOCD (GBD + Tcl RPC + Telnet)

Making the host mDNS-enabled would make these services available over LAN.

These services can be used within the Dev Container to support the following workflows
- **build:** builds the kernel
- **publish:** pushes the boot file tree to the boot media
- **run:** reboots the Pi over SWD and attaches the console to serial
- **debug:** is similar to build, but the Pi is halted to await GDB
- **attach:** runs GDB and attaches it to the Pi

This design has multiple advantages, but mainly, it allows for full debugging on the actual hardware. I still wonder if installing QEMU for fast iteration and testing is a bad idea, but the fact that the Pi 5 is not yet supported pushes me toward deferring this to a later stage. The described setup replaces it entirely.

There are a few things to consider beforehand. Mainly, the Pi 5 does not expose a `nRESET` pin equivalent. Instead, we could use the *power management watchdog* to reboot the board. I understand this is the trick the Linux kernel uses. I am not saying that the trick the Linux kernel uses may not be good enough for us. I know better than to question the gods. I am unsure about how writing to MMIO directly from SWD will work. We will have to try and see.

To package this all up, I would like to set it all up in a container. Out of mere habit, I will go with a slim flavor of Debian. On top of it, the full development environment should be set up.

I have some questions about how to handle the specifics of my setup, host machine, debug probe and other hardware. I will leave this too as a problem for my future self.

I believe this is enough of that. We can now start with the implementation.