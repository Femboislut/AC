# iOS port scaffold

This directory contains the iOS feasibility work and a buildable app-shell project definition.

## Build the app shell

The Xcode project is generated from XcodeGen:

```sh
cd ios
xcodegen generate --spec project.yml
```

GitHub Actions runs the same project generation on a macOS runner, tests the `AssaultCubeData` Swift package, archives the iOS app without signing, and uploads an unsigned IPA artifact.

**Important:** this IPA currently contains the game-data management shell only. It does not compile or launch the C++ AssaultCube engine and is not a playable game.

See [the engineering status and blockers](../docs/ios-port-engineering-status.md) before treating any build artifact as a game port.
