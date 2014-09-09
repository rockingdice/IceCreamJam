//
//  FarmManiaAppController.mm
//  FarmMania
//
//  Created by  James Lee on 13-5-1.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Crashlytics/Crashlytics.h>

#import "AppController.h"
#import "cocos2d.h"
#import "EAGLView.h"
#import "AppDelegate.h"

#import "RootViewController.h"


#import "SystemUtils.h"
#import "SnsServerHelper.h"
#ifndef SNS_DISABLE_FLURRY_V1
#import "FlurryHelper.h"
#endif
#import "SnsGameHelper.h"
#ifndef SNS_DISABLE_ADCOLONY
#import "AdColonyHelper.h"
#endif

#import "OBJCHelper.h"
#include "FMDataManager.h"
#include "FMSoundManager.h"
#ifdef BRANCH_JP
#import "PopGameHelper.h"
#endif
#ifdef SNS_ENABLE_MINICLIP
#import <FiksuSDK/FiksuSDK.h>
#endif
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>

#ifdef BRANCH_TH
#import "Adjust.h"
#import "ACTReporter.h"
#endif
#ifdef SNS_ENABLE_ADX
#import "AdxHelper.h"
#endif


@implementation AppController

@synthesize window;
@synthesize viewController;

#pragma mark -
#pragma mark Application lifecycle

// cocos2d application instance
static AppDelegate s_sharedApplication;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Override point for customization after application launch.

    // Add the view controller's view to the window and display.
    window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    EAGLView *__glView = [EAGLView viewWithFrame: [window bounds]
                                     pixelFormat: kEAGLColorFormatRGB565
                                     depthFormat: GL_DEPTH24_STENCIL8_OES
                              preserveBackbuffer: NO
                                      sharegroup: nil
                                   multiSampling: NO
                                 numberOfSamples:0 ];

    // Use RootViewController manage EAGLView
    viewController = [[RootViewController alloc] initWithNibName:nil bundle:nil];
    viewController.wantsFullScreenLayout = YES;
    viewController.view = __glView;

    // Set RootViewController to window
    if ( [[UIDevice currentDevice].systemVersion floatValue] < 6.0)
    {
        // warning: addSubView doesn't work on iOS6
        [window addSubview: viewController.view];
    }
    else
    {
        // use this method on ios6
        [window setRootViewController:viewController];
    }
    
    [window makeKeyAndVisible];
    [Crashlytics startWithAPIKey:@"82c89678e2cc43777b3ea5ca1fdb02942de20542"];

    [[UIApplication sharedApplication] setStatusBarHidden: YES];
    OBJCHelper::helper();

    
    
    // cocos2d::CCDirector *pDirector = cocos2d::CCDirector::sharedDirector();
    // pDirector->setOpenGLView(cocos2d::CCEGLView::sharedOpenGLView());
    
    // enable High Resource Mode(2x, such as iphone4) and maintains low resource on other devices.
    // pDirector->enableRetinaDisplay(true);
    
    // snsgame start
	[SystemUtils systemInfo];
	[SystemUtils config];
	[SystemUtils setRootViewController:viewController];
	
    //first reload all game configs
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onLoadGameConfig:)
												 name:kNotificationReloadGameConfig
											   object:nil];
    
    //then load user data
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onLoadGameData:)
												 name:kNotificationLoadGameData
											   object:nil];
    
    //start game scene at last
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onStartGameScene:)
												 name:kNotificationStartGameScene
											   object:nil];
    
	
	[SnsGameHelper helper];
    [[SnsServerHelper helper] initSession:__glView withLaunchOptions:launchOptions];
	
    // snsgame stop
#ifdef BRANCH_JP
    [[PopGameHelper helper] initSession:launchOptions];
    // [[PopGameHelper helper] performSelectorInBackground:@selector(initSession:) withObject:launchOptions];
#endif
#ifdef SNS_ENABLE_MINICLIP
    if ([self connectedToNetwork]) {
        [FiksuTrackingManager applicationDidFinishLaunching:launchOptions];
    }
#endif
    
#ifdef BRANCH_TH
    [Adjust appDidLaunch:@"z7bfpgq8t9x5"];
#ifdef DEBUG
    [Adjust setLogLevel:AILogLevelInfo];
    [Adjust setEnvironment:AIEnvironmentSandbox];
#else
    [Adjust setLogLevel:AILogLevelAssert];
    [Adjust setEnvironment:AIEnvironmentProduction];
#endif
    
    [ACTConversionReporter reportWithConversionID:@"969964807" label:@"zjyJCKm5pQkQh_rBzgM" value:@"1.000000" isRepeatable:NO];
    
#endif
    OBJCHelper::helper()->trackSessionStart();

#ifdef SNS_ENABLE_ADX
    [[AdxHelper helper] initSession];
#endif

    // cocos2d::CCApplication::sharedApplication()->run();
    return YES;
}

