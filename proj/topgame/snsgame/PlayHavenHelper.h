//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayHavenSDK.h"

@interface PlayHavenHelper : NSObject<PHPublisherContentRequestDelegate>
{
    BOOL    isInitialized;
    BOOL    isEnabled;
    BOOL    hasOffer;
    NSString *m_phToken;
    NSString *m_phSecret;
    PHPublisherContentRequest  *offerRequest;
    BOOL   hasFeatureApp;
    PHPublisherContentRequest  *featureRequest;
}

+ (PlayHavenHelper *) helper;

- (void) initSession;

- (BOOL) showOffer:(BOOL)showNoOfferHint;

- (BOOL) showFeaturedApp;

@end
