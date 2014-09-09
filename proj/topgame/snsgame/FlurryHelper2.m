//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "FlurryHelper2.h"
#import "SystemUtils.h"
#import "Flurry.h"
#import "FlurryAds.h"
#import "StringUtils.h"
#import "ASIFormDataRequest.h"
#import "SBJson.h"
#import "SnsStatsHelper.h"
#import "smPopupWindowNotice.h"

enum {
	kFlurryPrizeTypeNone = 0,
	kFlurryPrizeTypeGold,
	kFlurryPrizeTypeLeaf,
};

@implementation FlurryHelper2

#define SNS_FLURRY_FULLSCREEN_SPACE  @"MAIN_FULLSCREEN"
#define SNS_FLURRY_FULLSCREEN_SPACE2  @"MAIN_FULLSCREEN2"

static FlurryHelper2 *_gFlurryHelper2 = nil;

+ (FlurryHelper2 *) helper
{
    if(!_gFlurryHelper2) {
        _gFlurryHelper2 = [[FlurryHelper2 alloc] init];
    }
    return _gFlurryHelper2;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO;
        adSpace1 = nil; adSpace2 = nil;
        adSpace1Status = 0; adSpace2Status = 0;
    }
    return self;
}

- (void) dealloc
{
    if(adSpace1!=nil) [adSpace1 release];
    if(adSpace2!=nil) [adSpace2 release];
    [super dealloc];
}

-(NSDictionary *)getAppCookie
{
    NSString *flurryPrizeType = [SystemUtils getSystemInfo:@"kFlurryCoinType"];
    if(flurryPrizeType==nil || [flurryPrizeType length]==0) flurryPrizeType = @"1";
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								[SystemUtils getSystemInfo:kFlurryCallbackAppID], @"appID",
								[SystemUtils getCurrentUID], @"userID",
								flurryPrizeType, @"prizeType",
								[SystemUtils getOriginalCountryCode], @"country", nil];
	return dictionary;
}

- (void) startFlurry
{
    // @autoreleasepool {
	NSString *appID = [SystemUtils getGlobalSetting:kFlurryAppIdKey];
    if(!appID) appID = [SystemUtils getSystemInfo:kFlurryAppIdKey];
	if(!appID) return;
    isInitialized = YES;
    [Flurry startSession:appID];
    root =[SystemUtils getAbsoluteRootViewController];
    if(!root) return;
    [FlurryAds initialize:root];
    
    [FlurryAds setUserCookies:[self getAppCookie]];
    /*
    // 2. Fetch fullscreen ads for later display
	[FlurryAds fetchAdForSpace:SNS_FLURRY_FULLSCREEN_SPACE
                         frame:root.view.frame size:FULLSCREEN];
     */
    
    // Register yourself as a delegate for ad callbacks
	[FlurryAds setAdDelegate:self];
    // fetch an ad
    
    [FlurryAds fetchAdForSpace:adSpace1
                         frame:root.view.frame size:FULLSCREEN];
    [FlurryAds fetchAdForSpace:adSpace2
                         frame:root.view.frame size:FULLSCREEN];
    adSpace1Status = 1; adSpace2Status = 1;
    [self getRewardsLazy];
    // }
}

- (void) initSession
{
    if(isInitialized) return;
    [self loadAdSpace];
    SNSLog(@"start flurry session");
    [self startFlurry];
    // [self performSelectorInBackground:@selector(startFlurry) withObject:nil];
}
- (void) loadAdSpace
{
    NSString *space1 = [SystemUtils getGlobalSetting:@"kFlurryAdSpace1"];
    if(space1==nil || [space1 length]<=1) space1 = SNS_FLURRY_FULLSCREEN_SPACE;
    NSString *space2 = [SystemUtils getGlobalSetting:@"kFlurryAdSpace2"];
    if(space2==nil || [space2 length]<=1) space2 = SNS_FLURRY_FULLSCREEN_SPACE2;
    
    if([adSpace1 isEqualToString:space1] && [adSpace2 isEqualToString:space2]) return;
    if(adSpace1!=nil) [adSpace1 release];
    if(adSpace2!=nil) [adSpace2 release];
    adSpace1 = space1; adSpace2 = space2;
    [adSpace1 retain];
    [adSpace2 retain];
    if(isInitialized) {
        [FlurryAds fetchAdForSpace:adSpace1
                             frame:root.view.frame size:FULLSCREEN];
        [FlurryAds fetchAdForSpace:adSpace2
                             frame:root.view.frame size:FULLSCREEN];
        adSpace1Status = 1; adSpace2Status = 2;
    }
}

