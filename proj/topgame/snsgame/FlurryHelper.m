//
//  FlurryUtils.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import "SNSLogType.h"
#import "FlurryHelper.h"
#import "FlurryAnalytics.h"
#import "FlurryAppCircle.h"
#import "FlurryClips.h"
#import "FlurryOffer.h"
#import "SBJson.h"
#import "SystemUtils.h"
#import "StringUtils.h"
#import "ASIFormDataRequest.h"
#import "smPopupWindowFlurryOffer.h"
#import "smPopupWindowQueue.h"
#import "NetworkHelper.h"
#import "smPopupWindowNotice.h"
#import "SNSAlertView.h"
#import "SnsStatsHelper.h"

enum {
	kFlurryPrizeTypeNone = 0,
	kFlurryPrizeTypeGold,
	kFlurryPrizeTypeLeaf,
};

#define kFlurryRecommendationHookName @"RecommendationHook"

static FlurryHelper *_flurryHelper = nil;

@implementation FlurryHelper

@synthesize clickedAppNames, isFlurrySessionStart;
@synthesize isShowingOffer, isShowingVideo, videoPrizeGold, offerPrizeType, offerPrizeGold, offerPrizeLeaf;

+(FlurryHelper *)helper
{
	@synchronized(self) {
		if(!_flurryHelper) {
			_flurryHelper = [[FlurryHelper alloc] init];
		}
	}
	return _flurryHelper;
}

-(id)init
{
	self = [super init];
	clickedAppNames = [[NSMutableDictionary alloc] init];
	
	isFlurrySessionStart = NO;
	isShowingOffer = NO; isShowingVideo = NO;
	videoPrizeGold = 100; offerPrizeType = 0; offerPrizeLeaf = 10; offerPrizeGold = 1000;
	// [self initFlurrySession];
	
	return self;
}

// init flurry session
-(void)initFlurrySession
{
	if(isFlurrySessionStart) return;
	// init flurry
	NSString *kFlurryKey = [SystemUtils getGlobalSetting:kFlurryAppIdKey];
    if(!kFlurryKey || [kFlurryKey length]<5)
        kFlurryKey = [SystemUtils getSystemInfo:kFlurryAppIdKey];
	if(kFlurryKey) {
		NSLog(@"flurry start: %@", kFlurryKey);
		[FlurryAppCircle setAppCircleEnabled:YES];
#ifndef SNS_DISABLE_FLURRY_VIDEO
		[FlurryClips setVideoAdsEnabled:YES];
		[FlurryClips setVideoDelegate:self];
#endif
		[FlurryAnalytics startSession:kFlurryKey];
		NSString *userID = [SystemUtils getCurrentUID];
		if(userID) [FlurryAnalytics setUserID:userID];
		isFlurrySessionStart = YES;
	}
	
}

-(void)dealloc
{
	if(clickedAppNames) [clickedAppNames release];
	if(arrayInfo) [arrayInfo release];
	[super dealloc];
}


+(NSDictionary *)getCookieWithPrize:(int)prizeType amount:(int)prizeValue
{
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								[SystemUtils getSystemInfo:kFlurryCallbackAppID], @"appID",
								[SystemUtils getCurrentUID], @"userID",
								[NSString stringWithFormat:@"%i",prizeType], @"prizeType",
								[NSString stringWithFormat:@"%i",prizeValue], @"prizeValue",
								[SystemUtils getOriginalCountryCode], @"country", nil];
	return dictionary;
}

+(BOOL) canShowOffer
{
	BOOL hasOffer = YES;
    
	if(![NetworkHelper isConnected]) hasOffer = NO;
#ifndef DEBUG
	if(![SystemUtils isAdVisible]) hasOffer = NO;
#endif
    if(![SystemUtils checkFeature:kFeatureFlurry]) hasOffer = NO;
	if([SystemUtils doesAlertViewShow]) hasOffer = NO;
    
    return hasOffer;
}

