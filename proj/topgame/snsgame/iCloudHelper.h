//
//  ChartBoostHelper.h
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface iCloudHelper : NSObject
{
    BOOL    isInitialized;
    BOOL    isAvailable;
    int     enableStatus; // 0-未设置，1-允许使用，2-不允许使用
    id      currentToken;
    id      newToken;
    NSURL   *myUbiquityContainer;
    NSMetadataQuery *iCloudQuery;
}

+ (iCloudHelper *) helper;

- (void) initSession;

@end