- (BOOL) showOfferInternal:(int) type
{
    SNSLog(@"check");
    if(!isInitialized)
        [self initSession];
    if(!root) return NO;
    
    if(![SystemUtils isAdVisible]) {
        SNSLog(@"isAdVisible:NO");
        return NO;
    }
    
    //if(![SystemUtils checkFeature:kFeatureFlurry]) return NO;
    int now = [SystemUtils getCurrentTime];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:now] forKey:@"kFlurryShowOfferTime"];
    // Check if ad is ready. If so, display the ad
    NSString *slot = adSpace1; int status = adSpace1Status;
    if(type==2) {
        slot = adSpace2; status = adSpace2Status;
    }
    if ([FlurryAds adReadyForSpace:slot] || status==2) {
    	[FlurryAds displayAdForSpace:slot
                              onView:root.view];
        SNSLog(@"showOffer of %@", slot);
        return YES;
	} else {
        if(type==1 && adSpace1Status==0) {
            // fetch an ad
            [FlurryAds fetchAdForSpace:slot
                             frame:root.view.frame size:FULLSCREEN];
            adSpace1Status = 1;
            SNSLog(@"fetchOffer of %@", slot);
        }
        if(type==2 && adSpace2Status==0) {
            // fetch an ad
            [FlurryAds fetchAdForSpace:slot
                                 frame:root.view.frame size:FULLSCREEN];
            adSpace2Status = 1;
            SNSLog(@"fetchOffer of %@", slot);
        }
        return NO;
	}
}

- (BOOL) showOffer
{
    return [self showOfferInternal:1];
}
- (BOOL) showOffer2
{
    return [self showOfferInternal:2];
}

#pragma mark FlurryAdDelegate
/*
 *  It is recommended to pause app activities when an interstitial is shown.
 *  Listen to should display delegate.
 */
- (BOOL) spaceShouldDisplay:(NSString*)adSpace interstitial:(BOOL)
interstitial {
    if (interstitial) {
        // Pause app state here
    }
    if(![SystemUtils getInterruptMode]) return NO;
    // Continue ad display
    return YES;
}

/*
 *  Resume app state when the interstitial is dismissed.
 */
- (void)spaceDidDismiss:(NSString *)adSpace interstitial:(BOOL)interstitial {
    if (interstitial) {
        // Resume app state here
    }
    if([adSpace isEqualToString:adSpace1]) adSpace1Status = 1;
    if([adSpace isEqualToString:adSpace2]) adSpace2Status = 1;
    [FlurryAds fetchAdForSpace:adSpace
                         frame:root.view.frame size:FULLSCREEN];
}

- (void) spaceDidReceiveAd:(NSString*)adSpace
{
    if([adSpace isEqualToString:adSpace1]) adSpace1Status = 2;
    if([adSpace isEqualToString:adSpace2]) adSpace2Status = 2;
}

#pragma mark -

#pragma mark get rewards

-(void)getRewardsLazy
{
#if 0
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kFlurryShowOfferTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kFlurryCheckTime"] intValue];
    if(checkTime>showTime+1) return;
#endif
    [self getRewards];
    
}

