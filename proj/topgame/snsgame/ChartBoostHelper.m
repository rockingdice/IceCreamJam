//
//  ChartBoostHelper.m
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "ChartBoostHelper.h"
#import "SystemUtils.h"

@implementation ChartBoostHelper

static ChartBoostHelper *_gChartBoostHelper = nil;

+ (ChartBoostHelper *) helper
{
    if(!_gChartBoostHelper) {
        _gChartBoostHelper = [[ChartBoostHelper alloc] init];
        // [_gChartBoostHelper initSession];
    }
    return _gChartBoostHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO;
    }
    return self;
}

- (void) initSession
{
    if(isInitialized) return;
    SNSLog(@"start chartboost");
	NSString *appID = [SystemUtils getSystemInfo:kChartBoostAppID];
	if(!appID) return;
    isInitialized = YES;
	// Configure ChartBoost
    Chartboost *cb = [Chartboost sharedChartboost];
    cb.appId = appID;
    cb.appSignature = [SystemUtils getSystemInfo:kChartBoostAppSig];
    cb.delegate = self;
	
    // Notify an install
    [cb startSession];
    [self loadCacheOffer];
	
}

- (BOOL) showChartBoostOffer
{
    if(!isInitialized)
        [self initSession];
    if(![[Chartboost sharedChartboost] hasCachedInterstitial]) {
        [[Chartboost sharedChartboost] cacheInterstitial];
        return NO;
    }
    // Load interstitial
    [[Chartboost sharedChartboost] showInterstitial];
    return YES;
}
- (void) showPopupOffer
{
    if(!isInitialized)
        [self initSession];
    [[Chartboost sharedChartboost] showInterstitial];
}


- (void) loadCacheOffer
{
    [[Chartboost sharedChartboost] cacheInterstitial];
}

- (BOOL) hasCachedOffer
{
    return [[Chartboost sharedChartboost] hasCachedInterstitial];
}

#pragma mark ChartBoostDelegate

- (BOOL)shouldDisplayInterstitial:(UIView *)interstitialView
{
    return [SystemUtils getInterruptMode];
}

/// Same as above, but only called when dismissed for a close
- (void)didCloseInterstitial:(NSString *)location
{
    [SystemUtils addIgnoreAdCount];
}

/// Same as above, but only called when dismissed for a click
- (void)didClickInterstitial:(NSString *)location
{
    [SystemUtils resetIgnoreAdCount];
}

/// Called when the user dismisses the more apps view
/// If you are displaying the add yourself, dismiss it now.
- (void)didDismissMoreApps
{
    
}

/// Same as above, but only called when dismissed for a close
- (void)didCloseMoreApps
{
    
}

/// Same as above, but only called when dismissed for a click
- (void)didClickMoreApps
{
    
}


#pragma mark -

@end
