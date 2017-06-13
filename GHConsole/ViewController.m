//
//  ViewController.m
//  GHConsole
//
//  Created by 廖光辉 on 02/06/2017.
//  Copyright © 2017 廖光辉. All rights reserved.
//

#import "ViewController.h"
#import "GHConsole.h"
#import "Foundation+Log.m"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];


    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"第1次打印");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"第2次打印");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"第3次打印");
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSLog(@"10s后打印");
                });
                
                
            });
        });
    });
}

- (void)viewDidAppear:(BOOL)animated{
    [[GHConsole sharedConsole]startPrintString];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
