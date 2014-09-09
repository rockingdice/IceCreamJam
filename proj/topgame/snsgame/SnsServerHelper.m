//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "SnsServerHelper.h"
#import "StringUtils.h"
#import "SystemUtils.h"
#ifndef SNS_DISABLE_FLURRY_V1
#import "FlurryHelper.h"
#endif
#ifndef SNS_DISABLE_TAPJOY
#import "TapjoyHelper.h"
#endif
#import "SyncQueue.h"
#import "InAppStore.h"
#import "NetworkHelper.h"
#import "SBJson.h"
#ifndef SNS_DISABLE_FACEBOOK
#import "FacebookHelper.h"
#endif
#import "StatSendOperation.h"
#import "StatusCheckOperation.h"
#import "TutorialLoadOperation.h"
#import "LangLoadOperation.h"
#import "ItemLoadOperation.h"
#import "SyncTimeOperation.h"
#import "NoticeLoadOperation.h"
#import "LocalNotificationHelper.h"
#import "TinyiMailHelper.h"
#import "SnsStatsHelper.h"
#import "SNSGameResetOperation.h"
#import "ASIFormDataRequest.h"
#ifdef SNS_ENABLE_GROWMOBILE
#import "GrowMobileSDK.h"
#endif
#ifndef SNS_DISABLE_GAME_LOADSAVE
#import "GameSaveOperation.h"
#import "GameLoadOperation.h"
#endif
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
#import "SNSPromotionViewController.h"
#endif
#ifdef SNS_ENABLE_EMAIL_BIND
#import "BindEmailHelper.h"
#endif

#ifndef SNS_DISABLE_GAME_CENTER
#import "gameCenterHelper.h"
#endif
#ifndef SNS_DISABLE_PLAYHAVEN
#import "PlayHavenHelper.h"
#endif
#ifndef SNS_DISABLE_SOCIAL_MODULE
#import "SocialConfig.h"
#endif
#ifdef SNS_ENABLE_ADMOB
#import "AdmobViewController.h"
#endif
#ifdef SNS_ENABLE_LIMEI
#import "LiMeiHelper.h"
#endif
#ifdef SNS_ENABLE_LIMEI2
#import "LiMeiHelper2.h"
#endif
#ifdef SNS_ENABLE_ICLOUD
#import "iCloudHelper.h"
#endif
#ifdef SNS_ENABLE_GUOHEAD
#import "MixGHHelper.h"
#endif
#ifdef SNS_ENABLE_DOMOB
#import "DomobHelper.h"
#endif
#ifdef SNS_ENABLE_YOUMI
#import "YoumiHelper.h"
#endif
#ifdef SNS_ENABLE_DIANRU
#import "DianruHelper.h"
#endif
#ifdef SNS_ENABLE_ADWO
#import "AdwoHelper.h"
#endif
// #import "cocos2d.h"

#ifdef SNS_ENABLE_KIIP
#import "Kiip.h"
#endif

#ifdef SNS_ENABLE_TINYMOBI
#import "TinyMobiHelper.h"
#endif

#ifdef SNS_ENABLE_APPDRIVER
#import "AppDriverHelper.h"
#endif

#ifdef SNS_ENABLE_FLURRY_V2
#import "FlurryHelper2.h"
#import "Flurry.h"
#endif

#ifdef SNS_ENABLE_TAPJOY2
#import "TapjoyHelper2.h"
#endif

#ifdef SNS_ENABLE_MDOTM
#import "MdotMHelper.h"
#endif

#ifdef SNS_ENABLE_APPLOVIN
#import "AppLovinHelper.h"
#endif

#ifdef SNS_ENABLE_SPONSORPAY
#import "SponsorpayHelper.h"
#endif
#ifdef SNS_ENABLE_AARKI
#import "AarkiHelper.h"
#endif

#ifdef SNS_ENABLE_CHARTBOOST
#import "ChartBoostHelper.h"
#endif

#ifdef SNS_ENABLE_WEIXIN
#import "WeixinHelper.h"
#endif

#ifdef SNS_ENABLE_NANIGANS
#import "NanTracking.h"
#endif

#ifdef SNS_ENABLE_IAD
#import "iAdHelper.h"
#endif
#ifdef SNS_ENABLE_ADX
#import "AdxHelper.h"
#endif
#ifdef SNS_ENABLE_MINICLIP
#import "MiniclipHelper.h"
#endif

#ifdef SNS_ENABLE_CHUKONG
#import "ChukongHelper.h"
#endif


#ifdef SNS_ENABLE_YIJIFEN
#import "YijifenHelper.h"
#endif

#ifdef SNS_ENABLE_WAPS
#import "WapsHelper.h"
#endif

#ifdef SNS_ENABLE_MOBISAGE
#import "MobiSageHelper.h"
#endif

#ifdef SNS_ENABLE_ADJUST
#import "AdjustHelper.h"
#endif

enum {
	kLoadingStepNone,
	kLoadingStepCheckStatus,
	kLoadingStepLoadGameData,
	kLoadingStepLoadResource,
	kLoadingStepLoadTutorial,
	kLoadingStepSyncTime,
	kLoadingStepReloadStatus,
    kLoadingStepLoadNoticeImage1,
    kLoadingStepLoadNoticeImage2,
    kLoadingStepResumeLoadNoticeImage,
    kLoadingStepCheckStatusInBackground,
};

static SnsServerHelper *_snsServerHelper = nil;

void SnsgameExceptionHandler(NSException *exception)
{
    SNSLog(@"start SnsgameExceptionHandler");
    [SystemUtils uncaughtExceptionHandler:exception];
#ifdef SNS_ENABLE_FLURRY_V2
    [Flurry logError:@"Uncaught" message:@"Crash!" exception:exception];
#endif
    SNSLog(@"end SnsgameExceptionHandler");
}

@implementation SnsServerHelper
@synthesize isEnableLocalNotification;

#ifdef SNS_ENABLE_KOCHAVA
@synthesize kochavaTracker;
#endif

+(SnsServerHelper *)helper
{
	@synchronized(self) {
		if(!_snsServerHelper) {
			_snsServerHelper = [[SnsServerHelper alloc] init];
		}
	}
	return _snsServerHelper;
}

-(id)init
{
	
	self = [super init];
	if(self != nil) {
		m_isSessionInitialized = NO;
		isPaused = NO;
		isGameStarted = NO;
		isEnableLocalNotification = YES;
        isPaymentStarted = NO; m_adMobController = nil;
		[SystemUtils setAppDelegate:self];
        bgTaskID = UIBackgroundTaskInvalid;
        pendingURLGift = nil; newUID = 0; oldUID = 0;
        pendingCrossPromoTask = nil;
        
        if(1==[[SystemUtils getNSDefaultObject:@"kDisableNotify"] intValue])
        {
            isEnableLocalNotification = NO;
        }
	}
	// A notification method must be set to retrieve the points.
	// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getUpdatedPoints:) name:TJC_TAP_POINTS_RESPONSE_NOTIFICATION object:nil];
	
	return self;
}

-(void)dealloc
{
	// if(pendingActions) [pendingActions release];
    if(m_adMobController) {
        [m_adMobController release]; m_adMobController  = nil;
    }
#ifdef SNS_ENABLE_KOCHAVA
    if(kochavaTracker!=nil) [kochavaTracker release];
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) modifyAdColonyPath
{
    /*
    // 把adcolony的缓存目录移出到Library/Caches
    NSString *path = [[NSBundle mainBundle] bundlePath];
    path = [path stringByDeletingLastPathComponent];
    NSString *destPath = [path stringByAppendingPathComponent:@"Library/Caches/AdColony"];
    NSString *srcPath = [path stringByAppendingPathComponent:@"Documents/.AdColony"];
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    if([mgr fileExistsAtPath:srcPath])
    {
        NSDictionary *info = [mgr attributesOfItemAtPath:srcPath error:nil];
        if([info fileType] == NSFileTypeSymbolicLink)
        {
            // OK, no need to change
        }
        else {
            if([mgr fileExistsAtPath:destPath]) 
                [mgr removeItemAtPath:destPath error:nil];
            // move to destPath
            [mgr moveItemAtPath:srcPath toPath:destPath error:nil];
            // create symbol link
            [mgr createSymbolicLinkAtPath:srcPath withDestinationPath:@"../Library/Caches/AdColony" error:nil];
        }
    }
    else {
        // create symbol link
        [mgr createSymbolicLinkAtPath:srcPath withDestinationPath:@"../Library/Caches/AdColony" error:nil];
    }
    
    if(![mgr fileExistsAtPath:destPath]) 
        [mgr createDirectoryAtPath:destPath withIntermediateDirectories:YES attributes:nil error:nil];
    
     */
}

- (void) initSession:(UIView *)mainWindow
{
    [self initSession:mainWindow withLaunchOptions:nil];
}
// initSession with lauchoption
- (void) initSession:(UIView *)mainWindow withLaunchOptions:(NSDictionary *)options;
{
	if(m_isSessionInitialized) return;
	m_isSessionInitialized = YES;
	isNetworkOK = YES;
    if(m_launchOptions!=nil) {
        [m_launchOptions release];
        m_launchOptions = nil;
    }
    if(options!=nil) m_launchOptions = [options retain];
    
    if([self localNotificationEnabled])
    {
        UIApplication *app = [UIApplication sharedApplication];
        app.applicationIconBadgeNumber = 0;
        SNSLog(@"note count:%i\nnotes:%@",[app.scheduledLocalNotifications count], app.scheduledLocalNotifications);
        [app cancelAllLocalNotifications];
        // [[LocalNotificationHelper sharedHelper] cancelLocalNotification];
        
    }
#ifndef SNS_DISABLE_CATCH_EXCEPTION
    NSSetUncaughtExceptionHandler (&SnsgameExceptionHandler);
#endif
    
	m_mainWindow = mainWindow;
	
	[SystemUtils startCrashLog];
	[SystemUtils initGameStats];
    [SystemUtils logPlayTimeStart];
	
	[SystemUtils setAppDelegate:self];
	
	// register payment notification
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(onReceivePayment:) 
												 name:kInAppStoreItemBoughtNotification 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(onShowLoadingScene:) 
												 name:kNotificationShowLoadingScreen
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(onHideLoadingScene:) 
												 name:kNotificationHideLoadingScreen
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(onShowInGameLoadingView:) 
												 name:kNotificationShowInGameLoadingView
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(onHideInGameLoadingView:) 
												 name:kNotificationHideInGameLoadingView
											   object:nil];
	
	
	
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	
	int playTimes = [def integerForKey:kPlayTimes];
	// start normal checking
	if(playTimes == 0) {
		//[SystemUtils logInstallGame];
	}
    playTimes++;
	[def setInteger:playTimes forKey:kPlayTimes];
	[def synchronize];
	
	[SystemUtils showLoadingScreen];
	
	[self modifyAdColonyPath];
    
	[SystemUtils setLoadingScreenText:[SystemUtils getLocalizedString:@"Checking Network Status"]];
    
    int forceQuit = [[SystemUtils getNSDefaultObject:@"kForceQuitOnBgMode"] intValue];
    if(forceQuit==1) {
        [SystemUtils setNSDefaultObject:@"0" forKey:@"kForceQuitOnBgMode"];
    }

#ifdef DEBUG
    // [SystemUtils showCrashDetectedHint];
    // return;
    
    // test plural
    // NSString *word = @"leaf";
    // SNSLog(@"plural of %@: %@", word, [StringUtils getPluralFormOfWord:word]);
    
#endif
    /*
     // 没必要提示用户发送邮件
	if([SystemUtils isCrashDetected]) {
		NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
		int crashAlertTime = [def integerForKey:@"kLastCrashAlertTime"];
		int now = [SystemUtils getCurrentTime];
		if(crashAlertTime < now - 86400*7) // 一周提示一次
		{
			[SystemUtils showCrashDetectedHint];
			[def setInteger:now forKey:@"kLastCrashAlertTime"];
			[def synchronize];
			return;
		}
	}
     */
	
#if TARGET_IPHONE_SIMULATOR
#else
#ifdef DEBUG
    // register remote push service
    UIRemoteNotificationType type = (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert );
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:type];
#else
    if(playTimes==10 || playTimes==20 || playTimes==30) {
        // register remote push service
        UIRemoteNotificationType type = (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert );
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:type];
    }
#endif
#endif
    
    // 检查本地远程配置文件的版本号
    [SystemUtils checkRemoteConfigVersion];
    
	if(![SystemUtils verifyAllConfigFiles]) {
#if TARGET_IPHONE_SIMULATOR
        // DONOTHING
#else
		//[SystemUtils showConfigFileCorrupt];
		//return;
#endif
    }
    [self startLoadGame];
#ifdef SNS_ENABLE_KOCHAVA
    kochavaTracker = nil;
    NSString *kochID = [SystemUtils getSystemInfo:@"kKochavaAppID"];
    if(kochID!=nil && [kochID length]>3) {
        NSDictionary *initDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  kochID, @"kochavaAppId",
                                  // @"USD", @"currency",
                                  // @"0", @"limitAdTracking",
                                  // @"1", @"enableLogging",
                                  @"1", @"retrieveAttribution",
                                  nil];
        kochavaTracker = [[KochavaTracker alloc] initKochavaWithParams:initDict];
        kochavaTracker.trackerDelegate = self;
        // kochavaTracker = [[KochavaTracker alloc] initWithKochavaAppId:kochID];
    }
#endif
#ifdef SNS_ENABLE_NANIGANS
    [NanTracking initSettings];
#endif
}
- (void) Kochava_attributionResult:(NSDictionary*)attributionResult
{
    /*
     Organic Example:
     {
     "matched":false,
     "time_click":1374699246,
     }
     
     Tracked Campaign Example:
     {
     "matched":true,
     "time_click":1374699246,
     "time_install":1374703598,
     "network_name":"NetworkName - iOS",
     "network_id":99999,
     "site_id":"1",
     "creative_id":"",
     "campaign_name":"Campaign iOS- Customers",
     "campaign_id":"kochavaCampaignId",
     "cpi_price":0
     }
     */
    if(attributionResult!=nil && [[attributionResult objectForKey:@"matched"] boolValue]) {
        [SystemUtils setNSDefaultObject:attributionResult forKey:@"kKochavaCampaignAttribution"];
    }
    
}
// 完成发送邮件
-(void) onComposeEmailFinished:(NSNotification *)note
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationComposeEmailFinish object:nil];
	[self startLoadGame];
}

// 完成发送邮件
-(void) onComposeAppealEmailFinished:(NSNotification *)note
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationComposeEmailFinish object:nil];
    
    [self onApplicationGoesBackground];
    exit(0);
    
}

// 开始加载游戏
- (void) startLoadGame
{
	[self initChangeSocialAccountListener];//社交模块账户切换侦听
	[self initNetworkListener];
}

#pragma mark Application Delegate

- (void) onBackgroundHeatbeat
{
    SNSLog(@"");
    // save interval
    if(isPaused) {
        bgTaskTime += 5;
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:bgTaskTime] forKey:@"kBgTaskTime"];
    }
    if(bgTaskTime>400 || !isPaused || [UIApplication sharedApplication].backgroundTimeRemaining<5.0f)
    {
        if(bgTaskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
            bgTaskID = UIBackgroundTaskInvalid;
        }
        return;
    }
    [self performSelector:@selector(onBackgroundHeatbeat) withObject:nil afterDelay:5.0f];
}

