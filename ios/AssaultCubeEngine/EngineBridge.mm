#import "EngineBridge.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@implementation EngineBridge

+ (void)startEngine {
    // Host-only placeholder: AssaultCube's engine initialization and frame loop
    // have not yet been adapted to the UIKit/GLKView lifecycle.
    glClearColor(0.1f, 0.12f, 0.18f, 1.0f);
}

+ (void)shutdown {
    // Engine teardown will be added when native initialization is integrated.
}

+ (void)renderFrameWithWidth:(NSInteger)width height:(NSInteger)height {
    if (width <= 0 || height <= 0) return;

    glViewport(0, 0, (GLsizei)width, (GLsizei)height);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

@end
