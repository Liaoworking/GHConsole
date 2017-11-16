//
//  GHConsole.m
//  GHConsole
//
//  Created by 廖光辉 on 02/06/2017.
//  Copyright © 2017 廖光辉. All rights reserved.
//

#import "GHConsole.h"
#define k_WIDTH [UIScreen mainScreen].bounds.size.width
#import <unistd.h>
#import <sys/uio.h>
#import <pthread/pthread.h>
#define USE_PTHREAD_THREADID_NP                (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)
@interface GHConsoleTextField:UITextView
@end

@implementation GHConsoleTextField
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

@end

#pragma mark- GHConsole
@interface GHConsole (){
    NSDate *_timestamp;
}
@property (nonatomic, strong)GHConsoleTextField *textField;
@property (nonatomic, strong)NSString *string;

//添加一个全局的logString 防止局部清除
@property (nonatomic, copy)NSMutableString *logSting;
//记录打印数，来确定打印更新
@property (nonatomic, assign)NSInteger currentLogCount;
//是否显示
@property (nonatomic, assign)BOOL isShow;
//是否全屏
@property (nonatomic, assign)BOOL isFullScreen;
//添加的向外的手势，为了避免和查看log日志的手势冲突  isShow之后把手势移除
@property (nonatomic, strong)UIPanGestureRecognizer *panOutGesture;
@end
@implementation GHConsole


+ (instancetype)sharedConsole {
    
    static GHConsole *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [GHConsole new];
        });
    return _instance;
}

//开始显示log日志 更新频率0.5s
- (void)startPrintLog{
    self.isShow = YES;
    self.isFullScreen = NO;
    self.textField.text = @"控制台开始显示";
    _logSting = [NSMutableString new];
    
}

- (void)function:(const char *)function
            line:(NSUInteger)line
          format:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4){
    va_list args;
    
    if (format) {
        va_start(args, format);
        
        NSString *message = nil;
        
        message = [[NSString alloc] initWithFormat:format arguments:args];
        //UI上去展示日志内容
        [self printMSG:message andFunc:function];
        va_end(args);
        
        va_start(args, format);
        //  这里去处理message
        [self printMSGAtSystemConsole:message andFuncName:function andLine:line];
        va_end(args);
    }
    
}

- (void)printMSGAtSystemConsole:(NSString *)message andFuncName:(const char *)function andLine:(NSInteger)line{
    
    //    if (USE_PTHREAD_THREADID_NP) {
    //        __uint64_t tid;
    //        pthread_threadid_np(NULL, &tid);
    //        _threadID = [[NSString alloc] initWithFormat:@"%llu", tid];
    //    } else {
    //        _threadID = [[NSString alloc] initWithFormat:@"%x", pthread_mach_thread_np(pthread_self())];
    //    }
    
    int len;
    char ts[24] = "";
    size_t tsLen = 0;
    
    _timestamp = [NSDate new];
    NSTimeInterval epoch = [_timestamp timeIntervalSince1970];
    struct tm tm;
    time_t time = (time_t)epoch;
    (void)localtime_r(&time, &tm);
    int milliseconds = (int)((epoch - floor(epoch)) * 1000.0);
    
    len = snprintf(ts, 24, "%04d-%02d-%02d %02d:%02d:%02d:%03d", // yyyy-MM-dd HH:mm:ss:SSS
                   tm.tm_year + 1900,
                   tm.tm_mon + 1,
                   tm.tm_mday,
                   tm.tm_hour,
                   tm.tm_min,
                   tm.tm_sec, milliseconds);
    
    tsLen = (NSUInteger)MAX(MIN(24 - 1, len), 0);
    
    NSUInteger msgLen = [message lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    
    const BOOL useStack = msgLen < (1024 * 4);
    
    char msgStack[useStack ? (msgLen + 1) : 1]; // Analyzer doesn't like zero-size array, hence the 1
    char *msg = useStack ? msgStack : (char *)malloc(msgLen + 1);
    const char *resultCString = NULL;
    if ([message canBeConvertedToEncoding:NSUTF8StringEncoding]) {
        resultCString = [message cStringUsingEncoding:NSUTF8StringEncoding];
    }
    
    const char *lineCString = NULL;
    if ([@(line).stringValue canBeConvertedToEncoding:NSUTF8StringEncoding]) {
        lineCString = [@(line).stringValue cStringUsingEncoding:NSUTF8StringEncoding];
    }
    
    if (resultCString == NULL || lineCString == NULL) {
        return;
    }
    
    
    struct iovec v[12];
    
    v[0].iov_base = "";
    v[0].iov_len = 0;
    
    v[1].iov_base = "";
    v[1].iov_len = 0;
    
    v[11].iov_base = "";
    v[11].iov_len = 0;
    
    
    v[2].iov_base = ts;
    v[2].iov_len = tsLen;
    
    v[3].iov_base = " ";
    v[3].iov_len = 1;
    
    v[4].iov_base = (char *)function;
    v[4].iov_len = strlen(function);
    
    v[5].iov_base = "line";
    v[5].iov_len = 5;
    
    v[6].iov_base = (char *)lineCString;
    v[6].iov_len = strlen(lineCString);
    
    v[7].iov_base = " ";
    v[7].iov_len = 1;
    
    v[8].iov_base = " ";
    v[8].iov_len = 1;
    
    v[9].iov_base = (char *)resultCString;
    v[9].iov_len = msgLen;
    
    v[10].iov_base = "\n";
    v[10].iov_len = (msg[msgLen] == '\n') ? 0 : 1;
    
    writev(STDERR_FILENO, v, 12);
    
}



- (void)printMSG:(NSString *)msg andFunc:(const char *)function{
    //方法名C转OC
    NSString *funcString = [NSString stringWithUTF8String:function];
    ///时间格式化
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"HH:mm:ss.SSS";
    
    
    
    msg = [NSString stringWithFormat:@"%@ %@   %@\n\n",[formatter stringFromDate:[NSDate new]],funcString,msg];
    
    [_logSting appendString:msg];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.textField.text = _logSting;
        [self.textField scrollRectToVisible:CGRectMake(0, _textField.contentSize.height-15, _textField.contentSize.width, 10) animated:YES];
    });
 
    
}

