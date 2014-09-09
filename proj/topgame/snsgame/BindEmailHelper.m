//
//  BindEmailHelper.m
//  FarmSlots
//
//  Created by Leon Qiu on 8/14/14.
//
//
/*
 绑定email流程：
 新玩家－》提示绑定email－》请求存档服务器－》绑定成功，保存token，保存email－》提示发送邮件保存email和密码
                        ｜
                        －》绑定失败，email和密码不正确，重新输入
                        ｜
                        －》该email已经绑定了其他账号，提示是否切换账号－》切换账号，保存token，但不保存email, set kForceLoadAWS=1
                           ｜
                           －》不切换账号，提示输入新的email和密码
 
 存档更新流程：
 [SnsServerHelper syncFinished], [SnsServerHelper onApplicationGoesBackground]
 每次启动和退出时，检查上次更新时间 kLastUpdateAWS ，如果比当前时间早12小时以上，就启动更新流程
 ｜
 －》更新成功，保存更新时间 kLastUpdateAWS
 ｜
 －》更新失败，服务器上有新存档，设置 kForceLoadAWS 标识
     ｜
     －》如果还在前台运行，就直接启动下载流程
 
 存档下载流程：
 [SnsServerHelper syncFinished]
 每次启动时，检查 kForceLoadAWS 标识，如果有，就下载存档
 ｜
 －》下载成功，进入游戏，清除kForceLoadAWS标识
 ｜  ｜
 ｜  －》如果已经进入游戏了，就提示已经下载了最新存档，提示退出游戏重新开始
 ｜
 －》下载失败，进入游戏，清除kForceLoadAWS标识
 
 */

#import "BindEmailHelper.h"
#import "SystemUtils.h"
#import "StringUtils.h"
#import "SendEmailViewController.h"
#import "RemoteDataHelper.h"
#import "SnsStatsHelper.h"
#ifdef SNS_HAS_SNS_GAME_HELPER
#import "SnsGameHelper.h"
#endif
#import "SnsServerHelper.h"

#import "ASIFormDataRequest.h"

enum {
    CMAlertTagInputEmail = 1,
    CMAlertTagEmailPassword = 2,
    CMAlertTagSwitchAccount = 3,
    CMAlertTagBindSuccess = 4,
    CMAlertTagPasswordErr = 5,
    CMAlertTagSystemErr = 6,
    CMAlertTagCommonErr = 7,
    CMAlertTagBindTip = 8,
};

#define kBindEmail @"email"
#define kEmailRemoteDataUID @"kEmailRemoteDataUID"

@implementation BindEmailHelper

@synthesize _token,_secret,_uid,gameStatus;

static BindEmailHelper  *_gBindEmailHelper = nil;

+ (BindEmailHelper *) helper
{
    @synchronized(self)
    {
        if(_gBindEmailHelper==nil) {
            _gBindEmailHelper = [[BindEmailHelper alloc] init];
        }
    }
    return _gBindEmailHelper;
}

- (id) init
{
    self = [super init];
    if(self!=nil) {
        _email = nil; _pass = nil;
        _inputPass = nil; _inputEmail = nil;
        self.gameStatus = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(createAuthFinished:)
                                                     name:kRemoteDataHelperNotificationCreateAuthFinished
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateDataFinished:)
                                                     name:kRemoteDataHelperNotificationUpdateDataFinished
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(getDataFinished:)
                                                     name:kRemoteDataHelperNotificationGetDataFinished
                                                   object:nil];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(_email!=nil) [_email release];
    if(_pass!=nil) [_pass release];
    if(_inputPass!=nil) [_inputPass release];
    if(_inputEmail!=nil) [_inputEmail release];
    
    self._token = nil;
    self._secret = nil;
    self._uid = nil;
    
    [super dealloc];
}

- (BOOL)isBindEmailVisiable
{
    BOOL isShowed = [[SystemUtils getNSDefaultObject:@"kIsBindEmailTipShowed"] boolValue];
    if(isShowed) return NO;
    
    int installTime = [[SnsStatsHelper helper] getInstallTime];
    int now = [SystemUtils getCurrentTime];
    return (now-installTime>86400);
}