// 程序进入后台时调用
-(void) onApplicationGoesBackground
{
	if([InAppStore store].paymentPending) return;
	SNSLog(@"%s", __func__);
	[SystemUtils logPlayTimeEnd];
	[SystemUtils saveGameStat];
    [SystemUtils pauseDirector];
    
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:[SystemUtils getCurrentTime]] forKey:@"kLastExitTime"];
    
    // save game
    [[SystemUtils getGameDataDelegate] saveGame];
    
	isPaused = YES;
	[self scheduleLocalNotifications];
	
	[SystemUtils endCrashLog];
    
#ifndef SNS_DISABLE_GAME_LOADSAVE
#ifdef SNS_ENABLE_EMAIL_BIND
    [[BindEmailHelper helper] updateData];
#else
	// upload game save
	if([NetworkHelper isConnected]) {
		SNSLog(@"%s: start uploading", __func__);
		SyncQueue* syncQueue = [SyncQueue syncQueue];
		
		GameSaveOperation* saveOp = [[GameSaveOperation alloc] initWithManager:syncQueue andDelegate:nil];
		[syncQueue.operations addOperation:saveOp];
		[saveOp release];
        
        [[FacebookHelper helper] startSync];
        /*
        StatSendOperation *sendOp = [[StatSendOperation alloc] initWithManager:syncQueue andDelegate:nil];
        [syncQueue.operations addOperation:sendOp];
        [sendOp release];
         */
	}
#endif
#endif
    bgTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if(bgTaskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
            bgTaskID = UIBackgroundTaskInvalid;
        }
    }];
    bgTaskTime = 0;
    [self performSelector:@selector(onBackgroundHeatbeat) withObject:nil afterDelay:5.0f];
    
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
    [SNSPromotionViewController saveNoticeList];
#endif

    
    // 游戏Helper回调
    NSObject<GameDataDelegate> *gameHelper = [SystemUtils getGameDataDelegate];
    if([gameHelper respondsToSelector:@selector(onGameGoesBackground)]) {
        [gameHelper onGameGoesBackground];
    }
    
}

// 从后台恢复时调用
- (void) onApplicationGoesForground
{
    [SystemUtils saveDeviceTimeCheckPoint:NO];
    [SystemUtils correctCurrentTime];

#ifdef SNS_ENABLE_FLURRY_V2
    [[FlurryHelper2 helper] loadAdSpace];
#endif
    
	if(!isPaused) return;
	if([InAppStore store].paymentPending) return;
    
    [self startTinyMobi];
    
    [SystemUtils logPlayTimeStart];
    
    // set playtimes
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	
	int playTimes = [def integerForKey:kPlayTimes];
    playTimes++;
	[def setInteger:playTimes forKey:kPlayTimes];
	[def synchronize];
    
	isPaused = NO;
	// NSLog(@"%s", __func__);
	[SystemUtils startCrashLog];
    
    [SystemUtils resumeDirector];
	
	// [[LocalNotificationHelper sharedHelper] setNotificationCount:0];
    if([self localNotificationEnabled])
    {
        UIApplication *app = [UIApplication sharedApplication];
        app.applicationIconBadgeNumber = 0;
        SNSLog(@"note count:%i\nnotes:%@",[app.scheduledLocalNotifications count], app.scheduledLocalNotifications);
        [app cancelAllLocalNotifications];
        // [[LocalNotificationHelper sharedHelper] cancelLocalNotification];
    }
	
	checkingStep = kLoadingStepSyncTime;
	SNSLog(@"start sync time");
	SyncQueue* syncQueue = [SyncQueue syncQueue];
	
	SyncTimeOperation* syncOp = [[SyncTimeOperation alloc] initWithManager:syncQueue andDelegate:self];
	[syncQueue.operations addOperation:syncOp];
	[syncOp release];
	
#ifndef SNS_DISABLE_FACEBOOK
    if([[SystemUtils getiOSVersion] compare:@"6.0"]>=0) {
        [[FacebookHelper helper] checkSessionStatus];
        [[FacebookHelper helper] checkIncomingNotification];
    }
#endif
	// [SystemUtils startChartBoost];
    [self initAdMobBanner];
    
    NSString *bonusKey = @"kFBLikeBonusDate";
    // send facebook Like Bonus
    int likeDate = [[SystemUtils getNSDefaultObject:@"kFacebookLikeDate"] intValue];
    if(likeDate>0) {
        int bonus = [[SystemUtils getGlobalSetting:@"kFacebookLikeBonus"] intValue];
        int bonusDate = [[[SystemUtils getGameDataDelegate] getExtraInfo:bonusKey] intValue];
        if(bonusDate==0) {
            bonusDate = [[SystemUtils getPlayerDefaultSetting:bonusKey] intValue];
            if(bonusDate>0) {
                [[SystemUtils getGameDataDelegate] setExtraInfo:[NSNumber numberWithInt:bonusDate] forKey:bonusKey];
            }
        }
#ifdef DEBUG
        // bonusDate = 0;
#endif
        if(bonus>0 && bonusDate==0) {
            [SystemUtils setPlayerDefaultSetting:[NSNumber numberWithInt:likeDate] forKey:@"kFBLikeBonusDate"];
            [[SystemUtils getGameDataDelegate] setExtraInfo:[NSNumber numberWithInt:likeDate] forKey:bonusKey];
            
            SNSLog(@"show like us bonus popup");
            
            NSString *coinName = [SystemUtils getLocalizedString:@"CoinName1"];
            if(bonus>1) coinName = [StringUtils getPluralFormOfWord:coinName];
            NSString *title = [SystemUtils getLocalizedString:@"Like Us Bonus"];
            NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Thanks for liking us on Facebook, you've got a bonus of %1$d %2$@!"],
                              bonus, coinName];
            [SystemUtils showSNSAlert:title message:mesg];
            [SystemUtils addGameResource:bonus ofType:kGameResourceTypeCoin];
        }
    }
    
#ifdef SNS_ENABLE_GROWMOBILE
    if([SystemUtils isGrowMobileEnabled]) {
        [GrowMobileSDK reportOpen];
    }
#endif
    
#ifdef SNS_ENABLE_NANIGANS
    [NanTracking trackAppOpen];
#endif
    // 游戏Helper回调
    NSObject<GameDataDelegate> *gameHelper = [SystemUtils getGameDataDelegate];
    if([gameHelper respondsToSelector:@selector(onGameResumeForground)]) {
        [gameHelper onGameResumeForground];
    }
    
}

- (BOOL) handleOpenURL:(NSURL *)url
{
    
	if (url == nil)
        return NO;
    
    NSString *kAppId = [SystemUtils getFacebookAppID];
    // get appSchema
    NSString *suffix = [SystemUtils getSystemInfo:@"kFacebookURLSchemeSuffix"];
    //if(!suffix)
    //    suffix = [SystemUtils getSystemInfo:@"kAppURLScheme"];
    if(!suffix) suffix = @"";
	
	SNSLog(@"url:%@ scheme:%@ mine:fb%@%@", [url absoluteString], [url scheme], kAppId, suffix);
#ifndef SNS_DISABLE_FACEBOOK
    int len = [kAppId length]+2;
    NSString *scheme1 = [url scheme];
    if([[SystemUtils getiOSVersion] compare:@"5.0"]>=0) {
        if ([scheme1 length]>=len && [[scheme1 substringToIndex:len] isEqualToString:[NSString stringWithFormat:@"fb%@", kAppId]])
        {
            return [[FacebookHelper helper] handleOpenURL:url];
        }
    }
#endif
#ifdef SNS_ENABLE_WEIXIN
    if([[WeixinHelper helper] handleOpenURL:url]) return YES;
#endif
#ifdef SNS_ENABLE_ADX
    if([[AdxHelper helper] handleOpenURL:url]) return YES;
#endif
	// else
	//	[JumpTapAppReport handleApplicationLaunchUrl:url];
    
    // check email gift
    // SlotsCasino://emailgift?type=%2$@&count=%1$d&uid=%4$@&sig=%5$@
    /*
     host:emailgift
     scheme:SlotsCasino
     parameterString:(null)
     query:type=dollar&count=1500&uid=uid1234&sig=xxxxxxx
     */
    /*
    NSString *scheme = [SystemUtils getSystemInfo:@"kMyAppURLScheme"];
    if(scheme && [scheme isKindOfClass:[NSString class]])
        scheme = [scheme lowercaseString];
    if([scheme isEqualToString:[[url scheme] lowercaseString]])
    {
     */
    // parse query string
    NSString *host = [url host];
    if(host && [host isEqualToString:@"emailgift"] && [url query]!=nil)
    {
        [[TinyiMailHelper helper] onReceiveEmailGift:[url query]];
    }
    if(host && [host isEqualToString:@"getGift"] && [url query]!=nil) {
        // gift=xxxxx&sig=xxxxxx
        NSDictionary *params = [StringUtils parseURLParams:[url query]];
        pendingURLGift = [params objectForKey:@"gift"];
        if(pendingURLGift) {
            // verify hash
            // pendingURLGift = [StringUtils stringByUrlDecodingString:pendingURLGift];
            SNSLog(@"urlGift:%@",pendingURLGift);
            NSString *hash = [StringUtils stringByHashingStringWithMD5:pendingURLGift];
            SNSLog(@"hash1: %@", hash);
            NSString *hashText = [NSString stringWithFormat:@"%@-sdf28s070etrw3470",hash];
            hash = [StringUtils stringByHashingStringWithMD5:hashText];
            if(![hash isEqualToString:[params objectForKey:@"sig"]]) {
                SNSLog(@"Invalid hash:%@ sig:%@", hash, [params objectForKey:@"sig"]);
                pendingURLGift = nil;
            }
        }
        if(pendingURLGift) {
            [pendingURLGift retain];
            SNSLog(@"got link gift: %@", pendingURLGift);
        }
    }
    if (host && [host isEqualToString:@"addFrd"] && [url query] != nil) {
        NSDictionary *params = [StringUtils parseURLParams:[url query]];
        NSString * fromuid = [params objectForKey:@"from_uid"];
        if (fromuid) {
            NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:fromuid,@"fid", @"5",@"type",  nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAddWXFrd object:nil userInfo:dic];
        }
    }
    if(host && [host isEqualToString:@"switchUID"] && [url query]!=nil) {
        // uid=nnnnn&time=nnnnnn&sig=xxxxxx
        NSDictionary *params = [StringUtils parseURLParams:[url query]];
        NSString *uid = [params objectForKey:@"newUID"];
        NSString *uid2 = [params objectForKey:@"oldUID"];
        if(uid && uid2)
        {
            // verify hash
            // SNSLog(@"urlGift:%@",pendingURLGift);
            int time = [[params objectForKey:@"time"] intValue];
            NSString *hash = [StringUtils stringByHashingStringWithMD5:[NSString stringWithFormat:@"%@-%@-%d",uid2, uid,time]];
            SNSLog(@"hash1: %@", hash);
            NSString *hashText = [NSString stringWithFormat:@"%@-sdf28s070etrw3470",hash];
            hash = [StringUtils stringByHashingStringWithMD5:hashText];
            if(![hash isEqualToString:[params objectForKey:@"sig"]]) {
                SNSLog(@"Invalid hash:%@ sig:%@", hash, [params objectForKey:@"sig"]);
            }
            else {
                newUID = [uid intValue];
                oldUID = [uid2 intValue];
            }
        }
    }
    if(host && [host isEqualToString:@"crossPromo"] && [url query]!=nil) {
        // crossPromo?appID=%@&noticeID=%@&userID=%@&sig=%@
        NSDictionary *params = [StringUtils parseURLParams:[url query]];
        NSString *appID = [params objectForKey:@"appID"];
        NSString *noticeID = [params objectForKey:@"noticeID"];
        NSString *userID = [params objectForKey:@"userID"];
        NSString *sig    = [params objectForKey:@"sig"];
        NSString *prizeCond = [params objectForKey:@"cond"];
        NSString *hash = [self hashCrossPromoParams:[NSString stringWithFormat:@"%@-%@-%@-%@",appID, noticeID, userID, prizeCond]];
        if(sig && [sig isEqualToString:hash]) {
            // request valid
            if(pendingCrossPromoTask!=nil) [pendingCrossPromoTask release];
            pendingCrossPromoTask = @{@"appID":appID,@"noticeID":noticeID,@"userID":userID, @"prizeCond":prizeCond};
            [pendingCrossPromoTask retain];
        }
    }
    
    return YES;
    
}

#pragma mark -

#pragma mark Notification

// 设置是否允许本地通知
- (void) setNotificationStatus:(BOOL)enabled
{
    if(enabled==isEnableLocalNotification) return;
    isEnableLocalNotification = enabled;
    if(enabled) 
        [SystemUtils setNSDefaultObject:@"0" forKey:@"kDisableNotify"];
    else {
        [SystemUtils setNSDefaultObject:@"1" forKey:@"kDisableNotify"];
    }
    
}
// 获得本地通知状态
- (BOOL) getNotificationStatus
{
    return isEnableLocalNotification;
}

- (BOOL)localNotificationEnabled
{
	Class localNotificationClass = NSClassFromString(@"UILocalNotification");
	
	// this iOS may not know what UILocalNotification is
	if (localNotificationClass && isEnableLocalNotification) 
	{
		return YES;
	}
	
	return NO;
}

// 设置本地通知

