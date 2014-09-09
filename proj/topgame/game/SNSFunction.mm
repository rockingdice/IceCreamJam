//
//  SNSFunction.cpp
//  drawFree
//
//  Created by XU LE on 12-4-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#include <execinfo.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <exception>
#include <zlib.h>

#include "ccMacros.h"
#include "GameConfig.h"
#include "mtwist.h"

#include "SNSFunction.h"
#import  "SnsServerHelper.h"
#import "TinyiMailHelper.h"
#import "SnsStatsHelper.h"
#import "ChartBoostHelper.h"
#ifdef SNS_ENABLE_TINYMOBI
#import "TinyMobiHelper.h"
#endif
#import "SnsGameHelper.h"
#import "InAppStore.h"
#import "SBJson.h"
#import "FacebookHelper.h"
#ifdef SNS_ENABLE_WEIXIN
#import "WeixinHelper.h"
#endif
#ifdef SNS_ENABLE_MINICLIP
#import "MiniclipHelper.h"
#endif

static const char *g_sns_assert_mesg = NULL;

void SNSFunction_setAssertReason(const char *msg)
{
    g_sns_assert_mesg = msg;
    // assert(1);
    cpp_exception_handler(SIGABRT);
}

void SNSFunction_hideAdmob()
{
    [[SnsServerHelper helper] hideAdmobBanner];
}


void SNSFunction_showAdmob()
{
    [[SnsServerHelper helper] showAdmobBanner];
}

void cpp_exception_handler(int sig) {
    
    int j, nptrs, error;
    error = errno;
    
    // std::exception *ex = 
    
#define BUFF_SIZE 100
    
    void *buffer[BUFF_SIZE];
    char **strings;
    
    char *buf = (char *)malloc(2050); buf[0] = 0;
    char *p = buf; int len = 0; int slen = 0;
    sprintf(buf, "[errno:%d] signal:%d\n", error, sig);
    len = strlen(buf); p += len;
    
    nptrs = backtrace(buffer, BUFF_SIZE);
#ifdef DEBUG
    printf("errno:%d backtrace() returned %d addresses\n", error, nptrs);
#endif
    /* The call backtrace_symbols_fd(buffer, nptrs, STDOUT_FILENO)
     would produce similar output to the following: */
    
    strings = backtrace_symbols(buffer, nptrs);
    
    if(g_sns_assert_mesg) {
        slen = strlen(g_sns_assert_mesg);
        if(slen>250) slen = 250;
        memcpy(p, g_sns_assert_mesg, slen);
        p += slen; len += slen;
#ifdef DEBUG
        printf("assert reason:%s\n",g_sns_assert_mesg);
#endif
    }
    if (strings == NULL) {
    }
    else {
        for (j = 1; j < nptrs; j++) {
#ifdef DEBUG        
            printf("%s\n", strings[j]);
#endif
            slen = strlen(strings[j]);
            if(len+slen>2048) slen = 2048-len;
            if(slen<=0) break;
            memcpy(p, strings[j], slen);
            p += slen; len += slen;
            p[0] = '\n'; p++; len++;
        }
    }
    p[len]=0;
    
    SNSFunction_logException(buf);
    
    free(strings); free(buf);
    
    exit(error);
}

void cpp_unhandled_exception_handler()
{
    cpp_exception_handler(SIGABRT);
}

// 安装C＋＋异常处理
void SNSFunction_installCppExceptionHandler()
{
    signal(SIGSEGV, cpp_exception_handler);
    signal(SIGABRT, cpp_exception_handler);
    std::set_unexpected(cpp_unhandled_exception_handler);
    std::set_terminate(cpp_unhandled_exception_handler);
}

// 记录异常信息
void SNSFunction_logException(const char *info)
{
    // [NSException raise:@"CppException" format:@"unknown"];
    NSString *reason = [NSString stringWithCString:info encoding:NSASCIIStringEncoding];
    if(!reason) reason = @"NoReasonFound";
    [SystemUtils uncaughtCppExceptionInfo:reason];
}


// 获得购买金币的数量
int  SNSFunction_getIAPCoin(int price)
{
    return [[SystemUtils getGameDataDelegate] getIAPCoinCount:price];
}

// 促销折扣, 0-不促销，2／4／6／8：多送20／40／60／80％
int SNSFunction_getPromotionRate()
{
    return [SystemUtils getPromotionRate];
}

// 获得查询服务器状态的时间间隔
int SNSFunction_getCheckPeriodTime()
{
    int sec = [[SystemUtils getGlobalSetting:@"kCheckStatusPeriodTime"] intValue];
    if(sec <= 0) sec = 30;
    return sec;
}

