//
//  GHConsoleWindow.h
//  GHConsole
//
//  Created by zhoushaowen on 2017/12/5.
//  Copyright © 2017年 廖光辉. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GHConsoleRootViewController;

@interface GHConsoleWindow : UIWindow

+ (instancetype)consoleWindow;

/**
 最大化
 */
- (void)maxmize;

/**
 最小化
 */
- (void)minimize;

@property (nonatomic,strong) GHConsoleRootViewController *consoleRootViewController;


@end
