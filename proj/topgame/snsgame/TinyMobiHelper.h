//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TinyMobiDelegate.h"

@interface TinyMobiHelper : NSObject<TinyMobiDelegate>
{
    BOOL    isInitialized;
    BOOL    isCheckingRewards;
    NSMutableDictionary *rewardsIDList;
}

+ (TinyMobiHelper *) helper;

- (void) initSession;

- (void) resetSession;

// 显示广告墙
- (void) showOffer;
// 显示一天只有1次的弹窗广告, 如果显示成功，返回YES，如果没有广告，返回NO
- (BOOL) showPopupAd;
- (void) checkRewards;

- (void) loadCacheOffer;

- (BOOL) hasCachedOffer;

- (BOOL) showMoreGames;

- (BOOL) isRewardIDExists:(NSString *)rewardID;
- (void) addRewardID:(NSString *)rewardID;
@end
