# iOS prototype and game-data import

The current SwiftUI prototype accepts a ZIP or folder through the system file importer, validates a basic runtime layout (`config/font.cfg`, `packages/misc/notexture.jpg`, an official `.cgz` map, and `packages/{textures,models,audio}`), copies `config`, `packages`, and `mods` into `Documents/GameData`, reports file count/storage, and resets only that game-data directory.

This app target does not start the C++ engine. It is a data-management shell, not a playable client, renderer, or deliverable game IPA.

The native engine now has a separate CMake static-library target at `ios/Engine/CMakeLists.txt`. It is not linked into this SwiftUI target. The intended application architecture is SDL-owned UIKit startup and window/context ownership; the current SwiftUI `@main` app and GLKit host cannot simply be combined with SDL's UIKit bootstrap.

Importing files does not execute Windows binaries: `.exe` and `.dll` files are not invoked. The importer selects game-data roots and copies only the supported game-data directories.

See [the iOS port README](../README.md), [the engineering plan](../ENGINEERING_PLAN.md), and [the current blocker audit](../../docs/ios-port-engineering-status.md).
