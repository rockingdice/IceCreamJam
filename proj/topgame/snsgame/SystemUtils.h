//
//  SystemUtils.h
//  ZombieFarm
//
//  Created by LEON on 11-6-18.
//  Copyright 2011 playforge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameDataDelegate.h"
#import "SNSLogType.h"

#ifndef SNSLog
#ifdef DEBUG
#define SNSLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define SNSLog(...)
#endif
#endif

#ifndef SNSCrashLog
#define SNSCrashLog(fmt, ...) [SystemUtils addCrashLog:[NSString stringWithFormat:(@"%s [Line %d] trace:%@ " fmt), __PRETTY_FUNCTION__, __LINE__, [SystemUtils getStackTraceInfo], ##__VA_ARGS__]]

#endif

#ifndef SNSLocalizeString
#define SNSLocalizeString(key,comment) [SystemUtils getLocalizedString:key]
#endif

#ifndef SNSReleaseObj
#define SNSReleaseObj(obj)   {[obj release]; obj = nil;}
#endif

typedef enum {
	kFeatureNone,
	kFeatureTapjoy,
	kFeatureFlurry,
	kFeatureShowAd,
	kFeatureAdColony,
	kFeatureChartBoost,
    kFeatureAdMob,
    kFeatureGreystripe,
    kFeatureLiMei,
    kFeatureKiip,
    kFeatureTinyMobi,
    kFeatureAppDriver,
} kFeatureType;

enum {
    kFeedTextNone,
    kFeedTextInviteFriend,
    kFeedTextSharePicture,
    kFeedTextShowUID,
};

@interface NSNull (SNSTypeConversion)

- (int) intValue;
- (float) floatValue;
- (double) doubleValue;
@end

@interface SystemUtils : NSObject {

}

#pragma mark static variable initialize
// 全局配置，从服务器下载
+ (NSMutableDictionary *)config;
// 系统信息，不可修改
+ (NSMutableDictionary *)systemInfo;
// 配置文件的验证码信息
+ (NSMutableDictionary *)playerSetting;

// appDelegate
+ (void)setAppDelegate:(id)delegate;
+ (id)getAppDelegate;
+ (BOOL) isAppAlreadyTerminated;

// 获取系统信息
+(id)getSystemInfo:(NSString *)key;


// clearUp system info
+ (void)cleanUpStaticInfo;

// save config
+ (void) saveGlobalSetting;

// 设置游戏存档对象，在存档对象有变化时要重新设置
+ (void)setGameDataDelegate:(NSObject<GameDataDelegate>*)obj;
// 获得游戏存档对象
+ (NSObject<GameDataDelegate> *)getGameDataDelegate;

#pragma mark -



#pragma mark device property
// return iPhone, iPod, iPad
+ (NSString*)getDeviceType;

// check if this device is iPad
+ (BOOL)isiPad;

// check if is retina
+ (BOOL) isRetina;
// check if is iPhone5
+ (BOOL) isiPhone5Screen;

// model type
+ (NSString *)getDeviceModel;

// iOS version
+ (NSString *) getiOSVersion;

// install time
+ (int) getInstallTime;

// UDID
+ (NSString *)getDeviceID;
// MacAddr
+ (NSString*)getMACAddress;
// 不带前缀的
+ (NSString*)getOriginalMACAddress;
// idfa
+(NSString *)getIDFA;
// idfv
+(NSString *)getIDFV;

// get language: zh-Hans, zh-Hant
+ (NSString *)getCurrentLanguage;

// get country code: CN, TW, HK, US
+ (NSString *)getCountryCode;
// get original country code
+ (NSString *)getOriginalCountryCode;
// get device name
+ (NSString *)getDeviceName;

// set device Token
+ (void)setDeviceToken:(NSString *)token;
// get device token
+ (NSString *)getDeviceToken;
// get device info
+ (NSDictionary *)getDeviceInfo;

+ (void) saveDeviceTimeCheckPoint:(BOOL)reset;
// get current timestamp
+ (int)getCurrentTime;
// 矫正当前时间
+ (void) correctCurrentTime;

//get current Millisecond
+ (double)getCurrentMillisecond;
// get current device time
+ (int)getCurrentDeviceTime;
// set current server time
+ (void)setServerTime:(int)time;
//增加设备时间
+ (void)addDeviceTime:(int)time;
//得到当前时间
+ (int) getCurrentYear;
+ (int) getCurrentMonth;
+ (int) getCurrentDay;
+ (int) getCurrentHour;
+ (int) getCurrentMinute;
+ (int) getCurrentSecond;



// get client version
+ (NSString *)getClientVersion;
+ (NSString *)getBundleVersion;
// get version info
+ (NSString *)getVersionInfo;

// check if gamecenter enabled
+(BOOL)isGameCenterAPIAvailable;

// check if network required
+ (BOOL) isNetworkRequired;

// 获取游戏的屏幕横竖设置
+ (UIDeviceOrientation) getGameOrientation;

#pragma mark -

#pragma mark file path

// get document path
+ (NSString *)getDocumentRootPath;
// upgrade path
+ (void) relocateCachePath;
// get cache path
+ (NSString *)getCacheRootPath;
// Library/Cache
+ (NSString *) getLibraryCacheImagePath;

