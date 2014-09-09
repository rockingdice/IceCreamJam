//
//  OBJCHelper.m
//  FarmMania
//
//  Created by  James Lee on 13-5-23.
//
//

#import "OBJCHelper.h"
#import "cocos2d.h"
#import "SystemUtils.h"
#import "BubbleServiceHelper.h"
#import "BubbleServiceFunction.h"
#import "BubbleServiceUtils.h"
#import "InAppStore.h"
#import "FacebookHelper.h"
#import "SnsGameHelper.h"
#import "CCJSONConverter.h"
#import <Foundation/Foundation.h>
#import "NSData+Compression.h"
#import "StringUtils.h"
#import "ASIFormDataRequest.h"
#import "CCFileUtils.h"
#import "SnsServerHelper.h"
#import "FMGameNode.h"

#import "FMLoadingScene.h"
#import "FMMainScene.h"
#import "FMUIWorldMap.h"
#import "FMWorldMapNode.h"
#import "FMDataManager.h"
#import "SNSFunction.h"
#import "FMUIUnlimitLife.h"
#import "FMUISpin.h"
#import "GAMEUI_Scene.h"
#import "StringUtils.h"
#import "WeixinHelper.h"
#import "FMUIMessage.h"
#import "iOmniataHelper.h"
#import <CoreText/CoreText.h>
#ifdef SNS_ENABLE_TINYMOBI
#import "TinyMobiHelper.h"
#endif
#ifdef SNS_ENABLE_MINICLIP
#import <FiksuSDK/FiksuSDK.h>
#endif
#ifdef BRANCH_TH
#import "Adjust.h"
#endif

#import "kakaoPoliceViewController.h"

//#import <CoreText/CoreText.h>

//objc
@class OBJCHelperWrapper;
static OBJCHelperWrapper * m_wrapper = NULL;
@interface OBJCHelperWrapper : NSObject <InAppStoreDelegate>
{
    SEL_CallFuncO m_callback;
    CCObject * m_target;
    
    std::map<CCObject *, SEL_CallFuncO> m_downloadCallbacks;
}
+ (id) wrapper;
- (void) observeUpload:(BOOL)observe;
- (void) onUploadFinished:(NSNotification *)note;
- (void) onFacebookLoginFinished:(NSNotification *)note;
- (void) onFacebookLoginFaild;
- (void) onWeixinFeedSucceed:(NSNotification *)note;
- (void) onDownloadFinished:(NSNotification *)note;
- (void) setCallback:(SEL_CallFuncO)callback target:(CCObject *)target;
- (void) addDownloadCallback:(SEL_CallFuncO)callback target:(CCObject *)target;
// 交易完成通知，应该在这里关闭等候界面
// info中包含两个字段:
// itemId : NSString, 购买的产品ID
// amount : NSNumber, 购买数量
-(void) transactionFinished:(NSDictionary *)info;
// 交易取消通知，应该在这里关闭等候界面
-(void) transactionCancelled;

-(void) restoreFinished:(NSDictionary *)info;

-(NSDictionary *) getBIUniversalDic;

-(void) postToBI:(NSDictionary *)dic;
@end

@implementation OBJCHelperWrapper

+ (id) wrapper
{
    if (!m_wrapper) {
        m_wrapper = [[OBJCHelperWrapper alloc] init];
    }
    return m_wrapper;
}

- (id) init
{
    if ( (self = [super init]) ) { 
        
        // register payment notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onShowLoadingScene:)
                                                     name:kNotificationShowLoadingScreen
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onHideLoadingScene:)
                                                     name:kNotificationHideLoadingScreen
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onFacebookLoginFinished:)
                                                     name:kFacebookNotificationOnLoginFinished
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onFacebookLoginFaild)
                                                     name:kFacebookNotificationOnLoginFaild
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWeixinFeedSucceed:)
                                                     name:kSNSNotificationWeixinFeedSuccess
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDownloadFinished:)
                                                     name:kSNSNotificationRemoteFileLoaded
                                                   object:nil];
    }
    return self;
}

- (void) setCallback:(SEL_CallFuncO)callback target:(CCObject *)target;
{
    m_callback = callback;
    m_target = target;
}

- (void) addDownloadCallback:(SEL_CallFuncO)callback target:(cocos2d::CCObject *)target
{
    m_downloadCallbacks[target] = callback;
}

- (void) onShowLoadingScene:(NSNotification * )notify
{
    FMLoadingScene * scene = new FMLoadingScene;
    scene->autorelease();
    CCDirector::sharedDirector()->runWithScene(scene);
}

- (void) onHideLoadingScene:(NSNotification *)notify
{
    
}

- (void) onFacebookLoginFinished:(NSNotification *)note
{
    if (!FMDataManager::sharedManager()->isInGame()) {
        FMUIWorldMap * ui = (FMUIWorldMap *)FMDataManager::sharedManager()->getUI(kUI_WorldMap);
        ui->updateFacebook(false);
    }
    OBJCHelper::helper()->facebookLoginFinished();
}
- (void) onFacebookLoginFaild
{
    OBJCHelper::helper()->facebookLoginFaild();
}

- (void) onWeixinFeedSucceed:(NSNotification *)note
{ 
    if (!FMDataManager::sharedManager()->isInGame()) {
        FMUIWorldMap * ui = (FMUIWorldMap *)FMDataManager::sharedManager()->getUI(kUI_WorldMap);
        ui->updateUI();
    }
}

- (void) onDownloadFinished:(NSNotification *)note
{
    NSDictionary * dic = [note userInfo];
    NSLog(@"%@", dic);
    for (std::map<CCObject *, SEL_CallFuncO>::iterator it = m_downloadCallbacks.begin(); it != m_downloadCallbacks.end(); it++) {
        NSString * str = [dic objectForKey:@"itemID"];
        CCString * fileName = CCString::create([str UTF8String]);
        CCObject * target = it->first;
        SEL_CallFuncO sel = it->second;
        (target->*sel)(fileName);
    }
}

- (void) observeUpload:(BOOL)observe
{
    if (observe) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onUploadFinished:)
                                                     name:kBubbleServiceNotificationUploadSubLevelFinished
                                                   object:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void) onUploadFinished:(NSNotification *)note
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    int success = [[note.userInfo objectForKey:@"success"] intValue];
    NSString *mesg = [note.userInfo objectForKey:@"mesg"];
    NSString *title = @"Upload Failed";
    if(success==1) title = @"Upload Success";
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:title message:mesg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alertView show];
    FMDataManager::sharedManager()->reloadLevelData();
}

- (void) transactionCancelled
{
    [SystemUtils hideInGameLoadingView];
    if (m_callback && m_target) {
        CCDictionary * dic = CCDictionary::create();
        CCNumber * success = CCNumber::create(0);
        dic->setObject(success, "success");
        (m_target->*m_callback)(dic);
        m_callback = NULL;
        m_target = NULL;
    }
}

- (void) transactionFinished:(NSDictionary *)info
{
    [SystemUtils hideInGameLoadingView];
    if (m_callback && m_target) {
        CCDictionary * dic = CCDictionary::create();
        CCNumber * success = CCNumber::create(1);
        dic->setObject(success, "success");
        NSString * tid = [info objectForKey:@"tid"];
        if (tid) {
            dic->setObject(CCString::create([tid UTF8String]), "tid");
        }
        (m_target->*m_callback)(dic);
        m_callback = NULL;
        m_target = NULL;
    }
}

- (void) restoreFinished:(NSDictionary *)info
{
    [SystemUtils hideInGameLoadingView];
    if (m_callback && m_target) {
        (m_target->*m_callback)(CCNumber::create(1));
        m_callback = NULL;
        m_target = NULL;
    }
}

-(NSDictionary *) getBIUniversalDic
{
    NSString * uid = [SystemUtils getCurrentUID];
    NSString * snsid = [SystemUtils getIDFA];
    NSString * install_ts = [NSString stringWithFormat:@"%d",[SystemUtils getInstallTime]];
    NSString * install_source = @"";
    NSString * os = @"ios";
    NSString * os_version = [SystemUtils getiOSVersion];
    NSString * device = [SystemUtils getDeviceModel];
//    NSString * ip = [SystemUtils ];
    NSString * lang = [SystemUtils getCurrentLanguage];
    FMDataManager * manager = FMDataManager::sharedManager();
    int level = manager->getGlobalIndex(manager->getFurthestWorld(), manager->getFurthestLevel());
    
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:uid,@"uid",snsid,@"snsid",install_ts,@"install_ts",install_source,@"install_source",os,@"os",os_version,@"os_version",device,@"device",lang,@"lang",[NSNumber numberWithInt:level],@"level", nil];
    
    
    return dic;
}

-(void) postToBI:(NSDictionary *)dic
{
    NSString * urlStr = @"http://topstat.topgame.com/funplus/index.php";
    ASIFormDataRequest * req = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:urlStr]];
    [req setRequestMethod:@"POST"];
    for (NSString * key in [dic allKeys]) {
        [req setPostValue:[dic objectForKey:key] forKey:key];
    }
    [req startAsynchronous];
}

@end

@class OBJCHelperRequestUnit;
@interface OBJCHelperRequestUnit : NSObject
{
    SEL_CallFuncO m_callback;
    CCObject * m_target;
    kPostRequestType m_pType;
    int m_rTag;
    CCObject * m_userObject;
}
- (id)creatWithTarget:(CCObject *)target Callback:(SEL_CallFuncO)callback postType:(kPostRequestType)type tag:(int)tag userobject:(CCObject *)uobj;
- (int)getTag;
- (kPostRequestType)getPostType;
- (CCObject *)getTarget;
- (SEL_CallFuncO)getCallback;
- (CCObject *)getUserObject;
@end

@implementation OBJCHelperRequestUnit

- (id)creatWithTarget:(cocos2d::CCObject *)target Callback:(SEL_CallFuncO)callback postType:(kPostRequestType)type tag:(int)tag userobject:(cocos2d::CCObject *)uobj
{
    if (self = [super init]) {
        m_target = target;
        m_callback = callback;
        m_pType = type;
        m_rTag = tag;
        m_userObject = NULL;
        if (uobj) {
            m_userObject = uobj;
            m_userObject->retain();
        }
    }
    return [self autorelease];
}
- (void)dealloc
{
    [super dealloc];
    if (m_userObject) {
        m_userObject->release();
        m_userObject = NULL;
    }
}
- (int)getTag
{
    return m_rTag;
}
- (kPostRequestType)getPostType
{
    return m_pType;
}
- (CCObject *)getTarget
{
    return m_target;
}
- (SEL_CallFuncO)getCallback
{
    return m_callback;
}
- (CCObject *)getUserObject
{
    return m_userObject;
}

