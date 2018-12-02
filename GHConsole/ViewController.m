//
//  ViewController.m
//  GHConsole
//
//  Created by 廖光辉 on 02/06/2017.
//  Copyright © 2017 廖光辉. All rights reserved.
//

#import "ViewController.h"
#import "GHConsole.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"GHConsole";
    self.view.backgroundColor = [UIColor whiteColor];
    
  
    
    //像使用NSLog()一样使用GGLog()即可。
    GGLog(@"This is a log I just want to show in GHConsole");
    
    NSDictionary *parameterDict = @{@"paraKey1":@"paraValue1",
                                    @"paraKey2":@"paraValue2",
                                    @"paraKey3":@"paraValue2"
                                    };
    GGLog(@"%@",parameterDict);
    
    //if you  want to see the responsJSon from the API, you can just use GGLog( ) like NSLog( ) here.
    GGLog(@"if you  want to see the responsJSon from the API, you can just use GGLog( ) like NSLog( ) here!");
//    GGLog(@"%@",responsJSON);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        GGLog(@"In my life best day,any day best day");
    });
    for(int i=0;i<1000;i++){
        GGLog(@"Performance test");
    }

    for(int i=0;i<5;i++){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            GGLog(@"Thread safe test%@",[NSThread currentThread]);
        });
    }
}

- (void)viewDidAppear:(BOOL)animated{
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