#pragma mark-  三种手势的添加
//右滑隐藏
- (void)swipeLogView:(UISwipeGestureRecognizer *)swipeGesture{
    
    if (self.isShow) {//如果是显示情况并且往右边滑动就隐藏
        if (swipeGesture.direction == UISwipeGestureRecognizerDirectionRight) {
            NSLog(@"往右边滑动了");
            [UIView animateWithDuration:0.5 animations:^{
                self.textField.frame = CGRectMake(k_WIDTH - 30, 120, k_WIDTH, 90);
            } completion:^(BOOL finished) {
                self.isShow = NO;
                self.isFullScreen = NO;
                [self.textField addGestureRecognizer:self.panOutGesture];
            }];
        }
    }else{//如果是隐藏情况往左边滑就是显示
        
        [UIView animateWithDuration:0.5 animations:^{
            self.textField.frame = CGRectMake(60, 120, k_WIDTH - 60, 90);
        } completion:^(BOOL finished) {
            self.isShow = YES;
            self.isFullScreen = NO;
        }];
    }
}
//左拉显示
- (void)panOutTextView:(UIPanGestureRecognizer *)panGesture{
    
    if (self.isShow == YES) {//如果是显示情况什么都不管。
        return;
    }else{//如果是隐藏情况往左边滑就是显示
        [UIView animateWithDuration:0.5 animations:^{
            self.textField.frame = CGRectMake(60, 120, k_WIDTH - 60, 90);
        } completion:^(BOOL finished) {
            self.isShow = YES;
            [self.textField removeGestureRecognizer:self.panOutGesture];
        }];
    }
}

- (void)doubleTapTextView:(UITapGestureRecognizer *)tapGesture{
    
    if (self.isFullScreen == NO) {//变成全屏

        [UIView animateWithDuration:0.2 animations:^{
            self.textField.frame = [UIScreen mainScreen].bounds;
        } completion:^(BOOL finished) {
            self.isFullScreen = YES;
            [self.textField removeGestureRecognizer:self.panOutGesture];
        }];
    }else{//退出全屏

        [UIView animateWithDuration:0.2 animations:^{
            self.textField.frame = CGRectMake(k_WIDTH - 30, 120, k_WIDTH, 90);
        } completion:^(BOOL finished) {
            self.isFullScreen = NO;
            self.isShow = NO;
            [self.textField addGestureRecognizer:self.panOutGesture];
        }];
    }
}

#pragma mark- lazy
- (GHConsoleTextField *)textField{
    if (!_textField) {
        _textField = [[GHConsoleTextField alloc]initWithFrame:CGRectMake(k_WIDTH - 60, 120, k_WIDTH - 60, 90)];
        _textField.backgroundColor = [UIColor redColor];
        _textField.text = @"";
        _textField.editable = NO;
        self.textField.textColor = [UIColor whiteColor];
        _textField.alpha = 0.5;
        //        self.textField.font = [UIFont systemFontOfSize:15 weight:10];
        self.textField.selectable = NO;
        //添加右滑隐藏手势
        UISwipeGestureRecognizer *swipeGest = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLogView:)];
        //添加双击全屏或者隐藏的手势
        UITapGestureRecognizer *tappGest = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapTextView:)];
        tappGest.numberOfTapsRequired = 2;
        
        [_textField addGestureRecognizer:swipeGest];
        [_textField addGestureRecognizer:tappGest];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication].keyWindow addSubview:_textField];
        });
    }
    return _textField;
}

- (UIPanGestureRecognizer *)panOutGesture{
    if (!_panOutGesture) {
        _panOutGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panOutTextView:)];
    }
    return _panOutGesture;
}

-(void)dealloc{
}

@end
