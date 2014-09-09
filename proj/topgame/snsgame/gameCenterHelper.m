//
//  account.m
//  iPetHotel
//
//  Created by yang jie on 11/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import "gameCenterHelper.h"
#import "socialConfig.h"
#import "UIImageView+WebCache.h"
#import "SystemUtils.h"
#import "NetworkHelper.h"
#import "SnsServerHelper.h"
#import "StringUtils.h"
#import "ASIFormDataRequest.h"
#ifndef MODE_COCOS2D_X
#import "cocos2d.h"
#endif

enum {
    kSNSGameCenterTaskNone,
    kSNSGameCenterTaskShowBoard,
};

enum {
    kGCHelperRequestTypeNone,
    kGCHelperRequestTypeBindAccount,
};
#define kSNSGCAlertTagSwitchAccount 1
#define kSNSGCStatusLogin  1
#define kSNSGCStatusUserCancel 2

static GameCenterHelper *_gameCenterHelper = nil;

@implementation GameCenterHelper
@synthesize friendList, achievmentList, isLogin, alreadyUnlockAchievmentList;
@synthesize achievmentQueue;
@synthesize scoreQueue;

#pragma mark - init function & public method

+ (GameCenterHelper *)helper {
    @synchronized(self) {
        if (_gameCenterHelper == nil) {
            _gameCenterHelper = [[self alloc] init];
        }
    }
    return _gameCenterHelper;
}

+ (GameCenterHelper *) initGameCenter {
    return [self helper];
}

+ (id)alloc {
	@synchronized([GameCenterHelper class]) { 
		NSAssert(_gameCenterHelper == nil, @"Attempted to allocate a second instance of a singleton.");
		_gameCenterHelper = [super alloc];
		return _gameCenterHelper;
	}
	return nil;
}

- (id)init {
    self = [super init];
    if (self) {
        isStarted = NO;
        isAchievmentQueueSubmiting = NO;
        isLogin = NO;
        GCAlerts = [[NSMutableArray alloc] init];
        achievmentList = [[NSMutableDictionary alloc] init];
		achievmentQueue = [[NSMutableArray alloc] init];
		scoreQueue = [[NSMutableArray alloc] init];
        pendingTask = kSNSGameCenterTaskNone;
        checkingStatus = 0;
        leaderBoards = nil; loginViewController = nil; lastCheckTime = 0;
        bShowLoginView = NO;
		if ([self isGameCenterAvailable]) {
			[self registerForAllNotification];
		}
        //注册成就列队的观察者
        //[[NSNotificationCenter defaultCenter] postNotificationName:kAchievmentQueueNotification object:achievmentQueue];
    }
    return self;
}

#pragma mark - check account status

- (void)registerForAllNotification {
    //验证是否登录
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationChanged) name:GKPlayerAuthenticationDidChangeNotificationName object:nil];
    
    //验证网络
    // [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
	
    //直接检查一个适合很多国家地区访问的网站（直接检查苹果的服务器中国连不连的上）
	// NSString *host = @"gcsb.itunes.apple.com";
	//if([[SystemUtils getCountryCode] isEqualToString:@"CN"]) host = @"www.baidu.com";
	// hostReach = [[Reachability reachabilityWithHostName:host] retain];
	// [hostReach startNotifer];
    
    //成就列队
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkAchievmentQueueAndSubmit) name:kAchievmentQueueNotification object:nil];
}

- (void)removeAllNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GKPlayerAuthenticationDidChangeNotificationName object:nil];
    // [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAchievementQueueNotification object:nil];
}

- (void)authenticationChanged {
	if(![self isGameCenterAvailable]) return;
    if ([GKLocalPlayer localPlayer].isAuthenticated) {
        //这里放认证成功之后执行的代码
        isStarted = YES;
        isLogin = YES;
        //获得所有成就
        [self retrieveAchievmentMetadata];
        if(pendingTask==kSNSGameCenterTaskShowBoard) {
            [self showGameCenter];
            pendingTask = kSNSGameCenterTaskNone;
        }
        [self loadLeaderboardInfo];
        //获得该用户得到的所有成就
        [self loadAchievements];
        //获得所有好友
        //[self retrieveFriends];
		[self checkAchievmentQueueAndSubmit];
		[[SnsServerHelper helper] onHideInGameLoadingView:nil];
		if (needShow) {
			if ([needShow isEqualToString:@"leader"]) {
				[self showLeader:leaderCategory];
			} else if ([needShow isEqualToString:@"achievement"]) {
				[self showAchievement];
			} else {
				needShow = nil;
			}
		}
    } else {
        //这里放认证失败之后的操作
        isLogin = NO;
        if (gcAutoAuthentication) {
            // [self authenticateLocalUser];
        }
    }
    
#ifdef BRANCH_CN
    NSDictionary* userInfo = NULL;
    if ([GKLocalPlayer localPlayer].alias) {
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[GKLocalPlayer localPlayer].alias,@"name",  nil];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSyncUserInfo object:Nil userInfo:userInfo];
#endif
}

#pragma mark - login

- (BOOL)isGameCenterAvailable {
    // Check for presence of GKLocalPlayer API.
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
	if(gcClass == nil) return NO;
    // The device must be running running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    return (gcClass && osVersionSupported);
}

- (void) loginFinished:(BOOL) success
{
    self.isLogin = success;
    if(!success) return;
    // start bind fbid with userID
    NSString *bindUID = [SystemUtils getNSDefaultObject:@"kGCBindUID"];
#ifdef DEBUG
    bindUID = nil;
#endif
    if(bindUID==nil) {
        [self startBind];
    }
    
}

