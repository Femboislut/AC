# AssaultCube iOS feasibility scaffold

This directory contains an iOS host scaffold and a touch bridge for evaluating a port of the desktop-oriented AssaultCube engine.

## Current status

- UIKit/GLKit host and OpenGL ES placeholder renderer exist.
- Native bridge accepts normalized touch samples and exposes per-frame touch snapshots.
- The bridge is still not connected to the assaultcube game loop; touches are only captured as data.
- The existing engine is still SDL desktop-oriented and not yet adapted to an iOS runtime lifecycle.
- There is no full iOS build target, no packaged runtime assets, and no device validation.

## Next engineering steps

1. Add an iOS build target and resolve SDK/platform dependencies.
2. Replace or adapt the desktop fixed-function renderer for an iOS-supported rendering API.
3. Connect the touch snapshot API to engine input/game actions.
4. Adapt engine startup, pause/resume, audio, writable profile paths, and asset loading.
5. Bundle data files and validate on a physical device.

The scaffold is not yet a playable iOS port.