// 获得本地语言内容
const char *SNSFunction_getLocalizedString(const char *str)
{
    NSString *str2 = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
    NSString *str3 = [SystemUtils getLocalizedString:str2];
    if(!str3 || [str3 isEqualToString:str2]) return str;
    return [str3 UTF8String];
}

// 设置当前用户ID
void SNSFunction_setCurrentUID(const char *uid)
{
    [SystemUtils setCurrentUID:[NSString stringWithCString:uid encoding:NSUTF8StringEncoding]];
}
// 获取当前用户ID
const char * SNSFunction_getCurrentUID()
{
    NSString *uid = [SystemUtils getCurrentUID];
    return [uid UTF8String];
}

// 执行命令
void SNSFunction_runCommand(const char *cmd)
{
    if(strcmp(cmd,"showFlurry")==0) {
        [SystemUtils setNSDefaultObject:@"1" forKey:@"showNoOfferHint"];
    }
    [SystemUtils runCommand:[NSString stringWithCString:cmd encoding:NSUTF8StringEncoding]];
}
// 检查广告功能是否开启, tapjoy,flurry,limei
bool SNSFunction_checkFeature(int feature)
{
    /*
    if(feature == kSNSADFeatureVisible) {
        if([SystemUtils checkFeature:kFeatureShowAd]) return true;
        return false;
    }
    if(feature == kSNSADFeatureTapjoy) {
        if([SystemUtils checkFeature:kFeatureTapjoy]) return true;
        return false;
    }
    if(feature == kSNSADFeatureFlurry) {
        if([SystemUtils checkFeature:kFeatureFlurry]) return true;
        return false;
    }
    if(feature == kSNSADFeatureLiMei) {
        if([SystemUtils checkFeature:kFeatureLiMei]) return true;
        return false;
    }
     */
    return false;
}

// 初始化广告平台
void SNSFunction_initAdInfo()
{
    /*
    SNSLog(@"init ad");
    if(SNSFunction_checkFeature(kSNSADFeatureTapjoy)) {
        [[TapjoyHelper helper] initTapjoySession];
    }
    if(SNSFunction_checkFeature(kSNSADFeatureFlurry)) {
        [[FlurryHelper helper] initFlurrySession];
    }
    if(SNSFunction_checkFeature(kSNSADFeatureLiMei)) {
        [[LiMeiHelper helper] initSession];
    }
     */
    
}


// 获取设备token
const char *SNSFunction_getDeviceToken()
{
    NSString *token = [SystemUtils getDeviceToken];
    if(!token) token = @"";
#ifdef DEBUG
    NSLog(@"获取到的设备token===>%@",token);
#endif
    return [token UTF8String];
}

// 判断是否是iPod
bool SNSFunction_isIPod()
{
	NSString *deviceType = [SystemUtils getDeviceType];
	if([[deviceType substringToIndex:4] isEqualToString:@"iPod"]) return YES;
	
	return NO;
}

// 判断是否是iPad
bool SNSFunction_isIPad()
{
	return [SystemUtils isiPad];
}

// 设置默认邮箱
void SNSFunction_setDefaultEmail(const char *email)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    [[TinyiMailHelper helper] setDefaultEmail:[NSString stringWithCString:email encoding:NSUTF8StringEncoding]];
#endif
}

// 显示邀请界面
void SNSFunction_showInviteFriends()
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    // [[SnsGameHelper helper] sendFacebookInvitation];
    [[TinyiMailHelper helper] writeInvitationEmail];
#endif    
}

// Facebook邀请
void SNSFunction_connectFacebookAndInvite()
{
    // SNSFunction_showRandomPopup();
    [[SnsGameHelper helper] sendFacebookInvitation];

}

// 发布分享信息到朋友圈
void SNSFunction_weixinPublishToFriendCircle()
{
#ifdef SNS_ENABLE_WEIXIN
    [[WeixinHelper helper] publishNote];
#endif
}

// Facebook断开连接
void SNSFunction_disconnectFacebook()
{
#ifdef SNS_ENABLE_WEIXIN
    // NSString *country = [SystemUtils getOriginalCountryCode];
    // if([country isEqualToString:@"CN"]) {
        // no need to disconnect in weixin
        return;
    // }
#endif
    
    [[FacebookHelper helper] logout];
}

