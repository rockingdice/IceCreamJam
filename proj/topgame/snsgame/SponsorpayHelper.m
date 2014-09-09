//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "SponsorpayHelper.h"
#import "SystemUtils.h"
#import "SponsorPaySDK.h"
#import "StringUtils.h"
#import "smPopupWindowQueue.h"
#import "smPopupWindowNotice.h"
#import "StringUtils.h"
#import "ASIFormDataRequest.h"
#import "SBJson.h"

@implementation SponsorPayHelper

static SponsorPayHelper *_gSponsorPayHelper = nil;

+ (SponsorPayHelper *) helper
{
    if(!_gSponsorPayHelper) {
        _gSponsorPayHelper = [[SponsorPayHelper alloc] init];
    }
    return _gSponsorPayHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO; viewController = nil; req = nil;
        _brandEngageClient = nil; isVideoEnabled = NO; isVideoEnabled = NO;
    }
    return self;
}

- (void) initSession
{
    if(isInitialized) return;
    
    NSString *appID = [SystemUtils getGlobalSetting:@"kSponsorpayAppID"];
    NSString *appToken = [SystemUtils getGlobalSetting:@"kSponsorpayAppToken"];
    if(appID==nil || [appID length]<3) {
        appID    = [SystemUtils getSystemInfo:@"kSponsorpayAppID"];
        appToken = [SystemUtils getSystemInfo:@"kSponsorpayAppToken"];
    }
    if(appID!=nil && [appID length]>3) {
        [SponsorPaySDK startForAppId:appID
                          userId:[SystemUtils getCurrentUID]
                   securityToken:appToken];
        // if enable video
        int videoEnabled = [[SystemUtils getGlobalSetting:@"kSponsorpayEnableVideo"] intValue];
        if(videoEnabled==1) {
            isVideoEnabled = YES;
            _brandEngageClient = [SponsorPaySDK requestBrandEngageOffersNotifyingDelegate:self];
        }
        isInitialized = YES;
        [self checkCoins];
    }
}

- (void) dealloc
{
    if(req!=nil) { [req release]; req = nil; }
    [super dealloc];
    
}
- (void) checkCoins
{
    if(!isInitialized) return;
    // [SponsorPaySDK requestDeltaOfCoinsNotifyingDelegate:self];
    [self getRewardsLazy];
}

- (NSDictionary *)getCustomParameters
{
	NSString *appID = [SystemUtils getSystemInfo:kFlurryCallbackAppID];
    NSString *prizeType = [SystemUtils getSystemInfo:@"kSponsorpayPrizeType"];
    NSString *country = [SystemUtils getOriginalCountryCode];
    if(prizeType==nil || [prizeType length]==0) prizeType = @"1";
    return [NSDictionary dictionaryWithObjectsAndKeys:appID, @"appID", prizeType, @"prizeType", country, @"country", nil];
}

- (void) showOfferWall
{
    if(!isInitialized)
        [self initSession];
    
    if(!isInitialized) return;
    
    UIViewController *root = [SystemUtils getRootViewController];
    if(root==nil) root = [SystemUtils getAbsoluteRootViewController];
    // [ALInterstitialAd showOver:root.view.window];
    [self clearViewController];
    // viewController = [[SponsorPayViewController alloc] init];
    // [root.view addSubview:viewController.view];
    // [SponsorPaySDK showOfferWallWithParentViewController:root];
    SPOfferWallViewController *offerwallVC = [SponsorPaySDK offerWallViewController];
    offerwallVC.delegate = self;
    [offerwallVC setCustomParameters:[self getCustomParameters]];
    [offerwallVC showOfferWallWithParentViewController:root];
}

- (void) showPopupOffer
{
    if(!isInitialized)
        [self initSession];
    
    if(!isInitialized) return;
    
    UIViewController *root = [SystemUtils getRootViewController];
    if(root==nil) root = [SystemUtils getAbsoluteRootViewController];
    // [ALInterstitialAd showOver:root.view.window];
    [self clearViewController];
    // viewController = [[SponsorPayViewController alloc] init];
    // [root.view addSubview:viewController.view];
    SPInterstitialViewController *interVC = [SponsorPaySDK interstitialViewController];
    interVC.delegate = self;
    [interVC setCustomParameters:[self getCustomParameters]];
    [interVC startLoadingWithParentViewController:root];
    // [SponsorPaySDK startLoadingInterstitialWithParentViewController:root];
    // [SponsorPaySDK showOfferWallWithParentViewController:root];
    
}

