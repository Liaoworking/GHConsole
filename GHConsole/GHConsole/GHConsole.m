//
//  GHConsole.m
//  GHConsole
//
//  Created by liaoWorking on 22/11/2017.
//  Copyright © 2017 廖光辉. All rights reserved.
//  https://github.com/Liaoworking/GHConsole for lastest version
//

#import "GHConsole.h"
#define k_WIDTH [UIScreen mainScreen].bounds.size.width
#import <unistd.h>
#import <sys/uio.h>
#import <pthread/pthread.h>
#define USE_PTHREAD_THREADID_NP                (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)
#define KIsiPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

#pragma mark- GHConsoleRootViewController
typedef void (^clearTextBlock)(void);
typedef void (^readTextBlock)(void);

@interface GHConsoleRootViewController : UIViewController
{
    UITextView *_textView;
    UIButton *_clearBtn;
    UIButton *_saveBtn;
    UIButton *_readLogBtn;
}
@property (nonatomic,copy) NSString *text;
@property (nonatomic) BOOL scrollEnable;
@property (nonatomic, copy) clearTextBlock clearLogText;
@property (nonatomic, copy) readTextBlock readLog;

@end

@implementation GHConsoleRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configTextField];
    [self configClearBtn];
    [self configSaveBtn];
    [self configReadBtn];
}

- (void)configTextField{
    _textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    _textView.backgroundColor = [UIColor blackColor];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _textView.font = [UIFont boldSystemFontOfSize:13];
    _textView.textColor = [UIColor whiteColor];
    _textView.editable = _textView.scrollEnabled =_textView.selectable = NO;
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
    _clearBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.bounds.size.width - 80, KIsiPhoneX?40:20, 60, 30)];
    [_clearBtn addTarget:self action:@selector(clearText) forControlEvents:UIControlEventTouchUpInside];
    [_clearBtn setTitle:@"clear" forState:UIControlStateNormal];
    [_clearBtn setTitleColor:[UIColor colorWithRed:0/255.0 green:212/255.0 blue:59/255.0 alpha:1] forState:UIControlStateNormal];
    _clearBtn.layer.borderWidth = 2;
    _clearBtn.layer.borderColor = [UIColor colorWithRed:0/255.0 green:212/255.0 blue:59/255.0 alpha:1].CGColor;
    [self.view addSubview:_clearBtn];
}

- (void)configSaveBtn{
    _saveBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMinX(_clearBtn.frame) - 70, KIsiPhoneX?40:20, 60, 30)];
    [_saveBtn addTarget:self action:@selector(saveText) forControlEvents:UIControlEventTouchUpInside];
    [_saveBtn setTitle:@"save" forState:UIControlStateNormal];
    [_saveBtn setTitleColor:[UIColor colorWithRed:251/255.0 green:187/255.0 blue:0/255.0 alpha:1] forState:UIControlStateNormal];
    _saveBtn.layer.borderWidth = 2;
    _saveBtn.layer.borderColor = [[UIColor colorWithRed:251/255.0 green:187/255.0 blue:0/255.0 alpha:1] CGColor];
    [self.view addSubview:_saveBtn];
}

- (void)configReadBtn{
    _readLogBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMinX(_saveBtn.frame) - 70, KIsiPhoneX?40:20, 60, 30)];
    [_readLogBtn addTarget:self action:@selector(readSavedText) forControlEvents:UIControlEventTouchUpInside];
    [_readLogBtn setTitle:@"load" forState:UIControlStateNormal];
    [_readLogBtn setTitleColor:[UIColor colorWithRed:247/255.0 green:59/255.0 blue:59/255.0 alpha:1] forState:UIControlStateNormal];
    _readLogBtn.layer.borderWidth = 2;
    _readLogBtn.layer.borderColor = [[UIColor colorWithRed:247/255.0 green:59/255.0 blue:59/255.0 alpha:1] CGColor];
    _readLogBtn.hidden = [[NSUserDefaults standardUserDefaults]objectForKey:@"textSaveKey"]?false:true;
    [self.view addSubview:_readLogBtn];
}


