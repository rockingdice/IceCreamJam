//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlurryAdDelegate.h"
#import "ASIFormDataRequest.h"

@interface FlurryHelper2 : NSObject <FlurryAdDelegate>
{
    BOOL    isInitialized;
    UIViewController *root;
	NSArray *arrayInfo;
    ASIFormDataRequest *req;
    NSString *adSpace1;
    NSString *adSpace2;
    int      adSpace1Status; // 1-fetching offer, 2-ready for show
    int      adSpace2Status;
}

+ (FlurryHelper2 *) helper;

- (void) initSession;

- (BOOL) showOffer;
- (BOOL) showOffer2;

- (void) getRewardsLazy;
- (void) loadAdSpace;

@end