- (void) checkLogin:(BOOL)force
{
	SNSLog(@"%s",__FUNCTION__);
	if(![self isGameCenterAvailable]) return;
	// if(![NetworkHelper helper].connectedToInternet) return;
    if(self.isLogin) return;
    if(checkingStatus==kSNSGCStatusUserCancel && lastCheckTime<[SystemUtils getCurrentTime]-43200)
        checkingStatus = 0;
    if(checkingStatus!=0) {
        if(checkingStatus==kSNSGCStatusUserCancel && force) {
            // show alert
            [self showUserCancelAlert];
        }
        return;
    }
    if(!force) {
#ifndef DEBUG
	// 检查是否设置了下次检测的时间
	int nextTime = [[SystemUtils getPlayerDefaultSetting:kGameCenterNextTime] intValue];
	if(nextTime > [SystemUtils getCurrentTime]) return;
#endif
    }
    NSString *osVer = [SystemUtils getiOSVersion];
    if([osVer compare:@"6.0"]>=0) {
        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        if(localPlayer.isAuthenticated) {
            [self loginFinished:YES];
            return;
        }
        if(loginViewController!=nil) {
            if(force) {
                bShowLoginView = YES;
                [[SystemUtils getRootViewController] presentViewController:loginViewController animated:YES completion:nil];
            }
            return;
        }
        checkingStatus = kSNSGCStatusLogin;
        localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
            SNSLog(@"auth complete, viewController:%@ error:%@", viewController, error);
            checkingStatus = 0;
            if(error) {
				[self updateGameCenterPlayer:error];
            }
            if (localPlayer.isAuthenticated)
            {
                //authenticatedPlayer: is an example method name. Create your own method that is called after the loacal player is authenticated.
                // [self authenticatedPlayer: localPlayer];
                [self loginFinished:YES];
            }
            else if (viewController != nil)
            {
                //showAuthenticationDialogWhenReasonable: is an example method name. Create your own method that displays an authentication view when appropriate for your app.
                // [self showAuthenticationDialogWhenReasonable: viewController];
                if(force) {
                    bShowLoginView = YES;
                    [[SystemUtils getRootViewController] presentViewController:viewController animated: YES completion:nil];
                }
                loginViewController = viewController;
            }
            else
            {
                // disabled
                // [self disableGameCenter];
            }
        };
        return;
    }
    
    //判断是否认证过并且网络连接可用
    if(![GKLocalPlayer localPlayer].isAuthenticated) {
		SNSLog(@"%s: start check",__FUNCTION__);
        checkingStatus = kSNSGCStatusLogin;
        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:^(NSError *error) {
            checkingStatus = 0;
            if(error == nil) {
				SNSLog(@"%s: gamecenter login ok",__FUNCTION__);
                [self loginFinished:YES];
                
                //认证成功,获取当前用户信息
                //NSLog(@"认证成功！");
                //NSLog(@"1--alias--.%@",[GKLocalPlayer localPlayer].alias);
                //NSLog(@"2--authenticated--.%d",[GKLocalPlayer localPlayer].authenticated);
                //NSLog(@"3--isFriend--.%d",[GKLocalPlayer localPlayer].isFriend);
                //NSLog(@"4--playerID--.%@",[GKLocalPlayer localPlayer].playerID);
                //NSLog(@"5--underage--.%d",[GKLocalPlayer localPlayer].underage);
                //[self retrieveFriends];
                //[self reportAchievementIdentifier:@"com.diogame.petinn.Pet_lover" percentComplete:100.0];
            } else {
				[self updateGameCenterPlayer:error];
                //失败
                //[self authenticateLocalUser];
                //NSLog(@"认证失败:%@",[error localizedDescription]);
            }
        }];
    }
	else {
		SNSLog(@"%s: already logged in", __FUNCTION__);
        [self loginFinished:YES];
	}
}

- (void)updateGameCenterPlayer:(NSError*) error {
	SNSLog(@"%s: error:%@", __FUNCTION__, error);
	if(!error) {
		// login ok, reset next time
		[SystemUtils setPlayerDefaultSetting:[NSNumber numberWithInt:0] forKey:kGameCenterNextTime];
	} else if(error.code == GKErrorCommunicationsFailure) {
		// Couldn't connect with Game Center, continue as normal
		SNSLog(@"%s: commmunication error", __FUNCTION__);
	} else if(error.code == GKErrorCancelled) {
		// User canceled when logging into Game Center, continue as normal
		// set next time to ten days later
        checkingStatus = kSNSGCStatusUserCancel; lastCheckTime = [SystemUtils getCurrentTime];
#ifndef DEBUG
		int nextTime = [SystemUtils getCurrentTime] + 86400 * 10;
		[SystemUtils setPlayerDefaultSetting:[NSNumber numberWithInt:nextTime] forKey:kGameCenterNextTime];
		SNSLog(@"%s: set next time to ten days later", __FUNCTION__);
#endif
	}
	
}

- (void)authenticateLocalUser {
    [self checkLogin:NO];
}

// 获取用户名字
- (NSString *)getUserName
{
    if(!self.isLogin) return nil;
    return [GKLocalPlayer localPlayer].displayName;
}
// 获取用户ID
- (NSString *)getUserID
{
    if(!self.isLogin) return nil;
    return [GKLocalPlayer localPlayer].playerID;
}


#pragma mark -
#pragma mark display

- (void) showGameCenter {
    if(![self isGameCenterAvailable])return;
    if (!self.isLogin) {
        [self checkLogin:YES];
    }
    if (!self.isLogin) {
        pendingTask = kSNSGameCenterTaskShowBoard;
        return;
    }
    Class gcClass = (NSClassFromString(@"GKGameCenterViewController"));
	if(gcClass == nil) {
        SNSLog(@"GKGameCenterViewController class not exist");
        [self showLeader:nil];
        return;
    }
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;
        
        // gameCenterController.viewState = GKGameCenterViewControllerStateAchievements;
        bShowLoginView = YES;
        UIViewController *root = [SystemUtils getRootViewController];
        [root presentViewController: gameCenterController animated: YES completion:^(void) {
            bShowLoginView = NO;
        }];
        [gameCenterController autorelease];
    }
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    UIViewController *root = [SystemUtils getRootViewController];
    [root dismissViewControllerAnimated:YES completion:nil];
    // loginViewController = nil;
    if(checkingStatus==kSNSGCStatusLogin)
        checkingStatus = 0;
}

- (void) showBanner
{
    NSString* title = @"Sample Title";
    NSString* message = @"Sample Message";
    [GKNotificationBanner showBannerWithTitle: title message: message
                            completionHandler:^{
                                SNSLog(@"showBanner finish");
                            }];
}

#pragma mark -
#pragma mark leaderboard

