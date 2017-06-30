# GHConsole
a easy embeded Console in iPhone or iPad for iOS developer//  一个一行代码集成可在iPhone 或者iPad界面上显示的控制台     

//集成方法：
1.在APPdelegate中导入头文件
#import "GHConsole.h"
2.在app启动的方法中去实现：[[GHConsole sharedConsole]startPrintString];

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
[[GHConsole sharedConsole]startPrintString];

return YES;
}

ok 大功告成！