- (void) initSession
{
    [self readToken];
}

- (void) saveToken
{
    NSDictionary *tokenDict = @{@"uid":self._uid, @"token":self._token, @"secret":self._secret, @"email":_email};
    [SystemUtils setGlobalSetting:tokenDict forKey:@"kRemoteSaveToken"];
}

- (void) readToken
{
    NSDictionary *tokenDict = [SystemUtils getGlobalSetting:@"kRemoteSaveToken"];
    if(tokenDict==nil || ![tokenDict isKindOfClass:[NSDictionary class]]) return;
    self._uid = [tokenDict objectForKey:@"uid"];
    self._token = [tokenDict objectForKey:@"token"];
    self._secret = [tokenDict objectForKey:@"secret"];
    _email = [tokenDict objectForKey:@"email"];
    if(_email!=nil) [_email retain];
}

- (BOOL) isLoggedIn
{
    if(self._token==nil) return NO;
    return YES;
}

- (void) promptForEmail
{
    [self promptForEmailWithHint:@"Enter your email and password:"];
}

- (void) promptForEmailWithHint:(NSString *)hint
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[SystemUtils getLocalizedString: @"Bind Email"] message:hint delegate:self cancelButtonTitle:[SystemUtils getLocalizedString:@"Cancel"] otherButtonTitles:[SystemUtils getLocalizedString:@"Ok"], nil];
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    alertView.tag = CMAlertTagInputEmail;
    UITextField *loginTextField = [alertView textFieldAtIndex:0];
    UITextField *passTextField  = [alertView textFieldAtIndex:1];
    loginTextField.keyboardType = UIKeyboardTypeEmailAddress;
    loginTextField.placeholder = [SystemUtils getLocalizedString: @"Email"];
    if(_inputEmail!=nil) loginTextField.text = _inputEmail;
    if(_inputPass!=nil)  passTextField.text  = _inputPass;
    [alertView show];
}

- (void) syncSaveData
{
    // if(![self isEmailBinded]) return;
    // 与AWS的服务器同步进度
    
}

#pragma mark - request
- (void) startBind
{
    _inputEmail = [_inputEmail lowercaseString];
    [self createAuth];
    /*
	NSString *sessionKey = [SystemUtils getSessionKey];
    if(!sessionKey) {
        return;
    }
    NSString *prefix = [SystemUtils getSystemInfo:@"kHMACPrefix"];
    if(prefix==nil) prefix = @"";
	NSString *link = [NSString stringWithFormat:@"%@bindEmail.php", [SystemUtils getServerRoot]];
    SNSLog(@"link:%@ fbid:%@ sessionKey:%@",link, @"fbid", sessionKey);
	NSURL *url = [NSURL URLWithString:link];

    // 输入参数：sessionKey，email，prefix，ostype（ios＝0，andorid＝1），passwd（玩家密码的md5格式）
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
	[request setPostValue:_inputEmail forKey:@"email"];
    [request setPostValue:[StringUtils stringByHashingStringWithMD5:_inputPass] forKey:@"passwd"];
	[request setPostValue:prefix forKey:@"prefix"];
    [request setPostValue:@"0" forKey:@"osType"];
	[request setPostValue:sessionKey forKey:@"sessionKey"];
    
	[request setDelegate:self];
    [request startAsynchronous];
     */
}

- (void)createAuth{
    [[RemoteDataHelper helper] createAuthWithUUID:_inputEmail secret:kRemoteDataDefaultSecret];
}

// 只在上次上传12小时后才再次上传
- (void) updateDataLazy
{
    int now = [SystemUtils getCurrentTime];
    int lastUpdate = [[SystemUtils getNSDefaultObject:@"kLastUpdateAWS"] intValue];
    if(lastUpdate>now-43200) return;
    [self updateData];
}