-(void) scheduleLocalNotifications
{
#ifdef SNS_DISABLE_LOCAL_NOTIFICATION
    // do nothing
#else
    /*
#ifdef DEBUG
    NSDictionary *info = @{@"mesg":@"here's your 1 million coins!",@"mesgID":@"",@"action":@"",@"prizeGold":@"1000000",@"prizeLeaf":@"0"};
    [self scheduleLocalNotificationWithBody:@"Here's 1 million coins for you!" andAction:[SystemUtils getLocalizedString:@"Accept"] andSound:nil andInfo:info atTime:[NSDate dateWithTimeIntervalSinceNow:10.0f]];
#endif
     */
    
    
    // get install time
    int installTime = [[SnsStatsHelper helper] getInstallTime];
    int now = [SystemUtils getCurrentTime];
#ifdef DEBUG
    // installTime = now-1000;
#endif
    if(installTime<now && installTime>now-86400) {
        // 新注册用户3天离线奖励
        NSDictionary *leftBonus = nil;
        NSString *text = [SystemUtils getGlobalSetting:@"kThreeDayLeftBonus"];
        if(text!=nil && [text length]>10) {
            leftBonus = [StringUtils convertJSONStringToObject:text];
            if(leftBonus!=nil && ![leftBonus isKindOfClass:[NSDictionary class]]) leftBonus = nil;
        }
        if(leftBonus==nil)
            leftBonus = [SystemUtils getSystemInfo:@"kThreeDayLeftBonus"];
        if(leftBonus!=nil) {
            NSString *mesg = [leftBonus objectForKey:@"noteMesg"];
            if(mesg!=nil) {
                int delay = 86400*3;
#ifdef DEBUG
                // delay = 10;
#endif
                [self scheduleLocalNotificationWithBody:mesg andAction:[SystemUtils getLocalizedString:@"Accept"] andSound:nil andInfo:[leftBonus objectForKey:@"bonusInfo"] atTime:[NSDate dateWithTimeIntervalSinceNow:delay]];
            }
        }
    }
    
	if(![self localNotificationEnabled]) return;
	if(!isEnableLocalNotification) return;
	int disableNotify = [[SystemUtils getGlobalSetting:kDisableLocalNotify] intValue];
	if(disableNotify == 1) return;
	
	int i=0; int hour = 0;
	NSDate *today = [NSDate date]; NSString *body = nil; NSString *action = nil; int days = 0;
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *todayComp =
	[gregorian components:(NSDayCalendarUnit | NSWeekdayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) 
				 fromDate:today];
	SNSLog(@"todayComp:%i-%i-%i %i:%i", [todayComp year], [todayComp month], [todayComp day], [todayComp hour], [todayComp minute]);
	NSDateComponents *dateComp = nil;
	NSDate *itemDate = nil; // [NSDate date];
	NSString *sound = [SystemUtils getSystemInfo:@"kLocalNotifySound"];
    
    if([[SystemUtils getGameDataDelegate] getNotificationSoundOn]==NO){
        sound = @"muteSound.caf";
    }
    
	if(![[SystemUtils getGameDataDelegate] isTutorialFinished]) {
		if(![[SystemUtils getGameDataDelegate] isTutorialStart])
		{
			// 没有开始新手教程
			body = [SystemUtils getLocalizedString:@"NOTICE_TUTORIAL_NOT_START"];
			action = [SystemUtils getLocalizedString:@"View"];
			itemDate = today; // [today dateByAddingTimeInterval:5];
			dateComp = [gregorian components:NSHourCalendarUnit fromDate:itemDate];
			hour = [dateComp hour];
			[self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:nil atTime:itemDate];
			
			today = [SystemUtils delayDateToAvoidSleepHour:today]; // [today dateByAddingTimeInterval:86400];
			itemDate = [today dateByAddingTimeInterval:86400];
			[self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:nil atTime:itemDate];
			days = 7-[todayComp weekday]; // 1-sunday, 2-monday, 7-satuday
			if(days==0) days = 7;
			for(i=0;i<10;i++) {
				itemDate = [today dateByAddingTimeInterval:86400*(days+i*7)];
				[self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:nil atTime:itemDate];
			}
		}
		else
		{
			// 没有完成新手教程
			body = [SystemUtils getLocalizedString:@"NOTICE_COMPLETE_TUTORIAL_01"];
			action = [SystemUtils getLocalizedString:@"View"];
			today = [SystemUtils delayDateToAvoidSleepHour:today];
			itemDate = [today dateByAddingTimeInterval:300];
			[self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:nil atTime:itemDate];
			itemDate = [today dateByAddingTimeInterval:86400];
			[self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:nil atTime:itemDate];
			int days = 7-[todayComp weekday]; // 1-sunday, 2-monday, 7-satuday
			if(days==0) days = 7;
			itemDate = [itemDate dateByAddingTimeInterval:days*86400];
			for(i=0;i<10;i++) {
				[self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:nil atTime:itemDate];
				itemDate = [itemDate dateByAddingTimeInterval:86400*7];
			}
		}
		[gregorian release]; return;
	}
	NSMutableDictionary *installedNotes = [[NSMutableDictionary alloc] init];
	NSString *dateFmt = @"ymd";
	BOOL oncePerDay = NO;
	// 避开睡觉时间
	today = [SystemUtils delayDateToAvoidSleepHour:today];
	SNSLog(@"today:%@",today);
	todayComp =
	[gregorian components:(NSDayCalendarUnit | NSWeekdayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) 
				 fromDate:today];
	
    BOOL leftNoticeInGameData = [[SystemUtils getSystemInfo:@"kGetLeftNoticeFromGameData"] boolValue];
    
    if(!leftNoticeInGameData) {
	// 3天未登录提示
	body = [SystemUtils getLocalizedString:@"NOTICE_LEFT_3_DAYS"];
	action = [SystemUtils getLocalizedString:@"View"];
	itemDate = [today dateByAddingTimeInterval:86400*3];
	[self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:nil atTime:itemDate];
	SNSLog(@"3 dayes notify:%@", itemDate);
	if(oncePerDay) [installedNotes setObject:itemDate forKey:[StringUtils convertDateToString:itemDate withFormat:dateFmt]];
	// 7天未登录提示
	body = [SystemUtils getLocalizedString:@"NOTICE_LEFT_7_DAYS"];
	action = [SystemUtils getLocalizedString:@"View"];
	itemDate = [today dateByAddingTimeInterval:86400*7];
	[self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:nil atTime:itemDate];
	SNSLog(@"7 dayes notify:%@", itemDate);
	if(oncePerDay) [installedNotes setObject:itemDate forKey:[StringUtils convertDateToString:itemDate withFormat:dateFmt]];
	// 15天未登录提示
	body = [SystemUtils getLocalizedString:@"NOTICE_LEFT_15_DAYS"];
	action = [SystemUtils getLocalizedString:@"View"];
	itemDate = [today dateByAddingTimeInterval:86400*15];
	[self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:nil atTime:itemDate];
	if(oncePerDay) [installedNotes setObject:itemDate forKey:[StringUtils convertDateToString:itemDate withFormat:dateFmt]];
	SNSLog(@"15 dayes notify:%@", itemDate);
	// 30天未登录提示
	body = [SystemUtils getLocalizedString:@"NOTICE_LEFT_30_DAYS"];
	action = [SystemUtils getLocalizedString:@"View"];
	itemDate = [today dateByAddingTimeInterval:86400*30];
	[self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:nil atTime:itemDate];
	SNSLog(@"30 dayes notify:%@", itemDate);
	if(oncePerDay) [installedNotes setObject:itemDate forKey:[StringUtils convertDateToString:itemDate withFormat:dateFmt]];
	}
    /*
    if([[SystemUtils getGlobalSetting:@"kWeeklySaleNotify"] intValue]==1) {
        // 每周五晚上8点提示
        int kWeekendSaleOffsetHour = [[SystemUtils getSystemInfo:@"kWeekendSaleOffsetHour"] intValue];
        body = [SystemUtils getLocalizedString:@"Weekend sales time! Don't miss it!"];
        days = 7-[todayComp weekday]-1; // 1-sunday, 2-monday, 7-satuday
        NSLog(@"weekday:%i", [todayComp weekday]);
        int minute = [todayComp minute]; hour = [todayComp hour];
        if(days<=0) days += 7;
        for(i=1;i<2;i++) {
            itemDate = [today dateByAddingTimeInterval:86400*(days+i*7)-hour*3600-minute*60+(20+kWeekendSaleOffsetHour)*3600];
            NSLog(@"weekend sale notify:%@", itemDate);
            [self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:nil atTime:itemDate];
            if(oncePerDay) [installedNotes setObject:itemDate forKey:[StringUtils convertDateToString:itemDate withFormat:dateFmt]];
        }
	}
     */
    
	// 收获，扩容，建造提示
	NSArray *arr = [[SystemUtils getGameDataDelegate] getNotificationList];

	int gap = [SystemUtils getCurrentDeviceTime] - [SystemUtils getCurrentTime];
	SNSLog(@"deviceTime:%i serverTime:%i gap:%i now:%@", [SystemUtils getCurrentDeviceTime], [SystemUtils getCurrentTime], gap, today);
	for(i=0;i<[arr count];i++)
	{
		NSDictionary *info = [arr objectAtIndex:i];
		if(!info) continue;
		body = [info objectForKey:@"infoTip"];
		itemDate = [info objectForKey:@"infoDate"];
		SNSLog(@"itemDate1:%@",itemDate);
		itemDate = [SystemUtils delayDateToAvoidSleepHour:itemDate];
		if([itemDate timeIntervalSinceDate:today]<300) itemDate = [today dateByAddingTimeInterval:300];
		SNSLog(@"itemDate2:%@",itemDate);
		if(!body || !itemDate) continue;
		NSString *key = [StringUtils convertDateToString:itemDate withFormat:dateFmt];
		if([installedNotes objectForKey:key]) continue;
		SNSLog(@"room notify:%@ info:%@", itemDate, body);
		[self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:nil atTime:itemDate];
		if(oncePerDay) [installedNotes setObject:itemDate forKey:[StringUtils convertDateToString:itemDate withFormat:dateFmt]];
	}
	
	/*
	// 限时购买还剩2小时提示
	int endTime = [SystemUtils getSpecialOfferEndTime];
	int now = [SystemUtils getCurrentTime];
	if(now<endTime-7800)
	{
		itemDate = [NSDate dateWithTimeIntervalSince1970:endTime-7200+gap];
		NSDateComponents *dtcomp = [gregorian components:NSHourCalendarUnit fromDate:itemDate];
		BOOL show = YES;
		if([dtcomp hour]<10 || [dtcomp hour]>22) show = NO;
		NSString *key = [StringUtils convertDateToString:itemDate withFormat:dateFmt];
		if(show && ![installedNotes objectForKey:key]) {
			body = [SystemUtils getLocalizedString:@"2 hours to close the special offer. Come now and check out the special cute item~"];
			[self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:nil atTime:itemDate];
			if(oncePerDay) [installedNotes setObject:itemDate forKey:[StringUtils convertDateToString:itemDate withFormat:dateFmt]];
			NSLog(@"special sale notify:%@", itemDate);
		}
	}
	 */
	
	/*
	// 连续3天登录赠送5叶子，一次性
	if(dt.m_level>3 && dt.m_awardLoginDay>=3)
	{
		// check if already prized
		int prized = [[dt getExtraInfo:@"loginPrize1"] intValue];
#ifdef DEBUG
		// prized = 0; today = [NSDate date];
#endif
		if(prized==0) {
			NSLog(@"set local prize");
			[dt setExtraInfo:[NSNumber numberWithInt:1] withKey:@"loginPrize1"];
			[dt saveGame];
			itemDate = [today dateByAddingTimeInterval:5];
			body = [SystemUtils getLocalizedString:@"Pets love you! They gave you 5 leaves to express their gratitude for playing with them for 3 days."];
			NSDictionary *prizeInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithInt:5], @"prizeLeaf", 
									   @"Pets love you! They gave you 5 leaves to express their gratitude for playing with them for 3 days.", @"mesgID",
									   @"", @"action", nil];
			[self scheduleLocalNotificationWithBody:body andAction:action andSound:sound andInfo:prizeInfo atTime:itemDate];
		}
	}
	 */
	// TODO:远程下载的通知规则
	
	[gregorian release];
	[installedNotes release];
#endif
}

- (void) scheduleLocalNotificationWithBody:(NSString *)body andAction:(NSString *)action andSound:(NSString *)sound andInfo:(NSDictionary *)info atTime:(NSDate*)dt
{
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    if (localNotif == nil)
        return;
	// NSLog(@"%s body:%@ action:%@",__FUNCTION__, body, action);
    localNotif.fireDate = dt;
    localNotif.timeZone = [NSTimeZone defaultTimeZone];
	
    localNotif.alertBody = body;
    localNotif.alertAction = action;
    localNotif.soundName = sound; // UILocalNotificationDefaultSoundName;
    
    localNotif.applicationIconBadgeNumber = 1;
	
    localNotif.userInfo = info;
	
	[[UIApplication sharedApplication] scheduleLocalNotification:localNotif];		
	
    [localNotif release];
}


#pragma mark -

#pragma mark Listener


- (void) onShowLoadingScene:(NSNotification *)note
{
#ifndef SNS_DISABLE_LOADING_VIEW
	if(isGameStarted) return;
	if(m_loadingView) return;
    SNSLog(@"show loading view:%f,%f",m_mainWindow.bounds.size.width,m_mainWindow.bounds.size.height);
	m_loadingView = [[SnsLoadingView alloc] initWithFrame:m_mainWindow.bounds];
	[m_mainWindow addSubview:m_loadingView];
	[m_loadingView show];
	// [SystemUtils getAppDelegate]
#endif
}

- (void) onHideLoadingScene:(NSNotification *)note
{
#ifndef SNS_DISABLE_LOADING_VIEW
	if(!m_loadingView) return;
	[m_loadingView hide];
	[m_loadingView release];
	m_loadingView = nil;
#endif
}

- (void) onShowInGameLoadingView:(NSNotification *)note
{
#ifndef SNS_DISABLE_LOADING_VIEW
	if(m_inGameLoading) return;
	m_inGameLoading = [[SmInGameLoadingView alloc] init];
	[m_mainWindow addSubview:m_inGameLoading];
	// [SystemUtils getAppDelegate]
#endif
}

- (void) onHideInGameLoadingView:(NSNotification *)note
{
#ifndef SNS_DISABLE_LOADING_VIEW
	if(!m_inGameLoading) return;
	[m_inGameLoading removeFromSuperview];
	[m_inGameLoading release];
	m_inGameLoading = nil;
#endif
}

-(void) initNetworkListener
{
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector: @selector(onNetworkStatusChanged:) 
												 name: kNetworkHelperNetworkStatusChanged 
											   object: nil];
	isCheckingNetworkStatus = YES;
    
	[[NetworkHelper helper] checkNetworkStatus];
	// waiting for 10 seconds to check network again
	[self performSelector:@selector(checkNetworkStatus) withObject:nil afterDelay:2.0f];
    
#ifdef SNS_DISABLE_GAME_LOADSAVE
    [self startGameScene];
#endif
	 
}

//社交模块切换账户的侦听
-(void) initChangeSocialAccountListener
{
#ifndef SNS_DISABLE_SOCIAL_MODULE
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector: @selector(onAccountChanged:) 
												 name: kIfGameNeedChangeUser 
											   object: nil];
#endif
}


-(void) onNetworkStatusChanged:(NSNotification *)note
{
	[self checkNetworkStatus];
}

//切换账户
- (void)onAccountChanged:(NSNotification *)notification {
	NSDictionary *dictionary = notification.object;
	
	//获取到新账户的UID
	NSString *curUID = [NSString stringWithFormat:@"%@", [dictionary objectForKey:@"userId"]];
	SNSLog(@"切换账户后的UID=======>%@",curUID);
	if([curUID isEqualToString:[SystemUtils getCurrentUID]]){
		return;
	}
    int isNewUser = [[dictionary objectForKey:@"newUser"] intValue];
    
	//保存当前账户的数据
	[SystemUtils logPlayTimeEnd];
	
	// [m_mainGameData saveGame];
	[[SystemUtils getGameDataDelegate] saveGame];
	
    [[SnsStatsHelper helper] resetStats];
    
	//切换到新的UID
	[SystemUtils setCurrentUID:curUID];
	
	//清空游戏数据  (2011-10-17 我把数据清空放到startGameScene方法里了)
	//[m_mainGameData clear];
	//[m_mainGameData release];
	//m_mainGameData = nil;
	isPaused = NO;
	isGameStarted = NO;
	
    if(isNewUser == 1) {
        [self startGameScene];
    }
    else {
        //加载新scene
        [SystemUtils showLoadingScreen];
        [self checkPlayerStatus];
    }
}