+(int)getOfferCount
{
	if(!_flurryHelper || !_flurryHelper.isFlurrySessionStart) return 0;
	return [FlurryAppCircle getOfferCount:[SystemUtils getSystemInfo:kFlurryHookName]];
}

// 获取可用的Offers列表
+(NSArray *)getOffers
{
	if(!_flurryHelper || !_flurryHelper.isFlurrySessionStart) return nil;
	NSMutableArray *offers = [[NSMutableArray alloc] init];
	// [offers autorelease];
	// int prizeGold = [GameConfig getIapCoinsNumWithLevel:[GameData gameData].m_level iapType:1];
	// int prizeGold = 1000;
	NSDictionary *cookie = nil;
	if(_flurryHelper.offerPrizeType == 0) 
		cookie = [self getCookieWithPrize:kFlurryPrizeTypeGold amount:_flurryHelper.offerPrizeGold];
	else 
		cookie = [self getCookieWithPrize:kFlurryPrizeTypeLeaf amount:_flurryHelper.offerPrizeLeaf];
	FlurryOffer *flurryOffer = [[FlurryOffer alloc] init];
	NSMutableArray *appNames = [[NSMutableArray alloc] init];
    NSString *hookName = [SystemUtils getSystemInfo:kFlurryHookName];
	BOOL validOffer = [FlurryAppCircle getOffer:hookName withFlurryOfferContainer:flurryOffer userCookies:cookie];
	while (validOffer) {
		[appNames addObject:flurryOffer.appDisplayName];
		
		NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
		// NSString *myUrl = [flurryOffer.referralUrl stringByAppendingString:appendParam];
        if(flurryOffer.appIcon) {
            NSString *myUrl = flurryOffer.referralUrl;
            [info setValue:myUrl forKey:@"clickURL"];
            [info setValue:flurryOffer.appDisplayName  forKey:@"appName"];
            [info setValue:flurryOffer.appIcon  forKey:@"appIcon"];
            [info setValue:flurryOffer.referralUrl forKey:@"referralUrl"];
            [info setValue:flurryOffer.appPrice forKey:@"appPrice"];
            [info setValue:flurryOffer.appDescription forKey:@"appDescription"];
            [offers addObject:info];
            [info release];
        }
		// next offer
		validOffer = [FlurryAppCircle getOffer:hookName withFlurryOfferContainer:flurryOffer];
		// check if duplicate
		for(int i=0;i<[appNames count];i++)
		{
			if([flurryOffer.appDisplayName isEqualToString:[appNames objectAtIndex:i]]) { 
				validOffer = NO; break;
			}
		}
	}
    [appNames release]; appNames = nil;
	[flurryOffer release];
	
	if([offers count]==0)
	{
		[offers release];
		return nil;
	}
	
	int i = 0;
	// sort array by price
	for(i=0;i<[offers count]-1;i++)
	{
		NSDictionary *info = [offers objectAtIndex:i];
		double price = [[info objectForKey:@"appPrice"] doubleValue];
		for(int j=i+1;j<[offers count];j++)
		{
			NSDictionary *info2 = [offers objectAtIndex:j];
			double price2 = [[info2 objectForKey:@"appPrice"] doubleValue];
			if(price>price2) {
				[info retain]; [info2 retain];
				[offers replaceObjectAtIndex:i withObject:info2];
				[offers replaceObjectAtIndex:j withObject:info];
				[info release]; [info2 release];
				info = info2;
				price = price2;
			}
		}
	}
	NSLog(@"all offers:%@", offers);
	
	double maxPrice = [[SystemUtils getGlobalSetting:kFlurryOfferMaxPrice] doubleValue]*100;
#ifdef DEBUG
	maxPrice = 9999.0f;
#endif
	
	NSMutableDictionary *clickedInfo = [self helper].clickedAppNames;
	NSMutableArray *offer2 = [[NSMutableArray alloc] init];
	for(i=0;i<[offers count];i++)
	{
		NSDictionary *info = [offers objectAtIndex:i];
		NSString *name = [info objectForKey:@"appName"];
		if(maxPrice>0 && maxPrice < [[info objectForKey:@"appPrice"] doubleValue]) break;
		if([clickedInfo objectForKey:name]) continue;
		[offer2 addObject:info];
		[clickedInfo setObject:name forKey:name];
		// if([offer2 count]==2) break;
	}
    if([offer2 count]==0 && [offers count]>0)
    {
        // reset clickedInfo
        [clickedInfo removeAllObjects];
        for(i=0;i<[offers count];i++)
        {
            NSDictionary *info = [offers objectAtIndex:i];
            NSString *name = [info objectForKey:@"appName"];
            if(maxPrice>0 && maxPrice < [[info objectForKey:@"appPrice"] doubleValue]) break;
            if([clickedInfo objectForKey:name]) continue;
            [offer2 addObject:info];
            [clickedInfo setObject:name forKey:name];
            // if([offer2 count]==2) break;
        }
    }
	
	[offers release];
	[offer2 autorelease];
	return offer2;
}

