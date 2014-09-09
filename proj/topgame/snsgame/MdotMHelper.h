//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MdotMInterstitial.h"

@interface MdotMHelper : NSObject<MdotMInterstitialDelegate>
{
    BOOL    isInitialized;
    BOOL    isEnabled;
    BOOL    hasOffer;
    
    MdotMInterstitial *intlView;
}

+ (MdotMHelper *) helper;

- (void) initSession;

- (BOOL) showOffer:(BOOL)showNoOfferHint;


@end