// 设置无网络标志
- (void) setNetworkStatus:(BOOL)networkOK
{
    isNetworkOK = networkOK;
    [SystemUtils setNSDefaultObject:[NSNumber numberWithBool:isNetworkOK] forKey:@"kServerConnected"];
}

-(void) checkNetworkStatus {
	if(!isCheckingNetworkStatus) return;
	isCheckingNetworkStatus = NO;
	// start loading
	if(![NetworkHelper helper].connectedToInternet && [[SystemUtils getSystemInfo:@"kForceNetwork"] intValue]==0) {
        isNetworkOK = NO;
		// 无网络情况下玩游戏
		[self performSelectorOnMainThread:@selector(startGameScene) withObject:nil waitUntilDone:NO];
        
	}
    isNetworkOK = YES;
    [self checkPlayerStatus];
}

-(void) onReceivePayment:(NSNotification *)note
{
	SNSLog(@"%s:%@",__FUNCTION__,note);
	NSDictionary *info = note.userInfo;
	NSString* buyID = [info objectForKey:@"itemId"];
	NSString *tid = [info objectForKey:@"tid"];
    // NSString *receiptData = [info objectForKey:@"receiptData"];
    // NSString *verifyPostData = [info objectForKey:@"verifyPostData"];
	NSDictionary *priceInfo = [[InAppStore store] getProductPrice:buyID];
	
	if(!priceInfo) {
		// LOG to pending iap
		NSLog(@"invalid payment info:%@", info);
		return;
	}
	SNSLog(@"%s: priceInfo:%@", __func__, priceInfo);
	
	int amount = [[info objectForKey:@"amount"] intValue];
	int count = [[priceInfo objectForKey:@"count"] intValue];
	//int discount = [[prizeInfo objectForKey:@"discount"] intValue];
	// BOOL isCoin = [[priceInfo objectForKey:@"isCoin"] boolValue];
    int iapType = [[priceInfo objectForKey:@"type"] intValue];
    NSString *itemName = [priceInfo objectForKey:@"itemName"];
    NSString *itemID = [priceInfo objectForKey:@"itemID"];
	int oldCount = count;
    
#ifdef SNS_ENABLE_ADJUST
    int priceDollar = [[priceInfo objectForKey:@"priceUSD"] intValue];
    if(priceDollar>0) {
        [[AdjustHelper helper] trackRevenue:priceDollar*100-1 ofItem:itemID];
    }
#endif
    
    

    // 记录用户付费信息
    [[SnsStatsHelper helper] logPayment:oldCount*100-1 withItem:itemID andTransactionID:tid];
	if(iapType == 1)
	{
		// count = [GameConfig getIapCoinsNumWithLevel:[GameData gameData].m_level iapType:count];
		// count = 1000*count;
		// if(amount>1) count = count*amount;
        [SystemUtils addGameResource:count ofType:kGameResourceTypeIAPCoin];
        if(amount>1) {
            for(int i=1; i<amount;i++) {
                [SystemUtils addGameResource:count ofType:kGameResourceTypeIAPCoin];
                SNSLog(@"buy %i coins", count);
            }
        }
	}
	if(iapType == 2) {
        [SystemUtils addGameResource:count ofType:kGameResourceTypeIAPLeaf];
        if(amount > 1) {
            for(int i=0;i<amount;i++) {
                [SystemUtils addGameResource:count ofType:kGameResourceTypeIAPLeaf];
                SNSLog(@"buy %i leaves", count);
            }
        }
	}
	if(iapType == 3) {
        [SystemUtils addGameResource:count ofType:kGameResourceTypeIAPPromo];
        if(amount > 1) {
            for(int i=0;i<amount;i++) {
                [SystemUtils addGameResource:count ofType:kGameResourceTypeIAPPromo];
                SNSLog(@"buy %i leaves", count);
            }
        }
	}
    if(iapType == 4) {
        [SystemUtils addIapItem:itemName withCount:count];
    }
    
	
	
    /*
	double totalCost = [[[SystemUtils getGameDataDelegate] getExtraInfo:kTotalPayment] doubleValue];
	double price = [[priceInfo objectForKey:@"price"] doubleValue]*amount;
	totalCost += price;
	[[SystemUtils getGameDataDelegate] setExtraInfo:[NSNumber numberWithDouble:totalCost] forKey:kTotalPayment];
	NSString *iapID = nil; int logType = kLogTypeEarnLeaf;
	if(iapType==1) {
		iapID = [NSString stringWithFormat:@"Coin%i",oldCount];
		logType = kLogTypeEarnCoin;
	}
	else if(iapType==2) {
		iapID = [NSString stringWithFormat:@"Leaf%i", oldCount];
		logType = kLogTypeEarnLeaf;
    }
	else if(iapType==3) {
		iapID = [NSString stringWithFormat:@"Promo%i", oldCount];
		logType = kLogTypeEarnPromo;
    }
	// log payment info
	[SystemUtils logPaymentInfo:price*100 withItem:iapID];
	[SystemUtils logResourceChange:logType method:kLogMethodTypePayment itemID:iapID count:count];
     */
    
}

+ (void) didFinishReportIAP:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	if (!error) {
		// NSString *response = [request responseString];
		SNSLog(@"%s: response string:%@", __FUNCTION__, [request responseString]);
	}
	else {
		SNSLog(@"%s: error info:%@", __FUNCTION__, error);
	}
}

// 检查用户最新状态
-(void) checkPlayerStatus
{
	//NSLog(@"%s",__func__);
	// create sync queue
	// Queue up some sync operations
	checkingStep = kLoadingStepCheckStatus;
	SyncQueue* syncQueue = [SyncQueue syncQueue];
	
	StatusCheckOperation* statusCheckOp = [[StatusCheckOperation alloc] initWithManager:syncQueue andDelegate:self];
	[syncQueue.operations addOperation:statusCheckOp];
	[statusCheckOp release];
	
	/*
	 RemoteGameLoadOperation* remoteLoadOp = [[RemoteGameLoadOperation alloc] initWithManager:syncQueue andDelegate:self];
	 [syncQueue.operations addOperation:remoteLoadOp];
	 [remoteLoadOp release];
	  */
}

// 检查是否有未发送的通知点击记录
- (void) checkPendingNoticeReport
{
    int noticeID = [[SystemUtils getNSDefaultObject:kClickedNoticeID] intValue];
    if(noticeID>0) {
        SyncQueue *syncQue = [SyncQueue syncQueue];
        NoticeReportOperation *action = [[NoticeReportOperation alloc] initWithManager:syncQue andDelegate:nil];
        action.noticeID = noticeID;
        action.actionType = kSNSNoticeActionTypeClick;
        [syncQue.operations addOperation:action];
        [action release];
    }
}

// 正式进入游戏
-(void) startGameScene
{
	if(isGameStarted) return;
    
    [SystemUtils correctCurrentTime];
    
	isGameStarted = YES;
	[SystemUtils setLoadingScreenText: [SystemUtils getLocalizedString:@"Loading Game Config"]];
    
    if([self checkForceUpdateOrBlock]) {
        return;
    }
	// SNSLog(@"start");
#ifndef SNS_DISABLE_NETWORK_CHECK
	if([SystemUtils isNetworkRequired] && !isNetworkOK)
	{
		// show network required alert
		[SystemUtils showNetworkRequired];
		return;
	}
#endif
	if(![SystemUtils verifyAllConfigFiles]) {
#if TARGET_IPHONE_SIMULATOR
        // DONOTHING
#else
        if([[SystemUtils getGlobalSetting:@"kDisableProtectConfig"] intValue]==0) {
            [SystemUtils showConfigFileCorrupt];
            return;
        }
#endif
	}
	int noWaitResourceLoad = [[SystemUtils getSystemInfo:@"kNeverWaitLoadingResource"] intValue];
    
	if(![SystemUtils verifyAllLoadedConfigFiles]) {
		[SystemUtils showRemoteItemRequired];
		return;
	}
	// SNSCrashLog(@"start");
	
	// [SystemUtils showHackAlert];
	
	// SNSLog(@"localTime:%i deviceTIme:%i", [SystemUtils getCurrentTime], [SystemUtils getCurrentDeviceTime]);
	// [[CTimerManager sharedTimerManager] resetDate];
	// [[CTimerManager sharedTimerManager] setCurrentTime:[SystemUtils getCurrentTime]];
	
	// set last enter time
	[SystemUtils setPlayerDefaultSetting:[NSNumber numberWithInt:[SystemUtils getCurrentTime]] forKey:kLastBootTime];
	
	// load remote item
	// [GameConfig updateRemoteFile];
	// load game config
	// SNSCrashLog(@"load game config start");
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationReloadGameConfig object:nil userInfo:nil];
	// SNSCrashLog(@"load game config ok");
	
	[SystemUtils setLoadingScreenText: [SystemUtils getLocalizedString:@"Loading Game Data"]];
	// 初始化进度
	// SNSCrashLog(@"load game data start");
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationLoadGameData object:nil userInfo:nil];
	// SNSCrashLog(@"load game data ok");
	// NSLog(@"%s:check itemVer gameData:%@",__FUNCTION__, [SystemUtils getGameDataDelegate]);
	// 检查进度文件中的版本号
	int itemVerInSave = [[[SystemUtils getGameDataDelegate] getExtraInfo:kItemFileVerKey] intValue];
	NSString *localKey = [NSString stringWithFormat:@"%@-%@",kItemFileLocalVerKey, [SystemUtils getCurrentLanguage]];
    int itemVerLocal  = [[SystemUtils getGlobalSetting:localKey] intValue];
    if(itemVerLocal == 0) {
        itemVerLocal  = [[SystemUtils getGlobalSetting:kItemFileLocalVerKey] intValue];
    }
    
	// int itemVerLocal  = [[SystemUtils getGlobalSetting:kItemFileLocalVerKey] intValue];
	// backward support
	int itemVerRemote = [[SystemUtils getGlobalSetting:kItemFileVerKey] intValue];
    
	if(noWaitResourceLoad==0 && itemVerLocal < itemVerInSave && itemVerLocal < itemVerRemote && itemVerRemote>0) {
		int retryTimes = [[SystemUtils getNSDefaultObject:kDownloadItemRequired] intValue];
		SNSLog(@"%s: itemVerSave:%i itemVerLocal:%i retryTimes:%i", __func__, itemVerInSave, itemVerLocal, retryTimes);
		if(retryTimes==0) {
			[self setForceLoadStatus];
			// 重新加载远程道具
			isGameStarted = NO;
			[self startLoadingResource:YES];
			return;
		}
	}
    int retryTimes = [[SystemUtils getPlayerDefaultSetting:kCheckLostItemsTimes] intValue];
    if([[SystemUtils getGameDataDelegate] hasUnloadedItems])
    {
        SNSLog(@"%s: found lost items, retryTimes:%i", __func__, retryTimes);
        if(retryTimes==0 && noWaitResourceLoad==0) {
            [SystemUtils setPlayerDefaultSetting:[NSNumber numberWithInt:1] forKey:kCheckLostItemsTimes];
            [self setForceLoadStatus];
			// 重新加载远程道具
			isGameStarted = NO;
			[self startLoadingResource:YES];
			return;
        }
    }
    else {
        if(retryTimes>0) {
            [SystemUtils setPlayerDefaultSetting:[NSNumber numberWithInt:0] forKey:kCheckLostItemsTimes];
        }
    }
	/*
	 // 是否有丢失房间
	if([m_mainGameData hasLostRooms]) {
		[SystemUtils setPlayerDefaultSetting:[NSNumber numberWithInt:1] forKey:kDownloadItemRequired];
		NSLog(@"%s:lost room detected: itemVerSave:%i itemVerLocal:%i", __func__, itemVerInSave, itemVerLocal);
		[SystemUtils showRemoteItemRequired];// wwc 测试宝宝功能用
		return;
	}
	
	 // 房间数量是否正确
	if(![m_mainGameData isRoomCountValid]) {
		// force to load remote game
		NSLog(@"%s: room lost, force to reload", __func__);
		isGameStarted = NO;
		[SystemUtils setGlobalSetting:@"1" forKey:@"loadSave"];
		checkingStep = kLoadingStepCheckStatus;
		[self syncFinished];
		return;
	}
	 */
	
	if(itemVerLocal > itemVerInSave)
	{
		[[SystemUtils getGameDataDelegate] setExtraInfo:[NSNumber numberWithInt:itemVerLocal] forKey:kItemFileVerKey];
	}
	
	// SNSLog(@"check gameStat");
	// [SystemUtils checkGameStatInGameData];
	
	BOOL isTutorialStarted = [[SystemUtils getGameDataDelegate] isTutorialStart];
	
	int tutorialShown  = [[SystemUtils getGlobalSetting:kTutorialShown] intValue];
	if([[SystemUtils getGameDataDelegate] isTutorialFinished] || isTutorialStarted) tutorialShown = 1;
	
	if(tutorialShown == 0) {
		BOOL downloadSuccess = YES;
		/*
		if([SystemUtils isiPad])
		{
			int tutorialLoaded = [[SystemUtils getGlobalSetting:kTutorialLoaded] intValue];
			if(tutorialLoaded==0) {
				// load tutorial
				NSLog(@"%s: load tutorial", __func__);
				[SystemUtils setGlobalSetting:[NSNumber numberWithInt:2]  forKey:kTutorialLoaded];
				[self startLoadingTutorial];
				isGameStarted = NO;
				return;
			}
			if(tutorialLoaded==2) downloadSuccess = NO;
		}
		 */
		if(tutorialShown == 0 && downloadSuccess)
		{
			[self showPreviewScene];
			[SystemUtils setGlobalSetting:[NSNumber numberWithInt:1] forKey:kTutorialShown];
		}
	}
	[SystemUtils setLoadingScreenText: [SystemUtils getLocalizedString:@"Loading Game Scene"]];
	// SNSCrashLog(@"load game scene start");
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationStartGameScene object:nil userInfo:nil];
	// SNSCrashLog(@"load game scene end");

	// [SystemUtils showReviewHint];
	[SystemUtils hideLoadingScreen];
	
#ifndef SNS_DISABLE_GAME_LOADSAVE
    int localSaveID = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeExp];
    int uploadSaveID = [[SystemUtils getNSDefaultObject:kLastUploadSaveID] intValue];
    int todayDate = [SystemUtils getTodayDate];
    int lastUploadDate = [[SystemUtils getNSDefaultObject:@"kLastUploadSaveDate"] intValue];
    SNSLog(@"local:%i uploaded:%i", localSaveID, uploadSaveID);
    if(uploadSaveID<localSaveID && todayDate>lastUploadDate) {
        SNSLog(@"start uploading savefile");
        // start upload save file
        SyncQueue* syncQueue = [SyncQueue syncQueue];
        GameSaveOperation* saveOp = [[GameSaveOperation alloc] initWithManager:syncQueue andDelegate:nil];
        [syncQueue.operations addOperation:saveOp];
        [saveOp release];
    }
#endif

	
#ifndef SNS_DISABLE_TAPJOY
    [[TapjoyHelper helper] initTapjoySession];
