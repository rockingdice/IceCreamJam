//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AlSdk.h"
#import "ALAdRewardDelegate.h"

@interface AppLovinHelper : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate, ALAdRewardDelegate,ALAdVideoPlaybackDelegate>
{
    BOOL    isInitialized;
    BOOL    isAdReady;
    BOOL    isAdShowing;
    BOOL    isAdLoading;
    ALAd    *pengdingAd;
    int     currentAdType; // 0-normal, 1-video
    BOOL    isRewardVideoReady;
    BOOL    isRewardVideoLoading;
    BOOL    isPausingAudio;
    BOOL    isAdClicked;
    int     showAdType; // 0-normal, 1-video
    ALAd    *videoAd;
    BOOL    shouldPopupAd;
}

+ (AppLovinHelper *) helper;

- (void) initSession;

- (BOOL) showPopupOffer;

- (BOOL) showPopupOfferNotice;

// 显示带奖励的视频
- (BOOL) showRewardVideoOffer;
- (BOOL) isRewardVideoLoaded;
- (void) loadRewardVideo;
@end