- (void) loadLeaderboardInfo
{
    if([[SystemUtils getiOSVersion] compare:@"7.0"]<0) {
        [GKLeaderboard loadCategoriesWithCompletionHandler:^(NSArray *leaderboards, NSArray *titles, NSError *error)
         {
             if(leaderBoards!=nil) [leaderBoards release];
             leaderBoards = [leaderboards retain];
             SNSLog(@"loeaderBoards: %@", leaderBoards);
         }];
    
        return;
    }
    [GKLeaderboard loadLeaderboardsWithCompletionHandler:^(NSArray *leaderboards, NSError *error)
     {
         if(leaderBoards!=nil) [leaderBoards release];
         leaderBoards = [leaderboards retain];
         SNSLog(@"loeaderBoards: %@", leaderBoards);
     }];
}

// 获得前缀
- (NSString *)getIDPrefix
{
    NSString *prefix = [SystemUtils getSystemInfo:@"kGameCenterPrefix"];
    if(prefix==nil || [prefix length]<3) prefix = [SystemUtils getSystemInfo:@"kIapItemPrefix"];
    if(prefix==nil || [prefix length]<3) return nil;
    return prefix;
}

// 提交分数
- (void) reportScore: (int64_t) score forLeaderboardID: (NSString*) identifier
{
    if(![self isGameCenterAvailable]) return;
    [self checkLogin:NO];
    if(!self.isLogin) {
        SNSLog(@"player not login");
        return;
    }
    
    NSString *key = [NSString stringWithFormat:@"score_%@",identifier];
#ifndef DEBUG
    double lastScore = [[SystemUtils getNSDefaultObject:key] doubleValue];
    if(lastScore>score) {
        SNSLog(@"no need to submit, lastScore:%lf score:%lld", lastScore, score);
        return;
    }
#endif
    [SystemUtils setNSDefaultObject:[NSString stringWithFormat:@"%lld",score] forKey:key];
    
    NSString *prefix = [self getIDPrefix];
    if(prefix!=nil) {
        if([identifier length]<[prefix length] || ![prefix isEqualToString:[identifier substringToIndex:[prefix length]]])
            identifier = [prefix stringByAppendingString:identifier];
    }
    // NSString *osVer = [SystemUtils getiOSVersion];
    // if([osVer compare:@"7.0"]<0) {
    GKScore *scoreReporter = [[GKScore alloc] initWithCategory:identifier];
    scoreReporter.value = score;
    // scoreReporter.context = 0;
    
    [scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
        // Do something interesting here.
        if(error) {
            SNSLog(@"failed to submit score(%lld) to leaderboard:%@ error:%@", score, identifier, error);
        }
        else {
            SNSLog(@"reportscore success!");
        }
    }];
    //    return;
    // }
    /*
    GKScore *scoreReporter = [[GKScore alloc] initWithLeaderboardIdentifier: identifier];
    scoreReporter.value = score;
    scoreReporter.context = 0;
    
    NSArray *scores = @[scoreReporter];
    [GKLeaderboard reportScores:scores withCompletionHandler:^(NSError *error) {
        if(error) {
            SNSLog(@"failed to submit score(%lld) to leaderboard:%@ error:%@", score, identifier, error);
        }
    }];
     */
}

#pragma mark -

#pragma mark achievement
// 提交成就
- (void) reportAchievementIdentifier: (NSString*) identifier percentComplete: (float) percent
{
    if(![self isGameCenterAvailable])return;
    [self checkLogin:NO];
    if(!self.isLogin) {
        SNSLog(@"player not login");
        return;
    }
    
    NSString *prefix = [self getIDPrefix];
    if(prefix!=nil) {
        if([identifier length]<[prefix length] || ![prefix isEqualToString:[identifier substringToIndex:[prefix length]]])
            identifier = [prefix stringByAppendingString:identifier];
    }
    
    GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier: identifier];
    if (achievement)
    {
        achievement.percentComplete = percent;
        [achievement reportAchievementWithCompletionHandler:^(NSError *error)
         {
             if (error != nil)
             {
                 SNSLog(@"Error in reporting achievements: %@", error);
             }
             else {
                 SNSLog(@"report achievement success:%@",identifier);
             }
         }];
    }
    else {
        SNSLog(@"invalid identifier:%@",identifier);
    }
}
#pragma mark -


#pragma mark bindUserID
- (void) startBind
{
    [self checkLogin:NO];
    if(!self.isLogin) return;
    
    NSString *gcid = [self getUserID];
    if(gcid==nil) return;
	NSString *sessionKey = [SystemUtils getSessionKey];
    if(!sessionKey) {
        [self loadCancel]; return;
    }
    requestType = kGCHelperRequestTypeBindAccount;
    NSString *prefix = [SystemUtils getSystemInfo:@"kHMACPrefix"];
    if(prefix==nil) prefix = @"";
    // fbid = [NSString stringWithFormat:@"%@%@",prefix,fbid];
	NSString *link = [NSString stringWithFormat:@"%@bindGameCenter.php", [SystemUtils getServerRoot]];
    SNSLog(@"link:%@ gcid:%@ sessionKey:%@",link, gcid, sessionKey);
	NSURL *url = [NSURL URLWithString:link];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
	[request setPostValue:gcid forKey:@"gcid"];
	[request setPostValue:prefix forKey:@"prefix"];
	[request setPostValue:sessionKey forKey:@"sessionKey"];
    
	[request setDelegate:self];
    [request startAsynchronous];
    
}

- (void) showSwitchAccountAlert:(int) newUID
{
    gcUID = newUID;
    NSString *fmt = [SystemUtils getLocalizedString:@"You've connected to an existing account before(UID:%d), will you switch to that account now?"];
    NSString *mesg = [NSString stringWithFormat:fmt, gcUID];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Account Detected"]
                              message:mesg
                              delegate:self
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"Cancel"]
                              otherButtonTitles:[SystemUtils getLocalizedString:@"OK"],nil];
    
    alertView.tag = kSNSGCAlertTagSwitchAccount;
    [alertView show];
    [alertView release];
    
}

- (void) showBindSuccessAlert
{
    NSString *mesg = [SystemUtils getLocalizedString:@"You've link this player with your GameCenter account. You can retrieve your game data on other devices by login your GameCenter acocunt."];
    // NSString *mesg = [NSString stringWithFormat:@"You've connected to an existing account before(UID:%d), will you switch to that account now?", gcUID];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Account Linked"]
                              message:mesg
                              delegate:nil
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                              otherButtonTitles:nil];
    
    [alertView show];
    [alertView release];
    
}