#endif
    int playTimes = [[SystemUtils getNSDefaultObject:kPlayTimes] intValue];
    if(playTimes<10) {
#ifndef SNS_DISABLE_FLURRY_V1
        [[FlurryHelper helper] initFlurrySession];
#endif
    }
    
    [SystemUtils logPlayTimeStart];
    
    [self performSelector:@selector(initPaymentAndAds) withObject:nil afterDelay:3.0f];
    
    // 加载通知图片
    [self loadNoticeImage];
    
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
    [SNSPromotionViewController loadNoticeList];
#endif
    
    // 游戏Helper回调
    NSObject<GameDataDelegate> *gameHelper = [SystemUtils getGameDataDelegate];
    if([gameHelper respondsToSelector:@selector(onGameStarted)]) {
        [gameHelper onGameStarted];
    }
}



// 后台加载资源文件
-(void)startLoadingResource:(BOOL)block
{
	id deleg = nil;
	if(block) deleg = self;
    checkingStep = kLoadingStepLoadResource;
	// start loading resource
	SyncQueue* syncQueue = [SyncQueue syncQueue];
	// load language
	LangLoadOperation* langOp = [[LangLoadOperation alloc] initWithManager:syncQueue andDelegate:deleg];
	[syncQueue.operations addOperation:langOp];
	[langOp release];
    
#ifndef SNS_DISABLE_REMOTECONFIG
	// load items
	ItemLoadOperation *itemOp = [[ItemLoadOperation alloc] initWithManager:syncQueue andDelegate:deleg];
	[syncQueue.operations addOperation:itemOp];
	[itemOp release];
#endif
    /*
	// report to stat server
	StatSendOperation* statOp = [[StatSendOperation alloc] initWithManager:syncQueue andDelegate:nil];
	[syncQueue.operations addOperation:statOp];
	[statOp release];
     */
    if(!block) {
        [SystemUtils setNSDefaultObject:@"1" forKey:@"kLoadItemInBG"];
    }
    else {
        [SystemUtils setNSDefaultObject:@"0" forKey:@"kLoadItemInBG"];
    }
}



// init payment and ads setting
-(void) initPaymentAndAds
{
	// PlayerConfig *conf = [PlayerConfig config];
	// NSLog(@"UDID:%@",conf.UDID);
	// if(![NetworkHelper isConnected]) return;
    if(isPaymentStarted) return;
    isPaymentStarted = YES;
	// tapjoy pay per action call
	// [TapjoyConnect actionComplete:@"actionID"];
#ifndef SNS_DISABLE_PLAYHAVEN
    // init playhaven
    // [[PlayHavenHelper helper] initSession];
#endif
	/*
	 // apsalar
	 NSString *kAppSalarKey = [SystemUtils getGlobalSetting:kAppSalarAppIdKey];
	 NSString *kAppSalarSecret = [SystemUtils getGlobalSetting:kAppSalarAppSecretKey];
	 if(kAppSalarKey && kAppSalarSecret)
	 [Apsalar startSession:kAppSalarKey withKey:kAppSalarSecret];
	 */
    // only show first time
    [self startTinyMobi];
	// flurry
    [self initAdMobBanner];
    
    
#ifdef SNS_ENABLE_FLURRY_V2
    [[FlurryHelper2 helper] initSession];
#endif
    
#ifdef SNS_ENABLE_KIIP
    if([SystemUtils checkFeature:kFeatureShowAd] && [SystemUtils checkFeature:kFeatureKiip]) {
        // 启动Kiip广告
        SNSLog(@"start kiip");
        // Start and initialize when application starts
        KPManager *manager = [[KPManager alloc] initWithKey:@"d4ae8bf9d7e2b06107d2315ab4a8087e" secret:@"390d73795db133d83c3770f5d70ecd95"];
        // Set the shared instance after initialization
        // to allow easier access of the object throughout the project.
        // get current device orientation
        [manager setGlobalOrientation:[UIDevice currentDevice].orientation];
        // [manager setGlobalOrientation:[SystemUtils getGameOrientation]];
        [KPManager setSharedManager:manager];
        [manager release];    
    }
#endif
    
#ifdef SNS_ENABLE_MDOTM
    [[MdotMHelper helper] initSession];
#endif
    // send install report
    int playTimes = [[SystemUtils getNSDefaultObject:kPlayTimes] intValue];
    BOOL reportInstall = NO;
    if(playTimes<10 || playTimes%10==0) reportInstall = YES;
#ifdef DEBUG
    reportInstall = YES;
#endif
    if(reportInstall) {
        // facebook
#ifndef SNS_DISABLE_FACEBOOK
        if([[SystemUtils getiOSVersion] compare:@"5.0"]>=0) {
        [FacebookHelper installReport];
        }
#endif
        // admob
        [SystemUtils performSelectorInBackground:@selector(reportAppOpenToAdMob) withObject:nil];
        // my own install
        // [SystemUtils performSelectorInBackground:@selector(reportInstallToServer) withObject:nil];
        // adwhirl
        // [self showAdWhirlBanner];
        // greystrip
        // inMobi
        // MdotM
        // [SystemUtils performSelectorInBackground:@selector(reportAppOpenToMdotM) withObject:nil];
        // playhaven
        // [SystemUtils performSelectorInBackground:@selector(reportAppOpenToPlayHaven) withObject:nil];
    }
#ifndef SNS_DISABLE_FACEBOOK
    if([[SystemUtils getiOSVersion] compare:@"5.0"]>=0) {
        [[FacebookHelper helper] checkIncomingNotification];
    }
#endif
#ifdef SNS_ENABLE_WEIXIN
    [[WeixinHelper helper] initSession];
#endif
    
#ifdef SNS_ENABLE_GROWMOBILE
    if([SystemUtils isGrowMobileEnabled]) {
        NSString *key = [SystemUtils getSystemInfo:@"kGrowMobileAppKey"];
        NSString *secret = [SystemUtils getSystemInfo:@"kGrowMobileAppSecret"];
        SNSLog(@"connecting to growMobile, key:%@ secret:%@", key, secret);
        [GrowMobileSDK setAppKey:key andSecret:secret];
        [GrowMobileSDK reportOpen];
    }
#endif
    
#ifdef SNS_ENABLE_MOBISAGE
    [[MobiSageHelper helper] initSession];
#endif
    
#ifdef SNS_ENABLE_APPLOVIN
    [[AppLovinHelper helper] initSession];
#endif
    
#ifdef SNS_ENABLE_SPONSORPAY
    [[SponsorPayHelper helper] initSession];
#endif
    
#ifdef SNS_ENABLE_AARKI
    [[AarkiHelper helper] initSession];
#endif
 
#ifdef SNS_ENABLE_CHARTBOOST
    [[ChartBoostHelper helper] initSession];
#endif
    
#ifdef SNS_ENABLE_GUOHEAD
    [[MixGHHelper helper] initSession];
#endif
#ifdef SNS_ENABLE_DOMOB
    [[DomobHelper helper] initSession];
#endif
#ifdef SNS_ENABLE_YOUMI
    [[YoumiHelper helper] initSession];
#endif
    
#ifdef SNS_ENABLE_DIANRU
    [[DianruHelper helper] initSession];
#endif
#ifdef SNS_ENABLE_ADWO
    [[AdwoHelper helper] initSession];
#endif
#ifdef SNS_ENABLE_TAPJOY2
    [[TapjoyHelper2 helper] initTapjoySession];
#endif
#ifdef SNS_ENABLE_IAD
    [[iAdHelper helper] initSession];
#endif

#ifndef SNS_DISABLE_GAME_CENTER
	if([SystemUtils isGameCenterAPIAvailable]) {
		// [gameCenterHelper initGameCenter];
        int days = [SystemUtils getLoginDayCount];
        // only show one time
        int lastDays = [[SystemUtils getNSDefaultObject:@"kGameCenterLastDays"] intValue];
#ifdef DEBUG
        lastDays = -10;
#endif
        if(lastDays<days-1) {
            [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:days] forKey:@"kGameCenterLastDays"];
            SNSLog(@"days:%i lastDays:%i start authenticateLocalUser", days, lastDays);
            [[GameCenterHelper helper] performSelector:@selector(authenticateLocalUser) withObject:nil afterDelay:10.0f];
        }
	}
#endif
    
#ifdef SNS_ENABLE_ICLOUD
    [[iCloudHelper helper] initSession];
#endif
    
#ifdef SNS_ENABLE_ADX
    [[AdxHelper helper] initSession];
#endif
#ifdef SNS_ENABLE_MINICLIP
    [[MiniclipHelper helper] initSession:m_launchOptions];
#endif
    
#ifdef SNS_ENABLE_CHUKONG
    [[ChukongHelper helper] initSession];
#endif
    
#ifdef SNS_ENABLE_YIJIFEN
    [[YijifenHelper helper] initSession];
#endif
    
#ifdef SNS_ENABLE_WAPS
    [[WapsHelper helper] initSession];
#endif
    
#ifdef SNS_ENABLE_ADJUST
    [[AdjustHelper helper] initSession];
#endif
    
    [self refreshSessionStatus];

}

// 检查是否有强制更新状态和黑名单状态，如果有，就返回YES，否则返回NO
- (BOOL) checkForceUpdateOrBlock
{
    // check blocked status
    int isBlockUser = [[SystemUtils getGlobalSetting:@"isBlockedUser"] intValue];
    if(isBlockUser) {
        [SystemUtils showBlockedAlert];
        return YES;
    }
    
    // check force update
    NSString *updateVer = [SystemUtils getGlobalSetting:@"kForceUpdateVersion"];
#ifdef DEBUG
    // updateVer = @"1.8.8";
#endif
    NSString *curVer = [SystemUtils getClientVersion];
    //if([updateVer floatValue]>=[curVer floatValue])
    if(updateVer && [updateVer length]>1 && [curVer compare:updateVer]<=0)
    {
        [SystemUtils showForceUpdateAlert];
        return YES;
    }
    
    // [SystemUtils showHackAlert];
    return NO;
}

- (void) showBugFixHint:(NSDictionary *)info
{
    [SystemUtils showCrashBugFixed:info];
}

// 显示AdMob广告
- (void) showAdmobBanner
{
    if([SystemUtils isPaidVersion]) return;
    if(![SystemUtils isAdVisible]) return;
    if(![SystemUtils checkFeature:kFeatureAdMob]) return;
    if(!m_adMobController) [self initAdMobBanner];
    if(m_adMobController) {
#ifdef SNS_ENABLE_ADMOB
        AdmobViewController *ad = m_adMobController;
        if(![SystemUtils isAdVisible] || ![SystemUtils checkFeature:kFeatureAdMob]) {
            ad.view.hidden = YES; return;
        }
        ad.view.hidden = NO;
        [ad updatePosition];
#endif
        // hide it after 10 seconds
        // [self performSelector:@selector(hideAdmobBanner) withObject:nil afterDelay:10.0f];
        return;
    }
}

// 创建AdMob广告View
- (void) initAdMobBanner
{
    if(m_adMobController) return;
    // create admob container
    SNSLog(@"start load admob");
#ifdef SNS_ENABLE_ADMOB
#ifndef DEBUG
    if(![SystemUtils isAdVisible]) return;
#endif
    if(![SystemUtils checkFeature:kFeatureAdMob]) return;
    UIViewController *root = [SystemUtils getRootViewController];
    if(!root) {
        SNSLog(@"no root view controller"); return;
    }
    
    NSString *pubID = [SystemUtils getSystemInfo:@"kAdMobPublisherID"];
    if(pubID && [pubID length]>0) {
        AdmobViewController *adController = [[AdmobViewController alloc] initWithNibName:nil bundle:nil];
        m_adMobController = adController;
        [root.view addSubview:adController.view];
        adController.view.hidden = YES;
        // hide it after 10 seconds
        // [self performSelector:@selector(hideAdmobBanner) withObject:nil afterDelay:10.0f];
    }
#endif
    
}

// 隐藏admob广告
- (void) hideAdmobBanner
{
#ifdef SNS_ENABLE_ADMOB
    if(!m_adMobController) return;
    SNSLog(@"hide admob");
    UIViewController *ad = m_adMobController;
    ad.view.hidden = YES;
#endif
}

- (void) startTinyMobi
{
#ifdef SNS_ENABLE_TINYMOBI
    [[TinyMobiHelper helper] resetSession];
#endif
}

// 刷新session状态
-(void) refreshSessionStatus
{
    [SystemUtils showInGameNotice];
    [self checkPendingNoticeReport];
    [[TinyiMailHelper helper] checkEmailGift];
    
    // request IAP info
    if([[SystemUtils getGameDataDelegate] isTutorialFinished])
        [[InAppStore store] requestProductData];
    
    
    [self showEmailLinkPrize];
    
    if([[SystemUtils getiOSVersion] compare:@"5.0"]>=0) {
    // 提示给好友发送礼物
    [[FacebookHelper helper] sendGiftToFriendsDaily];
#ifdef SNS_ENABLE_TICKET_FEATURE
    [[FacebookHelper helper] performSelectorInBackground:@selector(loadTicketFromServer) withObject:nil];
#endif
    }
    

    // only do once per day
#ifndef SNS_DISABLE_TAPJOY
        if([SystemUtils checkFeature:kFeatureTapjoy])
            [[TapjoyHelper helper] checkPointsLazy];
#endif
#ifdef SNS_ENABLE_FLURRY_V2
        if([SystemUtils checkFeature:kFeatureFlurry])
            [[FlurryHelper2 helper] getRewardsLazy];
#endif
#ifdef SNS_ENABLE_LIMEI
        if([SystemUtils checkFeature:kFeatureLiMei])
            [[LiMeiHelper helper] checkPointsLazy];
#endif
#ifdef SNS_ENABLE_LIMEI2
        if([SystemUtils checkFeature:kFeatureLiMei])
            [[LiMeiHelper2 helper] checkPointsLazy];
#endif
#ifdef SNS_ENABLE_APPDRIVER
        if([SystemUtils checkFeature:kFeatureAppDriver])
            [[AppDriverHelper helper] checkPointsLazy];
#endif
    
#ifndef SNS_DISABLE_TINYMAIL
    [[TinyiMailHelper helper] startCheckStatus:NO];
#endif
    
#ifdef SNS_ENABLE_LIMEI
    if([SystemUtils checkFeature:kFeatureLiMei])
        [[LiMeiHelper helper] checkPointsLazy];
#endif
#ifdef SNS_ENABLE_DOMOB
    [[DomobHelper helper] checkPointsLazy];
#endif
#ifdef SNS_ENABLE_YOUMI
    [[YoumiHelper helper] checkPointsLazy];
#endif
#ifdef SNS_ENABLE_DIANRU
    [[DianruHelper helper] checkPointsLazy];
#endif
#ifdef SNS_ENABLE_ADWO
    [[AdwoHelper helper] checkPointsLazy];
#endif
#ifdef SNS_ENABLE_TAPJOY2
    [[TapjoyHelper2 helper] checkPointsLazy];
#endif
    // Loading TinyMobi
#ifdef SNS_ENABLE_TINYMOBI
    if([SystemUtils checkFeature:kFeatureTinyMobi])
    {
        BOOL showTinymobi = YES;
#ifndef DEBUG
        if([[SnsStatsHelper helper] getTotalPay]>0) showTinymobi = NO;
#endif
        if(showTinymobi)
            [[TinyMobiHelper helper] checkRewards];
    }
#endif
    
#ifdef SNS_ENABLE_SPONSORPAY
    [[SponsorPayHelper helper] checkCoins];
#endif
    
#ifdef SNS_ENABLE_AARKI
    [[AarkiHelper helper] getRewardsLazy];
#endif
#ifdef SNS_ENABLE_ADX
    [[AdxHelper helper] reportAppOpen];
#endif
#ifdef SNS_ENABLE_CHUKONG
    [[ChukongHelper helper] checkPointsLazy];
#endif
    
#ifdef SNS_ENABLE_YIJIFEN
    [[YijifenHelper helper] checkPointsLazy];
#endif
    
#ifdef SNS_ENABLE_WAPS
    [[WapsHelper helper] checkPointsLazy];
#endif
    
#ifdef SNS_ENABLE_MOBISAGE
    [[MobiSageHelper helper] checkPointsLazy];
#endif

}