// get cache image path
+ (NSString *)getCacheImagePath;
// get save path
+ (NSString *)getSaveRootPath;
// get item file path
+ (NSString *)getItemRootPath;
// get item image path
+ (NSString *)getItemImagePath;
// get notice image path
+ (NSString *)getNoticeImagePath;
// get notice image file, return xxx@2x.png file for retina
+ (NSString *)getNoticeImageFile:(int)noticeID withVer:(int)ver;
// get new format notice image file, with country code
+ (NSString *)getNoticeImageFile:(int)noticeID withVer:(int)ver andCountry:(NSString *)country;
// 读取远程进度为一个Array
+ (NSArray *) readRemoteConfigAsArray:(NSString *)file;

// 下载某个远程道具的资源文件
// info里必须包含3个字段，都是NSString类型：ID-道具ID，File－资源文件名，Ver－版本号
// 返回值含义：0－排入下载队列；1－文件最新版已经存在，不需要下载；－1－无效参数，不能下载
+ (int) loadRemoteItemAsset:(NSDictionary *)info;

// 检查远程道具文件是否已经下载过了
+ (BOOL) isRemoteFileExist:(NSString *)fileName withVer:(int)ver;
// + (NSString *) getRemoteConfigFile:(NSString *) fileName;
// 设置iCloud不备份的状态
+ (void) setNoBackupPath:(NSString *)path;

#pragma mark -

#pragma mark global setting

// set global setting
+ (void)setGlobalSettingByDictionary:(NSDictionary *)info;
// get global setting
+ (id)getGlobalSetting:(id)key;
// set global setting with key
+ (void)setGlobalSetting:(id)val forKey:(id)key;
// remove global setting
+ (void) removeGlocalSettingForKey:(id)key;

// get language info
+ (NSString *)getLocalizedString:(NSString *)key;
// set language info
+ (void) setLanguageInfo:(NSDictionary *)info;

// check language file
+ (BOOL) isLanguageFileExist;

+ (void) setNSDefaultObject:(id)obj forKey:(NSString *)key;
+ (id) getNSDefaultObject:(NSString *)key;

#pragma mark -

#pragma mark utility
// update file digest
+ (BOOL) updateFileDigest:(NSString *)file;
// verify file digest
+ (BOOL) checkFileDigest:(NSString *)file;
// verify config file digest
+ (BOOL) checkConfigFileDigest:(NSString *)file;
// 更新存档文件签名
+ (void) updateSaveDataHash:(NSString *)saveData;
// 检查存档文件签名
+ (BOOL) checkSaveDataHash:(NSString *)saveData;

// unzip files to a path
+ (BOOL) unzipFile:(NSString *)zipFile toPath:(NSString *)path;
// 获取指定时间是周几，1－周日，2－周一，7－周六
+ (int) getWeekDayOfTime:(int)time;
// 获取当前是周几，1－周日，2－周一，7－周六
+ (int) getCurrentWeekDay;
// 获取今天日期，110731
+(int)getTodayDate;
// 获得某天的前一天日期
+ (int) getPrevDay:(int)date;
/*获得当前周是1年中得第几周，周1为第一天，如果1月1日是周日算为上年得最后周，1月2日为这年得第1周*/
+(int)getWeekIndexInYear;
+(int)getWeekIndexInYear:(int)time;
+(int)getWeekIndexInYear:(int)year month:(int)month day:(int)day;

// 
// 某些旧设备上没有一些常用字体，用此函数来集中判断和替换
// 3.1.2平台上没有 Arial Bold
+ (NSString *) getSupportFont:(NSString *)font;

// 避开睡眠时间
+ (NSDate *)delayDateToAvoidSleepHour:(NSDate *)date;

// 给客服发邮件
+ (void) writeEmailToSupport;

// 从文件中读取JSON字符串并转换为NSObject
+ (id) readJsonObjectFromFile:(NSString *)file;

// 获得一个随机整数
+ (int) getRandomNumber:(int)max;

// 执行一个窗口命令
+ (void) runCommand:(NSString *)cmd;

// 显示Loading界面
+ (void) showLoadingScreen;
// 设置Loading文字
+ (void) setLoadingScreenText:(NSString *)info;
// 关闭Loading界面
+ (void) hideLoadingScreen;

// 显示游戏内Loading界面
+ (void) showInGameLoadingView;
// 关闭游戏内Loading界面
+ (void) hideInGameLoadingView;
// 显示弹出窗口
+ (void) showPopupView:(UIViewController *)vc;
// 关闭弹出窗口
+ (void) closePopupView:(UIViewController *)vc;


// 解析多语言内容，返回当前设备语言对应的内容
+ (NSString *)parseMultiLangStrForCurrentLang:(NSString *)mesg;

+ (void) pauseDirector;
+ (void) resumeDirector;

// 对于iOS6直接在应用内打开appstore
+ (void) openAppLink:(NSString *)link;

// 获取Feed文字内容，多条记录由三条竖线 ||| 分割
// kFeedTextInviteFriend: 邀请指定好友的文字
// kFeedTextSharePicture: 画完一幅画后分享文字
// kFeedTextShowUID: 公布自己UID的feed文字
+ (NSString *)getRemoteFeedText:(int) feedType;

// 让设备震动
+ (void) playVibrate;

// 给好友发送邀请链接
+ (void) shareAppLink;

#pragma mark -

#pragma mark config files

// 检查所有的配置文件是否有效
+ (BOOL) verifyAllConfigFiles;
// 检查下载配置文件是否有效
+ (BOOL) verifyAllLoadedConfigFiles;
// 检查远程配置文件的版本号，如果本地目前配置文件版本号与SystemConfig.plist中的kRemoteConfigVersion不同，
// 就会清除所有远程配置文件并重新下载；如果这时kRemoteConfigCleanAssets＝1，就会同时清除图片文件目录。
+ (void) checkRemoteConfigVersion;