- (void) showUserCancelAlert
{
    NSString *mesg = [SystemUtils getLocalizedString:@"Because you've cancelled GameCenter login more than twice, GameCenter is disable for this game on this device."];
    // NSString *mesg = [NSString stringWithFormat:@"You've connected to an existing account before(UID:%d), will you switch to that account now?", gcUID];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"User Cancelled"]
                              message:mesg
                              delegate:nil
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                              otherButtonTitles:nil];
    
    [alertView show];
    [alertView release];
    
}

- (void)loadCancel
{
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	SNSLog(@"%s status code:%i",__FUNCTION__, request.responseStatusCode);
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		[self loadCancel];
		return;
	}
    
    // kFacebookHelperRequestTypeBindAccount
	NSString *text = [request responseString];
    SNSLog(@"resp:%@", text);
	
	// [NetworkHelper helper].connectedToInternet = YES;
    NSDictionary *dict = [StringUtils convertJSONStringToObject:text];
    if(dict==nil) {
		SNSLog(@"invalid response:%@", text);
		[self loadCancel];
		return;
	}
    int success = [[dict objectForKey:@"success"] intValue];
    if(success==1) {
        // bind success
        [SystemUtils setNSDefaultObject:[SystemUtils getCurrentUID] forKey:@"kGCBindUID"];
        if([[dict objectForKey:@"first"] intValue]==1) {
            [self showBindSuccessAlert];
        }
    }
    else if(success==-1) {
        // this uid already bind to another facebookID
        [SystemUtils setNSDefaultObject:[SystemUtils getCurrentUID] forKey:@"kGCBindUID"];
    }
    else if(success==-2) {
        // this facebookID already bind to another uid
        int newUID = [[dict objectForKey:@"uid"] intValue];
        [SystemUtils setNSDefaultObject:[NSString stringWithFormat:@"%d",newUID] forKey:@"kGCBindUID"];
        // show alert
//        if(newUID>0)
//            [self showSwitchAccountAlert:newUID];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	SNSLog(@"%s - error: %@", __FUNCTION__, error);
	[self loadCancel];
}

#pragma mark -


#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1314)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUi" object:nil];
        return;
    }
    if(alertView.tag == kSNSGCAlertTagSwitchAccount && buttonIndex==1) {
        // switch account
        NSString *uid = [NSString stringWithFormat:@"%d",gcUID];
        [SystemUtils setCurrentUID:uid];
        [SystemUtils showSwitchAccountHint];
        [SystemUtils clearSessionKey];
    }
}

#pragma mark Get Friend's Method

- (void)retrieveFriends {
    if([self isGameCenterAvailable] && [GKLocalPlayer localPlayer].authenticated == YES && connectedToInternet) {
        GKLocalPlayer *lp = [GKLocalPlayer localPlayer];
        if (lp.authenticated) {
            [lp loadFriendsWithCompletionHandler:^(NSArray *friends, NSError *error) {
                if (error == nil) {
                    [self loadPlayerData:friends];
                } else {
                    ;// report an error to the user.
                }
            }];
        }
    }
}

- (void)loadPlayerData:(NSArray *)identifiers {
    [GKPlayer loadPlayersForIdentifiers:identifiers withCompletionHandler:^(NSArray *players, NSError *error) {
        if (error != nil) {
            SNSLog(@"获得好友列表详细信息失败");
            // Handle the error.
        }
        if (players != nil) {
            //NSLog(@"得到好友的alias成功,好友总数：%d", [players count]);
            for (int i=0; i<[players count]; i++) {
                GKPlayer *f = [players objectAtIndex:i];
                [friendList addObject:[NSDictionary dictionaryWithObjectsAndKeys:f.alias, @"name", f.playerID, @"id", nil]];
                //NSLog(@"friedns---alias---%@",friend1.alias);
                //NSLog(@"friedns---isFriend---%d",friend1.isFriend);
                //NSLog(@"friedns---playerID---%@",friend1.playerID);
            }
        } else {
            //NSLog(@"好友列表为空！");
        }
    }];
}

#pragma mark - Achievements Method

/*
 auother:orix
 param:identifier(成就id) percent(完成百分比，直接完成的成就传100进来即可) 
 method:提交一个成就，如果反复提交将不记录，比如一个成就已经达到100，那么如果你再提交一个80的进度，第一次提交的进度将不会被更改！
*/
/*
- (void)reportAchievementIdentifier:(NSString*)identifier percentComplete:(float)percent {
	if(![self isGameCenterAvailable]) return;
	if(![NetworkHelper helper].connectedToInternet) return;
    //判断是否已经认证并且可以连接到互联网
    if([GKLocalPlayer localPlayer].authenticated == YES) {
		SNSLog(@"%s: report achievement %@", __FUNCTION__, identifier);
        GKAchievement *achievement = [[[GKAchievement alloc] initWithIdentifier: identifier] autorelease];
        if (achievement) {
            achievement.percentComplete = percent;
			isAchievmentQueueSubmiting = NO;
            [achievement reportAchievementWithCompletionHandler:^(NSError *error) {
                if (error != nil) {
                    //NSLog(@"报告成就进度失败 ,错误信息为: \n %@",error);
                }else {
                    //NSLog(@"报告进度成功！");
                    //如果成就更新成功并且不是隐藏成就的话
                    //if (achievement.completed && !achievement.hidden) {
					
					
					NSDictionary *dic = [self.achievmentList objectForKey:identifier];
					//NSLog(@"%@", [dic description]);
					if (dic) {
						if (![alreadyUnlockAchievmentList containsObject:identifier]) {
							[alreadyUnlockAchievmentList addObject:identifier];
							[[NSUserDefaults standardUserDefaults] setObject:(NSObject *)alreadyUnlockAchievmentList 
																	  forKey:kGameCenterUnlockAchieveiment];
							NSString *title = [SystemUtils getLocalizedString:@"Achievement Earned!"];
							NSString *desc  = [SystemUtils getLocalizedString:[dic objectForKey:@"title"]];
							[self showAlertWithTitle:title message:desc identifier:identifier];
						}
						
						[self removeAchievmentFromQueue:identifier];
					} else {
						//因为可能没获得服务器端数据，所以wait一下
						// [self performSelector:@selector(checkAchievmentQueueAndSubmit) withObject:nil afterDelay:3.0f];
					}
					
                    //}
                    
                    //NSLog(@"    completed:%d",achievement.completed);
                    //NSLog(@"    hidden:%d",achievement.hidden);
                    //NSLog(@"    lastReportedDate:%@",achievement.lastReportedDate);
                    //NSLog(@"    percentComplete:%f",achievement.percentComplete);
                    //NSLog(@"    identifier:%@",achievement.identifier);
                }
            }];
        }
    }
}
*/
/*
 auother:orix
 method:加载这个用户目前获得的所有成就
*/
- (void)loadAchievements {
	/*
	if(![self isGameCenterAvailable]) return;
	if(![NetworkHelper helper].connectedToInternet) return;
	
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements,NSError *error) {
        if (error == nil) {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            NSArray *tempArray = [NSArray arrayWithArray:achievements];
            GKAchievement *tempAchievement;
            for (tempAchievement in tempArray) {
                [alreadyUnlockAchievmentList addObject:tempAchievement.identifier];
                //NSLog(@"    completed:%d",tempAchievement.completed);
                //NSLog(@"    hidden:%d",tempAchievement.hidden);
                //NSLog(@"    lastReportedDate:%@",tempAchievement.lastReportedDate);
                //NSLog(@"    percentComplete:%f",tempAchievement.percentComplete);
                //NSLog(@"    identifier:%@",tempAchievement.identifier);
            }
            [pool drain];
        }
		NSLog(@"%s:unlock achievement:%@", __FUNCTION__, alreadyUnlockAchievmentList);
    }];
	 */
	if (alreadyUnlockAchievmentList == nil) {
		alreadyUnlockAchievmentList = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kGameCenterUnlockAchieveiment]];
	}
	
	SNSLog(@"achievementList:%@", [alreadyUnlockAchievmentList description]);
}