#pragma mark -

#pragma mark Check Loaded Resources

- (void) setForceLoadStatus
{
    SNSLog(@" stack: %@", [NSThread callStackSymbols]);
	[SystemUtils setNSDefaultObject:[NSNumber numberWithInt:1] forKey:kDownloadItemRequired];
}

- (BOOL)checkImages:(NSArray *)pets ofFile:(NSString *)file
{
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSString *localFileRoot = [SystemUtils getItemImagePath];
	
	NSString *fieldKey = [NSString stringWithFormat:@"kConfigFileField-%@", file];
	NSDictionary *fieldList = [SystemUtils getSystemInfo:fieldKey];
	
	if(!fieldList || [fieldList count]==0) return YES;
	NSString *typeFieldName = [fieldList objectForKey:@"TypeFieldName"];
	NSString *allFieldName  = [fieldList objectForKey:@"FieldName"];
	
	BOOL loadAllOK = YES;
	for(int i=0;i<[pets count];i++)
	{
		NSDictionary *info = [pets objectAtIndex:i];
		BOOL loadOK = NO;
		// NSString *localFileRoot = [SystemUtils getItemImagePath];
		NSString *fileName = nil;
		if(typeFieldName) {
			NSString *type = [info objectForKey:typeFieldName];
			
			NSString *fieldName = [fieldList objectForKey:type];
			if(!fieldName) continue;
			NSArray *fieldNameList = [fieldName componentsSeparatedByString:@";"];
			for(fieldName in fieldNameList) {
				NSArray *arr = [fieldName componentsSeparatedByString:@","];
				fieldName = [arr objectAtIndex:0];
				BOOL hasSuffix = ([arr count]>=2);
				NSString *suffix = nil;
				if(hasSuffix) suffix = [arr objectAtIndex:1]; 
				fileName = [info objectForKey:fieldName];
				if(!fileName) continue;
				if(hasSuffix)
					fileName = [NSString stringWithFormat:@"%@.%@", fileName, suffix];
				loadOK = [mgr fileExistsAtPath: [localFileRoot stringByAppendingPathComponent: fileName]];
				if(!loadOK) {
                    SNSLog(@"missing remote item image %@/%@", localFileRoot, fileName);
					loadAllOK = NO; continue;
				}
			}
		}
		if(allFieldName) {
			NSString *fieldName = allFieldName;
			NSArray *fieldNameList = [fieldName componentsSeparatedByString:@";"];
			for(fieldName in fieldNameList) {
				NSArray *arr = [fieldName componentsSeparatedByString:@","];
				fieldName = [arr objectAtIndex:0];
				BOOL hasSuffix = ([arr count]>=2);
				NSString *suffix = nil;
				if(hasSuffix) suffix = [arr objectAtIndex:1]; 
				fileName = [info objectForKey:fieldName];
				if(!fileName) continue;
				if(hasSuffix)
					fileName = [NSString stringWithFormat:@"%@.%@", fileName, suffix];
				loadOK = [mgr fileExistsAtPath: [localFileRoot stringByAppendingPathComponent: fileName]];
				if(!loadOK) {
                    SNSLog(@"missing remote item image %@/%@", localFileRoot, fileName);
					loadAllOK = NO; continue;
				}
			}
		}
	}
	return loadAllOK;
}

// 检查是否有丢失的资源文件
- (void) checkLostCacheResource
{
	int playTimes = [[SystemUtils getNSDefaultObject:kPlayTimes] intValue];
	if(playTimes == 1) return; // no need to check
	NSArray *itemFiles = [SystemUtils getLoadedConfigFileNames];
	NSString *itemPath = [SystemUtils getItemRootPath];
	NSFileManager *mgr = [NSFileManager defaultManager];
	// NSError *err = nil; 
	BOOL loadImageOK = YES;
	for(int i=0;i<[itemFiles count];i++)
	{
		NSString *aKey = [itemFiles objectAtIndex:i];
		NSString *file = [itemPath stringByAppendingPathComponent:aKey];
		if(![mgr fileExistsAtPath:file]) {
			// [self setForceLoadStatus]; return;
            continue;
		}
        /*
		NSString *text = [items JSONRepresentation];
		BOOL res = [text writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:&err];
		*/
        NSString *text = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
        if([text length]>30 && [text characterAtIndex:0]=='|') 
            text = [SystemUtils stripHashFromSaveData:text];
        text = [SystemUtils stripHashFromSaveData:text];
		NSArray *items = [StringUtils convertJSONStringToObject:text];
		if(!items || [items count]==0) {
			SNSLog(@"invalid config file %@", file);
			// [self setForceLoadStatus]; return;
            continue;
		}
		NSDictionary *fieldInfo = [SystemUtils getSystemInfo:[NSString stringWithFormat:@"kConfigFileField-%@", aKey]];
		if(fieldInfo) 
		{
			loadImageOK = [self checkImages:items ofFile:aKey];
		}
		if(!loadImageOK) { 
			[self setForceLoadStatus]; return;
		}
	}	
}


#pragma mark -

#pragma mark SyncQueueDelegate

- (void)statusMessage:(NSString*)text cancelAfter:(int)seconds
{
    // Set the new message
    // [self performSelectorOnMainThread: @selector(setLoadingTip:) withObject:text waitUntilDone:NO];
    // Schedule a cancel button after the specified seconds
    // if (seconds > -1)
    //    [self performSelector:@selector(showMessageViewCancel) withObject: nil afterDelay:seconds];
    SNSLog(@"%@", text);
	[SystemUtils setLoadingScreenText:text];
}

- (void) checkAWSData:(BOOL)gameAlreadyLoaded
{
#ifdef SNS_ENABLE_EMAIL_BIND
    // 检查是否需要下载存档
    int kForceLoadAWS = [[SystemUtils getNSDefaultObject:@"kForceLoadAWS"] intValue];
    if(kForceLoadAWS==1) {
        // 必须下载存档
        if([[BindEmailHelper helper] isLoggedIn]) {
            if(gameAlreadyLoaded)
                [BindEmailHelper helper].gameStatus = kBindHelperStatusGameLoaded;
            else
                [BindEmailHelper helper].gameStatus = kBindHelperStatusGameStart;
            [[BindEmailHelper helper] getRemoteData];
        }
        else {
            [SystemUtils setNSDefaultObject:nil forKey:@"kForceLoadAWS"];
            [self syncFinished];
        }
    }
    else {
        // 检查是否需要上传存档
        [[BindEmailHelper helper] updateData];
        [self syncFinished];
    }
#endif
}

- (void)syncFinished
{
	SNSLog(@"checkingStep=%i", checkingStep);
	// [self performSelectorOnMainThread: @selector(removeLoading:) withObject:nil waitUntilDone:NO];
	BOOL startGame = NO;
	if(checkingStep == kLoadingStepCheckStatus) {
		
        if(!isNetworkOK && [[SystemUtils getSystemInfo:@"kForceNetwork"] intValue]==1)
        {
            [SystemUtils showNetworkRequired];
            return;
        }
        
        checkingStep = kLoadingStepLoadNoticeImage1;
        // 不在这里加载通知图片，改到游戏开始之后，以免加长启动游戏的等待时间
		// load image notice in background
		// [self loadNoticeImage];
        // go to next step
        [self syncFinished];
    }
    else if(checkingStep == kLoadingStepLoadNoticeImage1) {
		
		checkingStep = kLoadingStepLoadGameData;
#ifdef SNS_DISABLE_GAME_LOADSAVE
        [self syncFinished];
#else
#ifdef SNS_ENABLE_EMAIL_BIND
        [[BindEmailHelper helper] initSession];
        [self checkAWSData:NO];
#else
		int loadRemote   = [[SystemUtils getGlobalSetting:@"loadSave"] intValue];
		int remoteSaveID = [[SystemUtils getGlobalSetting:@"saveId"] intValue];
		if(remoteSaveID == 0) remoteSaveID = [[SystemUtils getGlobalSetting:@"saveID"] intValue];
		int localSaveID = [SystemUtils getSaveID];
        // 如果是自动从旧存档恢复的进度，就不加载进度
        int isUsingRecover = [[SystemUtils getGlobalSetting:@"kIsRecoveredSaveFile"] intValue];
        
		if(loadRemote > 0 || (localSaveID<remoteSaveID && isUsingRecover==0)) {
			// start loading save
			SyncQueue* syncQueue = [SyncQueue syncQueue];
			
			GameLoadOperation* loadOp = [[GameLoadOperation alloc] initWithManager:syncQueue andDelegate:self];
			[syncQueue.operations addOperation:loadOp];
			[loadOp release];
            // 强制加载资源文件
            int noWaitResourceLoad = [[SystemUtils getSystemInfo:@"kNeverWaitLoadingResource"] intValue];
            if(noWaitResourceLoad==0)
                [self setForceLoadStatus];
		}
		else {
			[self syncFinished];
		}
#endif
#endif
	}
	else if(checkingStep == kLoadingStepLoadGameData) {
		checkingStep = kLoadingStepLoadResource;
		
        int forceLoad = 0;
		forceLoad = [[SystemUtils getNSDefaultObject:kDownloadItemRequired] intValue];
        int noWaitResourceLoad = [[SystemUtils getSystemInfo:@"kNeverWaitLoadingResource"] intValue];
        
		//int forceLoad = [[SystemUtils getPlayerDefaultSetting:kDownloadItemRequired] intValue];
        //if(forceLoad==1) [SystemUtils setPlayerDefaultSetting:@"0" forKey:kDownloadItemRequired];

#ifndef SNS_DISABLE_CHECK_LOST_RESOURCE
		// 检查缓存的资源文件是否丢失
		[SystemUtils setLoadingScreenText:[SystemUtils getLocalizedString:@"Checking Loaded Resources"]];
		[self checkLostCacheResource];
#endif
		// BOOL userFileExists = [SystemUtils isSaveFileExists];
		// int  localSaveID = [SystemUtils getSaveID];
		// int remoteSaveID = [[SystemUtils getGlobalSetting:@"saveId"] intValue]; 
		SNSLog(@"%s: forceLoad:%i", __func__, forceLoad);
		// if(forceLoad==1 || (userFileExists && localSaveID<remoteSaveID)) 
        if(forceLoad==1 && noWaitResourceLoad==0)
        {
			[self startLoadingResource:YES];
		}
        else if(noWaitResourceLoad==2) {
            // 先加载完配置文件再进入游戏
			[self startLoadingResource:YES];
        }
		else {
			[self startLoadingResource:NO];
			[self syncFinished];
		}
	}
	else if(checkingStep == kLoadingStepLoadResource) {
		checkingStep = kLoadingStepNone; 
		startGame = YES;
	}
	else if(checkingStep == kLoadingStepLoadTutorial) {
		checkingStep = kLoadingStepNone; 
		// start game directly
		// [self performSelectorOnMainThread:@selector(startGameScene) withObject:nil waitUntilDone:NO];
        startGame = YES;
	}
	else if(checkingStep == kLoadingStepSyncTime) {
        
        if(!isNetworkOK && [[SystemUtils getSystemInfo:@"kForceNetwork"] intValue]==1)
        {
            [SystemUtils showNetworkRequired];
            return;
        }
        
		// continue to reload status
		checkingStep = kLoadingStepReloadStatus;
		
		SyncQueue* syncQueue = [SyncQueue syncQueue];
		
		StatusCheckOperation* statusCheckOp = [[StatusCheckOperation alloc] initWithManager:syncQueue andDelegate:self];
		[syncQueue.operations addOperation:statusCheckOp];
		[statusCheckOp release];
        /*
        // report to stat server
        StatSendOperation* statOp = [[StatSendOperation alloc] initWithManager:syncQueue andDelegate:nil];
        [syncQueue.operations addOperation:statOp];
        [statOp release];
         */
	}
	else if(checkingStep == kLoadingStepReloadStatus) {
		// 从后台运行恢复到前台
        checkingStep = kLoadingStepLoadNoticeImage2;
        [self syncFinished];
        //if([[SystemUtils getiOSVersion] compare:@"5.0"]<0) {
        //}
#ifdef SNS_ENABLE_EMAIL_BIND
        [self checkAWSData:YES];
#endif
        // send resume notification
        [[NSNotificationCenter defaultCenter] postNotificationName:kSNSNotificationOnResumeFromBackground object:nil userInfo:nil];
    }
    else if(checkingStep == kLoadingStepLoadNoticeImage2) {
        
		checkingStep = kLoadingStepNone; 
        
		int loadRemote = [[SystemUtils getGlobalSetting:@"loadSave"] intValue];
		int remoteSaveID = [[SystemUtils getGlobalSetting:@"saveId"] intValue];
		if(remoteSaveID == 0) remoteSaveID = [[SystemUtils getGlobalSetting:@"saveID"] intValue];
		int localSaveID = [SystemUtils getSaveID];
        // 如果试自动从旧存档恢复的进度，就不加载进度
        int isUsingRecover = [[SystemUtils getGlobalSetting:@"kIsRecoveredSaveFile"] intValue];
        if(![[SystemUtils getSystemInfo:@"kDisableUploadSave"] boolValue]) {
            if(loadRemote>0 || (remoteSaveID>localSaveID && isUsingRecover==0)) {
                [SystemUtils showReloadGameRequired]; return;
            }
        }
        if(![self checkForceUpdateOrBlock]) {
            [self refreshSessionStatus];
        }
		// 后台加载远程道具
        [self startLoadingResource:NO];
        // 后台加载通知图片
		[self loadNoticeImage];
        
	}
	
	if(startGame)
	{
		[self performSelectorOnMainThread:@selector(startGameScene) withObject:nil waitUntilDone:NO];
        [self performSelector:@selector(showEmailLinkPrize) withObject:nil afterDelay:5.0f];
	}
}


- (void)syncFailed
{
	SNSLog(@"failed");
	if(checkingStep == kLoadingStepSyncTime || checkingStep == kLoadingStepReloadStatus)
	{
        isNetworkOK = NO;
        
        if(!isNetworkOK && [[SystemUtils getSystemInfo:@"kForceNetwork"] intValue]==1)
        {
            [SystemUtils showNetworkRequired];
            return;
        }
        
        if(![self checkForceUpdateOrBlock]) {
            [self refreshSessionStatus];
        }
        
		return;
	}
	if(checkingStep == kLoadingStepLoadGameData) {
		[self syncFinished];
	}
	else {
        checkingStep = kLoadingStepNone;
		[self performSelectorOnMainThread:@selector(startGameScene) withObject:nil waitUntilDone:NO];
		// [self startGameScene];
	}
}

