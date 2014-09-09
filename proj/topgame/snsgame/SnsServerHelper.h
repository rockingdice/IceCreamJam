//
//  TapjoyHelper.h
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifdef SNS_ENABLE_IOS6
#import <StoreKit/SKStoreProductViewController.h>
#endif
#import "ASIHTTPRequestDelegate.h"
#import "SyncQueue.h"
#import "SnsLoadingView.h"
#import "SmInGameLoadingView.h"
#import "SNSAlertView.h"
#import "InAppStoreDelegate.h"
#import "ASIHTTPRequest.h"
#ifdef SNS_ENABLE_KOCHAVA
#import "TrackAndAd.h"
#endif


@interface SnsServerHelper : NSObject<SyncQueueDelegate, UIAlertViewDelegate, ASIHTTPRequestDelegate,
#ifdef SNS_ENABLE_IOS6
SKStoreProductViewControllerDelegate,
#endif
#ifdef SNS_ENABLE_KOCHAVA
KochavaTrackerClientDelegate,
#endif
SNSAlertViewDelegate,InAppStoreDelegate> {
	BOOL m_isSessionInitialized;
	BOOL isCheckingNetworkStatus;
	int  checkingStep; // 0-checking status, 1-loading market items, 2-loading save
	ASIHTTPRequest *timeRequest;
	BOOL 	isPaused;
	BOOL    isGameStarted;
    BOOL    isPaymentStarted;
	
	UIView        *m_mainWindow;
	SnsLoadingView  *m_loadingView;
	SmInGameLoadingView *m_inGameLoading;
    
    id      m_adMobController;
    BOOL    isNetworkOK;
    
    UIBackgroundTaskIdentifier bgTaskID;
    int     bgTaskTime;
    NSString *pendingURLGift;
    NSDictionary *m_launchOptions;
    int     newUID;
    int     oldUID;
    NSDictionary *pendingCrossPromoTask;
}

@property (nonatomic, assign) BOOL isEnableLocalNotification;
#ifdef SNS_ENABLE_KOCHAVA
@property(readonly) KochavaTracker *kochavaTracker;
#endif

+(SnsServerHelper *)helper;

// initSession
- (void) initSession:(UIView *)mainWindow;
// initSession with lauchoption
- (void) initSession:(UIView *)mainWindow withLaunchOptions:(NSDictionary *)options;
// 开始加载游戏
- (void) startLoadGame;

// 保存DeviceToken
-(void) saveDeviceToken:(NSData *)token;
// 初始化网络监听器
-(void) initNetworkListener;
// 初始化社交模块切换监听器
-(void) initChangeSocialAccountListener;//添加社交模块切换账户的侦听
// 初始化广告
-(void) initPaymentAndAds;
// 刷新session状态
-(void) refreshSessionStatus;

// 初始化付费监听
-(void) onReceivePayment:(NSNotification *)note;
// 网络状况变化时调用
-(void) onNetworkStatusChanged:(NSNotification *)note;
// 帐号切换时调用
-(void) onAccountChanged:(NSNotification *)notification;
// 检查网络是否存在
-(void) checkNetworkStatus;
// 检查用户最新状态
-(void) checkPlayerStatus;
// 正式进入游戏
-(void) startGameScene;
- (void) setForceLoadStatus;
// 设置无网络标志
- (void) setNetworkStatus:(BOOL)networkOK;

-(void) startLoadingResource:(BOOL)block;
// 加载iPad教程图
-(void)startLoadingTutorial;
// show preview image
-(void)showPreviewScene;
// load images of notice
-(void) loadNoticeImage;
// 检查是否有丢失的资源文件
- (void) checkLostCacheResource;
// 检查是否有强制更新状态和黑名单状态，如果有，就返回YES，否则返回NO
- (BOOL) checkForceUpdateOrBlock;
// 显示bug修复提示
- (void) showBugFixHint:(NSDictionary *)info;
// 设置是否允许本地通知
- (void) setNotificationStatus:(BOOL)enabled;
// 获得本地通知状态
- (BOOL) getNotificationStatus;

// 程序进入后台时调用
-(void) onApplicationGoesBackground;
// 从后台恢复时调用
- (void) onApplicationGoesForground;
// 处理打开URL的请求
- (BOOL) handleOpenURL:(NSURL *)url;
// 设置URL礼物
- (void) setFacebookURLGift:(NSString *)gift;

// 设置本地通知
- (void) scheduleLocalNotifications;
- (void) scheduleLocalNotificationWithBody:(NSString *)body andAction:(NSString *)action andSound:(NSString *)sound andInfo:(NSDictionary *)info atTime:(NSDate*)dt;

// 是否支持本地通知
- (BOOL) localNotificationEnabled;

// 显示加载等候界面
- (void) onShowLoadingScene:(NSNotification *)note;
- (void) onHideLoadingScene:(NSNotification *)note;
// 显示游戏内等候界面
- (void) onShowInGameLoadingView:(NSNotification *)note;
- (void) onHideInGameLoadingView:(NSNotification *)note;

// 完成发送邮件
-(void) onComposeEmailFinished:(NSNotification *)note;

// 完成发送申诉邮件
-(void) onComposeAppealEmailFinished:(NSNotification *)note;

// 显示AdMob广告
- (void) showAdmobBanner;
// 隐藏admob广告
- (void) hideAdmobBanner;
// 创建AdMob广告View
- (void) initAdMobBanner;
// 启动TinyMobi
- (void) startTinyMobi;

-(void) showAppStoreView:(NSString *)appID withLink:(NSString *)link;

// 删除服务器上的存档
- (void) resetSaveDataOnServer;
// facebook 账号绑定
- (void) loginWithFacebookAccount;

- (void) startCrossPromoTask:(NSDictionary *)noticeInfo;

#ifdef DEBUG
// 列出一个目录下的所有文件
- (void) showFilesOfPath:(NSString *)path;
#endif

@end