- (void)updateData{
    if(self._token == nil || self._secret == nil){
        return;
    }
    
    NSObject<GameDataDelegate> *gameData = [SystemUtils getGameDataDelegate];
    
    NSString *saveInfo = [gameData exportToString];
    if(!saveInfo || [saveInfo length]<3) {
        SNSLog(@"failed to get gamedata.");
        return;
    }
    
    int exp = [gameData getGameResourceOfType:kGameResourceTypeExp];
    int level = [gameData getGameResourceOfType:kGameResourceTypeLevel];
    int leaf = [gameData getGameResourceOfType:kGameResourceTypeLeaf];
    int gold = [gameData getGameResourceOfType:kGameResourceTypeCoin];
    int saveTime = [SystemUtils getCurrentTime];
    // NSString *stats = [SystemUtils getGameStatsTotal];
    // NSString *statsToday = [SystemUtils getGameStatsToday];
    NSString *stats = [StringUtils convertObjectToJSONString:[[SnsStatsHelper helper] exportToDictionary]];
    
    NSString *saveStr = nil;
    
    NSString *userID = [SystemUtils getCurrentUID];
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:7];
    [userInfo setObject:userID forKey:@"UID"];
    [userInfo setObject:[NSNumber numberWithInt:exp] forKey:@"Exp"];
    [userInfo setObject:[NSNumber numberWithInt:level] forKey:@"Level"];
    [userInfo setObject:[NSNumber numberWithInt:leaf] forKey:@"Leaf"];
    [userInfo setObject:[NSNumber numberWithInt:gold] forKey:@"Gold"];
    [userInfo setObject:[NSNumber numberWithInt:saveTime] forKey:@"SaveTime"];
    [userInfo setValue:[SystemUtils getDeviceInfo] forKey:@"deviceInfo"];
    NSString *userStr = [StringUtils convertObjectToJSONString: userInfo];
    saveStr = [NSString stringWithFormat:@"|SNSUserInfo|%i|%@|SAVEDATA|%i|%@|stat2|%i|%@",[userStr length], userStr, [saveInfo length], saveInfo,
               [stats length], stats];
    [userInfo release];
    
    [[RemoteDataHelper helper] updateDataWithToken:self._token
                                              data:saveStr secret:self._secret
                                               cas:exp
                                               key:nil];
}

