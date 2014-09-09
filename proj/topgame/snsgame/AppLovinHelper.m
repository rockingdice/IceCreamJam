//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "AppLovinHelper.h"
#import "SystemUtils.h"
#import "ALInterstitialAd.h"
#import "ALIncentivizedInterstitialAd.h"

@implementation AppLovinHelper

static AppLovinHelper *_gAppLovinHelper = nil;

+ (AppLovinHelper *) helper
{
    if(!_gAppLovinHelper) {
        _gAppLovinHelper = [[AppLovinHelper alloc] init];
    }
    return _gAppLovinHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO; isAdReady = NO; pengdingAd = nil; isAdShowing = NO;
        isAdLoading = NO; videoAd = nil;
    }
    return self;
}

- (void) initSession
{
    if(isInitialized) return;
    
    isInitialized = YES; shouldPopupAd = NO;
    ALSdk *sdk = [ALSdk shared];
    [sdk initializeSdk];
    [self loadAdOffer];
}

- (void) loadAdOffer
{
    if(isAdLoading || isRewardVideoLoading) return;
    currentAdType = 0;
    isAdLoading = YES;
    [[[ALSdk shared] adService] loadNextAd:[ALAdSize sizeInterstitial] andNotify:self];
}

- (BOOL) showPopupOfferNotice
{
    if(!isInitialized)
        [self initSession];
    
    if(!isInitialized) return NO;
    if(isAdLoading) return NO;
    if(!isAdReady) {
        [self loadAdOffer];
        return NO;
    }
    if(isAdShowing) return NO;
    NSDictionary *info = @{
                           @"action":@"showApplovin2",
                           @"auto_update": @0,
                           @"country": @"GENERAL",
                           @"country_limit":@0,
                           @"endTime":@2899967800,
                           @"hideClose":@0,
                           @"id":@"1000001",
                           @"level":@0,
                           @"message":@"Have a break, will you see an ad of another game?",
                           @"noticeVer":@1,
                           @"os":@0,
                           @"picBig":@"photo_hd5.png",
                           @"picExt":@"png",
                           @"picSmall":@"photo5.png",
                           @"picVer":@0,
                           @"prizeGold":@0,
                           @"prizeItem":@"",
                           @"prizeId":@0,
                           @"prizeLeaf":@0,
                           @"startTime":@1389190200,
                           @"subID":@"",
                           @"type":@3,
                           @"updateTime":@0,
                           @"noClose":@0
                           };
    NSMutableDictionary *info2 = [NSMutableDictionary dictionaryWithDictionary:info];
    int today = [SystemUtils getTodayDate];
    [info2 setObject:[NSNumber numberWithInt:today] forKey:@"noticeVer"];
#ifdef DEBUG
    int ver = rand();
    [info2 setObject:[NSNumber numberWithInt:ver] forKey:@"noticeVer"];
    [info2 setObject:@"see applovin ad." forKey:@"message"];
#endif
    [SystemUtils addPromotionNotice:info2];
    
    return YES;
}

- (BOOL) showPopupOffer
{
    if(!isInitialized)
        [self initSession];
    
    if(!isInitialized) return NO;
    if(isAdLoading) return NO;
    if(!isAdReady) {
        [self loadAdOffer];
        shouldPopupAd = YES;
        return NO;
    }
    shouldPopupAd = NO;
    if(isAdShowing) return NO;
    if([UIApplication sharedApplication].keyWindow==nil) return NO;
    // UIViewController *root = [SystemUtils getRootViewController];
    // if(root==nil) root = [SystemUtils getAbsoluteRootViewController];
    ALInterstitialAd *ad = [ALInterstitialAd shared];
    ad.adDisplayDelegate = self; isAdShowing = YES;
    // [ad initInterstitialAdWithSdk:[ALSdk shared]];
    // [ALInterstitialAd showOver:root.view.window];
    // [ad showOver:root.view.window andRender:pengdingAd];
    // [UIApplication sharedApplication].keyWindow
    [ad showOver:[UIApplication sharedApplication].keyWindow andRender:pengdingAd];
    isAdClicked = NO; showAdType = 0;
    return YES;
}

