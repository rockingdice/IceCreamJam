//
//  BindEmailHelper.h
//  FarmSlots
//
//  Created by Leon Qiu on 8/14/14.
//
//

#import <Foundation/Foundation.h>

enum {
    kBindHelperStatusGameStart = 1,
    kBindHelperStatusGameLoaded,
};

@interface BindEmailHelper : NSObject
{
    NSString *_email;
    NSString *_pass;
    NSString *_inputEmail;
    NSString *_inputPass;
    
    int    mailUID;
    
    BOOL _isDataUpdateAppending;
    BOOL _isDataGetAppending;
    
}

//optional string token = 3;  // 以后用于通信的验证串
//optional string secret = 4; // 存放于本地，用于签名，方法为hmac(md5)
//optional int32 uid = 5;     // 服务器端生的序列ID，可选使用
@property (retain, nonatomic) NSString *_token;
@property (retain, nonatomic) NSString *_secret;
@property (retain, nonatomic) NSString *_uid;
@property (assign, nonatomic) int gameStatus;

+ (BindEmailHelper *) helper;

- (id) init;
- (void) initSession;

- (BOOL) isLoggedIn;

- (void) promptForEmail;

- (void) syncSaveData;

- (void)showBindEmailTip;

- (BOOL)isBindEmailVisiable;

- (void)createAuth;
- (void)updateData;
- (void) updateDataLazy;
- (void)getRemoteData;

@end