- (void)getRemoteData{
    if(self._token == nil || self._secret == nil){
        [self createAuth];
        _isDataGetAppending = YES;
    }
    else{
        [[RemoteDataHelper helper] getDataWithToken:self._token secret:self._secret];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	int status = request.responseStatusCode;
	if(status>=400) {
		return;
	}
    
    NSString *text = [request responseString];
    SNSLog(@"resp:%@", text);
	
    /*
	 * 绑定 email，如果成功返回 {"success":1}，并发送密码备份邮件
	 * 如果失败返回：
	 * {"success":-1,"email":"xxx"}  － 此帐号已经绑定过其它email，客户端更新存档，把其它email存储进去
	 * {"success":-2,"uid":xxxx}    -  此email已经绑定了其它账号，客户端询问是否要切换到那个账号
	 * {"success":-3,"hint":"invalid pass"}    -  此email已经绑定了其它账号，但输入密码不对
	 * {"success":-100,"hint":"system error"} - 绑定失败，请重试
	 */
    NSDictionary *dict = [StringUtils convertJSONStringToObject:text];
    if(dict==nil) {
		SNSLog(@"invalid response:%@", text);
		return;
	}
    int success = [[dict objectForKey:@"success"] intValue];
    if(success==1) {
        // bind success
        //[self saveEmail:_inputEmail];
        [self showBindSuccessAlert];
    }
    else if(success==-1) {
        // 此帐号已经绑定过其它email，客户端更新存档，把其它email存储进去
        //[self saveEmail:_inputEmail];
    }
    else if(success==-2) {
        // 此email已经绑定了其它账号，客户端询问是否要切换到那个账号
        int newUID = [[dict objectForKey:@"uid"] intValue];
        [self showSwitchAccountAlert:newUID];
    }
    else if(success==-3) {
        // 此email已经绑定了其它账号，但输入密码不对
        [self showPasswordErr];
    }
    else if(success==-100){
        // 绑定失败，请重试
        [self showSystemErr];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	SNSLog(@"%s - error: %@", __FUNCTION__, error);
}

#pragma mark - RemoteDataHelper notification
//message CreateResponse {
//    required int32 ret = 1; //0是正常，其它是失败
//    optional string msg = 2; //错误说明
//    optional string token = 3; //以后用于通信的验证串
//    optional string secret = 4; //存放于本地，用于签名，方法为hmac(md5)
//    optional int32 uid = 5; //服务器端生的序列ID，可选使用
//}
- (void)createAuthFinished:(NSNotification *)note{
    NSDictionary *info = note.userInfo;
    int ret = [info[@"ret"] intValue];
    if(ret == 0){
        // succeeded
        self._uid = [NSString stringWithFormat:@"%@", info[@"uid"]];
        self._token = info[@"token"];
        self._secret = info[@"secret"];
        
        // 保存到global里
        [self saveToken];
        
        // TODO: 如果是新创建的用户，就提示玩家保存密码；如果是老用户，就提示是否要切换用户
        [self showEmailPasswordHint];
        /*
        if(_isDataUpdateAppending){
            _isDataUpdateAppending = NO;
            if(self._token && self._secret){
                NSObject<GameDataDelegate> *gameData = [SystemUtils getGameDataDelegate];
                NSString *saveStr = [gameData exportToString];
                [[RemoteDataHelper helper] updateDataWithToken:self._token
                                                          data:saveStr
                                                        secret:self._secret
                                                           cas:@([[SnsGameHelper helper] getTotalSpin])
                                                           key:nil];
            }
        }
         */
        
        if(_isDataGetAppending){
            _isDataGetAppending = NO;
            if(self._token && self._secret){
                [[RemoteDataHelper helper] getDataWithToken:self._token secret:self._secret];
            }
        }
    }
    else{
        NSString *msg = info[@"msg"];
        [self showCommonError:msg];
    }
}

- (void)updateDataFinished:(NSNotification *)note{
    NSDictionary *info = note.userInfo;
    if(info==nil) return;
    int ret = [info[@"ret"] intValue];
    if(ret == 0){
        // succeeded
        int now  = [SystemUtils getCurrentTime];
        [SystemUtils setNSDefaultObject:[NSString stringWithFormat:@"%d",now] forKey:@"kLastUpdateAWS"];
    }
    else{
        // TODO: 检查如果服务器端存档更新，就设置 kForceLoadAWS 标识
        SNSLog(@"updateDataFinished, ret = %d, msg = %@", ret, info[@"msg"]);
    }
    
//    [[RemoteDataHelper helper] getDataWithToken:self._token secret:self._secret];
}

- (void) loadDataDone
{
    // continue game load
    if(self.gameStatus == kBindHelperStatusGameStart) {
        [[SnsServerHelper helper] syncFinished];
    }
    if(self.gameStatus == kBindHelperStatusGameLoaded) {
        // TODO: 提示玩家下载了最新存档，需要退出游戏重新进入
    }
    self.gameStatus = 0;

}

- (void)getDataFinished:(NSNotification *)note{
    NSDictionary *info = note.userInfo;
    int ret = [info[@"ret"] intValue];
    if(ret == 0){
        // succeeded, parse save data
        // 解析存档格式：|SNSUserInfo|len|{json data}|SAVEDATA|len|<savedata>|stats|len|{json data}|todayStats|len|{json data}
        NSString *saveStr = [info objectForKey:@"data"];
        SNSLog(@"parsing:%@", saveStr);
        NSDictionary *saveInfo = [SystemUtils parseSaveDataFromServer:saveStr];
        SNSLog(@"loaded saveInfo:%@", saveInfo);
        saveStr = [saveInfo objectForKey:@"SAVEDATA"];
        
#ifdef SNS_HAS_SNS_GAME_HELPER
        if(![SnsGameHelper verifyLoadedSaveInfo:saveStr]) {
            [self loadDataDone];
            return;
        }
#endif
        NSFileManager *mgr = [NSFileManager defaultManager];
        NSString *userFile = [SystemUtils getUserSaveFile];
        NSString *bakFile  = [userFile stringByAppendingString:@".new"];
        // save data
        if([saveStr writeToFile:bakFile atomically:YES encoding:NSUTF8StringEncoding error:nil])
        {
            NSError *error = nil;
            if([mgr fileExistsAtPath:userFile]) {
                [mgr removeItemAtPath:userFile error:&error];
            }
            [mgr moveItemAtPath:bakFile toPath:userFile error:&error];
            // [SystemUtils updateFileDigest:userFile];
            [SystemUtils updateSaveDataHash:saveStr];
        }
        if([saveInfo objectForKey:@"stat2"]) {
            [SystemUtils checkGameStatInLoadData:saveInfo];
        }
        [self loadDataDone];
    }
    else{
        SNSLog(@"getDataFinished, ret = %d, msg = %@", ret, info[@"msg"]);
    }
}

#pragma mark - UIAlertViewDelegate
// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == CMAlertTagInputEmail) {
        UITextField *loginTextField = [alertView textFieldAtIndex:0];
        UITextField *passTextField = [alertView textFieldAtIndex:1];
        if(buttonIndex==1) {
            if(_inputEmail!=nil) [_inputEmail release];
            if(_inputPass!=nil) [_inputPass release];
            _inputEmail = loginTextField.text;
            _inputPass  = passTextField.text;
            
            [_inputPass retain]; [_inputEmail retain];
            if([_inputEmail length]<6) {
                [self promptForEmailWithHint:@"Invalid Email address, please correct it and try again: "];
                return;
            }
            if([_inputPass length]<4) {
                [self promptForEmailWithHint:@"Password must be longer than 4 characters, please correct it and try again:"];
                return;
            }
            if(![StringUtils isValidEmail:_inputEmail]) {
                [self promptForEmailWithHint:@"Invalid Email address, please correct it and try again: "];
                return;
            }
            [self startBind];
        }
    }
    else if(alertView.tag == CMAlertTagEmailPassword) {
        if(buttonIndex==1) {
            [self composePasswordBackupEmail];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(onEmailComposed:)
                                                         name:@"cmcard.oncomposeemailfinished"
                                                       object:nil];
        }
    }
    else if(alertView.tag == CMAlertTagSwitchAccount){
        // switch account
        if(buttonIndex==1){
            NSString *uid = [NSString stringWithFormat:@"%d",mailUID];
            [SystemUtils setCurrentUID:uid];
            [SystemUtils showSwitchAccountHint];
            [SystemUtils clearSessionKey];
            [SystemUtils setNSDefaultObject:@"1" forKey:@"kLoadRemoteSave"];
        }
    }
    else if(alertView.tag == CMAlertTagBindSuccess){
        if(buttonIndex==1){
            [self showEmailPasswordHint];
        }
    }
    else if(alertView.tag == CMAlertTagBindTip){
        if(buttonIndex==1){
            [self promptForEmail];
        }
    }
    else if(alertView.tag == CMAlertTagSystemErr){
        [self promptForEmail];
    }
    else if(alertView.tag == CMAlertTagPasswordErr){
        [self promptForEmail];
    }
}

