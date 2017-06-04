//
//  GHConsole.m
//  GHConsole
//
//  Created by 廖光辉 on 02/06/2017.
//  Copyright © 2017 廖光辉. All rights reserved.
//

#import "GHConsole.h"
#import "GHLogManager.h"

#define k_WIDTH [UIScreen mainScreen].bounds.size.width
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
@interface GHConsole ()
@property (nonatomic, strong)GHConsoleTextField *textField;
@property (nonatomic, strong)NSString *string;
//定时器
@property (nonatomic, strong)NSTimer *timer;
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
#pragma mark- lazy
- (GHConsoleTextField *)textField{
    if (!_textField) {
        _textField = [[GHConsoleTextField alloc]initWithFrame:CGRectMake(60, 0, k_WIDTH - 60, 90)];
        _textField.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.3];
        _textField.text = @"";
        _textField.editable = NO;
        self.textField.textColor = [UIColor blackColor];
        self.textField.selectable = NO;
        //添加右滑隐藏手势
        UISwipeGestureRecognizer *swipeGest = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLogView:)];
        //添加双击全屏或者隐藏的手势
        UITapGestureRecognizer *tappGest = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapTextView:)];
        tappGest.numberOfTapsRequired = 2;
        
        [_textField addGestureRecognizer:swipeGest];
        [_textField addGestureRecognizer:tappGest];
    [[UIApplication sharedApplication].keyWindow addSubview:_textField];
    }
    return _textField;
}

- (NSTimer *)timer{
    
    if (!_timer) {
        _timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(textFieldStartRefresh) userInfo:nil repeats:YES];
    }
    return _timer;
}

- (UIPanGestureRecognizer *)panOutGesture{
    if (!_panOutGesture) {
        _panOutGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panOutTextView:)];
    }
    return _panOutGesture;
}

+ (instancetype)sharedConsole {
    
    static GHConsole *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [GHConsole new];
        });
    return _instance;
}

//开始显示log日志 更新频率0.5s
- (void)startPrintString{
    self.isShow = YES;
    self.isFullScreen = NO;
    [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
    self.textField.text = @"控制台开始显示";
}

- (void)textFieldStartRefresh{
    
    _logSting = [NSMutableString stringWithFormat:@""];
    
    NSArray * dataArray = [GHLogManager allLogAfterTime:0.0];
    if (_currentLogCount == dataArray.count) {
        return;
    }
    [dataArray enumerateObjectsUsingBlock:^(GHLogMessager  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //sender 是当前控制器
        [_logSting appendString:[obj displayedTextForLogMessage]];
    }];
    _currentLogCount = dataArray.count;
    self.textField.text = _logSting;
    [self.textField scrollRectToVisible:CGRectMake(0, _textField.contentSize.height-15, _textField.contentSize.width, 10) animated:YES];
}

#pragma mark-  三种手势的添加
//右滑隐藏
- (void)swipeLogView:(UISwipeGestureRecognizer *)swipeGesture{
    
    if (self.isShow) {//如果是显示情况并且往右边滑动就隐藏
        if (swipeGesture.direction == UISwipeGestureRecognizerDirectionRight) {
            NSLog(@"往右边滑动了");
            [self.timer invalidate];
            self.timer = nil;
            [UIView animateWithDuration:0.5 animations:^{
                self.textField.frame = CGRectMake(k_WIDTH - 30, 0, k_WIDTH, 90);
            } completion:^(BOOL finished) {
                self.isShow = NO;
                self.isFullScreen = NO;
                [self.textField addGestureRecognizer:self.panOutGesture];
            }];
        }
    }else{//如果是隐藏情况往左边滑就是显示
        
        [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
        [UIView animateWithDuration:0.5 animations:^{
            self.textField.frame = CGRectMake(60, 0, k_WIDTH - 60, 90);
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
        [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
        [UIView animateWithDuration:0.5 animations:^{
            self.textField.frame = CGRectMake(60, 0, k_WIDTH - 60, 90);
        } completion:^(BOOL finished) {
            self.isShow = YES;
            [self.textField removeGestureRecognizer:self.panOutGesture];
        }];
    }
}

- (void)doubleTapTextView:(UITapGestureRecognizer *)tapGesture{
    
    if (self.isFullScreen == NO) {//变成全屏
        //如果timer失效了就让它启动
        if (!self.timer) {
            [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
        }
        [UIView animateWithDuration:0.5 animations:^{
            self.textField.frame = [UIScreen mainScreen].bounds;
        } completion:^(BOOL finished) {
            self.isFullScreen = YES;
            [self.textField removeGestureRecognizer:self.panOutGesture];
        }];
    }else{//退出全屏
        [self.timer invalidate];
        self.timer = nil;
        [UIView animateWithDuration:0.5 animations:^{
            self.textField.frame = CGRectMake(k_WIDTH - 30, 0, k_WIDTH, 90);
        } completion:^(BOOL finished) {
            self.isFullScreen = NO;
            [self.textField addGestureRecognizer:self.panOutGesture];
        }];    }
    
}

@end
