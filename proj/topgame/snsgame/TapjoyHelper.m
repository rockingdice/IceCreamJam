//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "TapjoyHelper.h"
#import "TapjoyConnect.h"
#import "SystemUtils.h"
#import "smPopupWindowNotice.h"
#import "smPopupWindowQueue.h"
// #import "AudioPlayer.h"
#import "SNSWebWindow.h"
#import "StringUtils.h"
#import "SnsStatsHelper.h"
#ifdef SNS_ENABLE_LIMEI
#import "LiMeiHelper.h"
#endif
#ifdef SNS_ENABLE_APPDRIVER
#import "AppDriverHelper.h"
#endif

static TapjoyHelper *_tapjoyHelper = nil;

@implementation TapjoyHelper

@synthesize isWebModeEnabled;

+(TapjoyHelper *)helper
{
	@synchronized(self) {
		if(!_tapjoyHelper) {
			_tapjoyHelper = [[TapjoyHelper alloc] init];
		}
	}
	return _tapjoyHelper;
}

-(id)init
{
    self = [super init];
    
	NSArray *arr = [SystemUtils getGlobalSetting:kTapjoyPendingActions];
	if(arr) pendingActions = [[NSMutableArray alloc] initWithArray:arr];
	else {
		pendingActions = [[NSMutableArray alloc] init];
	}
	
	isSessionInitialized = NO; isWebModeEnabled = YES;
	
	// A notification method must be set to retrieve the points.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getUpdatedPoints:) name:TJC_TAP_POINTS_RESPONSE_NOTIFICATION object:nil];
	return self;
}

-(void)dealloc
{
	if(pendingActions) [pendingActions release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(void) initTapjoySession
{
	if(isSessionInitialized) return;
	
    isWebModeEnabled = YES;
	NSString *kTapjoyAppID = [SystemUtils getGlobalSetting:kTapjoyAppIDKey];
	NSString *kTapjoySecret = [SystemUtils getGlobalSetting:kTapjoyAppSecretKey];
    
    // 前3次用默认AppID
    int playTimes = [[SystemUtils getNSDefaultObject:kPlayTimes] intValue];
    if(playTimes < 3) {
        kTapjoyAppID = [SystemUtils getSystemInfo:kTapjoyAppIDKey];
        kTapjoySecret = [SystemUtils getSystemInfo:kTapjoyAppSecretKey];
    }
    
    if(!kTapjoyAppID || [kTapjoyAppID length]<10) 
        kTapjoyAppID = [SystemUtils getSystemInfo:kTapjoyAppIDKey];
    if(kTapjoyAppID && ![kTapjoyAppID isEqualToString:[SystemUtils getSystemInfo:kTapjoyAppIDKey]]) {
        isWebModeEnabled = NO;
    }
    if(!kTapjoySecret || [kTapjoySecret length]<10) 
        kTapjoySecret = [SystemUtils getSystemInfo:kTapjoyAppSecretKey];
	if(kTapjoyAppID && kTapjoySecret) {
		SNSLog(@"tapjoy start: %@", kTapjoyAppID);
        [TapjoyConnect disableVideo:YES];
		[TapjoyConnect requestTapjoyConnect:kTapjoyAppID secretKey:kTapjoyAppSecretKey];
		// [TapjoyConnect initVideoAdWithDelegate:self];
		isSessionInitialized = YES;
	}
	[self checkPointsLazy];
}


+ (void) showTapjoyOrLiMeiOffers
{
    NSString *country = [SystemUtils getCountryCode];
    BOOL isChinese = [country isEqualToString:@"CN"] || [country isEqualToString:@"TW"] || [country isEqualToString:@"HK"];
    BOOL isLimeiEnabled = [SystemUtils checkFeature:kFeatureLiMei];
#ifdef SNS_ENABLE_LIMEI
    if(isChinese && isLimeiEnabled) {
        int clickCount = [[SystemUtils getNSDefaultObject:@"kLimeiCount"] intValue];
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:clickCount+1] forKey:@"kLimeiCount"];
#ifdef SNS_ENABLE_APPDRIVER
        if(clickCount%2==1) [[LiMeiHelper helper] showOffers];
        // else if(clickCount%3==1) [[AppDriverHelper helper] showOffer];
        else [TapjoyHelper showOffers];
#else
        if(clickCount%2==1) [[LiMeiHelper helper] showOffers];
        else [TapjoyHelper showOffers];
#endif
    }
    else {
        // tapjoy
        [TapjoyHelper showOffers];
    }
#else
    [TapjoyHelper showOffers];
#endif
    
   
}

+(void)showTapjoyOffers
{
	// [TapjoyConnect showOffersWithViewController:[SystemUtils getRootViewController]];
    [self showOffers];
}