- (void) showVideoOffer
{
    if(!isInitialized)
        [self initSession];
    
    if(!isInitialized) return;
    
    if(!isVideoReady) {
        _brandEngageClient = [SponsorPaySDK requestBrandEngageOffersNotifyingDelegate:self];
        return;
    }
    
    UIViewController *root = [SystemUtils getRootViewController];
    if(root==nil) root = [SystemUtils getAbsoluteRootViewController];
    // [ALInterstitialAd showOver:root.view.window];
    [self clearViewController];
    // viewController = [[SponsorPayViewController alloc] init];
    // [root.view addSubview:viewController.view];
    NSDictionary *dic = [self getCustomParameters];
    [_brandEngageClient setCustomParamWithKey:@"appID" value:[dic objectForKey:@"appID"]];
    [_brandEngageClient setCustomParamWithKey:@"prizeType" value:[dic objectForKey:@"prizeType"]];
    [_brandEngageClient setCustomParamWithKey:@"country" value:[dic objectForKey:@"country"]];
    BOOL res = [_brandEngageClient startWithParentViewController:root];
    if(!res) [self playVideoFinished];
}

- (void) clearViewController
{
    if(viewController) {
        [viewController.view removeFromSuperview];
        [viewController autorelease];
        viewController = nil;
    }
}

- (void) playVideoFinished
{
    if(isVideoReady) {
        [self clearViewController];
        isVideoReady = NO;
        _brandEngageClient = [SponsorPaySDK requestBrandEngageOffersNotifyingDelegate:self];
    }
}

/** @name Requesting offers */

/** Sent when BrandEngage receives an answer about offers availability.
 
 @param brandEngageClient The instance of SPBrandEngageClient that sent this message.
 @param areOffersAvailable A boolean value indicating whether offers are available. If this value is YES, you can start the engagement.
 */
- (void)brandEngageClient:(SPBrandEngageClient *)brandEngageClient
         didReceiveOffers:(BOOL)areOffersAvailable
{
    isVideoReady = areOffersAvailable;
}

/** @name Showing offers */

/** Sent when a running engagement changes state.
 
 @param brandEngageClient The instance of SPBrandEngageClient that sent this message.
 @param newStatus A constant value of the SPBrandEngageClientStatus type indicating the new status of the engagement.
 */

- (void)brandEngageClient:(SPBrandEngageClient *)brandEngageClient
          didChangeStatus:(SPBrandEngageClientStatus)newStatus
{
    if(newStatus!=STARTED) {
        [self playVideoFinished];
    }
}


/** Sent when SPVirtualCurrencyServerConnector receives an answer from the server for the amount of coins newly earned by the user.
 @param connector SPVirtualCurrencyServerConnector instance of SPVirtualCurrencyServerConnector that sent this message.
 @param deltaOfCoins Amount of coins earned by the user.
 @param transactionId Transaction ID of the last known operation involving your virtual currency for this user.
 */
- (void)virtualCurrencyConnector:(SPVirtualCurrencyServerConnector *)connector
  didReceiveDeltaOfCoinsResponse:(double)deltaOfCoins
             latestTransactionId:(NSString *)transactionId
{
    /*
    if(deltaOfCoins<1) return;
    int coinType = [SystemUtils getSystemInfo:@"kSponsorPayPrizeType"];
    if(coinType!=kGameResourceTypeLeaf) coinType = kGameResourceTypeCoin;
    
    int amount = deltaOfCoins;
    NSString *coinName = [SystemUtils getLocalizedString:@"CoinName1"];
    if(coinType==kGameResourceTypeLeaf) coinName = [SystemUtils getLocalizedString:@"CoinName2"];
    if(amount>1) coinName = [StringUtils getPluralFormOfWord:coinName];
	
    NSString *prizeLeaf = @"0"; NSString *prizeCoin = @"0";
    if(coinType==kGameResourceTypeCoin) prizeCoin = [NSString stringWithFormat:@"%d",amount];
    if(coinType==kGameResourceTypeLeaf) prizeLeaf = [NSString stringWithFormat:@"%d",amount];
    
	NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ from SponsorPay!"], amount, coinName];
	// show notice
	smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
	swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"content", @"", @"action", prizeCoin, @"prizeCoin", prizeLeaf, @"prizeLeaf", nil];
	[[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:0];
    [swqAlert release];
     */
}

/** Sent when SPVirtualCurrencyServerConnector detects an error condition.
 @param connector SPVirtualCurrencyServerConnector instance of SPVirtualCurrencyServerConnector that sent this message.
 @param error Type of the triggered error. @see SPVirtualCurrencyRequestErrorType
 @param errorCode if this is an error received from the back-end, error code as reported by the server.
 @param errorMessage if this is an error received from the back-end, error message as reported by the server.
 */
- (void)virtualCurrencyConnector:(SPVirtualCurrencyServerConnector *)connector
                 failedWithError:(SPVirtualCurrencyRequestErrorType)error
                       errorCode:(NSString *)errorCode
                    errorMessage:(NSString *)errorMessage
{
    
}