@end

#define kFBMaxSendNumber 30
@class OBJCHelperRequest;
static OBJCHelperRequest * m_Request = NULL;

enum FacebookReqType{
    kFBType_Invite,
    kFBType_Gift,
    kFBType_need
};

@interface OBJCHelperRequest : NSObject <ASIHTTPRequestDelegate, KNMultiItemSelectorDelegate,FacebookHelperDelegate>
{
    int m_requestTag;
    NSMutableArray * m_requestArray;
    NSMutableArray * m_facebookFrds;
    NSMutableArray * m_facebookInviteFrds;
    NSTimer * m_fbMsgTimer;
}
+ (id) request;
- (void) onGameCenterSignIn:(NSNotification *)note;
- (void) onReceivedFrdRequest:(NSNotification *)note;
- (void) onFacebookGetFrds:(NSNotification *)note;
- (void) onFacebookGetInviteFrds:(NSNotification *)note;
- (void) onFacebookGetToken:(NSNotification *)note;
- (void) onRegisterSuccess:(NSNotification *)note;
- (bool)postRequestWithTarget:(CCObject *)target Callback:(SEL_CallFuncO)callback postType:(kPostRequestType)type userObject:(CCObject *)userObject;
- (void) fbInvite;
- (void) fbAskForLife;
- (void) fbSendLife:(const char *)uid target:(CCObject *)target Callback:(SEL_CallFuncO)callback;
- (int)getFBMsgOneUserCheckedToday:(NSString *)uidstr type:(NSString *)typestr;
- (void)addFBMsgCheckTimes:(NSString *)uidstr type:(NSString *)typestr;
- (bool)getFBMsgs;
- (int)getFBFrdCount;

- (void)setSendMsgInterval:(const char *)fid :(int)type;
- (void)setSendMsgInterval:(const char *)fid :(int)type interval:(int)t;
- (int)getSendMsgInterval:(const char *)fid :(int)type;

@end

@implementation OBJCHelperRequest

+ (id) request
{
    if (!m_Request) {
        m_Request = [[OBJCHelperRequest alloc] init];
    }
    return m_Request;
}

- (id) init
{
    if ( (self = [super init]) ) {
        m_fbMsgTimer = NULL;
        m_requestTag = 0;
        m_requestArray = [[NSMutableArray alloc] init];
        m_facebookFrds = [[NSMutableArray alloc] init];
        m_facebookInviteFrds = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onGameCenterSignIn:)
                                                     name:kNotificationSyncUserInfo
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onReceivedFrdRequest:)
                                                     name:kNotificationAddWXFrd
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onFacebookGetFrds:)
                                                     name:kNotificationGetFacebookFrds
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onFacebookGetInviteFrds:)
                                                     name:kNotificationGetFacebookInviteFrds
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onFacebookGetToken:)
                                                     name:kNotificationGetFBToken
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onRegisterSuccess:)
                                                     name:kNotificationRegisterSuccess
                                                   object:nil];
    }
    return self;
}
- (void)dealloc
{
    [super dealloc];
    [m_requestArray release];
    [m_facebookFrds release];
    [m_facebookInviteFrds release];
}
- (void) onGameCenterSignIn:(NSNotification *)note
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    FMDataManager * manager = FMDataManager::sharedManager();
    NSString * username = NULL;
    if (note.userInfo) {
        username = [note.userInfo objectForKey:@"name"];
    }
    
    if (username && manager->getUserName() == NULL) {
        manager->setUserName([username UTF8String]);
        [self postRequestWithTarget:NULL Callback:NULL postType:kPostType_SyncInfo userObject:NULL];
    }
}

- (void) onReceivedFrdRequest:(NSNotification *)note
{
    if (!note.userInfo) {
        return;
    }
    NSString * fid = [note.userInfo objectForKey:@"fid"];
    NSString * type = [note.userInfo objectForKey:@"type"];
    if (!fid || [fid length] < 1) {
        return;
    }
    if ([[SystemUtils getCurrentUID] intValue] == 0) {
        FMDataManager::sharedManager()->setFid([fid intValue], [type intValue]);
        return;
    }
    if ([fid isEqualToString:[SystemUtils getCurrentUID]]) {
        return;
    }
    CCString * fidstr = CCString::createWithFormat("%s",[fid UTF8String]);
    if ([type intValue] == 5) {
        [self postRequestWithTarget:NULL Callback:NULL postType:kPostType_InviteFriend userObject:fidstr];
    }else{
        [self postRequestWithTarget:NULL Callback:NULL postType:kPostType_AddFriend userObject:fidstr];
    }
}
- (void) onFacebookGetInviteFrds:(NSNotification *)note
{
    if (!note.userInfo) {
        return;
    }
    [m_facebookInviteFrds removeAllObjects];
    NSArray * list = [note.userInfo objectForKey:@"friends"];
    if (list) {
        [m_facebookInviteFrds addObjectsFromArray:list];
    }
}
- (void) onFacebookGetFrds:(NSNotification *)note
{
    if (!note.userInfo) {
        return;
    }
    [m_facebookFrds removeAllObjects];
    NSArray * list = [note.userInfo objectForKey:@"friends"];
    if (list) {
        [m_facebookFrds addObjectsFromArray:list];
    }
    
    OBJCHelper::helper()->m_fbFriends->removeAllObjects();
    for (NSDictionary * dic in m_facebookFrds) {
        NSString * uid = [dic objectForKey:@"id"];
        NSString * name = [dic objectForKey:@"first_name"];
        int block = 0;
        int install = [[dic objectForKey:@"installed"] intValue];
        
        CCString * uidstr = CCString::create([uid UTF8String]);
        CCString * namestr = CCString::create([name UTF8String]);
        CCNumber * blockstr = CCNumber::create(block);
        
        CCDictionary * td = CCDictionary::create();
        td->setObject(uidstr, "fid");
        td->setObject(namestr, "name");
        td->setObject(blockstr, "block");
        td->setObject(CCNumber::create(install), "installed");
        
        OBJCHelper::helper()->m_fbFriends->addObject(td);
    }

    FMMainScene * mainScene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
    if (mainScene->getCurrentSceneType() == kWorldMapNode) {
        FMWorldMapNode* wd = (FMWorldMapNode*)mainScene->getNode(kWorldMapNode);
        wd->requestFriendsData();
    }
}
- (void) onFacebookGetToken:(NSNotification *)note
{
    FMMainScene * mainScene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
    if (mainScene->getCurrentSceneType() == kWorldMapNode) {
        FMWorldMapNode* wd = (FMWorldMapNode*)mainScene->getNode(kWorldMapNode);
        wd->requestFriendsData();
    }
}
- (void) onRegisterSuccess:(NSNotification *)note
{
    OBJCHelper::helper()->trackRegistration();
}

- (bool)postRequestWithTarget:(CCObject *)target Callback:(SEL_CallFuncO)callback postType:(kPostRequestType)type userObject:(CCObject *)userObject;
{
    FMDataManager * manager = FMDataManager::sharedManager();
#ifdef BRANCH_CN
//    NSString * urlStr = @"http://fbjelly.topgame.com/weixin";
    NSString * urlStr = @"http://ucjellyweb1.13580.com";
    if ([[SystemUtils getCurrentUID] intValue] == 0) {
        return false;
    }
    NSMutableDictionary * mdic = [[NSMutableDictionary alloc] init];
    [mdic setObject:[SystemUtils getCurrentUID] forKey:@"uid"];
    CCObject * postobj = NULL;
    switch (type) {
        case kPostType_SyncInfo:
        {
            urlStr = [urlStr stringByAppendingString:@"/info/sync/"];
            [mdic setObject:[NSString stringWithFormat:@"%d",manager->getUserIcon()] forKey:@"icon"];
            if (manager->getUserName() == NULL) {
                [mdic setObject:[NSString stringWithFormat:@"%s",manager->getUID()] forKey:@"name"];
            }else{
                [mdic setObject:[NSString stringWithFormat:@"%s",manager->getUserName()] forKey:@"name"];
            }
//            [mdic setObject:@"1" forKey:@"force"];
        }
            break;
        case kPostType_SyncData:
        {
            urlStr = [urlStr stringByAppendingString:@"/archive/sync/"];
            NSObject<GameDataDelegate> *gameData = [SystemUtils getGameDataDelegate];
            NSString *saveStr = [gameData exportToString];
            if(!saveStr || [saveStr length]<3) {
                SNSLog(@"failed to get gamedata.");
                [mdic release];
                return false;
            }
            saveStr = [SystemUtils stripHashFromSaveData:saveStr];

            [mdic setObject:saveStr forKey:@"gamedata"];
        }
            break;
        case kPostType_AddFriend:
        {
            urlStr = [urlStr stringByAppendingString:@"/friend/add/"];
            if (!userObject) {
                [mdic release];
                return false;
            }
            CCString * fid = (CCString* )userObject;
            postobj = fid;
            [mdic setObject:[NSString stringWithFormat:@"%s",fid->getCString()] forKey:@"target"];
        }
            break;
        case kPostType_InviteFriend:
        {
            urlStr = [urlStr stringByAppendingString:@"/friend/add/"];
            if (!userObject) {
                [mdic release];
                return false;
            }
            CCString * fid = (CCString* )userObject;
            postobj = fid;
            [mdic setObject:[NSString stringWithFormat:@"%s",fid->getCString()] forKey:@"target"];
            [mdic setObject:@"1" forKey:@"isnew"];
        }
            break;
        case kPostType_SyncFrdData:
        {
            urlStr = [urlStr stringByAppendingString:@"/archive/friends"];
        }
            break;
        case kPostType_SyncLevelRank:
        {
            urlStr = [urlStr stringByAppendingString:@"/archive/friends_detail"];
            int wi = manager->getWorldIndex();
            int li = manager->getLevelIndex();
            bool quest = manager->isQuest();
            NSString * keyStr = [NSString stringWithFormat:@"%d-%d",wi,li];
            if (quest) {
                keyStr = [keyStr stringByAppendingString:@"Q"];
            }
            [mdic setObject:keyStr forKey:@"key"];
            
            CCDictionary * td = CCDictionary::create();
            td->setObject(CCNumber::create(wi), "world");
            td->setObject(CCNumber::create(li), "level");
            td->setObject(CCNumber::create(quest), "quest");
            postobj = td;
        }
            break;
        default:
            break;
    }
    
    
    
    m_requestTag ++;
    OBJCHelperRequestUnit * unit = [[OBJCHelperRequestUnit alloc] creatWithTarget:target Callback:callback postType:type tag:m_requestTag userobject:postobj];
    [m_requestArray addObject:unit];
    
    int usezip = 0;
    NSString * postStr = [StringUtils convertObjectToJSONString:mdic];
    [mdic release];
    if ([postStr length] > 2048) {
        usezip = 1;
        NSData *data = [[postStr dataUsingEncoding:NSUTF8StringEncoding] zlibDeflate];
        postStr = [SnsGameHelper encryptDESData:data key:kDESKey];
    }else{
        NSData *data = [postStr dataUsingEncoding:NSUTF8StringEncoding];
        postStr = [SnsGameHelper encryptDESData:data key:kDESKey];
    }

    ASIFormDataRequest * req = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:urlStr]];
    [req setTag:m_requestTag];
    [req setRequestMethod:@"POST"];
    [req setPostValue:postStr forKey:@"data"];
    [req setPostValue:[NSString stringWithFormat:@"%d",usezip] forKey:@"usezip"];
	[req setDelegate:self];
    [req startAsynchronous];
