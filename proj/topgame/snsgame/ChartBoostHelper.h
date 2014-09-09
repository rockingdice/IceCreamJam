//
//  ChartBoostHelper.h
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Chartboost.h"

@interface ChartBoostHelper : NSObject <ChartboostDelegate>
{
    BOOL    isInitialized;
}

+ (ChartBoostHelper *) helper;

- (void) initSession;

- (BOOL) showChartBoostOffer;

- (void) loadCacheOffer;

- (BOOL) hasCachedOffer;

- (void) showPopupOffer;

@end
