#import <Foundation/Foundation.h>
@import WordPressSharedObjC;

@interface WPAnalyticsTrackerAutomatticTracks : NSObject<WPAnalyticsTracker>

- (instancetype)initWithEventNamePrefix:(NSString *)eventNamePrefix platform:(NSString *)platform;

@end