// 获取下载配置文件列表
+ (NSArray *) getLoadedConfigFileNames;


#pragma mark -

#pragma mark remote server

// get topgame service root
+ (NSString *) getTopgameServiceRoot;
// get server name
+ (NSString *) getServerName;
// get download server name
+ (NSString *) getDownloadServerName;
// get feed image server name
+ (NSString *) getFeedImageServerName;
// get feed image link
+ (NSString *) getFeedImageLink:(NSString *)fileName;
// get server Root
+ (NSString *) getServerRoot;
// get social server Root
+ (NSString *) getSocialServerRoot;
// get download link
+ (NSString *)getAppDownloadLink;
// get download link
+ (NSString *)getAppDownloadShortLink;
// get rate link
+ (NSString *)getAppRateLink;

// get flurry reward server name
+ (NSString *)getFlurryRewardServerName;
// get top click server name
+ (NSString *)getTopClickServerName;

// get facebook appID
+ (NSString *)getFacebookAppID;
// get weibo appID
+ (NSString *)getWeiboAppID;


#pragma mark -

#pragma mark user profile
// 获取当前UID
+ (NSString *)getCurrentUID;
// 设置当前UID
+ (void) setCurrentUID:(NSString *)uid;

// 获取当前userID, 不建议使用，请改用 getCurrentUID
+ (int)getCurrentUserID __attribute__ ((deprecated));
// 设置当前userID，不建议使用，请改用 setCurrentUID
+ (void) setCurrentUserID:(int) userID __attribute__ ((deprecated));
// sessionKey
+ (NSString *)getSessionKey;
// clear sessionKey
+ (void) clearSessionKey;

// get current save id
+ (int) getSaveID;
// set current save id
+ (void) setSaveID:(int)newID;
// get save file path
+ (NSString *)getUserSaveFile;
// 获取指定用户的存档文件路径
+ (NSString *)getUserSaveFileByUID:(NSString *)uid;
// 获取指定用户的存档文件路径，不建议使用，请改用 getUserSaveFileByUID
+ (NSString *)getUserSaveFileByID:(int)uid __attribute__ ((deprecated));
// check if user file exists
+ (BOOL) isSaveFileExists;

// 增加好友
+ (void) addFriend:(NSDictionary *)info;
// 获得好友列表
+ (NSArray *) getFriends;

// 获取用户设置
+(id) getPlayerDefaultSetting:(id)key;
// 存储用户设置
+(void) setPlayerDefaultSetting:(id)val forKey:(id)key;
+(void) setPlayerDefaultSetting:(id)val forKey:(id)key saveToFile:(BOOL)save;
// 删除用户设置
+(void) removePlayerSetting:(id)key saveToFile:(BOOL)save;
// 获取远程配置参数，如果没有，就取本地systemconfig.plist里的参数
+(id) getRemoteConfigValue:(NSString *)key;
// 发送邮件
// + (void) writeEmailTo:(NSString *)email withTitle:(NSString *)title andBody:(NSString *)body andAttachData:(NSData *)attachData withAttachFileName:(NSString *)attachFileName;

// 获取存档数据签名
+(NSString *) getHashOfSaveData:(NSString *)saveData;
// 从存档字符串里去掉签名
+(NSString *)stripHashFromSaveData:(NSString *)saveData;
// 给存档字符串加上签名
+(NSString *)addHashToSaveData:(NSString *)saveData;
// 从带签名的存档文件中读取数据字符串
+(NSString *)readHashedSaveData:(NSString *)file;

// 解析服务器存档格式
+(NSDictionary *)parseSaveDataFromServer:(NSString *)saveData;

// 验证存档信息是否有效
+ (BOOL) verifySaveDataWithHash:(NSString *)saveData;

#pragma mark -

#pragma mark notice and ad
// 获得当前公告版本号
+ (int) getNoticeVersion;

// check if some feature enabled
+ (BOOL) checkFeature:(kFeatureType)type;

// 是否付费版
+ (BOOL) isPaidVersion;

// 提示进行评分
+ (void) showReviewHint;
// 检查一个公告是否有效
+ (BOOL) isNoticeValid:(NSDictionary *)info;
// 检查一个现有公告是否有效，和isNoticeValid的区别是不检查公告版本号
+ (BOOL) isSavedNoticeValid:(NSDictionary *)noticeInfo;
// 获取当前公告的国家代码，如果当前公告不包含当前设备区域，将返回nil
+ (NSString *) getNoticeCountryCode:(NSString *)country;
// 显示游戏内公告
+ (void) showInGameNotice;
//显示连续登陆奖励
+ (void) showLoginDayNum;
+ (BOOL) showDailyBonusPopup;
// 获得连续登录次数
+ (int) getLoginDayCount;
// 重置连续登陆天数
+ (void) resetLoginDayCount;
// 显示IAP促销广告
+ (BOOL) showSpecialIapOffer:(NSString *)suffix;
// 检查是否是特价IAP，如果是，就返回增加的数额，否则返回0
+ (int) getSpecialIapBonusAmount:(NSString *)iapID withCount:(int)count;
// 发放GM礼物
+ (void) showGMPrize:(NSDictionary *)gmPrize;