- (BOOL) connectedToNetwork
{
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
	
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
	
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
	
    if (!didRetrieveFlags)
    {
        //printf("Error. Could not recover network reachability flags\n");
        return 0;
    }
	
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    return isReachable;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    cocos2d::CCDirector::sharedDirector()->pause();
    
    OBJCHelper::helper()->postRequest(NULL, NULL, kPostType_SyncData);
    OBJCHelper::helper()->livesRefillNote();
    OBJCHelper::helper()->freeSpinNote();
    // snsgame start
	if(isGameStarted)
		[[SnsServerHelper helper] onApplicationGoesBackground];
    // snsgame stop
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    cocos2d::CCDirector::sharedDirector()->resume();
    int forceQuit = [[SystemUtils getNSDefaultObject:@"kForceQuitOnBgMode"] intValue];
    if(forceQuit==1) {
        [SystemUtils setNSDefaultObject:@"0" forKey:@"kForceQuitOnBgMode"];
    }

    OBJCHelper::helper()->initRequest();
#ifdef BRANCH_CN
    OBJCHelper::helper()->postRequest(NULL, NULL, kPostType_SyncInfo);
#endif
    
#ifdef SNS_ENABLE_ADX
    [[AdxHelper helper] reportAppOpen];
#endif
    // snsgame start
	if(isGameStarted)
		[[SnsServerHelper helper] onApplicationGoesForground];
    // snsgame stop
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    cocos2d::CCApplication::sharedApplication()->applicationDidEnterBackground();
    
    // snsgame start
    int forceQuit = [[SystemUtils getNSDefaultObject:@"kForceQuitOnBgMode"] intValue];
    if(forceQuit==1) {
        SNSLog(@"forceQuit=1, exit now");
        [self applicationWillTerminate:application];
        exit(0);
    }
    // snsgame stop
    [[SnsGameHelper helper] onApplicationGoesToBackground];
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
    cocos2d::CCApplication::sharedApplication()->applicationWillEnterForeground();
    
    [[SnsGameHelper helper] onApplicationResumeFromBackground];
    
    FMDataManager * manager = FMDataManager::sharedManager();
    
    FMSound::setMusicOn(manager->isMusicOn());
    FMSound::setEffectOn(manager->isSFXOn());
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
    OBJCHelper::helper()->trackSessionEnd();

    // snsgame start
	if(notifyInfo) {
		[notifyInfo release]; notifyInfo = nil;
	}
	[SystemUtils cleanUpStaticInfo];
    // snsgame stop
    
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
     cocos2d::CCDirector::sharedDirector()->purgeCachedData();
}


- (void)dealloc {
    [super dealloc];
}




- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    OBJCHelper::helper()->initRequest();
    return [[SnsServerHelper helper] handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
#ifdef SNS_ENABLE_MINICLIP
    if ([[url scheme] hasPrefix:@"aso"])
    {
        return [FiksuTrackingManager handleURL:url sourceApplication:sourceApplication];
    }
#endif
    OBJCHelper::helper()->initRequest();
    return [[SnsServerHelper helper] handleOpenURL:url];
}
// snsgame start
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	[[SnsServerHelper helper] saveDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	UIApplicationState st = application.applicationState;
	if(st == UIApplicationStateInactive) {
		// user tap the notification
	}
	else if(st == UIApplicationStateActive) {
		//
	}
	NSLog(@"%s: receive local notify %@", __FUNCTION__, notification.userInfo);
	if(notification.userInfo) {
		[SystemUtils showCustomNotice:notification.userInfo];
	}
	application.applicationIconBadgeNumber = 0; // notification.applicationIconBadgeNumber-1;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	// receive remote notification when running
	NSLog(@"receive remote notification: %@", userInfo);
	[SystemUtils showCustomNotice:userInfo];
}

// snsgame stop



#pragma mark SNSGAME method
// snsgame start
// 加载配置文件
- (void) onLoadGameConfig:(NSNotification *)note
{
	// load resource files
    [[SnsGameHelper helper] loadIapItemList:YES];
    // CGameData::resetConfigFile();
}

- (void) onLoadGameData:(NSNotification *)note
{
    [[SnsGameHelper helper] loadGameData];
    
    OBJCHelper::helper()->trackLoginSuccess();

#ifndef SNS_DISABLE_FLURRY_V1
    
	// set flurry prize
	// [[FlurryHelper helper] setVideoPrizeGold:[gameData getIAPCoinCount:1]/10];
	[[FlurryHelper helper] setVideoPrizeGold:100];
	[FlurryHelper helper].offerPrizeLeaf = 10;
	[[FlurryHelper helper] setOfferPrizeGold:1000];
#endif
#ifndef SNS_DISABLE_ADCOLONY
	// [[AdColonyHelper helper] setPrizeGold:[gameData getIAPCoinCount:1]*12/100];
	[[AdColonyHelper helper] setPrizeGold:100];
#endif
}

- (void) onStartGameScene:(NSNotification *)note
{
	NSLog(@"%s: isGameStarted:%i", __func__, isGameStarted);
	if(isGameStarted) return;
	isGameStarted = YES;
    
    cocos2d::CCApplication::sharedApplication()->run();
    
    [viewController.view setUserInteractionEnabled:YES];
	NSLog(@"%s:check notify info",__FUNCTION__);
	// give notice prize
	if(notifyInfo)
	{
		NSLog(@"notifyInfo:%@", notifyInfo);
		[SystemUtils showCustomNotice:notifyInfo];
		[notifyInfo release];
		notifyInfo = nil;
	}
	
}

#pragma mark -

@end

