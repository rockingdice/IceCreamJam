//
//  ChartBoostHelper.h
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FAADNetworkHelper : NSObject 
{
    BOOL    isInitialized;
    BOOL    isEnabled;
    BOOL    hasOffer;
}

+ (FAADNetworkHelper *) helper;

- (void) initSession;

- (void) showFAADOffer:(BOOL)showNoOfferHint;

- (void) faadFeedsReceived:(NSNotification *)note;

@end