#else
    if (![[FacebookHelper helper] isLoggedIn]) {
        return false;
    }
    NSString *accessToken = [SystemUtils getNSDefaultObject:@"kFBUserToken"];
    if(accessToken==nil) return false;

    NSString *urlStr = [SystemUtils getSystemInfo:@"kFacebookRequestLink"];
    if(urlStr==nil || [urlStr length]<5) {
        SNSLog(@"kFacebookSyncLink is invalid: %@", urlStr);
        return false;
    }

    NSMutableDictionary * mdic = [[NSMutableDictionary alloc] init];
    CCObject * postobj = NULL;
    switch (type) {
        case kPostType_SyncFrdData:
        {
            urlStr = [urlStr stringByAppendingString:@"archive/friends"];
            if (!m_facebookFrds || m_facebookFrds.count == 0) {
                [[FacebookHelper helper] getAllFriends:[SnsGameHelper helper]];
                [mdic release];
                return false;
            }
            NSMutableString *uidList = [[NSMutableString alloc] init]; int count = 0;
            for (int i = 0; i < m_facebookFrds.count; i++) {
                NSDictionary * dic = [m_facebookFrds objectAtIndex:i];
                if (![dic objectForKey:@"installed"] || [[dic objectForKey:@"installed"] intValue] == 0) {
                    continue;
                }
                NSString *uid = [[m_facebookFrds objectAtIndex:i] objectForKey:@"id"];
                if(count>0) [uidList appendString:@","];
                [uidList appendString:uid];
                count++;
            }
            [mdic setObject:uidList forKey:@"friend_ids"];
        }
            break;
        case kPostType_SyncLevelRank:
        {
            urlStr = [urlStr stringByAppendingString:@"archive/friends_detail"];
            if (!m_facebookFrds || m_facebookFrds.count == 0) {
                [[FacebookHelper helper] getAllFriends:[SnsGameHelper helper]];
                [mdic release];
                return false;
            }

            NSMutableString *uidList = [[NSMutableString alloc] init]; int count = 0;
            [uidList appendString:[[FacebookHelper helper] fbUserID]];
            count = 1;
            for (int i = 0; i < m_facebookFrds.count; i++) {
                NSDictionary * dic = [m_facebookFrds objectAtIndex:i];
                if (![dic objectForKey:@"installed"] || [[dic objectForKey:@"installed"] intValue] == 0) {
                    continue;
                }
                NSString *uid = [[m_facebookFrds objectAtIndex:i] objectForKey:@"id"];
                if(count>0) [uidList appendString:@","];
                [uidList appendString:uid];
                count++;
            }
            [mdic setObject:uidList forKey:@"friend_ids"];

            int wi = manager->getWorldIndex();
            int li = manager->getLevelIndex();
            bool quest = manager->isQuest();
            [mdic setObject:[NSNumber numberWithInt:wi+1] forKey:@"page"];
            [mdic setObject:[NSNumber numberWithInt:li+1] forKey:@"level"];
            [mdic setObject:[NSNumber numberWithInt:quest] forKey:@"special"];
            
            CCDictionary * td = CCDictionary::create();
            td->setObject(CCNumber::create(wi), "world");
            td->setObject(CCNumber::create(li), "level");
            td->setObject(CCNumber::create(quest), "quest");
            postobj = td;
        }
            break;
        default:
            [mdic release];
            return false;
            break;
    }
    
    
    
    m_requestTag ++;
    OBJCHelperRequestUnit * unit = [[OBJCHelperRequestUnit alloc] creatWithTarget:target Callback:callback postType:type tag:m_requestTag userobject:postobj];
    [m_requestArray addObject:unit];
    
    ASIFormDataRequest * req = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:urlStr]];
    [req setTag:m_requestTag];
    [req setRequestMethod:@"POST"];
    for (NSString * key in [mdic allKeys]) {
        [req setPostValue:[mdic objectForKey:key] forKey:key];
    }
    [req setPostValue:accessToken forKey:@"token"];
	[req setDelegate:self];
    [req startAsynchronous];
    [mdic release];
#endif
    return true;
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    [request autorelease];
    SNSLog(@"%s status code:%i",__FUNCTION__, request.responseStatusCode);
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
        [self removeRequestWithTag:request.tag];
		return;
	}
    
#ifdef BRANCH_CN
    for (int i = 0; i < [m_requestArray count]; i++) {
        OBJCHelperRequestUnit * unit = [m_requestArray objectAtIndex:i];
        if ([unit getTag] == request.tag) {
            NSString *text = [request responseString];
            SNSLog(@"resp:%@", text);
            
            NSDictionary *dict = [text JSONValue];
            if(dict==nil) {
                SNSLog(@"invalid response:%@", text);
                return;
            }
            
            int usezip = [[dict objectForKey:@"usezip"] intValue];
            NSString * dataStr = [dict objectForKey:@"data"];
            if (dataStr && [dataStr length] > 0) {
                dataStr = [SnsGameHelper decryptDES:dataStr key:kDESKey zip:usezip];
                CCDictionary * cdic = CCJSONConverter::sharedConverter()->dictionaryFrom([dataStr UTF8String]);
                if ([unit getUserObject] && [unit getPostType] == kPostType_SyncLevelRank) {
                    CCDictionary * userDic = (CCDictionary *)[unit getUserObject];
                    cdic->setObject(userDic, "userobject");
                    FMDataManager::sharedManager()->setFrdLevelDic(cdic);
                }
                switch ([unit getPostType]) {
                    case kPostType_SyncFrdData:
                    {
                        FMDataManager * manager = FMDataManager::sharedManager();
                        manager->setFrdMapDic(cdic);
                        CCArray * list = (CCArray *)cdic->objectForKey("list");
                        for (int i = 0; i < list->count(); i++) {
                            CCDictionary * ud = (CCDictionary *)list->objectAtIndex(i);
                            CCNumber * uid = (CCNumber *)ud->objectForKey("uid");
                            if (uid->getIntValue() == atoi(manager->getUID())) {
                                CCNumber * iconid = (CCNumber *)ud->objectForKey("icon");
                                if (iconid && iconid->getIntValue() > 0 && iconid->getIntValue() < 7) {
                                    manager->setUserIcon(iconid->getIntValue());
                                }
                                break;
                            }
                        }
                    }
                        break;
                    case kPostType_AddFriend:
                    case kPostType_InviteFriend:
                    {
                        FMDataManager * manager = FMDataManager::sharedManager();
                        CCDictionary * adic = (CCDictionary *)cdic->objectForKey("any");
                        manager->insertFrdMapDic(adic);
                        manager->setFid(0, 4);
                        CCString * message = (CCString *)cdic->objectForKey("message");
                        if (message) {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:Nil message:[NSString stringWithUTF8String:message->getCString()] delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                            [alert show];
                            [alert release];
                        }
                    }
                        break;
                    default:
                        break;
                }
                if ([unit getTarget] && [unit getCallback]) {
                    ([unit getTarget]->*[unit getCallback])(cdic);
                }else{
                }
            }
            [m_requestArray removeObject:unit];
            break;
        }
    }
