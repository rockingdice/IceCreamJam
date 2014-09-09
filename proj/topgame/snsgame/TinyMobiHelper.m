//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "TinyMobiHelper.h"
#import "SystemUtils.h"
#import "TinyMobiConnect.h"
#import "smPopupWindowNotice.h"
#import "smPopupWindowQueue.h"
#import "StringUtils.h"
#import "TMBCommon.h"
#import "NetworkHelper.h"
#import "SnsStatsHelper.h"

@implementation TinyMobiHelper

static TinyMobiHelper *_gTinyMobiHelper = nil;

+ (TinyMobiHelper *) helper
{
    if(!_gTinyMobiHelper) {
        _gTinyMobiHelper = [[TinyMobiHelper alloc] init];
    }
    return _gTinyMobiHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO; isCheckingRewards = NO; rewardsIDList = nil;
    }
    return self;
}

- (void) dealloc
{
    if(rewardsIDList) {
        [rewardsIDList release];
        rewardsIDList = nil;
    }
    [super dealloc];
}

- (void) resetSession
{
    isInitialized = NO;
    [self initSession];
}

- (void) startTinyMobi
{
    NSString *appID = [SystemUtils getSystemInfo:@"kTinyMobiAppID"];
    NSString *secret = [SystemUtils getSystemInfo:@"kTinyMobiAppSecret"];
    
    BOOL isPortrait = NO;
    NSString *str = [SystemUtils getSystemInfo:@"kGameOrientation"];
    if(str && [str isKindOfClass:[NSString class]] && [str isEqualToString:@"Portrait"])
        isPortrait = YES;
    
    if(appID==nil || secret==nil || [appID length]==0 || [secret length]==0) return;
    TinyMobiConnect *tmb = [TinyMobiConnect sharedTinyMobi];
    tmb.appId = appID;
    tmb.secretKey = secret;
    NSString *autoOpen = @"0";
    if([SystemUtils isAdVisible]) autoOpen = @"1";
    if([[SnsStatsHelper helper] getTotalPay]>0) autoOpen = @"0";
    [tmb setOption:TMB_OPT_IS_POP_AUTO_OPEN WithValue:autoOpen];
    if(isPortrait)
        [tmb setOption:TMB_OPT_APP_ORIENTATION WithValue:TMB_APP_ORIENTATION_PORTRAIT];
    else
        [tmb setOption:TMB_OPT_APP_ORIENTATION WithValue:TMB_APP_ORIENTATION_LANDSCAPE];
    
#ifdef DEBUG
    // [tmb useSandbox:YES];
#endif
    [tmb start];
    
}

- (void) initSession
{
    if(isInitialized) return;
    // return;
    // [self performSelectorInBackground:@selector(startTinyMobi) withObject:nil];
    [self startTinyMobi];
    // [tmb performSelectorInBackground:@selector(start) withObject:nil];
    // [self performSelector:@selector(showPopupAd) withObject:nil afterDelay:3.0f];
    
    // [self performSelectorInBackground:@selector(checkRewards) withObject:nil];
    [self checkRewards];
    
    isInitialized = YES;
	
}



- (void) showOffer
{
    SNSLog(@"start show offer");
    if(![[NetworkHelper helper] connectedToInternet]) {
        NSString *title = [SystemUtils getLocalizedString:@"Network Required"];
        NSString *mesg  = [SystemUtils getLocalizedString:@"No Internet connection. Make sure you are connected to the Internet and try again."];
        [SystemUtils showSNSAlert:title message:mesg];
        return;
    }
    if(!isInitialized)
        [self initSession];
    BOOL showOffer = YES;
    if(!isInitialized) showOffer = NO;
    if(![SystemUtils isAdVisible]) {
        SNSLog(@"ad not visible");
        showOffer = NO;
    }
    // Load interstitial
    if(![SystemUtils checkFeature:kFeatureTinyMobi]) {
        SNSLog(@"tinymobi not enabled");
        showOffer = NO;
    }
    if(!showOffer) {
        NSString *title = [SystemUtils getLocalizedString:@"No Bonus Found"];
        NSString *mesg  = [SystemUtils getLocalizedString:@"There's no bonus now, please check again tomorrow."];
        [SystemUtils showSNSAlert:title message:mesg];
        return;
    }
    // [[TinyMobiConnect sharedTinyMobi] showAdWithType:TMB_AD_TINY_WALL On:nil];
    // UIViewController *root = [SystemUtils getRootViewController];
    // if(root == nil) root = [SystemUtils getAbsoluteRootViewController];
    UIViewController *root = [SystemUtils getAbsoluteRootViewController];
    // UIViewController *root = [TMBCommon getRootViewController];
    [[TinyMobiConnect sharedTinyMobi] showTinyWall:root];
}

