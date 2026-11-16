# iOS port engineering status

## Scope

This branch is a continuation of the iOS feasibility scaffold. It deliberately separates a buildable native data-management shell from the unfinished C++ game-engine port.

## What is present in the source tree

- SwiftUI app entry point and game-data import UI.
- A Swift package for ZIP/folder import, validation, storage accounting, and reset.
- A GLKit/OpenGL ES view controller prototype.
- An Objective-C++ bridge that currently clears the GLES framebuffer and stores touch snapshots.
- An iOS conditional in `source/src/platform.h`.

## What this branch adds

- `ios/project.yml`: XcodeGen project definition for the SwiftUI app shell and local data package.
- `.github/workflows/ios-build.yml`: macOS CI that runs package tests, generates the Xcode project, archives the app without signing, and uploads an unsigned IPA artifact.

**The IPA from this workflow is only the data-management shell. It is not a playable AssaultCube build.** The engine sources are not yet compiled or linked into this Xcode target.

## Verified engine integration blockers from source inspection

### Startup and event loop

`source/src/main.cpp` still owns desktop startup and rendering lifecycle. It calls SDL initialization, creates an SDL window and GL context, polls SDL events, and swaps the SDL window buffers. The iOS host bridge does not call into this engine lifecycle.

The next refactor should extract explicit engine lifecycle functions (initialize, process input, render one frame, suspend/resume, shutdown) from `main()`. Do not create a second SDL window on iOS. On iOS, SDL should be initialized in its iOS-supported application lifecycle or the UIKit host must own the view and context consistently.

### Renderer

`source/src/rendergl.cpp` uses desktop fixed-function OpenGL calls. OpenGL ES 2.0 does not provide the legacy immediate-mode API and matrix stack. Including `SDL_opengles2.h` alone cannot make this renderer compile or work.

A real solution must either:
- port the renderer to programmable GLES shaders and vertex/index buffers, including conversion of matrix, texture, lighting, fog, HUD, model and particle paths; or
- demonstrate and validate an iOS-compatible compatibility implementation that supplies the exact required functionality.

Do not label a framebuffer clear as a renderer.

### Build and dependencies

The desktop `source/src/Makefile` selects X11, desktop OpenGL and desktop library flags on non-Windows platforms. It has no iOS toolchain target. ENet, SDL2, SDL2_image, zlib, OpenAL and Vorbis must each be built or linked for iOS ARM64 with supported headers and configuration.

### Input

The touch bridge stores coordinates and deltas, but it is not translated into AssaultCube's movement, look, fire, jump, crouch, weapon and menu actions. The desktop SDL event loop still owns input processing. A platform-neutral input command layer is required.

### Data paths

The import package stores data at Documents/GameData. The engine's VFS, config, package and writable user-data paths must be configured to read that location and keep writable preferences/cache separate from imported read-only content.

## Next engineering milestones

1. Run the new CI and resolve any actual Swift/package/Xcode build failures.
2. Establish an iOS ARM64 dependency build for SDL2, ENet, SDL2_image, zlib, Vorbis and the selected audio backend.
3. Refactor the engine entry point into callable lifecycle/frame functions without breaking desktop builds.
4. Select and implement the renderer migration. This is the largest source-code task.
5. Connect UIKit touch and GameController events to the engine's platform-neutral input actions.
6. Configure VFS/data/config paths and test loading a real map.
7. Verify audio and networking.
8. Test on physical iPhone hardware.

## Acceptance criteria for calling it playable

A successful IPA archive is not enough. The port is playable only after a physical iPhone can launch the app, load an imported map, render the actual 3D world, move and aim, fire a weapon, hear audio, and enter a real multiplayer session.
