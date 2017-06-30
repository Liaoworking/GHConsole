//
//  GHConsole.m
//  GHConsole
//
//  Created by 廖光辉 on 02/06/2017.
//  Copyright © 2017 廖光辉. All rights reserved.
//

#import "GHConsole.h"
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
        _textField.backgroundColor = [UIColor redColor];
        _textField.text = @"";
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
    self.textField.text = @"控制台开始显示";
    _logSting = [NSMutableString new];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelVerbose]; // TTY = Xcode console
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(receiveValue:) name:@"logMessage" object:nil];
    GGLog(@"%@",@"333333");
    
}



/**
 核心方法：获取到打印的相关参数后去展示

 @param notify 获得的通知
 */
- (void)receiveValue:(NSNotification *)notify{
    

    
    [_logSting appendString:[self formatterNotify:notify]];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.textField.text = _logSting;
        [self.textField scrollRectToVisible:CGRectMake(0, _textField.contentSize.height-15, _textField.contentSize.width, 10) animated:YES];
    });
 
    
}

- (NSString *)formatterNotify:(NSNotification *)notify{
    
    DDLogMessage *message = notify.userInfo[@"message"];
    ///时间格式化
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"HH:mm:ss.SSS";
    
    return  [NSString stringWithFormat:@"%@ %@ %@ line:%lu\n%@\n\n",[formatter stringFromDate:message.timestamp],message.fileName,message.function,(unsigned long)message.line,message.message];
    
}

#pragma mark-  三种手势的添加
//右滑隐藏
- (void)swipeLogView:(UISwipeGestureRecognizer *)swipeGesture{
    
    if (self.isShow) {//如果是显示情况并且往右边滑动就隐藏
        if (swipeGesture.direction == UISwipeGestureRecognizerDirectionRight) {
            NSLog(@"往右边滑动了");
            [UIView animateWithDuration:0.5 animations:^{
                self.textField.frame = CGRectMake(k_WIDTH - 30, 0, k_WIDTH, 90);
            } completion:^(BOOL finished) {
                self.isShow = NO;
                self.isFullScreen = NO;
                [self.textField addGestureRecognizer:self.panOutGesture];
            }];
        }
    }else{//如果是隐藏情况往左边滑就是显示
        
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

        [UIView animateWithDuration:0.5 animations:^{
            self.textField.frame = [UIScreen mainScreen].bounds;
        } completion:^(BOOL finished) {
            self.isFullScreen = YES;
            [self.textField removeGestureRecognizer:self.panOutGesture];
        }];
    }else{//退出全屏

        [UIView animateWithDuration:0.5 animations:^{
            self.textField.frame = CGRectMake(k_WIDTH - 30, 0, k_WIDTH, 90);
        } completion:^(BOOL finished) {
            self.isFullScreen = NO;
            self.isShow = NO;
            [self.textField addGestureRecognizer:self.panOutGesture];
        }];
    }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
