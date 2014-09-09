//
//  SNSFunction.h
//  drawFree
//
//  Created by XU LE on 12-4-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#ifndef drawFree_SNSFunction_h
#define drawFree_SNSFunction_h

#include "SNSLogType.h"

// #include "GameDataStatic.h"

/**** 为了多平台适配，将静态全局常量移动GameDataStatic.h， wgx,2012.5.21 ****/
//#define kSNSADFeatureVisible   1
//#define kSNSADFeatureTapjoy    2
//#define kSNSADFeatureFlurry    3
//#define kSNSADFeatureLiMei     4


// 隐藏admob
void SNSFunction_hideAdmob();
// 显示admob
void SNSFunction_showAdmob();

// CPP异常处理函数
void cpp_exception_handler(int sig);

// 记录异常信息
void SNSFunction_logException(const char *info);

// 安装C＋＋异常处理
void SNSFunction_installCppExceptionHandler();

// 获得购买金币的数量
int  SNSFunction_getIAPCoin(int price);

// 购买某个IAP道具
void SNSFunction_buyIAPItem(const char *itemID);

// 促销折扣, 0-不促销，2／4／6／8：多送20／40／60／80％
int SNSFunction_getPromotionRate();

// 获得查询服务器状态的时间间隔，单位是秒
int SNSFunction_getCheckPeriodTime();

// 获得本地语言内容
const char *SNSFunction_getLocalizedString(const char *str);

// 设置当前用户ID
void SNSFunction_setCurrentUID(const char *uid);
// 获取当前用户ID
const char * SNSFunction_getCurrentUID();

// 执行命令
void SNSFunction_runCommand(const char *cmd);

// 检查广告功能是否开启, tapjoy,flurry,limei, showad
bool SNSFunction_checkFeature(int feature);

// 初始化广告平台
void SNSFunction_initAdInfo();

// 获取设备token
const char *SNSFunction_getDeviceToken();

// 返回是否是iPod
bool SNSFunction_isIPod();

// 返回是否是iPad
bool SNSFunction_isIPad();

// 设置默认邮箱
void SNSFunction_setDefaultEmail(const char *email);

// 显示邀请界面
void SNSFunction_showInviteFriends();

// Facebook连接并邀请
void SNSFunction_connectFacebookAndInvite();
// 检查Facebook是否已经登录
bool SNSFunction_isFacebookConnected();
// 检查是否已经获得过首次连接奖励了
bool SNSFunction_ifGotFacebookConnectPrize();
// 获取Facebook用户名
const char * SNSFunction_getFacebookUsername();
// 获取Facebook用户Icon路径
const char * SNSFunction_getFacebookIcon(const char * uid = NULL);
// 获取Facebook用户uid
const char * SNSFunction_getFacebookUid();
// Facebook断开连接
void SNSFunction_disconnectFacebook();
// Facebook/Weixin奖励状态: 0-从未连接过，1-今天还没有邀请过，2-今天已经邀请1次了，3-今天已经邀请2次了
// 对facebook只会返回0和3。
int  SNSFunction_getFacebookPrizeStatus();
// Weixin连接状态:true-已经连接过了，false－从未连接过
int  SNSFunction_isWeixinConnected();
// Weixin当天发布邀请的数量
int  SNSFunction_getWeixinInviteCount();
// Weixin朋友圈分享状态: 0-今天还没有发布过，1-今天已经发布到朋友圈了
int  SNSFunction_getWeixinPublishNoteStatus();
// 发布分享信息到朋友圈
void SNSFunction_weixinPublishNote();
// 发布分享信息到朋友圈
void SNSFunction_weixinInviteFriends();
// 发布添加好友信息到微信
void SNSFunction_weixinAddFriend();
// 发布好友邀请到微信获得无限体力
void SNSFunction_weixinUnlimitLife();
// 打开微信app
void SNSFunction_weixinOpen();

// 评价五星提示
void SNSFunction_showRatingHint();

// 给客服发信
void SNSFunction_writeEmailToSupport();

// 显示订阅邮件列表
void SNSFunction_showSubscribeMaillingList();

// 设置免打扰模式
// canInterrupt:true - 可以弹出广告，canInterrupt:false-不能弹出广告
void SNSFunction_setInterruptMode(bool canInterrupt);

// 设置本地通知允许状态
void SNSFunction_setNotificationStatus(bool enabled);

// 获取本地通知允许状态
bool SNSFunction_getNotificationStatus();

// 检查是否付费版本
bool SNSFunction_isPaidVersion();

// 获取后台服务器域名
const char *SNSFunction_getServerDomain();

// 获取版本信息
const char *SNSFunction_getVersionInfo();
// 获取当前用户ID和版本号
const char * SNSFunction_getVersionInfoAndUID();

// 显示版本信息
void SNSFunction_showAboutUs();

