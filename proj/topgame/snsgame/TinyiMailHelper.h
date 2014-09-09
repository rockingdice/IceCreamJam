//
//  TapjoyHelper.h
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SNSLogType.h"
#import "SNSAlertView.h"
#ifdef SNS_USE_ADDRESSBOOK_UI
#import <AddressBookUI/AddressBookUI.h>
#endif

#define kNotificationTinyiMailCheckStatusDone @"kNotificationTinyiMailCheckStatusDone"
#define kTinyiMailSecretKey @"dfwe234gdgit8"

enum {
    kTinyiMailStatusNone,  //0-尚未初始化
    kTinyiMailStatusEmailReady, //1-已经输入邮件
    kTinyiMailStatusEmailSent,  //2－已经发出验证邮件
    kTinyiMailStatusEmailVerified, //3－已经验证成功
};

@interface TinyiMailHelper : NSObject<SNSAlertViewDelegate 
#ifdef SNS_USE_ADDRESSBOOK_UI
,ABPeoplePickerNavigationControllerDelegate 
#endif
> {
	BOOL isSessionInitialized;
    BOOL isNoticeShown;
    int  iVerifyPrizeLeaf;
    BOOL isShowingPopupBox;
    BOOL isServerOK;
    id   pMailComposer;
    BOOL isFirstTime;
    id   pAddressBookPicker;
    int  nWriteEmailStatus; // 1-subscription, 2-invitation
    NSString *m_emailGiftQuery;
}

@property(nonatomic,readonly) int iVerifyPrizeLeaf;
@property(nonatomic,assign) BOOL isServerOK;

+(TinyiMailHelper *)helper;

-(void) initSession;


// 获取用户信息，email,userID,status,clientStatus,inviteCode(我的邀请码，2位数）,friendCode（朋友邀请码，N位数） 
- (NSDictionary *) getTinyiMailInfo;
- (void) updateTinyiMailInfo:(NSDictionary *)info;
- (id) getTinyiMailObject:(id)key;
- (void) setTinyiMailObject:(id)obj forKey:(id)key;
// 0－
- (int) getTinyiMailStatus;
// 判断是否注册成功
-(BOOL)isRegistered; 
// 判断是否填写了邀请码
-(BOOL)hasFriendCode; 


// 显示获奖通知
- (void) showTinyiMailPrize:(NSArray *)arr;
// 开始检查服务器
- (void) startCheckStatus:(BOOL)forceCheck;
// 更新服务器状态
- (void) reloadServerStatus;

// 发放验证成功奖励
- (void) giveVerifySuccessPrize;

// 检查状态完成
- (void) onStatusCheckDone:(NSNotification *)note;

// 显示iMail窗口，forceShow－强制显示，不检查限制规则
// 返回值：YES－有显示，NO－无显示
- (BOOL) showiMailPopupBox:(BOOL)forceShow;
// 关闭iMail窗口时调用
- (void) closeiMailPopupBox;

// start notice info
- (void) showGameNotice;

// 发验证邮件
-(void) writeVerifyEmail;
//-(void) showSentHint;
// 完成发送邮件
-(void) onComposeEmailFinished:(NSNotification *)note;

// 设置默认邮箱
-(void) setDefaultEmail:(NSString *)email;

// 显示邀请好友功能
- (void) showInviteFriendsPopup:(BOOL)forceShow;
// 显示输入邀请码功能
- (void) showEnterInviteCode:(BOOL)forceShow;

// 发邀请邮件
-(void) writeInvitationEmail;
// 获得邀请码
-(NSString *)getInviteCode;
// 检查并发放邀请奖励
-(void) checkInvitationBonus;
// 发送邀请邮件，emails是一个由Email字符串组成的Array
- (void) sendInvitationEmail:(NSArray *)friends;

// 发送礼物邮件
- (void) writeGiftEmail;
// 启动发送邮件界面
- (void) sendGiftEmail:(NSArray *)emails;
// 获得礼物连接验证码
- (NSString *)getGiftHash:(NSString *)info;
// 接收邮件礼物奖励
- (void) onReceiveEmailGift:(NSString *)query;
// 发放邮件礼物
- (void) checkEmailGift;


@end
