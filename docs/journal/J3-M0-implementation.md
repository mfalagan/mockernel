**Date:** 2026-04-05
**Author:** mfalagan
**Milestone:** M0

There is quite a bit of stuff to unpack from the design. The first order of business is to provide the services I deferred to the user.

To start, I will set up a RPi Zero to provide what I called the *boot media* service. Taken from the design, it should expose the boot files through two distinct interfaces, one boot-capable path for the Pi, and one write-enabled path for the dev host. I chose to do this through USB mass storage device emulation for booting, and through `rsync` for uploading. As I said, this part *is* left as homework, but I composed my approach to set up a Pi Zero in this way as a guide, provided in this journal as [Annex 1](./J3A1-boot-file-service.md).