//
//  FarmManiaAppController.h
//  FarmMania
//
//  Created by  James Lee on 13-5-1.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//

@class RootViewController;

@interface AppController : NSObject <UIAccelerometerDelegate, UIAlertViewDelegate, UITextFieldDelegate,UIApplicationDelegate> {
    UIWindow *window;
    RootViewController    *viewController;

    // snsgame start
	BOOL isPaused;
	BOOL isGameStarted;
	NSDictionary *notifyInfo;
    // snsgame stop


}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) RootViewController *viewController;



// snsgame start
// 加载配置文件
- (void) onLoadGameConfig:(NSNotification *)note;
// 加载游戏数据
- (void) onLoadGameData:(NSNotification *)note;
// 启动游戏场景
- (void) onStartGameScene:(NSNotification *)note;
// snsgame stop



@end

