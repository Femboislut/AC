# Native iOS port audit

## Executive summary

The repository is a desktop AssaultCube source tree. It contains the real engine code, a desktop SDL/OpenGL client, and the Windows/Linux runtime layout, but it is not an iOS app project. The official engine is feasible to port to iOS ARM64 only as a substantial source port, not by simply compiling the desktop client for iOS.

## What the repository contains

- `source/src` contains the game client, renderer, protocol, audio, entities, world, models, and other engine subsystems.
- `source/src/Makefile` builds Linux/UNIX targets. It links SDL2, SDL2_image, OpenGL, OpenAL, Vorbis, and zlib.
- `source/src/platform.h` includes desktop SDL, desktop OpenGL headers, OpenAL, and ENet.
- `source/src/rendergl.cpp` is a desktop OpenGL renderer; it is not a GLES/Metal iOS renderer.
- `source/src/openal.cpp` wraps OpenAL audio.
- `source/src/main.cpp` is the desktop app entry point and window loop.
- `source/xcode` contains a macOS desktop Xcode project, not an iPhone/iOS app target.
- `packages/*`, `config/*`, and `mods/*` contain runtime game data required by the game client.

The license and provenance are preserved in `source/README.txt`, `source/README_CUBEENGINE.txt`, and `docs/package_copyrights.txt`.

## Important porting findings

### 1. Rendering is the main blocker

The code is built around desktop OpenGL APIs and assumptions. The rendering code is not a portable iOS backend. A real iOS renderer must be implemented or substantially rewritten for OpenGL ES or Metal. This is not a cosmetic change; it is a core engine dependency.

### 2. App lifecycle and input are desktop-oriented

The project assumes desktop input (keyboard/mouse), fullscreen windowing, and a desktop event loop. iPhone requires touch, orientation handling, safe-area layout, foreground/background lifecycle, app bundle structure, and iOS document access.

### 3. Audio is not directly portable as-is

There is OpenAL support in the codebase, but the project must be audited and adapted for iOS audio-session requirements and iOS-supported audio APIs.

### 4. Game data import is feasible

The repo already expects standard data folders such as `config`, `packages/maps`, `packages/models`, `packages/textures`, `packages/audio`, and `mods`. That is a good candidate for a managed game-data importer in the app sandbox.

### 5. The engine itself is feasible

The AssaultCube engine core is likely portable to ARM64; the main work is platform and renderer integration, not replacing the game logic itself.

## Feasibility verdict

A true native iOS port is feasible, but only as a real porting effort. It is not feasible as a direct build of the desktop project for iOS. The project needs:

- an iOS app shell
- an iOS-compatible renderer backend
- touch/controller input mapping
- game-data import and validation
- audio adaptation
- unsigned IPA packaging via GitHub hosted macOS runners

## Current status

This branch is an audit checkpoint only. It does not yet contain a fully working iOS app project, renderer, touch controls, controller support, or an actual unsigned IPA build.

## Next engineering steps

1. Add a minimal iOS app skeleton using SDL2 or native UIKit.
2. Port or replace the rendering backend for GLES/Metal.
3. Add touch controls and controller support.
4. Implement game-data import, validation, and sandbox storage rules.
5. Add GitHub Actions to build an unsigned IPA on macOS runners.
6. Validate on a physical iPhone and document any remaining limitations.