#pragma mark - alerts
- (void)showBindEmailTip{
    [SystemUtils setNSDefaultObject:[NSNumber numberWithBool:YES] forKey:@"kIsBindEmailTipShowed"];
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Note"]
                              message:[SystemUtils getLocalizedString:@"Bind your email to your data. You can retrieve your game data on other devices by logining in with this email and password."]
                              delegate:self
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"Cancel"]
                              otherButtonTitles:[SystemUtils getLocalizedString:@"Bind"], nil];
    
    alertView.tag = CMAlertTagBindTip;
    [alertView show];
    [alertView release];
}

- (void)showCommonError:(NSString*)msg{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Sorry"]
                              message:msg
                              delegate:self
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                              otherButtonTitles:nil];
    
    alertView.tag = CMAlertTagCommonErr;
    [alertView show];
    [alertView release];
}

- (void) showSwitchAccountAlert:(int) newUID
{
    /*
    fbUID = newUID;
    NSString *fmt = [SystemUtils getLocalizedString:@"You've connected to an existing account before(UID:%d), will you switch to that account now?"];
    NSString *mesg = [NSString stringWithFormat:fmt, fbUID];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Account Detected"]
                              message:mesg
                              delegate:self
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"Cancel"]
                              otherButtonTitles:[SystemUtils getLocalizedString:@"OK"],nil];
    
    alertView.tag = kFacebookAlertTagSwitchAccount;
    [alertView show];
    [alertView release];
    */
    
    mailUID = newUID;
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Account Linked"]
                              message:@"xx_Need switch"
                              delegate:nil
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                              otherButtonTitles:nil];
    
    alertView.tag = CMAlertTagSwitchAccount;
    [alertView show];
    [alertView release];
}

