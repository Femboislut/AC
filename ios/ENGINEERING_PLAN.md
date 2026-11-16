# iOS engine port: implementation plan

## Direction

Do not rewrite AssaultCube's renderer as the first step. The upstream `acmobile` branch and the separate OUYA port demonstrate a closer path: keep the existing SDL2 engine architecture, use GL4ES to translate the desktop fixed-function OpenGL calls to OpenGL ES 2.0, and add a mobile input layer.

This is a feasibility direction, not a claim that the current iOS scaffold is playable. The current `EngineBridge.mm` still clears the screen and does not call the engine.

## Evidence in the existing codebases

- Upstream `assaultcube/AC` has an `acmobile` branch with a mobile touch UI under `source/src/touch/`. Its main loop calls `checktouchinput()` when touch is enabled.
- The OUYA port builds the same engine with SDL2 + GL4ES + OpenAL and explicitly requests an OpenGL ES 2.0 context in `setupscreen()`.
- GL4ES documents an iOS static-library build using `ios-cmake`, `NOX11=ON`, `NOEGL=ON`, `STATICLIB=ON`, and `PLATFORM=OS`. Its iOS instructions require calling `initialize_gl4es()` after the GLES context is current.
- There is a material graphics caveat: GL4ES documents that GLES 1.1/2.0 cannot provide the depth-buffer readback used by AssaultCube's desktop `readdepth()`. An iOS-only ray/line-of-sight fallback has now been added in `source/src/rendergl.cpp`, based on the upstream mobile implementation and with bounded traversal/map-edge handling. It is still uncompiled and untested; verify crosshair targeting, map geometry, mapmodels and editing before relying on it.

References:
- Upstream mobile branch: https://github.com/assaultcube/AC/tree/acmobile
- GL4ES iOS build notes: https://github.com/ptitSeb/gl4es/blob/master/COMPILE.md
- GL4ES depth-readback limitation: https://github.com/ptitSeb/gl4es/blob/master/MEDIA.md
- Working OUYA implementation notes: https://github.com/RyoSaeba89/assaultcube-ouya/blob/main/OUYA_PORT.md

## Architecture decisions

### 1. SDL owns the game window and frame loop

The current SwiftUI/GLKit view is useful as a UI/data-import prototype, but it should not become a second graphics owner alongside SDL. The engine already creates an SDL window and GL context in `source/src/main.cpp`, polls SDL events, runs the simulation, renders, and swaps buffers.

The iOS runtime should use SDL's iOS platform backend and its application lifecycle. Keep one SDL window/context and one authoritative engine loop. Do not create an EAGL/GLK context independently and then attempt to render into it from a separate SDL context.

### 2. GL4ES is the first renderer-compatibility experiment

Build GL4ES as an iOS static library for its GLES2 backend. The engine must include GL4ES's desktop-compatible GL headers for the iOS target, link the static library, create a GLES2 context, and initialize GL4ES only after that context is current.

This avoids immediately rewriting the large fixed-function renderer. It does not eliminate testing of unsupported calls, extensions, framebuffer behavior, shaders, or performance.

### 3. Port the mobile input layer, then add iOS-specific controls

The current branch has no `source/src/touch/` tree and its main loop never calls `checktouchinput()`. The upstream `acmobile` branch contains a touch UI and SDL-event handling that should be evaluated as a source of reusable code. It will need a version-aware transplant into this branch; do not copy its entire `main.cpp` over the newer engine blindly.

The iOS control layer should support:
- left virtual stick for movement;
- right-side drag for camera look;
- fire, jump, crouch, reload, weapon switch and aim buttons;
- Bluetooth controller input through SDL's game-controller API;
- safe-area-aware layout and configurable sensitivity.

### 4. Replace desktop depth readback on iOS

The desktop `readdepth()` calls `glReadPixels(..., GL_DEPTH_COMPONENT, ...)`. GL4ES documents that GLES2 cannot provide the depth readback required by this code. The upstream mobile branch contains a ray-based replacement for Android. Port that algorithm behind an iOS platform conditional, preserving the existing desktop path, and test crosshair targeting, map geometry, mapmodels and editing separately.

### 5. Keep the existing data importer, but make the engine consume its directory

The Swift `AssaultCubeData` package can remain useful for importing and validating the user's game-data archive. The runtime must receive the resulting absolute directory and configure AssaultCube's VFS/profile paths before it attempts to load fonts, maps, packages, configuration, or writable files.

Do not make the engine depend on the Windows executable or Windows DLLs. Only the game's data files are imported; the engine is compiled as native ARM64 iOS code.

## Work sequence and acceptance criteria

1. **Build a minimal SDL2 + GL4ES iOS test app.** It must create a GLES2 context, initialize GL4ES, draw a test scene, and present frames on an iPhone.
2. **Compile the AssaultCube engine sources for arm64 iOS.** Resolve platform headers, ENet, zlib, SDL2_image, Ogg/Vorbis and OpenAL. A successful link is required before attempting gameplay.
3. **Integrate engine startup and lifecycle.** App launch, backgrounding, foregrounding, shutdown and graphics-context recreation must not leave stale SDL/GL state.
4. **Integrate game-data paths and startup.** Imported data must load from the app sandbox; settings, logs, maps and demos must write only to app-owned writable locations.
5. **Integrate touch and controller input.** Verify each action in menus and in a local match.
6. **Validate rendering and targeting.** Test maps, models, textures, HUD, water, shadows, crosshair target selection, screenshots and resolution changes. Disable unsupported expensive effects only through explicit mobile defaults.
7. **Validate audio and networking.** Test positional audio, mute/background behavior, server browsing, joining, disconnecting and reconnecting.
8. **Package an unsigned arm64 IPA and install it through the user's existing sideloading workflow.** Do not label the port playable until a physical-device test reaches a map and confirms movement, aiming, firing, audio and multiplayer.

## Current blockers

- No iOS SDL2/GL4ES native build target is wired into this repository.
- `EngineBridge.mm` is a placeholder, not an engine bridge.
- The current branch lacks the upstream mobile touch UI.
- The current renderer still expects desktop OpenGL behavior and uses depth-buffer readback.
- The existing SwiftUI app is a data-management shell, not the final SDL game host.
- No ARM64 iOS engine build or physical-device gameplay test has succeeded yet.