/*
 auother:orix
 method:根据id获得成就
*/
- (GKAchievement*)getAchievementForIdentifier: (NSString *) identifier {
	if(![self isGameCenterAvailable]) return nil;
	if(![NetworkHelper helper].connectedToInternet) return nil;
	
    // NSMutableDictionary *achievementDictionary = [[NSMutableDictionary alloc] init];
    // GKAchievement *achievement = [achievementDictionary objectForKey:identifier];
    GKAchievement *achievement = [[[GKAchievement alloc] initWithIdentifier:identifier] autorelease];
    if (achievement == nil) {
        // achievement = [[[GKAchievement alloc] initWithIdentifier:identifier] autorelease];
        // [achievementDictionary setObject:achievement forKey:achievement.identifier];
    }
    // [achievementDictionary autorelease];
    return achievement;
}

/*
 auother:orix
 method:获得所有成就和图片（All）
*/
- (NSArray*)retrieveAchievmentMetadata {
	if(![self isGameCenterAvailable]) return nil;
	if(![NetworkHelper helper].connectedToInternet) return nil;
	
	
    if([GKLocalPlayer localPlayer].authenticated == YES) {
        //读取成就的描述
        [GKAchievementDescription loadAchievementDescriptionsWithCompletionHandler:^(NSArray *descriptions, NSError *error) {
            if (error != nil) {
                //NSLog(@"读取全部成就说明出错");
            }
            if (descriptions != nil) {
                GKAchievementDescription *achDescription;
                //NSLog(@"%d",[descriptions count]);
                for (achDescription in descriptions) {
                    NSAutoreleasePool * pool1 = [[NSAutoreleasePool alloc] init];
                    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:achDescription.title, @"title", achDescription.identifier, @"id", nil];
                    [self.achievmentList setObject:dic forKey:achDescription.identifier];
                    //NSLog(@"1..identifier..%@",achDescription.identifier);
                    //NSLog(@"2..achievedDescription..%@",achDescription.achievedDescription);
                    //NSLog(@"3..title..%@",achDescription.title);
                    //NSLog(@"4..unachievedDescription..%@",achDescription.unachievedDescription);
                    //NSLog(@"5............%@",achDescription.image);
                    //获取成就图片,如果成就未解锁,返回一个大问号
                    /*
                    [achDescription loadImageWithCompletionHandler:^(UIImage *image, NSError *error) {
                        if (error == nil) {
                            // use the loaded image. The image property is also populated with the same image.
                            NSLog(@"成功取得成就的图片");
                            UIImage *aImage = image;
                            UIImageView *aView = [[UIImageView alloc] initWithImage:aImage];
                            aView.frame = CGRectMake(50, 50, 200, 200);
                            aView.backgroundColor = [UIColor clearColor];
                            [[[CCDirector sharedDirector] openGLView] addSubview:aView];
                        } else {
                            //NSLog(@"获得成就图片失败");
                        }
                    }];*/
                    [pool1 drain];
                }
				SNSLog(@"%s: achievementList: %@",__FUNCTION__, achievmentList);
            }
        }];
    }
    return nil;
}

/*
 auother:orix
 method:提交获得的成就到成就队列
*/
- (void)commitAchievmentToQueue:(NSString*)identifier percentComplete:(float)percent {
    if(!isStarted) return;
	if (!self.isLogin && [self isGameCenterAvailable] && [NetworkHelper helper].connectedToInternet) {
		[self authenticateLocalUser];
	}
    BOOL canCommit = YES;
    SNSLog(@"[%s] - alreadyUnlockList:%@", __FUNCTION__, [alreadyUnlockAchievmentList description]);
    if (alreadyUnlockAchievmentList && [alreadyUnlockAchievmentList count]>0 && [alreadyUnlockAchievmentList containsObject:identifier]) {
		canCommit = NO;
		SNSLog(@"%s: already unlock Achievment:%@", __FUNCTION__, identifier);
		//如果有成就列队，并且没找到列队中的成就，那么把这个成就增加到已经获得的成就数组中
    } else {
		//由于程序那边不停的提交荣誉，所以如果没获得已得荣誉列表，那么直接返回
	}
//	if(canCommit) {
//		[alreadyUnlockAchievmentList addObject:identifier];
//		[[NSUserDefaults standardUserDefaults] setObject:alreadyUnlockAchievmentList 
//												  forKey:kGameCenterUnlockAchieveiment];
//	}

    if (canCommit && [self isGameCenterAvailable]) {
        NSString *realpath = [SystemUtils getDocumentRootPath];
		realpath = [realpath stringByAppendingString:gcAchievementQueuePlistPath];
        //NSLog(@"Path???:%@",[[NSMutableDictionary dictionaryWithContentsOfFile:realpath] description]);
        
        if (!achievmentQueue && [[NSFileManager defaultManager] fileExistsAtPath:realpath]) {
            achievmentQueue = [[NSMutableArray arrayWithContentsOfFile:realpath] retain];
			SNSLog(@"queue:%@", [achievmentQueue description]);
        }
        [achievmentQueue addObject:[NSDictionary dictionaryWithObjectsAndKeys:identifier, @"id", [NSString stringWithFormat:@"%f", percent], @"percent", nil]];
        //NSLog(@"%@",[achievmentQueue description]);
        if ([[NSFileManager defaultManager] fileExistsAtPath:realpath]) {
            [achievmentQueue writeToFile:realpath atomically:YES];
        }
        if (!isAchievmentQueueSubmiting) {
            [self checkAchievmentQueueAndSubmit];
        }
    }
}

