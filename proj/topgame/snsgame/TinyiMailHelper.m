//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "SNSLogType.h"
#import "TinyiMailHelper.h"
#import "SystemUtils.h"
#import "TinyiMailStatusOperation.h"
#import "smTinyiMail.h"
#import "smPopupWindowQueue.h"
#import "NetworkHelper.h"
#import "SendEmailViewController.h"
#import "StringUtils.h"
#import "SNSAlertView.h"
#import "SnsFriendsSelectViewController.h"
#import "SnsStatsHelper.h"

@implementation TinyiMailHelper

static TinyiMailHelper *_gTinyiMailHelper = nil;
static NSMutableDictionary *_gTinyiMailInfo = nil;

@synthesize iVerifyPrizeLeaf, isServerOK;

+(TinyiMailHelper *)helper
{
	@synchronized(self) {
		if(!_gTinyiMailHelper) {
			_gTinyiMailHelper = [[TinyiMailHelper alloc] init];
		}
	}
	return _gTinyiMailHelper;
}

- (id) init
{
	
	self = [super init];
	if(self != nil) {
		isSessionInitialized = NO; isNoticeShown = NO; isShowingPopupBox = NO;
        isServerOK = NO; isFirstTime = YES;
        pMailComposer = nil; pAddressBookPicker = nil;
        m_emailGiftQuery = nil;
	}
    [self initSession];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStatusCheckDone:) name:kNotificationTinyiMailCheckStatusDone object:nil];
    
	// A notification method must be set to retrieve the points.
	// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getUpdatedPoints:) name:TJC_TAP_POINTS_RESPONSE_NOTIFICATION object:nil];
	return self;
}