- (void) showBindSuccessAlert
{
    NSString *mesg = [SystemUtils getLocalizedString:@"You've bind your email to your data. You can retrieve your game data on other devices by logining in with this email and password."];
    // NSString *mesg = [NSString stringWithFormat:@"You've connected to an existing account before(UID:%d), will you switch to that account now?", gcUID];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Account Binded"]
                              message:mesg
                              delegate:self
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                              otherButtonTitles:nil];
    
    alertView.tag = CMAlertTagBindSuccess;
    [alertView show];
    [alertView release];
    
}

- (void)showPasswordErr{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Invalid Password"]
                              message:[SystemUtils getLocalizedString:@"Invalid password, please check and try again."]
                              delegate:self
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                              otherButtonTitles:nil];
    
    alertView.tag = CMAlertTagPasswordErr;
    [alertView show];
    [alertView release];
    
}

- (void)showSystemErr{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"System Error"]
                              message:@"Please try again later."
                              delegate:self
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                              otherButtonTitles:nil];
    
    alertView.tag = CMAlertTagSystemErr;
    [alertView show];
    [alertView release];
}

#pragma mark -

#pragma mark backup password
- (void) showEmailPasswordHint
{
    NSString *title = [SystemUtils getLocalizedString:@"Backup Login Password"];
    NSString *mesg = [SystemUtils getLocalizedString:@"Do you want to backup the Login Password to your email? You will not be able to access the data in this app if you forget the Login Password."];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:mesg
                                                       delegate:self
                                              cancelButtonTitle:[SystemUtils getLocalizedString:@"No"]
                                              otherButtonTitles:[SystemUtils getLocalizedString:@"Backup"], nil];
    alertView.tag = CMAlertTagEmailPassword;
    [alertView show];
    
}

- (void) onEmailComposed:(NSNotification *)note
{
    
}

- (void) composePasswordBackupEmail
{
    NSString *gameName = [SystemUtils getLocalizedString:@"GameName"];
    NSString *title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Login account for %@"], gameName];
    NSString *fmt = [SystemUtils getLocalizedString:@"Here's your login account in %@:\nemail:%@\npassword:%@\n\nPlease keep this email safe and don't forward it to anybody. You'll need it when you need to restore your data on new device or delete the game accidentally.\n"];
    NSString *body = [NSString stringWithFormat:fmt, gameName, _inputEmail, _inputPass];
    SendEmailViewController *messageView = [[SendEmailViewController alloc] init];
    messageView.useRootView = YES;
    
	[messageView displayComposerSheet:nil
							withTitle:title
							  andBody:body
						andAttachData:nil
				   withAttachFileName:nil];
	
    [messageView release];

}


#pragma mark -

@end