#else
    for (int i = 0; i < [m_requestArray count]; i++) {
        OBJCHelperRequestUnit * unit = [m_requestArray objectAtIndex:i];
        if ([unit getTag] == request.tag) {
            NSString *text = [request responseString];
            SNSLog(@"resp:%@", text);
            
            NSDictionary *dict = [text JSONValue];
            if(dict==nil) {
                SNSLog(@"invalid response:%@", text);
                return;
            }
            NSNumber * result = [dict objectForKey:@"result"];
            if (result && [result intValue] != 0) {
                [self removeRequestWithTag:request.tag];
                return;
            }
            switch ([unit getPostType]) {
                case kPostType_SyncFrdData:
                {
                    CCArray * list = CCArray::create();
                    for (NSString * uid in [dict allKeys]) {
                        CCDictionary * fdic = CCDictionary::create();
                        if (uid && uid.length > 1) {
                            NSString * tuid = [uid substringFromIndex:1];
                            fdic->setObject(CCString::create([tuid UTF8String]), "uid");
                            fdic->setObject(CCString::create([[self getFBFrdNameWithId:tuid] UTF8String]), "name");
                        }
                        NSArray * t = [dict objectForKey:uid];
                        if (t) {
                            if (t.count > 0) {
                                fdic->setObject(CCNumber::create([[t objectAtIndex:0] intValue] - 1), "page");
                            }
                            if (t.count > 1) {
                                fdic->setObject(CCNumber::create([[t objectAtIndex:1] intValue] -1), "level");
                            }
                            if (t.count > 3) {
                                fdic->setObject(CCNumber::create([[t objectAtIndex:3] intValue]), "stars");
                            }
                        }
                        list->addObject(fdic);
                    }
                    CCDictionary * f = CCDictionary::create();
                    f->setObject(list, "list");
                    FMDataManager::sharedManager()->setFrdMapDic(f);
                    
                    if ([unit getTarget] && [unit getCallback]) {
                        ([unit getTarget]->*[unit getCallback])(f);
                    }
                }
                    break;
                case kPostType_SyncLevelRank:
                {
                    CCDictionary * cdic = CCDictionary::create();
                    if ([unit getUserObject]) {
                        CCDictionary * userDic = (CCDictionary *)[unit getUserObject];
                        cdic->setObject(userDic, "userobject");
                    }
                    NSArray * dataList = [dict objectForKey:@"data"];
                    CCArray * list = CCArray::create();
                    for (NSArray * dlist in dataList) {
                        CCDictionary * dic = CCDictionary::create();
                        for (int i = 0; i < [dlist count]; i++) {
                            if (i == 0) {
                                NSString * uid = [dlist objectAtIndex:0];
                                dic->setObject(CCString::create([uid UTF8String]), "uid");
                                dic->setObject(CCString::create([[self getFBFrdNameWithId:uid] UTF8String]), "name");
                            }
                            else if (i == 2){
                                NSNumber * score = [dlist objectAtIndex:2];
                                dic->setObject(CCNumber::create(score.intValue), "highscore");
                            }
                        }
                        list->addObject(dic);
                    }
                    cdic->setObject(list, "list");
                    FMDataManager::sharedManager()->setFrdLevelDic(cdic);
                    
                    if ([unit getTarget] && [unit getCallback]) {
                        ([unit getTarget]->*[unit getCallback])(cdic);
                    }

                }
                    break;
                default:
                    break;
            }
//            NSString * dataStr = [dict objectForKey:@"data"];
//            if (dataStr && [dataStr length] > 0) {
//                CCDictionary * cdic = CCJSONConverter::sharedConverter()->dictionaryFrom([dataStr UTF8String]);
//                if ([unit getUserObject] && [unit getPostType] == kPostType_SyncLevelRank) {
//                    CCDictionary * userDic = (CCDictionary *)[unit getUserObject];
//                    cdic->setObject(userDic, "userobject");
//                    FMDataManager::sharedManager()->setFrdLevelDic(cdic);
//                }
//                switch ([unit getPostType]) {
//                    case kPostType_SyncFrdData:
//                    {
//                        FMDataManager * manager = FMDataManager::sharedManager();
//                        manager->setFrdMapDic(cdic);
//                        CCArray * list = (CCArray *)cdic->objectForKey("list");
//                        for (int i = 0; i < list->count(); i++) {
//                            CCDictionary * ud = (CCDictionary *)list->objectAtIndex(i);
//                            CCNumber * uid = (CCNumber *)ud->objectForKey("uid");
//                            if (uid->getIntValue() == atoi(manager->getUID())) {
//                                CCNumber * iconid = (CCNumber *)ud->objectForKey("icon");
//                                if (iconid && iconid->getIntValue() > 0 && iconid->getIntValue() < 7) {
//                                    manager->setUserIcon(iconid->getIntValue());
//                                }
//                                break;
//                            }
//                        }
//                    }
//                        break;
//                    case kPostType_AddFriend:
//                    case kPostType_InviteFriend:
//                    {
//                        FMDataManager * manager = FMDataManager::sharedManager();
//                        CCDictionary * adic = (CCDictionary *)cdic->objectForKey("any");
//                        manager->insertFrdMapDic(adic);
//                        manager->setFid(0, 4);
//                        CCString * message = (CCString *)cdic->objectForKey("message");
//                        if (message) {
//                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:Nil message:[NSString stringWithUTF8String:message->getCString()] delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//                            [alert show];
//                            [alert release];
//                        }
//                    }
//                        break;
//                    default:
//                        break;
//                }
            [m_requestArray removeObject:unit];
            break;
        }
    }
#endif
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
	SNSLog(@"%s - error: %@", __FUNCTION__, error);
    [self removeRequestWithTag:request.tag];
    [request autorelease];
}

- (void)removeRequestWithTag:(int)tag
{
    for (int i = 0; i < [m_requestArray count]; i++) {
        OBJCHelperRequestUnit * unit = [m_requestArray objectAtIndex:i];
        if ([unit getTag] == tag) {
            [m_requestArray removeObject:unit];
            break;
        }
    }
}

-(void)selectorDidCancelSelection:(KNMultiItemSelector *)selector
{
    [[SystemUtils getRootViewController] dismissModalViewControllerAnimated:NO];
}

