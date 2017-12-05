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
#import "GHConsoleWindow.h"
#import "GHConsoleRootViewController.h"
#define USE_PTHREAD_THREADID_NP                (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)

#pragma mark- GHConsole
@interface GHConsole (){
    NSDate *_timestamp;
    NSString *_timeString;
}

@property (nonatomic, strong)NSString *string;
///是否显示控制台
@property (nonatomic, assign)BOOL isShowConsole;
//添加一个全局的logString 防止局部清除
@property (nonatomic, copy)NSMutableString *logSting;
//记录打印数，来确定打印更新
@property (nonatomic, assign)NSInteger currentLogCount;
//是否全屏
@property (nonatomic, assign)BOOL isFullScreen;
//添加的向外的手势，为了避免和查看log日志的手势冲突  isShow之后把手势移除
@property (nonatomic, strong)UIPanGestureRecognizer *panOutGesture;
@property (nonatomic,strong) GHConsoleWindow *consoleWindow;
@end
@implementation GHConsole


+ (instancetype)sharedConsole {
    
    static GHConsole *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [GHConsole new];
        _instance.isShowConsole = NO;
        });
    return _instance;
}

- (GHConsoleWindow *)consoleWindow {
    if(!_consoleWindow){
        _consoleWindow = [GHConsoleWindow consoleWindow];
        _consoleWindow.rootViewController = [GHConsoleRootViewController new];
        //添加右滑隐藏手势
        UISwipeGestureRecognizer *swipeGest = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLogView:)];
        //添加双击全屏或者隐藏的手势
        UITapGestureRecognizer *tappGest = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapTextView:)];
        tappGest.numberOfTapsRequired = 2;

        [_consoleWindow.rootViewController.view addGestureRecognizer:swipeGest];
        [_consoleWindow.rootViewController.view addGestureRecognizer:tappGest];
        [_consoleWindow.rootViewController.view addGestureRecognizer:self.panOutGesture];
    }
    return _consoleWindow;
}

//开始显示log日志 更新频率0.5s
- (void)startPrintLog{
    _isFullScreen = NO;
    _isShowConsole = YES;
    self.consoleWindow.hidden = NO;
    self.consoleWindow.consoleRootViewController.text = @"控制台开始显示";
    _logSting = [NSMutableString new];
    
    
}

- (void)stopPringting{
    self.consoleWindow.hidden = YES;
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
        [self printMSG:message andFunc:function andLine:line];
    }
    
}

- (void)printMSG:(NSString *)msg andFunc:(const char *)function andLine:(NSInteger )Line{
    //方法名C转OC
    NSString *funcString = [NSString stringWithUTF8String:function];
    ///时间格式化
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    
    
    
    msg = [NSString stringWithFormat:@"%@ %@ line-%ld  %@\n\n",[formatter stringFromDate:[NSDate new]],funcString,(long)Line,msg];
    
    const char *resultCString = NULL;
    if ([msg canBeConvertedToEncoding:NSUTF8StringEncoding]) {
        resultCString = [msg cStringUsingEncoding:NSUTF8StringEncoding];
    }
    //控制台打印
    printf("%s", resultCString);
    if (self.isShowConsole) {//如果显示的话手机上的控制台开始显示。
        [_logSting appendString:msg];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.consoleWindow.consoleRootViewController.text = _logSting;
        });
    }
}

#pragma mark-  三种手势的添加
//右滑隐藏
- (void)swipeLogView:(UISwipeGestureRecognizer *)swipeGesture{
    
    if (_isFullScreen) {//如果是显示情况并且往右边滑动就隐藏
        if (swipeGesture.direction == UISwipeGestureRecognizerDirectionRight) {
            NSLog(@"往右边滑动了");
            [UIView animateWithDuration:0.5 animations:^{
                [self.consoleWindow minimize];
            } completion:^(BOOL finished) {
                _isFullScreen = NO;
                [self.consoleWindow.rootViewController.view addGestureRecognizer:self.panOutGesture];
            }];
        }
    }
}
//左拉显示
- (void)panOutTextView:(UIPanGestureRecognizer *)panGesture{
    
    if (_isFullScreen == YES) {//如果是显示情况什么都不管。
        return;
    }else{//如果是隐藏情况上下移动就
        if(panGesture.state == UIGestureRecognizerStateChanged){
            CGPoint transalte = [panGesture translationInView:[UIApplication sharedApplication].keyWindow];
            CGRect rect = self.consoleWindow.frame;
            rect.origin.y += transalte.y;
            if(rect.origin.y < 0){
                rect.origin.y = 0;
            }
            CGFloat maxY = [UIScreen mainScreen].bounds.size.height - rect.size.height;
            if(rect.origin.y > maxY){
                rect.origin.y = maxY;
            }
            self.consoleWindow.frame = rect;
            [panGesture setTranslation:CGPointZero inView:[UIApplication sharedApplication].keyWindow];
        }
    }
}
//双击666
- (void)doubleTapTextView:(UITapGestureRecognizer *)tapGesture{
    
    if (_isFullScreen == NO) {//变成全屏
        [UIView animateWithDuration:0.2 animations:^{
            [self.consoleWindow maxmize];
        } completion:^(BOOL finished) {
            _isFullScreen = YES;
            [self.consoleWindow.rootViewController.view removeGestureRecognizer:self.panOutGesture];
        }];
    }else{//退出全屏
        [UIView animateWithDuration:0.2 animations:^{
            [self.consoleWindow minimize];
        } completion:^(BOOL finished) {
            _isFullScreen = NO;
            [self.consoleWindow.rootViewController.view addGestureRecognizer:self.panOutGesture];
        }];
    }
}

- (UIPanGestureRecognizer *)panOutGesture{
    if (!_panOutGesture) {
        _panOutGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panOutTextView:)];
    }
    return _panOutGesture;
}


@end
