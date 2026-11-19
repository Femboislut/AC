# AssaultCube iOS Port (Experimental)

An independent iOS porting effort for [AssaultCube](https://assault.cubers.net/), based on the upstream [AssaultCube source repository](https://github.com/assaultcube/AC).

> **Status: experimental / not yet confirmed playable.** This repository has verified game-data import on an iPhone and builds native iOS dependencies and engine code in CI. The current game-app target is still being brought up; no gameplay, gyro, touch layout, audio, or multiplayer feature is claimed verified on-device yet.

## Project goals

- Native ARM64 iOS game runtime using SDL2 and GL4ES.
- Import game data from the official Windows installer without executing Windows binaries.
- Touch controls designed for phones, with editable layouts and multitouch.
- Optional gyroscope aiming, including calibration, sensitivity, and independent axis inversion.
- Bluetooth game-controller support and configurable bindings.
- Accessible in-game settings for graphics, controls, audio, HUD, and gameplay.
- Multiplayer server browser, favourites, direct-connect and reconnect UX where supported by the engine.

These are project goals; features become “implemented” only after build and device testing.

## Current verified milestone

- **Game-data importer tested on iPhone:** validates 1,829 files (~49 MB) imported from the Windows installer.
- **Native dependency CI:** SDL2, GL4ES, Ogg/Vorbis, ENet and engine source have been built as ARM64 libraries in earlier successful runs.
- **Current game IPA build:** in active development. The last build failed at the app link step because SDL Bluetooth HID symbols were missing the CoreBluetooth framework. The link configuration has been corrected; the follow-up build is pending.

See [iOS development status and build notes](ios/README.md).

## Testing builds

Open [GitHub Actions](https://github.com/TangiDev69/AC/actions), select the **iOS ARM64 dependency build** workflow, and open a successful run's artifacts. Artifacts are CI test builds, not official releases, until a tested IPA is published under [Releases](https://github.com/TangiDev69/AC/releases).

## Importing game data on iPhone

1. Keep the official AssaultCube Windows installer `.exe` in Files.
2. Long-press it and choose **Share**.
3. Share to the AssaultCube importer (or share to LiveContainer, then open the importer there).
4. Complete the import and confirm that it reports valid game data.

The importer extracts game assets only; it does not run the Windows installer or Windows executable code.

## Upstream project and licensing

AssaultCube is an upstream project. This repository is an independent iOS porting fork, not an official release. Preserve upstream notices and licenses; review the applicable upstream license before redistributing binaries or game data.