// 显示Offer窗口
+(void) showOffers:(BOOL)showHintIfNoOffer
{
	[self showOffers:showHintIfNoOffer prizeType:0];
}

// 显示Offer窗口，自定义奖励类型
// type:0-金币, 1-叶子
+(void) showOffers:(BOOL)showHintIfNoOffer prizeType:(int)type
{
    if(![self canShowOffer]) return;
    
	if(!_flurryHelper || !_flurryHelper.isFlurrySessionStart) {
        [[FlurryHelper helper] initFlurrySession];
    }
    

	if(_flurryHelper.isShowingOffer) {
		NSLog(@"%s: offer is already shown", __func__);
		return;
	}
	
	if(![[SystemUtils getGameDataDelegate] isTutorialFinished]) {
		// [self showNoOfferHint];
		return;
	}
	
	_flurryHelper.isShowingOffer = YES;
	_flurryHelper.offerPrizeType = type;
	
	NSArray *arr = [self getOffers];
	// int prizeGold = [GameConfig getIapCoinsNumWithLevel:[GameData gameData].m_level iapType:1];
	int prizeGold = 0;
	int prizeLeaf = 0;
	
	if(type==0) prizeGold = _flurryHelper.offerPrizeGold;
	if(type==1) prizeLeaf = _flurryHelper.offerPrizeLeaf;
    NSLog(@"%s: offers:%@", __func__, arr);
	// 如果没有取得arr显示窗口
	if (!arr || [arr count] <= 0) {
		/*
		 smWinQueueAlert *swqAlert = [[smWinQueueAlert alloc] initWithNibName:@"smWinQueueAlert" bundle:nil];
		 swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:[SystemUtils getLocalizedString:@"No free app available at the moment."], @"content", @"", @"action", [NSString stringWithFormat:@"%d",0], @"prizeCoin", [NSString stringWithFormat:@"%d", 0], @"prizeLeaf", nil];
		 [[smWindowQueue createQueue] pushToQueue:swqAlert timeOut:0];
		 */
		_flurryHelper.isShowingOffer = NO;
		if(!showHintIfNoOffer) return;
        SNSAlertView *av = [[SNSAlertView alloc] 
                            initWithTitle:[SystemUtils getLocalizedString: @"No Offer Now"]
                            message:[SystemUtils getLocalizedString: @"There's no free offer now, please try again later!"]
                            delegate:nil
                            cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                            otherButtonTitle: nil];
        
        av.tag = kTagAlertNone;
        // [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
        [av showHard];
        [av release];
        
		_flurryHelper.isShowingOffer = NO;
		return;
	} else {
        int date = [SystemUtils getTodayDate];
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kFlurryShowOfferTime"];
        
		// 显示Offer窗口
		smPopupWindowFlurryOffer *itemStore = [[smPopupWindowFlurryOffer alloc] initWithNibName:@"smPopupWindowFlurryOffer" bundle:nil];
		itemStore.setting = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", prizeGold], @"prizeGold", [NSString stringWithFormat:@"%d", prizeLeaf], @"prizeLeaf", arr, @"arr", nil];
		itemStore.prizeType = type;
		//[[SystemUtils getRootViewController] presentModalViewController:itemStore animated:YES];
		[itemStore showHard];
		[itemStore release];
	}
}

