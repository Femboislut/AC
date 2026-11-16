#import "EngineBridge.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#include <map>

namespace {
struct TouchState {
    ACIOSInputTouch value;
};

std::map<NSInteger, TouchState> touchStates;
}

@implementation EngineBridge

+ (void)startEngine {
    glClearColor(0.1f, 0.12f, 0.18f, 1.0f);
}

+ (void)shutdown {
    @synchronized(self) {
        touchStates.clear();
    }
}

+ (void)renderFrameWithWidth:(NSInteger)width height:(NSInteger)height {
    if (width <= 0 || height <= 0) return;
    glViewport(0, 0, (GLsizei)width, (GLsizei)height);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

+ (void)submitTouchWithID:(NSInteger)identifier
                        x:(CGFloat)x
                        y:(CGFloat)y
                   deltaX:(CGFloat)deltaX
                   deltaY:(CGFloat)deltaY
                   active:(BOOL)active {
    @synchronized(self) {
        auto existing = touchStates.find(identifier);
        if (existing == touchStates.end()) {
            TouchState state = {};
            state.value.identifier = identifier;
            state.value.x = x;
            state.value.y = y;
            state.value.active = active;
            touchStates[identifier] = state;
        } else {
            existing->second.value.x = x;
            existing->second.value.y = y;
            existing->second.value.deltaX += deltaX;
            existing->second.value.deltaY += deltaY;
            existing->second.value.active = active;
        }
    }
}

+ (NSUInteger)copyTouchSnapshot:(ACIOSInputTouch *)buffer capacity:(NSUInteger)capacity {
    if (!buffer || capacity == 0) return 0;

    @synchronized(self) {
        NSUInteger count = 0;
        for (auto it = touchStates.begin(); it != touchStates.end() && count < capacity;) {
            buffer[count++] = it->second.value;
            if (!it->second.value.active) {
                it = touchStates.erase(it);
            } else {
                it->second.value.deltaX = 0;
                it->second.value.deltaY = 0;
                ++it;
            }
        }
        return count;
    }
}

@end