// 检查Facebook是否已经登录
bool SNSFunction_isFacebookConnected()
{
#ifdef SNS_ENABLE_WEIXIN
    // NSString *country = [SystemUtils getOriginalCountryCode];
    // if([country isEqualToString:@"CN"]) {
        // check weixin
        if([[WeixinHelper helper] hasConnected]) return true;
        return false;
    // }
#endif
//    return [[FacebookHelper helper] isLoggedIn];
    NSString *fbUserID = [FacebookHelper helper].fbUserID;
    if(fbUserID==nil || [fbUserID length]==0) return false;
    return true;
}
// 检查是否已经获得过首次连接奖励了
bool SNSFunction_ifGotFacebookConnectPrize()
{
#ifdef SNS_ENABLE_WEIXIN
    // NSString *country = [SystemUtils getOriginalCountryCode];
    // if([country isEqualToString:@"CN"]) {
        // check weixin
        if([[WeixinHelper helper] hasConnected]) return true;
        return false;
    // }
#endif
    if([[FacebookHelper helper] ifGotConnectPrize]) return true;
    return false;
}
const char * SNSFunction_getFacebookUsername()
{
    NSString *fbUserName = [FacebookHelper helper].fbUserName;
    if(fbUserName==nil || [fbUserName length]==0) return NULL;
    
    return [fbUserName UTF8String];
}

const char * SNSFunction_getFacebookIcon(const char * uid)
{
    if (uid) {
        NSString * icon = [[FacebookHelper helper] getFacebookIconPath:[NSString stringWithUTF8String:uid]];
        return [icon UTF8String];
    }
    NSString *fbUserID = [FacebookHelper helper].fbUserID;
    if(fbUserID==nil || [fbUserID length]==0) return NULL;
    
    return [[[FacebookHelper helper] getFacebookIconPath:fbUserID] UTF8String];
}

const char * SNSFunction_getFacebookUid()
{
    NSString *fbUserID = [FacebookHelper helper].fbUserID;
    if(fbUserID==nil || [fbUserID length]==0) return NULL;

    return [fbUserID UTF8String];
}

// Facebook/Weixin奖励状态: 0-从未连接过，1-今天还没有邀请过，2-今天已经邀请1次了，3-今天已经邀请2次了
// 对facebook只会返回0和3。
int  SNSFunction_getFacebookPrizeStatus()
{
#ifdef SNS_ENABLE_WEIXIN
    // NSString *country = [SystemUtils getOriginalCountryCode];
    // if([country isEqualToString:@"CN"]) {
        // check weixin
    if(![[WeixinHelper helper] hasConnected]) return 0;
    if(![[WeixinHelper helper] hasGotTodayPrize]) {
        if([[WeixinHelper helper] hasGotTodayInvitePrize]) return 2;
        return 1;
    }
    return 3;
    // }
#endif
    if([[FacebookHelper helper] ifGotConnectPrize]) return 3;
    return 0;
}

// Weixin当天发布邀请的数量
int  SNSFunction_getWeixinInviteCount()
{
#ifdef SNS_ENABLE_WEIXIN
    return [[WeixinHelper helper] getTodayInviteCount];
#endif
    return 0;
}
// Weixin连接状态:true-已经连接过了，false－从未连接过
int  SNSFunction_isWeixinConnected()
{
#ifdef SNS_ENABLE_WEIXIN
    return [[WeixinHelper helper] hasConnected];
#endif
    return false;
}

// Weixin朋友圈分享状态: 0-今天还没有发布过，1-今天已经发布到朋友圈了
int  SNSFunction_getWeixinPublishNoteStatus()
{
#ifdef SNS_ENABLE_WEIXIN
    return [[WeixinHelper helper] getTodayPublishCount];
#endif
    return 0;
}
// 发布分享信息到朋友圈
void SNSFunction_weixinPublishNote()
{
#ifdef SNS_ENABLE_WEIXIN
    [[WeixinHelper helper] publishNote];
#endif
}
// 发布邀请给微信好友
void SNSFunction_weixinInviteFriends()
{
#ifdef SNS_ENABLE_WEIXIN
    [[WeixinHelper helper] inviteFriend];
#endif
}
// 发布添加好友信息到微信
void SNSFunction_weixinAddFriend()
{
#ifdef SNS_ENABLE_WEIXIN
    [[WeixinHelper helper] addFriend];
#endif
}
// 发布好友邀请到微信获得无限体力
void SNSFunction_weixinUnlimitLife()
{
#ifdef SNS_ENABLE_WEIXIN
    [[WeixinHelper helper] unlimitLife];
#endif
}

// 打开微信app
void SNSFunction_weixinOpen()
{
#ifdef SNS_ENABLE_WEIXIN
    [[WeixinHelper helper] openWeixinApp];
#endif
}

// 评价五星提示
void SNSFunction_showRatingHint()
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    [SystemUtils showReviewHint];
#endif
} 

