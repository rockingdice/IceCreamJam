//
//  ChartBoostHelper.m
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "FAADNetworkHelper.h"
#import "SystemUtils.h"
#import "FAADNetwork.h"
#import "SNSAlertView.h"
#import "smPopupWindowQueue.h"

@implementation FAADNetworkHelper

static FAADNetworkHelper *_gFAADNetworkHelper = nil;

+ (FAADNetworkHelper *) helper
{
    if(!_gFAADNetworkHelper) {
        _gFAADNetworkHelper = [[FAADNetworkHelper alloc] init];
    }
    return _gFAADNetworkHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO;
        isEnabled = NO;
        hasOffer  = NO;
    }
    return self;
}

- (void) initSession
{
    if(isInitialized) return;
    isInitialized = YES;
    
    NSString *key = [SystemUtils getSystemInfo:kFAADNetworkKey];
    NSString *secret = [SystemUtils getSystemInfo:kFAADNetworkSecret];
    if(key && secret && [key length]>10 && [secret length]>10)
    {
        isEnabled = YES;
        [[FAADNetwork sharedFAADNetwork] connectWithIntegrationKey:key andSecretKey:secret];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(faadFeedsReceived:) name:@"kNotificationFAADGetFeeds" object:nil]; 
        [[FAADNetwork sharedFAADNetwork] getNetworkFeeds:@"kNotificationFAADGetFeeds"]; 
    }
}

- (void) showFAADOffer:(BOOL)showNoOfferHint
{
    if(!isInitialized) 
        [self initSession];
    SNSLog(@"isEnabled:%i interruptMode:%i hasOffer:%i", isEnabled, [SystemUtils getInterruptMode], hasOffer);
    if(!isEnabled || ![SystemUtils getInterruptMode] || !hasOffer) {
        if(showNoOfferHint) {
            // TODO: show no offer hint
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
        }
        return;
    }
    UIDeviceOrientation o = [SystemUtils getGameOrientation];
    if(o == UIDeviceOrientationLandscapeLeft || o == UIDeviceOrientationLandscapeRight)
    {
        [[FAADNetwork sharedFAADNetwork] displayLandscapeAdsWithStatusBar:NO];
    }
    else {
        [[FAADNetwork sharedFAADNetwork] displayPortraitAdsWithStatusBar:NO];
    }
}

- (void) faadFeedsReceived:(NSNotification *)note
{
    NSArray *feeds = note.object;
    NSLog(@"%s: feed info:%@", __func__, feeds);
    // NSDictionary *feed = nil; 
    if(feeds && [feeds isKindOfClass:[NSArray class]] && [feeds count]>0)
    { 
        // feed = [feeds objectAtIndex:0]; 
        hasOffer = YES;
    } else { 
        // disable Feed interface 
        hasOffer = NO;
    } 
}


@end