+ (void) showOffers
{
    /*
    if(YES){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.tapjoy.com/"]];
        return;
    }
     */
    
    if(![SystemUtils checkFeature:kFeatureTapjoy]) {
        SNSLog(@"tapjoy is disabled");
        return;
    }
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kTapjoyShowOfferTime"];
    [[TapjoyHelper helper] initTapjoySession];
    
	[TapjoyConnect showOffersWithViewController:[SystemUtils getAbsoluteRootViewController]];
    
}

-(void)checkPointsLazy
{
    /*
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kTapjoyShowOfferTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kTapjoyCheckTime"] intValue];
    if(checkTime>showTime+1) return;
     */
    [self checkTapjoyPoints];
    
}

-(void)checkTapjoyPoints
{
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kTapjoyCheckTime"];
	// This method requests the tapjoy server for current virtual currency of the user.
	[self initTapjoySession];
	[TapjoyConnect getTapPoints];
}

-(void)getUpdatedPoints:(NSNotification*)notifyObj
{
	NSNumber *tapPoints = notifyObj.object;
	int amount = [tapPoints intValue];
    SNSLog(@"get %i points", amount);
	if (amount <= 0) return;
	
    int resType = [[SystemUtils getSystemInfo:@"kTapjoyPrizeType"] intValue];
    if(resType==0) resType = kGameResourceTypeLeaf;
	// [SystemUtils addGameResource:amount ofType:resType];
	[TapjoyConnect spendTapPoints:amount];
	
	// [SystemUtils logTapjoyIncome:amount];
#ifdef kCoinTypeTapjoy
    [[SnsStatsHelper helper] logResource:kCoinTypeTapjoy change:amount channelType:kResChannelTapjoy];
#endif
    NSString *leafName = [SystemUtils getLocalizedString:@"CoinName2"];
    if(amount>1) leafName = [StringUtils getPluralFormOfWord:leafName];
	
	NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], amount, leafName];
	// show notice
	smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
	swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"content", @"", @"action", @"0", @"prizeCoin", [NSNumber numberWithInt:amount], @"prizeLeaf", nil];
	[[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:0];
    [swqAlert release];
	// play sound
	// [[AudioPlayer sharedPlayer] playEffect:kEffect_Coins];
}

// 完成一项任务
-(void) completeAction:(NSString *)action
{
	SNSLog(@"%s", __FUNCTION__);
	[pendingActions addObject:action];
	[self completePendingAction];
	/*
	if([SystemUtils checkFeature:kFeatureTapjoy]) [self completePendingAction];
	else {
		NSLog(@"complete tapjoy action %@",action);
		// save to local info
		// [SystemUtils setGlobalSetting:pendingActions forKey:kTapjoyPendingActions];
		// connect directly
		NSString *key = [SystemUtils getSystemInfo:kTapjoyAppIDKey];
		NSString *secret = [SystemUtils getSystemInfo:kTapjoyAppSecretKey];
		[TapjoyConnect requestTapjoyConnect:key secretKey:secret];
		[TapjoyConnect actionComplete:action];
	}
	 */
}

// 提交等候的任务
- (void) completePendingAction
{
	if(!pendingActions || [pendingActions count]==0) return;
	for(int i=0;i<[pendingActions count];i++)
	{
		[TapjoyConnect actionComplete:[pendingActions objectAtIndex:i]];
	}
	[pendingActions removeAllObjects];
	[SystemUtils removeGlocalSettingForKey:kTapjoyPendingActions];
}


#pragma mark Tapjoy FeaturedApp
// show tapjoy feature app
- (BOOL) startGettingTapjoyFeaturedApp
{
    // NSLog(@"%s", __func__);
    if(![SystemUtils isAdVisible]) return NO;
    
    // check if featuredApp enabled
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    int tapjoyFeaturedAppDisabled = [def integerForKey:@"tapjoyFeaturedAppDisabled"];
    if(tapjoyFeaturedAppDisabled==1) return NO;

    // This method asks the tapjoy server for the fullscreen ad object.
    [TapjoyConnect getFullScreenAd];
    
    // A notification method must be set to retrieve the fullscreen ad object.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getFullScreenAd:)
                                                 name:TJC_FULL_SCREEN_AD_RESPONSE_NOTIFICATION
                                               object:nil];
    
    return YES;
}
- (void) onGetTapjoyFeaturedApp:(NSNotification*)notifyObj
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TJC_FULL_SCREEN_AD_RESPONSE_NOTIFICATION object:nil];
    
    
    // Show the custom Tapjoy full screen featured app ad view.
    if ([SystemUtils getInterruptMode])
    {
        // Display the featured app here. More details below...
        // [TapjoyConnect showFeaturedAppFullScreenAd];
        [TapjoyConnect showFullScreenAd];
    }
}

#pragma mark -

#pragma mark TJCVideoAdDelegate
// Called when the video ad begins playing.
- (void)videoAdBegan
{
    [SystemUtils pauseDirector];
}
// Called when the video ad is closed.
- (void)videoAdClosed
{
    [SystemUtils resumeDirector];
}
#pragma mark -

@end
