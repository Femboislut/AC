# Native iOS engine build-target audit

## Source selection

`ios/Engine/CMakeLists.txt` includes all 53 C++ translation units in the current `source/src/Makefile` `CLIENT_OBJS` list. A repository-tree check confirmed that every listed path exists at the audited branch head. This is the current desktop client source set, not the older Android `acmobile` revision; the Android build adds a JNI wrapper and an old touch module that are not present in this source tree.

The engine is built as a static library so the eventual iOS application can provide the SDL UIKit process entry point and link the engine into the app. The engine target is not yet linked to an iOS app target.

## Platform-header selection

`source/src/platform.h` imports `TargetConditionals.h` under `__APPLE__` and selects the iOS header branch when `TARGET_OS_IOS` is true. That branch defines `AC_PLATFORM_IOS`, includes SDL, GL4ES OpenGL headers, Apple's OpenAL headers and the Vorbis file API. The desktop SDL_image include is not needed on iOS: the sole `IMG_Load()` call in `main.cpp` is inside `#ifndef __APPLE__`.

`main.cpp` requests an OpenGL ES 2.0 context under `AC_PLATFORM_IOS`, creates the SDL window/context, then supplies SDL's GL procedure lookup and drawable-size callbacks to GL4ES before initializing it. This is a source-level integration path only; it has not yet been compiled or exercised on hardware.

## ENet platform sources

The CMake target compiles ENet's POSIX `unix.c` implementation. It also lists `win32.c`, but that translation unit is enclosed in `#ifdef WIN32` and contributes no Windows socket implementation to an iOS build. The POSIX implementation is the active socket backend. This arrangement follows the upstream Android CMake source list and should be revisited only if the first iOS compile exposes a portability issue.

## SDL bootstrap and link interface

The pinned SDL2 CMake revision selects `src/main/uikit/*.c` for UIKit platforms and creates the `SDL2main` target when SDL2main is not disabled. The native engine target links that archive alongside SDL2. The final executable must link this SDL bootstrap exactly once and must not also start a competing SwiftUI `@main`/UIKit application lifecycle.

SDL's own CMake target normally carries iOS framework dependencies. Since this project imports raw static archives, the engine target explicitly links the UIKit, Foundation, CoreGraphics, QuartzCore, CoreAudio, AudioToolbox, AVFoundation, CoreMotion, CoreVideo, OpenGLES and Metal frameworks; GameController is linked when found.

## Remaining compile-time unknowns

- The CMake target has not been configured or built with Xcode; framework availability and all transitive symbols remain unverified.
- GL4ES archive/header paths and exported symbols need confirmation from a successful dependency build.
- OpenAL framework availability and Vorbis/Ogg archive compatibility need confirmation on the selected iOS deployment target.
- ENet feature macros and socket portability need compiler validation.
- The static engine archive does not prove the final app entry point, SDL lifecycle, runtime filesystem paths, touch input, audio, networking or rendering are functional.

## Acceptance test for this milestone

Run the manual `iOS ARM64 dependency build` workflow and require it to compile `AssaultCubeEngine`, package the archive and report `arm64` for every static library. Do not mark this milestone complete until the workflow succeeds on the current branch head. The next integration test is a minimal SDL-owned iOS app that creates one ES2 context, initializes GL4ES, renders a clear-color frame, backgrounds/resumes and shuts down cleanly on a physical device.