+(BOOL)hasVideoOffer
{
#ifdef SNS_DISABLE_FLURRY_VIDEO
    return NO;
#endif
    if(![self canShowOffer]) return NO;
	
	if(_flurryHelper.isShowingVideo) return NO;
	
	return [FlurryClips videoAdIsAvailable:[SystemUtils getSystemInfo:kFlurryVideoHookName]];
}

+(void) showVideoOffer
{
	[self showVideoOffers:NO];
}

+(void) showVideoOffers:(BOOL)showNoOfferHint
{
#ifdef SNS_DISABLE_FLURRY_VIDEO
    return;
#endif
	SNSLog(@"start");
	BOOL hasOffer = YES;
	if(![self hasVideoOffer]) hasOffer = NO;
    
	if([SystemUtils doesAlertViewShow]) return;
	
	if(!hasOffer) {
		if(showNoOfferHint) {
            SNSAlertView *av = [[SNSAlertView alloc] 
                                initWithTitle:[SystemUtils getLocalizedString:@"No Video Available"]
                                message:[SystemUtils getLocalizedString:@"No video is available now, please try again later."]
                                delegate:nil
                                cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                                otherButtonTitle: nil];
            
            av.tag = kTagAlertNone;
            // [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
            [av showHard];
            [av release];
		}
		return;
	}
	
	_flurryHelper.isShowingVideo = YES;
	// buyCoinsIcon.png
	UIImage *rewardImage = [UIImage imageNamed:@"buyCoinsIcon.png"];
	// UIImage *rewardImage = [UIImage imageNamed:@"wqRunLoginLeafage.png"];
	// int prizeGold = [GameConfig getIapCoinsNumWithLevel:[GameData gameData].m_level iapType:1];
    NSString *coinName = [StringUtils getCapitalizeWord:[SystemUtils getLocalizedString:@"CoinName1"]];
	int prizeGold = _flurryHelper.videoPrizeGold;
    NSString *prizeMesg = [StringUtils getTextOfNum:prizeGold Word:coinName];
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%i",prizeGold], @"prizeGold", nil];
	
	[FlurryClips openVideoTakeover:[SystemUtils getSystemInfo:kFlurryVideoHookName] orientation:nil rewardImage:rewardImage 
					 rewardMessage:prizeMesg userCookies:dict autoPlay:NO];
	
}

+(BOOL) hasRecommendation
{
    if(![self canShowOffer]) return NO;
	
    return [FlurryAppCircle appAdIsAvailable:kFlurryRecommendationHookName];
}

+(void) showRecommendation
{
	if(![self hasRecommendation]) return;
    if(![SystemUtils getInterruptMode]) return;
    
	if([SystemUtils doesAlertViewShow]) return;
    
    // NSString *orig = [SystemUtils getSystemInfo:kGameOrientation];
    NSString *orig2 = @"portrait";
    // if(orig && ([orig isEqualToString:@"LandscapeRight"] || [orig isEqualToString:@""
    UIDeviceOrientation orig = [SystemUtils getGameOrientation];
    if(orig == UIDeviceOrientationLandscapeLeft || orig == UIDeviceOrientationLandscapeRight) 
        orig2 = @"landscape";
    [FlurryAppCircle openTakeover:kFlurryRecommendationHookName orientation:orig2 rewardImage:nil rewardMessage:nil userCookies:nil];
}