// 给客服发信
void SNSFunction_writeEmailToSupport()
{
    /*
#ifdef DEBUG
    NSString *url = @"SlotsCasino://";
    BOOL res = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    if(!res) NSLog(@"%s:failed to openURL: %@",__func__, url);
    return;
#endif
     */
#ifdef DEBUG
    // [SystemUtils showPopupOfferOfType:@"limeiPopup"]; return;
    // [SystemUtils showPromotionNotice]; return;
#endif
    [SystemUtils writeEmailToSupport];
}

// 显示订阅邮件列表
void SNSFunction_showSubscribeMaillingList()
{
    [[TinyiMailHelper helper] showiMailPopupBox:YES];
}

// 设置免打扰模式
// canInterrupt:true - 可以弹出广告，canInterrupt:false-不能弹出广告
void SNSFunction_setInterruptMode(bool canInterrupt)
{
    if(canInterrupt) {
        [SystemUtils setInterruptMode:YES];
    }
    else {
        [SystemUtils setInterruptMode:NO];
    }
}

// 设置本地通知允许状态
void SNSFunction_setNotificationStatus(bool enabled)
{
    BOOL res = NO; 
    if(enabled) res = YES;
    [[SnsServerHelper helper] setNotificationStatus:res];
}

// 获取本地通知允许状态
bool SNSFunction_getNotificationStatus()
{
    BOOL res = [[SnsServerHelper helper] getNotificationStatus];
    if(res) return true;
    return false;
}

// 检查是否付费版本
bool SNSFunction_isPaidVersion()
{
    if([SystemUtils isPaidVersion]) return true;
    return false;
}

// 获取后台服务器域名
const char *SNSFunction_getServerDomain()
{
    NSString *server = [SystemUtils getServerName];
    return [server UTF8String];
}

// 获取版本信息
const char *SNSFunction_getVersionInfo()
{
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;
    // NSLog(@"bundle info:%@", info);
    // NSLog(@"app version: %@(%@)", [info objectForKey:@"CFBundleVersion"], [info objectForKey:@"CFBundleShortVersionString"]);
    NSString *str = [NSString stringWithFormat:@"v%@", [info objectForKey:@"CFBundleVersion"]];
    return [str UTF8String];
}
// 获取当前用户ID和版本号, sample: UID: 123456 v1.0.1
const char * SNSFunction_getVersionInfoAndUID()
{
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;
    NSString *str = [NSString stringWithFormat:@"UID:%@ v%@", [SystemUtils getCurrentUID], [info objectForKey:@"CFBundleVersion"]];
    return [str UTF8String];
}

// 显示版本信息
void SNSFunction_showAboutUs()
{
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;
    // NSLog(@"bundle info:%@", info);
    // NSLog(@"app version: %@(%@)", [info objectForKey:@"CFBundleVersion"], [info objectForKey:@"CFBundleShortVersionString"]);
    NSString *str = [NSString stringWithFormat:@"Say Something\nV%@(%@)", [info objectForKey:@"CFBundleShortVersionString"], [info objectForKey:@"CFBundleVersion"]];
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"About Us" message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [av show];
    [av release];
}

#define DEFLATE_CHUNK  16384

int SNSFunction_deflateData(unsigned char *pData, int dataLen, unsigned char **pOut, int *pOutLen)
{
    int ret, flush;
    unsigned have;
    z_stream strm;
    // unsigned char inBuf[DEFLATE_CHUNK];
    unsigned char outBuf[DEFLATE_CHUNK];
    int CHUNK = DEFLATE_CHUNK; 
    int level = 3;
    /* allocate deflate state */
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    ret = deflateInit(&strm, level);
    if (ret != Z_OK)
        return ret;
    
    unsigned char *pOutData = (unsigned char *)malloc(dataLen*1.01+15);
    int outDataLen = 0;
    
    flush = Z_FINISH;
    /* compress until end of file */
    strm.avail_in = dataLen;
    strm.next_in = pData;
    
    /* run deflate() on input until output buffer not full, finish
     compression if all of source has been read in */
    do {
        strm.avail_out = CHUNK;
        strm.next_out = outBuf;
        ret = deflate(&strm, flush);    /* no bad return value */
        assert(ret != Z_STREAM_ERROR);  /* state not clobbered */
        have = CHUNK - strm.avail_out;
        memcpy(pOutData+outDataLen, outBuf, have);
        outDataLen += have;
    } while (strm.avail_out == 0);
    assert(strm.avail_in == 0);     /* all input will be used */
        
    /* clean up and return */
    (void)deflateEnd(&strm);
    
    *pOut = pOutData;
    *pOutLen = outDataLen;
    
    return Z_OK;
}

