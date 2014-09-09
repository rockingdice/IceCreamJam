//
//  ChartBoostHelper.h
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ADCADCPowerWallViewControllerDelegate.h"

@class ADCPowerWallViewController;

@interface AppDriverHelper : NSObject <ADCADCPowerWallViewControllerDelegate>
{
    BOOL    isInitialized;
    
    ADCPowerWallViewController *_powerWallViewController;
    
    NSString *siteID;
    NSString *siteKey;
    NSString *mediaID;
}

+ (AppDriverHelper *) helper;

- (void) initSession;

- (void) showOffer;

// - (void) loadCacheOffer;

// - (BOOL) hasCachedOffer;

// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy;

-(void) checkPoints;

-(BOOL) isOfferReady;

@end
