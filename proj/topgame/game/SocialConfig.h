//
//  socialConfig.h
//
//  Created by yang jie on 16/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//
#import "SystemUtils.h"

#define kSmRequestAddress [SystemUtils getSocialServerRoot]
#define kSmServerAddress [NSString stringWithFormat:@"http://%@/", [SystemUtils getServerName]]

//用户信息刷新通知
#define kIfProfileNeedRefurbish @"kIfProfileNeedRefurbish"

//社交模块加载数据，需要游戏切换到当前用户游戏
#define kIfGameNeedChangeUser @"kIfGameNeedChangeUser"
//社交模块是否可以显示（来自服务器端判断）
#define kSocialModuleCanBeOpened @"kSocialModuleCanBeOpened"
//主模块旋转通知Key
#define kMainModuleOrientation @"kMainModuleOrientation"
//主模块关闭通知key
#define kSmMainModuleNeedClose @"kSmMainModuleNeedClose"
//通知主模块切换到相应view的key
#define kSmMainModuleChangeView @"kSmMainModuleChangeView"

/*
 社交模块相关参数设置
 */
//所有读取多条数据的条数限制（最多取多少条）
#define kSmMaxLoadNumber 50
//用户每天可以送出的礼物数量,0为随便送
#define kSmCanSendGiftCount 3
//社交模块边框宽度
#define kPadding 10

//gift读取结束之后更新button统计数的key
#define kSmGiftLoadSuccess @"kSmGiftLoadSuccess"
//当送礼数到达今日极限的时候发送通知修改gift的视图
#define kSmGiftViewNeedReload @"kSmGiftViewNeedReload"
//成功取得今天可以送出的gift之后的发送消息的key
#define kTodayCanSendGiftLoadSuccess @"kTodayCanSendGiftLoadSuccess"

//通知主模块需要保存存档
#define kSocialModuleSaveData @"kSocialModuleSaveData"
//通知主模块需要读取存档
#define kSocialModuleLoadData @"kSocialModuleLoadData"
//用户数据接口每日执行userdefault的Key
#define kSocialModuleLastUserDataIndex @"kSocialModuleLastUserDataIndex"
//用户数据接口存档userdefault的key
#define kSocialModuleUserData @"kSocialModuleUserData"

//每日执行过的数据记录key
#define kSocialModuleDate @"kSocialModuleDate"

//通知弹出窗口关闭自己的键盘
#define kSocialModuleKeyBoardNeedClose @"kSocialModuleKeyBoardNeedClose"

//系统信息各种key
#define kDeviceIDKey   @"_deviceID"
#define kDeviceTypeKey @"_deviceType"
#define kDeviceModeKey @"_deviceMode"
#define kCurrentLanguageKey  @"_currentLanguage"
#define kCountryCodeKey      @"_countryCode"
#define kDeviceTokenKey @"_deviceToken"
#define kDocumentRootPath @"_kDocumentRootPath"
#define kServerRootPath @"_kServerRootPath"
#define kAppBundlePath  @"kAppBundlePath"

//facebook setting
#define kUserDefaultID_useFacebook @"smUserFacebookId"
#define kUserDataFetchedNotification @"kUserDataFetchedNotification"
#define kUserDataFetchingNotification @"kUserDataFetchingNotification"
 
// #define kAppId @"236552053032266"
// #define PublishURI @"http://www.topgame.com/"

#define ACCESS_TOKEN_KEY @"fb_access_token"
#define EXPIRATION_DATE_KEY @"fb_expiration_date"

#define kNetConnectivityUpdatedNotification @"kNetConnectivityUpdatedNotification"
#define kNetConnectivityResultDetermined @"kNetConnectivityResultDetermined"
#define kPhotoPermissionApproved @"kPhotoPermissionApproved"

//CameCenter setting
#define gcAutoAuthentication NO
#define kAchievmentQueue @"kAchievmentQueue"
#define kAchievementQueueNotification @"kAchievementQueueNotification"
#define gcAchievementQueuePlistPath @"achievmentQueue.plist"

//public
/*
#define WINDOW_SIZE [[CCDirector sharedDirector]winSize]
#define WINDOW_WIDTH ([[CCDirector sharedDirector]winSize]).width
#define WINDOW_HEIGHT ([[CCDirector sharedDirector]winSize]).height
 */
#define WINDOW_SIZE [UIScreen mainScreen].bounds.size
#define WINDOW_WIDTH [UIScreen mainScreen].bounds.size.width
#define WINDOW_HEIGHT [UIScreen mainScreen].bounds.size.height

//各个地方用的枚举
typedef enum {
	MainViewTypeINVALID = 0,
	MainViewTypeFriend,
	MainViewTypeGift,
	MainViewTypeInvite,
	MainViewTypeMission,
	MainViewTypeProfile,
} MainViewType;

typedef enum {
	GenderTypeINVALID = 0,
	GenderTypeMale,
	GenderTypeFemale,
} GenderType;

typedef enum {
	LoadTypeINVALID = 0,
	LoadTypeRamble,
	LoadTypeFriendTopgame,
	LoadTypeFriendFacebook,
	LoadTypeFriendGamecenter,
	LoadTypeTopList,
} LoadType;

typedef enum {
	ShowTypeINVALID = 0,
	ShowTypePersent,
	ShowTypePersentUp,
	ShowTypeHard,
	ShowTypePopo,
} ShowType;

//重写NSLog
#ifdef DEBUG
# define smLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
# define smLog(...);
#endif
