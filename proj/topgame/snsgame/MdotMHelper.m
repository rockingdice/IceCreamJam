//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "MdotMHelper.h"
#import "SystemUtils.h"
#import "PlayHavenSDK.h"
#import "SNSAlertView.h"
#import "smPopupWindowQueue.h"
#import "MdotMRequestParameters.h"

@implementation MdotMHelper

static MdotMHelper *_gMdotMHelper = nil;

+ (MdotMHelper *) helper
{
    if(!_gMdotMHelper) {
        _gMdotMHelper = [[MdotMHelper alloc] init];
    }
    return _gMdotMHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO;
        isEnabled = NO;
        hasOffer  = NO;
        intlView = nil;
    }
    return self;
}

- (void) dealloc
{
    if(intlView!=nil) {
        [intlView release]; intlView = nil;
    }
    [super dealloc];
}

- (void) initSession
{
    if(isInitialized) return;
    isInitialized = YES;
    
    NSString *phToken = [SystemUtils getSystemInfo:@"kMdotMAppKey"];
    if(phToken && [phToken length]>10) {
        isEnabled = YES;
        MdotMRequestParameters *requestParameters;
        requestParameters = [[MdotMRequestParameters alloc] init];
        requestParameters.appKey = phToken;
#ifdef DEBUG
        // requestParameters.test = @"1";
#endif
        intlView = [[MdotMInterstitial alloc] init];
        intlView.interstitialDelegate = self;
        [intlView loadInterstitialAd:requestParameters];
        SNSLog(@"loading MdotM offers");
    }
}

- (BOOL) showOffer:(BOOL)showNoOfferHint
{
    if(!isInitialized) 
        [self initSession];
    SNSLog(@"isEnabled:%i interruptMode:%i hasOffer:%i", isEnabled, [SystemUtils getInterruptMode], hasOffer);
    if(!isEnabled || !hasOffer || ![SystemUtils getInterruptMode]) {
        if(showNoOfferHint) {
            // TODO: show no offer hint
            SNSAlertView *av = [[SNSAlertView alloc] 
                                initWithTitle:[SystemUtils getLocalizedString: @"No Offer Now"]
                                message:[SystemUtils getLocalizedString: @"There's no free offer now, please try again later!"]
                                delegate:nil
                                cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                                otherButtonTitle: nil];
            
            av.tag = kTagAlertNone;
            [av showHard];
            [av release];
        }
        return NO;
    }
    UIViewController *root = [SystemUtils getRootViewController];
    if(root==nil) root = [SystemUtils getAbsoluteRootViewController];
    [intlView showInterstitial:root animated:YES];
    return YES;
}


#pragma mark MdotMInterstitialDelegate
-(void) onReceiveInterstitialAd
{
    hasOffer = YES;
    SNSLog(@"Interstitial Ad Received");
}
-(void) onReceiveInterstitialAdError:(NSString *)error
{
    hasOffer = NO;
    SNSLog(@"Interstitial Ad Load Error:%@",error);
}
-(void) onReceiveClickInInterstitialAd
{
    SNSLog(@"Interstitial Ad Download Error..");
}
-(void) willShowModalViewController
{
    
}
-(void) didShowModalViewController
{
    
}
-(void) willDismissModalViewController
{
    
}
-(void) didDismissModalViewController
{
    [intlView release]; intlView = nil;
    isInitialized = NO; hasOffer = NO;
    [self initSession];
}
-(void) willLeaveApplication
{
    
}

#pragma mark -


@end
