//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "FacebookHelper.h"
#import "SystemUtils.h"
#import "SNSAlertView.h"
#import "smPopupWindowQueue.h"
#import "FacebookFeedViewController.h"
#import "StringUtils.h"
#import "SnsStatsHelper.h"
#import "SnsServerHelper.h"
#import "SBJson.h"
#import "NSData+Compression.h"
#import "SnsGameHelper.h"
#ifdef SNS_ENABLE_FLURRY_V2
#import "Flurry.h"
#endif
#import "ASIFormDataRequest.h"
enum {
    kSessionStatusNone = 0,
    kSessionStatusSendInvitation,
    kSessionStatusPublishFeed,
    kSessionStatusConnectFirstTime,
};

enum {
    kFacebookOperationFeed = 1,
    kFacebookOperationPublishPhoto = 2,
    kFacebookOperationSendRequest = 3,
    kFacebookOperationGetInviteRequest = 4,
};

enum {
    kFacebookAlertTagConnectFirstTime = 1,
    kFacebookAlertTagSwitchAccount,
    kFacebookAlertTagSendingGifts,
};

enum {
    kFacebookHelperRequestTypeNone = 0,
    kFacebookHelperRequestTypeBindAccount = 1,
    kFacebookHelperRequestTypeLoadIcon = 2,
    kFacebookHelperRequestTypeSyncAccount = 3,
    kFacebookHelperRequestTypeGetUserToken = 4,
};

@interface FacebookHelper()<UIAlertViewDelegate,FBFriendPickerDelegate>

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error;
- (void)requestCompleted:(FBRequestConnection *)connection
                 forFbID:fbID
           operationType:(int)type
                  result:(id)result
                   error:(NSError *)error;


@property (retain, nonatomic) FBFriendPickerViewController *friendPickerController;
@property (retain, nonatomic) FBRequestConnection *requestConnection;
@property (nonatomic, retain) NSURL *openedURL;
@end

@protocol FBGraphUserExtraFields <FBGraphUser>

@property (nonatomic, retain) NSArray *devices;

@end

@implementation FacebookHelper

@synthesize fbUserID=_fbUserID;
@synthesize fbUserName = _fbUserName;
@synthesize friendPickerController = _friendPickerController;
@synthesize requestConnection = _requestConnection;
@synthesize fbUserInfo = _fbUserInfo;
@synthesize openedURL = _openedURL;

static FacebookHelper *_gFacebookHelper = nil;

+ (FacebookHelper *) helper
{
    if(!_gFacebookHelper) {
        _gFacebookHelper = [[FacebookHelper alloc] init];
    }
    return _gFacebookHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        delegate = nil;
        isInitialized = NO; arrKNFriendItems = nil; iKNInviteCount = 0; arrKNFriendInvited = nil;
        isEnabled = NO; iSessionStatus = kSessionStatusNone;
        invitedFriendList = nil; requestType = 0;
        iTotalFriendCount = 0; allFriendList = nil; pendingTasks = nil; arrPendingTicketRequests = nil;
        // iTotalFriendCount = [[SystemUtils getNSDefaultObject:@"kSGFBFriendCount"] intValue];
        [self initHelper];
    }
    return self;
}

- (void) dealloc
{
    self.fbUserID = nil; self.fbUserName = nil; self.fbUserInfo = nil;
    self.friendPickerController = nil; self.requestConnection = nil; self.openedURL = nil;
    if(invitedFriendList) {
        [invitedFriendList release];
        invitedFriendList = nil;
    }
    if(pendingTasks) {
        [pendingTasks release]; pendingTasks = nil;
    }
    if(arrKNFriendItems) {
        [arrKNFriendItems release]; arrKNFriendItems = nil;
    }
    if(arrPendingTicketRequests) {
        [arrPendingTicketRequests release];
    }
    [super dealloc];
}

- (void) initHelper
{
    if(isInitialized) return;
    if([[SystemUtils getiOSVersion] compare:@"5.0"]<0) {
        return;
    }
    isInitialized = YES;
    
    self.fbUserID = [SystemUtils getNSDefaultObject:@"kFBUserID"];
    self.fbUserName = [SystemUtils getNSDefaultObject:@"kFBUserName"];
    
#ifdef DEBUG
    [FBSettings setLoggingBehavior:
     [NSSet setWithObject:FBLoggingBehaviorFBRequests]];
#endif
    
    // auto login if already has token
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        // Yes, so just open the session (this won't display any UX).
        [self startLogin];
    }else{
        [self clearFbUserInfo];
    }
}

- (BOOL) isLoggedIn
{
    return (FBSession.activeSession.state == FBSessionStateOpen && FBSession.activeSession.isOpen);
}

- (void) addPendingTasks:(NSDictionary *)taskInfo
{
    if(pendingTasks==nil) pendingTasks = [[NSMutableArray alloc] init];
    [pendingTasks addObject:taskInfo];
}


- (void) startPendingTask
{
    if(pendingTasks && [pendingTasks count]>0) {
        NSDictionary *taskInfo = [pendingTasks objectAtIndex:0]; [taskInfo retain];
        [pendingTasks removeObjectAtIndex:0];
        int type = [[taskInfo objectForKey:@"type"] intValue];
        if(type == kFacebookOperationFeed) {
            [self publishCustomizedFeed:[taskInfo objectForKey:@"info"]];
        }
        if(type == kFacebookOperationPublishPhoto) {
            [self publishPhoto:[taskInfo objectForKey:@"image"] withCaption:[taskInfo objectForKey:@"caption"]];
        }
        if(type == kFacebookOperationGetInviteRequest) {
            [self notificationGet:[taskInfo objectForKey:@"requestid"]];
        }
        if(type == kFacebookOperationSendRequest) {
        }
        
        [taskInfo release];
    }
    else {
        /*
         // 不要自动弹出邀请框
        int prizeStatus = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"fbInviteFriends"] intValue];
        if(prizeStatus==1) return;
        [[SystemUtils getGameDataDelegate] setExtraInfo:@"1" forKey:@"fbInviteFriends"];
        [self showSelectFriends:NO];
         */
    }
}

- (void) checkSessionStatus
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    // FBSample logic
    // We need to properly handle activation of the application with regards to SSO
    //  (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
    [FBSession.activeSession handleDidBecomeActive];
    
}

- (BOOL) checkPublishPermission
{
    // publish_stream is superset of publish_actions
    // Ask for publish_actions permissions in context
    if(!FBSession.activeSession.isOpen) {
        [self startLogin];
        return NO;
    }
    
    if ([FBSession.activeSession.permissions
         indexOfObject:@"publish_actions"] == NSNotFound) {
        // No permissions found in session, ask for it
        [FBSession.activeSession
         requestNewPublishPermissions:
         [NSArray arrayWithObject:@"publish_actions"]
         defaultAudience:FBSessionDefaultAudienceFriends
         completionHandler:^(FBSession *session, NSError *error) {
             if (!error) {
                 // If permissions granted, publish the story
                 // [self publishStory];
             }
             else {
                 // show alert
                 // [self cancelButtonAction:nil];
#ifdef SNS_ENABLE_FLURRY_V2
                 [Flurry logError:@"FacebookError" message:@"reauthorizeWithPublishPermissions fail" error:error];
#endif
             }
         }];
        return NO;
    } else {
        // If permissions present, publish the story
        // [self publishStory];
        return YES;
    }
    
}

- (BOOL) handleOpenURL:(NSURL *)url
{
    self.openedURL = url;
    SNSLog(@"URL:%@",[url absoluteString]);
    return [FBSession.activeSession handleOpenURL:url];
}

- (void) closeSession
{
    [[FBSession activeSession] closeAndClearTokenInformation];
    // [[FBSession activeSession] close];
}

-(void)fbResync
{
    if([[SystemUtils getiOSVersion] compare:@"6.0"]<0) return;
    
    ACAccountStore *accountStore  = [[ACAccountStore alloc] init];
    ACAccountType *accountTypeFB;
    if ((accountStore!=nil) && (accountTypeFB = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook] ) ){
        
        NSArray *fbAccounts = [accountStore accountsWithAccountType:accountTypeFB];
        id account;
        if (fbAccounts && [fbAccounts count] > 0 && (account = [fbAccounts objectAtIndex:0])){
            
            [accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
                //we don't actually need to inspect renewResult or error.
                if (error){
                    
                }
            }];
        }
        [accountStore autorelease];
    }else if(accountStore!=nil){  //xiawei add , 条件判断不成功的时候也要释放accountStore
        [accountStore autorelease];
    }
    
}

- (void)startLogin
{
    if([SystemUtils getGameDataDelegate]==nil) return;
    
    NSString *fbAppID = [SystemUtils getSystemInfo:@"kFacebookAppID"];
    NSString *fbURLSchemeSuffix = [SystemUtils getSystemInfo:@"kFacebookURLSchemeSuffix"];
    if(fbURLSchemeSuffix && [fbURLSchemeSuffix length]==0) fbURLSchemeSuffix = nil;
    // [NSArray arrayWithObject:@"publish_actions"];
    /*
    FBSession *session1 = [[FBSession alloc] initWithAppID:fbAppID permissions:nil urlSchemeSuffix:fbURLSchemeSuffix tokenCacheStrategy:nil];
    [FBSession setActiveSession:session1];
    [session1 openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
             completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
        [self sessionStateChanged:session state:state error:error];
    }];
    [session1 release];
     */
    
    
    FBSession *session1 = [[FBSession alloc] initWithAppID:fbAppID permissions:[NSArray arrayWithObjects:@"user_birthday", nil] urlSchemeSuffix:fbURLSchemeSuffix tokenCacheStrategy:nil];
    [FBSession setActiveSession:session1];
    [session1 autorelease];
    
    dispatch_async(dispatch_get_main_queue(), ^{
    // [FBSession openActiveSessionWithReadPermissions:nil allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState state, NSError *error)
        [session1 openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                 completionHandler:^(FBSession *session, FBSessionState state, NSError *error)
        {
        SNSLog(@"state:%i error:%@",state,error);
            [self sessionStateChanged:session state:state error:error]; return;

        if(error)
        {
            [self fbResync];
            [self closeSession];
            [NSThread sleepForTimeInterval:0.5f];   //half a second
            FBSession *session2 = [[FBSession alloc] initWithAppID:fbAppID permissions:nil urlSchemeSuffix:fbURLSchemeSuffix tokenCacheStrategy:nil];
            [FBSession setActiveSession:session2];
            [session2 openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                     completionHandler:^(FBSession *session2a, FBSessionState state, NSError *error)
                    {
                         [self sessionStateChanged:session2a state:state error:error];
                     }];

            /*
            [FBSession openActiveSessionWithReadPermissions:nil
                                               allowLoginUI:YES
                                          completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                              [self sessionStateChanged:session state:state error:error];
                                          }];
             */
            
        }
        else
            [self sessionStateChanged:session state:state error:error];
        
    }];
    
    SNSLog(@"login finished");
    
    /*
    [FBSession openActiveSessionWithReadPermissions:nil
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session,
       FBSessionState state, NSError *error) {
         [self sessionStateChanged:session state:state error:error];
     }];
     */
    });
}

