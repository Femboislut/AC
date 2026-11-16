# AssaultCube iOS feasibility scaffold

This directory contains a minimal iOS application scaffold to evaluate whether the desktop-oriented AssaultCube engine can be adapted to iOS.

The code here is intentionally a host layer only. It does not yet contain a full engine port of AssaultCube, and it does not attempt to replace the existing SDL/OpenGL desktop build.

## Purpose

- Provide a starting point for an iOS runtime host.
- Isolate the required engine-glue work from the desktop codebase.
- Make the remaining work explicit: renderer backend adaptation, input translation, and file-system packaging.

## Current status

- App shell: scaffolded
- Native game loop bridge: stubbed
- Desktop SDL engine: still untouched
- iOS renderer/backend port: still required

## Next engineering steps

1. Port the desktop renderer to OpenGL ES / Metal.
2. Replace SDL event handling with iOS touch + motion input translation.
3. Add packaged assets and config files to the app bundle.
4. Build and validate on device.
5. Move the game loop behind a native platform abstraction.

## Notes

This scaffold is designed to sit beside the existing `source/src` codebase without changing the current desktop build path.
