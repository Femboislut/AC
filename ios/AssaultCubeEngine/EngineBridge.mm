// ios/AssaultCubeEngine/EngineBridge.mm
#import "EngineBridge.h"

extern "C" int ac_ios_main(int argc, char **argv) {
    return 0;
}

extern "C" void ac_ios_resize(int width, int height) {
}

extern "C" void ac_ios_tick(void) {
}

extern "C" void ac_ios_set_touch(int touch_id, float x, float y, bool active) {
}

extern "C" void ac_ios_set_look(float dx, float dy) {
}

extern "C" void ac_ios_set_fire(bool active) {
}

extern "C" void ac_ios_set_jump(bool active) {
}