// 显示游戏公告窗口
// {"mesg":"xxxx","mesgID":"localized key","action":"","prizeGold":"0","prizeLeaf":"0"}
+ (void)showCustomNotice:(NSDictionary *)info;
// 显示推荐广告
+ (void)showPopupOffer;
// 显示某个广告商的弹窗广告，如果显示成功返回YES，否则NO
+ (BOOL) showPopupOfferOfType:(NSString *)type;
// 显示FB Like窗口
+ (BOOL) showFacebookLikePopup;

// 是否有促销
+ (BOOL) isPromotionReady;
// 促销折扣, 0-不促销，2／4／6／8：多送20／40／60／80％
+ (int) getPromotionRate;
// 促销截至时间
+ (int) getPromotionEndTime;
// 促销开始时间
+ (int) getPromotionStartTime;
// 显示促销倒计时提示
+ (void) showPromoteNotice;
// 设置免打扰模式, YES－允许打扰，NO-不允许打扰
+ (void) setInterruptMode:(BOOL)canInterrupt;
// 获取免打扰模式, YES-可以弹窗，NO－不可以弹窗
+ (BOOL) getInterruptMode;

// 是否有新道具
+ (BOOL) isNewItemAvailable;

// 是否显示广告
+(BOOL)isAdVisible;
// 显示视频广告
+ (void) showFreeVideoOffer;
// 增加忽略广告的次数
+ (void) addIgnoreAdCount;
// 重置忽略广告次数
+ (void) resetIgnoreAdCount;
// 是否要忽略广告
+ (BOOL) shouldIgnoreAd;

// 获取金币奖励数量
// + (int) getFlurryGoldPrize;

// 获取Tapjoy累计分数
+(int)getTapjoyPoint;
// 存储Tapjoy累计分数
+(void)setTapjoyPoint:(int)point;

// 获取特价动物信息，如果没有就返回 nil
+(NSDictionary *)getSpecialOfferInfo;
// 获取特价动物结束时间
+(int) getSpecialOfferEndTime;


// 奖励用户资源, kGameResourceTypeCoin, kGameResourceTypeLeaf, kGameResourceTypeExp
+(void) addGameResource:(int)amount ofType:(int)type;
// IAP购买成功，给予奖励
+(void) addIapItem:(NSString *)itemName withCount:(int)count;
// 增加某个道具
+(void) addItem:(NSString *)itemID withCount:(int)count;

// 显示作弊警告
+(void)showHackAlert;

// 显示促销窗口
+(void) showPromotionNotice;
// 关闭公告窗口
+(void) closePromotionNotice;

// 获得新通知数量
+(int) getPromotionNoticeUnreadCount;
// 获得通知数量
+(int) getPromotionNoticeCount;
// 添加一个新通知
+(void) addPromotionNotice:(NSDictionary *)noticeInfo;

#pragma mark -

#pragma mark stats

// 从下载进度中恢复统计信息
+(void)checkGameStatInLoadData:(NSDictionary *)loadData;

+ (void) resetGameStats;
+ (void) initGameStats;

// 存储统计信息
+(void)saveGameStat;

// 累计资源变化，最终只形成一条记录，适用于零碎小额的资源变化，比如随机出现的气泡，点击后获得金币
+(void) addUpResource:(int)type method:(int)method count:(int) count;

// 记录特定资源变化，适用于大额变化，比如购买一头动物／消耗叶子加速建设
+(void)logResourceChange:(int)type method:(int)method itemID:(NSString *)itemID count:(int) count;

// 记录支付信息，单位是美分
+(void)logPaymentInfo:(int)cost withItem:(NSString *)iapID;
// 记录游戏时间
+(void)logPlayTimeStart;
+(void)logPlayTimeEnd;
// 记录道具购买记录
+(void)logItemBuy:(int)type withID:(NSString *)ID;
// 记录道具购买记录
+(void)logItemBuy:(int)type withID:(NSString *)ID cost:(int)cost resType:(int)resType;
// 记录升级记录
+(void)logLevelUp:(int)level;
// 记录玩小游戏的时间
+(void)logPlayMiniGame:(int)gameID forTime:(int)seconds;



// 记录IAP订单ID
+ (void) addIapTransactionID:(NSString *)tranID;
// 检查这个IAP订单是否已经存在了
+ (BOOL) isIapTransactionUsed:(NSString *)tranID;
// 获得打开游戏的次数
+ (int) getPlayTimes;
// 获得邀请成功的人数
+ (int) getInviteSuccessTimes;
// 显示邀请界面
+ (void) showInviteFriendsDialog;


#pragma mark -

#pragma mark CrashLog
// 开始崩溃日志
+ (void) startCrashLog;
// 结束崩溃日志
+ (void) endCrashLog;
// 发送崩溃日志
+ (void) sendCrashLog;
// 清除崩溃日志
+ (void) clearCrashLog;
// 记录崩溃日志
+ (void) addCrashLog:(NSString *)info;
// 返回崩溃日志内容
+ (NSString *) getCrashLogContent;
// 是否启用了崩溃日志
+ (BOOL) isCrashDetected;
// 处理全局Exception
+ (void) uncaughtExceptionHandler:(NSException *)exception;
// 获取Thread的Stack Trace
+ (NSArray *)getStackTraceInfo;
// 处理全局CPP Exception
+ (void) uncaughtCppExceptionInfo:(NSString *)reason;


#pragma mark -


#pragma mark report

// admob统计安装
+ (void)reportAppOpenToAdMob;

// MdotM安装报告
+ (void)reportAppOpenToMdotM;

// 实时付费统计
+ (void) reportIAPToServer:(NSDictionary *)info;

// playhaven安装统计
+ (void) reportAppOpenToPlayHaven;

