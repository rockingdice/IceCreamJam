//
//  LiMeiHelper.h
//  
//  require framework: MapKit,EventKit,EventKitUI,CoreLocation
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Eadver/HMCustomScore.h>
#import <Eadver/HMUserMessage.h>
#import <Eadver/HMInitServer.h>

#import <Eadver/HMRecoAd.h>
#import <Eadver/HMIntegralScore.h>
#import <Eadver/HMInterstitial.h>
#import <Eadver/HMScore.h>
#import <Eadver/HMRecommendWeb.h>
#import <Eadver/HMScoreWeb.h>


@interface YijifenHelper : NSObject<HMAdRecoDelegate,HMInterstitialDelegate,HMIntegralScoreDelegate,HMCustomScoreDelegate> {
	BOOL isSessionInitialized;
    
    int  offerStatus; // 1-loading, 2-ready, 3-failed, 4-showing

    int  interstitialStatus; // 1-loading, 2-ready, 3-failed, 4-showing
    
    NSString  *stAppKey;
    int pendingCoins;
}


+(YijifenHelper *)helper;

// 显示Offer
- (void) showOffers;

// 显示弹窗
- (void) showInterstitial;

// hide offers
-(void) hideOffers;

-(void) initSession;

// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy;

-(void) checkPoints;

-(BOOL) isOfferReady;

@end
