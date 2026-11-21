#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define AC_IOS_MAX_TOUCHES 10

typedef struct ACIOSInputTouch {
    NSInteger identifier;
    CGFloat x;
    CGFloat y;
    CGFloat deltaX;
    CGFloat deltaY;
    BOOL active;
} ACIOSInputTouch;

@interface EngineBridge : NSObject

+ (void)startEngine;
+ (void)shutdown;
+ (void)renderFrameWithWidth:(NSInteger)width height:(NSInteger)height;
+ (void)submitTouchWithID:(NSInteger)identifier
                        x:(CGFloat)x
                        y:(CGFloat)y
                   deltaX:(CGFloat)deltaX
                   deltaY:(CGFloat)deltaY
                   active:(BOOL)active;
+ (NSUInteger)copyTouchSnapshot:(ACIOSInputTouch *)buffer capacity:(NSUInteger)capacity;

@end

NS_ASSUME_NONNULL_END