- (void) setBonusDate
{
    NSString *today = [NSString stringWithFormat:@"%i",[SystemUtils getTodayDate]];
    [SystemUtils setNSDefaultObject:today forKey:@"kFBBonusDate"];
    [[SystemUtils getGameDataDelegate] setExtraInfo:today forKey:@"kFBBonusDate"];
}

- (BOOL) ifGotInviteBonus
{
    int date = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"kFBBonusDate"] intValue];
    if(date==[SystemUtils getTodayDate]) return YES;
    return NO;
}

- (BOOL) ifGotConnectPrize
{
    if([SystemUtils getGameDataDelegate]==nil) return NO;
    int prizeStatus = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"fbConnectPrize"] intValue];
    if(prizeStatus==1) return YES;
    return NO;
    
}

- (void) showConnectFirstTimePrize
{
    if([SystemUtils getGameDataDelegate]==nil) return;
    int prizeStatus = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"fbConnectPrize"] intValue];
    if(prizeStatus==1) {
        int conndate = [[SystemUtils getNSDefaultObject:@"kFBConnectDate"] intValue];
        if(conndate==0)
            [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:[SystemUtils getTodayDate]] forKey:@"kFBConnectDate"];
        return;
    }
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:[SystemUtils getTodayDate]] forKey:@"kFBConnectDate"];
    int count = [[SystemUtils getRemoteConfigValue:@"kFacebookConnectPrize"] intValue];
    if(count==0) count = [[SystemUtils getRemoteConfigValue:@"kFacebookDailyPrize"] intValue];
    if(count==0) return;
    [[SystemUtils getGameDataDelegate] setExtraInfo:@"1" forKey:@"fbConnectPrize"];
    
    int type = [[SystemUtils getRemoteConfigValue:@"kFacebookPrizeType"] intValue];
    if(type==0) type = kGameResourceTypeCoin;
    [SystemUtils addGameResource:count ofType:type];
    NSString *coinName = [SystemUtils getLocalizedString:@"CoinName1"];
    if(type==2) coinName = NSLocalizedStringFromTable(@"CoinName2",@"GameLocalizable",nil);//[SystemUtils getLocalizedString:@"CoinName2"];
    if(count>1) coinName = [StringUtils getPluralFormOfWord:coinName];
    
    NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Thanks for connecting to Facebook! You've got %i %@ as a reward!"], count, coinName];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Connect Bonus"]
                              message:mesg
                              delegate:nil
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                              otherButtonTitles:nil];
    // alertView.tag = 1314;
    [alertView show];
    [alertView release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUi" object:nil];
}

- (void) showInviteFriendsPrize:(int)friendCount
{
    
    [[SnsStatsHelper helper] logAction:@"fbInvite" withCount:friendCount];
    
    if([self ifGotInviteBonus]) return;
    [self setBonusDate];
    
    int count = [[SystemUtils getRemoteConfigValue:@"kFacebookDailyPrize"] intValue];
    if(count==0) {
        count = [[SystemUtils getRemoteConfigValue:@"kFacebookConnectPrize"] intValue];
        count = count/2;
    }
    if(count==0) return;
    if(friendCount>5) friendCount = 5;
    count = count*friendCount;
    int type = [[SystemUtils getRemoteConfigValue:@"kFacebookDailyPrizeType"] intValue];
    if(type==0) type = [[SystemUtils getRemoteConfigValue:@"kFacebookPrizeType"] intValue];
    //int type = kGameResourceTypeCoin;
    if(type==0) type = kGameResourceTypeCoin;
    [[SystemUtils getGameDataDelegate] addGameResource:count ofType:type];
    NSString *coinName = [SystemUtils getLocalizedString:@"CoinName1"];
    if(type==2) coinName = [SystemUtils getLocalizedString:@"CoinName2"];
    else if(type!=1) {
        coinName = [SystemUtils getLocalizedString:[NSString stringWithFormat:@"CoinName%d",type]];
    }
    if(count>1) coinName = [StringUtils getPluralFormOfWord:coinName];
    NSString *friend = @"friend";
    if(friendCount>1) friend = @"friends";
    
    NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Thanks for inviting %i %@, you've got %i %@ as a bonus!"], friendCount, friend, count, coinName];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Invite Bonus"]
                              message:mesg
                              delegate:nil
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

- (void) showFacebookFeedPrize
{
    [self startPendingTask];
    
    [[SnsStatsHelper helper] logAction:@"fbFeed" withCount:1];
    
    int feedCount = [[SystemUtils getNSDefaultObject:@"kZBSetFBFeedCount"] intValue];
    feedCount++;
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:feedCount] forKey:@"kZBSetFBFeedCount"];
    
    if (feedCount > 1)
        return;
    
    [self setBonusDate];
    
    int count = [[SystemUtils getRemoteConfigValue:@"kFacebookDailyPrize"] intValue];
    if(count==0) return;
    int type = [[SystemUtils getRemoteConfigValue:@"kFacebookDailyPrizeType"] intValue];
    if(type==0) type = [[SystemUtils getRemoteConfigValue:@"kFacebookPrizeType"] intValue];
    if(type==0) type = kGameResourceTypeCoin;
    [[SystemUtils getGameDataDelegate] addGameResource:count ofType:type];
    NSString *coinName = [SystemUtils getLocalizedString:@"CoinName1"];
    if(type==2) coinName = [SystemUtils getLocalizedString:@"CoinName2"];
    if(count>1) coinName = [StringUtils getPluralFormOfWord:coinName];
    
    NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Thanks for sharing to Facebook, you've got %i %@ as a bonus!"], count, coinName];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Feed Bonus"]
                              message:mesg
                              delegate:nil
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

- (void) showFacebookNotificationGift:(int)count type:(int)type from:(NSString *)friendName
{
    [[SystemUtils getGameDataDelegate] addGameResource:count ofType:type];
    NSString *coinName = [SystemUtils getLocalizedString:@"CoinName1"];
    if(type==2) coinName = [SystemUtils getLocalizedString:@"CoinName2"];
    else if(type!=1) {
        coinName = [SystemUtils getLocalizedString:[NSString stringWithFormat:@"CoinName%d",type]];
    }
    if(count>1) coinName = [StringUtils getPluralFormOfWord:coinName];
    
    NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"You just received %d %@ from %@!"], count, coinName, friendName];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Friend Gift"]
                              message:mesg
                              delegate:nil
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    
}

- (void) loginFinished:(BOOL) success
{
    NSDictionary *userInfo = nil;
    if(success){
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:_fbUserID,@"id", _fbUserName, @"name", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationOnLoginFinished object:nil userInfo:userInfo];
    }
    else{
        [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationOnLoginFaild object:nil userInfo:Nil];
    }
    if(success) {
        [SystemUtils setNSDefaultObject:@"1" forKey:@"kFBConnectedBefore"];
        if(iSessionStatus == kSessionStatusSendInvitation)
            [self showSelectFriends:NO];
        [self showConnectFirstTimePrize];
        [self startPendingTask];
        
#ifdef SNS_AUTOLOAD_FB_ICON
        [self loadFacebookIcon:_fbUserID];
#endif

#ifdef SNS_SYNCFACEBOOK
        [self getAllFriends:[SnsGameHelper helper]];
        // start sync gamedata with accesstoken
//        [self startSync];
#else
        // start bind fbid with userID
        NSString *bindUID = [SystemUtils getNSDefaultObject:@"kFBBindUID"];
        if(bindUID==nil) {
            [self startBind];
        }
#endif
    }else{
        [FBSession.activeSession closeAndClearTokenInformation];
        [self clearFbUserInfo];
        [SystemUtils setNSDefaultObject:NULL forKey:@"kFBUserToken"];
    }
}


// 检查是否曾经connect过
- (BOOL) ifConnectedBefore
{
    if(self.fbUserID!=nil && [self.fbUserID length]>0) return YES;
    int val = [[SystemUtils getNSDefaultObject:@"kFBConnectedBefore"] intValue];
    if(val==1) return YES;
    return NO;
}


- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    SNSLog(@"state:%i error:%@",state,error);
    if(error) {
#ifdef SNS_ENABLE_FLURRY_V2
        [Flurry logError:@"FacebookError" message:@"sessionStateChanged error" error:error];
#endif
    }
    switch (state) {
        case FBSessionStateOpen: {
            // request user's info
            if(self.fbUserID==nil) {
            [[FBRequest requestForMe] startWithCompletionHandler:
             ^(FBRequestConnection *connection,
               NSDictionary<FBGraphUser> *user,
               NSError *error) {
                 if (!error) {
                     // login ok
                     [self saveFbUserInfo:user];
                     [self loginFinished:YES];
                 }
                 else {
#ifdef SNS_ENABLE_FLURRY_V2
                     [Flurry logError:@"FacebookError" message:@"requestForMe error" error:error];
#endif
                     [self loginFinished:NO];
                 }
             }];
            }
            else {
                [self loginFinished:YES];
            }
        }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            // Once the user has logged in, we want them to
            // be looking at the root view.
            // [self.navController popToRootViewControllerAnimated:NO];
            
            [FBSession.activeSession closeAndClearTokenInformation];
            self.fbUserID = nil;
            [self clearFbUserInfo];
            [SystemUtils setNSDefaultObject:NULL forKey:@"kFBUserToken"];
            break;
        default:
            break;
    }

    if (error && error.code!=FBErrorOperationCancelled) {
#ifdef SNS_ENABLE_FLURRY_V2
        [Flurry logError:@"FacebookError" message:@"Failed to login" error:error];
#endif
        [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationOnLoginFaild object:nil userInfo:Nil];

        NSString *errorTitle = [SystemUtils getLocalizedString:@"Error"];
        NSString *errorMessage = [error localizedDescription];
        if (error.code == FBErrorLoginFailedOrCancelled) {
            errorTitle = [SystemUtils getLocalizedString:@"Facebook Login Failed"];
            errorMessage = [SystemUtils getLocalizedString:@"Sorry, there was a problem accessing your Facebook account. Please try logging in again."];
            // errorMessage = [NSString stringWithFormat:@"%@\nerror:%@",errorMessage, error.description];
        }
        // if(error.code == FBErrorNonTextMimeTypeReturned)
        [self fbResync];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:errorTitle
                                                            message:errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    }
}

