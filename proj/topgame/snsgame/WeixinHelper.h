//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WXApi.h"

@interface WeixinHelper : NSObject<WXApiDelegate>
{
    BOOL    isInitialized;
    BOOL    isAdReady;
    int     _scene;
    NSDictionary *weixinInfo;
    int     currentRequestType; // 0-分享到朋友圈，1-邀请好友
}

+ (WeixinHelper *) helper;

- (void) initSession;

- (BOOL) handleOpenURL:(NSURL *)url;


- (void) shareToFriends;

// 邀请好友
- (void) inviteFriend;
// 分享到朋友圈
- (void) publishNote;
// 添加好友
- (void) addFriend;
// 邀请获得无限体力
- (void) unlimitLife;
// 是否已经连接过了
- (BOOL) hasConnected;

// 今天的邀请次数
- (int) getTodayInviteCount;
// 今天发布到朋友圈的次数
- (int) getTodayPublishCount;

// 今天是否已经获得奖励了
- (BOOL) hasGotTodayPrize;
// 今天是否已经获得第2次奖励了
- (BOOL) hasGotTodayInvitePrize;

// 打开微信
- (void) openWeixinApp;

- (void)publishCustomerFeed:(NSString *)imagePath;
@end
