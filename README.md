# mfalagan/mockernel

`mockernel` is a formative OSdev project targeting the Raspberry Pi Zero 2w.

The project goals are:
 - to develop a coherent minimal operating system.
 - to explore the engineering process required to do so.

The emphasis is on deliberate system design and implementation. The aim is not to produce a booting demo, nor to imitate a production system at an inappropriate scale, but to build a minimal system with a clear structure and grow it over time.

## Design Philosophy

### Standards First

The project treats standards and established conventions as design constraints from the beginning. Architectural choices are made with future compatibility in mind, so that later alignment with real-world interfaces and practices remains possible.

This principle is not about premature conformance or implementing standards for their own sake. It is about avoiding decisions that would make later compliance unnecessarily difficult.

In practice, this means:
 - respecting AArch64 execution and AAPCS64 conventions.
 - following the Raspberry Pi firmware boot flow and the arm64 kernel entry contract.
 - using Devicetree as the hardware description mechanism.
 - preferring stable internal interfaces and explicit architectural decisions.

### System Ownership

The project should retain direct ownership of its core mechanisms in order to preserve its formative value. Core mechanisms should be designed and implemented directly, rather than delegated away behind heavy tooling or broad external dependencies.

This principle is not about refusing all external components. It is about retaining visibility into the critical parts of the system.

In practice, this means:
 - keeping tooling and dependencies deliberately simple.
 - admitting external components only when they earn their place.

### Performance Orientation

The project should treat performance as a design responsibility. Abstractions, interfaces, and internal representations should be chosen so that performance-relevant properties remain visible in the design and controllable in the implementation.

This principle is not about premature optimization or reducing the system to handwritten low-level code. It is about refusing convenience when it hides real cost.

In practice, this means:
 - preferring machine-friendly data and execution models.
 - keeping layout, lifetime, and cost visible in the design.
 - treating abstraction as a tool for structure, not as a license to obscure the underlying system.

## Development Model

`mockernel` is developed through a milestone-based workflow. Each milestone is scoped to embody one coherent concern of the system, and to carry that concern to a complete state. The purpose of this structure is to keep the project intelligible as it grows, and to make progress in units that are complete and cleanly bounded.

Each milestone passes through four stages:
 - **definition** fixes the milestone's intent and scope.
 - **design** incorporates the chosen solution into the project's architectural description.
 - **implementation** produces the source code.
 - **validation** checks the result against the milestone's intended outcome.

## Project State

### v1 - Current Version Target

Version `v1` targets a minimal but architecturally coherent kernel for the Raspberry Pi Zero 2w. Its scope is to establish the core semantic boundaries of the system: explicit privileged and unprivileged execution contexts, a defined syscall interface, managed memory, and a descriptor-oriented I/O model. The intent is to reach a small kernel whose structure can later be extended without architectural rework.

Version `v1` is intentionally scoped to remain achievable as a first complete system. Multiprocessor support, persistent storage, networking, USB, wireless peripherals, graphics output, and broad platform portability are intentionally deferred. Broader interface coverage and stronger standards alignment are also outside the immediate target.

## Documentation Model

`mockernel` maintains two documentation lines: one describes the system as designed, and one describes the system as developed.

The engineering line captures the currently intended project structure. It defines milestone scope, records major decisions, and describes the architecture the implementation is expected to follow.

The journal line captures the actual development path. It records the work itself, the constraints and mistakes discovered during it, and the changes in understanding that occurred along the way. It is meant to preserve both the implementation record and the tutorial value of the project.

## License

This project is released under the **BSD 3-Clause License**. See [LICENSE](./LICENSE) for the full license text.