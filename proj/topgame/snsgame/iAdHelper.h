//
//  ChartBoostHelper.h
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <iAd/iAd.h>

@interface iAdHelper : NSObject <ADInterstitialAdDelegate>
{
    BOOL    isInitialized;
    int     adStatus; // 0-loading, 1-loaded, 2-showing
    ADInterstitialAd   *interstitial;
}

+ (iAdHelper *) helper;

- (void) initSession;

- (void) showPopupOffer;

@end
