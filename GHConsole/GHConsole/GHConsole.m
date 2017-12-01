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
    NSString *_timeString;
}
@property (nonatomic, strong)GHConsoleTextField *textField;
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

//开始显示log日志 更新频率0.5s
- (void)startPrintLog{
    _isFullScreen = NO;
    _isShowConsole = YES;
    self.textField.text = @"控制台开始显示";
    self.textField.scrollEnabled = NO;//一开始防止手势冲突，靠边显示时候滚动禁用
    _logSting = [NSMutableString new];
    
    
}

- (void)stopPringting{
    if (self.textField.superview) {
        [self.textField removeFromSuperview];
    }
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
            self.textField.text = _logSting;
            [self.textField scrollRectToVisible:CGRectMake(0, _textField.contentSize.height-15, _textField.contentSize.width, 10) animated:YES];
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
                self.textField.frame = CGRectMake(k_WIDTH - 30, 120, k_WIDTH, 90);
            } completion:^(BOOL finished) {
                _isFullScreen = NO;
                [self.textField addGestureRecognizer:self.panOutGesture];
            }];
        }
    }else{//如果是隐藏情况往左边滑就是显示
        
        [UIView animateWithDuration:0.5 animations:^{
            self.textField.frame = CGRectMake(60, 120, k_WIDTH - 60, 90);
        } completion:^(BOOL finished) {
            _isFullScreen = NO;
        }];
    }
}
//左拉显示
- (void)panOutTextView:(UIPanGestureRecognizer *)panGesture{
    
    if (_isFullScreen == YES) {//如果是显示情况什么都不管。
        return;
    }else{//如果是隐藏情况上下移动就
        CGPoint point = [panGesture locationInView:[UIApplication sharedApplication].keyWindow];
        CGRect rect = self.textField.frame;
        rect.origin.y = point.y - 30;
        self.textField.frame = rect;
    }
}
//双击666
- (void)doubleTapTextView:(UITapGestureRecognizer *)tapGesture{
    
    if (_isFullScreen == NO) {//变成全屏
        self.textField.scrollEnabled = YES;
        [UIView animateWithDuration:0.2 animations:^{
            self.textField.frame = [UIScreen mainScreen].bounds;
        } completion:^(BOOL finished) {
            _isFullScreen = YES;
            [self.textField removeGestureRecognizer:self.panOutGesture];
        }];
    }else{//退出全屏
        self.textField.scrollEnabled = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.textField.frame = CGRectMake(k_WIDTH - 30, 120, k_WIDTH, 90);
        } completion:^(BOOL finished) {
            _isFullScreen = NO;
            [self.textField addGestureRecognizer:self.panOutGesture];
        }];
    }
}

#pragma mark- lazy
- (GHConsoleTextField *)textField{
    if (!_textField) {
        _textField = [[GHConsoleTextField alloc]initWithFrame:CGRectMake(k_WIDTH - 30, 120, k_WIDTH - 60, 90)];
        _textField.backgroundColor = [UIColor blackColor];
        _textField.text = @"\n\n";
        _textField.editable = NO;
        self.textField.textColor = [UIColor whiteColor];
        //        self.textField.font = [UIFont systemFontOfSize:15 weight:10];
        self.textField.selectable = NO;
        //添加右滑隐藏手势
        UISwipeGestureRecognizer *swipeGest = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLogView:)];
        //添加双击全屏或者隐藏的手势
        UITapGestureRecognizer *tappGest = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapTextView:)];
        tappGest.numberOfTapsRequired = 2;
        
        [_textField addGestureRecognizer:swipeGest];
        [_textField addGestureRecognizer:tappGest];
        [_textField addGestureRecognizer:self.panOutGesture];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (_isShowConsole) {
                [[UIApplication sharedApplication].keyWindow addSubview:_textField];
            }
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


@end
