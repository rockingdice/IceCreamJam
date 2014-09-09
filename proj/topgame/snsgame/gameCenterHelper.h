//
//  account.h
//  iPetHotel
//
//  Created by yang jie on 11/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "Reachability.h"

#define kGameCenterNextTime @"kGameCenterNextTime"
#define kGameCenterUnlockAchieveiment @"kGameCenterUnlockAchieveiment"
#define gcAchievementQueuePlistPath @"achievmentQueue.plist"

@interface GameCenterHelper : UIView <GKLeaderboardViewControllerDelegate, GKAchievementViewControllerDelegate,GKGameCenterControllerDelegate>{
    BOOL    isStarted;
    NSMutableArray *				GCAlerts;
    BOOL							connectedToInternet;
    BOOL							isAchievmentQueueSubmiting;
    Reachability *					hostReach;
    BOOL							isAnimation;
	GKLeaderboardViewController *	leaderboardController;
	GKAchievementViewController *	achievementController;
	NSString *						needShow;
	NSString *						leaderCategory;
    
    NSArray                      *leaderBoards;
    int checkingStatus;
    int lastCheckTime;
    int pendingTask;
    int requestType;
    int gcUID;
    UIViewController *loginViewController;
    BOOL  bShowLoginView;
}

@property (nonatomic) BOOL isLogin;
@property (nonatomic, retain) NSMutableArray *friendList;
@property (nonatomic, retain) NSMutableArray *alreadyUnlockAchievmentList;
@property (nonatomic, retain) NSMutableDictionary *achievmentList;
@property (nonatomic, retain) NSMutableArray *achievmentQueue;
@property (nonatomic, retain) NSMutableArray *scoreQueue;

+ (GameCenterHelper *)initGameCenter;
+ (GameCenterHelper *)helper;
- (BOOL)isGameCenterAvailable;

- (void)authenticateLocalUser;
- (void)registerForAllNotification;
- (void)updateGameCenterPlayer:(NSError*) error;

- (void)retrieveFriends;
- (void)loadPlayerData:(NSArray *)identifiers;

- (void)loadAchievements;
- (GKAchievement*)getAchievementForIdentifier:(NSString *)identifier;
//提交荣誉到gamecenter
// - (void)reportAchievementIdentifier:(NSString*)identifier percentComplete:(float)percent;
- (NSArray*)retrieveAchievmentMetadata;
- (NSString*) getCurrentLanguage;
- (void)showAlertWithTitle:(NSString*)title message:(NSString*)message identifier:(NSString *)identifier;
- (void)animateAlert;

- (void)commitAchievmentToQueue:(NSString*)identifier percentComplete:(float)percent;
- (void)removeAchievmentFromQueue:(NSString *)identifier;
- (void)checkAchievmentQueueAndSubmit;

- (void)reportScore:(int)score forCategory:(NSString*)category;
- (void)commitSource;
- (void)retrieveTopTenScores;

//显示leaderboard
- (void)showLeader:(NSString *)category;
//显示AchievementBoard
- (void)showAchievement;


// 登陆gamecenter，如果force＝YES，就忽略掉过滤条件
- (void) checkLogin:(BOOL)force;
// 显示GameCenter
- (void) showGameCenter;
// 显示banner
- (void) showBanner;
// 提交排行榜分数
- (void) reportScore: (int64_t) score forLeaderboardID: (NSString*) identifier;
// 提交成就
- (void) reportAchievementIdentifier: (NSString*) identifier percentComplete: (float) percent;

// 获取用户名字
- (NSString *)getUserName;
// 获取用户ID
- (NSString *)getUserID;

@end
