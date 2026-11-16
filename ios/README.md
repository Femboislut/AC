# AssaultCube iOS port

This directory contains the native iOS data-import prototype and the first native engine build scaffold. The app is not yet a playable AssaultCube port.

## Current status

- The SwiftUI data importer validates and stores imported AssaultCube game data.
- The existing GLKit/Objective-C++ bridge is a placeholder; it does not start the C++ engine.
- `ios/Engine/CMakeLists.txt` now defines a static `AssaultCubeEngine` target from the current desktop client source list and compiles ENet from source.
- The manual dependency workflow builds SDL2, GL4ES and Ogg/Vorbis for iOS ARM64, then attempts to compile the native engine target using those libraries.
- The dependency workflow has not yet completed successfully. No ARM64 engine archive or playable IPA has been verified.

## Architecture

SDL2 must own the iOS application bootstrap, game window, OpenGL ES context and event loop. The current SwiftUI `@main` shell and GLKit context are not connected to the engine because they conflict with SDL's UIKit bootstrap/window ownership. The preferred first integration is a minimal SDL-owned app; the data-import/settings UI can be moved into UIKit after that lifecycle proof.

GL4ES is the compatibility layer for the engine's desktop fixed-function OpenGL calls. The engine requests an ES2 context and initializes GL4ES through SDL on iOS. The iOS-only depth-readback fallback and renderer integration remain uncompiled and untested.

## Build the native engine static library

1. Open the repository's [Actions](https://github.com/Femboislut/AC/actions) page.
2. Run **iOS ARM64 dependency build** manually. This workflow builds the pinned SDL2, GL4ES, libogg and libvorbis dependencies, then compiles `AssaultCubeEngine`.
3. Download the `AssaultCube-iOS-ARM64-dependencies` artifact from the successful run.
4. Extract the archive into `ios/Dependencies/`. It should create `SDL2/`, `GL4ES/`, `Audio/` and `Engine/` directories.

Equivalent local CMake configure/build commands (with Xcode, CMake, and the pinned `ios-cmake` toolchain already available):

```sh
cmake -S ios/Engine -B build/engine -G Xcode \
  -DCMAKE_TOOLCHAIN_FILE="$PWD/ios-cmake/ios.toolchain.cmake" \
  -DPLATFORM=OS64 -DCMAKE_BUILD_TYPE=Release \
  -DAC_IOS_DEPS_DIR="$PWD/ios/Dependencies"
cmake --build build/engine --config Release --target AssaultCubeEngine
```

The resulting `libAssaultCubeEngine.a` is a static engine library, **not an app**. It still needs an SDL-owned iOS application target, lifecycle integration, and physical-device testing.

## Build the data-management shell

The separate **Manual iOS app-shell archive (not playable)** workflow can archive the SwiftUI data-management prototype. Its unsigned IPA does not compile or launch the C++ AssaultCube engine and is not a playable game.

## Game data and runtime paths

The importer stores data in `Documents/GameData`. The engine accepts `--mod=<path>` for the data search path and `--home=<path>` for its writable profile. The planned runtime layout is `Documents/GameData` plus `Documents/Profile`; this handoff has not yet been implemented.

See [ENGINEERING_PLAN.md](ENGINEERING_PLAN.md), [the input port audit](../docs/ios-mobile-input-port-audit.md), [the game-data path audit](../docs/ios-game-data-path-audit.md), and [the engineering status](../docs/ios-port-engineering-status.md) for details.

The Windows executable and DLLs are not part of the iOS runtime. Only game data is imported; AssaultCube itself must run as native ARM64 iOS code.
