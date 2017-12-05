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
    GGLog(@"This is some log I just want to show in GHConsole");
    
    NSDictionary *parameterDict = @{@"paraKey1":@"paraValue1",
                                    @"paraKey2":@"paraValue2",
                                    @"paraKey3":@"paraValue2"
                                    };
    GGLog(@"%@",parameterDict);
    
    //if you  want to see the responsJSon from the API, you can just use GGLog( ) like NSLog( ) here.
    GGLog(@"if you  want to see the responsJSon from the API, you can just use GGLog( ) like NSLog( ) here!");
//    GGLog(@"%@",responsJSON);
    
  
}

- (void)viewDidAppear:(BOOL)animated{
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
