# iOS game-data and writable-path integration audit

## Existing data importer

The Swift package `ios/AssaultCubeData` imports either a ZIP archive or a selected folder into the app's Documents directory under `GameData`. It validates required game assets before replacing an existing installation and exposes the resulting directory through `GameDataStore.gameDataDirectory` (see `GameDataStore.swift`). The importer is separate from the engine and does not execute the Windows executable or DLLs.

## Existing engine path interface

The current engine's `source/src/main.cpp` already parses two useful command-line switches:

- `--mod=<path>` calls `addpackagedir(<path>)`, adding a package/data search directory.
- `--home=<path>` calls `sethomedir(<path>)`, selecting the writable profile directory.

If no home path is supplied, the engine falls back to `profile`. That relative default is unsuitable as an iOS writable location because the process working directory is not a stable, app-owned persistence contract. The iOS launcher should supply both paths explicitly, using absolute sandbox paths obtained from Foundation at runtime.

## Proposed sandbox layout

Use the app's Documents directory as the durable root:

- `Documents/GameData/` — imported game assets; read-only from the engine's perspective.
- `Documents/Profile/` — writable engine profile: config, logs, screenshots, demos, downloaded maps and other user-generated files.

Pass the exact absolute paths to the engine as arguments before its initialization:

- `--mod=<absolute Documents/GameData path>`
- `--home=<absolute Documents/Profile path>`

Create the Profile directory before entering the engine. Do not hard-code `/var/mobile/Containers/...`; iOS container identifiers change. Do not use the bundle resource directory for writes. If some packaged assets are copied into the app bundle in a later design, keep those read-only and retain Documents/Profile for all mutable state.

## Integration requirements

1. Confirm that `addpackagedir()` and the package VFS accept an absolute iOS sandbox path and do not assume a current working directory. Verify this against the implementation before wiring the launcher.
2. Confirm the importer validates all runtime-critical assets, not merely a minimal subset. The engine must fail with a clear missing-data message rather than crash on absent maps, config templates, fonts, textures or sound assets.
3. Ensure `--home` is parsed before config/profile initialization and that all writes stay under Profile. Audit relative writes such as screenshots, downloaded maps, logs and demo files.
4. Use Foundation to resolve Documents at launch. Never persist the absolute container path across launches; it may change after restore/reinstall. Persist only the relative directory names.
5. Treat imported game data as immutable while the engine is running. Re-import/reset should first stop the engine and release open VFS/archive handles.
6. Add tests for paths containing spaces, Unicode, long paths, missing directories, read-only data, and app-container relocation.

## Runtime interface recommendation

The eventual native launcher should construct an argv array with a stable program name and the two explicit path switches, then invoke the engine through the selected SDL UIKit bootstrap. The exact argv ownership/lifetime and SDL entry-point contract must be implemented with the chosen SDL lifecycle design; do not call the current `EngineBridge.startEngine()` placeholder or rely on a process-wide `chdir()` as a substitute.

**Status:** the data-import layer exists; no engine path handoff has been implemented or tested. This document is a design audit, not evidence that the game currently loads imported data.