- (void)clearText{
    if (self.clearLogText) {
        self.clearLogText();
    }
}

- (void)saveText{
    if (_textView.text.length<1) {
        return;
    }else{
        [[NSUserDefaults standardUserDefaults]setObject:_textView.text forKey:@"textSaveKey"];
        if (_readLogBtn.isHidden) {
            _readLogBtn.hidden = false;
        }
    }
}

- (void)readSavedText{
    if (self.readLog) {
        self.readLog();
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

- (BOOL)prefersStatusBarHidden{
    return false;
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
    window.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 30, 120, 30, 90);
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
    self.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 30, 120, 30, 90);
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
@property (nonatomic, assign)BOOL isShowConsole;
//a global variable to prove performance
@property (nonatomic, copy)NSMutableString *logSting;
@property (nonatomic, copy)NSString *funcString;

@property (nonatomic, assign)NSInteger currentLogCount;
@property (nonatomic, assign)BOOL isFullScreen;
@property (nonatomic, strong)UIPanGestureRecognizer *panOutGesture;
@property (nonatomic,strong) GHConsoleWindow *consoleWindow;
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
        _consoleWindow.consoleRootViewController.readLog = ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf readSavedText];
        };
        //right direction swipe and double tap to make the console be hidden
        UISwipeGestureRecognizer *swipeGest = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLogView:)];
        UITapGestureRecognizer *tappGest = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapTextView:)];
        tappGest.numberOfTapsRequired = 2;
        
        [_consoleWindow.rootViewController.view addGestureRecognizer:swipeGest];
        [_consoleWindow.rootViewController.view addGestureRecognizer:tappGest];
        [_consoleWindow.rootViewController.view addGestureRecognizer:self.panOutGesture];
    }
    return _consoleWindow;
}

/**
 start printing
 */
- (void)startPrintLog{
    _isFullScreen = NO;
    _isShowConsole = YES;
    self.consoleWindow.hidden = NO;
    _logSting = [NSMutableString new];
    _formatter = [[NSDateFormatter alloc]init];
    _formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    GGLog(@"GHConsole start working!");
  
    //如果想在release情况下也能显示控制台打印请把stopPrinting方法注释掉
    // if you want to see GHConsole at the release mode you will annotating the stopPrinting func below here.
#ifndef DEBUG
    [self stopPrinting];
#endif
}
/**
 stop printing
 */- (void)stopPrinting{
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
        //showing log in UI
        [self printMSG:_msgString andFunc:function andLine:line];
    }
}

- (void)printMSG:(NSString *)msg andFunc:(const char *)function andLine:(NSInteger )Line{
    //convert C function name to OC
    _funcString = [NSString stringWithUTF8String:function];
    
    _now =[NSDate new];
    msg = [NSString stringWithFormat:@"%@ %@ line-%ld\n%@\n\n",[_formatter stringFromDate:_now],_funcString,(long)Line,msg];
    
    const char *resultCString = NULL;
    if ([msg canBeConvertedToEncoding:NSUTF8StringEncoding]) {
        resultCString = [msg cStringUsingEncoding:NSUTF8StringEncoding];
    }
    //printing at system concole
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

- (void)readSavedText{
   NSString *savedString = [[NSUserDefaults standardUserDefaults]objectForKey:@"textSaveKey"];
    _logSting = [savedString stringByAppendingString:@"\n-----------------RECORD-----------------\n\n"].mutableCopy;
    self.consoleWindow.consoleRootViewController.text = _logSting;
}

#pragma mark- gesture function
/**
 right direction to hidden
 */
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
/**
 scroll vertical.
 */
- (void)panOutTextView:(UIPanGestureRecognizer *)panGesture{
    
    if (_isFullScreen == YES) {// do nothing when it fullScreen.
        return;
    }else{
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
/**
 double tap
 */
- (void)doubleTapTextView:(UITapGestureRecognizer *)tapGesture{
    
    if (!_isFullScreen) {//变成全屏
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
