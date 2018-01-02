#  ![Alt text](http://img.njbanban.com/GHOwn/GHConsoleLogo2.png)

# GHConsole


中文版本请参看[这里](https://github.com/Liaoworking/GHConsole/wiki)


An easy  and wireless way to get what you had logged and wanted to see in your App.

[![Pod Version](https://img.shields.io/badge/Pod-1.4.0-6193DF.svg)](https://cocoapods.org/)
![Swift Version](https://img.shields.io/badge/xCode-9.1+-blue.svg)
![Swift Version](https://img.shields.io/badge/iOS-7.0+-blue.svg) 
![Plaform](https://img.shields.io/badge/Platform-iOS-lightgrey.svg)
![License MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg) 

![Alt text](http://oyrr7ye20.bkt.clouddn.com/GHOwn/Untitled.gif)


## Installation
Simply add GHConsole folder with files to your project, or use CocoaPods.

#### CocoaPods
You can use [CocoaPods](http://cocoapods.org/) to install `GHConsole` by adding it to your `Podfile`:

```ruby
platform :ios, '7.0'
use_frameworks!
#you need to update your CocoaPods version if you can't find this pod.
target 'your_project_name' do
	pod 'GHConsole'
end
```

## Usage example

Simply start GHConsole in your App. GHConsole view will be added above the key window as a view.

You can find example projects [here](https://github.com/liaoworking/GHConsole)

#### Start Log on GHConsole

You just only initialize GHConsole in your appDelegate.m When your App are launching.


```Objective-C
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   [[GHConsole sharedConsole]startPrintLog];
    return YES;
}
```

And then, you can use GGLog( ) like NSLog( )

```Objective-C
GGLog(@"This is some log I just want to show in GHConsole")；




  NSDictionary *parameterDict = @{@"paraKey1":@"paraValue1",
                                    @"paraKey2":@"paraValue2",
                                    @"paraKey3":@"paraValue2"
                                    }
GGLog(@"%@",parametersDict);

//if you  want to see the responsJSon from the API, you can just use GGLog( ) like NSLog( ) here.
GGLog(@"%@",responsJSON);
```
When you double tap  The GHConsole in your app and then the appearance of it just like this.
![Alt text](http://img.njbanban.com/GHOwn/67732829-C757-49AB-B7A4-2089124C580E.png)

#### Stop Logging

Call when you're done with GHConsole.

```Objective-C
[GHConsole shareConsole]stop];
```

if you don't want to see the GHConsole,you just need to annotate it.

```Objective-C
//[[GHConsole sharedConsole]startPrintLog];
```


## Features
GHConsole is at an inconspicuous position in your app.Multiple gesture was added in GHConsole. double tap to make it Full Screen and back.

This framework only contains two files 

**GHConsole.h**

**GHConsole.m**

Easy to use and uninstall.

you can see **the number of the line** for your GGLog( ) and **function name** clearly in GHConslole.

A **clear button** on GHConsole can remove some useless log.

## Configuration

Sorry. The GHConsole is too easy to have any configuration. If you have any good idea or demand you can tell me at my git or email.



## Requirements
- iOS 7.0+


## Contributors List:
zhoushaowen - [https://github.com/zhoushaowen](https://github.com/zhoushaowen)

Kane - [https://github.com/KaneLanF](https://github.com/KaneLanF)
## Meta

Liao Guanghui - [Blog](https://liaoworking.com) - [FB](https://www.facebook.com/guanghui.liao.3)


GHConsole is available under the MIT license. See the LICENSE file for more info.




