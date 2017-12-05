//
//  GHConsoleWindow.m
//  GHConsole
//
//  Created by zhoushaowen on 2017/12/5.
//  Copyright © 2017年 廖光辉. All rights reserved.
//

#import "GHConsoleWindow.h"
#import "GHConsoleRootViewController.h"

@implementation GHConsoleWindow

+ (instancetype)consoleWindow {
    GHConsoleWindow *window = [[self alloc] init];
    window.windowLevel = UIWindowLevelStatusBar + 100;
    window.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 30, 120, [UIScreen mainScreen].bounds.size.width - 60, 90);
    return window;
}

- (GHConsoleRootViewController *)consoleRootViewController {
    return (GHConsoleRootViewController *)self.rootViewController;
}

- (void)maxmize {
    self.frame = [UIScreen mainScreen].bounds;
    self.consoleRootViewController.scrollEnable = YES;
}

- (void)minimize {
    self.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 30, 120, [UIScreen mainScreen].bounds.size.width - 60, 90);
    self.consoleRootViewController.scrollEnable = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.rootViewController.view.frame = self.bounds;
}



@end