- (void) logout
{
    [self clearFbUserInfo];
    [FBSession.activeSession closeAndClearTokenInformation];
}

- (void) saveFbUserInfo:(NSDictionary<FBGraphUser> *)info
{
    self.fbUserName = info.name;
    self.fbUserID   = [info objectForKey:@"id"];
    self.fbUserInfo = info;
    [SystemUtils setNSDefaultObject:self.fbUserID forKey:@"kFBUserID"];
    [SystemUtils setNSDefaultObject:self.fbUserName forKey:@"kFBUserName"];
    if([SystemUtils getGameDataDelegate]) {
        // save fbid, send prize
        [[SystemUtils getGameDataDelegate] setExtraInfo:self.fbUserID forKey:@"kFBID"];
    }
}
- (void) clearFbUserInfo
{
    self.fbUserID = nil; self.fbUserName = nil; self.fbUserInfo = nil;
    [SystemUtils setNSDefaultObject:self.fbUserID forKey:@"kFBUserID"];
    [SystemUtils setNSDefaultObject:self.fbUserName forKey:@"kFBUserName"];
}

- (BOOL) isAllFriendInvited
{
    if(allFriendList && iTotalFriendCount>=[allFriendList count]) return YES;
    return NO;
}

- (void) loadSelectedFriends
{
    arrKNFriendInvited = [[NSMutableArray alloc] init];
    int inviteDate = [[SystemUtils getNSDefaultObject:@"kKNFBInviteDate"] intValue];
    int today = [SystemUtils getTodayDate];
    if(today==inviteDate) {
        // load existing friend list
        NSArray *arr = [SystemUtils getNSDefaultObject:@"kKNFBInvitedFriends"];
        if(arr!=nil) [arrKNFriendInvited addObjectsFromArray:arr];
    }
}

- (void) saveSelectedFriends
{
    int today = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:arrKNFriendInvited forKey:@"kKNFBInvitedFriends"];
    [SystemUtils setNSDefaultObject:[NSString stringWithFormat:@"%d",today] forKey:@"kKNFBInviteDate"];
}

- (BOOL) isFriendSelected:(NSString *)uid
{
    if(arrKNFriendInvited==nil || [arrKNFriendInvited count]==0) return NO;
    for(NSString *u in arrKNFriendInvited) {
        if([u isEqualToString:uid]) return YES;
    }
    return NO;
}

- (void) showSelectFriends:(BOOL)onlyInstalled {
    if(![self isLoggedIn]) {
        [self startLogin];
        return;
    }
    
    if(arrKNFriendItems!=nil && iKNInviteCount<[arrKNFriendItems count]) {
        // continue select friends
        [self showSelectFriendsSelector];
        return;
    }
    
    NSString *reqpath = @"me/friends";
    if(onlyInstalled) reqpath = @"me/friends?fields=name,installed";
    
    // start loading friends
    FBRequestConnection *conn = [[FBRequestConnection alloc] initWithTimeout:10];
    // show loading view
    [SystemUtils showInGameLoadingView];
    FBRequest *req = [[FBRequest alloc] initWithSession:[FBSession activeSession] graphPath:reqpath];
    [conn addRequest:req completionHandler:^(FBRequestConnection *conn2, id result, NSError *error)
    {
        [conn2 release];
        [SystemUtils hideInGameLoadingView];
        NSDictionary *dict = result;
        if(error) {
            // TODO: 提示获取好友列表失败
            SNSLog(@"Failed to get user's friends:%@", error);
            NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Failed to load friend list from facebook.\n%@"], error];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[SystemUtils getLocalizedString:@"Request Failed"]
                                                                message:mesg
                                                               delegate:nil
                                                      cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                                                      otherButtonTitles:nil];
            [alertView show];
            [alertView release];
            return;
        }
        if(arrKNFriendItems) [arrKNFriendItems removeAllObjects];
        else {
            arrKNFriendItems = [[NSMutableArray alloc] init];
        }
        [self loadSelectedFriends];
        NSArray * dataArray = [dict objectForKey:@"data"];
        for (NSDictionary * f in dataArray) {
            if(onlyInstalled) {
                if([[f objectForKey:@"installed"] intValue]==0) continue;
            }
            NSString *uid = [f objectForKey:@"id"];
            // 1137856968: hotmail,  1607073362 gmail
            // if(![uid isEqualToString:@"1137856968"]) continue;
            // if(![uid isEqualToString:@"1607073362"]) continue;
            if([self isFriendSelected:uid]) continue;
            KNSelectorItem *item = [[KNSelectorItem alloc] initWithDisplayValue:[f objectForKey:@"name"]
                                                                    selectValue:uid
                                                                       imageUrl:[NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=square", [f objectForKey:@"id"]]];
            [arrKNFriendItems addObject:item];
            [item autorelease];
        }
        iKNInviteCount = 0;
        [self showSelectFriendsSelector];
    }];
    [req autorelease];
    [conn start];
    // [[FBSession activeSession] requestWithGraphPath:@"me/friends" andDelegate:self];
    
}
#define FB_MAX_REQUEST_RECEIPIENTS  30
#ifdef DEBUG
// #define FB_MAX_REQUEST_RECEIPIENTS  2
#else
// #define FB_MAX_REQUEST_RECEIPIENTS  30
#endif
- (void)showSelectFriendsSelector {
    
    if(iKNInviteCount>=[arrKNFriendItems count]) {
        int today = [SystemUtils getTodayDate];
        [SystemUtils setNSDefaultObject:[NSString stringWithFormat:@"%d",today] forKey:@"kAllFBFriendInvitedDate"];
        
        // alert
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[SystemUtils getLocalizedString: @"No More Friends"]
                                                            message:[SystemUtils getLocalizedString: @"You've sent gifts to all of you friends today. You can send again tomorrow."]
                                                           delegate:nil
                                                  cancelButtonTitle:[SystemUtils getLocalizedString: @"OK"]
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        return;
    }
    
    // You can even change the title and placeholder text for the selector
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    int i=0;
    for(i=iKNInviteCount;i<[arrKNFriendItems count];i++) {
        if(i-iKNInviteCount==FB_MAX_REQUEST_RECEIPIENTS) break;
        [arr addObject:[arrKNFriendItems objectAtIndex:i]];
    }
    
    if([arr count]==0) {
        SNSLog(@"No friends found:%@", arr); [arr release];
        return;
    }
    
    iKNInviteCount = i;
    KNMultiItemSelector * selector = [[KNMultiItemSelector alloc] initWithItems:arr
                                                               preselectedItems:arr
                                                                          title:@"Send Gift to Friends"
                                                                placeholderText:@"Search by name"
                                                                       delegate:self];
    // Again, the two optional settings
    selector.allowSearchControl = YES;
    selector.useTableIndex      = YES;
    selector.useRecentItems     = YES;
    selector.maxNumberOfRecentItems = 4;
    selector.allowModeButtons = NO;
    UINavigationController * uinav = [[UINavigationController alloc] initWithRootViewController:selector];
    uinav.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    uinav.modalPresentationStyle = UIModalPresentationFormSheet;
    UIViewController *root = [SystemUtils getRootViewController];
    if(root)
        [root presentModalViewController:uinav animated:YES];
    // [selector autorelease];
    [arr release];
    [selector release];
    [uinav autorelease];
}

-(void)selectorDidCancelSelection:(KNMultiItemSelector *)selector
{
    // do nothing
    [[SystemUtils getRootViewController] dismissModalViewControllerAnimated:NO];
    // [selector autorelease];
    iKNInviteCount -= FB_MAX_REQUEST_RECEIPIENTS;
    if(iKNInviteCount<0) iKNInviteCount = 0;
}
-(void)selector:(KNMultiItemSelector *)selector didFinishSelectionWithItems:(NSArray*)selectedItems
{
    [[SystemUtils getRootViewController] dismissModalViewControllerAnimated:NO];
    if(selectedItems==nil || [selectedItems count]==0) {
        iKNInviteCount -= FB_MAX_REQUEST_RECEIPIENTS;
        if(iKNInviteCount<0) iKNInviteCount = 0;
        return;
    }
    // [selector autorelease];
    // send requests to friends
    NSMutableString *uidList = [[NSMutableString alloc] init]; int count = 0; [uidList autorelease];
    for (KNSelectorItem * i in selectedItems) {
        NSString *uid = i.selectValue;
        [arrKNFriendInvited addObject:uid];
        if(count>0) [uidList appendString:@","];
        [uidList appendString:uid];
        count++;
    }
    if(count==0) {
        iKNInviteCount -= FB_MAX_REQUEST_RECEIPIENTS;
        if(iKNInviteCount<0) iKNInviteCount = 0;
        return;
    }
    [self saveSelectedFriends];
    
    NSMutableDictionary* params =   [NSMutableDictionary dictionaryWithObjectsAndKeys:uidList, @"to",nil];

    NSString *inviteMessage = [SystemUtils getSystemInfo:@"kFacebookRequestMessage"];
    NSString *gift = [SystemUtils getSystemInfo:@"kFacebookRequestPrize"];
    // 如果有多种奖励，就随机选一个
    NSArray *arr = [gift componentsSeparatedByString:@","];
    if([arr count]>1) {
        int idx = rand()%[arr count];
        gift = [arr objectAtIndex:idx];
        inviteMessage = [SystemUtils getSystemInfo:[NSString stringWithFormat:@"kFacebookRequestMessage%d", idx]];
    }
    // data, message
    if(inviteMessage) [params setValue:inviteMessage forKey:@"message"];
    if(gift) [params setValue:gift forKey:@"data"];
    
    [FBWebDialogs presentRequestsDialogModallyWithSession:[FBSession activeSession]
                                                  message:inviteMessage
                                                    title:@"Send Gift"
                                               parameters:params
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                      if (error) {
                                                          // Case A: Error launching the dialog or sending request.
                                                          SNSLog(@"Error sending request.");
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              // Case B: User clicked the "x" icon
                                                              SNSLog(@"User canceled request.");
                                                          } else {
                                                              // Handle the send request callback
                                                              NSDictionary *urlParams = [StringUtils parseURLParams:[resultURL query]];
                                                              if (![urlParams valueForKey:@"request"]) {
                                                                  // User clicked the Cancel button
                                                                  SNSLog(@"User canceled request.");
                                                              } else {
                                                                  // User clicked the Send button
                                                                  NSString *requestID = [urlParams valueForKey:@"request"];
                                                                  SNSLog(@"Request Sent. ID: %@", requestID);
                                                                  [self showInviteFriendsPrize:iKNInviteCount];
                                                                  // if(iKNInviteCount>=[arrKNFriendItems count])
                                                                  // else
                                                                      // [self showSelectFriendsSelector];
                                                                  
                                                              }
                                                              
                                                          }
                                                      }}];
    
    
}