// 加载iPad教程图
-(void)startLoadingTutorial
{
	checkingStep = kLoadingStepLoadTutorial;
	SyncQueue* syncQueue = [SyncQueue syncQueue];
	
	TutorialLoadOperation* loadOp = [[TutorialLoadOperation alloc] initWithManager:syncQueue andDelegate:self];
	[syncQueue.operations addOperation:loadOp];
	[loadOp release];
}

// 加载通知图片
-(void) loadNoticeImage
{
    SyncQueue* syncQueue = [SyncQueue syncQueue];
    
    NoticeLoadOperation* loadOp = [[NoticeLoadOperation alloc] initWithManager:syncQueue andDelegate:nil];
    [syncQueue.operations addOperation:loadOp];
    [loadOp release];
    
    /*
	NSArray *noticeArr = [SystemUtils getGlobalSetting:@"noticeInfo"];
	if(!noticeArr || ![noticeArr isKindOfClass:[NSArray class]]) return;
	BOOL hasImage = NO;
	for(NSDictionary *notice in noticeArr)
	{
		if(![notice isKindOfClass:[NSDictionary class]]) continue;
		if([[notice objectForKey:@"type"] intValue]==2) {
			hasImage = YES; break;
		}
	}
	if(hasImage)
	{
		SyncQueue* syncQueue = [SyncQueue syncQueue];
		
		NoticeLoadOperation* loadOp = [[NoticeLoadOperation alloc] initWithManager:syncQueue andDelegate:nil];
		[syncQueue.operations addOperation:loadOp];
		[loadOp release];
	}
     */
}

// show preview image
-(void)showPreviewScene
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationShowPreviewScene object:nil userInfo:nil];
	/*
	CCScene *scene = [CCScene node];
	CGamePreviewLayer *gplayer = [CGamePreviewLayer node];
	[scene addChild: gplayer];
	[gplayer startRun];
	[[CCDirector sharedDirector] pushScene:scene];
	 */
}



// save device token to remote server
-(void) saveDeviceToken:(NSData *)token
{
	if(!token || [token length]==0) return;
	NSString *deviceToken = [Base64 encode:token];
	SNSLog(@"get device token:%@", deviceToken);
	[SystemUtils setDeviceToken:deviceToken];
}

#pragma mark -

#pragma mark UIAlertViewDelegate

- (void) onAlertViewFinished:(int)tagAlert withButtonIndex:(int)buttonIndex
{
    SNSLog(@"tag:%i buttonIndex:%i", tagAlert, buttonIndex);
	if (tagAlert == kTagAlertNetworkRequired || tagAlert == kTagAlertFileCorrupt || tagAlert == kTagAlertReloadGameRequired)
	{
		[self onApplicationGoesBackground];
		// [self applicationWillTerminate:[UIApplication sharedApplication]];
		exit(0);
	}
	if (tagAlert == kTagAlertViewRateIt && buttonIndex == 1)
	{
		NSString *link = [SystemUtils getAppRateLink];
#ifdef DEBUG
        // link = @"http://itunes.apple.com/us/app/id533451786?mt=8";
        // link = @"http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=533451786&mt=8";
        // link = @"itms://itunes.apple.com/us/app/id554425888?mt=8"; // this will open itunes in iPhone
        // link = @"itms-apps://itunes.apple.com/us/app/id554425888?mt=8";
#endif
		if(link) {
			SNSLog(@"%s: %@", __func__, link);
            NSURL *url = [NSURL URLWithString:link];
            [[UIApplication sharedApplication] openURL:url];
            // [SystemUtils openAppLink:link];
		}
	}
    if(tagAlert == kTagAlertFacebookLikeUs && buttonIndex == 1)
    {
        NSString *link = [SystemUtils getSystemInfo:@"kFacebookFansLink"];
        int today = [SystemUtils getTodayDate];
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:today] forKey:@"kFacebookLikeDate"];
        NSString *fbPageID = [SystemUtils getSystemInfo:@"kFacebookPageID"];
        NSURL *fburl = nil;
        if(fbPageID!=nil && [fbPageID length]>3) {
            fburl = [NSURL URLWithString:[NSString stringWithFormat:@"fb://profile/%@",fbPageID]];
        }
        if(fburl!=nil && [[UIApplication sharedApplication] canOpenURL:fburl]) {
            [[UIApplication sharedApplication] openURL:fburl];
        }
        else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
        }
    }
    if (tagAlert == kTagAlertForceUpdate) {
        NSString *link = [SystemUtils getGlobalSetting:@"kForceUpdateLink"];
        if(!link || [link length]<10) 
            link = [SystemUtils getAppDownloadLink];
		if(link) {
			SNSLog(@"%s: %@", __func__, link);
            // [SystemUtils openAppLink:link];
			NSURL *url = [NSURL URLWithString:link];
			[[UIApplication sharedApplication] openURL:url];
		}
		[self onApplicationGoesBackground];
		// [self applicationWillTerminate:[UIApplication sharedApplication]];
		exit(0);
    }
	if (tagAlert == kTagAlertViewDownloadApp && buttonIndex == 1)
	{
		NSString *link = [SystemUtils getAppDownloadLink];
		if(link) {
			SNSLog(@"%s: %@", __func__, link);
			[SystemUtils openAppLink:link];
		}
	}
	if (tagAlert == kTagAlertReloadLanguage && buttonIndex == 1)
	{
		[self onApplicationGoesBackground];
		// [self applicationWillTerminate:[UIApplication sharedApplication]];
		exit(0);
	}
	if (tagAlert == kTagAlertCrashDetected)
	{
		if(buttonIndex == 1) {
			[[NSNotificationCenter defaultCenter] addObserver:self 
													 selector:@selector(onComposeEmailFinished:) 
														 name:kNotificationComposeEmailFinish
													   object:nil];
			
			
			[SystemUtils writeEmailToSupport];
		}
		else {
			[self startLoadGame];
		}
	}
	if (tagAlert == kTagAlertAppealForBlock)
	{
		if(buttonIndex == 1) {
			[[NSNotificationCenter defaultCenter] addObserver:self 
													 selector:@selector(onComposeAppealEmailFinished:) 
														 name:kNotificationComposeEmailFinish
													   object:nil];
			
			
			[SystemUtils writeEmailToSupport];
		}
		else {
            [self onApplicationGoesBackground];
            // [self applicationWillTerminate:[UIApplication sharedApplication]];
            exit(0);
		}
	}
    
    if(tagAlert == kTagAlertInvalidTransaction) {
        if(buttonIndex==1) {
            NSString *info = [SystemUtils getNSDefaultObject:@"kSnsPayVerifyResult"];
            NSString *emailText = [NSString stringWithFormat:@"Transaction Verification failed, please check again:\n%@", info];
            [SystemUtils setNSDefaultObject:emailText forKey:@"kSupportEmailAttachment"];
            [SystemUtils writeEmailToSupport];
        }
        [SystemUtils setNSDefaultObject:@"" forKey:@"kSnsPayVerifyResult"];
    }
    
    if(tagAlert == kTagAlertResetGameData && buttonIndex==1)
    {
        [SystemUtils showInGameLoadingView];
		SyncQueue* syncQueue = [SyncQueue syncQueue];
		
		SNSGameResetOperation* saveOp = [[SNSGameResetOperation alloc] initWithManager:syncQueue andDelegate:nil];
		[syncQueue.operations addOperation:saveOp];
		[saveOp release];
    }
    if(tagAlert == kTagAlertSwitchAccountConfirm) {
        if(buttonIndex==1) {
            // switch account
            NSString *uid = [NSString stringWithFormat:@"%d",newUID];
            [SystemUtils setCurrentUID:uid];
            [SystemUtils showSwitchAccountHint];
            [SystemUtils clearSessionKey];
        } else {
            // reset status
            oldUID = 0; newUID = 0;
        }
    }
        
    if(tagAlert == kTagAlertResetGameDataOK)
    {
        [self onApplicationGoesBackground];
        // [self applicationWillTerminate:[UIApplication sharedApplication]];
        exit(0);
    }
    
    if(tagAlert == kTagAlertInvalidEmailSetting) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationComposeEmailFinish object:nil userInfo:nil];
    }
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	SNSLog(@"%s", __func__);
	[SystemUtils decAlertViewCount];
	
    [self onAlertViewFinished:alertView.tag withButtonIndex:buttonIndex];
}

#pragma mark -

#pragma mark SNSAlertViewDelegate
- (void)snsAlertView:(SNSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self onAlertViewFinished:alertView.tag withButtonIndex:buttonIndex];
}

#pragma mark -


#pragma mark InAppStoreDelegate

// 交易完成通知，应该在这里关闭等候界面
// info中包含两个字段:
// itemId : NSString, 购买的产品ID
// amount : NSNumber, 购买数量
-(void) transactionFinished:(NSDictionary *)info
{
	[SystemUtils hideInGameLoadingView];
    
}

// 交易取消通知，应该在这里关闭等候界面
-(void) transactionCancelled
{
	SNSLog(@"%s", __func__);
	[SystemUtils hideInGameLoadingView];
}

#pragma mark -

#pragma mark SKStoreProductViewControllerDelegate
-(void) showAppStoreView:(NSString *)appID  withLink:(NSString *)link
{
    if([[SystemUtils getiOSVersion] compare:@"6.0"]>=0 && [SKStoreProductViewController class])
    {
    SKStoreProductViewController *storeController = [[SKStoreProductViewController alloc] init];
    storeController.delegate = self; // productViewControllerDidFinish
    // Example app_store_id (e.g. for Words With Friends)
    // [NSNumber numberWithInt:322852954];
    [link retain];
    [SystemUtils showInGameLoadingView];
    NSDictionary *productParameters = @{ SKStoreProductParameterITunesItemIdentifier : appID };
    
    
    [storeController loadProductWithParameters:productParameters completionBlock:^(BOOL result, NSError *error) {
        [SystemUtils hideInGameLoadingView];
        if (result) {
            [[SystemUtils getAbsoluteRootViewController] presentViewController:storeController animated:YES completion:^(void){}];
        } else {
            [storeController release];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
        }
        [link release];
    }];
    }
    else
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [[SystemUtils getAbsoluteRootViewController] dismissModalViewControllerAnimated:NO];
    [viewController release];
}

#pragma mark -

// 删除服务器上的存档
- (void) resetSaveDataOnServer
{
    SNSAlertView *av = [[SNSAlertView alloc]
                        initWithTitle:[SystemUtils getLocalizedString: @"Reset Game Data Confirm"]
                        message:[SystemUtils getLocalizedString: @"Do you really want to reset the save data and start playing this game as a new player?"]
                        delegate:self
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"No"]
                        otherButtonTitle:[SystemUtils getLocalizedString:@"Yes"], nil];
    
    av.tag = kTagAlertResetGameData;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
}
// facebook 账号绑定
- (void) loginWithFacebookAccount
{
    // TODO: login with facebook account
}

// 设置URL礼物
- (void) setFacebookURLGift:(NSString *)gift
{
    if(pendingURLGift) [pendingURLGift release];
    pendingURLGift = [gift retain];
}

- (void) showSwitchAccountAlert
{
    // gcUID = newUID;
    NSString *fmt = [SystemUtils getLocalizedString:@"Are you sure to switch to another account (UID:%d)?"];
    NSString *mesg = [NSString stringWithFormat:fmt, newUID];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Account Change Notice"]
                              message:mesg
                              delegate:self
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"Cancel"]
                              otherButtonTitles:[SystemUtils getLocalizedString:@"OK"],nil];
    
    alertView.tag = kTagAlertSwitchAccountConfirm;
    [alertView show];
    [alertView release];
}

- (void) sendNoticePrize:(NSDictionary *)noticeInfo
{
    // send notice prize
    // {"gid":123,"coin":100,"hint":"here is 100 coins.","leaf":0,"items":""}
    int prizeCoin = [[noticeInfo objectForKey:@"prizeGold"] intValue];
    int prizeLeaf = [[noticeInfo objectForKey:@"prizeLeaf"] intValue];
    NSString *prizeItem = [noticeInfo objectForKey:@"prizeItem"];
    if(prizeItem==nil) prizeItem = @"";
    NSString *mesg = [noticeInfo objectForKey:@"prizeMesg"];
    if(mesg==nil || [mesg length]<3) mesg =[SystemUtils getLocalizedString:@"Great! You finished an install task and just received the bonus."];
    NSDictionary *gift = @{
                           @"coin":[NSNumber numberWithInt:prizeCoin],
                           @"leaf":[NSNumber numberWithInt:prizeLeaf],
                           @"items":prizeItem,
                           @"hint":mesg
                           };
    [SystemUtils showGMPrize:gift];
}

// 检查安装奖励任务是否完成
- (void) checkInstallTaskPrize
{
    NSString *prizeList = [SystemUtils getNSDefaultObject:@"pendingInstallPrize"];
    if(prizeList==nil || [prizeList length]==0) return;
    NSArray *arr = [prizeList componentsSeparatedByString:@","];
    prizeList = nil;
    for (NSString *idStr in arr) {
        int noticeID = [idStr intValue];
        NSString *noticeKey = [NSString stringWithFormat:@"prizeNotice-%@",idStr];
        NSDictionary *noticeInfo = [SystemUtils getNSDefaultObject:noticeKey];
        if(noticeID==0 || noticeInfo==nil || ![noticeInfo isKindOfClass:[NSDictionary class]]) continue;
        
        NSString *urlScheme = [noticeInfo objectForKey:@"urlScheme"];
        if(urlScheme==nil || [urlScheme length]==0) continue;
        
        if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlScheme]])
        {
            // 安装任务完成，发放奖励
            [self sendNoticePrize:noticeInfo];
            [SystemUtils setNSDefaultObject:nil forKey:noticeKey];
            continue;
        }
        if(prizeList==nil) prizeList = idStr;
        else prizeList = [prizeList stringByAppendingFormat:@",%@",idStr];
    }
    
    [SystemUtils setNSDefaultObject:prizeList forKey:@"pendingInstallPrize"];
    
}