-(void)selector:(KNMultiItemSelector *)selector didFinishSelectionWithItems:(NSArray*)selectedItems
{
    FacebookReqType reqType = (FacebookReqType)selector.tag;
    [[SystemUtils getRootViewController] dismissModalViewControllerAnimated:NO];
    if(selectedItems==nil || [selectedItems count]==0) {
        return;
    }
    // [selector autorelease];
    // send requests to friends
    NSMutableString *uidList = [[NSMutableString alloc] init]; int count = 0;
    for (KNSelectorItem * i in selectedItems) {
        NSString *uid = i.selectValue;
        if(count>0) [uidList appendString:@","];
        [uidList appendString:uid];
        count++;
    }
    if(count==0) {
        return;
    }
    
    NSMutableDictionary* params =   [NSMutableDictionary dictionaryWithObjectsAndKeys:uidList, @"to",nil];
    
    NSString *inviteMessage;
    NSString * title;
    
    if (reqType == kFBType_Invite) {
        [params setValue:@"invite" forKey:@"data"];
        title = @"Invite";
        inviteMessage = [SystemUtils getSystemInfo:@"kFacebookInviteMessage"];
    }else if (reqType == kFBType_need){
        [params setValue:@"need" forKey:@"data"];
        title = @"Ask for lives";
        inviteMessage = [SystemUtils getSystemInfo:@"kFacebookNeedGiftMessage"];
    }else{
        [params setValue:@"gift" forKey:@"data"];
        title = @"Send lives";
        inviteMessage = [SystemUtils getSystemInfo:@"kFacebookSendGiftMessage"];
    }
    
    if(inviteMessage) [params setValue:inviteMessage forKey:@"message"];

    [FBWebDialogs presentRequestsDialogModallyWithSession:[FBSession activeSession]
                                                  message:inviteMessage
                                                    title:title
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
- (void) onGetUserInfo:(NSDictionary *)info withError:(NSError *)error
{
    if (error) {
        return;
    }
    
    NSString * gender = @"u";
    NSString * gstr = [info objectForKey:@"gender"];
    if (gstr && [gstr isEqualToString:@"female"]) {
        gender = @"f";
    }else if (gstr && [gstr isEqualToString:@"male"]){
        gender = @"m";
    }
    NSString * birthday = @"";
    if ([info objectForKey:@"birthday"]) {
        NSArray * blist = [[info objectForKey:@"birthday"] componentsSeparatedByString:@"/"];
        if ([blist count] > 2) {
            birthday = [NSString stringWithFormat:@"%@-%@-%@",[blist objectAtIndex:2],[blist objectAtIndex:0],[blist objectAtIndex:1]];
        }else{
            birthday = [info objectForKey:@"birthday"];
        }
    }
    OBJCHelper::helper()->trackLoginFb([gender UTF8String], [birthday UTF8String]);
}
- (void) onGetFacebookMessages:(NSArray *)msgs withError:(NSError *)error
{
    FMUIMessage * msg = (FMUIMessage *)FMDataManager::sharedManager()->getUI(kUI_Message);

    if(error!=nil) {
        if (msg) {
            msg->updateUI(false);
        }

        SNSLog(@"failed to get facebook msgs:%@", error);
        return;
    }
    OBJCHelper::helper()->m_fbMessages->removeAllObjects();
    if(msgs ==nil || ![msgs isKindOfClass:[NSArray class]] || [msgs count]==0) {
        if (msg) {
            msg->updateUI(false);
        }

        SNSLog(@"no msgs");
        return;
    }

    NSMutableDictionary * tmpdic = [[NSMutableDictionary alloc] init];
    for (NSDictionary * dic in msgs) {
        NSString * uidstr = [[dic objectForKey:@"from"] objectForKey:@"id"];
        NSString * datastr = [dic objectForKey:@"data"];
        if ([datastr isEqualToString:@"invite"]) {
            continue;
        }
        int checkedToday = [self getFBMsgOneUserCheckedToday:uidstr type:datastr];
        if (checkedToday >= 5 ) {
            continue;
        }
        NSNumber * count = [tmpdic objectForKey:uidstr];
        if (!count) {
            count = [NSNumber numberWithInt:1+checkedToday];
        }else{
            count = [NSNumber numberWithInt:count.intValue+1];
        }
        if (count.intValue > 5) {
            continue;
        }
        [tmpdic setObject:count forKey:uidstr];
        
        CCDictionary * cdic = CCDictionary::create();
        CCString * msgid = CCString::create([[dic objectForKey:@"id"] UTF8String]);
        CCString * uid = CCString::create([uidstr UTF8String]);
        CCString * data = CCString::create([datastr UTF8String]);
        CCString * message = CCString::create([[dic objectForKey:@"message"] UTF8String]);
        CCString * name = CCString::create([[self getFBFrdNameWithId:[NSString stringWithUTF8String:uid->getCString()]] UTF8String]);
        
        cdic->setObject(msgid, "msgid");
        cdic->setObject(uid, "uid");
        cdic->setObject(data, "data");
        cdic->setObject(message, "message");
        cdic->setObject(name, "name");
        OBJCHelper::helper()->m_fbMessages->addObject(cdic);
    }
    [tmpdic release];
    
    if (msg) {
        msg->updateUI(false);
    }
}
- (int)getFBMsgOneUserCheckedToday:(NSString *)uidstr type:(NSString *)typestr
{
    NSDictionary * fbMsgDic = [SystemUtils getNSDefaultObject:@"kFBMsg"];
    if (!fbMsgDic) {
        return 0;
    }
    int todayDate = [SystemUtils getTodayDate];
    int savedDate = [[fbMsgDic objectForKey:@"date"] intValue];
    if (todayDate != savedDate) {
        return 0;
    }
    
    NSDictionary * todayUsers = [fbMsgDic objectForKey:@"users"];
    if (!todayUsers) {
        return 0;
    }
    NSDictionary * userdic = [todayUsers objectForKey:uidstr];
    if (!userdic) {
        return 0;
    }
    NSNumber * times = [userdic objectForKey:typestr];
    if (!times) {
        return 0;
    }
    
    return times.intValue;
}
- (void)addFBMsgCheckTimes:(NSString *)uidstr type:(NSString *)typestr
{
    NSDictionary * fbMsgDic = [SystemUtils getNSDefaultObject:@"kFBMsg"];
    NSMutableDictionary * tdic = [[NSMutableDictionary alloc] initWithDictionary:fbMsgDic];
    
    int todayDate = [SystemUtils getTodayDate];
    [tdic setObject:[NSNumber numberWithInt:todayDate] forKey:@"date"];
    
    NSDictionary * todayUsers = [fbMsgDic objectForKey:@"users"];
    NSMutableDictionary * todayUsersDic = [[NSMutableDictionary alloc] initWithDictionary:todayUsers];
    
    if ([todayUsersDic objectForKey:uidstr]) {
        NSMutableDictionary * udic = [[NSMutableDictionary alloc] initWithDictionary:[todayUsersDic objectForKey:uidstr]];
        int t = [[udic objectForKey:typestr] intValue]+1;
        [udic setObject:[NSNumber numberWithInt:t] forKey:typestr];
        [todayUsersDic setObject:udic forKey:uidstr];
        [udic release];
    }else{
        [todayUsersDic setObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:typestr] forKey:uidstr];
    }
    [tdic setObject:todayUsersDic forKey:@"users"];
    [todayUsersDic release];
    
    [SystemUtils setNSDefaultObject:tdic forKey:@"kFBMsg"];
    [tdic release];
}

- (bool)getFBMsgs
{
    if (m_fbMsgTimer) {
        [m_fbMsgTimer invalidate];
        m_fbMsgTimer = NULL;
    }
    if (![[FacebookHelper helper] isLoggedIn]) {
        return false;
    }
    m_fbMsgTimer = [NSTimer scheduledTimerWithTimeInterval:30.f target:self selector:@selector(getFBMsgs) userInfo:nil repeats:true];
    [[FacebookHelper helper] getAppMessage:self];
    return true;
}
- (int)getFBFrdCount
{
    if (!m_facebookFrds) {
        return 0;
    }
    return m_facebookFrds.count;
}

- (NSString *)getFBFrdNameWithId:(NSString *)uid
{
    for (NSDictionary * dic in m_facebookFrds) {
        if ([[dic objectForKey:@"id"] isEqualToString:uid]) {
            return [dic objectForKey:@"first_name"];
        }
    }
    return @"";
}

- (void)setSendMsgInterval:(const char *)fid :(int)type interval:(int)t
{
    int time = OBJCHelper::helper()->getCurrentTime() + t;
    NSDictionary * fbMsgDic = [SystemUtils getNSDefaultObject:@"kFBMsg"];
    NSMutableDictionary * tdic = [[NSMutableDictionary alloc] initWithDictionary:fbMsgDic];
    NSString * key = [NSString stringWithUTF8String:fid];
    key = [key stringByAppendingFormat:@"type%d",type];
    [tdic setObject:[NSNumber numberWithInt:time] forKey:key];
    [SystemUtils setNSDefaultObject:tdic forKey:@"kFBMsg"];
    [tdic release];
}

- (void)setSendMsgInterval:(const char *)fid :(int)type
{
    int time = 3600*24;
    [self setSendMsgInterval:fid :type interval:time];
}
- (int)getSendMsgInterval:(const char *)fid :(int)type
{
    NSDictionary * fbMsgDic = [SystemUtils getNSDefaultObject:@"kFBMsg"];
    if (!fbMsgDic) {
        return 0;
    }
    NSString * key = [NSString stringWithUTF8String:fid];
    key = [key stringByAppendingFormat:@"type%d",type];
    if ([fbMsgDic objectForKey:key]) {
        return [[fbMsgDic objectForKey:key] intValue];
    }
    
    return 0;
}

- (void) fbInvite
{
    if (!m_facebookInviteFrds) {
        return;
    }
    
    NSMutableArray * arr = [[NSMutableArray alloc] init];
    for (int i = 0; i < [m_facebookInviteFrds count]; i++) {
        NSDictionary * dic = [m_facebookInviteFrds objectAtIndex:i];
        if (arr.count == kFBMaxSendNumber) {
            break;
        }
        [arr addObject:[[KNSelectorItem alloc] initWithDisplayValue:[dic objectForKey:@"name"]
                                                        selectValue:[dic objectForKey:@"id"]
                                                           imageUrl:[[[dic objectForKey:@"picture"] objectForKey:@"data"] objectForKey:@"url"]]];
        
    }
    
    if([arr count]==0) {
//        SNSLog(@"No friends found:%@", arr); [arr release];
//        return;
    }
    
    KNMultiItemSelector * selector = [[KNMultiItemSelector alloc] initWithItems:arr
                                                               preselectedItems:arr
                                                                          title:@"Invite Friends"
                                                                placeholderText:@"Search by name"
                                                                       delegate:self];
    // Again, the two optional settings
    selector.allowSearchControl = YES;
    selector.useTableIndex      = YES;
    selector.useRecentItems     = YES;
    selector.maxNumberOfRecentItems = kFBMaxSendNumber;
    selector.allowModeButtons = NO;
    selector.tag = kFBType_Invite;
    UINavigationController * uinav = [[UINavigationController alloc] initWithRootViewController:selector];
    uinav.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    uinav.modalPresentationStyle = UIModalPresentationFormSheet;
    UIViewController *root = [SystemUtils getRootViewController];
    if(root)
        [root presentModalViewController:uinav animated:YES];
    // [selector autorelease];
    [arr release];
    [selector release];
}

- (void) fbAskForLife
{
    if (!m_facebookFrds || m_facebookFrds.count == 0) {
        return;
    }
    
    NSMutableArray * arr = [[NSMutableArray alloc] init];
    for (int i = 0; i < [m_facebookFrds count]; i++) {
        NSDictionary * dic = [m_facebookFrds objectAtIndex:i];
        if (![dic objectForKey:@"installed"] && [[dic objectForKey:@"installed"] intValue] == 0) continue;
        if (arr.count == kFBMaxSendNumber) {
            break;
        }
        [arr addObject:[[KNSelectorItem alloc] initWithDisplayValue:[dic objectForKey:@"name"]
                                                        selectValue:[dic objectForKey:@"id"]
                                                           imageUrl:[NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=square", [dic objectForKey:@"id"]]]];
        
    }
    
    if([arr count]==0) {
        SNSLog(@"No friends found:%@", arr); [arr release];
        return;
    }
    
    KNMultiItemSelector * selector = [[KNMultiItemSelector alloc] initWithItems:arr
                                                               preselectedItems:arr
                                                                          title:@"Ask for help"
                                                                placeholderText:@"Search by name"
                                                                       delegate:self];
    // Again, the two optional settings
    selector.allowSearchControl = YES;
    selector.useTableIndex      = YES;
    selector.useRecentItems     = YES;
    selector.maxNumberOfRecentItems = kFBMaxSendNumber;
    selector.allowModeButtons = NO;
    selector.tag = kFBType_need;
    UINavigationController * uinav = [[UINavigationController alloc] initWithRootViewController:selector];
    uinav.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    uinav.modalPresentationStyle = UIModalPresentationFormSheet;
    UIViewController *root = [SystemUtils getRootViewController];
    if(root)
        [root presentModalViewController:uinav animated:YES];
    // [selector autorelease];
    [arr release];
    [selector release];
}

- (void) fbSendLife:(const char *)uid target:(CCObject *)target Callback:(SEL_CallFuncO)callback
{
    if (!uid) {
        return;
    }
    NSString * uidstr = [NSString stringWithUTF8String:uid];
    NSMutableDictionary* params =   [NSMutableDictionary dictionaryWithObjectsAndKeys:uidstr, @"to",nil];
    [params setValue:@"gift" forKey:@"data"];
    [params setValue:[SystemUtils getSystemInfo:@"kFacebookSendGiftMessage"] forKey:@"message"];

    [FBWebDialogs presentRequestsDialogModallyWithSession:[FBSession activeSession]
                                                  message:[SystemUtils getSystemInfo:@"kFacebookSendGiftMessage"]
                                                    title:@"Send Life"
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
                                                                  SNSLog(@"Request Sent. ID: %@, %@", requestID, uidstr);
                                                                  NSArray * uidlist = [uidstr componentsSeparatedByString:@","];
                                                                  for (int i = 0; i < [uidlist count]; i++) {
                                                                      NSString * u = [uidlist objectAtIndex:i];
                                                                      [self setSendMsgInterval:[u UTF8String] :1];
                                                                  }
                                                                  if (target && callback) {
                                                                      (target->*callback)(NULL);
                                                                  }
                                                              }
                                                              
                                                          }
                                                      }}];
}

@end
//cpp



using namespace cocos2d;
static OBJCHelper * m_instance = NULL;

OBJCHelper::OBJCHelper()
:m_delegate(NULL),
m_startTime(0)
{
    m_iapProducts = CCArray::create();
    m_iapProducts->retain();
    
    m_fbMessages = CCArray::create();
    m_fbMessages->retain();
    
    m_fbFriends = CCArray::create();
    m_fbFriends->retain();
    
    [OBJCHelperWrapper wrapper];
}

OBJCHelper::~OBJCHelper()
{
    m_iapProducts->release();
    m_fbMessages->release();
    m_fbFriends->release();
}

OBJCHelper * OBJCHelper::helper()
{
    if (!m_instance) {
        m_instance = new OBJCHelper();

    }
    return m_instance;
}

std::vector<std::string> &split(const std::string &s, char delim, std::vector<std::string> &elems) {
    std::stringstream ss(s);
    std::string item;
    while (std::getline(ss, item, delim)) {
        elems.push_back(item);
    }
    return elems;
}


std::vector<std::string> split(const std::string &s, char delim) {
    std::vector<std::string> elems;
    split(s, delim, elems);
    return elems;
}

std::string replace(std::string &str, const char *string_to_replace, const char *new_string)
{
    // Find the first string to replace
    int index = str.find(string_to_replace);
    // while there is one
    while(index != std::string::npos)
    {
        // Replace it
        str.replace(index, strlen(string_to_replace), new_string);
        // Find the next one
        index = str.find(string_to_replace, index + strlen(new_string));
    }
    return str;
}

void OBJCHelper::loadLocalizedStrings()
{
    const char * langCode = getLanguageCode();
    CCString * content = CCString::createWithContentsOfFile("LOCALIZATION.csv");
    std::vector<std::string> splits = split(content->getCString(), '\n');
    std::string fieldstring = splits.at(0);
    std::vector<std::string> fields = split(fieldstring, ';');
    int index = 0;
    for (int i=0; i<fields.size(); i++) {
        std::string & s = fields[i];
        if (s == langCode) {
            CCLOG("langIndex: %d", i);
            index = i;
            break;
        }
    }
    
    for (int i=1; i<splits.size(); i++) {
        std::string &row = splits[i];
        std::vector<std::string> texts = split(row, ';');
        for (int j=0; j<texts.size(); j++) {
            std::string &t = texts[0];
            std::string &text = texts[index];
            text = replace(text, "\\n", "\n");
            m_localizedStrings[t] = text;
        }
    }
}

void OBJCHelper::loadFont(const char * path)
{
    NSString * fontPath = [NSString stringWithCString:CCFileUtils::sharedFileUtils()->fullPathForFilename(path).c_str() encoding:NSUTF8StringEncoding];
    CGDataProviderRef fontDataProvider = CGDataProviderCreateWithFilename([fontPath UTF8String]);//"TypographyofCoop-Black.ttf");
    
    // Create the font with the data provider, then release the data provider.
    CGFontRef customFont =  CGFontCreateWithDataProvider(fontDataProvider);
    if (!customFont) {
        NSLog(@"font didn't find: %@", fontPath);
        return;
    }
    CGDataProviderRelease(fontDataProvider);
    
    CFErrorRef error = nil;
    CTFontManagerRegisterGraphicsFont(customFont, &error);
    NSString *s = (NSString *)CGFontCopyFullName(customFont);
    NSLog(@"fullname %@", s);
    CGFontRelease(customFont);
    if (error != nil)
    {
        NSError* err = (NSError*)error;
        NSLog(@"error code %d desc: %@",err.code, [err description]);
    }
}