- (void) dealloc
{
    SNSReleaseObj(_gTinyiMailInfo);
    if(pMailComposer) [pMailComposer release];
    if(pAddressBookPicker) [pAddressBookPicker release];
	// if(pendingActions) [pendingActions release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) initSession
{
    if(isSessionInitialized) return;
    isSessionInitialized = YES;
    iVerifyPrizeLeaf = [[SystemUtils getGlobalSetting:kTinyiMailPrizeLeaf] intValue];
    if(iVerifyPrizeLeaf==0)
        iVerifyPrizeLeaf = [[SystemUtils getSystemInfo:kTinyiMailPrizeLeaf] intValue];
}


// 获取用户系统信息
- (NSDictionary *) getTinyiMailInfo
{
    if(!_gTinyiMailInfo) {
        NSDictionary *info = [SystemUtils getGlobalSetting:kTinyiMailInfo];
        if(info && [info isKindOfClass:[NSDictionary class]]) {
            _gTinyiMailInfo = [[NSMutableDictionary alloc] initWithDictionary:info];
        }
        else {
            // read from gamedata
            info = [[SystemUtils getGameDataDelegate] getExtraInfo:kTinyiMailInfo];
            if(info && [info isKindOfClass:[NSDictionary class]]) {
                _gTinyiMailInfo = [[NSMutableDictionary alloc] initWithDictionary:info];
            }
        }
        
        if(!_gTinyiMailInfo){
            _gTinyiMailInfo = [[NSMutableDictionary alloc] initWithCapacity:4];
        }
        [SystemUtils setGlobalSetting:_gTinyiMailInfo forKey:kTinyiMailInfo];
        [[SystemUtils getGameDataDelegate] setExtraInfo:_gTinyiMailInfo forKey:kTinyiMailInfo];
    }
    return _gTinyiMailInfo;
}

// 设置默认邮箱
-(void) setDefaultEmail:(NSString *)email
{
    if(!email || ![email isKindOfClass:[NSString class]]) return;
    NSString *oldemail = [self getTinyiMailObject:@"email"];
    if(!oldemail || ![oldemail isKindOfClass:[NSString class]]) oldemail = @"";
    if([email isEqualToString:oldemail]) return;
    [self setTinyiMailObject:email forKey:@"email"];
}

- (void) updateTinyiMailInfo:(NSDictionary *)info
{
    if(!info) return;
    // [_gTinyiMailInfo addEntriesFromDictionary:info];
    
    NSString *userID = [info objectForKey:@"userID"];
    if(userID) {
        if(![userID isKindOfClass:[NSString class]])
            userID = [NSString stringWithFormat:@"%@",userID];
        [self setTinyiMailObject:userID forKey:@"uid"];
    }
    // inviteCode, friendCode, inviteSuccess, invitePrizeCount
    NSString *code = [info objectForKey:@"inviteCode"];
    if([code intValue]>0) 
        [_gTinyiMailInfo setValue:[info objectForKey:@"inviteCode"] forKey:@"inviteCode"];
    [_gTinyiMailInfo setValue:[info objectForKey:@"friendCode"] forKey:@"friendCode"];
    [_gTinyiMailInfo setValue:[info objectForKey:@"inviteSuccess"] forKey:@"inviteSuccess"];
    NSString *prizeCount = [info objectForKey:@"invitePrizeCount"];
    NSString *localCount = [self getTinyiMailObject:@"invitePrizeCount"];
    if([prizeCount intValue]>[localCount intValue])
        [_gTinyiMailInfo setValue:prizeCount forKey:@"invitePrizeCount"];
    
    NSString *email  = [info objectForKey:@"email"];
    if(email) {
        if(![email isKindOfClass:[NSString class]])
            email = [NSString stringWithFormat:@"%@",email];
        [self setDefaultEmail:email];
    }
    int status = [[info objectForKey:@"status"] intValue];
    int oldStatus = [[self getTinyiMailObject:@"status"] intValue];
    if(status!=oldStatus) {
        // 持久化获奖状态，确保不会重复发奖
        NSString *key = [NSString stringWithFormat:@"kTinyiMail-%@", [self getTinyiMailObject:@"uid"]];
        int prizeStatus = [[[SystemUtils getGameDataDelegate] getExtraInfo:key] intValue];
        if(status == 1 && oldStatus==0 && prizeStatus==0) {
            [self giveVerifySuccessPrize];
        }
        if(status==1) status = 2;
        if(prizeStatus!=1) {
            [[SystemUtils getGameDataDelegate] setExtraInfo:[NSNumber numberWithInt:1] forKey:key];
        }
        [self setTinyiMailObject:[NSNumber numberWithInt:status] forKey:@"status"];
    }
    // update clientStatus
    int clientStatus = [[self getTinyiMailObject:@"clientStatus"] intValue];
    if(status==1 || status==2 || status==3) {
        clientStatus = kTinyiMailStatusEmailVerified;
        [self setTinyiMailObject:[NSNumber numberWithInt:clientStatus] forKey:@"clientStatus"];
    }
    else {
        if(clientStatus == kTinyiMailStatusEmailVerified) 
            clientStatus = kTinyiMailStatusNone;
        if(clientStatus == kTinyiMailStatusNone && email && [email length]>0) {
            clientStatus = kTinyiMailStatusEmailReady;
            [self setTinyiMailObject:[NSNumber numberWithInt:clientStatus] forKey:@"clientStatus"];
        }
    }
    [SystemUtils setGlobalSetting:_gTinyiMailInfo forKey:kTinyiMailInfo];
    [[SystemUtils getGameDataDelegate] setExtraInfo:_gTinyiMailInfo forKey:kTinyiMailInfo];    
    NSArray *notice = [info objectForKey:@"prizeInfo"];
    if(notice && [notice isKindOfClass:[NSArray class]])
    {
        [self showTinyiMailPrize:notice];
    }
}

- (id) getTinyiMailObject:(id)key
{
    [self getTinyiMailInfo];
    return [_gTinyiMailInfo objectForKey:key];
}

- (void) setTinyiMailObject:(id)obj forKey:(id)key
{
    [self getTinyiMailInfo];
    [_gTinyiMailInfo setValue:obj forKey:key];
}

- (int) getTinyiMailStatus
{
    int clientStatus = [[self getTinyiMailObject:@"clientStatus"] intValue];
    return clientStatus;
}
// 判断是否注册成功
-(BOOL)isRegistered
{
    NSString *uid = [self getTinyiMailObject:@"uid"];
    if(uid && [uid isKindOfClass:[NSString class]] 
       && [uid length]>1 && ![uid isEqualToString:@"0"]) return YES;
    return NO;
}
// 判断是否填写了邀请码
-(BOOL)hasFriendCode
{
    NSString *code = [self getTinyiMailObject:@"friendCode"];
    if(code && [code isKindOfClass:[NSString class]] && [code length]>2) return YES;
    return NO;
}


// 显示获奖通知
- (void) showTinyiMailPrize:(NSArray *)arr
{
    for(NSDictionary *info in arr)
    {
        if(![info isKindOfClass:[NSDictionary class]]) 
            continue;
        // {"id"1, "type":1,"count":50,"message":"恭喜你成功安装宠物旅馆，活动50金币奖励！"}
        NSString *mesg = [info objectForKey:@"message"];
        if(!mesg) continue;
        int prizeGold = 0; int prizeLeaf = 0;
        int prizeType = [[info objectForKey:@"type"] intValue];
        if(prizeType == 1) prizeGold = [[info objectForKey:@"num"] intValue];
        if(prizeType == 2) prizeLeaf = [[info objectForKey:@"num"] intValue];
        
        NSDictionary *prizeInfo = [NSDictionary 
                                   dictionaryWithObjectsAndKeys: 
                                   mesg, @"mesg", @"", @"action", 
                                   [NSNumber numberWithInt:prizeLeaf], @"prizeLeaf",
                                   [NSNumber numberWithInt:prizeGold], @"prizeGold", nil];
        [SystemUtils showCustomNotice:prizeInfo];
        
    }
}

// 发放验证成功奖励
- (void) giveVerifySuccessPrize
{
    SNSLog(@"give tinyimail prize");
    NSString *coinName = [SystemUtils getLocalizedString:@"CoinName2"];
    NSString *awardInfo = [StringUtils getTextOfNum:iVerifyPrizeLeaf Word:coinName];
        // 发放一次性奖励
        // {"mesg":"xxxx","mesgID":"localized key","action":"","prizeGold":"0","prizeLeaf":"0"}
        NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Great! You've got %@ for subscribing to our mail list."], awardInfo];
        NSDictionary *prizeInfo = [NSDictionary 
                                   dictionaryWithObjectsAndKeys: 
                                   mesg, @"mesg", @"", @"action", 
                                   [NSNumber numberWithInt:iVerifyPrizeLeaf], @"prizeLeaf",
                                   [NSNumber numberWithInt:0], @"prizeGold", nil];
        [SystemUtils showCustomNotice:prizeInfo];
}

// 开始检查服务器
- (void) startCheckStatus:(BOOL)forceCheck
{
    if(!forceCheck) {
        int lastTime = [[SystemUtils getNSDefaultObject:@"kTinyiMailCheckTime"] intValue];
        int nowTime = [SystemUtils getCurrentTime];
        SNSLog(@"now:%i lastTime:%i diff:%i",nowTime, lastTime, nowTime-lastTime);
        // 每12小时检查一次
#ifndef DEBUG
        int forceTime = [[SystemUtils getNSDefaultObject:@"kForceCheckTinyimail"] intValue];
        // int today = [SystemUtils getTodayDate];
        if(lastTime > nowTime - 43200 && forceTime < nowTime-86400) {
            [self showGameNotice];
            return;
        }
#endif
        [SystemUtils setNSDefaultObject:[NSString stringWithFormat:@"%i",nowTime] forKey:@"kTinyiMailCheckTime"];
    }
    
    [self reloadServerStatus];
    /*
    SyncQueue* syncQueue = [SyncQueue syncQueue];
    
    TinyiMailStatusOperation* saveOp = [[TinyiMailStatusOperation alloc] initWithManager:syncQueue andDelegate:nil];
    [syncQueue.operations addOperation:saveOp];
    [saveOp release];
     */
}

// 更新服务器状态
- (void) reloadServerStatus
{
    SyncQueue* syncQueue = [SyncQueue syncQueue];
    
    TinyiMailStatusOperation* saveOp = [[TinyiMailStatusOperation alloc] initWithManager:syncQueue andDelegate:nil];
    [syncQueue.operations addOperation:saveOp];
    [saveOp release];
}

// 检查状态完成
- (void) onStatusCheckDone:(NSNotification *)note
{
    [self checkInvitationBonus];
    if(!isFirstTime) return;
    isFirstTime = NO;
    int status = [[self getTinyiMailObject:@"status"] intValue];
    if(status == 0) {
        [self showiMailPopupBox:NO];
    }
    if(!isShowingPopupBox)
        [self showGameNotice];
}

// show popup box
- (BOOL) showiMailPopupBox:(BOOL)forceShow
{
    if(!forceShow) {
        if(!isServerOK) return NO;
        if(![SystemUtils getGameDataDelegate] || ![[SystemUtils getGameDataDelegate] isTutorialFinished]) return NO;
        // if(![NetworkHelper isConnected]) return NO;
        if(![SystemUtils isAdVisible]) return NO;
        // 只有安装后第3天才出现，每周出现一次，最多3次
        int dayCount = [SystemUtils getLoginDayCount];
        if(dayCount>20 || (dayCount%10)!=3) return NO;
        // 只显示一次
        int displayDate = [[SystemUtils getNSDefaultObject:@"iMailDisplayDate"] intValue];
        if(displayDate==dayCount) return NO;
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:dayCount] forKey:@"iMailDisplayDate"];
        
        /*
        // 控制显示频率
        // （如果未验证，每天出现一次，连续3天。 还不完成，一周后循环。）（送多少可服务器设置）
        int lastTime = [[SystemUtils getNSDefaultObject:@"kTinyiMailNoticeTime"] intValue];
        int count = [[SystemUtils getNSDefaultObject:@"kTinyiMailNoticeCount"] intValue];
        int nowTime = [SystemUtils getCurrentTime];
        SNSLog(@"now:%i lastTime:%i diff:%i",nowTime, lastTime, nowTime-lastTime);
        
        if(lastTime > nowTime - 86400) 
            return NO;
        if(count > 3 && lastTime > nowTime - 86400*7)
            return NO;
        
        count++; 
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:count] forKey:@"kTinyiMailNoticeCount"];
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:nowTime] forKey:@"kTinyiMailNoticeTime"];
         */
    }
	if (isShowingPopupBox) return NO;
    isShowingPopupBox = YES;
    // 显示输入邮件状态
    int status = [self getTinyiMailStatus];
    int type = 1;
    if(status == kTinyiMailStatusNone) type = 1;
    if(status == kTinyiMailStatusEmailReady || status == kTinyiMailStatusEmailSent) type = 2;
    if(status == kTinyiMailStatusEmailVerified) type = 3;
    smTinyiMail *imail = [[smTinyiMail alloc] initWithStep:type];
    [[smPopupWindowQueue createQueue] pushToQueue:imail timeOut:0];
    // [imail showHard];
    [imail release];
    return YES;
}
// 关闭iMail窗口时调用
- (void) closeiMailPopupBox
{
    if(isShowingPopupBox) {
        [self showGameNotice];
        isShowingPopupBox = NO;
    }
}


