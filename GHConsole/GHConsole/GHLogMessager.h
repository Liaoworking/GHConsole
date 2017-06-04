//
//  GHLogMessager.h
//  GHConsole
//
//  Created by Guanghui Liao on 6/4/17.
//  Copyright © 2017 廖光辉. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <asl.h>

@interface GHLogMessager : NSObject

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic, copy) NSString *sender;
@property (nonatomic, copy) NSString *messageText;
@property (nonatomic, assign) long long messageID;

+ (instancetype)logMessageFromASLMessage:(aslmsg)aslMessage;
+ (NSString *)logTimeStringFromDate:(NSDate *)date;
- (NSString *)displayedTextForLogMessage;
@end
