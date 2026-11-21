// SDL2main supplies the iOS process entry point. This translation unit keeps
// the XcodeGen application target concrete while SDL2main calls SDL_main from
// the linked AssaultCubeEngine archive.
#import <UIKit/UIKit.h>

void ac_ios_game_target_anchor(void)
{
    (void)UIApplication.sharedApplication;
}
