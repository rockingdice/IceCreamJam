//
//  SnsGameHelper.h
//  DreamTrain
//
//  Created by XU LE on 12-4-20.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "GameDataDelegate.h"
#import "ASINetworkQueue.h"
#import "InAppStoreDelegate.h"
#import "FacebookHelperDelegate.h"

@interface SnsGameHelper : NSObject<GameDataDelegate,InAppStoreDelegate, FacebookHelperDelegate>
{
    BOOL showDailyBonus;
    
    NSDictionary *m_iapItemList;
    NSMutableDictionary *m_extraInfo;
    
    char data_hash[CC_MD5_DIGEST_LENGTH];
    
	ASINetworkQueue *networkQueue;
    // NSString *stBattleServiceRoot;
    int  m_popupShown;
    int  currentLevelID;
}

+(SnsGameHelper *)helper;

// 验证加载的存档信息是否有效
+ (BOOL) verifyLoadedSaveInfo:(NSString *)info;

// DES加密
+ (NSString *) encryptDESData:(NSData *)plainData key:(NSString *)key;
// DES解密
+ (NSString *) decryptDES:(NSString *)desStr key:(NSString *)key zip:(int)usezip;

// 发放每日奖励
- (void) updateDailyBonusStatus:(NSNotification *)note;

// 发放邀请奖励
- (void) onSendInvitationEmailFinish:(NSNotification *)note;

// Facebook 登陆成功通知服务器绑定
- (void) onLoginFinish:(NSNotification *)note;

// 发送Facebook Feed
- (void) sendFacebookInvitation;
// facebook登陆成功
- (void) facebooLoginSuccess;
// facebook登陆成功
- (void) facebooFeedSuccess;

// 添加奖励的接口

// 加载IAP列表
- (void) loadIapItemList:(BOOL) forceReload;
// 获取IAP道具对应的购买数量
- (int)  getIapItemQuantity:(NSString *)ID;
// 加载游戏数据
- (void) loadGameData;

// 购买某个IAP道具
- (void) buyIapItem:(const char *)itemID;

// 进入后台运行
- (void) onApplicationGoesToBackground;

// 从后台运行恢复
- (void) onApplicationResumeFromBackground;

// 获取自己当前登陆的FaceBook帐号信息
+ (NSDictionary *) getFaceBookInfo;

// 获取好友列表
- (void) onGetAllFacebookFriends:(NSArray *)friends withError:(NSError *)error;

// 显示广告offer
- (void) showOfferWall:(NSString *)offerType;
// 显示弹窗广告
- (void) showPopupOffer;

@end
