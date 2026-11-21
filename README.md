# AssaultCube iOS Port

An independent, native **AssaultCube port for iPhone and iPad**. This project brings the open-source AssaultCube first-person shooter (FPS) to iOS as an ARM64 app, with touch controls, gyroscope aiming, multiplayer support, and an in-app game-data importer.

If you are searching for **AssaultCube on iOS**, an **AssaultCube iPhone port**, or a way to **play AssaultCube on iPhone or iPad**, this repository is the home of this independent iOS port.

[AssaultCube](https://assault.cubers.net/) is an open-source first-person shooter. This port is based on the upstream [AssaultCube source code](https://github.com/assaultcube/AC).

**Project status:** Functional and device-tested by the maintainer. The current build has been reported stable. It remains an experimental community port because device coverage, signing/install paths, and long-term compatibility have not been independently tested across the full iOS device range.

**Canonical branch:** `master` contains the integrated port and is the branch for ongoing development and stable releases. Older `ios/*` branches are historical snapshots.

## Download

- **[Download the latest stable iOS IPA](https://github.com/TangiDev69/Assaultcube-ios-port/releases/latest/download/AssaultCube-iOS-Game.ipa)**
- [All releases](https://github.com/TangiDev69/Assaultcube-ios-port/releases)
- [GitHub Actions build history](https://github.com/TangiDev69/Assaultcube-ios-port/actions)

The IPA is unsigned. Depending on your setup, compatible installation options may include **AltStore**, **SideStore**, or importing the IPA into **LiveContainer**. These tools have different signing and app-container requirements; follow the instructions for your chosen tool. Installation compatibility can vary by iOS version and tool version.

## Features

- Native iOS application shell and ARM64 engine build.
- Game-data import from the official Windows installer; the installer is parsed and extracted, not executed.
- Touch HUD with movement, aiming, fire, jump, crouch, reload, and weapon controls.
- Adjustable and movable on-screen controls.
- Gyroscope aiming with sensitivity and independent axis inversion.
- Touch/menu navigation and keyboard/text-entry support.
- Graphics, audio, gameplay, and mobile settings.
- Multiplayer connectivity and in-game authentication.

The maintainer reports these features working in the current iPhone 11 build; compatibility and performance may vary on other devices.

## Resolution

The app requests a high-DPI drawable and uses the device's available native pixel dimensions automatically. A manual render-resolution / render-scale selector is not currently provided.

## Install and import game data

1. Download the IPA from the **latest stable release** above.
2. Install or import it using a compatible sideloading workflow, such as AltStore, SideStore, or LiveContainer.
3. Obtain the official AssaultCube Windows installer from the [official downloads page](https://assault.cubers.net/download.html) and keep the `.exe` file in the iOS Files app.
4. Open the port and use its game-data import flow to select the installer and extract the game data.
5. Launch the game.

The port extracts game assets from the installer without running Windows installer code. Game data is not bundled in this repository or the IPA. Use the official game download and respect the upstream license.

## Building

The reproducible iOS build is defined in [GitHub Actions](.github/workflows/ios-dependencies-build.yml). It builds pinned SDL2, SDL2_image, Ogg/Vorbis, GL4ES, the AssaultCube engine, the native data extractor, and the iOS app, then publishes an IPA.

- Development-branch builds are published as prereleases.
- Builds on `master` are published as stable releases (the latest-release link above).
- Build logs and dependency artifacts are available from the Actions run.

See [iOS development notes](ios/README.md) and [the engineering plan](ios/ENGINEERING_PLAN.md).

## Project identity

This repository is an independent community-made **AssaultCube iOS port**, not an official AssaultCube release and not a Windows emulator guide. It is intended for people looking for AssaultCube for iOS, AssaultCube on iPhone, an iPhone FPS port, or an ARM64 iOS build of AssaultCube.

## Credits and license

- **Upstream:** AssaultCube project and contributors. See upstream notices and license files.
- **Port maintainer:** TangiDev69.
- **Coding assistance:** Codex (OpenAI / ChatGPT), assisting with implementation, debugging, and documentation.

This is an independent port, not an official AssaultCube release. Review the applicable upstream licenses before redistributing software or game assets.
