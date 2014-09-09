//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PopGame.h"
#import "PopGameDelegate.h"

@interface PopGameHelper : NSObject
{
    BOOL    isInitialized;
    NSDictionary *priceInfo;
}

+ (PopGameHelper *) helper;

- (void) initSession:(NSDictionary *)options;

- (BOOL) recordFee;

@end