// start notice info
- (void) showGameNotice
{
    if(!isNoticeShown) {
        isNoticeShown = YES;
        // 不在这里显示通知，改回到SnsServerHelper中
        // [SystemUtils showInGameNotice];
    }
}

- (NSString *)getVerifyString
{
    NSString *uid = [self getTinyiMailObject:@"uid"];
    int time = [SystemUtils getCurrentTime];
    NSString *email = [self getTinyiMailObject:@"email"];
    NSString *str = [NSString stringWithFormat:@"%@-tinyiMail-%i-%@", uid, time, email];
    NSString *sig = [StringUtils stringByHashingStringWithMD5:str];
    str = [NSString stringWithFormat:@"|||TinyiMail|||%@|||%@|||%i|||%@|||", uid, email, time, sig];
    return str;
}

// 发验证邮件
-(void) writeVerifyEmail
{
	if(![MFMailComposeViewController canSendMail]) {
		[SystemUtils setUpMailAccountAlert];
		return;
	}
	
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(onComposeEmailFinished:) 
                                                 name:kNotificationComposeEmailFinish
                                               object:nil];
    
	NSString *title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Subscribe to %@ Mailing List"],[SystemUtils getLocalizedString:@"GameName"]];
	NSString *body = [NSString stringWithFormat:@"%@\n\n%@\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n%@\n\n", 
                      [SystemUtils getLocalizedString:[SystemUtils getSystemInfo:kSupportEmailGreeting]], 
                      [SystemUtils getLocalizedString:[SystemUtils getSystemInfo:@"kTinyiMailVerifyBody"]], 
                      [self getVerifyString]];
	SendEmailViewController *messageView = [[SendEmailViewController alloc] init];
    
    nWriteEmailStatus = 1;
    
#ifdef SNS_POP_MAILCOMPOSER_IN_ROOTVIEW
    messageView.useRootView = YES;
#endif
    
	[messageView displayComposerSheet:[SystemUtils getSystemInfo:@"kTinyiMailVerifyEmail"] 
							withTitle:title
							  andBody:body
						andAttachData:nil 
				   withAttachFileName:nil];
    
    pMailComposer = messageView;
}

#pragma mark Invitation

// 显示邀请好友功能
- (void) showInviteFriendsPopup:(BOOL)forceShow
{
    // int status = [self getTinyiMailStatus];
    int type = 5;
    smTinyiMail *imail = [[smTinyiMail alloc] initWithStep:type];
    [[smPopupWindowQueue createQueue] pushToQueue:imail timeOut:0];
    // [imail showHard];
    [imail release];
}
// 显示输入邀请码功能
- (void) showEnterInviteCode:(BOOL)forceShow
{
    // int status = [self getTinyiMailStatus];
    int type = 4;
    smTinyiMail *imail = [[smTinyiMail alloc] initWithStep:type];
    [[smPopupWindowQueue createQueue] pushToQueue:imail timeOut:0];
    // [imail showHard];
    [imail release];
}