// 显示一天只有1次的弹窗广告
- (BOOL) showPopupAd
{
    SNSLog(@"show tinymobi popup");
    if(!isInitialized)
        [self initSession];
    if(!isInitialized) return NO;
    if(![[TinyMobiConnect sharedTinyMobi] isTinyPopReady]) return NO;
    // [[TinyMobiConnect sharedTinyMobi] showAdWithType:TMB_AD_TINY_POP On:nil];
    int today = [SystemUtils getTodayDate];
    int lastDate = [[SystemUtils getNSDefaultObject:@"tmbPopDate"] intValue];
#ifdef DEBUG
    lastDate = 0;
#endif
    if(lastDate!=today) {
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:today] forKey:@"tmbPopDate"];
        [[TinyMobiConnect sharedTinyMobi] performSelectorInBackground:@selector(showTinyPop:) withObject:nil];
        return YES;
    }
    return NO;
}

- (BOOL) isRewardIDExists:(NSString *)rewardID
{
    if(!rewardID) return NO;
    if(rewardsIDList==nil) {
        rewardsIDList = [[NSMutableDictionary alloc] init];
        NSDictionary *dict = [[SystemUtils getGameDataDelegate] getExtraInfo:@"kTMBRewards"];
        if(dict && [dict isKindOfClass:[NSDictionary class]])
            [rewardsIDList addEntriesFromDictionary:dict];
    }
    if([rewardsIDList objectForKey:rewardID]) return YES;
    return NO;
}
- (void) addRewardID:(NSString *)rewardID
{
    if(!rewardID) return;
    if(!rewardsIDList) return;
    [rewardsIDList setValue:@"1" forKey:rewardID];
    [[SystemUtils getGameDataDelegate] setExtraInfo:rewardsIDList forKey:@"kTMBRewards"];
}