const char * OBJCHelper::getLocalizedString(const char *string)
{
    if (m_localizedStrings.find(string) != m_localizedStrings.end()) {
        return m_localizedStrings[string].c_str();
    } 
    NSString * s = [SystemUtils getLocalizedString:[NSString stringWithCString:string encoding:NSUTF8StringEncoding]];
    return s.UTF8String; 
}

const char * OBJCHelper::getLanguageCode()
{ 
    NSString * s = [SystemUtils getCurrentLanguage];
#ifdef BRANCH_WORLD
    const char * ss = s.UTF8String;
    //currently only allowed: English.
    if (strcmp(ss, "en") == 0) {
        return ss;
    }
    else {
        return "en";
    }
#elif defined BRANCH_JP
    const char * ss = s.UTF8String;
    if (strcmp(ss, "ja") == 0) {
        return ss;
    }
    else {
        return "ja";
    }
#elif defined BRANCH_CN
    const char * ss = s.UTF8String;
    //currently only allowed: (English), Simplified Chinese, Traditional Chinese.
    if (/*strcmp(ss, "en") == 0 ||*/ strcmp(ss, "zh-Hans") == 0 || strcmp(ss, "zh-Hant") == 0) {
        return ss;
    }
    else {
        return "zh-Hans";
    }
    
#elif defined BRANCH_TH
    const char * ss = s.UTF8String;
    //Thai
    if (strcmp(ss, "th") == 0) {
        return ss;
    }
    else {
        return "th";
    }
#else
    return "en";
#endif
}

const char * OBJCHelper::getUID()
{
    return [SystemUtils getCurrentUID].UTF8String;
}

int OBJCHelper::getCurrentTime()
{
    return [SystemUtils getCurrentTime];
}

void OBJCHelper::uploadLevelData(int worldIndex, int levelIndex, bool isQuest, const char * content)
{
    BubbleLevelInfo * info = FMDataManager::sharedManager()->getLevelInfo(worldIndex);
    if (info) {
        // register notification info 
        [[OBJCHelperWrapper wrapper] observeUpload:YES];        
        NSString * sublevelid = [NSString stringWithFormat:@"%d",levelIndex+1];
        NSString * levelid = [NSString stringWithFormat:@"%d", info->ID];
        NSString * c = [NSString stringWithFormat:@"%s", content];
        int type = 0; if(isQuest) type = 1;
        [[BubbleServiceHelper helper] uploadSubLevel:sublevelid ofLevel:levelid withContent:c andType:type];
    }
}

const char * OBJCHelper::getHMAC()
{
    NSString * s = [BubbleServiceUtils getClientHMAC];
    return [s UTF8String];
}

const char * OBJCHelper::getVersion()
{
    NSString * s = [SystemUtils getClientVersion];
    return [s UTF8String];
}

void OBJCHelper::updateIAPGroup(iapItemGroup *group)
{ 
    CCDictionary * dic = (CCDictionary *)getIAPProducts()->objectAtIndex(group->index);
    group->amount = ((CCNumber *)dic->objectForKey("amount"))->getIntValue();
    group->price =((CCString *)dic->objectForKey("price"))->getCString();
    group->ID = ((CCString *)dic->objectForKey("ID"))->getCString();
    group->symbol = ((CCString *)dic->objectForKey("symbol"))->getCString();
    group->code = ((CCString *)dic->objectForKey("code"))->getCString();
}

CCArray * OBJCHelper::getIAPProducts()
{
    NSArray * array = [[InAppStore store] getProductList];
    
    CCArray * products = CCArray::create();
    for (int i=0; i<[array count]; i++) {
        NSDictionary * data = [array objectAtIndex:i];
        NSString * price = [data objectForKey:@"OriginalPrice"];
        NSString * symbol = [data objectForKey:@"CurrencySymbol"];
        NSString * ID = [data objectForKey:@"ID"];
        NSString * currencyCode = [data objectForKey:@"CurrencyCode"];
        
        int amount = [[SnsGameHelper helper] getIapItemQuantity:ID];
        
        CCDictionary * dic = CCDictionary::create();
        dic->setObject(CCString::create([price UTF8String]), "price");
        dic->setObject(CCString::create([symbol UTF8String]), "symbol");
        dic->setObject(CCString::create([ID UTF8String]), "ID");
        dic->setObject(CCNumber::create(amount), "amount");
        dic->setObject(CCString::create([currencyCode UTF8String]), "code");
        products->addObject(dic);
    }
    m_iapProducts->removeAllObjects();
    m_iapProducts->addObjectsFromArray(products);
    return m_iapProducts;
}

void OBJCHelper::buyIAPItem(const char *itemID, int amount, CCObject * target, SEL_CallFuncO callback)
{
    BOOL res = [[InAppStore store] buyAppStoreItem:[NSString stringWithCString:itemID encoding:NSUTF8StringEncoding] amount:amount withDelegate:[OBJCHelperWrapper wrapper]];
    [[OBJCHelperWrapper wrapper] setCallback:callback target:target];
    if(res) {
        [SystemUtils showInGameLoadingView];
    }
}


void OBJCHelper::restoreIAP(CCObject * target, SEL_CallFuncO callback)
{
    [[InAppStore store] restoreIAP:[OBJCHelperWrapper wrapper]];
    [[OBJCHelperWrapper wrapper] setCallback:callback target:target];
    [SystemUtils showInGameLoadingView];
}

void OBJCHelper::saveGame()
{
    SNSFunction_saveGameData();
}

void OBJCHelper::contactUs()
{
#ifdef DEBUG
    // SNSFunction_logBuyItem("fiveStep", 1, 9, 2, 0, "default");
    // SNSFunction_connectFacebookAndInvite(); return;
#endif
    SNSFunction_writeEmailToSupport();
    
}

void OBJCHelper::connectFacebook(bool connect)
{
    
}

bool OBJCHelper::isConnectedToFacebook()
{
    return false;
}

void OBJCHelper::showTinyMobiOffer()
{
#ifdef SNS_ENABLE_TINYMOBI
    [[TinyMobiHelper helper] showOffer];
#endif
}

void OBJCHelper::goUpdate()
{
    NSString *link = [SystemUtils getAppDownloadLink];
    if(link) {
        [SystemUtils openAppLink:link];
    }
}

void OBJCHelper::showRate()
{
    [SystemUtils showReviewHint];
}

void OBJCHelper::addDownloadCallback(cocos2d::CCObject *target, SEL_CallFuncO callback)
{
    [[OBJCHelperWrapper wrapper] addDownloadCallback:callback target:target];
}

bool OBJCHelper::postRequest(CCObject * target, SEL_CallFuncO callback, kPostRequestType type, CCObject * userObject)
{
    return [[OBJCHelperRequest request] postRequestWithTarget:target Callback:callback postType:type userObject:userObject];
}
void OBJCHelper::initRequest()
{
    [OBJCHelperRequest request];
}

void OBJCHelper::connectToFacebook(OBJCHelperDelegate * delegate)
{
    m_delegate = delegate;
    [[FacebookHelper helper] startLogin];
}
void OBJCHelper::facebookLoginFinished()
{
    [[FacebookHelper helper] getUserInfo:[OBJCHelperRequest request]];
    if (m_delegate) {
        m_delegate->facebookLoginSuccess();
    }
}
void OBJCHelper::facebookLoginFaild()
{
    if (m_delegate) {
        m_delegate->facebookLoginFaild();
    }
}
void OBJCHelper::releaseDelegate(OBJCHelperDelegate * delegate)
{
    if (m_delegate == delegate) {
        m_delegate = NULL;
    }
}
bool OBJCHelper::showUnlimitLife()
{
    const char *info = SNSFunction_getRemoteConfigString("kUnlimitLifeInfo");
    if (!info) {
        return false;
    }
    NSDictionary *offerInfo = [StringUtils convertJSONStringToObject:[NSString stringWithUTF8String:info]];
    if(!offerInfo || ![offerInfo isKindOfClass:[NSDictionary class]]) return false;
    
    int todayDate = [SystemUtils getTodayDate];
    int lastUseDate = [[SystemUtils getNSDefaultObject:@"kUnlimitLifeUseTime"] intValue];
    int now = getCurrentTime();
    if (lastUseDate == todayDate) {
        return false;
    }

    // check start and end time
    NSString *startStr = [offerInfo objectForKey:@"start"];
    NSString *endStr   = [offerInfo objectForKey:@"end"];
    NSDate *stDate = [StringUtils convertStringToDate:startStr];
    NSDate *edDate = [StringUtils convertStringToDate:endStr];
    if([stDate timeIntervalSince1970]>now || [edDate timeIntervalSince1970]<now) return NO;
    
    // check if image ready
    NSString *fileName = [offerInfo objectForKey:@"fileName"];
    NSString *animName = [offerInfo objectForKey:@"animName"];
    if(fileName==nil || animName==nil) return NO;
    NSString *path = [SystemUtils getItemImagePath];
    NSString *imageFile = [NSString stringWithFormat:@"%@/%@", path, fileName];
    if(![[NSFileManager defaultManager] fileExistsAtPath:imageFile]) {
        SNSLog(@"image not found:%@", imageFile);
        return false;
    }
    
    NSString * weekday = [offerInfo objectForKey:@"weekday"];
    NSArray * weekdays = [weekday componentsSeparatedByString:@","];
    int today = [SystemUtils getCurrentWeekDay] - 1;
    if (today == 0) {
        today = 7;
    }
    int currentHour = [SystemUtils getCurrentHour];
    bool flag = false;
    for (NSString * day in weekdays) {
        if (today == [day intValue]) {
            NSString * startHour = [offerInfo objectForKey:@"clock1"];
            NSString * endHour = [offerInfo objectForKey:@"clock2"];
            if ([startHour intValue] > currentHour || [endHour intValue] < currentHour) {
                return false;
            }
            
            flag = true;
            NSString * timestr = [NSString stringWithFormat:@"%04d-%02d-%02d %02d:00",[SystemUtils getCurrentYear], [SystemUtils getCurrentMonth], [SystemUtils getCurrentDay], [endHour intValue]+1];
            int time = [[StringUtils convertStringToDate:timestr] timeIntervalSinceNow];
            FMDataManager *manager = FMDataManager::sharedManager();
            manager->setUnlimitLifeTime(MAX(now, manager->getUnlimitLifeTime()) + time);
            [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:todayDate] forKey:@"kUnlimitLifeUseTime"];

            FMUIUnlimitLife * dialog = (FMUIUnlimitLife *)FMDataManager::sharedManager()->getUI(kUI_UnlimitLife);
            GAMEUI_Scene::uiSystem()->addDialog(dialog);
            dialog->showWithFile([imageFile UTF8String], [animName UTF8String]);
            break;
        }
    }
    
    
    return flag;
}


