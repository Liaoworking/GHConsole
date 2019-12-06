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
#define KIsiPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? (CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size)||CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size)||CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size)) : NO)

#pragma mark- GHConsoleRootViewController
typedef void (^clearTextBlock)(void);
typedef void (^readTextBlock)(void);

@interface GHTextViewController : UIViewController

@property (nonatomic,copy) NSString *text;

@end

@implementation GHTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, self.view.bounds.size.height)];
    textView.editable = NO;
    textView.backgroundColor = [UIColor blackColor];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    textView.textColor = [UIColor whiteColor];
    textView.text = self.text;
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [backBtn setBackgroundColor:[UIColor redColor]];
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    backBtn.frame = CGRectMake(0, 0, self.view.bounds.size.width, 20);
    [self.view addSubview:backBtn];
    [backBtn addTarget:self action:@selector(backBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:textView];
}

- (void)backBtnAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

@interface GHConsoleRootViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>
{
    @public
    UITableView *_tableView;
    UIButton *_clearBtn;
    UIButton *_saveBtn;
    UIButton *_readLogBtn;
    UIButton *_minimize;
    UIImageView *_imgV;
}
@property (nonatomic) BOOL scrollEnable;
@property (nonatomic, copy) clearTextBlock clearLogText;
@property (nonatomic, copy) readTextBlock readLog;
@property (nonatomic,strong) void(^minimizeActionBlock)(void);
@property (nonatomic,copy) NSArray *dataSource;

@end

@implementation GHConsoleRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configTextField];
    [self configClearBtn];
    [self configSaveBtn];
    [self configReadBtn];
    [self configMinimizeBtn];
    [self createImgV];
}

- (void)configTextField{
    self.view.clipsToBounds = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.tableFooterView = [UIView new];
    _tableView.separatorColor = [UIColor whiteColor];
    _tableView.estimatedRowHeight = 44;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _tableView.backgroundColor = [UIColor blackColor];
    if (@available(iOS 11.0, *)) {
        _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        // Fallback on earlier versions
    }
    [self.view addSubview:_tableView];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_tableView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_tableView)]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(h)-[_tableView]-0-|" options:0 metrics:@{@"h":@((KIsiPhoneX?44:0) + 44)} views:NSDictionaryOfVariableBindings(_tableView)]];
    [_tableView reloadData];
}

- (void)configClearBtn{

  _clearBtn = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 80, KIsiPhoneX?44:0, 60, 44)];
    [_clearBtn addTarget:self action:@selector(clearText) forControlEvents:UIControlEventTouchUpInside];
    [_clearBtn setTitle:@"清空" forState:UIControlStateNormal];
    [_clearBtn setTitleColor:[UIColor colorWithRed:0/255.0 green:212/255.0 blue:59/255.0 alpha:1] forState:UIControlStateNormal];
    _clearBtn.layer.borderWidth = 2;
    _clearBtn.layer.borderColor = [UIColor colorWithRed:0/255.0 green:212/255.0 blue:59/255.0 alpha:1].CGColor;
    [self.view addSubview:_clearBtn];
}

- (void)configSaveBtn{
    _saveBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMinX(_clearBtn.frame) - 70, KIsiPhoneX?44:0, 60, 44)];
    [_saveBtn addTarget:self action:@selector(saveText) forControlEvents:UIControlEventTouchUpInside];
    [_saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    [_saveBtn setTitleColor:[UIColor colorWithRed:251/255.0 green:187/255.0 blue:0/255.0 alpha:1] forState:UIControlStateNormal];
    _saveBtn.layer.borderWidth = 2;
    _saveBtn.layer.borderColor = [[UIColor colorWithRed:251/255.0 green:187/255.0 blue:0/255.0 alpha:1] CGColor];
    [self.view addSubview:_saveBtn];
}

- (void)configReadBtn{
    _readLogBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMinX(_saveBtn.frame) - 70, KIsiPhoneX?44:0, 60, 44)];
    [_readLogBtn addTarget:self action:@selector(readSavedText) forControlEvents:UIControlEventTouchUpInside];
    [_readLogBtn setTitle:@"加载" forState:UIControlStateNormal];
    [_readLogBtn setTitleColor:[UIColor colorWithRed:247/255.0 green:59/255.0 blue:59/255.0 alpha:1] forState:UIControlStateNormal];
    _readLogBtn.layer.borderWidth = 2;
    _readLogBtn.layer.borderColor = [[UIColor colorWithRed:247/255.0 green:59/255.0 blue:59/255.0 alpha:1] CGColor];
    [self.view addSubview:_readLogBtn];
}