/*
- (void)showSelectFriendsiPad {
    NSLog(@"%s",__func__);
    // Same code as above
    KNMultiItemSelector * selector = [[KNMultiItemSelector alloc] initWithItems:friends
                                                               preselectedItems:nil
                                                                          title:@"Select friends"
                                                                placeholderText:@"Search by name"
                                                                       delegate:self];
    selector.allowSearchControl = YES;
    selector.useTableIndex      = YES;
    selector.useRecentItems     = YES;
    selector.maxNumberOfRecentItems = 8;
    
    // But different way of presenting only for iPad
    UINavigationController * uinav = [[UINavigationController alloc] initWithRootViewController:selector];
    self.popoverController = [[UIPopoverController alloc] initWithContentViewController:uinav];
    [self.popoverController presentPopoverFromRect:popoverButton.frame
                                            inView:self.view
                          permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}
*/

- (void) showSelectFriendsOld
{
    if(isShowingFriends) return;
    isShowingFriends = YES;
    if (self.friendPickerController == nil) {
        // Create friend picker, and get data loaded into it.
        _friendPickerController = [[FBFriendPickerViewController alloc] init];
        self.friendPickerController.title = [SystemUtils getLocalizedString:@"Invite Friends"];
        self.friendPickerController.delegate = self;
        // Ask for friend device data
        _friendPickerController.fieldsForRequest =
        [NSSet setWithObjects:@"devices", nil];
    }
    
    [self.friendPickerController loadData];
    [self.friendPickerController clearSelection];
    
    iShowInviteCount = 0;
    if(invitedFriendList == nil) {
        invitedFriendList = [[NSMutableDictionary alloc] init];
        NSDictionary *dict = [SystemUtils getNSDefaultObject:@"kFBInvitedUser"];
        if(dict && [dict isKindOfClass:[NSDictionary class]])
            [invitedFriendList addEntriesFromDictionary:dict];
        allFriendList = [[NSMutableDictionary alloc] init];
    }
    SNSLog(@"invited list:%@", invitedFriendList);
    shownFriendList = [[NSMutableDictionary alloc] init];
    
    // iOS 5.0+ apps should use [UIViewController presentViewController:animated:completion:]
    // rather than this deprecated method, but we want our samples to run on iOS 4.x as well.
    UIViewController *root = [SystemUtils getAbsoluteRootViewController];
    NSString *osVer =  [SystemUtils getiOSVersion];
    
    if(root.presentedViewController) [root dismissModalViewControllerAnimated:NO];
    
    if([osVer compare:@"5.0"]>=0)
        [root presentViewController:self.friendPickerController animated:YES completion:^(void){
            /*
            if(iShowInviteCount==0) {
                [SystemUtils setNSDefaultObject:@"1" forKey:@"kAllFBFriendInvited"];
                [root dismissModalViewControllerAnimated:NO];
                // show alert
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Friends Left"
                                                                    message:@"You've invited all your friends on Facebook."
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
                [alertView release];
            }
             */
            // self.friendPickerController.tableView.delegate = self;
        }];
    else
        [root presentModalViewController:self.friendPickerController animated:YES];
}

- (void) setAllFriendSelection
{
    /*
    SNSLog(@"set default selection");
    UITableView *tableView = self.friendPickerController.tableView;
    for(int section=0;section<[tableView numberOfSections];section++) {
        for(int row=0;row<[tableView numberOfRowsInSection:section];row++) {
            SNSLog(@"section:%i row:%i",section,row);
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition: UITableViewScrollPositionNone];
        }
    }
     */
    
}

#pragma mark Facebook Friend Picker

- (void)facebookViewControllerDoneWasPressed:(id)sender {
    SNSLog(@"selected friends:%@", self.friendPickerController.selection);
    // we pick up the users from the selection, and create a string that we use to update the text view
    // at the bottom of the display; note that self.selection is a property inherited from our base class
    if(iSessionStatus == kSessionStatusSendInvitation) {
        [self startSendRequest:self.friendPickerController.selection];
    }
    else {
        NSDictionary *info = [NSDictionary dictionaryWithObject:self.friendPickerController.selection forKey:@"selectedFriends"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationOnSelectFriendFinished object:nil userInfo:info];
    }
    if(iShowInviteCount==0)
        [SystemUtils setNSDefaultObject:@"1" forKey:@"kAllFBFriendInvited"];
    [[SystemUtils getAbsoluteRootViewController] dismissModalViewControllerAnimated:NO];
    isShowingFriends = NO;
}

- (void)facebookViewControllerCancelWasPressed:(id)sender {
    // [self fillTextBoxAndDismiss:@"<Cancelled>"];
    [[SystemUtils getAbsoluteRootViewController] dismissModalViewControllerAnimated:NO];
    if(iShowInviteCount==0)
        [SystemUtils setNSDefaultObject:@"1" forKey:@"kAllFBFriendInvited"];
    if(iSessionStatus == kSessionStatusSendInvitation) {
        // kFacebookNotificationOnSendRequestFinished
        [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationOnSendRequestFinished object:nil userInfo:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationOnSelectFriendFinished object:nil userInfo:nil];
    }
    isShowingFriends = NO;
}

/*!
 @abstract
 Tells the delegate that data has been loaded.
 
 @discussion
 The <FBFriendPickerViewController> object's `tableView` property is automatically
 reloaded when this happens. However, if another table view, for example the
 `UISearchBar` is showing data, then it may also need to be reloaded.
 
 @param friendPicker        The friend picker view controller whose data changed.
 */
- (void)friendPickerViewControllerDataDidChange:(FBFriendPickerViewController *)friendPicker
{
    // [self performSelector:@selector(setAllFriendSelection) withObject:nil afterDelay:5.0f];
}

/*!
 @abstract
 Tells the delegate that the selection has changed.
 
 @param friendPicker        The friend picker view controller whose selection changed.
 */
- (void)friendPickerViewControllerSelectionDidChange:(FBFriendPickerViewController *)friendPicker
{
}

/*!
 @abstract
 Asks the delegate whether to include a friend in the list.
 
 @discussion
 This can be used to implement a search bar that filters the friend list.
 
 @param friendPicker        The friend picker view controller that is requesting this information.
 @param user                An <FBGraphUser> object representing the friend.
 */
- (BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                 shouldIncludeUser:(id <FBGraphUser>)user
{
    SNSLog(@"showCount:%i fbUser:%@", iShowInviteCount, user);
    NSString *uid = [user objectForKey:@"id"];
    if([invitedFriendList objectForKey:uid]) return NO;
    if([shownFriendList objectForKey:uid]) return YES;
    if(![allFriendList objectForKey:uid]) {
        [allFriendList setObject:@"1" forKey:uid];
    }
    if(iInviteCount>0 && iShowInviteCount>iInviteCount) return NO;
    NSArray *deviceData = [user objectForKey:@"devices"];
    if(deviceData==nil || [deviceData count]==0) {
        iShowInviteCount += 1;
        [shownFriendList setObject:@"1" forKey:uid];
        return YES;
    }
    // Loop through list of devices
    for (NSDictionary *deviceObject in deviceData) {
        // Check if there is a device match
        if ([@"iOS" isEqualToString:
             [deviceObject objectForKey:@"os"]]) {
            // Friend is an iOS user, include them in the display
            SNSLog(@"fbid:%@ device:%@",uid, deviceObject);
            iShowInviteCount += 1;
            [shownFriendList setObject:@"1" forKey:uid];
            return YES;
        }
    }
    // Friend is not an iOS user, do not include them
    return NO;
}

/*!
 @abstract
 Tells the delegate that there is a communication error.
 
 @param friendPicker        The friend picker view controller that encountered the error.
 @param error               An error object containing details of the error.
 */
- (void)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                       handleError:(NSError *)error
{
    if(iSessionStatus == kSessionStatusSendInvitation) {
        // kFacebookNotificationOnSendRequestFinished
        [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationOnSendRequestFinished object:nil userInfo:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationOnSelectFriendFinished object:nil userInfo:nil];
    }
    [[SystemUtils getAbsoluteRootViewController] dismissModalViewControllerAnimated:NO];
}



#pragma mark -

- (void) sendInvitationRequest:(int)count
{
    iInviteCount = count;
    iSessionStatus = kSessionStatusSendInvitation;
    if(![self isLoggedIn])
    {
        [self startLogin];
        return;
    }
    
    [self showSelectFriends:NO];
}

- (void) startSendRequest:(NSArray *)userList
{
    iShowInviteCount = [userList count];
    iSendInviteCount = 0;
    if(iShowInviteCount == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationOnSendRequestFinished object:nil userInfo:nil];
        return;
    }
    iTotalFriendCount += iShowInviteCount;
    
    [SystemUtils showInGameLoadingView];
    
    // create the connection object
    FBRequestConnection *newConnection = [[FBRequestConnection alloc] init];
    
    NSString *inviteMessage = [SystemUtils getSystemInfo:@"kFacebookInviteMessage"];
    NSString *gift = [SystemUtils getSystemInfo:@"kFacebookInvitePrize"];
    // data, message
    // for each fbid in the array, we create a request object to fetch
    // the profile, along with a handler to respond to the results of the request
    for (NSDictionary<FBGraphUser> *fbUser in userList) {
        
        NSString *fbid = [fbUser objectForKey:@"id"];
        // create a handler block to handle the results of the request for fbid's profile
        FBRequestHandler handler =
        ^(FBRequestConnection *connection, id result, NSError *error) {
            // output the results of the request
#ifdef SNS_ENABLE_FLURRY_V2
            if(error)
                [Flurry logError:@"FacebookError" message:@"sendInvitationRequest error" error:error];
#endif
            [self requestCompleted:connection forFbID:fbid operationType:kFacebookOperationSendRequest result:result error:error];
        };
        
        // create the request object, using the fbid as the graph path
        // as an alternative the request* static methods of the FBRequest class could
        // be used to fetch common requests, such as /me and /me/friends
        FBRequest *request = [[FBRequest alloc] initWithSession:FBSession.activeSession
                                                      graphPath:fbid];
        
        if(gift!=nil) [request.parameters setValue:gift forKey:@"data"];
        if(inviteMessage!=nil)[request.parameters setValue:inviteMessage forKey:@"message"];
        
        // add the request to the connection object, if more than one request is added
        // the connection object will compose the requests as a batch request; whether or
        // not the request is a batch or a singleton, the handler behavior is the same,
        // allowing the application to be dynamic in regards to whether a single or multiple
        // requests are occuring
        [newConnection addRequest:request completionHandler:handler];
        [request release];
    }
    
    // if there's an outstanding connection, just cancel
    [self.requestConnection cancel];
    
    // keep track of our connection, and start it
    self.requestConnection = newConnection;
    [newConnection start];
    [newConnection autorelease];
    
}