// 安装统计
+ (void) reportInstallToServer;

// 显示发送邮件界面，界面中显示默认的标题、内容和附件，附件的文件名为attachFileName。
// 除了email外，其它参数都可以是nil，表示没有默认值。
// + (void) writeEmailTo:(NSString *)email withTitle:(NSString *)title andBody:(NSString *)body andAttachData:(NSData *)attachData withAttachFileName:(NSString *)attachFileName;


#pragma mark -


#pragma mark alert

// 提示被阻止
+(void) showBlockedAlert;

// 提示需要更新版本
+(void) showForceUpdateAlert;

// 提示需要网络
+(void)showNetworkRequired;
// 提示需要下载远程市场
+(void)showRemoteItemRequired;
// 显示购买成功提示
+(void)showPaymentNotice:(NSString *)mesg;
// 显示购买失败提示
+(void)showPaymentFailNotice:(NSString *)errorMesg;
// 提示重置存档完成
+(void)showResetGameDataFinished;
// 提示资源文件损坏
+(void)showConfigFileCorrupt;
// 提示需要下载远程进度
+(void)showReloadGameRequired;
// 提示语言包加载完成
+ (void) showLangUpdateHint;
// 崩溃检测提示
+ (void) showCrashDetectedHint;
// 显示无效支付提示
+(void) showInvalidTransactionAlert:(NSDictionary *)info;
// 帐号切换提示
+(void)showSwitchAccountHint;


// BUG修复提示
+ (void) showCrashBugFixed:(NSDictionary *)hintInfo;
//显示提示框
+(void)showSNSAlert:(NSString*)title message:(NSString*)message;
// 显示时加1
+(void) incAlertViewCount;
// 关闭时减1
+(void) decAlertViewCount;
// 检查目前是否有View
+(BOOL) doesAlertViewShow;

+(void) setUpMailAccountAlert;

#pragma mark -

//根据礼物ID获取到礼物信息
// +(NSMutableDictionary*)getGifInfo:(int)gifID;
+(void)openFriendSpace:(NSDictionary *)friendData error:(NSError *)error;
//返回rootViewController
+ (UIViewController *)getRootViewController;
+ (void) setRootViewController:(UIViewController *)controller;
// 返回绝对的rootViewController
+ (UIViewController *)getAbsoluteRootViewController;


// 是否启用growMobile
+(BOOL) isGrowMobileEnabled;

+(BOOL) isJailbreak;

@end


#define kStatusCheckSecret     @"de4334507234wewoyerw723"
#define kTapjoyAppIDKey        @"kTapjoyAppIDKey"
#define kTapjoyAppSecretKey    @"kTapjoyAppSecret"
#define kAppSalarAppIdKey      @"kAppSalarAppIdKey"
#define kAppSalarAppSecretKey  @"kAppSalarAppSecretKey"

#define kAdWhirlPublisherIDKey @"kAdWhirlPublisherIDKey"

#define kFlurryAppIdKey        @"kFlurryAppIdKey"
#define kFlurryAPIAccessCode   @"kFlurryAPIAccessCode"

#define kPlayHavenTrackCodeKey @"kPlayHavenTrackCodeKey"   
#define kAdMobTrackCodeKey     @"kAdMobTrackCodeKey"

#define kMdotMAppIDKey @"kMdotMAppIDKey"
#define kMdotMAdvIDKey @"kMdotMAdvIDKey"

#define kHackTime  @"hackTime"
#define kHackAlertTimes @"kHackAlertTimes"
#define kFollowReviewHint @"followReviewHint"

#define kFacebookFeedLink @"kFacebookFeedLink"
#define kAppStoreAppID    @"kAppStoreAppID"

#define kGameServerGlobal @"kGameServerGlobal"
#define kGameServerChina  @"kGameServerChina"
#define kImageServerGlobal @"kImageServerGlobal"
#define kImageServerChina  @"kImageServerChina"
#define kFeedImageServerGlobal   @"kFeedImageServerGlobal"
#define kFeedImageServerChina    @"kFeedImageServerChina"
#define kStatServerGlobal  @"kStatServerGlobal"
#define kStatServerChina   @"kStatServerChina"
#define kFlurryCallbackServer   @"kFlurryCallbackServer"

#define kGameCenterAuthenticationDoneNotification @"kGameCenterAuthenticationDoneNotification"

#define kStatusMessageCanceledNotification @"kStatusMessageCanceledNotification"
#define kStatusCheckDoneNotification @"kStatusCheckDoneNotification"

#define kLangFileVerKey   @"langVer"
#define kItemFileVerKey   @"itemVer"
#define kItemFileLocalVerKey   @"itemVerLocal"
#define kNoticeInfoVerKey @"noticeVer"
#define kSessionKeyID     @"sessionKey"
#define kLastUploadTimeKey  @"lastUploadTime"
#define kCurrentUserIDKey @"currentUserID"
#define kCurrentOnlineVersionKey @"kCurrentOnlineVersion"
#define kCurrentReviewVersionKey @"kCurrentReviewVersion"
#define kCurrentVersionDescKey   @"kCurrentVersionDesc"
#define kCurrentNewFeatureKey    @"kCurrentNewFeatureDesc"

#define kiTunesAppDownloadLink @"kiTunesAppDownloadLink"
#define kiTunesAppRateLink @"kiTunesAppRateLink"

#define kPromotionStartTime @"kPromotionStartTime"
#define kPromotionEndTime   @"kPromotionEndTime"
#define kPromotionRate      @"kPromotionRate"

