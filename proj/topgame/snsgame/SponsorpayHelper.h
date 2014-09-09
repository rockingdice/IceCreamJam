//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPBrandEngageClient.h"
#import "SPOfferWallViewController.h"
#import "SPInterstitialViewController.h"
#import "SPVirtualCurrencyServerConnector.h"

@class SponsorPayViewController;
@class ASIFormDataRequest;

@interface SponsorPayHelper : NSObject<SPBrandEngageClientDelegate, SPVirtualCurrencyConnectionDelegate, SPOfferWallViewControllerDelegate, SPInterstitialViewControllerDelegate>
{
    BOOL    isInitialized;
    BOOL    isVideoEnabled;
    BOOL    isVideoReady;
    SponsorPayViewController *viewController;
    SPBrandEngageClient *_brandEngageClient;
    ASIFormDataRequest  *req;
    NSArray  *arrayInfo;
}

+ (SponsorPayHelper *) helper;

- (void) initSession;

- (void) showOfferWall;

- (void) showPopupOffer;

- (void) showVideoOffer;

- (void) clearViewController;

- (void) playVideoFinished;


- (void) checkCoins;
-(void)getRewardsLazy;

@end


@interface SponsorPayViewController : UIViewController<SPOfferWallViewControllerDelegate, SPInterstitialViewControllerDelegate>



@end