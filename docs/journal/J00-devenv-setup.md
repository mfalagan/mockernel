I am an embedded software developer by passion, but a user-space dev by trade. For a long time now I have wanted to bridge the gap between these two worlds.

Those were the first two sentences of the query I wrote to ask an LLM what a project like this would entail, back when `mockernel` first came to mind. After several months of reading on the topic, filling in technical voids, and generally catching up - while still not fully confident in my abilities - I have decided to bite the bullet and get on with the implementation. After all, one does not *just* let such an awesome idea for a project name go to waste...

Although Fortran does hold a special place in my heart, I remain mildly suspicious of anything that uses one-based indexing. I kid, of course, but I usually do start my projects by their 0th step, as it seems like the perfect number for an initial "setup & config" step. This is precisely what M0 will cover, the complete set up of an environment that is fully capable of hosting the development of the project.

I, as many people, was born a windows user, and, as many windows users, have always tended to stay the furthest away from windows that I could. It did not take a lot of time, once I discovered containers, for me to implement them into my workflow as a way to set up an environment free of my host OS' grip. When I discovered VS code's Dev Containers, I quickly jumped onboard. I did carry a lot of vices, though, usually just spooling up a Debian container and manually setting up the toolchain. For this, my first portfolio piece, the development environment is the first thing I want to take a more normative approach with.

---

As this milestone deribelately avoids concerning itself with the implementation, I don't think it calls for any architectural documentation. For this reason, I'll try to be particularly verbose in journaling the design of the development environment.

My idea is, as I mentioned earlier, to set up a Development Container wit the full toolchain. For the base container, I will go with a slim Debian, mainly out of habit.

Again working out of habit, for the emulation I'm going with QEMU. It apparently does not support the Zero 2w, but it does support the RPi 3A+ variant, which seems like a nice enough alternative. Once the kernel is made DTB-aware - a capability left for latter milestones to implement - our program should not behave any different. I decided to target the 2w because it is both particularly cheap, and especially inexpensive, and I do not intend to buy a Pi that does not offer both of these advantages just to have a slightly more faithful emulator.

Arm offers a nice GNU toolchain. Its aarch64-none-elf flavor is perfectly aimed at our 64-bit bare-metal Arm target. I initially thought of installing the version built for Aarch64 Linux hosts, but, in the name of portability, I may end up checking for x86-64 hosts, so as to give support to the more unfavored half.

QEMU also offers a nifty debug stub, to which we can attach a gdb debugger, like the one included in the Arm cross-toolchain mentioned earlier. Things are falling into place almost as if someone had already planned it all. Eerie.

With these tools' powers combined, we should be able to set up a debug workflow, and peep at our code thriving - or failing scandalously - in its natural habitat. This is probably the best we are going to get, short of JTAG. The best we are going to get, that is.

The last piece of the puzzle is how to orchestrate everything. As we have everything neatly set up and containerized, trusty old GNU Make will do the trick, and I can live another day without learning CMake.

This should be all for setup. I have seen people piece together setups that would put mine to shame, but this is not my field and I'd rather get to it as soon as I can. Am I to survive the set up and configuration process, we can focus on more interesting things. Oncce everything is validated, that is.

That last bit is the punchline, in case you missed it. Validation actually is a nontrivial issue, because how does one validate a kernel development environment without actually developing a kernel. One doesn't, I say. The catch is, a kernel does not need to be a nontrivial development. Not as long as it is not an actual kernel, but a booting demo. In this way, we could non-nontrivialize the original issue, not making it a non-issue, but a trivial one at least. I too got lost for a minute there.

All joking aside, that is the validation strategy: building a minimal booting demo. We can actually come full circle by making it a hello world.

---

With the design done, the obvious firts thing to get on with is the Dev Container. This has two main components: the definition of the container in the [devcontainer.json](../../.devcontainer/devcontainer.json), and the [Dockerfile](../../.devcontainer/Dockerfile) that builds the image.

In the first file just a few lines do important stuff. Namely, they point the devcontainer services to a Dockerfile to build the image, and pass a few parameters into it. These parameters tell the image which version (the latest, at the time of this writing) and flavor (bare-metal 64-bit arm, in our case) of the Arm GNU toolchain to install. The last bit just installs a couple of VS code extensions, mainly to add IntelliSense and syntax highlighting to GNU Arm assembly, C++, Makefile and linker scripts, and points its compiler path to the C++ cross-compiler.

In the second file there aren't any surprises either. From a base Debian image, after installing a few utilities from apt-get, the container fetches, decompresses and saves the Arm cross-toolchain, adding it to the PATH and creating a symling to the C++ cross-compiler for the .json to point VS code to. The last bit just runs the three basic commands asking for the version of the cross-toolchain, emulator, and Devicetree compiler, so as to catch any issues before finishing the build.

With all of this configuration done, we can build the container and reopen the project in it. From now on, all will be done through the Dev Container - although its definition or image may change over time.