- (void)configMinimizeBtn{
    _minimize = [[UIButton alloc]initWithFrame:CGRectMake(20, KIsiPhoneX?44:0, 80, 44)];
    [_minimize addTarget:self action:@selector(minimizeAction:) forControlEvents:UIControlEventTouchUpInside];
    [_minimize setTitle:@"最小化" forState:UIControlStateNormal];
    [_minimize setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
    _minimize.layer.borderWidth = 2;
    _minimize.layer.borderColor = [[UIColor cyanColor] CGColor];
    [self.view addSubview:_minimize];
}

- (void)createImgV {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"GHConsole.bundle" ofType:nil];
    path = [path stringByAppendingPathComponent:@"icon.png"];
    _imgV = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:path]];
    _imgV.userInteractionEnabled = YES;
    _imgV.frame = self.view.bounds;
    _imgV.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _imgV.layer.shadowOpacity = 0.5;
    _imgV.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:_imgV];
}

- (void)minimizeAction:(UIButton *)sender {
    if(_minimizeActionBlock){
        _minimizeActionBlock();
    }
}

- (void)setDataSource:(NSArray *)dataSource {
    _dataSource = [dataSource copy];
    [_tableView reloadData];
}

- (void)clearText{
    if (self.clearLogText) {
        self.clearLogText();
    }
}

- (void)saveText{
    if (self.dataSource.count<1) {
        return;
    }else{
        NSData *data = [NSJSONSerialization dataWithJSONObject:self.dataSource options:NSJSONWritingPrettyPrinted error:nil];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"textSaveKey"];
    }
}

- (void)readSavedText{
    if (self.readLog) {
        self.readLog();
    }
}

- (void)setScrollEnable:(BOOL)scrollEnable {
    _tableView.scrollEnabled = scrollEnable;
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Cell = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Cell];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:Cell];
        cell.contentView.backgroundColor = [UIColor blackColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UITextView *textView = [[UITextView alloc] init];
        textView.scrollEnabled = NO;
        textView.textContainer.lineFragmentPadding = 0;
        textView.textContainerInset = UIEdgeInsetsZero;
        textView.backgroundColor = [UIColor blackColor];
        textView.textColor = [UIColor whiteColor];
        textView.font = [UIFont systemFontOfSize:13];
        textView.tag = 100;
        textView.userInteractionEnabled = NO;
        [cell.contentView addSubview:textView];
        textView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[textView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(textView)]];
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[textView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(textView)]];
    }
    NSString *str = self.dataSource[indexPath.row];
    UITextView *textView = [cell.contentView viewWithTag:100];
    textView.text = str;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *str = self.dataSource[indexPath.row];
    CGRect rect = [str boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width - 10, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil];
    return ceil(rect.size.height);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    dispatch_async(dispatch_get_main_queue(), ^{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"复制选中的log" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *str = self.dataSource[indexPath.row];
        [UIPasteboard generalPasteboard].string = str;
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"单独查看选中的log" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        GHTextViewController *vc = [[GHTextViewController alloc] init];
        NSString *str = self.dataSource[indexPath.row];
        vc.text = str;
        [self presentViewController:vc animated:YES completion:nil];
    }];
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertVC addAction:action1];
    [alertVC addAction:action2];
    [alertVC addAction:action3];
    [self presentViewController:alertVC animated:YES completion:nil];
    });
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

/**
 the point of origin X-axis and Y-axis 
 */
@property (nonatomic, assign)CGPoint axisXY;

@property (nonatomic,strong) GHConsoleRootViewController *consoleRootViewController;
@end


@implementation GHConsoleWindow
+ (instancetype)consoleWindow {
    GHConsoleWindow *window = [[self alloc] init];
    window.windowLevel = UIWindowLevelStatusBar + 100;
    window.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 50, 120, 50, 50);
    window.clipsToBounds = YES;
    return window;
}

