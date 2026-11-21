# AssaultCube iOS Port

An independent iOS port of [AssaultCube](https://assault.cubers.net/), based on the upstream [AssaultCube source](https://github.com/assaultcube/AC).

**Status:** Functional and device-tested by the maintainer. The current build has been reported stable on an iPhone 11. It remains an experimental community port because device coverage, signing/install paths, and long-term compatibility have not been independently tested across the full iOS device range.

**Canonical branch:** `master` now contains the integrated port and is the branch for ongoing development and stable releases. The older `ios/*` branches are historical snapshots; they are retained for now rather than deleted without a branch-deletion operation available in this integration.

## Download

- **[Download the latest stable IPA](https://github.com/TangiDev69/Assaultcube-ios-port/releases/latest/download/AssaultCube-iOS-Game.ipa)**
- [All releases](https://github.com/TangiDev69/Assaultcube-ios-port/releases)
- [Latest successful iOS build (CI)](https://github.com/TangiDev69/Assaultcube-ios-port/actions)

The IPA is unsigned and intended for compatible sideloading workflows such as LiveContainer. This is not an App Store release.

## Features

- Native iOS application shell and ARM64 engine build.
- Game-data import from the official Windows installer; the installer is parsed/extracted, not executed.
- Touch HUD with movement, aiming, fire, jump, crouch, reload and weapon controls.
- Adjustable and movable on-screen controls.
- Gyroscope aiming with sensitivity and independent axis inversion.
- Touch/menu navigation and keyboard/text-entry support.
- Graphics, audio, gameplay and mobile settings.
- Multiplayer connectivity and in-game authentication.

The maintainer reports these features working in the current iPhone 11 build; compatibility and performance may vary on other devices.

## Resolution

The app requests a high-DPI drawable and uses the device's available native pixel dimensions automatically. It does **not** hardcode the iPhone 11 resolution. A manual render-resolution / render-scale selector is not currently provided.

## Install and import game data

1. Download the IPA from the **latest stable release** above.
2. Install/open it using a compatible sideloading method (for example, LiveContainer).
3. Obtain the official AssaultCube Windows installer from the [official downloads page](https://assault.cubers.net/download.html) and keep the `.exe` in Files.
4. Use the app's import flow to select the installer and extract the game data.
5. Launch the game.

The port extracts game assets from the installer without running Windows installer code. The game data is not bundled in this repository or the IPA.

## Building

The reproducible iOS build is defined in [GitHub Actions](.github/workflows/ios-dependencies-build.yml). It builds pinned SDL2, SDL2_image, Ogg/Vorbis, GL4ES, the AssaultCube engine, the native data extractor and the iOS app, then publishes an IPA.

- Development-branch builds are published as prereleases.
- Builds on `master` are published as stable releases (latest-release link).
- Build logs and dependency artifacts are available from the Actions run.

See [iOS development notes](ios/README.md) and [the engineering plan](ios/ENGINEERING_PLAN.md).

## Credits and license

- **Upstream:** AssaultCube project and contributors. See upstream notices and license files.
- **Port maintainer:** TangiDev69.
- **AI coding assistance:** Codex (OpenAI / ChatGPT), assisting with implementation, debugging, and documentation.

This is an independent port, not an official AssaultCube release. Review the applicable upstream licenses before redistributing software or game assets.