- (void) checkRewards2
{
    /*
     //get rewards info
     - (NSArray *) getRewardsInfo;
     contents of reward info:
     [{
     "offerId": 0,//reward Id
     "offerInfo": {
     "amount": "10", //reward amount
     "name": "coin", //reward name
     "adv_app_id": "2001156", //advertiser app id
     "time": 1354861955, //reward time
     "type": "play" // play or buy
     }
     }]
     Dec 14 11:24:14 unknown Pet Home[6839] <Warning>: -[TinyMobiHelper checkRewards] [Line 114] tinymobi Rewards:(
     {
     rewardId = 0;
     rewardInfo =         {
     "adv_app_id" = 2001103;
     amount = 10;
     name = Coins;
     time = 1355455308;
     type = play;
     };
     }
     )
     
     */
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    [self initSession];
    NSString *coinName = [SystemUtils getSystemInfo:@"kTinyMobiCoinName"];
    int coinType = [[SystemUtils getSystemInfo:@"kTinyMobiCoinType"] intValue];
    if(!coinName || [coinName length]==0) coinName = @"coins";
    else coinName = [coinName lowercaseString];
    if(coinType<=0) coinType = 1;
    NSArray * arr = [[TinyMobiConnect sharedTinyMobi] getRewardsInfo];
    if(!arr || [arr count]==0) {
        [pool release];
        return;
    }
#ifdef DEBUG
    SNSLog(@"tinymobi Rewards:%@",arr);
#endif
    int coinCount = 0; NSMutableArray *arr2 = [NSMutableArray arrayWithCapacity:[arr count]];
    for (NSDictionary *info in arr) {
        NSDictionary *info2 = [info objectForKey:@"rewardInfo"];
        if(info2==nil || [info objectForKey:@"rewardId"]==nil) continue;
        NSString *rewardID = [NSString stringWithFormat:@"%@",[info objectForKey:@"rewardId"]];
        if([self isRewardIDExists:rewardID]) continue;
        [self addRewardID:rewardID];
        NSString *coinName1 = nil; int count = 0;
        [arr2 addObject:rewardID];
        if(info2) {
            coinName1 = [info2 objectForKey:@"name"];
            count = [[info2 objectForKey:@"amount"] intValue];
        }
        if(count<=0 || coinName1==nil) continue;
        if([coinName isEqualToString:[coinName1 lowercaseString]])
        {
            coinCount += count;
        }
    }
    if(coinCount>0) {
		// 显示获奖通知
        int prizeValue = coinCount;
        NSString *moneyType = [SystemUtils getLocalizedString:coinName];
        if(prizeValue>1) moneyType = [StringUtils getPluralFormOfWord:moneyType];
		NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], prizeValue, moneyType];
        /*
		// show notice
        UIAlertView *av = [[UIAlertView alloc]
                           initWithTitle:[SystemUtils getLocalizedString:@"TinyMobi Prize"]
                           message:mesg
                           delegate:nil
                           cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                           otherButtonTitles: nil];
        [av show];
        [av release];
         */
        // [[SystemUtils getGameDataDelegate] addGameResource:coinCount ofType:coinType];
        int prizeCoin = 0; int prizeLeaf = 0;
        if(coinType==1) prizeCoin = coinCount;
        else if(coinType==2) prizeLeaf = coinCount;
        else
            [[SystemUtils getGameDataDelegate] addGameResource:coinCount ofType:coinType];
        
		smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
		swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"content", @"", @"action", [NSNumber numberWithInt:prizeCoin], @"prizeCoin", [NSNumber numberWithInt:prizeLeaf], @"prizeLeaf", nil];
		[[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:0];
		[swqAlert release];
        
    }
    // [[TinyMobiConnect sharedTinyMobi] completeRewards:arr];
    [[TinyMobiConnect sharedTinyMobi] performSelectorInBackground:@selector(finishRewardsInfo:) withObject:arr2];
    // [[TinyMobiConnect sharedTinyMobi] finishRewardsInfo:arr2];
    isCheckingRewards = NO;
    [pool release];
}
- (void) checkRewards
{
    if(isCheckingRewards) return;
    isCheckingRewards = YES;
    [self performSelectorInBackground:@selector(checkRewards2) withObject:nil];
    /*
#ifdef DEBUG
    // 测试获奖显示
    int prizeCoin = 2; int prizeLeaf = 0;
    
    smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
    swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:@"Congratulations! You've got 2 brains for free!", @"content", @"", @"action", [NSNumber numberWithInt:prizeCoin], @"prizeCoin", [NSNumber numberWithInt:prizeLeaf], @"prizeLeaf", nil];
    [[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:0];
    [swqAlert release];
    
#endif
     */
}

- (void) loadCacheOffer
{
    // [[Chartboost sharedChartboost] cacheInterstitial];
}

- (BOOL) hasCachedOffer
{
    return NO;
    // return [[Chartboost sharedChartboost] hasCachedInterstitial];
}

- (BOOL) showMoreGames
{
    [[TinyMobiConnect sharedTinyMobi] showTinyMyGames:nil];
    return YES;
}


#pragma mark TinyMobiDelegate

- (BOOL)shouldDisplayPopupOffer
{
    return [SystemUtils getInterruptMode];
}



#pragma mark -

@end