- (GHConsoleRootViewController *)consoleRootViewController {
    return (GHConsoleRootViewController *)self.rootViewController;
}

- (void)maxmize {
    self.consoleRootViewController.view.backgroundColor = [UIColor blackColor];
    self.frame = [UIScreen mainScreen].bounds;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    self.consoleRootViewController.scrollEnable = YES;
    self.backgroundColor = [UIColor blackColor];
    self.consoleRootViewController->_imgV.alpha = 0;
    self.consoleRootViewController->_minimize.alpha = 1.0;
    self.consoleRootViewController->_readLogBtn.alpha = 1.0;
    self.consoleRootViewController->_clearBtn.alpha = 1.0;
    self.consoleRootViewController->_saveBtn.alpha = 1.0;
    self.consoleRootViewController->_tableView.alpha = 1.0;
}

- (void)minimize {
    self.consoleRootViewController.view.backgroundColor = [UIColor clearColor];
    self.frame = CGRectMake(_axisXY.x, _axisXY.y, 50, 50);
    [self setNeedsLayout];
    [self layoutIfNeeded];
    self.consoleRootViewController.scrollEnable = NO;
    self.consoleRootViewController->_imgV.alpha = 1.0;
    self.consoleRootViewController->_minimize.alpha = 0;
    self.consoleRootViewController->_readLogBtn.alpha = 0;
    self.consoleRootViewController->_clearBtn.alpha = 0;
    self.consoleRootViewController->_saveBtn.alpha = 0;
    self.consoleRootViewController->_tableView.alpha = 0;
    self.backgroundColor = [UIColor clearColor];
    [[UIApplication sharedApplication].delegate.window.rootViewController setNeedsStatusBarAppearanceUpdate];
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
@property (nonatomic, strong) NSMutableArray *logStingArray;
@property (nonatomic, copy)NSString *funcString;

@property (nonatomic, assign)NSInteger currentLogCount;
@property (nonatomic, assign)BOOL isFullScreen;
@property (nonatomic, strong)UIPanGestureRecognizer *panOutGesture;
@property (nonatomic,strong) GHConsoleWindow *consoleWindow;
@property (nonatomic, strong)NSDateFormatter *formatter;
@property (nonatomic, copy)NSString *msgString;
@property (nonatomic, strong)NSDate *now;
@property (nonatomic, strong)NSLock *lock;
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (GHConsoleWindow *)consoleWindow {
    if(!_consoleWindow){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReceiveMemoryWarningNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        _consoleWindow = [GHConsoleWindow consoleWindow];
        _consoleWindow.rootViewController = [GHConsoleRootViewController new];
        _consoleWindow.rootViewController.view.backgroundColor = [UIColor clearColor];
        _consoleWindow.axisXY = _consoleWindow.frame.origin;
        __weak __typeof__(self) weakSelf = self;
        _consoleWindow.consoleRootViewController.clearLogText = ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf clearAllText];
        };
        _consoleWindow.consoleRootViewController.readLog = ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf readSavedText];
        };
        UITapGestureRecognizer *tappGest = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapImageView:)];
        
        [_consoleWindow.rootViewController.view addGestureRecognizer:self.panOutGesture];
        [_consoleWindow.consoleRootViewController->_imgV addGestureRecognizer:tappGest];
        _consoleWindow.consoleRootViewController.minimizeActionBlock = ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf minimizeAnimation];
        };
        _consoleWindow.backgroundColor = [UIColor clearColor];
        self.consoleWindow.consoleRootViewController->_imgV.alpha = 1.0;
        self.consoleWindow.consoleRootViewController->_saveBtn.alpha = 0;
        self.consoleWindow.consoleRootViewController->_readLogBtn.alpha = 0;
        self.consoleWindow.consoleRootViewController->_clearBtn.alpha = 0;
        self.consoleWindow.consoleRootViewController->_minimize.alpha = 0;
        self.consoleWindow.consoleRootViewController->_tableView.alpha = 0;
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
    _formatter = [[NSDateFormatter alloc]init];
    _formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    _lock = [NSLock new];
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
        [_lock lock];
        [self printMSG:_msgString andFunc:function andLine:line];
        [_lock unlock];
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
    if(msg.length > 0 && [msg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0){
        [self.logStingArray addObject:msg];
    }
    if (_isShowConsole && _isFullScreen) {
        //如果显示的话手机上的控制台开始显示。
        dispatch_async(dispatch_get_main_queue(), ^{
            self.consoleWindow.consoleRootViewController.dataSource = self.logStingArray;
            [self scrollToBottom];
        });
    }
}