#define kTapjoyPoint   @"kTapjoyPoint"
#define kTapjoyShowTime    @"kTapjoyShowTime"
#define kFlurryShowTime    @"kFlurryShowTime"

#define kLastBootTime      @"kLastBootTime"
#define kTotalPayment      @"kTotalPayment"
#define kDownloadItemRequired  @"kDownloadItemRequired"
#define kPlayTimes         @"kPlayTimes"

#define kTutorialLoaded    @"tutorialLoaded"
#define kTutorialShown     @"tutorialShown"

#define kFlurryHookName    @"kFlurryHookName"
#define kFlurryVideoHookName @"kFlurryVideoHookName"
#define kFlurryCallbackAppID @"kFlurryCallbackAppID"
#define kFlurryRewardsSigKey @"2342fsdfoyrowe"

#define kSpecialAnimalID  @"kSpecialAnimalID"
#define kSpecialStartTime @"kSpecialStartTime"
#define kSpecialEndTime   @"kSpecialEndTime"

#define kFlurryOfferMaxPrice @"kFlurryOfferMaxPrice"

#define kGameStats      @"kGameStats"
#define kTapjoyPendingActions @"kTapjoyPendingActions"
#define kiTunesAppID    @"kiTunesAppID"

#define kMinTimeDiff     -10000000
#define kMinServerTime   1012369200

#define kSupportEmail          @"kSupportEmail"
#define kSupportEmailTitle     @"kSupportEmailTitle"
#define kSupportEmailGreeting  @"kSupportEmailGreeting"
#define kSupportEmailSuffix    @"kSupportEmailSuffix"
#define kDisableLocalNotify    @"kDisableLocalNotify"
#define kInstallReport         @"kInstallReport"
#define kGameClientVer         @"kGameClientVer"

#define kTransactionList       @"kTransactionList"
#define kGameCenterNextTime    @"kGameCenterNextTime"

#define kAdColonyAppID         @"kAdColonyAppID"
#define kAdColonyZoneID        @"kAdColonyZoneID"

#define kLastUploadSaveID      @"kLastUploadSaveID"
#define kRemoteConfigFiles     @"kRemoteConfigFiles"
#define kRemoteConfigFileDict  @"kRemoteConfigFileDict"
#define kSaveFileRootKey       @"kSaveFileRootKey"

#define kGameOrientation       @"kGameOrientation"
#define kIapItemPrefix         @"kIapItemPrefix"
#define kCheckLostItemsTimes   @"playerHasLostItems"

#define kChartBoostAppID       @"kChartBoostAppID"
#define kChartBoostAppSig      @"kChartBoostAppSig"

#define kPlayHavenToken        @"kPlayHavenToken"
#define kPlayHavenSecret       @"kPlayHavenSecret"

#define kFAADNetworkKey        @"kFAADNetworkKey"
#define kFAADNetworkSecret     @"kFAADNetworkSecret"

#define kTinyiMailInfo         @"kTinyiMailInfo"
#define kTinyiMailPrizeLeaf    @"kTinyiMailPrizeLeaf"

#define kMinLevelToShowBonus   @"kMinLevelToShowBonus"

#define kClickedNoticeID       @"kClickedNoticeID"

// Notification
#define kNotificationRegisterSuccess       @"kNotificationRegisterSuccess"
#define kNotificationSyncUserInfo          @"kNotificationSyncUserInfo"
#define kNotificationGetFacebookFrds       @"kNotificationGetFacebookFrds"
#define kNotificationGetFacebookInviteFrds       @"kNotificationGetFacebookInviteFrds"
#define kNotificationGetFBToken            @"kNotificationGetFacebookToken"
#define kNotificationAddWXFrd              @"kNotificationAddWXFrd"
#define kNotificationShowLoadingScreen     @"kNotificationShowLoadingScreen"
#define kNotificationHideLoadingScreen     @"kNotificationHideLoadingScreen"
#define kNotificationSetLoadingScreenText  @"kNotificationSetLoadingScreenText"
#define kNotificationRunCommand            @"kNotificationRunCommand"
#define kNotificationStartGameScene        @"kNotificationStartGameScene"
#define kNotificationLoadGameData          @"kNotificationLoadGameData"
#define kNotificationReloadGameConfig      @"kNotificationReloadGameConfig"
#define kNotificationShowPreviewScene      @"kNotificationShowPreviewScene"
#define kNotificationShowInGameLoadingView     @"kNotificationShowInGameLoading"
#define kNotificationHideInGameLoadingView     @"kNotificationHideInGameLoading"
#define kNotificationComposeEmailFinish        @"kNotificationComposeEmailFinish"
#define kNotificationSendInvitationEmailFinish        @"kNotificationSendInvitationEmailFinish"
#define kNotificationPauseMusic            @"kNotificationSNSPauseMusic"
#define kNotificationResumeMusic           @"kNotificationSNSResumeMusic"
#define kNotificationSetServerTime         @"kNotificationSetServerTime"
#define kSNSNotificationUpdateStatus           @"kSNSNotificationUpdateStatus"
#define kSNSNotificationNewItemLoaded          @"kSNSNotificationNewItemLoaded"
#define kSNSNotificationUpdateItemLoadingStatus          @"kSNSNotificationUpdateItemLoadingStatus"
#define kSNSNotificationRemoteConfigLoaded          @"topgame.kSNSNotificationRemoteConfigLoaded"
#define kSNSNotificationRemoteFileLoaded          @"topgame.kSNSNotificationRemoteFileLoaded"
#define kSNSNotificationFileLoadingProgress       @"topgame.kSNSNotificationFileLoadingProgress"
#define kSNSNotificationSendDailyRewards       @"kSNSNotificationSendDailyRewards"
#define kSNSNotificationFacebookFeedSuccess    @"kFBFeedSuccess"
#define kSNSNotificationWeixinFeedSuccess      @"topgame.kWeixinFeedSuccess"
#define kSNSNotificationOnResumeFromBackground    @"topgame.kSNSNotificationOnResumeFromBackground"
#define kSNSNotificationOnShowUpdateDialog        @"topgame.kSNSNotificationOnShowUpdateDialog"
#define kSNSNotificationOnShowRatingDialog        @"topgame.kSNSNotificationOnShowRatingDialog"
#define kSNSNotificationShowAlertView             @"topgame.kSNSNotificationShowAlertView"
#define kSNSNotificationHideAlertView             @"topgame.kSNSNotificationHideAlertView"
// 命令