// FBSample logic
// Report any results.  Invoked once for each request we make.
- (void)requestCompleted:(FBRequestConnection *)connection
                 forFbID:fbID
           operationType:(int)type
                  result:(id)result
                   error:(NSError *)error {
    // not the completion we were looking for...
    if (self.requestConnection &&
        connection != self.requestConnection) {
        return;
    }
    
    if(error) {
#ifdef SNS_ENABLE_FLURRY_V2
        [Flurry logError:@"FacebookError" message:@"requestCompleted:forFbID:operationType: error" error:error];
#endif
        SNSLog(@"error:%@",error);
        if(error.code==10) {
            // invalid permission, request it
            [self checkPublishPermission];
        }
        return;
    }
    
    if(type==kFacebookOperationSendRequest) {
        iSendInviteCount += 1;
        [invitedFriendList setObject:@"1" forKey:fbID];
        SNSLog(@" fbID:%@ count:%i total:%i error:%@", fbID, iSendInviteCount, iShowInviteCount, error);
        
        if(iSendInviteCount == iShowInviteCount) {
            // save to local
            [SystemUtils setNSDefaultObject:invitedFriendList forKey:@"kFBInvitedUser"];
            // clean this up, for posterity
            self.requestConnection = nil;
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:iSendInviteCount] forKey:@"inviteCount"];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationOnSendRequestFinished object:nil userInfo:userInfo];
            
            // give player prize
            [SystemUtils hideInGameLoadingView];
            [self showInviteFriendsPrize:iSendInviteCount];
            [self startPendingTask];
        }
    }
}


-(void)publishFeed
{
    [self publishCustomizedFeed:nil];
}

// publish customized feed, info must contain these properties:
// picture: URL address of the picture
// caption: feed caption
// description: detailed description
-(void)publishCustomizedFeed:(NSDictionary *)info
{
    if(![self checkPublishPermission]) {
        // wait for publish
        NSDictionary *taskInfo = [NSDictionary
                                  dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:kFacebookOperationFeed], @"type",
                                  info, @"info",
                                  nil];
        [self addPendingTasks:taskInfo];
        return;
    }
    
    FacebookFeedViewController *viewController = [[FacebookFeedViewController alloc]
                                                  initWithNibName:@"FacebookFeedView"
                                                  bundle:nil];
    
    if(info!=nil) [viewController setParameters:info];
    if([[SystemUtils getiOSVersion] compare:@"5.0"]>=0)
        [[SystemUtils getAbsoluteRootViewController] presentViewController:viewController animated:YES completion:nil];
    else {
        [[SystemUtils getAbsoluteRootViewController] presentModalViewController:viewController animated:YES];
    }
    [viewController release];
}

-(void) publishPhoto:(UIImage *)image withCaption:(NSString *)caption
{
    // publish_stream is superset of publish_actions
    // Ask for publish_actions permissions in context
    if([self checkPublishPermission]==NO) {
        // wait for publish
        NSDictionary *taskInfo = [NSDictionary
                                  dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:kFacebookOperationPublishPhoto], @"type",
                                  image, @"image",
                                  caption, @"caption",
                                  nil];
        [self addPendingTasks:taskInfo];
        return;
    }
    // If permissions present, publish the story
    // [self publishStory];
    [FBRequestConnection startForUploadPhoto:image completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
#ifdef SNS_ENABLE_FLURRY_V2
            if(error)
                [Flurry logError:@"FacebookError" message:@"startForUploadPhoto: error" error:error];
#endif
        
        }];
    
}

- (BOOL) hasInviteToday
{
    int lastDate = [[SystemUtils getNSDefaultObject:@"kFBBonusDate"] intValue];
    if(lastDate==0)
        lastDate = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"kFBBonusDate"] intValue];
    if(lastDate==[SystemUtils getTodayDate])
        return YES;
    return NO;
    
}

- (BOOL) showFacebookPromotionHintNoHint
{
    if([self hasInviteToday]) return NO;
    [self showFacebookPromotionHint];
    return YES;
}

- (void) showFacebookPromotionHint
{
    // 1, 检查是否关联facebook，如果没有，就提示关联，关联成功获得一次性奖励：N金币
    // 2, 关联后，每天发送一次好友邀请，获得邀请数量xN金币
    // 3, 好友邀请完后，每天发送一次feed，获得N金币
#ifndef DEBUG
    if([self hasInviteToday]) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:[SystemUtils getLocalizedString:@"Invite Friends"]
                                  message:[SystemUtils getLocalizedString:@"You've invited your friends today, please try again tomorrow."]
                                  delegate:nil
                                  cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        
        return;
    }
#endif
    if([SystemUtils getGameDataDelegate] == nil) return;
    NSString *fbid = [[SystemUtils getGameDataDelegate] getExtraInfo:@"kFBID"];
    if(fbid==nil)
        fbid = [SystemUtils getNSDefaultObject:@"kFBUserID"];

    // 监测5.0以下设备不支持
    if([[SystemUtils getiOSVersion] compare:@"5.0"]<0) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:[SystemUtils getLocalizedString:@"System Too Old"]
                                  message:[SystemUtils getLocalizedString:@"This feature requires iOS 5.0+, please upgrade your iOS system."]
                                  delegate:self
                                  cancelButtonTitle:[SystemUtils getLocalizedString:@"Cancel"]
                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        return;
    }
#if 0
    if(fbid==nil) {
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:[SystemUtils getLocalizedString:@"Facebook Bonus"]
                                  message:[SystemUtils getLocalizedString:@"Connecting Facebook to get bonus, will you connect now?"]
                                  delegate:self
                                  cancelButtonTitle:[SystemUtils getLocalizedString:@"Cancel"]
                                  otherButtonTitles:[SystemUtils getLocalizedString:@"Connect"],nil];
        alertView.tag = kFacebookAlertTagConnectFirstTime;
        [alertView show];
        [alertView release];
        
        return;
    }
#endif
    if(!FBSession.activeSession.isOpen) {
        [self startLogin];
        return;
    }
    
    int today = [SystemUtils getTodayDate];
    int inviteDate = [[SystemUtils getNSDefaultObject:@"kAllFBFriendInvitedDate"] intValue];
#ifdef DEBUG
    // inviteDate = 0;
    // noFriendLeft = 1;
#endif
    if(inviteDate != today) {
        [self showSelectFriends:NO];
        return;
    }
    
    // send feed
    [self publishFeed];
}

+ (void) installReport
{
    [FBAppEvents activateApp];
    // [FBSettings publishInstall:[SystemUtils getSystemInfo:@"kFacebookAppID"]];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == kFacebookAlertTagConnectFirstTime && buttonIndex==1) {
        iSessionStatus = kSessionStatusConnectFirstTime;
        [self startLogin];
    }
    if(alertView.tag == kFacebookAlertTagSwitchAccount && buttonIndex==1) {
        // switch account
        NSString *uid = [NSString stringWithFormat:@"%d",fbUID];
        [SystemUtils setCurrentUID:uid];
        [SystemUtils showSwitchAccountHint];
        [SystemUtils clearSessionKey];
    }
    if(alertView.tag==kFacebookAlertTagSendingGifts && buttonIndex==1) {
        [self showSelectFriends:YES];
    }
}

#pragma mark -

#pragma mark Notification

/*
 * Helper function to delete the request notification
 */
- (void) notificationClear:(NSString *)requestid {
    // Delete the request notification
    [FBRequestConnection startWithGraphPath:requestid
                                 parameters:nil
                                 HTTPMethod:@"DELETE"
                          completionHandler:^(FBRequestConnection *connection,
                                              id result,
                                              NSError *error) {
                              SNSLog(@"error:%@",error);
                              if (!error) {
                                  SNSLog(@"Request deleted");
                              }
                              else {
#ifdef SNS_ENABLE_FLURRY_V2
                                  [Flurry logError:@"FacebookError" message:@"notificationClear: error" error:error];
#endif
                                  
                              }
                          }];
}

- (void) handleRequestAction:(NSDictionary *) reqAction from:(NSDictionary *)friend
{
    NSString *action = [reqAction objectForKey:@"action"];
    if([action isEqualToString:@"ticketAsk"]) {
        if([reqAction objectForKey:@"sender"]) friend = [reqAction objectForKey:@"sender"];
        
        // 去掉重复的ticket请求
        NSString *ticketID = [NSString stringWithFormat:@"%@-%@",[friend objectForKey:@"uid"], [reqAction objectForKey:@"level"]];
        if(dictPendingTicketID==nil) dictPendingTicketID = [[NSMutableDictionary alloc] init];
        if([dictPendingTicketID objectForKey:ticketID]) return;
        [dictPendingTicketID setObject:@"1" forKey:ticketID];
        
        if(arrPendingTicketRequests==nil) arrPendingTicketRequests = [[NSMutableArray alloc] init];
        [arrPendingTicketRequests addObject:[NSDictionary dictionaryWithObjectsAndKeys:reqAction, @"request", friend, @"from", nil]];
        // [self sendTicketReply:[[reqAction objectForKey:@"level"] intValue] to:friend];
        // 增加好友信息
        [SystemUtils addFriend:friend];
    }
    else if([action isEqualToString:@"ticketReply"]) {
        if([reqAction objectForKey:@"replier"]) friend = [reqAction objectForKey:@"replier"];
        [SystemUtils addFriend:friend];
        // send notification: kFacebookNotificationOnReceiveTicket
        // NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:reqAction];
        // [info setObject:friend forKey:@"from"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationOnReceiveTicket object:nil userInfo:reqAction];
    }
}

- (void)snsAlertView:(SNSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == kTagAlertFacebookReplyTicket) {
        if(buttonIndex==1 && arrPendingTicketRequests!=nil) {
            for (NSDictionary *info in arrPendingTicketRequests) {
                NSDictionary *friend  = [info objectForKey:@"from"];
                NSDictionary *reqAction = [info objectForKey:@"request"];
                [self sendTicketReply:reqAction to:friend];
            }
        }
        [arrPendingTicketRequests release]; arrPendingTicketRequests = nil;
        [dictPendingTicketID release]; dictPendingTicketID = nil;
    }
}


