#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EngineBridge : NSObject

+ (void)initialize;
+ (void)shutdown;
+ (void)renderFrame;
+ (void)setViewportWithWidth:(NSInteger)width height:(NSInteger)height;

@end

NS_ASSUME_NONNULL_END