/*
 auother:orix
 method:提交成就队列
*/
- (void)checkAchievmentQueueAndSubmit {
	if(!self.isLogin) return;
	if(![self isGameCenterAvailable]) return;
	if(![NetworkHelper helper].connectedToInternet) return;
	
    isAchievmentQueueSubmiting = YES;
    //NSLog(@"%s - %@", __FUNCTION__, [achievmentQueue description]);
    if ([achievmentQueue count] > 0) {
		//NSLog(@"code:%@", [dics description]);
        NSDictionary *dics = [achievmentQueue objectAtIndex:0];
		[self reportAchievementIdentifier:[dics objectForKey:@"id"] percentComplete:[[dics objectForKey:@"percent"] floatValue]];
    } else {
        isAchievmentQueueSubmiting = NO;
    }
}

/*
 auother:orix
 method:从成就队列中删除某一成就
*/
- (void)removeAchievmentFromQueue:(NSString *)identifier {
	if(![self isGameCenterAvailable]) return;
    //[achievmentQueue removeObjectForKey:identifier];
    NSDictionary *dics;
    for (NSUInteger i = 0;i<[achievmentQueue count];i++) {
        dics = [achievmentQueue objectAtIndex:i];
        //NSLog(@"code:%@", [dics description]);
        if ([[dics objectForKey:@"id"] isEqualToString:identifier]) {
            [achievmentQueue removeObjectAtIndex:i];
        }
    }
	
	NSString *realpath = [SystemUtils getDocumentRootPath];
	realpath = [realpath stringByAppendingString:gcAchievementQueuePlistPath];
	
    [achievmentQueue writeToFile:realpath atomically:YES];
    [self checkAchievmentQueueAndSubmit];
}

#pragma mark - Alert & message method

- (NSString*)getCurrentLanguage {
	return [SystemUtils getCurrentLanguage];
}

- (void)showAlertWithTitle:(NSString*)title message:(NSString*)message identifier:(NSString *)identifier {
    /*
	CGFloat widthScale = WINDOW_WIDTH/480.0f;
	CCLayer *gui = self;
	CCSprite *achievementBox = [CCSprite spriteWithFile:@"achievementBox.png"];
	[gui addChild:achievementBox z:100000 tag:9999];
	achievementBox.position = ccp(240*widthScale, -achievementBox.contentSize.height/2);
	
    //NSLog(@"func:%s - 系统语言 - %@", __FUNCTION__, [self getCurrentLanguage]);
	if([[self getCurrentLanguage] isEqualToString:@"zh-Hant"] || [[self getCurrentLanguage] isEqualToString:@"zh-Hans"]||
	   [[self getCurrentLanguage] isEqualToString:@"ja"])
	{
		CCLabelTTF *label1 = [CCLabelTTF labelWithString:title fontName:@"Arial" fontSize:26];
		CCLabelTTF *label2 = [CCLabelTTF labelWithString:message fontName:@"Arial" fontSize:26];
		label1.scale = 0.40;
		label1.opacity = 0xC0;
		label2.scale = 0.65;
		label1.position = ccp(achievementBox.contentSize.width/2, achievementBox.contentSize.height/2 + 18);
		label2.position = ccp(achievementBox.contentSize.width/2, achievementBox.contentSize.height/2 - 0);
		[achievementBox addChild:label1 z:1];
		[achievementBox addChild:label2 z:1];
	} else {
		CCLabelBMFont *label1 = [CCLabelBMFont labelWithString:title fntFile:@"ABD26.fnt"];
		CCLabelBMFont *label2 = [CCLabelBMFont labelWithString:message fntFile:@"ABD26.fnt"];
		label1.scale = 0.40;
		label1.opacity = 0xC0;
		label2.scale = 0.65;
		label1.position = ccp(achievementBox.contentSize.width/2, achievementBox.contentSize.height/2 + 18);
		label2.position = ccp(achievementBox.contentSize.width/2, achievementBox.contentSize.height/2 - 0);
		[achievementBox addChild:label1 z:1];
		[achievementBox addChild:label2 z:1];
	}
    
	
	[GCAlerts addObject:achievementBox];
    //NSLog(@"%@",[achievementBox description]);
    //NSLog(@"alert num:%d",[GCAlerts count]);
	
	if ([GCAlerts count] >0)
	{
		[self animateAlert];
	}
     */
	//NSLog(@"id:%@",identifier);
    UIView *alert = [[UIView alloc] init];
    alert.backgroundColor = [UIColor clearColor];
    UIImageView *customBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"achievementBox.png"]];
    [alert addSubview:customBackground];
    [alert sendSubviewToBack:customBackground];
	[customBackground release];
    alert.frame = CGRectMake(WINDOW_WIDTH/2-196/2, WINDOW_HEIGHT, 196, 60);
    
    UILabel *achievementTitle = [[UILabel alloc] init];
    UILabel *achievementContent = [[UILabel alloc] init];
    achievementTitle.text = title;
    achievementTitle.font = [UIFont fontWithName:@"Arial" size:12];
    achievementTitle.textColor = [UIColor colorWithRed:180 green:180 blue:180 alpha:1];
    achievementTitle.backgroundColor = [UIColor clearColor];
    achievementTitle.textAlignment = UITextAlignmentCenter;
    achievementTitle.frame = CGRectMake(40, 3, alert.frame.size.width - 40, 20);
	
    achievementContent.text = message;
    achievementContent.font = [UIFont fontWithName:@"Arial" size:14];
    achievementContent.textColor = [UIColor whiteColor];
    achievementContent.backgroundColor = [UIColor clearColor];
    achievementContent.textAlignment = UITextAlignmentCenter;
    achievementContent.frame = CGRectMake(34, 20, alert.frame.size.width - 34, 20);
    [alert addSubview:achievementTitle];
    [alert addSubview:achievementContent];
    [achievementTitle release];
    [achievementContent release];
	
	UIImageView *achievementImage = [[UIImageView alloc] init];
	achievementImage.frame = CGRectMake(13, 7, 34, 34);
	NSString *imageFile = nil;
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Achievement.plist" ofType:nil];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		//如果找到映射文件从本地读取成就图标
		NSDictionary *achievementData = [NSDictionary dictionaryWithContentsOfFile:path];
		if(achievementData && [achievementData isKindOfClass:[NSDictionary class]] && [achievementData count] > 3) {
			//如果映射文件存在并且字典长度大于3那么用映射文件读取图片
			//NSLog(@"111111111111111:%@", [achievementData description]);
			imageFile = [[achievementData objectForKey:identifier] objectForKey:@"Icon"];
		} else {
			//否则直接根据id在本地找图片
			imageFile = [NSString stringWithFormat:@"%@.png", identifier];
		}
		[achievementImage setImage:[UIImage imageNamed:imageFile]];
	} else {
		//如果没有找到本地映射文件那么从远程读取成就图标
		imageFile = [NSString stringWithFormat:@"%@.png", identifier];
		[achievementImage setImageWithURL:[NSURL URLWithString:[SystemUtils getFeedImageLink:imageFile]] placeholderImage:[UIImage imageNamed:@"com.diogame.petinn.Beautiful_inn.png"]];
	}
	
	[alert addSubview:achievementImage];
	[achievementImage release];
    
    [GCAlerts addObject:alert];
	SNSLog(@"%s - send to server!!!!", __FUNCTION__);
    // [[[CCDirector sharedDirector] openGLView] addSubview:alert];
    UIViewController *root = [SystemUtils getAbsoluteRootViewController];
    [root.view addSubview:alert];
    [alert release];
    
    if ([GCAlerts count] >0) {
		[self animateAlert];
	}
}