- (void)clearAllText{
    [self.logStingArray removeAllObjects];
    self.consoleWindow.consoleRootViewController.dataSource = self.logStingArray;
}

- (void)readSavedText{
   NSData *savedString = [[NSUserDefaults standardUserDefaults] objectForKey:@"textSaveKey"];
    NSArray *array = [NSJSONSerialization JSONObjectWithData:savedString options:NSJSONReadingAllowFragments error:nil];
    self.logStingArray = [NSMutableArray arrayWithArray:array];
    [self.logStingArray addObject:@"\n-----------------RECORD-----------------\n\n"];
    self.consoleWindow.consoleRootViewController.dataSource = self.logStingArray;
}

- (NSMutableArray *)logStingArray {
    if(!_logStingArray){
        _logStingArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _logStingArray;
}

- (void)handleReceiveMemoryWarningNotification {
    [self.logStingArray removeAllObjects];
    [self.logStingArray addObject:@"收到了系统内存警告!所有日志被清空!"];
    self.consoleWindow.consoleRootViewController.dataSource = self.logStingArray;
}

#pragma mark- gesture function
- (void)panGesture:(UIPanGestureRecognizer *)gesture {
    if (_isFullScreen == YES) {// do nothing when it fullScreen.
        return;
    }
    if(gesture.state == UIGestureRecognizerStateChanged){
        CGPoint translation = [gesture translationInView:gesture.view];
        CGRect rect = CGRectOffset(self.consoleWindow.frame, translation.x, translation.y);
        self.consoleWindow.frame = rect;
        [gesture setTranslation:CGPointZero inView:gesture.view];
    }else if (gesture.state == UIGestureRecognizerStateEnded||gesture.state == UIGestureRecognizerStateCancelled){
        CGRect rect = self.consoleWindow.frame;
        if(self.consoleWindow.center.y<rect.size.height/2.0f){
            rect.origin.y = KIsiPhoneX?44:20;
        }else if (self.consoleWindow.center.y>[UIScreen mainScreen].bounds.size.height-rect.size.height/2.0f){
            rect.origin.y = [UIScreen mainScreen].bounds.size.height-rect.size.height;
        }else{
            if(self.consoleWindow.center.x<[UIScreen mainScreen].bounds.size.width/2.0f){
                rect.origin.x = 0;
            }else{
                rect.origin.x = [UIScreen mainScreen].bounds.size.width-rect.size.width;
            }
        }
        self.consoleWindow.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.consoleWindow.frame = rect;
        } completion:^(BOOL finished) {
            self.consoleWindow.userInteractionEnabled = YES;
        }];
    }
}
/**
tap
 */
- (void)tapImageView:(UITapGestureRecognizer *)tapGesture{
    [self maximumAnimation];
}

//全屏
- (void)maximumAnimation {
    if (!_isFullScreen) {
        // becoma full screen
        self.consoleWindow.consoleRootViewController.dataSource = self.logStingArray;
        [UIView animateWithDuration:0.25 animations:^{
            [self.consoleWindow maxmize];
        } completion:^(BOOL finished) {
            self->_isFullScreen = YES;
            if(!finished){
                [self.consoleWindow maxmize];
            }
            [self scrollToBottom];
        }];
    }
}

- (void)minimizeAnimation {
    //退出全屏
    [UIView animateWithDuration:0.25 animations:^{
        [self.consoleWindow minimize];
    } completion:^(BOOL finished) {
        self->_isFullScreen = NO;
        if(!finished){
            [self.consoleWindow minimize];
        }
    }];
}

- (void)scrollToBottom {
    if(self.logStingArray.count > 0){
        [self.consoleWindow.consoleRootViewController->_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.logStingArray.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
}


- (UIPanGestureRecognizer *)panOutGesture{
    if (!_panOutGesture) {
        _panOutGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGesture:)];
    }
    return _panOutGesture;
}
@end
