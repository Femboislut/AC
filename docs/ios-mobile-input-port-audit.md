# Mobile touch-input transplant audit

## Finding

The upstream `acmobile` branch is a useful implementation reference, but its touch interface is **not a drop-in addition** to this repository's current engine revision.

A source inspection of the current iOS branch confirms:

- `source/src/main.cpp` has no calls to `touchenabled()`, `showtouchmenu()`, `menuevent()`, `touchmenuvisible()`, `rendertouchmenu()`, `rendertouchhud()`, or `checktouchinput()`.
- `source/src/cube.h` does not declare that touch interface.
- `source/src/Makefile` does not compile `source/src/touch/touch.cpp`.
- The only touch-related native implementation currently in the iOS scaffold is `ios/AssaultCubeEngine/TouchInput.swift` and the placeholder queue in `EngineBridge.mm`. Neither is connected to SDL events or the engine's `checkinput()` path.

By contrast, upstream `acmobile` adds a touch module under `source/src/touch/`, wires its entry points into its older `main.cpp`, and includes `touch/touch.cpp` in its Android CMake target. Its `touch.cpp` is the composition root for a set of header-defined UI components: game, input, view, navigation button, text view, touch menu, model view, slider view, HUD, and main/game scene classes.

## Upstream integration points

The older mobile `main.cpp` contains these hooks:

- Forward SDL events to `menuevent(SDL_Event *)` while the touch menu is visible.
- Call `showtouchmenu(false)` after startup when `touchenabled()` is true.
- Call `checktouchinput()` in the main loop when touch is enabled.
- Its rendering path also calls the touch menu/HUD drawing functions.

The public functions are defined in upstream `source/src/touch/touch.cpp`: `touchenabled`, `showtouchmenu`, `menuevent`, `rendertouchmenu`, `touchmenuvisible`, `rendertouchhud`, and `checktouchinput`. These names are not present in the current branch's engine interface.

## Why a blind copy is unsafe

1. **Engine revision mismatch:** the upstream mobile `main.cpp` is 1,466 lines; the current branch's is 1,648 lines. Its startup, event, rendering and input loops cannot safely be replaced wholesale.
2. **Missing call sites:** adding only `touch.cpp` and its headers would compile at best as unused code; it would not deliver touch controls.
3. **Input ownership:** SDL already owns the event queue and the game loop. The Swift `TouchInput` snapshot queue is a separate prototype and should not become a second source of input truth. The iOS path should translate UIKit touches into SDL finger events (or a deliberately defined engine input API), then let the engine consume those events on its game thread.
4. **UI/render dependencies:** the upstream module draws menu/HUD elements using the engine's rendering and UI state. It must be integrated only after the selected SDL app/window lifecycle and GL4ES renderer path are stable.
5. **Platform controls:** volume-button behavior and Android-specific integration should not be imported as-is for iOS. GameController support should be routed through SDL's controller subsystem where possible.

## Recommended transplant sequence

1. Pin and record the exact upstream `acmobile` commit used for the audit; compare its touch module against this engine revision before copying files.
2. Start with the gameplay input layer, not the full menu/HUD: define movement/look/fire/jump/crouch/reload/weapon actions and map SDL finger IDs to active touch slots.
3. Integrate at the current branch's event polling and `checkinput()` boundaries. Keep all engine-state mutation on the engine thread; UIKit callbacks should only enqueue immutable touch events.
4. Add a small SDL-side input adapter and tests for touch begin/move/end/cancel, simultaneous fingers, orientation/size changes, and lost-touch cancellation.
5. Port the touch HUD/menu as a separate milestone after GL4ES rendering works. Audit every upstream dependency and remove Android-only controls.
6. Delete or replace the current Swift `TouchInput` / Objective-C++ snapshot prototype once the SDL-to-engine path is proven, rather than maintaining two parallel touch queues.

## Sources inspected

- Upstream mobile touch module: https://github.com/assaultcube/AC/tree/acmobile/source/src/touch
- Upstream mobile main-loop wiring: https://github.com/assaultcube/AC/blob/acmobile/source/src/main.cpp
- Upstream Android native source list: https://github.com/assaultcube/AC/blob/acmobile/source/android/app/src/main/cpp/CMakeLists.txt

**Status:** source-level audit only. No touch source has been transplanted, compiled, or tested on iOS.
