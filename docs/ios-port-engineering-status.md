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
- `.github/workflows/ios-dependencies-build.yml`: one consolidated macOS job that builds SDL2 and GL4ES sequentially for ARM64 iOS and packages both libraries together. SDL2 is pinned to upstream commit `fe30456e94e89ef2cab50172121bffb7f7f50830`.

This dependency workflow is not an engine build. Its first run is pending; no artifact has been verified yet. The former separate GL4ES, SDL2 and app-shell-validation workflows were removed to avoid duplicate queued jobs.

**The IPA from this workflow is only the data-management shell. It is not a playable AssaultCube build.** The engine sources are not yet compiled or linked into this Xcode target.

## Verified engine integration blockers from source inspection

### Startup and event loop

`source/src/main.cpp` still owns desktop startup and rendering lifecycle. It calls SDL initialization, creates an SDL window and GL context, polls SDL events, and swaps the SDL window buffers. The iOS host bridge does not call into this engine lifecycle.

The next refactor should extract explicit engine lifecycle functions (initialize, process input, render one frame, suspend/resume, shutdown) from `main()`. Do not create a second SDL window on iOS. On iOS, SDL should be initialized in its iOS-supported application lifecycle or the UIKit host must own the view and context consistently.

### iOS window and application lifecycle ownership

A source-level check of the pinned SDL2 iOS backend establishes an important integration constraint:

- SDL's UIKit video driver creates its own `SDL_uikitwindow` / `UIWindow` and controller when `SDL_CreateWindow` is called.
- The SDL UIKit backend explicitly permits only one SDL window per display.
- SDL's iOS entry point (`SDL_UIKitRunApp`) owns `UIApplicationMain` and forwards control to `SDL_main`.
- AssaultCube's existing `main.cpp` already creates an SDL window and GL context, then initializes GL4ES against SDL's GL procedure resolver. Its main loop is a persistent frame loop that polls SDL events, updates the world, renders, and swaps the SDL window.

This means the current prototype architecture has a real ownership conflict: `EngineViewController.swift` creates a separate UIKit `GLKView` / EAGL context, while the AssaultCube engine expects SDL to create and own its window and context. Simply calling the current engine `main()` from `EngineBridge` would create a second rendering context/window rather than render into the existing GLKView.

**Integration rule:** do not connect the current placeholder bridge to `main()` as-is. The iOS application must have one authoritative owner for the UIKit window and OpenGL ES context. The preferred route to preserve the existing SDL event/render pipeline is to let SDL's UIKit backend own the game window and context, then adapt the game-data import experience to that host. An alternative is a deeper SDL video-backend adaptation that lets SDL render into a host-owned UIKit view; that requires explicit proof that the iOS backend supports external-view binding and must not be assumed from `SDL_CreateWindowFrom`.

The current SwiftUI data-import shell and GLKView prototype should therefore be treated as scaffolding, not the final application root. The next lifecycle refactor should separate engine initialization, one-frame execution, pause/resume, and shutdown while preserving the desktop entry point. It must also ensure SDL's iOS application bootstrap is used exactly once and that no second `UIApplicationMain`, `UIWindow`, or GL context is created.

### Renderer

`source/src/rendergl.cpp` uses desktop fixed-function OpenGL calls. OpenGL ES 2.0 does not provide the legacy immediate-mode API and matrix stack. Including `SDL_opengles2.h` alone cannot make this renderer compile or work.

A real solution must either:
- port the renderer to programmable GLES shaders and vertex/index buffers, including conversion of matrix, texture, lighting, fog, HUD, model and particle paths; or
- demonstrate and validate an iOS-compatible compatibility implementation that supplies the exact required functionality.

Do not label a framebuffer clear as a renderer.

### Build and dependencies

The desktop `source/src/Makefile` selects X11, desktop OpenGL and desktop library flags on non-Windows platforms. It has no iOS toolchain target. ENet is vendored as source, but SDL2, SDL2_image, Ogg and Vorbis must be built or linked for iOS ARM64 with supported headers and configuration.

The prebuilt frameworks under `source/xcode/Frameworks` are not usable as iOS dependencies: their bundle metadata explicitly lists `MacOSX` as the supported platform. In particular, the checked-in SDL2, SDL2_image, Ogg and Vorbis binaries cannot be assumed to be arm64 iOS libraries. The new SDL2 workflow rebuilds SDL2 for the iOS device SDK rather than reusing those macOS binaries. zlib can be linked from the iOS SDK; the audio backend still needs a deliberate iOS-compatible implementation and link configuration.

### Input

The touch bridge stores coordinates and deltas, but it is not translated into AssaultCube's movement, look, fire, jump, crouch, weapon and menu actions. The desktop SDL event loop still owns input processing. A platform-neutral input command layer is required.

### Data paths

The import package stores data at Documents/GameData. The engine's VFS, config, package and writable user-data paths must be configured to read that location and keep writable preferences/cache separate from imported read-only content.

## Next engineering milestones

1. Verify the first GL4ES and SDL2 ARM64 iOS dependency builds and correct any toolchain or packaging failures.
2. Build the remaining iOS dependencies: SDL2_image, Ogg/Vorbis, ENet and the selected audio backend; use the iOS SDK zlib rather than desktop library flags.
3. Resolve the single-owner SDL/UIKit window and context architecture before wiring the app bridge.
4. Add an actual Xcode engine target that compiles and links the native ARM64 C/C++ sources and the verified dependencies.
5. Refactor the engine entry point into callable lifecycle/frame functions without breaking desktop builds.
6. Select and implement the renderer migration. This is the largest source-code task.
7. Connect UIKit touch and GameController events to the engine's platform-neutral input actions.
8. Configure VFS/data/config paths and test loading a real map.
9. Verify audio and networking, then test on physical iPhone hardware.

## Acceptance criteria for calling it playable

A successful IPA archive is not enough. The port is playable only after a physical iPhone can launch the app, load an imported map, render the actual 3D world, move and aim, fire a weapon, hear audio, and enter a real multiplayer session.


### SDL application bootstrap and SwiftUI entry-point conflict

The pinned SDL2 iOS source includes `src/main/uikit/SDL_uikit_main.c`, which calls `SDL_UIKitRunApp(argc, argv, SDL_main)` for the SDL-managed application entry point. SDL's `SDL_main.h` maps the engine's `main` to `SDL_main`. The current Xcode target separately declares a SwiftUI `@main` app. Those are competing process bootstraps: linking SDL2main into the SwiftUI app without redesigning the entry point is not a valid way to start the engine, and calling SDL_UIKitRunApp after SwiftUI has already started UIKit is also invalid.

Before wiring the engine, select one architecture: (A) let SDL2 own the process entry point and port the importer/settings UI into UIKit screens hosted by the SDL app, or (B) keep SwiftUI as the process owner and patch SDL's UIKit backend to attach to the existing application/window/view without invoking SDL_UIKitRunApp or creating a second UIWindow/context. Option B is a larger backend integration and requires a real device proof. The current shell and engine remain intentionally disconnected until this is resolved.