- (void) sendInvitationEmail:(NSArray *)emails
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(onComposeEmailFinished:) 
                                                 name:kNotificationComposeEmailFinish
                                               object:nil];
    
    int awardNum = [TinyiMailHelper helper].iVerifyPrizeLeaf;
    NSString *coinName = [SystemUtils getLocalizedString:@"CoinName2"];
    NSString *awardInfo = [StringUtils getTextOfNum:awardNum Word:coinName];
    
    NSString *gameName = [SystemUtils getLocalizedString:@"GameName"];
    NSString *title = [SystemUtils getSystemInfo:@"kInviteEmailTitle"];
	if(!title) 
        title = @"%@ is funny!";
    title = [NSString stringWithFormat:[SystemUtils getLocalizedString:title], gameName];
    NSString *bodyFmt = [SystemUtils getSystemInfo:@"kInviteEmailBody"];
    if(!bodyFmt) {
        bodyFmt = [SystemUtils getLocalizedString:@"Hi there,\n\nCome and check out %1$@! It's mind-blowingly awesome! If you accept my invite, we'll both get a bonus of %2$@.\n\nMy invitation code is: %3$@\n\nAnd here is the download link: %4$@\n\nDon't miss out!\n\n"];
    }
    NSString *appID = [SystemUtils getSystemInfo:@"kiTunesAppID"];
    bodyFmt = [bodyFmt stringByReplacingOccurrencesOfString:@"__APP_NAME__" withString:gameName];
    bodyFmt = [bodyFmt stringByReplacingOccurrencesOfString:@"__APP_ID__" withString:appID];
    SNSLog(@"bodyFmt:%@",bodyFmt);
    NSDictionary *vars = [SystemUtils getSystemInfo:@"kGiftEmailVars"];
    if(vars && [vars isKindOfClass:[NSDictionary class]] && [vars count]>0)
    {
        for (NSString *key in [vars allKeys]) {
            bodyFmt = [bodyFmt stringByReplacingOccurrencesOfString:key withString:[vars objectForKey:key]];
            SNSLog(@"replace:%@",key);
        }
    }
    SNSLog(@"bodyFmt:%@",bodyFmt);
    
	NSString *body = [NSString stringWithFormat:bodyFmt,
                      gameName, awardInfo, [self getInviteCode],
                      [SystemUtils getAppDownloadShortLink] ];
	SendEmailViewController *messageView = [[SendEmailViewController alloc] init];
    
#ifdef SNS_POP_MAILCOMPOSER_IN_ROOTVIEW
    messageView.useRootView = YES;
#endif
    
	[messageView displayComposerSheet:emails 
							withTitle:title
							  andBody:body
						andAttachData:nil 
				   withAttachFileName:nil];
    
    pMailComposer = messageView;
    
    nWriteEmailStatus = 2;
}

-(NSString *)getInviteCode
{
    NSString *code = [self getTinyiMailObject:@"inviteCode"];
    if(!code || [code length]==0) {
        // generate code
        int v = rand()%90+10;
        code = [NSString stringWithFormat:@"%i",v];
        [self setTinyiMailObject:code forKey:@"inviteCode"];
    }
    NSString *uid = [self getTinyiMailObject:@"uid"];
    if(uid==nil) return code;
    // NSString *uid = [SystemUtils getCurrentUID];
    return [code stringByAppendingString:uid];
}