/**
 Sent when the SPOfferWallViewController finished. It can have been explicitly dismissed by the user, closed itself when redirecting outside of the app to proceed with an offer, or closed due to an error.
 
 @param offerWallVC the SPOfferWallViewController which is being closed.
 @param status if there was a network error, this will have the value of SPONSORPAY_ERR_NETWORK.
 */
- (void)offerWallViewController:(SPOfferWallViewController *)offerWallVC
           isFinishedWithStatus:(int)status
{
    SNSLog(@"status:%d",status);
    // [self clearViewController];
}

/**
 Sent when the corresponding SPInterstitialViewControllerDelegate changes status, denoting an answer from the server which indicates the availability of an Interstitial offer, a close event, or an error.
 
 @param interstitialViewController The SPInterstitialViewController which is sending this message.
 @param status A status code defined in SPInterstitialViewControllerStatus.
 */
- (void)interstitialViewController:(SPInterstitialViewController *)interstitialViewController
                   didChangeStatus:(SPInterstitialViewControllerStatus)status
{
    SNSLog(@"status:%d",status);
    if(status!=AD_SHOWN) {
        // [self clearViewController];
        // [[SponsorPayHelper helper] clearViewController];
    }
}


#pragma mark get rewards

-(void)getRewardsLazy
{
#if 0
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kSponsorPayShowOfferTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kSponsorPayCheckTime"] intValue];
    if(checkTime>showTime+1) return;
#endif
    [self getRewards];
    
}

-(void)getRewards
{
    [self initSession];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kSponsorPayCheckTime"];
	// get rewards
	NSString *api   = [NSString stringWithFormat:@"http://%@/api/", [SystemUtils getFlurryRewardServerName]];
	NSString *appID = [SystemUtils getSystemInfo:kFlurryCallbackAppID];
	NSString *userID = [SystemUtils getCurrentUID];
	NSString *time   = [NSString stringWithFormat:@"%i",[SystemUtils getCurrentTime]];
	NSString *country = [SystemUtils getOriginalCountryCode];
	NSString *digKey  = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", appID, userID, country, kFlurryRewardsSigKey, time];
	NSString *sig = [StringUtils stringByHashingStringWithMD5:digKey];
	api = [api stringByAppendingFormat:@"sponsorpayRewardsGet.php?appID=%@&userID=%@&country=%@&time=%@&sig=%@", appID, userID, country, time, sig];
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
    
    int prizeType = [[SystemUtils getGlobalSetting:@"kSponsorpayPrizeType"] intValue];
    if(prizeType<=0) prizeType = [[SystemUtils getSystemInfo:@"kSponsorpayPrizeType"] intValue];
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


@implementation SponsorPayViewController

- (id)init
{
	if ((self = [super init])) {
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

// Override to allow orientations other than the default landscape orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsLandscape( interfaceOrientation );
    
    // switch to this line if you want to set portrait view
    // return UIInterfaceOrientationIsPortrait( interfaceOrientation );
}

- (NSInteger) supportedInterfaceOrientations {
#ifdef __IPHONE_6_0
    return UIInterfaceOrientationMaskLandscape;
#endif
}

- (BOOL) shouldAutorotate {
    return YES;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)dealloc {
    [super dealloc];
    
    
}

/**
 Sent when the SPOfferWallViewController finished. It can have been explicitly dismissed by the user, closed itself when redirecting outside of the app to proceed with an offer, or closed due to an error.
 
 @param offerWallVC the SPOfferWallViewController which is being closed.
 @param status if there was a network error, this will have the value of SPONSORPAY_ERR_NETWORK.
 */
- (void)offerWallViewController:(SPOfferWallViewController *)offerWallVC
           isFinishedWithStatus:(int)status
{
    SNSLog(@"status:%d",status);
    [[SponsorPayHelper helper] clearViewController];
}
/** @name Showing offers */

/** Sent when a running engagement changes state.
 
 @param brandEngageClient The instance of SPBrandEngageClient that sent this message.
 @param newStatus A constant value of the SPBrandEngageClientStatus type indicating the new status of the engagement.
 */
/*
- (void)brandEngageClient:(SPBrandEngageClient *)brandEngageClient
          didChangeStatus:(SPBrandEngageClientStatus)newStatus
{
    if(newStatus!=STARTED) {
        [[SponsorPayHelper helper] playVideoFinished];
    }
}
 */

/**
 Sent when the corresponding SPInterstitialViewControllerDelegate changes status, denoting an answer from the server which indicates the availability of an Interstitial offer, a close event, or an error.
 
 @param interstitialViewController The SPInterstitialViewController which is sending this message.
 @param status A status code defined in SPInterstitialViewControllerStatus.
 */
- (void)interstitialViewController:(SPInterstitialViewController *)interstitialViewController
                   didChangeStatus:(SPInterstitialViewControllerStatus)status
{
    SNSLog(@"status:%d",status);
    if(status!=AD_SHOWN) {
        [[SponsorPayHelper helper] clearViewController];
    }
}

@end
