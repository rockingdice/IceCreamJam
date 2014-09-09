//
//  TMBUnity.c
//  TMBDemo
//
//  Created by Leon Qiu on 7/23/13.
//
//

#import <Foundation/Foundation.h>
#import "AlSdk.h"
#import "ALInterstitialAd.h"

@interface AppLovinUnityHelper : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate>
{
    BOOL    isInitialized;
    BOOL    isAdReady;
    ALAd    *pengdingAd;
}

+ (AppLovinUnityHelper *) helper;

- (void) initSession;

- (BOOL) showPopupOffer;

@end

// 在游戏启动时调用这个函数初始化applovin
void UnityStartApplovin()
{
    [[AppLovinUnityHelper helper] initSession];
}

// 每跑完5次后调用一下下面这个函数，显示applovin的广告
void UnityShowApplovinOffer()
{
    [[AppLovinUnityHelper helper] showPopupOffer];
}


// 返回绝对的rootViewController
UIViewController * getAbsoluteRootViewController()
{
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	if (!window) {
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	}
    
    UIResponder *nextResponder = [window.subviews lastObject];
    while(nextResponder){
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }else{
            nextResponder = [nextResponder nextResponder];
        }
    }
    
    if(window.rootViewController) {
        return window.rootViewController;
    }
    
	return nil;
}



@implementation AppLovinUnityHelper

static AppLovinUnityHelper *_gAppLovinUnityHelper = nil;

+ (AppLovinUnityHelper *) helper
{
    if(!_gAppLovinUnityHelper) {
        _gAppLovinUnityHelper = [[AppLovinUnityHelper alloc] init];
    }
    return _gAppLovinUnityHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO; isAdReady = NO; pengdingAd = nil;
    }
    return self;
}

- (void) initSession
{
    if(isInitialized) return;
    
    isInitialized = YES;
    ALSdk *sdk = [ALSdk shared];
    [sdk initializeSdk];
    [[sdk adService] loadNextAd:[ALAdSize sizeInterstitial] placedAt:@"POPUP" andNotify:self];
}

- (void) loadAdOffer
{
    [[[ALSdk shared] adService] loadNextAd:[ALAdSize sizeInterstitial] placedAt:@"POPUP" andNotify:self];
}

- (BOOL) showPopupOffer
{
    if(!isInitialized)
        [self initSession];
    
    if(!isInitialized) return NO;
    if(!isAdReady) {
        [self loadAdOffer];
        return NO;
    }
    
    UIViewController *root = getAbsoluteRootViewController();
    if(root==nil) return NO;
    ALInterstitialAd *ad = [ALInterstitialAd shared];
    ad.adDisplayDelegate = self;
    // [ad initInterstitialAdWithSdk:[ALSdk shared]];
    // [ALInterstitialAd showOver:root.view.window];
    [ad showOver:root.view.window andRender:pengdingAd];
    return YES;
}

-(void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad
{
    NSLog(@"ad loaded");
    isAdReady = YES; pengdingAd = [ad retain];
}

-(void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code
{
    NSLog(@"fail to load ad:%d", code);
}

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
    NSLog(@"ALAd displayed");
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
    [pengdingAd release];
    pengdingAd = nil;
    isAdReady = NO;
    [self loadAdOffer];
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
    NSLog(@"ALAd clicked");
}


@end

