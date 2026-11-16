# iOS static dependency and link audit

## SDL2 static archive

The pinned SDL2 CMake revision names the static target SDL2-static and sets its output name to SDL2; it also creates SDL2main from src/main/uikit on iOS. The workflow's archive names therefore match the upstream target definitions. SDL2's generated SDL_config.h is emitted under include-config-<configuration>/SDL2 and is copied into the packaged SDL2/include/SDL2 directory.

SDL2's CMake target normally propagates Apple frameworks to final consumers. Because this project imports the built archive as a raw static library, the engine target explicitly carries the iOS frameworks needed by the selected SDL subsystems. SDL's GameController and CoreHaptics integrations are weak-linked upstream; the iOS engine target now mirrors that behavior when those frameworks exist.

## GL4ES archive location

The pinned GL4ES CMake project sets CMAKE_ARCHIVE_OUTPUT_DIRECTORY to its source-tree lib directory. With a multi-configuration generator such as Xcode, CMake may append the active configuration directory. The dependency workflow now searches recursively below the GL4ES lib directory for libGL.a instead of assuming the archive is always directly in lib/.

## Vorbis dependency chain

The pinned Vorbis CMake project builds vorbisfile against vorbis, and vorbis against Ogg::ogg. The engine link interface lists vorbisfile, vorbis, then ogg, preserving the static dependency chain. vorbisenc is packaged for completeness but is not required by the current game client target.

## Still unverified

These source-level checks do not replace an Xcode build. The next build must validate that the selected SDL configuration enables only available iOS subsystems, that all transitive symbols resolve, and that the final app target links the SDL2main UIKit entry point exactly once.