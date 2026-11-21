# iOS development notes

## Current status

The port is functional and has been device-tested by the maintainer. The current build is reported stable on an iPhone 11. This is user-reported device validation, not a claim of universal iOS compatibility.

The latest successful CI build is [build 164](https://github.com/TangiDev69/Assaultcube-ios-port/actions/runs/44845433560). It compiled the dependencies, engine, extractor and app, verified the IPA bundle, and published the IPA.

## Device resolution

The iOS SDL window requests `SDL_WINDOW_ALLOW_HIGHDPI`; SDL's UIKit OpenGL view then uses the device native scale for its drawable. This means the app uses the device's drawable pixel dimensions rather than a resolution hard-coded for the maintainer's iPhone 11.

A user-selectable internal render resolution / scale is not implemented. Native display resolution is selected automatically.

## Install and data import

1. Install the IPA using a compatible sideloading workflow.
2. Download the official AssaultCube Windows installer from [the official downloads page](https://assault.cubers.net/download.html).
3. Use the in-app importer to select the installer from Files.
4. The extractor reads the installer and extracts game data; it does not execute Windows binaries.

## Mobile controls

The iOS overlay includes an Aim/Menu mode switch, virtual movement stick, look/touch aiming, fire, jump, crouch, reload, grenade and weapon shortcuts, editable control layout, HUD scale, and optional gyro aiming with separate axis inversion. Text entry can use the iOS keyboard toggle. Controls feed the engine's input layer.

The maintainer has reported the current control setup working on the tested iPhone. Other device layouts and controller combinations may need adjustment.

## Build

The [iOS ARM64 dependency build workflow](../.github/workflows/ios-dependencies-build.yml) is the source of truth. It pins third-party dependency revisions and builds the engine and app. Development-branch runs create prereleases; master runs create stable releases.

The workflow also uploads temporary engine diagnostics and dependency archives. The IPA is attached directly to the GitHub Release.

## Remaining scope

- Manual render-scale / internal resolution selector.
- Additional device and iOS-version compatibility testing.
- More comprehensive multiplayer/server-browser reliability testing.
- Performance and battery testing on devices beyond the maintainer's iPhone.
- Sideloading/signing guidance for different workflows.

