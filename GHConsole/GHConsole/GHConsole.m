//
//  GHConsole.m
//  GHConsole
//
//  Created by liaoWorking on 22/11/2017.
//  Copyright © 2017 廖光辉. All rights reserved.
//

#import "GHConsole.h"
#define k_WIDTH [UIScreen mainScreen].bounds.size.width
#import <unistd.h>
#import <sys/uio.h>
#import <pthread/pthread.h>
#define USE_PTHREAD_THREADID_NP                (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)
#pragma mark- GHConsoleRootViewController
typedef void (^clearTextBlock)(void);
@interface GHConsoleRootViewController : UIViewController
{
    UITextView *_textView;
    UIButton *_clearBtn;
}
@property (nonatomic,copy) NSString *text;
@property (nonatomic) BOOL scrollEnable;
@property (nonatomic, copy) clearTextBlock clearLogText;

@end

@implementation GHConsoleRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configTextField];
    [self configClearBtn];
}

- (void)configTextField{
    
    _textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    _textView.backgroundColor = [UIColor blackColor];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _textView.font = [UIFont boldSystemFontOfSize:13];

    _textView.textColor = [UIColor whiteColor];
    _textView.editable = NO;
    _textView.scrollEnabled = NO;
    _textView.selectable = NO;
    _textView.alwaysBounceVertical = YES;
#ifdef __IPHONE_11_0
    if([_textView respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
        _textView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
#pragma clang diagnostic pop
        
    }
#endif
    [self.view addSubview:_textView];
    _textView.text = self.text;
    [_textView scrollRectToVisible:CGRectMake(0, _textView.contentSize.height-15, _textView.contentSize.width, 10) animated:YES];
    
}

- (void)configClearBtn{
    
    _clearBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.bounds.size.width - 100, 20, 80, 30)];
    [_clearBtn addTarget:self action:@selector(clearText) forControlEvents:UIControlEventTouchUpInside];
    [_clearBtn setTitle:@"clear" forState:UIControlStateNormal];
    [_clearBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _clearBtn.layer.borderWidth = 2;
    _clearBtn.layer.borderColor = [[UIColor whiteColor] CGColor];
    [self.view addSubview:_clearBtn];
    
}

- (void)clearText{
    if (self.clearLogText) {
        self.clearLogText();
    }
}

- (void)setText:(NSString *)text {
    _text = [text copy];
    if(_textView){
        _textView.text = text;
        [_textView scrollRectToVisible:CGRectMake(0, _textView.contentSize.height-15, _textView.contentSize.width, 10) animated:YES];
    }
}

- (void)setScrollEnable:(BOOL)scrollEnable {
    _textView.scrollEnabled = scrollEnable;
}
@end


#pragma mark- GHConsoleWindow
@interface GHConsoleWindow : UIWindow

+ (instancetype)consoleWindow;

/**
  to make the GHConsole full-screen.
 */
- (void)maxmize;

/**
 to make the GHConsole at the right side in your app
 */
- (void)minimize;

@property (nonatomic,strong) GHConsoleRootViewController *consoleRootViewController;
@end


@implementation GHConsoleWindow
+ (instancetype)consoleWindow {
    GHConsoleWindow *window = [[self alloc] init];
    window.windowLevel = UIWindowLevelStatusBar + 100;
    window.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 30, 120, [UIScreen mainScreen].bounds.size.width - 60, 90);
    return window;
}

- (GHConsoleRootViewController *)consoleRootViewController {
    return (GHConsoleRootViewController *)self.rootViewController;
}

- (void)maxmize {
    self.frame = [UIScreen mainScreen].bounds;
    self.consoleRootViewController.scrollEnable = YES;
}

- (void)minimize {
    self.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 30, 120, [UIScreen mainScreen].bounds.size.width - 60, 90);
    self.consoleRootViewController.scrollEnable = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.rootViewController.view.frame = self.bounds;
}
@end



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
///性能优化，使用全局变量压测会有明显性能提升
@property (nonatomic, copy)NSString *funcString;
@property (nonatomic, strong)NSDateFormatter *formatter;
@property (nonatomic, copy)NSString *msgString;
@property (nonatomic, strong)NSDate *now;
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
        __weak __typeof__(self) weakSelf = self;
        _consoleWindow.consoleRootViewController.clearLogText = ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf clearAllText];
        };
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

//开始显示log日志
- (void)startPrintLog{
    _isFullScreen = NO;
    _isShowConsole = YES;
    self.consoleWindow.hidden = NO;
    _logSting = [NSMutableString new];
    _formatter = [[NSDateFormatter alloc]init];
    _formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    GGLog(@"GHConsole start working");
    
}
//停止显示
- (void)stopPringting{
    self.consoleWindow.hidden = YES;
    _isShowConsole = NO;
}

- (void)function:(const char *)function
            line:(NSUInteger)line
          format:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4){
    va_list args;
    
    if (format) {
        va_start(args, format);
        
        _msgString = [[NSString alloc] initWithFormat:format arguments:args];
        //UI上去展示日志内容
        [self printMSG:_msgString andFunc:function andLine:line];
    }
}

- (void)printMSG:(NSString *)msg andFunc:(const char *)function andLine:(NSInteger )Line{
    //方法名C转OC
    _funcString = [NSString stringWithUTF8String:function];
    
    _now =[NSDate new];
    msg = [NSString stringWithFormat:@"%@ %@ line-%ld\n%@\n\n",[_formatter stringFromDate:_now],_funcString,(long)Line,msg];
    
    const char *resultCString = NULL;
    if ([msg canBeConvertedToEncoding:NSUTF8StringEncoding]) {
        resultCString = [msg cStringUsingEncoding:NSUTF8StringEncoding];
    }
    //控制台打印
    printf("%s", resultCString);
    [_logSting appendString:msg];
    if (_isShowConsole && _isFullScreen) {//如果显示的话手机上的控制台开始显示。
        dispatch_async(dispatch_get_main_queue(), ^{
            self.consoleWindow.consoleRootViewController.text = _logSting;
        });
    }
}

- (void)clearAllText{
    _logSting = [NSMutableString stringWithString:@""];
    self.consoleWindow.consoleRootViewController.text = _logSting;
}

#pragma mark-  三种手势的添加
//右滑隐藏
- (void)swipeLogView:(UISwipeGestureRecognizer *)swipeGesture{
    
    if (_isFullScreen) {//如果是显示情况并且往右边滑动就隐藏
        if (swipeGesture.direction == UISwipeGestureRecognizerDirectionRight) {
            [UIView animateWithDuration:0.5 animations:^{
                [self.consoleWindow minimize];
            } completion:^(BOOL finished) {
                _isFullScreen = NO;
                [self.consoleWindow.rootViewController.view addGestureRecognizer:self.panOutGesture];
            }];
        }
    }
}
//scroll vertical.
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
//双击操作
- (void)doubleTapTextView:(UITapGestureRecognizer *)tapGesture{
    
    if (_isFullScreen == NO) {//变成全屏
        [UIView animateWithDuration:0.2 animations:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.consoleWindow.consoleRootViewController.text = _logSting;
            });
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