// 获得缓存文件目录，Library/Caches ,该目录里的文件可能随时被系统删除
const char *SNSFunction_getCachePath()
{
    NSString *cachePath = [SystemUtils getCacheRootPath];
    NSFileManager *mgr = [NSFileManager defaultManager];
    if(![mgr fileExistsAtPath:cachePath]) 
        [mgr createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    return [cachePath UTF8String];
}

// 获得字符串类型的系统配置参数
const char *SNSFunction_getSystemInfoString(const char *key)
{
    NSString *key2 = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
    NSString *val = [SystemUtils getSystemInfo:key2];
    if(val==nil) return "";
    return [val UTF8String];
}
// 获得整数类型的系统配置参数
int SNSFunction_getSystemInfoInt(const char *key)
{
    NSString *key2 = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
    id val = [SystemUtils getSystemInfo:key2];
    if(val==nil) return 0;
    if([val respondsToSelector:@selector(intValue)]) return [val intValue];
    return 0;
}


// 购买某个IAP道具
void SNSFunction_buyIAPItem(const char *itemID)
{
    [[SnsGameHelper helper] buyIapItem:itemID];
}

// 获得某个IAP道具对应的物品数量
int SNSFunction_getIAPItemCount(const char *itemID)
{
    NSString *str = [NSString stringWithCString:itemID encoding:NSUTF8StringEncoding];
    return [[SnsGameHelper helper] getIapItemQuantity:str];
}

// 获得IAP道具的价格
const char *getIAPItemPrice(const char *itemID)
{
    NSString *str = [NSString stringWithCString:itemID encoding:NSUTF8StringEncoding];
    NSString *prefix = [SystemUtils getSystemInfo:@"kIapItemPrefix"];
    if([str rangeOfString:prefix].location == NSNotFound)
        str = [prefix stringByAppendingString:str];
    NSDictionary *info = [[InAppStore store] getProductInfo:str];
    if(info && [info isKindOfClass:[NSDictionary class]])
    {
        NSString *price = [info objectForKey:@"Price"];
        NSString *symbol = [info objectForKey:@"CurrencySymbol"];
        if([symbol length]>2) symbol = [symbol substringFromIndex:2];
        price = [symbol stringByAppendingString:price];
        return [price UTF8String];
    }
    else {
        char buf[10]; int len = strlen(itemID); int i=0;
        for(i=len-1;i>0;i--)
        {
            if(itemID[i]>'9' || itemID[i]<'0') break;
        }
        int pos = i;
        for(i=pos;i<len;i++)
            buf[i-pos] = itemID[i];
        buf[len-pos] = '\0';
        int price1 = atoi(buf);
        NSString *price = [NSString stringWithFormat:@"$%i.99",price1];
        return [price UTF8String];
    }
    // return "$1.99";
    /*
     {
     CurrencyCode = CNY;
     CurrencySymbol = "CN\U00a5";
     Desc = "The gems can buy the special dragons or reduce waiting time!";
     ID = "com.topgame.DragonSoul.gem100";
     OriginalPrice = 648;
     Price = 648;
     Promos = 0;
     Title = "Mountain of gems";
     coin = 0;
     discount = 0;
     gem = 100;
     priceKey = "com.topgame.DragonSoul.gem100";
     }
     */
}


// 获取当前系统时间
int SNSFunction_getCurrentTime()
{
    return [SystemUtils getCurrentTime];
}

// 获取当前日期,格式6位整数，121102
int SNSFunction_getTodayDate()
{
    return [SystemUtils getTodayDate];
}

// 获取当前小时数
int SNSFunction_getCurrentHour()
{
    return [SystemUtils getCurrentHour];
}
// 获取当前分钟数
int SNSFunction_getCurrentMinute()
{
    return [SystemUtils getCurrentMinute];
}
// 获取当前秒数
int SNSFunction_getCurrentSecond()
{
    return [SystemUtils getCurrentSecond];
}

// 获取上次退出游戏的时间, 如果是首次打开游戏，返回0
int SNSFunction_getLastExitTime()
{
    return [[SystemUtils getNSDefaultObject:@"kLastExitTime"] intValue];
}

// 设置退出游戏的时间
void SNSFunction_setLastExitTime()
{
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:[SystemUtils getCurrentTime]] forKey:@"kLastExitTime"];
}


// 邮件发送礼物
void SNSFunction_sendGift()
{
    // [[TinyiMailHelper helper] writeGiftEmail];
    [[SnsGameHelper helper] sendFacebookInvitation];
}
// 禁止／允许弹窗
void SNSFunction_setPopupStatus(bool enable)
{
    if(enable) [SystemUtils setInterruptMode:YES];
    else [SystemUtils setInterruptMode:NO];
}

