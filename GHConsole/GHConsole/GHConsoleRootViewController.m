//
//  GHConsoleRootViewController.m
//  GHConsole
//
//  Created by zhoushaowen on 2017/12/5.
//  Copyright © 2017年 廖光辉. All rights reserved.
//

#import "GHConsoleRootViewController.h"

@interface GHConsoleRootViewController ()
{
    UITextView *_textView;
}

@end

@implementation GHConsoleRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
        _textView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
#endif
    [self.view addSubview:_textView];
    _textView.text = self.text;
    [_textView scrollRectToVisible:CGRectMake(0, _textView.contentSize.height-15, _textView.contentSize.width, 10) animated:YES];
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
