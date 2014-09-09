//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "AarkiHelper.h"
#import "SystemUtils.h"
#import "AarkiContact.h"
#import "AarkiOfferLoader.h"
#import "StringUtils.h"
#import "ASIFormDataRequest.h"
#import "smPopupWindowNotice.h"
#import "smPopupWindowQueue.h"
#import "SBJson.h"

@implementation AarkiHelper

static AarkiHelper *_gAarkiHelper = nil;

+ (AarkiHelper *) helper
{
    if(!_gAarkiHelper) {
        _gAarkiHelper = [[AarkiHelper alloc] init];
    }
    return _gAarkiHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO; offerLoader = nil; popupPlacementID = nil;
        req = nil; arrayInfo = nil;
    }
    return self;
}

- (void) initSession
{
    if(isInitialized) return;
    
    NSString *appID = [SystemUtils getGlobalSetting:@"kAarkiAppID"];
    NSString *appKey = [SystemUtils getGlobalSetting:@"kAarkiAppKey"];
    NSString *placeID = [SystemUtils getGlobalSetting:@"kAarkiPlacementID"];
    if(appID==nil || [appID length]<3) {
        appID = [SystemUtils getSystemInfo:@"kAarkiAppID"];
        appKey = [SystemUtils getSystemInfo:@"kAarkiAppKey"];
        placeID = [SystemUtils getSystemInfo:@"kAarkiPlacementID"];
    }
    if(appID==nil || [appID length]<3) return;
    
    popupPlacementID = [placeID retain];
    
    [AarkiContact registerApp:appID withClientSecurityKey:appKey];
    
    NSString *uid = [NSString stringWithFormat:@"%@-%@",[SystemUtils getOriginalCountryCode], [SystemUtils getCurrentUID]];
    [AarkiContact setUserId:uid];
    SNSLog(@"Loading Offer Manager v. %@.", [AarkiContact libraryVersion]);
    offerLoader = [[AarkiOfferLoader alloc] init];
    isInitialized = YES;

    [self getRewardsLazy];
}

- (void) showVideoOffer
{
    if(!isInitialized)
        [self initSession];
    
    if(!isInitialized) return;
    
    UIViewController *root = [SystemUtils getRootViewController];
    if(root==nil) root = [SystemUtils getAbsoluteRootViewController];
    // [ALInterstitialAd showOver:root.view.window];
    [offerLoader showFullScreenAd:popupPlacementID withParent:root options:nil];
}
- (void) showPopupOffer
{
    if(!isInitialized)
        [self initSession];
    
    if(!isInitialized) return;
    
    UIViewController *root = [SystemUtils getRootViewController];
    if(root==nil) root = [SystemUtils getAbsoluteRootViewController];
    [offerLoader showInterstitialAd:popupPlacementID withParent:root options:nil
                         completion:^(AarkiStatus status) {
                             if (status == AarkiStatusOK) {
                                 SNSLog(@"Ad viewed");
                             } else if (status == AarkiStatusAppNotRegistered) {
                                 SNSLog(@"This app was not registered in Aarki. Call registerApp to set app ID.");
                             } else if (status == AarkiStatusNotAvailable) {
                                 SNSLog(@"Ads not available");
                             }
                             
                             // Insert code to take actions which should be taken after the interstitial was viewed:
                             // proceed to the next level, continue with gameplay, etc.
                         }];
}

- (void) showOfferWall
{
    if(!isInitialized)
        [self initSession];
    
    if(!isInitialized) return;
    
    UIViewController *root = [SystemUtils getRootViewController];
    if(root==nil) root = [SystemUtils getAbsoluteRootViewController];
    // [ALInterstitialAd showOver:root.view.window];
    [offerLoader showAds:popupPlacementID withParent:root options:nil];
}


#pragma mark get rewards

-(void)getRewardsLazy
{
#if 0
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kAarkiShowOfferTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kAarkiCheckTime"] intValue];
    if(checkTime>showTime+1) return;
#endif
    [self getRewards];
    
}

-(void)getRewards
{
    [self initSession];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kAarkiCheckTime"];
	// get rewards
	NSString *api   = [NSString stringWithFormat:@"http://%@/api/", [SystemUtils getFlurryRewardServerName]];
	NSString *appID = [SystemUtils getSystemInfo:kFlurryCallbackAppID];
	NSString *userID = [SystemUtils getCurrentUID];
	NSString *time   = [NSString stringWithFormat:@"%i",[SystemUtils getCurrentTime]];
	NSString *country = [SystemUtils getOriginalCountryCode];
	NSString *digKey  = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", appID, userID, country, kFlurryRewardsSigKey, time];
	NSString *sig = [StringUtils stringByHashingStringWithMD5:digKey];
	api = [api stringByAppendingFormat:@"getAarkiRewards.php?appID=%@&userID=%@&country=%@&time=%@&sig=%@", appID, userID, country, time, sig];
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
    
    int prizeType = [[SystemUtils getGlobalSetting:@"kAarkiPrizeType"] intValue];
    if(prizeType<=0) prizeType = [[SystemUtils getSystemInfo:@"kAarkiPrizeType"] intValue];
    if(prizeType<=0) prizeType = kGameResourceTypeCoin;
    
	for(int i=0;i<[arrayInfo count];i++)
	{
		NSDictionary *info = [arrayInfo objectAtIndex:i];
		// 给用户发奖
		int prizeValue = [[info objectForKey:@"prizeValue"] intValue];
		int prizeCount = [[info objectForKey:@"prizeCount"] intValue];
		if(prizeCount == 0) prizeCount = 1;
		
		NSString *moneyType = @""; NSString *prizeCoin = @"0"; NSString *prizeLeaf = @"0";
		if(prizeType == kGameResourceTypeLeaf) {
            // [SystemUtils addGameResource:prizeValue ofType:kGameResourceTypeLeaf];
            prizeLeaf = [NSString stringWithFormat:@"%d", prizeValue];
			moneyType = [SystemUtils getLocalizedString:@"CoinName2"];
            if(prizeValue>1) moneyType = [StringUtils getPluralFormOfWord:moneyType];
            // [[SnsStatsHelper helper] logResource:kCoinType2 change:prizeValue channelType:kResChannelFlurry];
			// [SystemUtils logFlurryIncome:prizeValue prizeType:kLogTypeEarnLeaf];
		}
		else {
            // [SystemUtils addGameResource:prizeValue ofType:kGameResourceTypeCoin];
            prizeCoin = [NSString stringWithFormat:@"%d", prizeValue];
            moneyType = [SystemUtils getLocalizedString:@"CoinName1"];
            if(prizeValue>1) moneyType = [StringUtils getPluralFormOfWord:moneyType];
			// [SystemUtils logFlurryIncome:prizeValue prizeType:kLogTypeEarnCoin];
            // [[SnsStatsHelper helper] logResource:kCoinType1 change:prizeValue channelType:kResChannelFlurry];
        }
		int amount = prizeValue;
		// 显示获奖通知
		NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], amount, moneyType];
		// show notice
		smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
		swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"content", @"", @"action", prizeCoin, @"prizeCoin", prizeLeaf, @"prizeLeaf", nil];
		[[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:0];
		[swqAlert release];
		// 播放金币声音
		// [[AudioPlayer sharedPlayer] playEffect:kEffect_Coins];
	}
    [arrayInfo release]; arrayInfo = nil;
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