bool OBJCHelper::showFreeSpin()
{
#ifndef SNS_DISABLE_DAILYCHECKIN
    return false;
#endif
    if (!showMinigame()) {
        return false;
    }
    FMDataManager * manager = FMDataManager::sharedManager();
    if (manager->getGlobalIndex(manager->getFurthestWorld(), manager->getFurthestLevel()) < 7) {
        return false;
    }
    if (manager->getSpinTimes() > 0) {
        return false;
    }
    int todayDate = [SystemUtils getTodayDate];
    CCNumber * lastUseDate = (CCNumber *)manager->getObjectForUserSave("kFreeSpinDate");
    if (lastUseDate && lastUseDate->getIntValue() == todayDate) {
        return false;
    }
    
    manager->addSpinTimes();
    manager->setObjectForUserSave(CCNumber::create(todayDate), "kFreeSpinDate");
    
    FMUISpin * window = (FMUISpin *)manager->getUI(kUI_Spin);
    GAMEUI_Scene::uiSystem()->nextWindow(window);
    
    return true;
}

void OBJCHelper::inviteFBFriends()
{
    [[OBJCHelperRequest request] fbInvite];
}

void OBJCHelper::askLifeFromFriend()
{
    [[OBJCHelperRequest request] fbAskForLife];
}

void OBJCHelper::sendLifeToFriend(const char * uid, CCObject * target, SEL_CallFuncO callback)
{
    [[OBJCHelperRequest request] fbSendLife:uid target:target Callback:callback];
}

bool OBJCHelper::getFacebookMessages()
{
    return [[OBJCHelperRequest request] getFBMsgs];
}

int  OBJCHelper::facebookFrdCount()
{
    return [[OBJCHelperRequest request] getFBFrdCount];
}

void OBJCHelper::acceptFBRequest()
{
    NSMutableString *uidList = [[NSMutableString alloc] init]; int count = 0;
    for (int i = 0; i < m_fbMessages->count(); i++) {
        CCDictionary * dic = (CCDictionary *)m_fbMessages->objectAtIndex(i);
        CCNumber * select = (CCNumber *)dic->objectForKey("select");
        if (!select || select->getIntValue() == 0) {
            continue;
        }
        
        CCString * data = (CCString *)dic->objectForKey("data");
        CCString * uid = (CCString *)dic->objectForKey("uid");
        
        [[OBJCHelperRequest request] addFBMsgCheckTimes:[NSString stringWithUTF8String:uid->getCString()] type:[NSString stringWithUTF8String:data->getCString()]];
        if (strcmp(data->getCString(), "gift") == 0) {
            FMDataManager * manager = FMDataManager::sharedManager();
            manager->setLifeNum(manager->getLifeNum() + 1);
        }else if (strcmp(data->getCString(), "need") == 0){
            NSString *uidstr = [NSString stringWithUTF8String:uid->getCString()];
            if(count>0) [uidList appendString:@","];
            [uidList appendString:uidstr];
            count++;
        }
        
        CCString * rid = (CCString *)dic->objectForKey("msgid");
        [[FacebookHelper helper] deleteAppRequest:[NSString stringWithUTF8String:rid->getCString()]];
        
        m_fbMessages->removeObjectAtIndex(i);
        i--;
    }
    if ([uidList length] > 0) {
        sendLifeToFriend([uidList UTF8String]);
    }
    FMDataManager::sharedManager()->updateStatusBar();
}

int get8DifWithTimeSinceNow(int t)
{
    NSDate * tdate = [NSDate dateWithTimeIntervalSinceNow:t];
    
    NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *todayComp =
	[gregorian components:(NSHourCalendarUnit)
				 fromDate:tdate];
    int h = [todayComp hour];

    todayComp =
    [gregorian components:(NSMinuteCalendarUnit)
				 fromDate:tdate];
    int m = [todayComp minute];

    todayComp =
    [gregorian components:(NSSecondCalendarUnit)
				 fromDate:tdate];
    int s = [todayComp second];
    
    if (h >= 22) {
        t += 60-s+(59-m)*60+(23-h+8)*3600;
    }else if (h < 8){
        t += 60-s+(59-m)*60+(7-h)*3600;
    }
    
	[gregorian release];
    
    return t;
}

void OBJCHelper::livesRefillNote()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    if (manager->getNextLifeTime() <= manager->getCurrentTime()) {
        return;
    }
    if (manager->getLifeNum() >= manager->getMaxLife()) {
        return;
    }
    int t = manager->getRemainTime(manager->getNextLifeTime());
    t += kRecoverTime * (manager->getMaxLife() - manager->getLifeNum() -1);
    
    int unlimitlifetime = manager->getUnlimitLifeTime() - manager->getCurrentTime();
    if (unlimitlifetime >= t) {
        return;
    }
    
    t = get8DifWithTimeSinceNow(t);
    
    
    [[SnsServerHelper helper] scheduleLocalNotificationWithBody:[SystemUtils getLocalizedString:@"lives_refilled"] andAction:NULL andSound:NULL andInfo:NULL atTime:[NSDate dateWithTimeIntervalSinceNow:t]];
}
void OBJCHelper::freeSpinNote()
{
    if (!showMinigame()) {
        return;
    }
//    NSString * timestr = [NSString stringWithFormat:@"%04d-%02d-%02d 00:00",[SystemUtils getCurrentYear], [SystemUtils getCurrentMonth], [SystemUtils getCurrentDay]+1];
    int h = [SystemUtils getCurrentHour];
    int m = [SystemUtils getCurrentMinute];
    int s = [SystemUtils getCurrentSecond];
    
    int t = 60-s+(59-m)*60+(23-h)*3600;
//    NSDate * date = [StringUtils convertStringToDate:timestr];
    
    t = get8DifWithTimeSinceNow(t);

    [[SnsServerHelper helper] scheduleLocalNotificationWithBody:[SystemUtils getLocalizedString:@"daily_bonus"] andAction:NULL andSound:NULL andInfo:NULL atTime:[NSDate dateWithTimeIntervalSinceNow:t]];

}


void OBJCHelper::publicFBPassLevel(const char * level, const char * score)
{
    NSString * description = [NSString stringWithFormat:@"Completed level %s with a score of %s!",level, score];
    NSString * name =[NSString stringWithFormat:@"Level Completed"];
    NSString * caption = [NSString stringWithFormat:@"Jelly Mania"];
    NSString * link = @"https://apps.facebook.com/jellymania";
    NSString * picture = [SystemUtils getSystemInfo:@"kFacebookRequestLink"];
    picture = [picture stringByAppendingString:@"swf/feedjellys/jelly1.png"];
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:description,@"description",name,@"name",caption,@"caption",link,@"link",picture,@"picture", nil];
//    [[FacebookHelper helper] publishCustomizedFeed:dic];
    
    [FBWebDialogs presentFeedDialogModallyWithSession:[FBSession activeSession] parameters:dic handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
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
        }
    }];
}
void OBJCHelper::publicFBDailyBonus(CCArray * tdic)
{
#ifdef BRANCH_CN
    CCSize size = CCDirector::sharedDirector()->getWinSize();
    CCRenderTexture *screen = CCRenderTexture::create(size.width, size.height);
    CCScene *scene = CCDirector::sharedDirector()->getRunningScene();
    screen->begin();
    scene->visit();
    screen->end();
    if (!screen->saveToFile("wxShare.jpg", kCCImageFormatJPEG)) {
        return;
    }
    std::string picPath = CCFileUtils::sharedFileUtils()->getWriteablePath() + "wxShare.jpg";
    WeixinHelper * helper = [WeixinHelper helper];
    NSString * pic = [NSString stringWithCString:picPath.c_str() encoding:[NSString defaultCStringEncoding]];
    [helper publishCustomerFeed:pic];
#else
    if (!SNSFunction_isFacebookConnected()) {
        this->connectToFacebook(NULL);
        return;
    }
    FMDataManager * manager = FMDataManager::sharedManager();
    int type = ((CCNumber *)tdic->objectAtIndex(0))->getIntValue();
    int amount = ((CCNumber *)tdic->objectAtIndex(1))->getIntValue();
    const char * nstr = manager->getLocalizedString(CCString::createWithFormat("V100_BOOSTER_%d",type)->getCString());
    NSString * description = [NSString stringWithFormat:@"%@ got %s x%d from Jelly Mania Daily Bonus!",[NSString stringWithUTF8String:SNSFunction_getFacebookUsername()], nstr, amount];
    if (type == kBooster_UnlimitLife) {
        description = [NSString stringWithFormat:@"%@ got %d hours %s from Jelly Mania Daily Bonus!",[NSString stringWithUTF8String:SNSFunction_getFacebookUsername()], amount, nstr];
    }
    NSString * name =[NSString stringWithFormat:@"Jelly Mania Daily Bonus!"];
    NSString * caption = [NSString stringWithFormat:@"Jelly Mania"];
    NSString * link = @"https://apps.facebook.com/jellymania";
    NSString * picture = [SystemUtils getSystemInfo:@"kFacebookRequestLink"];
    if (type == kBooster_UnlimitLife) {
        picture = [picture stringByAppendingString:@"swf/feedjellys/ios2/unlimitlife.jpg"];
    }else{
        picture = [picture stringByAppendingFormat:@"swf/feedjellys/ios2/bonus%d.jpg",type];
    }
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:description,@"description",name,@"name",caption,@"caption",link,@"link",picture,@"picture", nil];
//    [[FacebookHelper helper] publishCustomizedFeed:dic];
    
    [FBWebDialogs presentFeedDialogModallyWithSession:[FBSession activeSession] parameters:dic handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
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
        }
    }];

#endif
}

void OBJCHelper::requestIOMContent()
{
    [[iOmniataHelper helper] requestContent];
}

bool OBJCHelper::isFrdMsgEnable(const char* fid, int type)
{
#ifdef SNS_DISABLE_DAILYCHECKIN
    return true;
#endif
    int t = [[OBJCHelperRequest request] getSendMsgInterval:fid :type];
    if (getCurrentTime() >= t) {
        return true;
    }
    return false;
}