- (void) showTicketRequestReplyAlert
{
    if(arrPendingTicketRequests==nil || [arrPendingTicketRequests count]==0) return;
    // show alert
    NSMutableString *friendNames = [[NSMutableString alloc] init]; [friendNames autorelease];
    int count = 0;
    for (NSDictionary *info in arrPendingTicketRequests) {
        NSDictionary *friend = [info objectForKey:@"from"];
        if(count>0) [friendNames appendString:@", "];
        [friendNames appendString:[friend objectForKey:@"name"]];
        count++;
    }
    NSString *title =  [SystemUtils getLocalizedString:@"Ticket Request"];
    NSString *fmt = [SystemUtils getLocalizedString:@"Your friends(%@) ask you for help. Will you help them?"];
    if(count==1) fmt = [SystemUtils getLocalizedString:@"%@ ask you for help. Will you help him/her?"];
    NSString *message = [NSString stringWithFormat:fmt, friendNames];
    SNSAlertView *av = [[SNSAlertView alloc]
                        initWithTitle:title
                        message:message
                        delegate:self
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"Cancel"]
                        otherButtonTitle:[SystemUtils getLocalizedString:@"OK"], nil];
    
    av.tag = kTagAlertFacebookReplyTicket;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
    
}

- (void) parseInviteRequest:(NSDictionary *)result
{
    NSString *friendName = [[result objectForKey:@"from"]
                            objectForKey:@"name"];
    int type = 1; int count = 0;
    if ([result objectForKey:@"data"]) {
        NSString *giftStr = [result objectForKey:@"data"];
        NSDictionary *requestData = [giftStr JSONValue];
        if(requestData) {
            if([requestData objectForKey:@"action"]) {
                [self handleRequestAction:requestData from:[result objectForKey:@"from"]];
            }
            else {
                type = [[requestData objectForKey:@"type"] intValue];
                count =[[requestData objectForKey:@"count"] intValue];
            }
        }
        else {
            NSArray *arr = [giftStr componentsSeparatedByString:@":"];
            if([arr count]>=2) {
                type = [[arr objectAtIndex:0] intValue];
                count = [[arr objectAtIndex:1] intValue];
            }
        }
    }
    if(count>0) {
        [self showFacebookNotificationGift:count type:type from:friendName];
    }
    // Delete the request notification
    [self notificationClear:[result objectForKey:@"id"]];
    
}

/*
 * Helper function to get the request data
 */
- (void) notificationGet:(NSString *)requestids {
    if(![self isLoggedIn]) {
        NSDictionary *taskInfo = [NSDictionary
                                  dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:kFacebookOperationGetInviteRequest], @"type",
                                  requestids, @"requestid",
                                  nil];
        [self addPendingTasks:taskInfo];
        [self startLogin];
        return;
    }
    static int pendingRequestCount = 0;
    NSArray *arr = [requestids componentsSeparatedByString:@","];
    pendingRequestCount += [arr count];
    
    for(NSString *reqID in arr) {
    
    [FBRequestConnection startWithGraphPath:reqID
                          completionHandler:^(FBRequestConnection *connection,
                                              id result,
                                              NSError *error) {
                              if (!error) {
                                  [self parseInviteRequest:result];
                              }
                              else {
#ifdef SNS_ENABLE_FLURRY_V2
                                  [Flurry logError:@"FacebookError" message:@"notificationGet: error" error:error];
#endif
                                  
                              }
                              pendingRequestCount--;
                              if(pendingRequestCount<=0) {
                                  pendingRequestCount = 0;
                                  [self showTicketRequestReplyAlert];
                              }
                          }];
    }
}

/*
 * Helper function to check incoming URL
 */
- (void) checkIncomingNotification {
    if (self.openedURL) {
        NSString *query = [self.openedURL fragment];
        if (!query) {
            query = [self.openedURL query];
        }
        NSDictionary *params = [StringUtils parseURLParams:query];
        // Check target URL exists
        NSString *targetURLString = [params valueForKey:@"target_url"];
        if (targetURLString) {
            NSURL *targetURL = [NSURL URLWithString:targetURLString];
            NSDictionary *targetParams = [StringUtils parseURLParams:[targetURL query]];
            NSString *ref = [targetParams valueForKey:@"ref"];
            // Check for the ref parameter to check if this is one of
            // our incoming news feed link, otherwise it can be an
            // an attribution link
            if ([ref isEqualToString:@"notif"]) {
                // Get the request id
                NSString *requestIDParam = [targetParams
                                            objectForKey:@"request_ids"];
                [self notificationGet:requestIDParam];
                //NSArray *requestIDs = [requestIDParam
                //                       componentsSeparatedByString:@","];
                
                // Get the request data from a Graph API call to the
                // request id endpoint
                // [self notificationGet:[requestIDs objectAtIndex:0]];
            }
            // FEED礼物格式： {"gid":123,"coin":100,"hint":"here is 100 coins.","udid":"public"}
            NSString *gift = [targetParams objectForKey:@"gift"];
            if(gift!=nil && [gift length]>10) {
                NSString *sig  = [targetParams objectForKey:@"gids"];
                // php: $hash = md5(md5($gift)."-topgamefacebookHashKey");
                NSString *hash = [StringUtils stringByHashingStringWithMD5:[NSString stringWithFormat:@"%@-topgamefacebookHashKey",[StringUtils stringByHashingStringWithMD5:gift]]];
                if(sig!=nil && [sig isEqualToString:hash])
                    [[SnsServerHelper helper] setFacebookURLGift:gift];
            }
        }
        // Clean out to avoid duplicate calls
        self.openedURL = nil;
    }
}

#pragma mark -
- (void) getUserInfo:(id<FacebookHelperDelegate>) handler
{
    FBRequest* friendsRequest = [FBRequest requestWithGraphPath:@"me?fields=birthday,gender" parameters:nil HTTPMethod:@"GET"];
    [friendsRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                  NSDictionary* result,
                                                  NSError *error) {
        SNSLog(@"result: %@  error:%@", result, error);
        [handler onGetUserInfo:result withError:error];
    }];
}

- (void) getAllFriends:(id<FacebookHelperDelegate>) handler
{
    delegate = handler;
    FBRequest* friendsRequest = [FBRequest requestWithGraphPath:@"me/friends?fields=installed,name,first_name" parameters:nil HTTPMethod:@"GET"];
    [friendsRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                  NSDictionary* result,
                                                  NSError *error) {
        NSArray* friends = [result objectForKey:@"data"];
        SNSLog(@"result: %@  error:%@", result, error);
        [delegate onGetAllFacebookFriends:friends withError:error];
        delegate = nil;
        /*
        for (NSDictionary<FBGraphUser>* friend in friends) {
            NSLog(@"I have a friend named %@ with id %@: installed=%@", friend.name, friend.id, [friend objectForKey:@"installed"]);
            
        }
        NSArray *friendIDs = [friends collect:^id(NSDictionary<FBGraphUser>* friend) {
            return friend.id;
        }];
         */
    }];
    
    friendsRequest = [FBRequest requestWithGraphPath:@"me/invitable_friends" parameters:nil HTTPMethod:@"GET"];
    [friendsRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                  NSDictionary* result,
                                                  NSError *error) {
        NSArray* friends = [result objectForKey:@"data"];
        SNSLog(@"result: %@  error:%@", result, error);
        
        if(friends ==nil || ![friends isKindOfClass:[NSArray class]] || [friends count]==0) {
            SNSLog(@"no friends count");
            return;
        }
        NSDictionary * userInfo = [NSDictionary dictionaryWithObject:friends forKey:@"friends"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationGetFacebookInviteFrds object:Nil userInfo:userInfo];
    }];
}

- (void)getAppMessage:(id<FacebookHelperDelegate>)handler
{
    NSString * str = [NSString stringWithFormat:@"me/apprequests?access_token=%@",[[[FBSession activeSession] accessTokenData] accessToken]];
    FBRequest* msgsRequest = [FBRequest requestWithGraphPath:str parameters:nil HTTPMethod:@"GET"];
    [msgsRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                  NSDictionary* result,
                                                  NSError *error) {
        SNSLog(@"error:%@",error);
        NSArray* msgs = [result objectForKey:@"data"];
        SNSLog(@"result: %@  error:%@", result, error);
        [handler onGetFacebookMessages:msgs withError:error];
    }];

//    NSString *query = [NSString stringWithFormat:@"SELECT message,request_id,sender_uid,data FROM apprequest WHERE app_id=%@ AND recipient_uid=me()",[SystemUtils getSystemInfo:@"kFacebookAppID"]];
//    NSDictionary * dic = @{ @"q" : query};
//    [FBRequestConnection startWithGraphPath:@"fql"
//                                 parameters:dic
//                                 HTTPMethod:@"GET"
//                          completionHandler:^(FBRequestConnection *connection,
//                                              id result,
//                                              NSError *error) {
//                              SNSLog(@"error:%@",error);
//                              NSArray* msgs = [result objectForKey:@"data"];
//                              SNSLog(@"result: %@  error:%@", result, error);
//                              [handler onGetFacebookMessages:msgs withError:error];
//                          }];
}

- (void) deleteAppRequest:(NSString *)requestID
{
    [FBRequestConnection startForDeleteObject:requestID
                            completionHandler:^(FBRequestConnection *connection,
                                                id result,
                                                NSError *error) {
                                SNSLog(@"result: %@  error:%@", result, error);
                            }];
}

// 获得本地缓存头像的路径
- (NSString *) getFacebookIconPath:(NSString *)uid
{
    NSString *path = [NSString stringWithFormat:@"%@/fbicon",[SystemUtils getItemImagePath]];
    NSFileManager *mgr = [NSFileManager defaultManager];
    if(![mgr fileExistsAtPath:path]) [mgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    return [path stringByAppendingFormat:@"/%@.jpg",uid];
}


- (void) loadFacebookIcon:(NSString *)uid
{
    if(requestType!=kFacebookHelperRequestTypeNone) return;
    SNSLog(@"loading icon of %@", uid);
    // 下载玩家的FB头像
    NSString *file = [self getFacebookIconPath:uid];
    if([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        BOOL skipLoad = NO;
        NSDictionary *info = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil];
        if(info && info.fileSize>0) {
            skipLoad = YES;
            // 3天内不用重新下载
            if([info.fileModificationDate timeIntervalSince1970]<[SystemUtils getCurrentTime]-3*86400)
                skipLoad = NO;
        }
        if(skipLoad) {
            SNSLog(@"no need to reload icon of #%@", uid);
            return;
        }
    }
    
//    requestType = kFacebookHelperRequestTypeLoadIcon;
    int size = 200;
    if([SystemUtils isiPad] && [SystemUtils isRetina]) size = 400;
    NSString *link = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=%d&height=%d",uid, size, size];
    ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:link]];
    [req setTag:kFacebookHelperRequestTypeLoadIcon];
    [req setDownloadDestinationPath:file];
    [req setDelegate:Nil];
    [req startAsynchronous];
}