/*
 本地需要记录的数据：
 充值信息：累计统计（充值额，次数），今日统计（充值额，充值次数）
 tapjoy：累计收入额，当日收入额
 flurry：累计下载次数，当日下载次数
 黏性统计：上次玩游戏时间，累计统计（分钟数，次数），当日统计（累计分钟数，次数）
 消费点：当日每个道具的消费金币和叶子数
 升级速度：到达每个等级所经过的时间
 // sample 
 "statInfo":{"timeLast":1312108249,"timeACount":18,"tjTIncome1":0,
 "itemList":{"2-63":1,"10-7":1,"4-5":1,"3-409":1,"8-603":1,"2-62":1,"3-211":1,"3-421":1,"4-6":1},
 "levels":{"2":3600,"3":5800},
 "timeTUsed":1935,"devModel":"x86_64","flTCount":0,"tjTIncome2":0,
 "payTIncome":0,"timeInstall":1312081780,"timeAUsed":1935,"country":"CN",
 "today":110731,"timeTCount":18,"payTCount":0}
 
 */

#define kStatUserID           @"userID"  // userID
#define kStatTimeInstall           @"timeInstall" // 游戏安装时间，timestamp
#define kStatTimeLastPlay          @"timeLast" // 最后一次运行时间

/*
// payment
#define kStatPayAllIncome   @"payAIncome" // 累计付费金额
#define kStatPayAllCount    @"payACount"  // 累计付费次数
#define kStatPayTodayIncome   @"payTIncome" // 今日付费金额
#define kStatPayTodayCount    @"payTCount" // 今日付费次数

// player info
#define kStatDeviceModel      @"devModel" // 设备型号
#define kStatPlayerCountry    @"country" // 国家ID
#define kStatTodayDate        @"today"   // 日期，格式110731

#define kStatiOSVersion       @"osVer"
#define kStatSystemName       @"sysName"

// tapjoy
#define kStatTapjoyAllIncome    @"tjAIncome" // tapjoy累计点数
#define kStatTapjoyTodayIncome1   @"tjTIncome1" // 今日之前的累计点数
#define kStatTapjoyTodayIncome2   @"tjTIncome2" // 目前的累计点数

// flurry
#define kStatFlurryAllCount      @"flACount" // flurry累计安装次数
#define kStatFlurryTodayCount    @"flTCount" // 今日安装次数

// time consumed
// 黏性统计：上次玩游戏时间，累计统计（分钟数，次数），今日统计（累计分钟数，次数），昨日统计（累计分钟数，次数）
#define kStatTimeInstall           @"timeInstall" // 游戏安装时间，timestamp
#define kStatTimeLastPlay          @"timeLast" // 最后一次运行时间
#define kStatTimeAllUsed           @"timeAUsed" // 累计游戏时间
#define kStatTimeAllCount          @"timeACount" // 累计游戏次数
#define kStatTimeTodayUsed         @"timeTUsed" // 今日游戏时间
#define kStatTimeTodayCount        @"timeTCount" // 今日游戏次数

// consume
// 消费点：每个道具的消费金币和叶子数（昨日、今日）
#define kStatItemList              @"itemList" // 


// upgrade
// 升级速度：到达每个等级的时间点
#define kStatLevelUpList           @"levels" // 

// history
#define kStatHistoryList           @"history"
*/


enum
{
	kTagAlertNone,
    kTagAlertNetworkRequired,
	kTagAlertViewRateIt,
	kTagAlertViewDownloadApp,
	kTagAlertFileCorrupt,
	kTagAlertReloadGameRequired,
	kTagAlertReloadLanguage,
	kTagAlertCrashDetected,
    kTagAlertAppealForBlock,
    kTagAlertForceUpdate,
    kTagAlertInvalidEmailSetting,
    kTagAlertInviteNoEmailFound,
    kTagAlertFacebookLikeUs,
    kTagAlertResetGameData,
    kTagAlertResetGameDataOK,
    kTagAlertInvalidTransaction,
    kTagAlertFacebookReplyTicket,
    kTagAlertSwitchAccountConfirm,
};

enum {
	kGameResourceTypeNone, // 0
	kGameResourceTypeCoin, // 1
	kGameResourceTypeLeaf, // 2
	kGameResourceTypeExp,  // 3
    kGameResourceTypeLevel,   // 4-only for get
	kGameResourceTypeIAPCoin, // 5-only for add
	kGameResourceTypeIAPLeaf, // 6-only for add
	kGameResourceTypeIAPPromo, // 7-only for add
    kGameResourceTypeDisableAds = 10001, // 10001 - 禁用广告的状态
};

