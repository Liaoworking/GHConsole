//
//  GHConsole.h
//  GHConsole
//
//  Created by 廖光辉 on 02/06/2017.
//  Copyright © 2017 廖光辉. All rights reserved.
//

#import <UIKit/UIKit.h>
#define DDLogInfo(frmt, ...)    LOG_OBJC_MAYBE(LOG_ASYNC_INFO,    LOG_LEVEL_DEF, LOG_FLAG_INFO,    0, frmt, ##__VA_ARGS__)

@interface GHConsole : NSObject
- (void)startPrintString;
+ (instancetype)sharedConsole;

@end