#pragma mark bindUserID
- (void) startBind
{
    NSString *fbid = self.fbUserID;
    if(fbid==nil) return;
	NSString *sessionKey = [SystemUtils getSessionKey];
    if(!sessionKey) {
        [self loadCancel]; return;
    }
    requestType = kFacebookHelperRequestTypeBindAccount;
    NSString *prefix = [SystemUtils getSystemInfo:@"kHMACPrefix"];
    if(prefix==nil) prefix = @"";
    // fbid = [NSString stringWithFormat:@"%@%@",prefix,fbid];
	NSString *link = [NSString stringWithFormat:@"%@fbBind.php", [SystemUtils getServerRoot]];
    SNSLog(@"link:%@ fbid:%@ sessionKey:%@",link, fbid, sessionKey);
	NSURL *url = [NSURL URLWithString:link];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
	[request setPostValue:fbid forKey:@"fbid"];
	[request setPostValue:prefix forKey:@"prefix"];
	[request setPostValue:sessionKey forKey:@"sessionKey"];
    [request setTag:kFacebookHelperRequestTypeBindAccount];
    
	[request setDelegate:self];
    [request startAsynchronous];
    
}

- (void) showSwitchAccountAlert:(int) newUID
{
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
    
}

- (void) showBindSuccessAlert
{
    NSString *mesg = [SystemUtils getLocalizedString:@"You've link this player with your Facebook account. You can retrieve your game data on other devices by login your Facebook acocunt."];
    // NSString *mesg = [NSString stringWithFormat:@"You've connected to an existing account before(UID:%d), will you switch to that account now?", gcUID];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[SystemUtils getLocalizedString:@"Account Linked"]
                              message:mesg
                              delegate:nil
                              cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                              otherButtonTitles:nil];
    
    [alertView show];
    [alertView release];
    
}

#pragma mark syncFBAccount
- (void) getUserToken
{
    if ([SystemUtils getNSDefaultObject:@"kFBUserToken"]) {
        [self startSync];
    }else{
        NSString *accessToken = FBSession.activeSession.accessTokenData.accessToken;
        if(accessToken==nil) return;
        NSString *link = [SystemUtils getSystemInfo:@"kFacebookRequestLink"];
        if(link==nil || [link length]<5) {
            SNSLog(@"kFacebookSyncLink is invalid: %@", link);
            [self loadCancel];
            return;
        }
        link = [link stringByAppendingString:@"auth/loginbyfacebook"];
        SNSLog(@"link:%@ accessToken:%@",link, accessToken);
        NSURL *url = [NSURL URLWithString:link];
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
        [request setRequestMethod:@"POST"];
        [request setPostValue:accessToken forKey:@"access_token"];
        [request setPostValue:@"ios" forKey:@"device_model"];
        [request setTag:kFacebookHelperRequestTypeGetUserToken];
        [request setDelegate:self];
        [request startAsynchronous];
    }
}

- (void) startSync
{
    if (![self isLoggedIn]) {
        return;
    }
    NSString *accessToken = [SystemUtils getNSDefaultObject:@"kFBUserToken"];
    if(accessToken==nil) return;
    requestType = kFacebookHelperRequestTypeSyncAccount;
    
    NSObject<GameDataDelegate> *gameData = [SystemUtils getGameDataDelegate];
    NSString *saveStr = [gameData exportToString];
    if(!saveStr || [saveStr length]<3) {
        SNSLog(@"failed to get gamedata.");
        [self loadCancel];
        return;
    }
    
    NSString *link = [SystemUtils getSystemInfo:@"kFacebookRequestLink"];
    if(link==nil || [link length]<5) {
        SNSLog(@"kFacebookSyncLink is invalid: %@", link);
        [self loadCancel];
        return;
    }
    link = [link stringByAppendingString:@"facebook/syncdata"];
	int useZip = 0;
    if([saveStr length]>2048) useZip = 1;
	if(useZip==1) {
        NSData *data = [[saveStr dataUsingEncoding:NSUTF8StringEncoding] zlibDeflate];
        saveStr = [Base64 encode:data];
	}
    
//	NSString *link = @"http://fbjelly.topgame.com/master/facebook/syncdata";
#ifdef DEBUG
//    link = @"http://fbjelly.topgame.com/dev/facebook/syncdata";
#endif
    SNSLog(@"link:%@ accessToken:%@",link, accessToken);
	NSURL *url = [NSURL URLWithString:link];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
    [request setPostValue:saveStr forKey:@"data"];
	[request setPostValue:accessToken forKey:@"token"];
    [request setPostValue:[NSString stringWithFormat:@"%i",useZip] forKey:@"usezip"];
    [request setTag:kFacebookHelperRequestTypeSyncAccount];
	[request setDelegate:self];
    [request startAsynchronous];
}

- (void)loadCancel
{
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	SNSLog(@"%s status code:%i",__FUNCTION__, request.responseStatusCode);
    int type = request.tag;
    requestType = kFacebookHelperRequestTypeNone;
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		[self loadCancel];
		return;
	}
    
    if(type == kFacebookHelperRequestTypeLoadIcon) {
        SNSLog(@"load icon ok:%@", [request downloadDestinationPath]);
        return;
    }
    if (type == kFacebookHelperRequestTypeGetUserToken) {
        NSString *text = [request responseString];
        SNSLog(@"resp:%@", text);

        NSDictionary *dict = [StringUtils convertJSONStringToObject:text];
        if(dict==nil) {
            SNSLog(@"invalid response:%@", text);
            [self loadCancel];
            return;
        }
        
        NSString * token = [dict objectForKey:@"token"];
        if (token) {
            [SystemUtils setNSDefaultObject:token forKey:@"kFBUserToken"];
            [self startSync];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationGetFBToken object:Nil userInfo:Nil];
        }
    }
    if (type == kFacebookHelperRequestTypeSyncAccount) {

        NSString *text = [request responseString];
        SNSLog(@"resp:%@", text);
        
        NSDictionary *dict = [StringUtils convertJSONStringToObject:text];
        if(dict==nil) {
            SNSLog(@"invalid response:%@", text);
            [self loadCancel];
            return;
        }
        NSString * leveldata = [dict objectForKey:@"leveldata"];
        
        if ([[dict objectForKey:@"usezip"] intValue] == 1) {
            NSData *zipData = [[Base64 decode:leveldata] zlibInflate];
            leveldata = [[NSString alloc] initWithBytes:[zipData bytes] length:[zipData length] encoding:NSUTF8StringEncoding];
            [leveldata autorelease];
        }
        if (leveldata) {
            SNSLog(@"leveldata:%@",leveldata);
            NSObject<GameDataDelegate> *gameData = [SystemUtils getGameDataDelegate];
            [gameData importFromFBString:leveldata];
        }

        return;
    }
    // kFacebookHelperRequestTypeBindAccount
	NSString *text = [request responseString];
    SNSLog(@"resp:%@", text);
	
	// [NetworkHelper helper].connectedToInternet = YES;
    NSDictionary *dict = [StringUtils convertJSONStringToObject:text];
    if(dict==nil) {
		SNSLog(@"invalid response:%@", text);
		[self loadCancel];
		return;
	}
    int success = [[dict objectForKey:@"success"] intValue];
    if(success==1) {
        // bind success
        [SystemUtils setNSDefaultObject:[SystemUtils getCurrentUID] forKey:@"kFBBindUID"];
        if([[dict objectForKey:@"first"] intValue]==1) {
            [self showBindSuccessAlert];
        }
    }
    else if(success==-1) {
        // this uid already bind to another facebookID
        [SystemUtils setNSDefaultObject:[SystemUtils getCurrentUID] forKey:@"kFBBindUID"];
    }
    else if(success==-2) {
        // this facebookID already bind to another uid
        int newUID = [[dict objectForKey:@"uid"] intValue];
        [SystemUtils setNSDefaultObject:[NSString stringWithFormat:@"%d",newUID] forKey:@"kFBBindUID"];
        // show alert
#ifndef SNS_SYNCFACEBOOK
        if(newUID>0)
            [self showSwitchAccountAlert:newUID];
#endif
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	SNSLog(@"%s - error: %@", __FUNCTION__, error);
	[self loadCancel];
    if (request.tag == kFacebookHelperRequestTypeGetUserToken) {
        [self getUserToken];
    }
}

#pragma mark -

// 每日提醒给朋友送礼物
- (void) sendGiftToFriendsDaily
{
#ifdef SNS_SYNCFACEBOOK
    return;
#endif
    if(![self isLoggedIn]) return;
    int today = [SystemUtils getTodayDate]; int inviteDate = 0;
// #ifndef DEBUG
    int disable = [[SystemUtils getGlobalSetting:@"kDisableFBDailyGiftHint"] intValue];
    if(disable==1) return;
    inviteDate = [[SystemUtils getNSDefaultObject:@"kAllFBFriendInvitedDate"] intValue];
    if(today==inviteDate) return;
    inviteDate = [[SystemUtils getNSDefaultObject:@"kFBConnectDate"] intValue];
    if(inviteDate==today) return;
    inviteDate = [[SystemUtils getNSDefaultObject:@"kFBFriendSendGiftDate"] intValue];
    if(today==inviteDate) return;
// #endif
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:today] forKey:@"kFBFriendSendGiftDate"];
    
    // show alert
    
    NSString *mesg = @"Will you send daily gift to your friends? You'll get bonus too after sending gifts to friends.";
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Sending Gifts"
                              message:mesg
                              delegate:self
                              cancelButtonTitle:@"No"
                              otherButtonTitles:@"Great", nil];
    alertView.tag = kFacebookAlertTagSendingGifts;
    [alertView show];
    [alertView release];
}

- (void) sendTestTicketReplyToServer:(int) levelID
{
    // {"action":"ticketReply","level":1,"uid":123, "sender":{"uid":123,"fbid":"11111","name":"Qiu"}, "replier":{"uid":124,"fbid":"12345668","name":"Leon"}}
    NSDictionary *user = [NSDictionary dictionaryWithObjectsAndKeys:
                          [SystemUtils getCurrentUID], @"uid",
                          self.fbUserID, @"fbid",
                          self.fbUserName, @"name",
                          nil];
    NSDictionary *replier = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"4866806", @"uid",
                          @"1137856968", @"fbid",
                          @"Leon Qiu", @"name",
                          nil];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"ticketReply", @"action",
                          [SystemUtils getCurrentUID], @"uid",
                          [NSString stringWithFormat:@"%d",levelID],@"level",
                          user, @"sender",
                          replier, @"replier",
                          nil];
    [self performSelectorInBackground:@selector(sendTicketReplyToServer:) withObject:dict];
}

