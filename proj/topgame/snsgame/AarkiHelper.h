//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AarkiOfferLoader;
@class ASIFormDataRequest;

@interface AarkiHelper : NSObject
{
    BOOL    isInitialized;
    NSString *popupPlacementID;
    AarkiOfferLoader *offerLoader;
    ASIFormDataRequest  *req;
    NSArray  *arrayInfo;
}

+ (AarkiHelper *) helper;

- (void) initSession;

- (void) showPopupOffer;
- (void) showVideoOffer;
- (void) showOfferWall;

-(void)getRewardsLazy;

@end