- (void)animateAlert {
//	CCSprite *achievementBox = nil;
//	if ([GCAlerts count] > 0) {
//		achievementBox = [GCAlerts objectAtIndex:0];
//	}
//	
//	CGFloat widthScale = WINDOW_WIDTH/480.0f;
//	
//	id actionTo = [CCSequence actions:
//				   [CCMoveTo actionWithDuration:.25 position:ccp(240*widthScale, achievementBox.contentSize.height/2)],
//				   [CCDelayTime actionWithDuration:2],
//				   [CCMoveTo actionWithDuration:.25 position:ccp(240*widthScale, -achievementBox.contentSize.height/2)], 
//				   [CCCallFunc actionWithTarget:self selector:@selector(cleanupAchievementBox)],
//				   nil];
//	[achievementBox runAction:actionTo];
    if (!isAnimation) {
        isAnimation = YES;
        UIView *alertBox = nil;
        if ([GCAlerts count] > 0) {
            alertBox = [GCAlerts objectAtIndex:0];
            
            [UIView beginAnimations:@"startAlert" context:UIGraphicsGetCurrentContext()];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:0.8f];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(waitAlert)];
            alertBox.frame = CGRectMake(WINDOW_WIDTH/2-196/2, WINDOW_HEIGHT-alertBox.frame.size.height, 196, 60);
            [UIView commitAnimations];
            
            //[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0f]];
        }
    }
    
}

- (void)waitAlert {
    UIView *alertBox = nil;
    if ([GCAlerts count] > 0) {
        alertBox = [GCAlerts objectAtIndex:0];
        [UIView beginAnimations:@"waitAlert" context:UIGraphicsGetCurrentContext()];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:2.0f];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(stopAlert)]; //动画结束时的委托处理
        alertBox.frame = CGRectMake(WINDOW_WIDTH/2-196/2, WINDOW_HEIGHT-alertBox.frame.size.height-1, 196, 60);
        [UIView commitAnimations];
    }
}

- (void)stopAlert {
    UIView *alertBox = nil;
    if ([GCAlerts count] > 0) {
        //NSLog(@"fuck me");
        alertBox = [GCAlerts objectAtIndex:0];
        [UIView beginAnimations:@"stopAlert" context:UIGraphicsGetCurrentContext()];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.8f];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(cleanupAchievementBox)]; //动画结束时的委托处理
        alertBox.frame = CGRectMake(WINDOW_WIDTH/2-196/2, WINDOW_HEIGHT, 196, 60);
        [UIView commitAnimations];
    }
}

- (void)cleanupAchievementBox {
//	CCSprite *achievementBox = nil;
//	
//	if (GCAlerts.count > 0) {
//		achievementBox = [GCAlerts objectAtIndex:0];
//	} else {
//		return;
//	}
//	
//	[achievementBox removeAllChildrenWithCleanup:YES];
//	[achievementBox.parent removeChild:achievementBox cleanup:YES];
//	
//	[GCAlerts removeObject: achievementBox];
//	
//	if (GCAlerts.count > 0 ) {
//		[self animateAlert];
//	}
	UIView *alert = nil;
	if (GCAlerts.count > 0) {
        alert = [GCAlerts objectAtIndex:0];
	} else {
		return;
	}
    
    [alert removeFromSuperview];
    [GCAlerts removeObjectAtIndex:0];
    isAnimation = NO;
    if (GCAlerts.count > 0 ) {
        [self animateAlert];
    }
}

#pragma mark - High source method

- (void)reportScore:(int)score forCategory:(NSString*)category
{
    if(!isStarted) return;
	if (!self.isLogin && [self isGameCenterAvailable] && [NetworkHelper helper].connectedToInternet) {
		[self authenticateLocalUser];
	}
	NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:score], @"score", category, @"category", nil];
	if (![self.scoreQueue containsObject:dic]) {
		[self.scoreQueue addObject:dic];
		[self commitSource];
	}
}