// 显示弹窗广告
void SNSFunction_showRandomPopup()
{
#ifdef SNS_ENABLE_MINICLIP
    if([[MiniclipHelper helper] showUrgentBoard]) return;
//    if([[MiniclipHelper helper] showPopup]) return;
#endif
    // show facebook like
    BOOL res;
#ifndef JELLYMANIA
    res = [SystemUtils showFacebookLikePopup];
    if(res) return;
#endif
    
    res = [SystemUtils showSpecialIapOffer:nil];
    if(res) return;
    
    int date1 = 0; int today = [SystemUtils getTodayDate];
    
    
#ifdef SNS_ENABLE_TINYMOBI
    // show tinymobi
//    date1 = [[SystemUtils getNSDefaultObject:@"kTinyMobiPopTime"] intValue];
//    if(date1!=today) {
//        res = [[TinyMobiHelper helper] showPopupAd];
//        if(res) {
//            date1 = today;
//            [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date1] forKey:@"kTinyMobiPopTime"];
//        }
//    }
//    if(res) return;
#endif
    
    date1 = [[SystemUtils getNSDefaultObject:@"kChartboostPopTime"] intValue];
    if(date1!=today) {
        // show chartboost
        res = [[ChartBoostHelper helper] showChartBoostOffer];
        if(res) {
            date1 = today;
            
            [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date1] forKey:@"kChartboostPopTime"];
        }
    }
    if(res) return;
}

// 显示带奖励的广告
void SNSFunction_getFreeBonus()
{
    // TODO: 根据用户状态选择广告
}

// 保存进度
void SNSFunction_saveGameData()
{
    [[SnsGameHelper helper] saveGame];
    [[SnsStatsHelper helper] saveStats];
}

// 货币／资源统计， resType－货币类型／资源类型， num－变化数量，正数增加，负数减少， type－渠道类型，消耗渠道和来源渠道
void SNSFunction_logResource(int resType, int num, int type)
{
    [[SnsStatsHelper helper] logResource:resType change:num channelType:type];
}
// 成就统计，成就只统计一次，已经完成的成就重复调用会直接忽略
void SNSFunction_logAchievement(const char *achieveName)
{
    [[SnsStatsHelper helper] logAchievement:[NSString stringWithUTF8String:achieveName]];
}
// 道具购买统计, itemID-道具ID，count－购买数量，cost－价格／消耗资源数量，resType－货币类型／消耗资源类型, itemType-道具类型, place-发生此行为的位置,默认位置可以填default
void SNSFunction_logBuyItem(const char *itemID, int count, int cost, int resType, int itemType, const char *place)
{
    [[SnsStatsHelper helper]
     logBuyItem:[NSString stringWithUTF8String:itemID]
     count:count cost:cost resType:resType itemType:itemType placeName:[NSString stringWithUTF8String:place]];
}
// 行为统计，记录累计次数和最后一次操作的时间
void SNSFunction_logAction(const char *actionName)
{
    [[SnsStatsHelper helper] logAction:[NSString stringWithUTF8String:actionName]];
}


