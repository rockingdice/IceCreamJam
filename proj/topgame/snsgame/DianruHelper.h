//
//  LiMeiHelper.h
//  
//  require framework: MapKit,EventKit,EventKitUI,CoreLocation
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DianRuAdWall.h"

@interface DianruHelper : NSObject<DianRuAdWallDelegate> {
	BOOL isSessionInitialized;
    BOOL isOfferLoaded;
    BOOL isOfferShowing;
    NSString  *stAppKey;
    int pendingCoins;
    // UINavigationController *container;
}


+(DianruHelper *)helper;

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
