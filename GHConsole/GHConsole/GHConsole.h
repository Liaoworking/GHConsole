//
//  GHConsole.h
//  GHConsole
//
//  Created by liaoWorking on 22/11/2017.
//  Copyright © 2017 liaoWorking. All rights reserved.
//

#import <UIKit/UIKit.h>

//release model with no log
#ifdef DEBUG
#define GGLog(frmt, ...)    LOG_OBJC_MAYBE(frmt, ##__VA_ARGS__)
#else
#define GGLog(frmt, ...)
#endif

#define LOG_OBJC_MAYBE(frmt, ...) \
LOG_MAYBE(__PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)

#define LOG_MAYBE(fnct,frmt, ...)                       \
do { if(1 & 1) LOG_MACRO(fnct, frmt, ##__VA_ARGS__); } while(0)


#define LOG_MACRO(fnct, frmt, ...) \
[[GHConsole sharedConsole] function : fnct                          \
line : __LINE__                                           \
format : (frmt), ## __VA_ARGS__]


@interface GHConsole : NSObject

+ (instancetype)sharedConsole;

- (void)startPrintLog;

- (void)stopPringting;

- (void)function:(const char *)function
            line:(NSUInteger)line
          format:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4);

@end
