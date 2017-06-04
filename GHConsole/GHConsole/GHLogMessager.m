//
//  GHLogMessager.m
//  GHConsole
//
//  Created by Guanghui Liao on 6/4/17.
//  Copyright © 2017 廖光辉. All rights reserved.
//

#import "GHLogMessager.h"

@implementation GHLogMessager
+(instancetype)logMessageFromASLMessage:(aslmsg)aslMessage
{
    GHLogMessager *logMessage = [[GHLogMessager alloc] init];
    
    const char *timestamp = asl_get(aslMessage, ASL_KEY_TIME);
    if (timestamp) {
        NSTimeInterval timeInterval = [@(timestamp) integerValue];
        const char *nanoseconds = asl_get(aslMessage, ASL_KEY_TIME_NSEC);
        if (nanoseconds) {
            timeInterval += [@(nanoseconds) doubleValue] / NSEC_PER_SEC;
        }
        logMessage.timeInterval = timeInterval;
        logMessage.date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    }
    
    
    const char *sender = asl_get(aslMessage, ASL_KEY_SENDER);
    if (sender) {
        logMessage.sender = @(sender);
    }
    
    const char *messageText = asl_get(aslMessage, ASL_KEY_MSG);
    if (messageText) {
        logMessage.messageText = @(messageText);
    }
    
    const char *messageID = asl_get(aslMessage, ASL_KEY_MSG_ID);
    if (messageID) {
        logMessage.messageID = [@(messageID) longLongValue];
    }
    
    return logMessage;
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[GHLogMessager class]] && self.messageID == [object messageID];
}

- (NSUInteger)hash
{
    return (NSUInteger)self.messageID;
}


- (NSString *)displayedTextForLogMessage
{
    
    return [NSString stringWithFormat:@"%@: %@ \n\n", [self.class logTimeStringFromDate:self.date], self.messageText];
}

+ (NSString *)logTimeStringFromDate:(NSDate *)date
{
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        //        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
        formatter.dateFormat = @"HH:mm:ss.SSS";
        
    });
    
    return [formatter stringFromDate:date];
}

@end