// 获得远程下载的CSV配置文件
const char *SNSFunction_getRemoteConfigCSVFile(const char *csvFile)
{
    NSDictionary *dict = [SystemUtils getSystemInfo:@"kRemoteConfigFileDict"];
    if(!dict && ![dict isKindOfClass:[NSDictionary class]]) return NULL;
    NSString *remoteFile = [dict objectForKey:[NSString stringWithCString:csvFile encoding:NSUTF8StringEncoding]];
    if(remoteFile==nil) return NULL;
    
    NSString *remoteFilePath = [NSString stringWithFormat:@"%@/%@", [SystemUtils getItemRootPath], remoteFile];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:remoteFilePath]) return NULL;
    NSString *text = nil;
    NSArray *content = nil;
    text = [NSString stringWithContentsOfFile:remoteFilePath encoding:NSUTF8StringEncoding error:nil];
    if([text characterAtIndex:0]=='|') {
        // 新格式：带验证信息，后面是JSON数组
        if([SystemUtils verifySaveDataWithHash:text]) {
            text = [SystemUtils stripHashFromSaveData:text];
        }
        else {
            text = nil;
        }
    }
    else {
        // 旧格式：JSON数组
    }
    if(!text) return NULL;
    if(text) content = [text JSONValue];
    if(!content || ![content isKindOfClass:[NSArray class]]) return NULL;
    NSArray *fields = [SystemUtils getGlobalSetting:[remoteFile stringByAppendingString:@"_fields"]];
    NSMutableString *buff = [[NSMutableString alloc] init];
    NSString *key = nil; int count = 0;
    if(fields) {
        for(key in fields) {
            if(count>0) [buff appendString:@";"];
            [buff appendString:key];
            count++;
        }
        [buff appendString:@"\n"];
    }
    for(NSDictionary * v in content) {
        if(fields==nil) {
            fields = [v allKeys]; count = 0;
            for(key in fields) {
                if(count>0) [buff appendString:@";"];
                [buff appendString:key];
                count++;
            }
            [buff appendString:@"\n"];
        }
        count = 0;
        for(key in fields) {
            if(count>0) [buff appendString:@";"];
            NSString *val = [v objectForKey:key];
            if([val rangeOfString:@"\""].location!=NSNotFound || [val rangeOfString:@";"].location!=NSNotFound) {
                val = [val stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
                val = [NSString stringWithFormat:@"\"%@\"",val];
            }
            [buff appendString:val];
            count++;
        }
        [buff appendString:@"\n"];
    }
    NSString *path = [NSString stringWithFormat:@"%@/%s.new",[SystemUtils getItemImagePath],csvFile];
    [buff writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
    [buff release];
    SNSLog(@"dump %@ to %@", remoteFile, path);
    return [path UTF8String];
}


// 获得目前龙窝加速次数
int SNSFunction_getNestFastTimes(int nestID)
{
    NSString *key1 = [NSString stringWithFormat:@"nestTimes_%i", nestID];
    NSString *key2 = [NSString stringWithFormat:@"nestDate_%i", nestID];
    int count = [[[SystemUtils getGameDataDelegate] getExtraInfo:key1] intValue];
    if(count==0) return 1;
    int today = [SystemUtils getTodayDate]+1;
    int lastDate = [[[SystemUtils getGameDataDelegate] getExtraInfo:key2] intValue];
    if(today!=lastDate) return 1;
    return count+1;
}

// 增加龙窝加速次数
int SNSFunction_addNestFastTimes(int nestID)
{
    NSString *key1 = [NSString stringWithFormat:@"nestTimes_%i", nestID];
    NSString *key2 = [NSString stringWithFormat:@"nestDate_%i", nestID];
    int count = [[[SystemUtils getGameDataDelegate] getExtraInfo:key1] intValue];
    int lastDate = [[[SystemUtils getGameDataDelegate] getExtraInfo:key2] intValue];
    int today = [SystemUtils getTodayDate]+1;
    if(today!=lastDate) {
        count = 0;
        [[SystemUtils getGameDataDelegate] setExtraInfo:[NSNumber numberWithInt:today] forKey:key2];
    }
    [[SystemUtils getGameDataDelegate] setExtraInfo:[NSNumber numberWithInt:count+1] forKey:key1];
    return count+1;
}

// 获得累计的付费金额，单位是美分
int SNSFunction_getTotalPayment()
{
    return [[SnsStatsHelper helper] getTotalPay];
}

// 重置存档
void SNSFunction_resetGameData()
{
    [[SnsServerHelper helper] resetSaveDataOnServer];
}

// 显示offer广告: flurry, arriki
void SNSFunction_showAdOffer(const char *offerType)
{
    [[SnsGameHelper helper] showOfferWall:[NSString stringWithUTF8String:offerType]];
}

// 是否可以显示广告
bool SNSFunction_isAdVisible()
{ 
    if([SystemUtils isAdVisible]) return true;
    return false;
}
// 显示弹窗广告
void SNSFunction_showPopupAd()
{
    [[SnsGameHelper helper] showPopupOffer];
}


// 获取远程下载文件路径
const char *SNSFunction_getDownloadFilePath(const char *fileName)
{
    NSString *file = [NSString stringWithUTF8String:fileName];
    NSString *path = [[SystemUtils getItemImagePath] stringByAppendingPathComponent:file];
    return [path UTF8String];
}

// 检查远程文件是否存在
bool SNSFunction_isDownloadFileExists(const char *fileName)
{
    NSString *file = [NSString stringWithUTF8String:fileName];
    NSString *path = file;
    if(fileName[0]!='/') path = [[SystemUtils getItemImagePath] stringByAppendingPathComponent:file];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) return false;
    /*
    const char *p = fileName;
    if(fileName[0]=='/') {
        int pos = strlen(fileName)-1;
        while(fileName[pos]!='/') {
            if(pos==0) break;
            pos--;
        }
        // skip '/'
        if(pos>0) pos++;
        p = fileName+pos;
    }
    NSString *fname = [NSString stringWithUTF8String:p];
    if(![[SnsGameHelper helper] isRemoteFileLoaded:fname]) return false;
     */
    return true;
}

//获取远程下载目录路径
const char * SNSFunction_getDownloadFolderPath(){
    return [[SystemUtils getItemImagePath] UTF8String];
}

//获取远程下载目录子目录文件名路径
const char * SNSFunction_getDownloadSubFolderFilePath(const char* subFolder, const char* fileName){
    NSString *file = [NSString stringWithUTF8String:subFolder];
    NSString *path = [[SystemUtils getItemImagePath] stringByAppendingPathComponent:file];
    file = [NSString stringWithUTF8String:fileName];
    path = [path stringByAppendingPathComponent:file];
    
    return [path UTF8String];
    
}