void OBJCHelper::trackLoginSuccess()
{
#ifdef SNS_ENABLE_MINICLIP
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] initWithCapacity:3];
    if (SNSFunction_isFacebookConnected()) {
        [dic setObject:@"Facebook" forKey:@"login_type"];
    }else{
        [dic setObject:@"Guest" forKey:@"login_type"];
    }
    FMDataManager * manager = FMDataManager::sharedManager();
    [dic setObject:[NSNumber numberWithInt:manager->getGoldNum()] forKey:@"coins"];
    [dic setObject:[NSNumber numberWithInt:manager->getLifeNum()] forKey:@"lifes"];
    [[iOmniataHelper helper] trackEvent:[NSDictionary dictionaryWithObjectsAndKeys:dic, @"value", @"om_load", @"key", nil]];
    [dic release];
    
    
    dic = [[NSMutableDictionary alloc] initWithCapacity:1];
    [dic setObject:[NSNumber numberWithBool:[SystemUtils isJailbreak]] forKey:@"jailbreak"];
    [[iOmniataHelper helper] trackEvent:[NSDictionary dictionaryWithObjectsAndKeys:dic, @"value", @"mc_info", @"key", nil]];
    [dic release];
    
#endif
}
void OBJCHelper::trackPurchase(const char* str, double price, const char* code)
{
#ifdef SNS_ENABLE_MINICLIP
    [FiksuTrackingManager uploadPurchaseEvent:@"" price:price currency:[NSString stringWithUTF8String:code]];
    FMDataManager * manager = FMDataManager::sharedManager();

    NSString * idstr = [NSString stringWithUTF8String:str];
    NSArray * l = [idstr componentsSeparatedByString:@"."];
    if (l.count > 0) {
        NSString * id_ = [l objectAtIndex:l.count-1];
        NSMutableDictionary * dic = [[NSMutableDictionary alloc] initWithCapacity:5];
        [dic setObject:id_  forKey:@"product_id"];
        [dic setObject:[NSNumber numberWithDouble:price] forKey:@"total"];
        [dic setObject:[NSString stringWithUTF8String:code] forKey:@"currency_code"];
        [dic setObject:[NSNumber numberWithInt:manager->getGoldNum()] forKey:@"coins"];
        [dic setObject:[NSNumber numberWithInt:manager->getLifeNum()] forKey:@"lifes"];
        [[iOmniataHelper helper] trackPurchaseEvent:price currency_code:[NSString stringWithUTF8String:code] additional_params:dic];
        [dic release];
    }
#endif
}
void OBJCHelper::trackLoginFb(const char* gender, const char* dob)
{
#ifdef SNS_ENABLE_MINICLIP

    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:gender],@"gender",[NSString stringWithUTF8String:dob],@"dob", nil];
    [[iOmniataHelper helper] trackEvent:[NSDictionary dictionaryWithObjectsAndKeys:dic,@"value",@"om_user",@"key", nil]];
#endif
}
void OBJCHelper::trackLevelFinish(const char* level, bool complete)
{
#ifdef SNS_ENABLE_MINICLIP

    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:level],@"level",[NSNumber numberWithBool:complete],@"completed", nil];
    [[iOmniataHelper helper] trackEvent:[NSDictionary dictionaryWithObjectsAndKeys:dic,@"value",@"mc_played_level",@"key", nil]];
#endif
}
void OBJCHelper::trackBuyBooster(const char* name, int cost)
{
#ifdef SNS_ENABLE_MINICLIP
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:name],@"product",[NSNumber numberWithInt:cost],@"coins", nil];
    [[iOmniataHelper helper] trackEvent:[NSDictionary dictionaryWithObjectsAndKeys:dic,@"value",@"mc_soft_purchase",@"key", nil]];
#endif
}
void OBJCHelper::trackTutorial(int step)
{
#ifdef SNS_ENABLE_MINICLIP
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:step],@"step", nil];
    [[iOmniataHelper helper] trackEvent:[NSDictionary dictionaryWithObjectsAndKeys:dic,@"value",@"mc_tutorial",@"key", nil]];
#endif
}
void OBJCHelper::trackLevelUp(int level)
{
#ifdef BRANCH_TH
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] initWithDictionary:[[OBJCHelperWrapper wrapper] getBIUniversalDic]];
    [dic setObject:[NSNumber numberWithInt:level] forKey:@"from_level"];
    [dic setObject:@"levelup" forKey:@"event"];
    [[OBJCHelperWrapper wrapper] postToBI:dic];
    [dic release];
#endif
}

bool OBJCHelper::showMinigame()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    if (manager->getGlobalIndex(manager->getFurthestWorld(), manager->getFurthestLevel()) < 7) {
        return false;
    }
#ifdef SNS_ENABLE_MINICLIP
    if ([SystemUtils getNSDefaultObject:@"showMiniGame"]) {
        return [[SystemUtils getNSDefaultObject:@"showMiniGame"] boolValue];
    }
    else
        return false;
#endif
    return true;
}

void OBJCHelper::trackRegistration()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    if (manager->getSaveExp() == 0) {
        manager->addSaveExp();
        saveGame();
    }else{
        return;
    }
#ifdef SNS_ENABLE_MINICLIP
//    [FiksuTrackingManager uploadRegistrationEvent:@""];
#endif
#ifdef BRANCH_TH
    NSString * uid = [NSString stringWithUTF8String:getUID()];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:uid forKey:@"userid"]; //将引号中的{{userid}}替换为用户在游戏中的唯一id
    [Adjust trackEvent:@"o46qtx" withParameters:parameters];
    
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] initWithDictionary:[[OBJCHelperWrapper wrapper] getBIUniversalDic]];
    [dic setObject:@"newuser" forKey:@"event"];
    [[OBJCHelperWrapper wrapper] postToBI:dic];
    [dic release];
#endif
}

void OBJCHelper::trackSessionStart()
{
    m_startTime = getCurrentTime();
#ifdef BRANCH_TH
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] initWithDictionary:[[OBJCHelperWrapper wrapper] getBIUniversalDic]];
    [dic setObject:@"session_start" forKey:@"event"];
    [[OBJCHelperWrapper wrapper] postToBI:dic];
    [dic release];
#endif

}
void OBJCHelper::trackSessionEnd()
{
    int duration = getCurrentTime() - m_startTime;
#ifdef BRANCH_TH
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] initWithDictionary:[[OBJCHelperWrapper wrapper] getBIUniversalDic]];
    [dic setObject:@"session_end" forKey:@"event"];
    [dic setObject:[NSNumber numberWithInt:duration] forKey:@"duration"];
    [[OBJCHelperWrapper wrapper] postToBI:dic];
    [dic release];
#endif

}
void OBJCHelper::trackBIPurchase(const char* amount, const char* pid, int gameAmount, const char* tid, const char* code)
{
#ifdef BRANCH_TH
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] initWithDictionary:[[OBJCHelperWrapper wrapper] getBIUniversalDic]];

    NSString * amountstr = [NSString stringWithUTF8String:amount];
    amountstr = [amountstr stringByReplacingOccurrencesOfString:@"." withString:@""];
    int amountint = [amountstr intValue];
    [dic setObject:[NSNumber numberWithInt:amountint] forKey:@"amount"];
    
    [dic setObject:[NSString stringWithUTF8String:code] forKey:@"currency"];

    NSString * pidstr = [NSString stringWithUTF8String:pid];
    [dic setObject:pidstr forKey:@"product_id"];

    NSArray * pa = [pidstr componentsSeparatedByString:@"."];
    if (pa.count > 0) {
        NSString * id_ = [pa objectAtIndex:pa.count-1];
        [dic setObject:id_ forKey:@"product_name"];
    }

    [dic setObject:@"rc" forKey:@"product_type"];

    [dic setObject:[NSNumber numberWithInt:gameAmount] forKey:@"gameamount"];

    [dic setObject:[NSString stringWithUTF8String:tid] forKey:@"transaction_id"];

    [dic setObject:@"appleiap" forKey:@"payment_processor"];

    [dic setObject:@"payment" forKey:@"event"];

    [[OBJCHelperWrapper wrapper] postToBI:dic];
    [dic release];
#endif
}

double OBJCHelper::convertStringDateTo1970Sec(const char* timeStr)
{
   return [[StringUtils convertStringToDate:[NSString stringWithUTF8String:timeStr]] timeIntervalSince1970];
}

CCDictionary* OBJCHelper::converJsonStrToCCDic(const char* str)
{
    if (!str) return NULL;
    NSDictionary *ocDic = [StringUtils convertJSONStringToObject:[NSString stringWithUTF8String:str]];
    if (!ocDic || ![ocDic isKindOfClass:[NSDictionary class]]) return NULL;
    CCDictionary* ret = CCDictionary::create();
    NSArray* allKeys = [ocDic allKeys];
    int keyCount = [allKeys count];
    if (keyCount < 1) return NULL;
    for (int i = 0; i < keyCount; ++i) {
        NSString* key = [allKeys objectAtIndex:i];
        NSString* value = [ocDic objectForKey:key];
        ret->setObject(CCString::create([value UTF8String]), [key UTF8String]);
    }
    
    return ret;
}

void OBJCHelper::showWeb(const char* urlstring)
{
    kakaoPoliceViewController * vctrl = [[kakaoPoliceViewController alloc] initWithNibName:Nil bundle:Nil];
    UIViewController *root = [SystemUtils getAbsoluteRootViewController];
    [root presentModalViewController:vctrl animated:NO];
    [vctrl showWithURL:[NSString stringWithUTF8String:urlstring]];
    [vctrl release];

}

const char* OBJCHelper::getDeviceType()
{
    return [[SystemUtils getDeviceType] UTF8String];
}

const char* OBJCHelper::getSysVersion()
{
    return [[SystemUtils getiOSVersion] UTF8String];
}

const char* OBJCHelper::getClientVersion()
{
    return [[SystemUtils getClientVersion] UTF8String];
}

bool OBJCHelper::canShowMiniclipPopup()
{
    NSString * version = [SystemUtils getClientVersion];
    NSString * lastVersion = [SystemUtils getNSDefaultObject:@"kMiniclipPopVersion"];
    if (!lastVersion || ![lastVersion isEqualToString:version]) {
        [SystemUtils setNSDefaultObject:version forKey:@"kMiniclipPopVersion"];
        
        int time = getCurrentTime();
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:time] forKey:@"kMiniclipUpdateTime"];
        
        return false;
    }
    
    int t = [[SystemUtils getNSDefaultObject:@"kMiniclipUpdateTime"] intValue];
    if (getCurrentTime() - t > 3600 * 5) {
        return true;
    }
    
    return false;
}

