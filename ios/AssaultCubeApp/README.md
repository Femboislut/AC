# iOS prototype and game-data import

The iOS groundwork in this branch is a SwiftUI data-management prototype. It accepts a ZIP or a folder through the system file importer, validates the same runtime layout used by this source tree (`config/font.cfg`, `packages/misc/notexture.jpg`, an official `.cgz` map, and `packages/{textures,models,audio}`), copies only `config`, `packages`, and `mods` into `Documents/GameData`, reports file count/storage, and resets only that game-data directory. Files app document sharing is enabled by `ios/AssaultCubeApp/Info.plist`.

This prototype explicitly does not start the C++ engine. It is not a playable client, renderer, or deliverable IPA. The renderer and platform integration blockers are detailed in [the audit](../../docs/ios-port-audit.md). Importing files is safe from Windows binary execution: `.exe` and `.dll` files are not invoked; imported selected directories are filtered to game data roots.

The SwiftUI app source is in `ios/AssaultCubeApp/AssaultCubeDataApp.swift` and uses the `AssaultCubeData` package. Integration into an Xcode iOS app target and actual on-device validation are still required.
