//
//  ChartBoostHelper.h
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MIXViewDelegate.h"

@interface MixGHHelper : NSObject <MIXViewDelegate>
{
    BOOL    isInitialized;
}

+ (MixGHHelper *) helper;

- (void) initSession;

- (void) showPopupOffer;

@end
