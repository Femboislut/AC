#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EngineBridge : NSObject

+ (void)startEngine;
+ (void)shutdown;
+ (void)renderFrameWithWidth:(NSInteger)width height:(NSInteger)height;

@end

NS_ASSUME_NONNULL_END
