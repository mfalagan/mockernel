**Date:** 2026-04-01
**Author:** mfalagan
**Milestone:** M0

I have always gravitated toward embedded projects. Despite having a few ones on my shoulders, I have never tried to set up a serious development environment. Looking back at all the hours of pen-and-paper execution and UART-print debugging, it would probably have paid off within a week.

Primarily motivated by the intent to take this whole project seriously, but also in the interest of my future self, I have actually spent some time thinking the setup through.

The Pi 5 has two main advantages I would like to leverage for this setup; *network boot*, and *serial wire debug*. With the former, I envision setting up a TFTP server that serves the latest compilation to the Pi on each boot. With the latter, one can debug on the actual hardware.

The design of this benchmark is deliberately left with some wiggle room to be finely tuned during implementation. I know, I know, we have not completed a single milestone and we already are stretching the limits. What you do not know is that I come from aerospace, where acronyms are chosen before their meaning. I'm sure I can find a way of making this case fit into the methodology text. When I come around to write it, that is.

The main workflows I imagine are:
- **release:**
    1. source code gets compiled into `.elf` file
    2. the `.img` file is generated and stored in the TFTP directory
    3. the `.dbg` file is generated and stored in the GDB directory 
- **run:**
    1. reboot signal is sent to hardware over SWD
    2. latest `.img` file is served over TFTP
- **debug:**
    1. same process as in *run* workflow
    2. GDB is attached to the hardware via SWD / OpenOCD

This design has multiple advantages, but mainly, it allows for full debugging on the actual hardware. I still wonder if installing QEMU for fast iteration and testing is a bad idea, but the fact that the Pi 5 is not yet supported pushes me toward deferring this to a later stage. The described setup replaces it entirely.

There are a few things to consider beforehand. Mainly, the Pi 5 does not expose a `nRESET` pin equivalent. Instead, we could use the *power management watchdog* to reboot the board. I understand this is the trick the Linux kernel uses. I am not saying that the trick the Linux kernel uses may not be good enough for us. I know better than to question the gods. I am unsure about how writing to MMIO directly from SWD will work. We will have to try and see.

To package this all up, I would like to set it all up in a container. Out of mere habit, I will go with a slim flavor of Debian. On top of it, the full development environment should be set up.

I have some questions about how to handle the specifics of my setup, host machine, debug probe and other hardware. I will leave this too as a problem for my future self.

I believe this is enough of that. We can now start with the implementation.