// 发邀请邮件
-(void) writeInvitationEmail
{
    if(![MFMailComposeViewController canSendMail]) {
		[SystemUtils setUpMailAccountAlert];
		return;
	}
	
    SNSLog(@"start write invitation email");
#ifdef  SNS_USE_ADDRESSBOOK_UI
    if(pAddressBookPicker) [pAddressBookPicker release];

    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    picker.displayedProperties = [NSArray arrayWithObjects:
                                  [NSNumber numberWithInt:kABPersonFirstNameProperty],
                                  [NSNumber numberWithInt:kABPersonLastNameProperty],
                                  [NSNumber numberWithInt:kABPersonMiddleNameProperty],
                                  [NSNumber numberWithInt:kABPersonEmailProperty], nil];
    pAddressBookPicker = picker;
    
    UIViewController *ct = [SystemUtils getAbsoluteRootViewController];
    
#ifdef SNS_POPUP_IN_TOP_WINDOW
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	if (!window) {
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	}
	UIResponder *nextResponder = [[window.subviews objectAtIndex:0] nextResponder];
	if ([nextResponder isKindOfClass:[UIViewController class]]) {
		ct = (UIViewController *)nextResponder;
	}
#endif    
    if(ct) {
        if([[SystemUtils getiOSVersion] compare:@"5.0"]>=0)
            [ct presentViewController:picker animated:YES completion:^(void){}];
        else
            [ct presentModalViewController:picker animated:YES];
    }
#else
    
    // get all friends with email
    NSMutableArray *friends = [NSMutableArray array];
    ABAddressBookRef addressBook =ABAddressBookCreate();
    CFArrayRef allPeople =ABAddressBookCopyArrayOfAllPeople( addressBook );
    CFIndex nPeople =ABAddressBookGetPersonCount( addressBook );
    NSString *country = [SystemUtils getCountryCode];
    BOOL isChinese = NO;
    if([country isEqualToString:@"CN"] || [country isEqualToString:@"TW"] 
       || [country isEqualToString:@"HK"] || [country isEqualToString:@"MO"]
       || [country isEqualToString:@"SG"]) 
        isChinese = YES;
    for(int i =0; i < nPeople; i++){    
        ABRecordRef person = CFArrayGetValueAtIndex( allPeople, i );
        // get player email address
        NSString* email = nil;
        ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
        if (emails && ABMultiValueGetCount(emails) > 0) {
            email = (NSString*) ABMultiValueCopyValueAtIndex(emails, 0);
        }
        if(!email) continue;
        
        NSString* firstName = (NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        if(!firstName) firstName = @"";
        else {
            if(!isChinese || ([firstName length]>0 && [firstName characterAtIndex:0]<255))
                firstName = [firstName stringByAppendingString:@" "];
        }
        NSString *middleName = (NSString*)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
        if(!middleName) middleName = @"";
        else {
            if(!isChinese || ([middleName length]>0 && [middleName characterAtIndex:0]<255))
                middleName = [middleName stringByAppendingString:@" "];
        }
        NSString *lastName = (NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
        if(!lastName) lastName = @"";
        
        
        NSString *name = [NSString stringWithFormat:@"%@%@%@", firstName, middleName, lastName];
        if(isChinese && [name length]>0 && [name characterAtIndex:0]>255)
            name = [NSString stringWithFormat:@"%@%@%@",lastName, middleName, firstName];
        
        NSDictionary *friend = [NSDictionary dictionaryWithObjectsAndKeys:email, @"email", name, @"name", nil];
        
        [friends addObject:friend];
        // CFRelease(emails);
        // [firstName release]; [middleName release]; [lastName release];
    }
    // CFRelease(allPeople);
    CFRelease(addressBook);
    if([friends count]==0) {
        // NO friends with email found
        [self sendInvitationEmail:nil];
        return;
    }
    // 不到10个好友就直接发邮件邀请
    int inviteAllFriends = [[SystemUtils getNSDefaultObject:@"kSendInviteToAllFriends"] intValue];
#ifdef DEBUG
    //inviteAllFriends = 0;
#endif
    if([friends count]<10 && inviteAllFriends==0) {
        NSMutableArray *emails = [NSMutableArray arrayWithCapacity:[friends count]];
        for(int i=0;i<[friends count];i++)
        {
            NSDictionary *f = [friends objectAtIndex:i];
            NSString *name = [f objectForKey:@"name"];
            if([name rangeOfString:@"\""].location != NSNotFound) {
                name = [name stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
            }
            NSString *email = [NSString stringWithFormat:@"\"%@\" <%@>", name, [f objectForKey:@"email"]];
            [emails addObject:email];
        }
        [self sendInvitationEmail:emails];
        [SystemUtils setNSDefaultObject:@"1" forKey:@"kSendInviteToAllFriends"];
        return;
    }
    
    SNSLog(@"found %i friends:%@",[friends count], friends );
    SnsFriendsSelectViewController *friendSelector = [[SnsFriendsSelectViewController alloc] init];
	friendSelector.items = friends;
    friendSelector.wantsFullScreenLayout = YES;
    // friendSelector.isInWindow = YES;
    friendSelector.emailType = 1;
	[friendSelector showHard];
    
#ifndef SNS_DISABLE_SET_POPUP_POSITION
    int width = [UIScreen mainScreen].bounds.size.width; 
    int height = [UIScreen mainScreen].bounds.size.height;
    int t = 0;
    UIDeviceOrientation or = [SystemUtils getGameOrientation];
    if(UIDeviceOrientationIsLandscape(or)) 
    {
        // landscape
        if(width<height) {
            t = width; width = height; height = t; // portrait
        }
    }
    else {
        // portrait
        if(width>height) {
            t = width; width = height; height = t; // portrait
        }
    }
    CGPoint center = friendSelector.view.center;
    CGRect f = friendSelector.view.frame;
    f.size.width = width;
    f.size.height = height;
    friendSelector.view.frame = f;
    friendSelector.view.center = center;
#endif
    [friendSelector release];
#endif    
}

- (void) sendInvitationEmailTo:(NSString *)email withName:(NSString *)name
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(onComposeEmailFinished:) 
                                                 name:kNotificationComposeEmailFinish
                                               object:nil];
    int awardNum = [TinyiMailHelper helper].iVerifyPrizeLeaf;
    NSString *coinName = [SystemUtils getLocalizedString:@"CoinName2"];
    NSString *awardInfo = [StringUtils getTextOfNum:awardNum Word:coinName];
    
    NSString *gameName = [SystemUtils getLocalizedString:@"GameName"];
    NSString *title = [SystemUtils getSystemInfo:@"kInviteEmailTitle"];
	if(!title) 
        title = @"%@ is funny!";
    title = [NSString stringWithFormat:title,gameName];
    NSString *bodyFmt = [SystemUtils getSystemInfo:@"kInviteEmailBody"];
    if(!bodyFmt)
    bodyFmt = [SystemUtils getLocalizedString:@"Hi, %1$@,\n\nI find %2$@ is really funny, download and play together. If you accept my invitation, we'll both get %3$@ as bonus.\n\nMy invitation code:%4$@\nDownload link:\n%5$@\n\nDon't miss it!\n\n"];
    
	NSString *body = [NSString stringWithFormat:bodyFmt, 
                      name, gameName, 
                      awardInfo, [self getInviteCode],
                      [SystemUtils getAppDownloadShortLink]];
	SendEmailViewController *messageView = [[SendEmailViewController alloc] init];
    
#ifdef SNS_POP_MAILCOMPOSER_IN_ROOTVIEW
    messageView.useRootView = YES;
#endif
    
	[messageView displayComposerSheet:email 
							withTitle:title
							  andBody:body
						andAttachData:nil 
				   withAttachFileName:nil];
    
    pMailComposer = messageView;
    int today = [SystemUtils getCurrentTime];
    [SystemUtils setNSDefaultObject:[NSString stringWithFormat:@"%d",today] forKey:@"kForceCheckTinyimail"];
    
    nWriteEmailStatus = 2;
}

// 检查并发放邀请奖励
-(void) checkInvitationBonus
{
    int inviteSuccess = [[self getTinyiMailObject:@"inviteSuccess"] intValue];
    if(inviteSuccess==0) return;
    
    int prizeCount = [[self getTinyiMailObject:@"invitePrizeCount"] intValue];
    if(inviteSuccess <= prizeCount) return;
    // give prize
    [self setTinyiMailObject:[NSString stringWithFormat:@"%d",inviteSuccess] forKey:@"invitePrizeCount"];
    int count = inviteSuccess - prizeCount;
    int awardNum = iVerifyPrizeLeaf*count;
    NSString *coinName = [SystemUtils getLocalizedString:@"CoinName2"];
    NSString *awardInfo = [StringUtils getTextOfNum:awardNum Word:coinName];
    NSString *friendWord = [SystemUtils getLocalizedString:@"friend"];
    NSString *friendInfo = [StringUtils getTextOfNum:count Word:friendWord];
    
    [SystemUtils addGameResource:awardNum ofType:kGameResourceTypeLeaf];
    
    NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Great! You just got %@ as bonus for inviting %@ successfully!"], awardInfo, friendInfo];
    SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:[SystemUtils getLocalizedString: @"Invitation Success"]
                        message:mesg
                        delegate:nil
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertNone;
    // [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av showHard];
    [av release];
    
}



#pragma mark -

#pragma mark Email Gift
// 发送礼物邮件
- (void) writeGiftEmail
{

    if(![MFMailComposeViewController canSendMail]) {
		[SystemUtils setUpMailAccountAlert];
		return;
	}
	
    SNSLog(@"start write invitation email");
    // get all friends with email
    NSMutableArray *friends = [NSMutableArray array];
    ABAddressBookRef addressBook =ABAddressBookCreate();
    CFArrayRef allPeople =ABAddressBookCopyArrayOfAllPeople( addressBook );
    CFIndex nPeople =ABAddressBookGetPersonCount( addressBook );
    NSString *country = [SystemUtils getCountryCode];
    BOOL isChinese = NO;
    if([country isEqualToString:@"CN"] || [country isEqualToString:@"TW"] 
       || [country isEqualToString:@"HK"] || [country isEqualToString:@"MO"]
       || [country isEqualToString:@"SG"]) 
        isChinese = YES;
    for(int i =0; i < nPeople; i++){    
        ABRecordRef person = CFArrayGetValueAtIndex( allPeople, i );
        // get player email address
        NSString* email = nil;
        ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
        if (emails && ABMultiValueGetCount(emails) > 0) {
            email = (NSString*) ABMultiValueCopyValueAtIndex(emails, 0);
        }
        if(!email) continue;
        
        NSString* firstName = (NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        if(!firstName) firstName = @"";
        else {
            if(!isChinese || ([firstName length]>0 && [firstName characterAtIndex:0]<255))
                firstName = [firstName stringByAppendingString:@" "];
        }
        NSString *middleName = (NSString*)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
        if(!middleName) middleName = @"";
        else {
            if(!isChinese || ([middleName length]>0 && [middleName characterAtIndex:0]<255))
                middleName = [middleName stringByAppendingString:@" "];
        }
        NSString *lastName = (NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
        if(!lastName) lastName = @"";
        
        
        NSString *name = [NSString stringWithFormat:@"%@%@%@", firstName, middleName, lastName];
        if(isChinese && [name length]>0 && [name characterAtIndex:0]>255)
            name = [NSString stringWithFormat:@"%@%@%@",lastName, middleName, firstName];
        
        NSDictionary *friend = [NSDictionary dictionaryWithObjectsAndKeys:email, @"email", name, @"name", nil];
        
        [friends addObject:friend];
        // CFRelease(emails);
        // [firstName release]; [middleName release]; [lastName release];
    }
    // CFRelease(allPeople);
    CFRelease(addressBook);
    if([friends count]==0) {
        // NO friends with email found
        [self sendGiftEmail:nil];
        return;
    }
    // 不到10个好友就直接发邮件邀请
    int inviteAllFriends = [[SystemUtils getNSDefaultObject:@"kSendGiftsToAllFriends"] intValue];
#ifdef DEBUG
    //inviteAllFriends = 0;
#endif
    if([friends count]<10 && inviteAllFriends==0) {
        NSMutableArray *emails = [NSMutableArray arrayWithCapacity:[friends count]];
        for(int i=0;i<[friends count];i++)
        {
            NSDictionary *f = [friends objectAtIndex:i];
            NSString *name = [f objectForKey:@"name"];
            if([name rangeOfString:@"\""].location != NSNotFound) {
                name = [name stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
            }
            NSString *email = [NSString stringWithFormat:@"\"%@\" <%@>", name, [f objectForKey:@"email"]];
            [emails addObject:email];
        }
        [self sendGiftEmail:emails];
        [SystemUtils setNSDefaultObject:@"1" forKey:@"kSendGiftsToAllFriends"];
        return;
    }
    
    SNSLog(@"found %i friends:%@",[friends count], friends );
    // 杨杰：这里调用好友选择窗口，完成后调用 [[TinyiMailHelper helper] sendInvitationEmail:arrayOfEmails] 发送邀请邮件
    SnsFriendsSelectViewController *friendSelector = [[SnsFriendsSelectViewController alloc] init];
	friendSelector.items = friends;
    friendSelector.wantsFullScreenLayout = YES;
    // friendSelector.isInWindow = YES;
    friendSelector.emailType = 2;
	[friendSelector showHard];
    
#ifndef SNS_DISABLE_SET_POPUP_POSITION
    int width = [UIScreen mainScreen].bounds.size.width; 
    int height = [UIScreen mainScreen].bounds.size.height;
    int t = 0;
    UIDeviceOrientation or = [SystemUtils getGameOrientation];
    if(UIDeviceOrientationIsLandscape(or)) 
    {
        // landscape
        if(width<height) {
            t = width; width = height; height = t; // portrait
        }
    }
    else {
        // portrait
        if(width>height) {
            t = width; width = height; height = t; // portrait
        }
    }
    CGPoint center = friendSelector.view.center;
    CGRect f = friendSelector.view.frame;
    f.size.width = width;
    f.size.height = height;
    friendSelector.view.frame = f;
    friendSelector.view.center = center;
#endif
    
    [friendSelector release];
    
}

// 获得礼物连接验证码
- (NSString *)getGiftHash:(NSString *)info
{
    NSString *str = [NSString stringWithFormat:@"%@-digw23843435",info];
    return [[StringUtils stringByHashingStringWithSHA1:str] substringToIndex:10];
}

- (void) sendGiftEmail:(NSArray *)emails
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(onComposeEmailFinished:) 
                                                 name:kNotificationComposeEmailFinish
                                               object:nil];
     
    
    int awardNum = [[SystemUtils getGlobalSetting:@"kGiftEmailPrizeCount"] intValue];
    if(awardNum==0) awardNum = [[SystemUtils getSystemInfo:@"kGiftEmailPrizeCount"] intValue];
    NSString *coinName = [SystemUtils getGlobalSetting:@"kGiftEmailPrizeType"];
    if(coinName==nil || [coinName length]<=1) coinName = [SystemUtils getSystemInfo:@"kGiftEmailPrizeType"];
    NSString *coinName2 = [SystemUtils getLocalizedString:coinName];
    if(awardNum>0) coinName2 = [StringUtils getPluralFormOfWord:coinName];
    
    NSString *gameName = [SystemUtils getLocalizedString:@"GameName"];
    NSString *title = [SystemUtils getSystemInfo:@"kGiftEmailTitle"];
	if(!title) 
        title = @"%1$d %2$@ for you in %3$@(iPhone/iPad)!";
    title = [NSString stringWithFormat:[SystemUtils getLocalizedString:title], awardNum, coinName2, gameName];
    NSString *bodyFmt = [SystemUtils getSystemInfo:@"kGiftEmailBody"];
    if(!bodyFmt)
        bodyFmt = [SystemUtils getLocalizedString:@"<p>Hi, there,</p><p>Running out of %2$@ in %4$@? Here is <strong>%1$d %2$@</strong> for you, come to enjoy it together!</p><p><a href=\"%3$@\">Click here to receive your %1$d %2$@!</a></p><p>If you have not installed %4$@, you can <a href=\"%5$@\">download it now</a>(For iPhone/iPad only).</p><p>Don't worry, it's completely free!</p>"];
    // SNSLog(@"bodyFmt:%@",bodyFmt);
    // __BONUS_ICON__, __APP_ICON__, __APP_NAME__
	NSString *remoteURLRoot = [NSString stringWithFormat:@"http://%@/item_files/general", [SystemUtils getDownloadServerName]];
    bodyFmt = [bodyFmt stringByReplacingOccurrencesOfString:@"__BONUS_ICON__" withString:[remoteURLRoot stringByAppendingPathComponent:@"bonus-620x348.jpg"]];
    bodyFmt = [bodyFmt stringByReplacingOccurrencesOfString:@"__APP_ICON__" withString:[remoteURLRoot stringByAppendingPathComponent:@"icon-175x175.png"]];
    // SNSLog(@"replace:%@",key);
    
    /*
    NSDictionary *vars = [SystemUtils getSystemInfo:@"kGiftEmailVars"];
    if(vars && [vars isKindOfClass:[NSDictionary class]] && [vars count]>0)
    {
        for (NSString *key in [vars allKeys]) {
            bodyFmt = [bodyFmt stringByReplacingOccurrencesOfString:key withString:[vars objectForKey:key]];
            SNSLog(@"replace:%@",key);
        }
    }
     */
    NSString *appID = [SystemUtils getSystemInfo:@"kiTunesAppID"];
    bodyFmt = [bodyFmt stringByReplacingOccurrencesOfString:@"__APP_NAME__" withString:gameName];
    bodyFmt = [bodyFmt stringByReplacingOccurrencesOfString:@"__APP_ID__" withString:appID];
    bodyFmt = [bodyFmt stringByReplacingOccurrencesOfString:@"__ITUNES_ID__" withString:appID];
    // SNSLog(@"bodyFmt:%@",bodyFmt);
    NSString *uid = [SystemUtils getCurrentUID];
    NSString *topAppID = [SystemUtils getSystemInfo:@"kFlurryCallbackAppID"];
    NSString *gid = [NSString stringWithFormat:@"%i-%@", [SystemUtils getTodayDate], uid];
    NSString *hash = [self getGiftHash:[NSString stringWithFormat:@"%@-%@-%i-%@", uid, coinName, awardNum, gid]];
    NSString *scheme = [SystemUtils getSystemInfo:@"kMyAppURLScheme"];
    NSString *gift = [NSString stringWithFormat:@"emailgift?type=%2$@&amp;count=%1$d&amp;uid=%3$@&amp;sig=%4$@&amp;gid=%5$@", awardNum, coinName, uid, hash, gid];
    NSString *giftLink = [NSString stringWithFormat:@"http://www.topgame.com/gm/email-gift.php?appID=%@&scheme=%@&gift=%@", topAppID, scheme, [StringUtils stringByUrlEncodingString:gift]];
	NSString *body = [NSString stringWithFormat:bodyFmt, 
                      awardNum, coinName2,  giftLink, gameName,
                      [SystemUtils getAppDownloadShortLink] ];
    
    SNSLog(@"Email Body:%@",body);
	SendEmailViewController *messageView = [[SendEmailViewController alloc] init];
    
#ifdef SNS_POP_MAILCOMPOSER_IN_ROOTVIEW
    messageView.useRootView = YES;
#endif
    
	[messageView displayComposerSheet:emails 
							withTitle:title
							  andBody:body
						andAttachData:nil 
				   withAttachFileName:nil];
    
    pMailComposer = messageView;
    
    nWriteEmailStatus = 3;
    
    [[SnsStatsHelper helper] logAction:@"sendEmailGift"];
}

// 接收邮件礼物奖励
- (void) onReceiveEmailGift:(NSString *)query
{
    if(m_emailGiftQuery) [m_emailGiftQuery release];
    m_emailGiftQuery = [query retain];
    [[SnsStatsHelper helper] logAction:@"getEmailGift"];
}
// 发放邮件礼物
- (void) checkEmailGift
{
    if(m_emailGiftQuery == nil) return;
    NSDictionary *dict = [StringUtils parseURLQueryStringToDictionary:m_emailGiftQuery];
    [m_emailGiftQuery release];
    m_emailGiftQuery = nil;
    NSString *uid = [dict objectForKey:@"uid"];
    NSString *type = [dict objectForKey:@"type"];
    NSString *count = [dict objectForKey:@"count"];
    NSString *sig = [dict objectForKey:@"sig"];
    NSString *gid = [dict objectForKey:@"gid"];
    NSString *title = nil; NSString *mesg = nil;
    // 不能自己发给自己礼物
    if([uid isEqualToString:[SystemUtils getCurrentUID]] && ![uid isEqualToString:@"0"])
    {
        title = [SystemUtils getLocalizedString:@"Invalid Sender"];
        mesg = [SystemUtils getLocalizedString:@"You can't accept gift from yourself!"];
        [SystemUtils showSNSAlert:title message:mesg];
        return;
    }
    // 验证是否已经接收过了
    NSString *gidkey = [NSString stringWithFormat:@"GID_%@",gid];
    if([[SystemUtils getPlayerDefaultSetting:gidkey] intValue]==1) {
        title = [SystemUtils getLocalizedString:@"Duplicated Gift"];
        mesg = [SystemUtils getLocalizedString:@"You've already received this gift."];
        [SystemUtils showSNSAlert:title message:mesg];
        return;
    }
    // 验证签名
    NSString *hash = [self getGiftHash:[NSString stringWithFormat:@"%@-%@-%@-%@", uid, type, count, gid]];
    if(![hash isEqualToString:sig]) {
        title = [SystemUtils getLocalizedString:@"Invalid Gift Link"];
        mesg = [SystemUtils getLocalizedString:@"This gift link is invalid, please ask your friend to send again."];
        [SystemUtils showSNSAlert:title message:mesg];
        return;
    }
    // 检查每日限额, 暂时不限制
    // 保存GID
    [SystemUtils setPlayerDefaultSetting:@"1" forKey:gidkey];
    // 发放奖励
    int gold = [count intValue];
    [SystemUtils addItem:type withCount:gold];
    title = [SystemUtils getLocalizedString:@"Gift Received"];
    NSString *giftMesg = [SystemUtils getSystemInfo:@"kGiftAcceptMessage"];
    if(giftMesg==nil) giftMesg = @"Congratulations! You just got a gift of %1$@ %2$@!";
    NSString *coinName = [SystemUtils getLocalizedString:type];
    mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:giftMesg], count, coinName];
    [SystemUtils showSNSAlert:title message:mesg];
    
    [[SnsStatsHelper helper] logAction:@"verifyEmailGift"];
    [[SnsStatsHelper helper] logResource:kCoinType1 change:gold channelType:kResChannelEmailGift];
}

