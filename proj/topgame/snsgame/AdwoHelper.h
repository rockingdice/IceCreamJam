//
//  LiMeiHelper.h
//  
//  require framework: MapKit,EventKit,EventKitUI,CoreLocation
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZKcmoneZkcmtwo.h"
#import "AdwoAdSDK.h"

@interface AdwoHelper : NSObject<AWAdViewDelegate> {
	BOOL isSessionInitialized;
    BOOL isOfferLoaded;
    BOOL isOfferShowing;
    NSString  *stAppKey;
    int pendingCoins;
    
    UIView *mAdView;
    BOOL hasAdLoaded;
}


+(AdwoHelper *)helper;

// 显示弹窗
- (void) showInterstitial;

// 显示Offer
-(void) showOffers;

// hide offers
-(void) hideOffers;

-(void) initSession;

// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy;

-(void) checkPoints;

-(BOOL) isOfferReady;

@end