// 获取远程配置参数,没有就返回默认值0
int SNSFunction_getRemoteConfigInt(const char *key)
{
    return [[SystemUtils getGlobalSetting:[NSString stringWithUTF8String:key]] intValue];
}
// 获取字符串配置参数, 没有就返回NULL
const char *SNSFunction_getRemoteConfigString(const char *key)
{
    NSString *val = [SystemUtils getGlobalSetting:[NSString stringWithUTF8String:key]];
    if(val==nil) return NULL;
    return [val UTF8String];
}
// 生成随机数
int SNSFunction_getRandom()
{
    static bool _isTwistInit = false;
    if(!_isTwistInit) {
        // mt_seed32new(1024);
        mt_seed();
    }
    
    // SNSLog(@"mt_rand: %d %d %d %d", mt_lrand(),mt_lrand(),mt_lrand(),mt_lrand());
    
    return mt_lrand();
}

// 显示力美广告墙
void SNSFunction_showFreeGemsOffer()
{
    NSString *list = [SystemUtils getGlobalSetting:@"kPopupOfferList"];
    NSString *vender = @"limei";
    if(list!=nil && [list length]>3) {
        NSArray *arr = [list componentsSeparatedByString:@","];
        static int idx = 0;
        NSString *str = [arr objectAtIndex:idx];
        if([str length]>2) vender = str;
        idx++;if(idx>=[arr count]) idx  = 0;
    }
    [[SnsGameHelper helper] showOfferWall:vender];
}
// 显示免费广告墙: 1-力美，2-domob, 3-youmi, 4-dianru, 5-adwo
void SNSFunction_showFreeGemsOfferOfType(int type)
{
    // int date = [SystemUtils getTodayDate];
    int now = [SystemUtils getCurrentTime];
    int days = (now+8*3600)/86400;
    /*
     for(int i=0;i<25;i++) {
     days = (now + i*3600)/86400;
     SNSLog(@"i:%d days:%d",i, days);
     }
     */
    NSArray *list = [NSArray arrayWithObjects:@"chukong",@"yijifen",@"adwo",@"waps",@"mobisage", nil];
    int num = [list count];
    int idx = (days + type)%num;
    
    NSString *vender = [list objectAtIndex:idx];
    /*
     NSString *list = [SystemUtils getGlobalSetting:@"kFreeGemsOfferList2"];
     if(list!=nil && [list length]>3) {
     NSArray *arr = [list componentsSeparatedByString:@","];
     NSString *st1 = [arr objectAtIndex:0];
     if(![st1 isEqualToString:@"nouse"]) type = type-1;
     if(type<=[arr count]) {
     NSString *str = [arr objectAtIndex:type];
     if([str length]>2) vender = str;
     }
     }
     */
    
    [[SnsGameHelper helper] showOfferWall:vender];
}

// 打开URL连接
void SNSFunction_openURL(const char *link)
{
    [SystemUtils openAppLink:[NSString stringWithCString:link encoding:NSASCIIStringEncoding]];
}

// 去评分
void SNSFunction_toRateIt()
{
    NSString *link = [SystemUtils getAppRateLink];
    if(link) {
        NSURL *url = [NSURL URLWithString:link];
        [[UIApplication sharedApplication] openURL:url];
    }
}

// 获取上次评分时间, 如果是首次打开游戏，返回0
int SNSFunction_getLastRateTime()
{
    return [[SystemUtils getNSDefaultObject:@"kLastRateTime"] intValue];
}

// 设置评分时间
void SNSFunction_setLastRateTime()
{
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:[SystemUtils getCurrentTime]] forKey:@"kLastRateTime"];
}

// 获得新通知数量
int SNSFunction_getNewNoticeCount()
{
    return [SystemUtils getPromotionNoticeUnreadCount];
}
// 显示通知
void SNSFunction_showNoticePopup()
{
    [SystemUtils showPromotionNotice];
}

// 显示弹窗广告
void SNSFunction_showCNPopupOffer()
{
    // int uid = [[SystemUtils getCurrentUID] intValue];
    int now = [SystemUtils getCurrentTime];
    int days = (now+8*3600)/86400;
    NSArray *list = [NSArray arrayWithObjects:@"chukongPopup",@"yijifenPopup",@"adwoPopup",@"wapsPopup",@"mobisagePopup", nil];
    int num = [list count];
    int idx = (rand()+days)%num;
    NSString *vender = [list objectAtIndex:idx];
    [SystemUtils showPopupOfferOfType:vender];
}