// 完成发送邮件
-(void) onComposeEmailFinished:(NSNotification *)note
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationComposeEmailFinish object:nil];
    int res = 0;
    if(note.userInfo) res = [[note.userInfo objectForKey:@"result"] intValue];
    if(res == 1)
    {
        // 显示验证提示
        //[[TinyiMailHelper helper] showSentHint];
        if(nWriteEmailStatus==1) {
            // 成功发出验证邮件
            [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:[SystemUtils getCurrentTime]+86400] forKey:@"kSendVerifyEmailTime"];
        }
        if(nWriteEmailStatus==2) {
            // 成功发出邀请邮件
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:res], @"result", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSendInvitationEmailFinish object:nil userInfo:userInfo];
        }
        if(nWriteEmailStatus==3) {
            // 成果发出礼物邮件
        }
    }
    nWriteEmailStatus = 0;
    SNSReleaseObj(pMailComposer);
}



#pragma mark -

#ifdef  SNS_USE_ADDRESSBOOK_UI


#pragma mark ABPeoplePickerNavigationControllerDelegate


- (void) showPeopleHasNoEmailAlert:(NSString *)firstName
{
    NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString: @"%@'s email address is not found, please select another one with email address!"], firstName];
    SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:[SystemUtils getLocalizedString: @"No Email Address"]
                        message:mesg
                        delegate:self
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertInviteNoEmailFound;
    // [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av showHard];
    [av release];
}

