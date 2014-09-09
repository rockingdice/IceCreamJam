//
//  ChartBoostHelper.m
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "iAdHelper.h"
#import "SystemUtils.h"
#import "AppLovinHelper.h"
#ifdef SNS_ENABLE_LIMEI2
#import "LiMeiHelper2.h"
#endif

@implementation iAdHelper

static iAdHelper *_giAdHelper = nil;

+ (iAdHelper *) helper
{
    if(!_giAdHelper) {
        _giAdHelper = [[iAdHelper alloc] init];
        // [_gChartBoostHelper initSession];
    }
    return _giAdHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO; adStatus = 0;
    }
    return self;
}

- (void) dealloc
{
    [interstitial release];
    [super dealloc];
}

- (void) initSession
{
    if(isInitialized) return;
    if(![SystemUtils isiPad]) return;
    SNSLog(@"start iad sdk");
	int val = [[SystemUtils getGlobalSetting:@"kEnableiAd"] integerValue];
	if(val==0) val = [[SystemUtils getSystemInfo:@"kEnableiAd"] integerValue];
    if(val!=1) return;
    isInitialized = YES;
	interstitial = [[ADInterstitialAd alloc] init];
    interstitial.delegate = self;
}


- (void) showPopupOffer
{
    if(![SystemUtils isiPad] || adStatus!=1) {
#ifdef SNS_ENABLE_LIMEI2
        if([[SystemUtils getCountryCode] isEqualToString:@"CN"]) {
            [[LiMeiHelper2 helper] showOffers];
            return;
        }
#endif
        [[AppLovinHelper helper] showPopupOffer];
        return;
    }
    if(adStatus!=1) return;
    if(!isInitialized)
        [self initSession];
    UIViewController *root = [SystemUtils getRootViewController];
    // [MIXView showAdWithDelegate:self withPlace:@"default" viewController:root];
    if (interstitial.loaded)
    {
        adStatus = 2;
        [interstitial presentFromViewController:root];
    }
    else {
        // just wait
    }
}



#pragma mark ADInterstitialAdDelegate

/*!
 * @method interstitialAdDidUnload:
 *
 * @discussion
 * When this method is invoked, if the application is using -presentInView:, the
 * content will be unloaded from the container shortly after this method is
 * called and no new content will be loaded. This may occur either as a result
 * of user actions or if the ad content has expired.
 *
 * In the case of an interstitial presented via -presentInView:, the layout of
 * the app should be updated to reflect that an ad is no longer visible. e.g.
 * by removing the view used for presentation and replacing it with another view.
 */
- (void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd
{
    [interstitial release];
    interstitial = [[ADInterstitialAd alloc] init];
    interstitial.delegate = self; adStatus = 0;
}

/*!
 * @method interstitialAd:didFailWithError:
 *
 * @discussion
 * Called when an error has occurred attempting to get ad content.
 *
 * @see ADError for a list of possible error codes.
 */
- (void)interstitialAd:(ADInterstitialAd *)interstitialAd didFailWithError:(NSError *)error
{
    adStatus = 0;
}

/*!
 * @method interstitialAdWillLoad:
 *
 * @discussion
 * Called when the interstitial has confirmation that an ad will be presented,
 * but before the ad has loaded resources necessary for presentation.
 */
- (void)interstitialAdWillLoad:(ADInterstitialAd *)interstitialAd
{
    
}

/*!
 * @method interstitialAdDidLoad:
 *
 * @discussion
 * Called when the interstitial ad has finished loading ad content. The delegate
 * should implement this method so it knows when the interstitial ad is ready to
 * be presented.
 */
- (void)interstitialAdDidLoad:(ADInterstitialAd *)interstitialAd
{
    adStatus = 1;
}

/*!
 * @method interstitialAdActionShouldBegin:willLeaveApplication:
 *
 * @discussion
 * Called when the user chooses to interact with the interstitial ad.
 *
 * The delegate may return NO to block the action from taking place, but this
 * should be avoided if possible because most ads pay significantly more when
 * the action takes place and, over the longer term, repeatedly blocking actions
 * will decrease the ad inventory available to the application.
 *
 * Applications should reduce their own activity while the advertisement's action
 * executes.
 */
- (BOOL)interstitialAdActionShouldBegin:(ADInterstitialAd *)interstitialAd willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

/*!
 * @method interstitialAdActionDidFinish:
 * This message is sent when the action has completed and control is returned to
 * the application. Games, media playback, and other activities that were paused
 * in response to the beginning of the action should resume at this point.
 */
- (void)interstitialAdActionDidFinish:(ADInterstitialAd *)interstitialAd
{
    
}



#pragma mark -

@end