// 显示邮件连接奖励
- (void) showEmailLinkPrize
{
    if(newUID>0 && oldUID>0) {
        int curUID = [[SystemUtils getCurrentUID] intValue];
        if(curUID==oldUID) [self showSwitchAccountAlert];
        return;
    }
    // 处理通知里带的奖励
    if(m_launchOptions!=nil) {
        
        NSDictionary *userInfo = nil;
        UILocalNotification *note = [m_launchOptions objectForKey: UIApplicationLaunchOptionsLocalNotificationKey];
        if(note!=nil) userInfo = note.userInfo;
        NSDictionary *info = [m_launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if(info!=nil) userInfo = info;
        
        if(userInfo!=nil) {
            [SystemUtils showCustomNotice:userInfo];
        }
        
        [m_launchOptions release]; m_launchOptions = nil;
    }
    // 检查奖励任务是否达成
    [self checkCrossPromoCondition];
    // 检查安装奖励
    [self checkInstallTaskPrize];
    // 检查条件奖励
    [self checkCrossPromoTaskPrize];
    
    if(pendingURLGift==nil) return;
    // 处理邮件奖励礼物
    NSDictionary *giftInfo = [StringUtils convertJSONStringToObject:pendingURLGift];
    [pendingURLGift release]; pendingURLGift = nil;
    if(giftInfo==nil || ![giftInfo isKindOfClass:[NSDictionary class]]) return;
    
    if([giftInfo objectForKey:@"from_uid"]) {
        // 这是用户之间互相发的礼物
        NSString *from_uid = [giftInfo objectForKey:@"from_uid"];
        if([from_uid integerValue]<=0 || [from_uid isEqualToString:[SystemUtils getCurrentUID]]) {
            SNSLog(@"You can't accept gift from yourself.");
            return;
        }
        // 重新组装礼物格式
        // $giftInfo = array('uid'=>$_GET['uid'], 'udid'=>$_GET['udid'], 'gift_id'=>time(), 'coin'=>10000,'leaf'=>1, 'exp'=>'1000', 'hint'=>'Here\'s 10000 coins for you!',  'items'=>'', 'level'=>1);
        // coin,leaf,exp,hint,items
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
        [dict setObject:[giftInfo objectForKey:@"hint"] forKey:@"hint"];
        [dict setObject:@"0" forKey:@"coin"];
        [dict setObject:@"0" forKey:@"leaf"];
        [dict setObject:@"0" forKey:@"exp"];
        [dict setObject:@"" forKey:@"items"];
        [dict setObject:[giftInfo objectForKey:@"gid"] forKey:@"gid"];
        
        int type = [[giftInfo objectForKey:@"type"] intValue];
        NSString *count = [giftInfo objectForKey:@"count"];
        if(type==1) [dict setObject:count forKey:@"coin"];
        else if(type==2) {
            // no gems
            // [dict setObject:count forKey:@"leaf"];
        }
        else if(type==3) [dict setObject:count forKey:@"exp"];
        else {
            NSString *items = [NSString stringWithFormat:@"%d:%@",type, count];
            [dict setObject:items forKey:@"items"];
            [dict setObject:@"1" forKey:@"coin"];
        }
        giftInfo = dict;
        SNSLog(@"giftInfo:%@",giftInfo);
    }
    else {
        // 来自GM的礼物, {"gid":123,"coin":100,"hint":"here is 100 coins.","udid":"public"}
        // verify uid
        NSString *uid = [giftInfo objectForKey:@"uid"]; int uidInt = [uid intValue];
        BOOL uidValid = NO; BOOL isPublic = NO;
        if(uidInt==0 || [uid isEqualToString:[SystemUtils getCurrentUID]]) uidValid = YES;
        else {
            SNSLog(@"Invalid UID:%@ me:%@", uid, [SystemUtils getCurrentUID]);
            return;
        }
        NSString *udid = [giftInfo objectForKey:@"udid"];
        if([udid isEqualToString:@"public"]) isPublic = YES;
        // verify udid
        if(uidValid && uidInt==0 && !isPublic) {
            NSString *hmac = [SystemUtils getMACAddress];
            NSString *idfv = [SystemUtils getIDFV];
            NSString *idfa = [SystemUtils getIDFA];
            if(udid==nil || [udid length]==0 || !([udid isEqualToString:hmac] || [udid isEqualToString:idfv] || [udid isEqualToString:idfa])) {
                // invalid udid
                SNSLog(@"Invalid UDID:%@", udid);
                return;
            }
        }
    }

    [giftInfo retain];
    [SystemUtils showGMPrize:giftInfo];
    [giftInfo release];
}

#pragma mark prizeTask
// 检查奖励任务是否达成
- (void) checkCrossPromoCondition
{
    NSArray *arr = [SystemUtils getNSDefaultObject:@"kCrossPromoCond"];
    NSMutableArray *condList = [NSMutableArray array];
    if(arr!=nil) [condList addObjectsFromArray:arr];
    BOOL modified = NO;
    if(pendingCrossPromoTask!=nil) {
        [condList addObject:pendingCrossPromoTask];
        [pendingCrossPromoTask release];
        pendingCrossPromoTask = nil; modified = YES;
    }
    
    if([condList count]>0) {
        NSMutableArray *arr2 = [NSMutableArray array];
        for (NSDictionary *dict in condList) {
            NSString *prizeCond = [dict objectForKey:@"prizeCond"];
            if(prizeCond==nil || [prizeCond length]==0) {
                modified = YES;
                continue;
            }
            arr = [prizeCond componentsSeparatedByString:@":"];
            if([arr count]<2) {
                modified = YES; continue;
            }
            int type = [[arr objectAtIndex:0] intValue];
            int count = [[arr objectAtIndex:1] intValue];
            NSString *str = [arr objectAtIndex:0];
            if([str isEqualToString:@"level"]) type = 4;
            if(type<=0 || count<=0) {
                modified = YES; continue;
            }
            if([[SystemUtils getGameDataDelegate] getGameResourceOfType:type]>=count)
            {
                // 条件达到了，更新状态
                [self performSelectorInBackground:@selector(updateCrossPromoTaskStatus:) withObject:dict];
            }
            [arr2 addObject:dict];
        }
        condList = arr2;
    }
    
    if(modified) {
        if([condList count]==0) [SystemUtils setNSDefaultObject:nil forKey:@"kCrossPromoCond"];
        else [SystemUtils setNSDefaultObject:condList forKey:@"kCrossPromoCond"];
    }
}

- (void) finishCrossPromoCond:(NSDictionary *)taskInfo
{
    NSArray *arr = [SystemUtils getNSDefaultObject:@"kCrossPromoCond"];
    if(arr==nil) return;
    NSMutableArray *condList = [NSMutableArray arrayWithArray:arr];
    [condList removeObject:taskInfo];
    if([condList count]==0) condList = nil;
    [SystemUtils setNSDefaultObject:condList forKey:@"kCrossPromoCond"];
}

// 任务达成，更新服务器端完成状态
- (void) updateCrossPromoTaskStatus:(NSDictionary *)taskInfo
{
    @autoreleasepool {
        
        NSString *root = [SystemUtils getSystemInfo:@"kTopgameServiceRoot"];
        NSString *link  = [root stringByAppendingString:@"prizeTask.php"];
        NSURL *url = [NSURL URLWithString:link];
        
        NSString *appID = [taskInfo objectForKey:@"appID"];
        NSString *noticeID = [taskInfo objectForKey:@"noticeID"];
        NSString *userID = [taskInfo objectForKey:@"userID"];
        int time = [SystemUtils getCurrentTime];
        NSString *sig = [self hashCrossPromoParams:[NSString stringWithFormat:@"%@-%@-%@-%d", appID, noticeID, userID, time]];
        
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
        [request setRequestMethod:@"POST"];
        [request addPostValue:appID forKey:@"appID"];
        [request addPostValue:noticeID forKey:@"noticeID"];
        [request addPostValue:userID forKey:@"userID"];
        [request addPostValue:@"create" forKey:@"action"];
        [request addPostValue:[NSString stringWithFormat:@"%d",time] forKey:@"time"];
        [request addPostValue:sig forKey:@"sig"];
        
        [request setTimeOutSeconds:10.0f];
        [request buildPostBody];
#ifdef DEBUG
        
        NSLog(@"%s: url:%@\npost len:%i data: %s", __func__, link, [request postBody].length, [request postBody].bytes);
#endif
        [request startSynchronous];
#ifdef DEBUG
        NSLog(@"%s: response: %@",__func__, [request responseString]);
#endif
        NSDictionary *resp =[StringUtils convertJSONStringToObject:[request responseString]];
        if(resp && [resp isKindOfClass:[NSDictionary class]])
        {
            if([[resp objectForKey:@"status"] intValue]==1) {
                // update ok
                [self finishCrossPromoCond:taskInfo];
            }
        }
    }
}

// 检查带条件的奖励任务是否完成
- (void) checkCrossPromoTaskPrize
{
    NSString *pendingTask = [SystemUtils getNSDefaultObject:@"kCrossPromoTask"];
    if(pendingTask==nil || [pendingTask length]==0) return;
    
    NSArray *arr = [pendingTask componentsSeparatedByString:@","];
    pendingTask = nil;
    for (NSString *str in arr) {
        [self performSelectorInBackground:@selector(checkCrossPromoTaskStatus:) withObject:str];
    }
    
    // [SystemUtils setNSDefaultObject:pendingTask forKey:@"kCrossPromoTask"];

}

- (void) finishCrossPromoTask:(NSString *)taskID
{
    NSArray *arr = [taskID componentsSeparatedByString:@"-"];

    if([arr count]<2) return;
    NSString *noticeID = [arr objectAtIndex:0];
    NSString *userID = [arr objectAtIndex:1];
    NSString *noticeKey = [NSString stringWithFormat:@"prizeNotice-%@",noticeID];
    NSDictionary *noticeInfo = [SystemUtils getNSDefaultObject:noticeKey];
    if(noticeInfo==nil || ![noticeInfo isKindOfClass:[NSDictionary class]]) return;
    
    // send prize
    [self sendNoticePrize:noticeInfo];

    [SystemUtils setNSDefaultObject:nil forKey:noticeKey];
    NSString *pendingTask = [SystemUtils getNSDefaultObject:@"kCrossPromoTask"];
    if(pendingTask==nil || [pendingTask length]==0) return;
    
    NSArray *arr1 = [pendingTask componentsSeparatedByString:@","];
    pendingTask = nil;
    for (NSString *str in arr1) {
        if([str isEqualToString:taskID]) continue;
        if(pendingTask==nil) pendingTask = str;
        else pendingTask = [pendingTask stringByAppendingFormat:@",%@",str];
    }
    
    [SystemUtils setNSDefaultObject:pendingTask forKey:@"kCrossPromoTask"];

}

// 任务达成，更新服务器端完成状态
- (void) checkCrossPromoTaskStatus:(NSString *)taskID
{
    @autoreleasepool {
        
        NSArray *arr = [taskID componentsSeparatedByString:@"-"];
        if([arr count]<2) return;
        
        NSString *root = [SystemUtils getSystemInfo:@"kTopgameServiceRoot"];
        NSString *link  = [root stringByAppendingString:@"prizeTask.php"];
        NSURL *url = [NSURL URLWithString:link];
        
        NSString *appID = [SystemUtils getSystemInfo:@"kFlurryCallbackAppID"];
        NSString *noticeID = [arr objectAtIndex:0];
        NSString *userID = [arr objectAtIndex:1];
        int time = [SystemUtils getCurrentTime];
        NSString *sig = [self hashCrossPromoParams:[NSString stringWithFormat:@"%@-%@-%@-%d", appID, noticeID, userID, time]];
        
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
        [request setRequestMethod:@"POST"];
        [request addPostValue:appID forKey:@"appID"];
        [request addPostValue:noticeID forKey:@"noticeID"];
        [request addPostValue:userID forKey:@"userID"];
        [request addPostValue:@"check" forKey:@"action"];
        [request addPostValue:[NSString stringWithFormat:@"%d",time] forKey:@"time"];
        [request addPostValue:sig forKey:@"sig"];
        
        [request setTimeOutSeconds:10.0f];
        [request buildPostBody];
#ifdef DEBUG
        
        NSLog(@"%s: url:%@\npost len:%i data: %s", __func__, link, [request postBody].length, [request postBody].bytes);
#endif
        [request startSynchronous];
#ifdef DEBUG
        NSLog(@"%s: response: %@",__func__, [request responseString]);
#endif
        NSDictionary *resp =[StringUtils convertJSONStringToObject:[request responseString]];
        if(resp && [resp isKindOfClass:[NSDictionary class]])
        {
            if([[resp objectForKey:@"status"] intValue]==1) {
                // task finished, send prize
                [self performSelectorOnMainThread:@selector(finishCrossPromoTask:) withObject:taskID waitUntilDone:NO];
            }
        }
    }
}

- (NSString *) hashCrossPromoParams:(NSString *)param
{
    return [StringUtils stringByHashingStringWithMD5:[NSString stringWithFormat:@"%@-scis3470345j7234", [StringUtils stringByHashingStringWithMD5:param]]];
}

- (void) startCrossPromoTask:(NSDictionary *)noticeInfo
{
    NSString *urlScheme = [noticeInfo objectForKey:@"urlScheme"];
    if(urlScheme==nil) return;
    NSRange r = [urlScheme rangeOfString:@"://"];
    if (r.location==NSNotFound) {
        urlScheme = [urlScheme stringByAppendingString:@"://"];
    }
    NSString *appID = [SystemUtils getSystemInfo:@"kFlurryCallbackAppID"];
    NSString *noticeID = [noticeInfo objectForKey:@"id"];
    NSString *userID = [SystemUtils getCurrentUID];
    NSString *prizeCond = [noticeInfo objectForKey:@"prizeCond"];
    NSString *sig = [self hashCrossPromoParams:[NSString stringWithFormat:@"%@-%@-%@-%@",appID, noticeID, userID, prizeCond]];
    urlScheme = [urlScheme stringByAppendingFormat:@"crossPromo?appID=%@&noticeID=%@&userID=%@&sig=%@&cond=%@", appID, noticeID, userID, sig, [StringUtils stringByUrlEncodingString:prizeCond]];
    SNSLog(@"urlScheme:%@",urlScheme);
    
    NSURL *url = [NSURL URLWithString:urlScheme];
    if(![[UIApplication sharedApplication] canOpenURL:url]) return;
    NSString *pendingTask = [SystemUtils getNSDefaultObject:@"kCrossPromoTask"];
    if(pendingTask==nil || [pendingTask length]==0) pendingTask = [NSString stringWithFormat:@"%@-%@",noticeID, userID];
    else pendingTask = [pendingTask stringByAppendingFormat:@",%@-%@",noticeID, userID];
    [SystemUtils setNSDefaultObject:pendingTask forKey:@"kCrossPromoTask"];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark -

#ifdef DEBUG
- (void) showFilesOfPath:(NSString *)path
{
    NSString *dir = path;
    // NSMutableSet *contents = [[[NSMutableSet alloc] init] autorelease];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    if (dir && ([fm fileExistsAtPath:dir isDirectory:&isDir] && isDir))
    {
        if (![dir hasSuffix:@"/"]) 
        {
            dir = [dir stringByAppendingString:@"/"];
        }
        
        // this walks the |dir| recurisively and adds the paths to the |contents| set
        NSDirectoryEnumerator *de = [fm enumeratorAtPath:dir];
        NSString *f;
        NSString *fqn;
        while ((f = [de nextObject]))
        {
            // make the filename |f| a fully qualifed filename
            fqn = [dir stringByAppendingString:f];
            if ([fm fileExistsAtPath:fqn isDirectory:&isDir] && isDir)
            {
                // append a / to the end of all directory entries
                // fqn = [fqn stringByAppendingString:@"/"];
                NSLog(@"--- files in %@ ---", f);
                [self showFilesOfPath:fqn];
                NSLog(@"--- end %@ ---", f);
            }
            else {
                NSDictionary *info = [fm attributesOfItemAtPath:fqn error:nil];
                NSLog(@"%@: %llu", f, [info fileSize]);
            }
            // [contents addObject:fqn];
        }
        
    }
}
#endif

@end
