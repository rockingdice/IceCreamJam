//
//  LiMeiHelper.h
//  
//  require framework: MapKit,EventKit,EventKitUI,CoreLocation
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "immobSDK/immobView.h"

#define LIMEI_SHOW_BOX_CLOSE_NOTIFICATION  @"kLIMEI_ShowBoxClose"

@interface LiMeiHelper2 : NSObject<immobViewDelegate> {
	NSMutableArray *pendingActions;
	BOOL isSessionInitialized;
    immobView * pLimeiView;
    NSString  *stAppKey;
    immobView * pPopupView;
    NSString  *stPopupKey;
    int       adType; // 0-offer wall, 1-interstitial
    int       checkPointType; // 0-offer wall, 1-interstitial
    // UINavigationController *container;
}


+(LiMeiHelper2 *)helper;

// 显示Offer
-(void) showOffers;
// 显示插屏广告
- (void) showInterstitial;

// hide offers
-(void) hideOffers;

-(void) initSession;

// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy;

-(void) checkPoints;

-(BOOL) isOfferReady;

@end
