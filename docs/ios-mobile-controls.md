# iOS touch controls and input modes

## Current implementation

The iOS overlay is an adapter to AssaultCube's existing SDL input path. It does not replace the game controls or create a separate gameplay simulation.

- **Menu mode** is the startup mode. It releases relative mouse capture, leaves the pointer visible where supported, and lets mouse/touch clicks reach the existing AssaultCube menus. A native on-screen navigation pad provides left/right, up/down, OK and Back because the original menu system navigates the highlighted row rather than hit-testing finger coordinates.
- **Aim mode** captures relative mouse movement for camera look and displays the touch HUD.
- The left virtual stick emits the existing `W/A/S/D` key bindings.
- FIRE emits the normal left-mouse button event.
- JUMP, CROUCH, RELOAD, NADE, PREV, PRI and SEC emit the existing Space, Left Shift, R, G, Q, 1 and 2 key bindings.
- The UIKit controls only consume touches inside their own hit regions. Touches elsewhere continue to the SDL game view for camera movement.
- Gyroscope aiming is optional and disabled by default. It sends relative-look input through the same SDL mouse-motion path.
- The original Settings menu includes an iOS Touch Controls page for HUD visibility/scale, gyro enable/sensitivity, and keyboard-button visibility/position/size.

## In-game settings

The iOS Touch Controls page in AssaultCube's original Settings menu edits these persistent config variables:

| Variable | Default | Purpose |
|---|---:|---|
| `ioshud` | 1 | Show or hide the virtual gameplay HUD |
| `ioshudscale` | 100 | HUD size, range 60–140 percent |
| `iosgyro` | 0 | Enable gyroscope aiming |
| `iosgyrosensitivity` | 100 | Gyroscope sensitivity, range 10–300 |
| `ioskeyboardbutton` | 1 | Show or hide the keyboard button |
| `ioskeyboardx` | 92 | Keyboard button horizontal position, percent |
| `ioskeyboardy` | 7 | Keyboard button vertical position, percent |
| `ioskeyboardsize` | 48 | Keyboard button size, range 32–80 |

The same variables can also be changed from the engine console. The existing AssaultCube configuration system saves them. The original Settings, Keyboard, Mouse, HUD, Gameplay, Video, Sound, Multiplayer and Singleplayer menus remain the game's own menus; they are not replaced by the iOS overlay.

## Validation status and limitations

Source implementation and CI compilation are separate from physical-device verification. Before calling this a stable release, test on an actual iPhone:

1. Tap several welcome-menu items in Menu mode, including text fields and sliders.
2. Switch to Aim mode and verify the camera responds only to the look area.
3. Hold the virtual stick in each direction and diagonally; verify movement stops on release and when the app loses focus.
4. Test fire, jump, crouch, reload, grenade and weapon selection in a local match.
5. Test gyro on/off and sensitivity at low and high values.
6. Background/resume the app and repeat menu/gameplay input.
7. Test controller input, multiplayer browser, joining/reconnecting, audio and repeated launches.

The fixed HUD layout and size are configurable; individual button repositioning/remapping is not yet implemented. Gyroscope axis feel also requires device testing and may need calibration/orientation refinement.