- (void) setVideoPrizeGold:(int)gold
{
	if(gold<10) gold = 10;
	videoPrizeGold = gold;
}

- (void) setOfferPrizeGold:(int)gold
{
	if(gold<10) gold = 10;
	offerPrizeGold = gold;
}

-(void)getRewardsLazy
{
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kFlurryShowOfferTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kFlurryCheckTime"] intValue];
    if(checkTime>showTime+1) return;
    [self getRewards];
    
}

-(void)getRewards
{
    [self initFlurrySession];
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
	NSLog(@"%s api:%@", __FUNCTION__, api);
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
		if(prizeType == kFlurryPrizeTypeGold) {
            [SystemUtils addGameResource:prizeValue ofType:kGameResourceTypeCoin];
            moneyType = [SystemUtils getLocalizedString:@"CoinName1"];
            if(prizeValue>1) moneyType = [StringUtils getPluralFormOfWord:moneyType];
			// [SystemUtils logFlurryIncome:prizeValue prizeType:kLogTypeEarnCoin];
            [[SnsStatsHelper helper] logResource:kCoinType1 change:prizeValue channelType:kResChannelFlurry];
        }
		if(prizeType == kFlurryPrizeTypeLeaf) {
            [SystemUtils addGameResource:prizeValue ofType:kGameResourceTypeLeaf];
			moneyType = [SystemUtils getLocalizedString:@"CoinName2"];
            if(prizeValue>1) moneyType = [StringUtils getPluralFormOfWord:moneyType];
            [[SnsStatsHelper helper] logResource:kCoinType2 change:prizeValue channelType:kResChannelFlurry];
			// [SystemUtils logFlurryIncome:prizeValue prizeType:kLogTypeEarnLeaf];
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
	NSLog(@"%s status code:%i",__FUNCTION__, request.responseStatusCode);
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		[self loadCancel];
		return;
	}
	NSLog(@"%s response:%@", __FUNCTION__, [request responseString]);
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
		NSLog(@"deserializer result:%@", arr);
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
	NSLog(@"%s - error: %@", __FUNCTION__, error);
	[self loadCancel];
}

#pragma mark -

#pragma mark FlurryAdDelegate

- (void)takeoverWillDisplay:(NSString *)hook
{
	//[[AudioPlayer sharedPlayer] pauseMusic];
	// [[CCDirector sharedDirector] pause];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationPauseMusic object:nil userInfo:nil];
}

- (void)takeoverWillClose
{
	isShowingVideo = NO;
	// [[AudioPlayer sharedPlayer] resumeMusic];
	// [[CCDirector sharedDirector] resume];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationResumeMusic object:nil userInfo:nil];
}

- (void)videoDidFinish:(NSString*)hook withUserCookies:(NSDictionary*)userCookies
{
	NSLog(@"%s: cookies:%@", __FUNCTION__, userCookies);
	int prizeGold = [[userCookies objectForKey:@"prizeGold"] intValue];
	if(prizeGold > 0) {
		[SystemUtils addGameResource:prizeGold ofType:kGameResourceTypeCoin];
		//[[AudioPlayer sharedPlayer] playEffect:kEffect_Coins];
		[SystemUtils logResourceChange:kLogTypeEarnCoin method:kLogMethodTypeFreeOffer itemID:@"flurryVideo" count:prizeGold];
	}
	int prizeLeaf = [[userCookies objectForKey:@"prizeLeaf"] intValue];
	if(prizeLeaf > 0) {
		[SystemUtils addGameResource:prizeLeaf ofType:kGameResourceTypeLeaf];
		//[[AudioPlayer sharedPlayer] playEffect:kEffect_Coins];
		[SystemUtils logResourceChange:kLogTypeEarnLeaf method:kLogMethodTypeFreeOffer itemID:@"flurryVideo" count:prizeLeaf];
	}
}


#pragma mark -

@end