- (void)commitSource
{
	if (!self.isLogin) {
		[self performSelector:@selector(commitSource) withObject:nil afterDelay:3.0f];
		return;
	}
	if ([self.scoreQueue count] > 0) {
		NSDictionary *dic = [self.scoreQueue objectAtIndex:0];
		if (dic && [dic isKindOfClass:[NSDictionary class]]) {
			int score = [[dic objectForKey:@"score"] intValue];
			SNSLog(@"dic description:%@", [dic description]);
			SNSLog(@"score:%i -- category:%@", score, (NSString *)[dic objectForKey:@"category"]);
			GKScore *scoreReporter = [[[GKScore alloc] initWithCategory:[dic objectForKey:@"category"]] autorelease];
			scoreReporter.value = score;
			
			[scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
				if (error != nil) {
					// handle the reporting error
					SNSLog(@"上传分数出错.error:%@", error);
					//If your application receives a network error, you should not discard the score.
					//Instead, store the score object and attempt to report the player’s process at
					//a later time.
				} else {
					SNSLog(@"上传分数成功");
					[self.scoreQueue removeObjectAtIndex:0];
					//[self retrieveTopTenScores];
				}
				if ([self.scoreQueue count] > 0) [self commitSource];
			}];
		}
	}
}

- (void) retrieveTopTenScores
{
    GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] init];
    if (leaderboardRequest != nil) {
        leaderboardRequest.playerScope = GKLeaderboardPlayerScopeGlobal; //表示检索玩家分数范围
        leaderboardRequest.timeScope = GKLeaderboardTimeScopeAllTime; //表示某一时间段之内的分数
        leaderboardRequest.range = NSMakeRange(1,10); //表示分数排名的范围
        leaderboardRequest.category = @"com.topgame.dreamtrain.travel"; //表示leaderboardID
        [leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
            if (error != nil){
                // handle the error.
                SNSLog(@"下载失败,error:%@", error);
            }
            if (scores != nil){
                // process the score information.
                SNSLog(@"下载成功....");
                NSArray *tempScore = [NSArray arrayWithArray:leaderboardRequest.scores];
                for (GKScore *obj in tempScore) {
                    SNSLog(@"    playerID            : %@",obj.playerID);
                    SNSLog(@"    category            : %@",obj.category);
                    SNSLog(@"    date                : %@",obj.date);
                    SNSLog(@"    formattedValue    : %@",obj.formattedValue);
                    SNSLog(@"    value                : %lld",obj.value);
                    SNSLog(@"    rank                : %d",obj.rank);
                    SNSLog(@"**************************************");
                }
            }
        }];
    }
}

- (void)showLeader:(NSString *)category {
	if(![self isGameCenterAvailable]) return;
	// if(![NetworkHelper helper].connectedToInternet) return;
	if (!self.isLogin) {
		[[SnsServerHelper helper] onShowInGameLoadingView:nil];
		//设置超时
		[[SnsServerHelper helper] performSelector:@selector(onHideInGameLoadingView:) withObject:nil afterDelay:20.0f];
		[self authenticateLocalUser];
		leaderCategory = category;
		needShow = @"leader";
        return;
	}
	if(category==nil && leaderBoards!=nil && [leaderBoards count]>0) {
        category = [leaderBoards objectAtIndex:0];
        // category = b.category;
    }
    if(category==nil) {
        [self loadLeaderboardInfo];
        return;
    }
	SNSLog(@"category:%@", category);
	
    if([GKLocalPlayer localPlayer].authenticated == YES) {
		leaderboardController = [[GKLeaderboardViewController alloc] init];
		// UIResponder *nextResponder = [[CCDirector sharedDirector].openGLView nextResponder];
        UIViewController *root = [SystemUtils getAbsoluteRootViewController];
		if (root) {
			if (leaderboardController != nil) {
				leaderboardController.category = category;
				leaderboardController.timeScope = GKLeaderboardTimeScopeAllTime;
				leaderboardController.leaderboardDelegate = self;
				[root presentModalViewController: leaderboardController animated: YES];
				[leaderboardController release];
				leaderboardController = nil;
			}
		}
	}
}

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController {
    [viewController dismissModalViewControllerAnimated:YES];
}

- (void)showAchievement {
	if(![self isGameCenterAvailable]) return;
	if(![NetworkHelper helper].connectedToInternet) return;
	if (!self.isLogin && [self isGameCenterAvailable] && [NetworkHelper helper].connectedToInternet) {
		[[SnsServerHelper helper] onShowInGameLoadingView:nil];
		//设置超时
		[[SnsServerHelper helper] performSelector:@selector(onHideInGameLoadingView:) withObject:nil afterDelay:20.0f];
		[self authenticateLocalUser];
		needShow = @"achievement";
	}
	
    if([GKLocalPlayer localPlayer].authenticated == YES) {
		achievementController = [[GKAchievementViewController alloc] init];
        UIViewController *root = [SystemUtils getAbsoluteRootViewController];
		if (root) {
			if (achievementController != nil) {
				achievementController.achievementDelegate = self;
				[root presentModalViewController:achievementController animated:YES];
				[achievementController release];
				achievementController = nil;
			}
		}
	}
}

- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController {
	[viewController dismissModalViewControllerAnimated:YES];
}

#pragma mark - internet connect status test method

- (void)reachabilityChanged:(NSNotification* )note {
    /*
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	NetworkStatus netStatus = [curReach currentReachabilityStatus];
	BOOL old = connectedToInternet;
	connectedToInternet = (netStatus != NotReachable);
	
	if (connectedToInternet != old) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kNetConnectivityUpdatedNotification object: nil];	
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNetConnectivityResultDetermined object: nil];
     */
}

#pragma mark - System method

- (void)dealloc {
    [friendList release];
    self.friendList = nil;
    [GCAlerts release];
    self.achievmentList = nil;
    self.achievmentQueue = nil;
	self.scoreQueue = nil;
    [self removeAllNotification];
    if(leaderBoards!=nil) [leaderBoards release];
    if(loginViewController!=nil) loginViewController = nil;
    [super dealloc];
}

@end
