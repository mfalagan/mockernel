**Date:** 2026-03-17
**Author:** mfalagan
**Status:**  Open
**Target Version:** v1

# M0 - Development Environment Setup

## Summary

This milestone establishes the development environment and the first complete bring-up loop for `mockernel`. Its purpose is to produce a reproducible workspace, a freestanding cross-compilation toolchain, an emulator-based run and debug workflow, and a minimal real-hardware boot path.

## Context

This milestone exists to separate environmental and workflow concerns from kernel architecture proper. Later milestones will depend on a stable build, run, and debug loop, but should not have to carry uncertainty about container or toolchain setup, emulator invocation, or the mechanics of producing a bootable image.

The output of this milestone is the ability to develop the system under controlled conditions. That ability is a prerequisite for all later architectural and implementation work, and deserves to be established, validated, and documented in its own right.

## Scope

This milestone gains the following capabilities:
 - a reproducible development container, suitable as the development environment for the project.
 - a complete build workflow.
 - an emulated execution path.
 - a debug workflow using said emulation.

This milestone does not attempt to implement anything beyond the minimal bootstrap program needed to validate the environment and workflow. Anything beyond is deferred to future milestones.

## Exit Criteria

The milestone is complete when all of the following are true:
 1. a clean build produces the required artifacts.
 2. a minimal demo can be run via emulation.
 3. a minimal demo can be run in the target hardware.
 4. a minimal demo can demonstrate the complete debug workflow.
 5. the workflow designed in this milestone is completely documented.