// 获得字符串类型的系统配置参数
const char *SNSFunction_getSystemInfoString(const char *key);
// 获得整数类型的系统配置参数
int SNSFunction_getSystemInfoInt(const char *key);

// 获得缓存文件目录，Library/Caches ,该目录里的文件可能随时被系统删除
const char *SNSFunction_getCachePath();

// deflate压缩字符串，返回的pOut需要用free(*pOut)释放, PHP中对应的解压函数是gzuncompress()
int SNSFunction_deflateData(unsigned char *pData, int dataLen, unsigned char **pOut, int *pOutLen);

// 获得某个IAP道具对应的物品数量, 不如:coin2-1500, coin5-5000
int SNSFunction_getIAPItemCount(const char *itemID); // 、、

// 获取当前系统时间
int SNSFunction_getCurrentTime();
// 获取当前日期,格式6位整数，121102
int SNSFunction_getTodayDate();
// 获取当前小时数
int SNSFunction_getCurrentHour();
// 获取当前分钟数
int SNSFunction_getCurrentMinute();
// 获取当前秒数
int SNSFunction_getCurrentSecond();

// 邮件发送礼物
void SNSFunction_sendGift();

// 显示弹窗广告
void SNSFunction_showRandomPopup();
// 禁止／允许弹窗
void SNSFunction_setPopupStatus(bool enable);

// 显示带奖励的广告
void SNSFunction_getFreeBonus();

// 保存进度
void SNSFunction_saveGameData();

// 货币／资源统计， resType－货币类型／资源类型， num－变化数量，正数增加，负数减少， type－渠道类型，消耗渠道和来源渠道
void SNSFunction_logResource(int resType, int num, int type);
// 成就统计，成就只统计一次，已经完成的成就重复调用会直接忽略
void SNSFunction_logAchievement(const char *achieveName);
// 道具购买统计, itemID-道具ID，count－购买数量，cost－价格／消耗资源数量，resType－货币类型／消耗资源类型, itemType-道具类型, place-发生此行为的位置,默认位置可以填default
// usage: SNSFunction_logBuyItem("fiveStep", 1, 9, 2, 0, "default");
void SNSFunction_logBuyItem(const char *itemID, int count, int cost, int resType, int itemType, const char *place);
// 行为统计，记录累计次数和最后一次操作的时间
void SNSFunction_logAction(const char *actionName);


// 获得IAP道具的价格 $2.99
const char *getIAPItemPrice(const char *itemID);

// 获得远程下载的CSV配置文件
const char *SNSFunction_getRemoteConfigCSVFile(const char *csvFile);

// 获得目前龙窝加速次数
int SNSFunction_getNestFastTimes(int nestID);

// 增加龙窝加速次数
int SNSFunction_addNestFastTimes(int nestID);

// 获得累计的付费金额，单位是美金
int SNSFunction_getTotalPayment();

// 重置存档
void SNSFunction_resetGameData();

// 显示offer广告: flurry, arriki
void SNSFunction_showAdOffer(const char *offerType);

// 检查广告功能是否开启, tapjoy,flurry,limei, showad
// bool SNSFunction_checkFeature(int feature);
// 是否可以显示广告
bool SNSFunction_isAdVisible();
// 显示弹窗广告
void SNSFunction_showPopupAd();

// 获取远程下载文件路径
const char *SNSFunction_getDownloadFilePath(const char *fileName);
// 检查远程文件是否存在
bool SNSFunction_isDownloadFileExists(const char *fileName);

//获取远程下载目录路径
const char * SNSFunction_getDownloadFolderPath();

//获取远程下载目录子目录文件名路径
const char * SNSFunction_getDownloadSubFolderFilePath(const char* subFolder, const char* fileName);

// 获取远程配置参数,没有就返回默认值0
int SNSFunction_getRemoteConfigInt(const char *key);
// 获取字符串配置参数, 没有就返回NULL
const char *SNSFunction_getRemoteConfigString(const char *key);

// 获取上次退出游戏的时间, 如果是首次打开游戏，返回0
int SNSFunction_getLastExitTime();
//设置退出游戏的时间
void SNSFunction_setLastExitTime();

// 显示力美广告墙
void SNSFunction_showFreeGemsOffer();
// 显示免费广告墙: 1-力美，2-Domob, 3-youmi, 4-dianru, 5-adwo
void SNSFunction_showFreeGemsOfferOfType(int type);
// 打开URL连接
void SNSFunction_openURL(const char *link);

// 去评分
void SNSFunction_toRateIt();
// 获取上次评分时间, 如果是首次打开游戏，返回0
int SNSFunction_getLastRateTime();
// 设置评分时间
void SNSFunction_setLastRateTime();
// 生成随机数
int SNSFunction_getRandom();
// 获得新通知数量
int SNSFunction_getNewNoticeCount();
// 显示通知
void SNSFunction_showNoticePopup();
// 轮询显示插屏广告
void SNSFunction_showCNPopupOffer();

#endif
