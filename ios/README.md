# AssaultCube iOS port

This directory contains the native iOS data-import prototype and early engine-host experiments. The app is not yet a playable AssaultCube port.

## Current status

- The SwiftUI data importer validates and stores imported AssaultCube game data.
- The GLKit/Objective-C++ bridge is only a placeholder; it does not start the C++ engine.
- The existing engine still owns its SDL startup, event loop, rendering and buffer presentation in `source/src/main.cpp`.
- GL4ES is pinned as a submodule, and the engine now requests an ES2 context and initializes GL4ES through SDL on iOS. An iOS-only raycast fallback replaces depth-buffer readback for crosshair targeting. None of this integration has yet been compiled or tested.
- No ARM64 iOS engine build or physical-device gameplay test has succeeded.

## Recommended implementation direction

Use SDL2's iOS backend as the single application/window/context owner, and evaluate GL4ES as the compatibility layer for the engine's desktop OpenGL calls. The upstream `acmobile` branch provides reusable mobile touch-UI code and an Android ray-based replacement for depth-buffer readback. Those changes need to be adapted to this newer source tree rather than copied wholesale.

See [ENGINEERING_PLAN.md](ENGINEERING_PLAN.md) for the technical rationale, known limitations, implementation sequence and acceptance criteria.

The Windows executable and DLLs are not part of the iOS runtime. The intended app imports game data only; the AssaultCube engine itself must be compiled as native ARM64 iOS code.
