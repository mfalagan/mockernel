**Date:** 2026-03-31
**Author:** mfalagan
**Milestone:** M0

I am an embedded software developer by heart, but a user-space dev by trade. There is a particular kind of itch that comes from knowing the ins and outs of these two different worlds. I say different, and not distinct, because there is a clear difference, an abyss of unknowns called the *operating system*.

I've always tried to avoid it, to tell myself that, if the abstractions do their job correctly, not knowing what lies underneath *is* the point. Then again, I often find myself thinking of low-level optimization - branch-predictor friendliness, cache locality and line alignment, whether this loop is actually vectorizable or just looks like it should be, what the TLB is doing to my access patterns... Gazing into the abyss. And, if you gaze long enough into the abyss... well you know how it goes.

There *is* a real gap between programming a few peripheral controllers over MMIO or understanding concepts like memory virtualization or concurrency, and having an intuition for how it all works. As much as I would like to have closed this gap by reading and researching, I have come to realize, there is nothing like getting my hands dirty and actually building the thing.

`mockernel` is that thing. And after several months of reading on the topic, filling in technical voids, and catching up in general, I have decided to embark on this journey. I am still overwhelmed by the task and second-guessing my abilities, but, if it ultimately comes to this, one does not just chicken out on... such an awesome project name.

---

Before even thinking of a `git init`, I have spent what I can only describe as a *crazy* amount of time reading on project structure, methodology, documentation, and the likes. It did feel like I was planning a project about planning a project. I do not think, though, that any of it was in vain.

The result, some summarized in the project [front page](../../README.md), some still waiting to be proved by the test of time, is a formalization of my ususal workflow, plus some missing bits, forming an infrastructure that can bear the load of a project that does not even remotely fit entirely into memory.

I have never imposed this much structure on a personal project. Part of me wonders if it is overkill. The other part still remembers every project that died around the third major refactor.

---

I would be lying if I said I was not nervous. This is, by far, the most ambitious thing I have set out to build. I would also be lying if I said I was not excited. After months of reading, planning, and second-guessing, there is something deeply satisfying about finally getting to a milestone to work on rather than a vague aspiration to worry about.

If you are anything like me, you must be tired of the intro already. Let us get to it already.