// 发送赠送钥匙记录到我们自己的服务器
- (void) sendTicketReplyToServer:(NSDictionary *)gift
{
    @autoreleasepool {
        // uid, time, sig, gift, country, appID
        // sig=md5(md5($gift)-xdfiwrw-$time)
        NSString *giftText = [StringUtils convertObjectToJSONString:gift];
        NSString *uid = [gift objectForKey:@"uid"];
        NSString *appID = [SystemUtils getSystemInfo:@"kFlurryCallbackAppID"];
        NSString *time = [NSString stringWithFormat:@"%d", [SystemUtils getCurrentTime]];
        NSString *text =  [NSString stringWithFormat:@"%@-xdfiwrw-%@", [StringUtils stringByHashingStringWithMD5:giftText], time];
        NSString *sig = [StringUtils stringByHashingStringWithMD5:text];
        
        NSString *link = [NSString stringWithFormat:@"%@ticketAdd.php", [SystemUtils getTopgameServiceRoot]];
        NSURL *url = [NSURL URLWithString:link];
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
        [request setRequestMethod:@"POST"];
        [request setPostValue:giftText forKey:@"gift"];
        [request setPostValue:time forKey:@"time"];
        [request setPostValue:sig forKey:@"sig"];
        [request setPostValue:uid forKey:@"uid"];
        [request setPostValue:[gift objectForKey:@"country"] forKey:@"country"];
        [request setPostValue:appID forKey:@"appID"];
        [request setTimeOutSeconds:15.0f];
        [request startSynchronous];
        SNSLog(@"response:%@",[request responseString]);
    }
}

// 处理从服务器返回的ticket请求
- (void) handleRequestsFromServer:(NSArray *)recs
{
    for(NSDictionary *rec in recs) {
        NSString *action = [rec objectForKey:@"action"];
        if(action==nil) continue;
        [self handleRequestAction:rec from:nil];
    }
}

// 从我们自己的服务器加载钥匙
- (void) loadTicketFromServer
{
    @autoreleasepool {
        int now = [SystemUtils getCurrentTime];
        int force = [[SystemUtils getNSDefaultObject:@"kForceCheckTicket"] intValue];
#ifndef DEBUG
        int pending = [[SystemUtils getNSDefaultObject:@"kPendingTicketRequest"] intValue];
        int lastTime = [[SystemUtils getNSDefaultObject:@"kCheckTicketTime"] intValue];
        if(force==0) {
            // 有未完成请求时5分钟刷新一次
            if(pending==1 && now<lastTime+300) return;
            // 没有未完成请求时1小时刷新一次
            if(pending==0 && now<lastTime+3600) return;
        }
#endif
        // time,sig,uid,country,appID
        // sig=md5($uid-dsfuywerqr-$time)
        NSString *time = [NSString stringWithFormat:@"%d",now];
        NSString *uid = [SystemUtils getCurrentUID];
        NSString *appID = [SystemUtils getSystemInfo:@"kFlurryCallbackAppID"];
        NSString *text = [NSString stringWithFormat:@"%@-dsfuywerqr-%@",uid, time];
        NSString *sig = [StringUtils stringByHashingStringWithMD5:text];
        
        NSString *link = [NSString stringWithFormat:@"%@ticketGet.php", [SystemUtils getTopgameServiceRoot]];
        NSURL *url = [NSURL URLWithString:link];
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
        [request setRequestMethod:@"POST"];
        [request setPostValue:time forKey:@"time"];
        [request setPostValue:sig forKey:@"sig"];
        [request setPostValue:uid forKey:@"uid"];
        [request setPostValue:[SystemUtils getOriginalCountryCode] forKey:@"country"];
        [request setPostValue:appID forKey:@"appID"];
        [request setTimeOutSeconds:15.0f];
        [request startSynchronous];
        
        NSString *resp = [request responseString];
        SNSLog(@"response:%@",[request responseString]);
        NSDictionary *info = [StringUtils convertJSONStringToObject:resp];
        int success = 0;
        if(info && [info isKindOfClass:[NSDictionary class]])
            success = [[info objectForKey:@"success"] intValue];
        
        if(success==1) {
            NSArray *arr = [info objectForKey:@"tickets"];
            if(arr && [arr isKindOfClass:[NSArray class]] && [arr count]>0) {
                [self performSelectorOnMainThread:@selector(handleRequestsFromServer:) withObject:arr waitUntilDone:YES];
            }
            
            if(force==1) [SystemUtils setNSDefaultObject:@"0" forKey:@"kForceCheckTicket"];
            [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:now] forKey:@"kCheckTicketTime"];
        }
    }
}

// 发送赠送钥匙请求
- (void) sendTicketReply:(NSDictionary *)reqAction  to:(NSDictionary *)friendInfo
{
    if(![self isLoggedIn]) {
        [self startLogin]; return;
    }
    
    NSMutableDictionary* params =   [NSMutableDictionary dictionaryWithObjectsAndKeys:[friendInfo objectForKey:@"fbid"], @"to",nil];

    // NSDictionary *gift =  [NSDictionary dictionaryWithObjectsAndKeys:@"ticketReply", @"action",
    //                       [NSString stringWithFormat:@"%d", levelID], @"level", nil];
    NSMutableDictionary *gift = [NSMutableDictionary dictionaryWithDictionary:reqAction];
    [gift setObject:@"ticketReply" forKey:@"action"];
    NSDictionary *fromUser = [NSDictionary dictionaryWithObjectsAndKeys:[SystemUtils getCurrentUID], @"uid", self.fbUserID, @"fbid", self.fbUserName, @"name", nil];
    [gift setObject:fromUser forKey:@"replier"];
    [self performSelectorInBackground:@selector(sendTicketReplyToServer:) withObject:gift];
    
    NSString *giftText = [StringUtils convertObjectToJSONString:gift];
    
    int type = [[gift objectForKey:@"type"] intValue];
    int intVal = [[gift objectForKey:@"level"] intValue];
    NSString *inviteMessage = [NSString stringWithFormat:[SystemUtils getLocalizedString:[NSString stringWithFormat:@"ticket_reply_hint_with_type_%d",type]], intVal];
    if(type==0) {
        NSString *key = [NSString stringWithFormat:@"ticket_reply_hint_%d", intVal];
        NSString *msg = [SystemUtils getLocalizedString:key];
        if(msg!=nil && ![msg isEqualToString:key]) inviteMessage = msg;
    }
    // data, message
    if(inviteMessage) [params setValue:inviteMessage forKey:@"message"];
    [params setValue:giftText forKey:@"data"];
    
    [FBWebDialogs presentRequestsDialogModallyWithSession:[FBSession activeSession]
                                                  message:inviteMessage
                                                    title:@"Send Ticket"
                                               parameters:params
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                      if (error) {
                                                          // Case A: Error launching the dialog or sending request.
                                                          SNSLog(@"Error sending request.");
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              // Case B: User clicked the "x" icon
                                                              SNSLog(@"User canceled request.");
                                                          } else {
                                                              // Handle the send request callback
                                                              NSDictionary *urlParams = [StringUtils parseURLParams:[resultURL query]];
                                                              if (![urlParams valueForKey:@"request"]) {
                                                                  // User clicked the Cancel button
                                                                  SNSLog(@"User canceled request.");
                                                              } else {
                                                                  // User clicked the Send button
                                                                  NSString *requestID = [urlParams valueForKey:@"request"];
                                                                  SNSLog(@"Request Sent. ID: %@", requestID);
                                                                  
                                                              }
                                                              
                                                          }
                                                      }}];
    
}

// 发送赠送钥匙请求
- (void) sendTicketRequest:(int)levelID
{
    [self sendTicketRequest:levelID ofType:0 withID:levelID];
}

// 发送赠送钥匙请求, type-钥匙类型，intVal-对应的数量, req_id－请求的ID, 提示信息的格式为：
// "ticket_request_hint_with_type_1" = "Please help to send me %d coins!";
- (void) sendTicketRequest:(int)intVal ofType:(int)type withID:(int) req_id
{
    if(![self isLoggedIn]) {
        [self startLogin]; return;
    }
    
    [SystemUtils setNSDefaultObject:@"1" forKey:@"kPendingTicketRequest"];
    
    NSMutableDictionary* params =   [NSMutableDictionary dictionary];
    NSDictionary *sender = [NSDictionary dictionaryWithObjectsAndKeys:[SystemUtils getCurrentUID], @"uid", self.fbUserName, @"name", self.fbUserID, @"fbid", nil];
    
    NSDictionary *gift = [NSDictionary dictionaryWithObjectsAndKeys:@"ticketAsk", @"action",
                          [NSString stringWithFormat:@"%d", intVal], @"level",
                          [NSString stringWithFormat:@"%d", type], @"type",
                          [NSString stringWithFormat:@"%d", req_id], @"req_id",
                          [SystemUtils getCurrentUID], @"uid", sender, @"sender", nil];
    
    NSString *inviteMessage = [NSString stringWithFormat:[SystemUtils getLocalizedString:[NSString stringWithFormat:@"ticket_request_hint_with_type_%d", type]], intVal];
    if(type==0) {
        NSString *key = [NSString stringWithFormat:@"ticket_request_hint_%d", intVal];
        NSString *msg = [SystemUtils getLocalizedString:key];
        if(msg!=nil && ![msg isEqualToString:key]) inviteMessage = msg;
    }
    // 如果有多种奖励，就随机选一个
    // data, message
    if(inviteMessage) [params setValue:inviteMessage forKey:@"message"];
    if(gift) [params setValue:[StringUtils convertObjectToJSONString:gift] forKey:@"data"];
    
    [FBWebDialogs presentRequestsDialogModallyWithSession:[FBSession activeSession]
                                                  message:inviteMessage
                                                    title:@"Ask For Ticket"
                                               parameters:params
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                      if (error) {
                                                          // Case A: Error launching the dialog or sending request.
                                                          SNSLog(@"Error sending request.");
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              // Case B: User clicked the "x" icon
                                                              SNSLog(@"User canceled request.");
                                                          } else {
                                                              // Handle the send request callback
                                                              NSDictionary *urlParams = [StringUtils parseURLParams:[resultURL query]];
                                                              if (![urlParams valueForKey:@"request"]) {
                                                                  // User clicked the Cancel button
                                                                  SNSLog(@"User canceled request.");
                                                              } else {
                                                                  // User clicked the Send button
                                                                  NSString *requestID = [urlParams valueForKey:@"request"];
                                                                  SNSLog(@"Request Sent. ID: %@", requestID);
                                                                  
                                                              }
                                                              
                                                          }
                                                      }}];
    
}

@end