enum {
	kLogTypeEarnCoin=4,    // 4-获得金币一次
	kLogTypeSpendCoin,     // 5-消耗金币一次
	kLogTypeEarnLeaf,      // 6-获得叶子／钻石一次
	kLogTypeSpendLeaf,   // 7-消耗叶子／钻石一次
	kLogTypeEarnExp,     // 8-获得经验一次
    kLogTypeEarnPromo,   // 9-获得奖励礼包
};
// 定义获得／消耗资源的方式，这个各游戏可以根据自身游戏设计在SNSLogType.h中补充，补充的类型ID从101开始。
enum {
	kLogMethodTypeNone = 0,
	kLogMethodTypePayment, // 1－付费购买
	kLogMethodTypeFreeOffer, // 2－广告奖励
	kLogMethodTypeDailyBonus, // 3－每日奖励
    kLogMethodTypeSendFeed, // 4-发Feed
    kLogMethodTypeFinishTask, // 5-完成任务
    kLogMethodTypeLottery, // 6－参与抽奖
    kLogMethodTypePlayMiniGame, // 7-玩小游戏
    kLogMethodTypeGenerate = 101,
};

// 资源获取与消耗渠道定义
enum {
    kResChannelNone = 0,
    kResChannelIAP=1,  // 1-IAP购买
    kResChannelTapjoy=2, // Tapjoy广告奖励
    kResChannelFlurry=3, // Flurry
    kResChannelLiMei=4,  // 力美广告奖励
    kResChannelAppDriver=5, // AppDriver
    kResChannelEmailGift=6, // Email礼物
};

enum {
    kCoinTypeNone = 0,
    kCoinType1, // 金币
    kCoinType2, // 钻石／叶子
    kCoinType3, // 精力值／第三种货币
    kCoinType4, // 
};

/*
 // 旧版，现已不适用
// 日志记录格式：
//  
//  type: 日志类型
//  time：记录时间（发生时的时间戳）
//  insTime：从首次安装到现在的时间（秒）
// 获得／消耗资源的额外字段：
//  method－获得／消耗方式（整数），花钱买/点广告/宠物收获/功能房间收获/每日奖励/宠物心情／扩建／雇员／宠物房间建造／功能房间建造／加速建造／玩小游戏
//  itemID－主体对象ID（字符串）
//  count-获得／消耗数量
//  {"type":4,"time":1234566,"insTime":3600, "method":1, "itemID":"Coin10", "count":3000}

// 日志类型定义
enum {
	kLogTypeNone = 0,
	kLogTypeInstallGame, // 1-新安装, {"type":1,"time":1234566,"insTime":3600}
	kLogTypePlayGame,    // 2-玩一次游戏（打开游戏然后关闭游戏），增加字段： playTime－本次玩游戏时长（秒）, {"type":2,"time":1234566,"insTime":3600, "playTime":350}
	kLogTypePayment,     // 3-付费一次，额外字段：price－金额（美分），iapID－道具ID（字符串）, {"type":3,"time":1234566,"insTime":3600, "price":99, "iapID":"Diamond5"}
	kLogTypeEarnCoin,    // 4-获得金币一次，额外字段见说明
	kLogTypeSpendCoin,   // 5-消耗金币一次，额外字段见说明
	kLogTypeEarnLeaf,    // 6-获得叶子一次
	kLogTypeSpendLeaf,   // 7-消耗叶子一次
	kLogTypeEarnExp,     // 8-获得经验一次
	kLogTypeLevelUp,     // 9-升级一次，额外字段：level－升级后等级, {"type":9,"time":1234566,"insTime":3600, "level":5}
	kLogTypeBuyItem,     // 10-购买道具一次，额外字段：itemType-道具类型（整数），itemID-道具ID（字符串）, {"type":10,"time":1234566,"insTime":3600, "itemType":1, "itemID":"car01"}
	kLogTypePlayMiniGame, // 11-玩一次内置游戏（打开游戏然后关闭游戏），增加字段： playTime－本次玩游戏时长（秒），gameID－小游戏ID, {"type":11,"time":1234566,"insTime":3600, "playTime":35,"gameID":1}
};
 // 定义获得／消耗资源的方式
 enum {
 kLogMethodTypeNone = 0,
 kLogMethodTypePayment, // 1－付费购买
 kLogMethodTypeFreeOffer, // 2－广告奖励
 kLogMethodTypeDailyBonus, // 3－每日奖励
 kLogMethodTypeSendFeed, // 4-发Feed
 kLogMethodTypeFinishTask, // 5-完成任务
 kLogMethodTypeLottery, // 6－参与抽奖
 kLogMethodTypePlayMiniGame, // 7-玩小游戏
 };
 
*/



/*
 
 framework required:
 MobileCoreServices.framework
 SystemConfiguration.framework
 MessageUI.framework
 AddressBookUI.framework
 MediaPlayer.framework
 StoreKit.framework
 CoreTelephony.framework
 CoreAudio.framework
 CoreMedia.framework
 libsqlite3.dylib
 libicucore.dylib
 CFNetwork.framework
 GameKit.framework
 CoreFoundation.framework
 CoreGraphics.framework
 OpenGLES.framework
 UIKit.framework
 OpenAL.framework
 AudioToolbox.framework
 libz.dylib
 AVFoundation.framework
 CoreMedia.framework
 
 weak:
 Accounts.framework
 Social.framework
 AdSupport.framework
 Foundation.framework
 
 */

