//
//  GHLogManager.h
//  GHConsole
//
//  Created by Guanghui Liao on 6/4/17.
//  Copyright © 2017 廖光辉. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <asl.h>
#import "GHLogMessager.h"
@interface GHLogManager : NSObject

/**
 通过asl的接口来获取系统打印的日志

 @param time 一般填0就行
 @return 有序的日志模型数组
 */
+ (NSArray<GHLogMessager *> *)allLogAfterTime:(CFAbsoluteTime) time;
@end
