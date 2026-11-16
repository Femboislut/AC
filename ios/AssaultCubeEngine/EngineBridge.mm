#import "EngineBridge.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@implementation EngineBridge

+ (void)initialize {
    // This is intentionally a stub. The actual AssaultCube engine remains desktop-oriented
    // and is not yet ported to iOS. This bridge exists to hold the platform boundary.
    glClearColor(0.1f, 0.12f, 0.18f, 1.0f);
}

+ (void)shutdown {
}

+ (void)renderFrame {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

+ (void)setViewportWithWidth:(NSInteger)width height:(NSInteger)height {
    if (width <= 0 || height <= 0) {
        return;
    }
    glViewport(0, 0, (GLsizei)width, (GLsizei)height);
}

@end
