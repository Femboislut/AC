# iOS application lifecycle integration audit

## SDL lifecycle delivery

The pinned SDL2 revision used by the iOS dependency workflow (fe30456e94e89ef2cab50172121bffb7f7f50830) registers UIKit notifications in src/video/uikit/SDL_uikitevents.m. It forwards background and foreground transitions through SDL's application lifecycle event functions. The SDL iOS bootstrap enables its event pump before forwarding control to the engine's main.

## Engine-side handling

The native client event loop in source/src/main.cpp::checkinput() previously handled window minimize/restore events but did not handle SDL's application-level background/foreground events. UIKit lifecycle transitions are not guaranteed to arrive as desktop-style SDL_WINDOWEVENT_MINIMIZED / SDL_WINDOWEVENT_RESTORED events.

The iOS integration now handles:

- SDL_APP_WILLENTERBACKGROUND: release relative input capture and set the existing minimized flag, which suppresses frame rendering.
- SDL_APP_DIDENTERFOREGROUND: clear minimized and refresh the SDL drawable dimensions before rendering resumes.

These cases use SDL2 public event constants and leave the existing desktop window-event behavior unchanged.

## Remaining lifecycle validation

This is source-level integration only. It still needs a real iOS build and device testing for:

- home gesture / app switcher backgrounding and foreground restoration;
- device lock and unlock;
- drawable/context validity after returning from background;
- audio interruption and resume behavior;
- memory-warning handling and resource recovery;
- whether the engine's simulation timers need an explicit background-time reset.

No claim is made that OpenGL ES resources survive every suspension scenario without additional renderer recovery work.
