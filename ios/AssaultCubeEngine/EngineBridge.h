// ios/AssaultCubeEngine/EngineBridge.h
#pragma once
#ifdef __cplusplus
extern "C" {
#endif
int ac_ios_main(int argc, char **argv);
void ac_ios_resize(int width, int height);
void ac_ios_tick(void);
void ac_ios_set_touch(int touch_id, float x, float y, bool active);
void ac_ios_set_look(float dx, float dy);
void ac_ios_set_fire(bool active);
void ac_ios_set_jump(bool active);
#ifdef __cplusplus
}
#endif