// Called after the user has pressed cancel
// The delegate is responsible for dismissing the peoplePicker
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    UIViewController *ct = [SystemUtils getAbsoluteRootViewController];
    [ct dismissModalViewControllerAnimated:YES];
}

// Called after a person has been selected by the user.
// Return YES if you want the person to be displayed.
// Return NO  to do nothing (the delegate is responsible for dismissing the peoplePicker).
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    // get player email address
    NSString* firstName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    if(!firstName) firstName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    
    NSString* email = nil;
    ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (ABMultiValueGetCount(emails) > 0) {
        email = (__bridge_transfer NSString*)
            ABMultiValueCopyValueAtIndex(emails, 0);
        [self sendInvitationEmailTo:email withName:firstName];
        
    } else {
        // no email alert
        [self showPeopleHasNoEmailAlert:firstName];
    }
    
    /*
    if(!email) {
        NSString* phone = nil;
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        if (ABMultiValueGetCount(phoneNumbers) > 0) {
            phone = (__bridge_transfer NSString*)
            ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
        } else {
            // no phone
        }
        if(phone) {
            // TODO: send short message
        }
    }
     */
    
    
    [self peoplePickerNavigationControllerDidCancel:peoplePicker];
    return NO;
}
// Called after a value has been selected by the user.
// Return YES if you want default action to be performed.
// Return NO to do nothing (the delegate is responsible for dismissing the peoplePicker).
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    [self peoplePickerNavigationControllerDidCancel:peoplePicker];
    return NO;
}

#pragma mark -

#endif

#pragma mark SNSAlertViewDelegate
- (void)snsAlertView:(SNSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == kTagAlertInviteNoEmailFound)
    {
        [self writeInvitationEmail];
    }
}

#pragma mark -

@end