// 显示带奖励的视频
- (BOOL) showRewardVideoOffer
{
    if(isRewardVideoLoading) return NO;
    if(isAdShowing) return NO;
    if(isRewardVideoReady) {
        // 播放视频广告
        [self startPlayVideo];
        return YES;
    }
    [self loadRewardVideo];
    if(isRewardVideoReady) {
        // 播放视频广告
        [self startPlayVideo];
        return YES;
    }
    
    return NO;
}
- (BOOL) isRewardVideoLoaded
{
    return isRewardVideoReady;
}
- (void) loadRewardVideo
{
    if(isRewardVideoLoading || isAdLoading) return;
    currentAdType = 1; isRewardVideoLoading = YES;
    [ALIncentivizedInterstitialAd preloadAndNotify: self];
}

- (void) resumeGamePlay
{
    if(isPausingAudio) {
        isPausingAudio = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"snsgame.ResumeGame" object:nil userInfo:nil];
    }
}

- (void) pauseGamePlay
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"snsgame.PauseGame" object:nil userInfo:nil];
    isPausingAudio = YES;
}
- (void) startPlayVideo
{
    isRewardVideoReady = NO; showAdType = 1; isAdShowing = YES;
    [ALIncentivizedInterstitialAd shared].adVideoPlaybackDelegate = self;
    [ALIncentivizedInterstitialAd shared].adDisplayDelegate = self;
    [ALIncentivizedInterstitialAd showOver: [[UIApplication sharedApplication] keyWindow] andNotify: self];
}

