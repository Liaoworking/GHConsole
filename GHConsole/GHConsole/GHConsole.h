//
//  GHConsole.h
//  GHConsole
//
//  Created by 廖光辉 on 02/06/2017.
//  Copyright © 2017 廖光辉. All rights reserved.
//

#import <UIKit/UIKit.h>

//屏蔽release模式下的log输出
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

- (void)function:(const char *)function
            line:(NSUInteger)line
          format:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4);
+ (instancetype)sharedConsole;
- (void)startPrintLog;
- (void)stopPringting;
@end
