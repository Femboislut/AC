# iOS port development notes

This document records the current status, build pipeline, import procedure, and implementation plan. It distinguishes CI build evidence from actual device validation.

## Status

**Experimental; not yet verified playable on a physical iPhone.**

### Verified
- The SwiftUI data importer has been installed and tested on an iPhone.
- It validated **1,829 files / approximately 49 MB** from the official Windows installer.
- CI previously compiled ARM64 SDL2, GL4ES, Ogg/Vorbis, ENet, and the AssaultCube engine library.
- The SDL/GL4ES smoke-test IPA is a renderer/bootstrap test, not gameplay.

### Current build issue and fix
Run #43 failed in the final app link: SDL's Bluetooth HID object referenced CoreBluetooth symbols, but the game target didn't link CoreBluetooth. Added the framework to the AssaultCubeGame target. The follow-up CI run will verify the correction.

## Import game data from an iPhone

1. Download the official Windows AssaultCube installer from [the official downloads page](https://assault.cubers.net/download.html).
2. Keep the `.exe` in Files.
3. Long-press it, tap **Share**, and select the importer. If you're using LiveContainer, share the file to LiveContainer and open the importer there.
4. Complete the import and verify the valid-data message.

This extracts data only. The installer and Windows executables/DLLs are never run.

## Mobile input implementation in progress

The iOS game target now has a native Aim/Menu switch, a virtual movement stick, fire/jump/crouch/reload/grenade/weapon shortcut buttons, adjustable HUD scale, and optional CoreMotion gyro aiming. These controls inject SDL input events so the existing AssaultCube key bindings and gameplay code remain authoritative. Menu mode is the default and avoids the engine's normal first-click-to-capture behavior. See [the touch-control implementation and validation notes](../docs/ios-mobile-controls.md).

The following remain planned or require further work:

- SDL-owned iOS app lifecycle and engine launch.
- Native game-data and profile path handoff (`Documents/GameData` and `Documents/Profile`).
- Touch HUD: per-control dragging, opacity adjustment, individual button remapping, and saved custom layouts.
- Gyroscope aiming: physical-device axis calibration, horizontal/vertical inversion and fine-grained mode options.
- Bluetooth controller support: configurable mapping, dead zones and vibration where supported.
- In-game settings pages: controls, gyro, graphics, FOV, crosshair, HUD, audio, gameplay and accessibility.
- Multiplayer UI improvements: server list refresh, favourites, ping, direct connect and reconnect.
- Stable lifecycle: suspend/resume, safe config saving, and performance options.


## iOS keyboard toggle and diagnostics

- A floating **⌨ Hide / Show** control stays near the top of the screen. It hides or reopens the iOS keyboard; when no text field is active, tapping it opens the engine command input.
- Its saved config variables can be customized from the in-game console: `ioskeyboardbutton 1` enables it, `ioskeyboardx 92` and `ioskeyboardy 7` move it (0–100 percent), and `ioskeyboardsize 48` adjusts its size (32–80 points). Set `ioskeyboardbutton 0` to hide it.
- iOS builds no longer write the persistent startup breadcrumb file or client diagnostic log. Existing `Documents/AssaultCubeStartup.log` is deleted on launch.

## Build workflow

The [iOS ARM64 dependency build](../.github/workflows/ios-dependencies-build.yml) builds the pinned dependencies, engine, importer, smoke test, and game app.

CI artifacts are temporary test outputs. Only a device-tested IPA should be promoted to a GitHub Release.

## Runtime architecture notes

SDL2 should own the UIKit application entry point, window, GLES context and event loop. GL4ES provides compatibility for the engine's desktop OpenGL calls. The importer is a separate prototype target; do not assume its SwiftUI interface or settings currently appear in the game.

## Development quality gate

Before describing a build as playable, verify on-device:
1. App launches and doesn't immediately crash.
2. Imported assets are discovered and the initial map/menu loads.
3. Menu clicks, touch movement, looking, firing, multi-touch, and buttons work without interfering.
4. Gyroscope responds correctly in both axes, including calibration and inversion.
5. Controller input and reconnect behaviour are tested.
6. Graphics, sound, settings persistence, background/resume and quit are checked.
7. Multiplayer server discovery and direct connection are tested, with limitations documented.

Until those checks pass, keep the project marked experimental.