- (void) trackPurchase
{
    NSString * packageName = [[[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleIdentifier"] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    NSString * idfa        = [SystemUtils getIDFA];
    if(idfa==nil || [idfa length]==0) return;
    
    NSString * urlString = [NSString stringWithFormat: @"http://rt.applovin.com/pix?event=landing&package_name=%@&idfa=%@&platform=ios&sdk_key=YOUR_SDK_KEY_HERE", packageName, idfa];
    
    NSURL *        url     = [NSURL URLWithString: urlString];
    NSURLRequest * request = [NSURLRequest requestWithURL: url
                                              cachePolicy: NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                          timeoutInterval: 300];
    NSOperationQueue * requestQueue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest: request
                                       queue: requestQueue
                           completionHandler: ^(NSURLResponse * response, NSData * data, NSError * connectionError) {
                               if ( connectionError ) {
                                   NSLog(@"AppLovin retargeting notification failed - connection error: %@", [connectionError description]);
                               }
                               
                               if ( [response isKindOfClass: [NSHTTPURLResponse class]] && [((NSHTTPURLResponse*) response) statusCode] != 200) {
                                   NSLog(@"AppLovin retargeting notification failed - invalid product IDs, package name or SDK key provided.");
                               }
                           }];
    
}

#pragma mark ALAdLoadDelegate

-(void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad
{
    SNSLog(@"ad loaded");
    if([ad.type isEqual: [ALAdType typeIncentivized]])
    {
        // do nothing
        isRewardVideoReady = YES; isRewardVideoLoading = NO;
        // [self startPlayVideo];
        videoAd = [ad retain];
    }
    else {
        isAdLoading = NO;
        isAdReady = YES;
        pengdingAd = [ad retain];
        if(shouldPopupAd) {
            [self showPopupOffer];

        }
    }
    isAdClicked = NO;
}

-(void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code
{
    SNSLog(@"fail to load ad:%d", code);
    isAdLoading = NO; isRewardVideoLoading = NO;
}

#pragma mark -

#pragma mark ALAdRewardDelegate

-(void) rewardValidationRequestForAd:(ALAd *)ad didSucceedWithResponse:(NSDictionary *)response
{
    // AppLovin servers validated the reward. Refresh user balance from your server.
    // We will also pass the number of coins awarded and the name of the currency.
    // However, ideally, you should verify this with your server before granting it.
    SNSLog(@"reward video loaded:%@", response);
    
    NSString* currencyName = [[response objectForKey: @"currency"] lowercaseString];
    NSString* amountGiven = [response objectForKey: @"amount"];
    int count = [amountGiven integerValue];
    if(count>0) {
        int type = [[SystemUtils getGlobalSetting:@"kApplovinCoinType"] intValue];
        if(type==0) type = [[SystemUtils getSystemInfo:@"kApplovinCoinType"] intValue];
        if(type==0) {
            if([currencyName length]>4) currencyName = [currencyName substringToIndex:4];
            if([currencyName isEqualToString:@"coin"]) type = kGameResourceTypeCoin;
            if(type==0 && [currencyName isEqualToString:@"gold"]) type = kGameResourceTypeCoin;
            currencyName = [currencyName substringToIndex:3];
            if(type==0 && [currencyName isEqualToString:@"gem"])  type = kGameResourceTypeLeaf;
        }
        if(type>0)
            [[SystemUtils getGameDataDelegate] addGameResource:count ofType:type];
    }
}

-(void) rewardValidationRequestForAd:(ALAd *)ad didExceedQuotaWithResponse:(NSDictionary *)response
{
    SNSLog(@"reward video exceed quota:%@", response);
    // User watched video but has already earned the maximum number of coins you specified in the UI.
}

-(void) rewardValidationRequestForAd:(ALAd *)ad wasRejectedWithResponse:(NSDictionary *)response
{
    SNSLog(@"reward video rejected:%@", response);
    // The user's reward was marked as fraudulent, they are most likely trying to modify their balance illicitly.
}

-(void) rewardValidationRequestForAd:(ALAd *)ad didFailWithError:(NSInteger)responseCode
{
    SNSLog(@"reward video failed:%d", responseCode);
    // We were unable to contact the server. Grant the reward, or don't, as you see fit.
}

-(void) userDeclinedToViewAd: (ALAd*) ad
{
    SNSLog(@"reward video declined");
    // When prompted, the user decided they did not want to view a rewarded video.
}

#pragma mark -
#pragma mark ALAdDisplayDelegate

/**
 * This method is invoked when the ad is displayed in the view.
 * <p>
 * This method is invoked on the main UI thread.
 *
 * @param ad     Ad that was just displayed. Guranteed not to be null.
 * @param view   Ad view in which the ad was displayed. Guranteed not to be null.
 */
-(void) ad:(ALAd *) ad wasDisplayedIn: (UIView *)view
{
    SNSLog(@"ALAd displayed");
    isAdShowing = YES; isAdClicked = NO;
}

/**
 * This method is invoked when the ad is hidden from in the view. This occurs
 * when the ad is rotated or when it is explicitly closed.
 * <p>
 * This method is invoked on the main UI thread.
 *
 * @param ad     Ad that was just hidden. Guranteed not to be null.
 * @param view   Ad view in which the ad was hidden. Guranteed not to be null.
 */
-(void) ad:(ALAd *) ad wasHiddenIn: (UIView *)view
{
    if(showAdType==0) {
        if(isAdClicked)
        {
            [SystemUtils resetIgnoreAdCount];
        }
        else
        {
            SNSLog(@"Ad not click");
            [SystemUtils addIgnoreAdCount];
        }
        [pengdingAd release];
        pengdingAd = nil;
        isAdReady = NO;
        [self loadAdOffer];
    }
    if(showAdType==1) {
        [videoAd release];
        videoAd = nil;
        isRewardVideoReady = NO;
        [self loadRewardVideo];
    }
    isAdShowing = NO;
}

/**
 * This method is invoked when the ad is clicked from in the view.
 * <p>
 * This method is invoked on the main UI thread.
 *
 * @param ad     Ad that was just clicked. Guranteed not to be null.
 * @param view   Ad view in which the ad was hidden. Guranteed not to be null.
 */
-(void) ad:(ALAd *) ad wasClickedIn: (UIView *)view
{
    SNSLog(@"ALAd clicked");
    isAdClicked = YES;
}

/**
 * This method is invoked when a video starts playing in an ad.
 *
 * This method is invoked on the main UI thread.
 *
 * @param ad Ad in which video playback began.
 */
-(void) videoPlaybackBeganInAd: (ALAd*) ad
{
    [self pauseGamePlay];
}

/**
 * This method is invoked when a video stops playing in an ad.
 *
 * This method is invoked on the main UI thread.
 *
 * @param ad             Ad in which video playback ended.
 * @param percentPlayed  How much of the video was watched, as a percent.
 * @param fullyWatched   Whether or not the video was watched to, or very near to, completion.
 *                       This can be used for incentivized advertising, for example to award your
 *                       users virtual in-game currency if the video ad was fully viewed.
 */
-(void) videoPlaybackEndedInAd: (ALAd*) ad atPlaybackPercent:(NSNumber*) percentPlayed fullyWatched: (BOOL) wasFullyWatched
{
    [self resumeGamePlay];
}


@end