-(void)getRewards
{
    [self initSession];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kFlurryCheckTime"];
	// get rewards
	NSString *api   = [NSString stringWithFormat:@"http://%@/api/", [SystemUtils getFlurryRewardServerName]];
	NSString *appID = [SystemUtils getSystemInfo:kFlurryCallbackAppID];
	NSString *userID = [SystemUtils getCurrentUID];
	NSString *time   = [NSString stringWithFormat:@"%i",[SystemUtils getCurrentTime]];
	NSString *country = [SystemUtils getOriginalCountryCode];
	NSString *digKey  = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", appID, userID, country, kFlurryRewardsSigKey, time];
	NSString *sig = [StringUtils stringByHashingStringWithMD5:digKey];
	api = [api stringByAppendingFormat:@"getFlurryRewards.php?appID=%@&userID=%@&country=%@&time=%@&sig=%@", appID, userID, country, time, sig];
	SNSLog(@"%s api:%@", __FUNCTION__, api);
	NSURL *url = [NSURL URLWithString:api];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"GET"];
	[request setDelegate:self];
	[request startAsynchronous];
	req = [request retain];
}

- (void)loadDone
{
	if(req) {
		[req release]; req = nil;
	}
    
	for(int i=0;i<[arrayInfo count];i++)
	{
		NSDictionary *info = [arrayInfo objectAtIndex:i];
		// 给用户发奖
		int prizeType = [[info objectForKey:@"prizeType"] intValue];
		int prizeValue = [[info objectForKey:@"prizeValue"] intValue];
		int prizeCount = [[info objectForKey:@"prizeCount"] intValue];
		if(prizeCount == 0) prizeCount = 1;
		
		NSString *moneyType = @"";
		if(prizeType == kFlurryPrizeTypeLeaf) {
            [SystemUtils addGameResource:prizeValue ofType:kGameResourceTypeLeaf];
			moneyType = [SystemUtils getLocalizedString:@"CoinName2"];
            if(prizeValue>1) moneyType = [StringUtils getPluralFormOfWord:moneyType];
            [[SnsStatsHelper helper] logResource:kCoinType2 change:prizeValue channelType:kResChannelFlurry];
			// [SystemUtils logFlurryIncome:prizeValue prizeType:kLogTypeEarnLeaf];
		}
		else {
            [SystemUtils addGameResource:prizeValue ofType:kGameResourceTypeCoin];
            moneyType = [SystemUtils getLocalizedString:@"CoinName1"];
            if(prizeValue>1) moneyType = [StringUtils getPluralFormOfWord:moneyType];
			// [SystemUtils logFlurryIncome:prizeValue prizeType:kLogTypeEarnCoin];
            [[SnsStatsHelper helper] logResource:kCoinType1 change:prizeValue channelType:kResChannelFlurry];
        }
		int amount = prizeValue;
		// 显示获奖通知
		NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], amount, moneyType];
		// show notice
		smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
		swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"content", @"", @"action", @"0", @"prizeCoin", @"0", @"prizeLeaf", nil];
		[[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:0];
		[swqAlert release];
		// 播放金币声音
		// [[AudioPlayer sharedPlayer] playEffect:kEffect_Coins];
	}
}

- (void)loadCancel
{
	// cancel load
	if(req) {
		[req release]; req = nil;
	}
}


#pragma mark ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
	SNSLog(@"%s status code:%i",__FUNCTION__, request.responseStatusCode);
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		[self loadCancel];
		return;
	}
	SNSLog(@"%s response:%@", __FUNCTION__, [request responseString]);
	// NSString *response = [request responseString];
	NSData *jsonData = [request responseData];
	if(!jsonData || [jsonData length]==0) {
		[self loadCancel];
		return;
	}
	// [request responseData];
	// NSString *jsonString = @"yourJSONHere";
	// NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	// NSError *error = nil;
	NSString *jsonString = [[NSString alloc] initWithBytes:jsonData.bytes length:jsonData.length encoding:NSUTF8StringEncoding];
	[jsonString autorelease];
	NSArray *arr = [jsonString JSONValue];
	if(!arr || ![arr isKindOfClass:[NSArray class]]) {
		SNSLog(@"deserializer result:%@", arr);
		[self loadCancel];
		return;
	}
	if(arrayInfo) [arrayInfo release];
	arrayInfo = [arr retain];
	// xuke,zhizhao zhenfu,daima zheng, a4
	[self loadDone];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	SNSLog(@"%s - error: %@", __FUNCTION__, error);
	[self loadCancel];
}

#pragma mark -


@end
