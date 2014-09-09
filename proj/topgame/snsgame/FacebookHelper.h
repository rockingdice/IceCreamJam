//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import "FacebookHelperDelegate.h"
#import "KNMultiItemSelector.h"
#import "SNSAlertView.h"

#define kFacebookNotificationOnLoginFinished  @"topgame.kFacebookNotificationOnLoginFinished"
#define kFacebookNotificationOnLoginFaild  @"topgame.kFacebookNotificationOnLoginFaild"
#define kFacebookNotificationOnSelectFriendFinished  @"topgame.kFacebookNotificationOnSelectFriendFinished"
#define kFacebookNotificationOnSendRequestFinished @"topgame.kFacebookNotificationOnSendRequestFinished"
#define kFacebookNotificationOnReceiveTicket  @"topgame.kFacebookNotificationOnReceiveTicket"


@interface FacebookHelper : NSObject<KNMultiItemSelectorDelegate, SNSAlertViewDelegate>
{
    BOOL    isInitialized;
    BOOL    isEnabled;
    int     iSessionStatus;
    int     iInviteCount;
    int     iShowInviteCount;
    int     iSendInviteCount;
    BOOL    isShowingFriends;
    NSMutableDictionary *invitedFriendList;
    NSMutableDictionary *shownFriendList;
    NSDictionary *fbUserInfo;
    int     iTotalFriendCount;
    NSMutableDictionary *allFriendList;
    NSMutableArray  *pendingTasks;
    
    NSMutableArray  *arrKNFriendItems;
    NSMutableArray  *arrKNFriendInvited;
    int iKNInviteCount;
    
    id<FacebookHelperDelegate> delegate;
    
    int    fbUID;
    int    requestType; // 1-binding, 2-loading icon
    
    NSMutableArray *arrPendingTicketRequests;
    NSMutableDictionary *dictPendingTicketID;
}

@property(retain,nonatomic) NSString *fbUserID;
@property(retain,nonatomic) NSString *fbUserName;
@property(retain,nonatomic) NSDictionary<FBGraphUser> *fbUserInfo;

+ (FacebookHelper *) helper;

- (void) initHelper;
- (void) startLogin;
- (void) closeSession;
- (void) checkSessionStatus;
- (void) logout;
- (void) getUserToken;
- (void) startSync;
- (BOOL) isLoggedIn;
- (BOOL) handleOpenURL:(NSURL *)url;

- (void) saveFbUserInfo:(NSDictionary<FBGraphUser> *)info;
- (void) clearFbUserInfo;

- (BOOL) isAllFriendInvited;
- (void) showSelectFriends:(BOOL)onlyInstalled;
// - (void) sendInvitationRequest:(int)count;
- (void) startSendRequest:(NSArray *)userList;
- (BOOL) hasInviteToday;
- (void) publishFeed;
// publish customized feed, info must contain these properties:
// picture: URL address of the picture
// caption: feed caption
// description: detailed description
-(void)publishCustomizedFeed:(NSDictionary *)info;
-(void) publishPhoto:(UIImage *)image withCaption:(NSString *)caption;

- (void) showFacebookPromotionHint;
- (void) showFacebookFeedPrize;
// return YES if has popup, NO if not.
- (BOOL) showFacebookPromotionHintNoHint;
// 检查是否已经获得过连接奖励了
- (BOOL) ifGotConnectPrize;

+ (void) installReport;
- (void) checkIncomingNotification;

- (void) getAllFriends:(id<FacebookHelperDelegate>) handler;
- (void) getAppMessage:(id<FacebookHelperDelegate>) handler;
- (void) getUserInfo:(id<FacebookHelperDelegate>) handler;
- (void) deleteAppRequest:(NSString *)requestID;
// 下载用户头像
- (void) loadFacebookIcon:(NSString *)fbUID;
// 获得本地缓存头像的路径
- (NSString *) getFacebookIconPath:(NSString *)fbUID;

// 每日提醒给朋友送礼物
- (void) sendGiftToFriendsDaily;
// 检查是否曾经connect过
- (BOOL) ifConnectedBefore;

// 发送赠送钥匙请求
- (void) sendTicketRequest:(int)levelID;
// 发送赠送钥匙请求, type-钥匙类型，intVal-对应的数量, req_id－请求的ID, 提示信息的格式为：
// "ticket_request_hint_with_type_1" = "Please help to send me %d coins!";
- (void) sendTicketRequest:(int)intVal ofType:(int)type withID:(int) req_id;
// 发送赠送钥匙回复
- (void) sendTicketReply:(NSDictionary *)reqAction to:(NSDictionary *)friendInfo;

// 从我们自己的服务器加载钥匙，这是同步请求，请通过后台运行
- (void) loadTicketFromServer;
// 发送赠送钥匙记录到我们自己的服务器,
// gift: {"action":"ticketReply","level":1,"uid":123, "sender":{"uid":123,"fbid":"11111","name":"Qiu"}, "replier":{"uid":124,"fbid":"12345668","name":"Leon"}}
- (void) sendTicketReplyToServer:(NSDictionary *)gift;

- (void) sendTestTicketReplyToServer:(int) levelID;

@end
