//
//  SystemUtils.m
//  ZombieFarm
//
//  Created by LEON on 11-6-18.
//  Copyright 2011 playforge. All rights reserved.
//

#import <sys/sysctl.h>
#include <sys/socket.h> // Per msqr
#include <net/if.h>
#include <net/if_dl.h>
#include <sys/xattr.h>
#include <mach/mach_time.h>
#import <AudioToolbox/AudioServices.h>

#import <CommonCrypto/CommonDigest.h>
#import "SNSLogType.h"

#import "SystemUtils.h"
#import "StringUtils.h"
#import "ZipArchive.h"
#import "SBJson.h"
#import "NetworkHelper.h"
#import "InAppStore.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"
#ifndef SNS_DISABLE_FLURRY_V1
#import "FlurryHelper.h"
#endif
#ifdef SNS_ENABLE_FLURRY_V2
#import "FlurryHelper2.h"
#endif
#import "smPopupWindowQueue.h"
#import "smPopupWindowNotice.h"
#import "smPopupWindowImageNotice.h"
#ifndef SNS_DISABLE_TAPJOY
#import "TapjoyHelper.h"
#endif
#import "SendEmailViewController.h"
#import "SnsServerHelper.h"
#import "CrashReportOperation.h"
#import "SNSAlertView.h"
#import "ItemLoadOperation.h"
#import "SnsStatsHelper.h"
#import "FacebookHelper.h"
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
#import "SNSPromotionViewController.h"
#endif

#ifndef SNS_DISABLE_CHARTBOOST
#import "ChartBoostHelper.h"
#endif
#ifndef SNS_DISABLE_BONUS_WINDOW
#import "smPopupWindowBonusCollection.h"
#endif
#ifndef SNS_DISABLE_PLAYHAVEN
#import "PlayHavenHelper.h"
#endif
#import "SNSGameStat.h"
#ifndef SNS_DISABLE_GREYSTRIPE
#import "GreystripeHelper.h"
#endif
#import "StatSendOperation.h"
#ifndef MODE_COCOS2D_X
#import "cocos2d.h"
#endif
#ifndef SNS_DISABLE_CHARTBOOST
#import "ChartBoost.h"
#endif
#ifndef SNS_DISABLE_ADCOLONY
#import "AdColonyHelper.h"
#endif
#ifdef SNS_ENABLE_LIMEI
#import "LiMeiHelper.h"
#endif
#ifdef SNS_ENABLE_LIMEI2
#import "LiMeiHelper2.h"
#endif

#ifndef SNS_DISABLE_DAILY_PRIZE
#import "smPopupWindowDailyAwards.h"
#endif

#ifdef SNS_ENABLE_TINYMOBI
#import "TinyMobiHelper.h"
#endif

#ifdef SNS_ENABLE_APPDRIVER
#import "AppDriverHelper.h"
#endif
#ifdef SNS_ENABLE_AARKI
#import "AarkiHelper.h"
#endif
#ifdef SNS_ENABLE_SPONSORPAY
#import "SponsorpayHelper.h"
#endif
#ifdef SNS_ENABLE_APPLOVIN
#import "AppLovinHelper.h"
#endif
#ifdef SNS_ENABLE_MDOTM
#import "MdotMHelper.h"
#endif
#ifdef SNS_ENABLE_GUOHEAD
#import "MixGHHelper.h"
#endif
#ifdef SNS_ENABLE_DOMOB
#import "DomobHelper.h"
#endif
#ifdef SNS_ENABLE_YOUMI
#import "YoumiHelper.h"
#endif
#ifdef SNS_ENABLE_DIANRU
#import "DianruHelper.h"
#endif
#ifdef SNS_ENABLE_ADWO
#import "AdwoHelper.h"
#endif
#ifdef SNS_ENABLE_TAPJOY2
#import "TapjoyHelper2.h"
#endif
#ifdef SNS_ENABLE_IAD
#import "iAdHelper.h"
#endif
#ifdef SNS_ENABLE_CHUKONG
#import "ChukongHelper.h"
#endif
#ifdef SNS_ENABLE_YIJIFEN
#import "YijifenHelper.h"
#endif
#ifdef SNS_ENABLE_WAPS
#import "WapsHelper.h"
#endif
#ifdef SNS_ENABLE_MOBISAGE
#import "MobiSageHelper.h"
#endif

#import "TinyiMailHelper.h"

#define kDeviceIDKey   @"_deviceID"
#define kDeviceTypeKey @"_deviceType"
#define kDeviceModeKey @"_deviceMode"
#define kCurrentLanguageKey  @"_currentLanguage"
#define kCountryCodeKey      @"_countryCode"
#define kDeviceTokenKey @"_deviceToken"
#define kDocumentRootPath @"_kDocumentRootPath"
#define kServerRootPath @"_kServerRootPath"
#define kAppBundlePath  @"kAppBundlePath"

#define kPendingGameResource  @"kPendingGameResource"
#define kPendingIAPItem       @"kPendingIAPItem"
#define kLastLoginDate        @"kLastLoginDate"
#define kLoginDateCount       @"kLoginDateCount"

#define kFileDigestKey  @"lwe23347212316423dfs3"

#define kInstallTime           @"kInstallTime"

@implementation NSNull(SNSTypeConversion)

- (int) intValue { return 0; }
- (float) floatValue { return 0; }
- (double) doubleValue { return 0; }
- (BOOL) boolValue { return NO; }

@end

@implementation SystemUtils

static NSMutableDictionary *_systemInfo = nil;
static NSMutableDictionary *_globalConfig = nil;
static NSDictionary *_langInfo = nil;
static NSDictionary *_digestInfo = nil;
static NSMutableDictionary *_playerSetting = nil;
static int timeDiff = 0;
static int g_deviceTimeDiff = 0;
static NSString *currentUserID = @"0";
static SendEmailViewController *_emailController = nil;
static BOOL isAppTerminated = NO;
static id appDelegate = nil;

static NSObject<GameDataDelegate> *_currentGameDataDelegate = nil;

static int _alertViewCount = 0;

static int _gInstallTime    = 0;

static SNSGameStat *_gameStatsTotal = nil;
static SNSGameStat *_gameStatsToday = nil;
static UIViewController  *_gSNSRootViewController = nil;
static NSString *_sysPendingCommand = nil;

#pragma mark access static variable

//Raw mach_absolute_times going in, difference in seconds out
+ (double) getTimeSinceSystemBoot
{
    uint64_t difference = mach_absolute_time();
    static double conversion = 0.0;
    
    if( conversion == 0.0 )
    {
        mach_timebase_info_data_t info;
        kern_return_t err = mach_timebase_info( &info );
        
		//Convert the timebase into seconds
        if( err == 0  )
			conversion = 1e-9 * (double) info.numer / (double) info.denom;
    }
    
    return conversion * (double) difference;
}


+ (BOOL) isAppAlreadyTerminated
{
    return isAppTerminated;
}


// 设置游戏存档对象
+ (void)setGameDataDelegate:(NSObject<GameDataDelegate>*)obj
{
    if(_currentGameDataDelegate == obj) return;
    SNSLog(@"set delegate %@, trace:%@", obj, [self getStackTraceInfo]);
    _currentGameDataDelegate = obj;
    if(!obj) return;
	
	// 检查安装时间
	int time = [self getInstallTime];
	int time2 = [[obj getExtraInfo:kInstallTime] intValue];
	if(time2 > 0 && time2 < time) {
		[self setGlobalSetting:[NSNumber numberWithInt:time2] forKey:kInstallTime];
		_gInstallTime = time2;
	}
	else {
		[obj setExtraInfo:[NSNumber numberWithInt:time] forKey:kInstallTime];
	}
#ifdef DEBUG
	// 设置测试用户标志
	[obj setExtraInfo:[NSNumber numberWithInt:1] forKey:@"kTestUser"];
#endif
	
    NSDictionary *info = [self getPlayerDefaultSetting:kPendingGameResource];
    if(info) {
        int val = [[info objectForKey:@"coin"] intValue];
        if(val>0) [self addGameResource:val ofType:kGameResourceTypeCoin];
        val = [[info objectForKey:@"leaf"] intValue];
        if(val>0) [self addGameResource:val ofType:kGameResourceTypeLeaf];
        val = [[info objectForKey:@"exp"] intValue];
        if(val>0) [self addGameResource:val ofType:kGameResourceTypeExp];
        NSString *str = [info objectForKey:@"iapCoin"];
        if(str) {
            NSArray *arr = [str componentsSeparatedByString:@","];
            for (int i=0; i<[arr count]; i++) {
                val = [[arr objectAtIndex:i] intValue];
                [self addGameResource:val ofType:kGameResourceTypeIAPCoin];
            }
        }
        str = [info objectForKey:@"iapLeaf"];
        if(str) {
            NSArray *arr = [str componentsSeparatedByString:@","];
            for (int i=0; i<[arr count]; i++) {
                val = [[arr objectAtIndex:i] intValue];
                [self addGameResource:val ofType:kGameResourceTypeIAPLeaf];
            }
        }
        [self removePlayerSetting:kPendingGameResource saveToFile:YES];
    }
    NSDictionary *info2 = [self getPlayerDefaultSetting:kPendingIAPItem];
    if(info2 && [info2 isKindOfClass:[NSDictionary class]] && [_currentGameDataDelegate respondsToSelector:@selector(onBuyIAPItem:withCount:)]) {
        for(NSString *key in info2.allKeys) {
            int count = [[info2 objectForKey:key] intValue];
            NSArray *arr = [key componentsSeparatedByString:@"|"];
            NSString *itemName = [arr objectAtIndex:0];
            int itemCount = [[arr objectAtIndex:1] intValue];
            for(int i=0;i<count;i++) {
                [_currentGameDataDelegate onBuyIAPItem:itemName withCount:itemCount];
            }
        }
        [self removePlayerSetting:kPendingIAPItem saveToFile:YES];
        
    }
    
}

// 获得游戏存档对象
+ (NSObject<GameDataDelegate> *)getGameDataDelegate
{
    return _currentGameDataDelegate;
}

// 用子版本配置参数覆盖默认参数
+ (void) setSubVersionSystemInfo
{
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    NSArray *arr = [bundleID componentsSeparatedByString:@"."];
    bundleID = [arr objectAtIndex:[arr count]-1];
    NSString *key = [bundleID stringByAppendingString:@"Config"];
    // SNSLog(@"key=%@", key);
    NSDictionary *info = [_systemInfo objectForKey:key];
    if(!info) return;
    SNSLog(@"set subConfig:%@", info);
    arr = [info allKeys];
    for(int i=0;i<[arr count]; i++)
    {
        key = [arr objectAtIndex:i];
        [_systemInfo setObject:[info objectForKey:key] forKey:key];
        if([key isEqualToString:@"subVerIAPPrefix"])
        {
            NSString *val = [_systemInfo objectForKey:kIapItemPrefix];
            if(val) {
                val = [NSString stringWithFormat:@"%@%@",[info objectForKey:key], val];
                [_systemInfo setObject:val forKey:kIapItemPrefix];
            }
        }
    }
    
}

+ (NSMutableDictionary *)systemInfo
{
	@synchronized(self) {
		if(!_systemInfo) {
			_systemInfo = [[NSMutableDictionary alloc] init];
			// NSString *dictPath = [path stringByAppendingPathComponent:@"digest.plist"];
			NSString *path = [[NSBundle mainBundle] bundlePath];
			path = [path stringByAppendingPathComponent:@"SystemConfig.plist"];
			NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
			if(dict) {
				[_systemInfo addEntriesFromDictionary:dict];
				//NSLog(@"load default system info %@", _systemInfo);
#ifdef DEBUG
                // NSLog(@"SystemConfig.plist:\n%@\n", [dict JSONRepresentation]);
#endif
                [self setSubVersionSystemInfo];
			}
		}
	}
	return _systemInfo;
}


+ (NSDictionary *)digestInfo
{
	@synchronized(self) {
		if(!_digestInfo) {
			NSString *path = [[NSBundle mainBundle] bundlePath];
			path = [path stringByAppendingPathComponent:@"digest.plist"];
			_digestInfo = [[NSDictionary alloc] initWithContentsOfFile:path];
		}
	}
	return _digestInfo;
}

+ (void) correctCurrentTime
{
    int now = [self getCurrentTime];
    int lastSaveTime = [[self getNSDefaultObject:@"kLastExitTime"] intValue];
    // 上次保存时间如果比现在小，并且与上次退出不超过10分钟，就是正常的，不用修正
    if(lastSaveTime < now && lastSaveTime+600 > now) return;
    int deviceTime = [[NSDate date] timeIntervalSince1970];
    // 上次保存时间如果比设备时间还大，就不用修正
    if(lastSaveTime > deviceTime) return;
    // 修正为设备时间
    g_deviceTimeDiff = 0;
    [self setServerTime:deviceTime];
}

+ (void) saveDeviceTimeCheckPoint:(BOOL)reset
{
    int lastDeviceTime = [[_globalConfig objectForKey:@"kLDevTime"] intValue];
    int lastBootTime   = [[_globalConfig objectForKey:@"kLBootTime"] intValue];
    int nowDeviceTime = [[NSDate date] timeIntervalSince1970];
    int nowBootTime   = [self getTimeSinceSystemBoot];
    int kBgTaskTime = [[self getNSDefaultObject:@"kBgTaskTime"] intValue];
    if(reset || kBgTaskTime>300 || nowBootTime<=lastBootTime || lastBootTime==0) {
        // reboot detected
        [_globalConfig setObject:[NSNumber numberWithInt:nowDeviceTime] forKey:@"kLDevTime"];
        [_globalConfig setObject:[NSNumber numberWithInt:nowBootTime] forKey:@"kLBootTime"];
        lastDeviceTime = nowDeviceTime; lastBootTime = nowBootTime;
        if(!reset || kBgTaskTime>300) [self saveGlobalSetting];
    }
    // 设备时间与准确时间的差额
    g_deviceTimeDiff = (lastDeviceTime - lastBootTime + nowBootTime) - nowDeviceTime;
}

+ (NSMutableDictionary *)config
{
	@synchronized(self) {
		if(!_globalConfig) {
			// load from cache file
			NSString *cachePath = [self getCacheRootPath];
			NSString *cacheFile = [cachePath stringByAppendingPathComponent:@"globalInfo.dat"];
			if([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
                NSString *text = [NSString stringWithContentsOfFile:cacheFile encoding:NSUTF8StringEncoding error:nil];
                NSDictionary *dict = nil;
                if([text characterAtIndex:0]=='|') {
                    if([self verifySaveDataWithHash:text]) {
                        text = [self stripHashFromSaveData:text];
                        dict = [text JSONValue];
                    }
                    else 
                        text = nil;
                    
                }
                else {
                    // old version
                    if([self checkFileDigest:cacheFile])
                    {
                        dict = [text JSONValue];
                    }
                    else {
                        SNSLog(@"invalid globalInfo.dat"); // exit(0);
                    }
                }
                if(dict && [dict isKindOfClass:[NSDictionary class]]) {
                    _globalConfig = [NSMutableDictionary dictionaryWithDictionary:dict];
                    currentUserID = [dict objectForKey:@"userID"];
                    timeDiff = [[dict objectForKey:@"timeDelay"] intValue];
                    if(timeDiff < kMinTimeDiff) timeDiff = 0;
                }
                else {
                    SNSLog(@"%s: invalid globalInfo.dat:%@", __FUNCTION__, dict);
                }
			}
			if(_globalConfig) [_globalConfig retain];
			else {
				_globalConfig = [[NSMutableDictionary alloc] init];
                // currentUserID = [self getNSDefaultObject:@"SGUserID"];
			}
            if(currentUserID && ![currentUserID isKindOfClass:[NSString class]])
                currentUserID = [NSString stringWithFormat:@"%@", currentUserID];
            if(currentUserID && [currentUserID isEqualToString:@"(null)"])
                currentUserID = nil;
            if(currentUserID) 
                [currentUserID retain];
            else 
                currentUserID = @"0";
            
            // set time point
            [self saveDeviceTimeCheckPoint:NO];
		}
        
        [self relocateCachePath];
	}
	return _globalConfig;
}


+ (NSMutableDictionary *)playerSetting
{
	[self config];
	NSString *uid = [SystemUtils getCurrentUID];
	@synchronized(self) {
		if(!_playerSetting) {
			// load from cache file
			NSString *fileName = [NSString stringWithFormat:@"setting-%@.dat", uid];
			
			NSString *cachePath = [self getCacheRootPath];
			NSString *cacheFile = [cachePath stringByAppendingPathComponent:fileName];
			if(![[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
				cacheFile = [cachePath stringByAppendingPathComponent:@"setting-0.dat"];
			}
			if([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
				NSError *err = nil;
				NSString *text = [NSString stringWithContentsOfFile:cacheFile encoding:NSUTF8StringEncoding error:&err ];
                NSDictionary *dict = nil;
                if([text characterAtIndex:0]=='|') {
                    if([self verifySaveDataWithHash:text])
                    {
                        text = [self stripHashFromSaveData:text];
                        dict = [text JSONValue];
                    }
                }
                else {
                    if([self checkFileDigest:cacheFile])
                        dict = [text JSONValue];
                }
				if(dict && [dict isKindOfClass:[NSDictionary class]]) {
					_playerSetting = [NSMutableDictionary dictionaryWithDictionary:dict];
				}
				else {
					SNSLog(@"%s: invalid setting.dat:%@", __FUNCTION__, dict);
				}
			}
			else {
				SNSLog(@"%s: %@ not exists", __FUNCTION__, cacheFile);
			}
			if(_playerSetting) {
				[_playerSetting retain];
			}
			else {
				_playerSetting = [[NSMutableDictionary alloc] init];
			}
			//NSLog(@"playerSetting:%@", _playerSetting);
		}
	}
	return _playerSetting;
}

// appDelegate
+ (void)setAppDelegate:(id)delegate
{
	appDelegate = delegate;
}

+ (id)getAppDelegate
{
	return appDelegate;
}

#pragma mark -

#pragma mark systemInfo

// 获取系统信息
+(id)getSystemInfo:(NSString *)key
{
	return [[self systemInfo] objectForKey:key];
}

// clearUp system info
+ (void)cleanUpStaticInfo
{
    if(isAppTerminated) return;
    isAppTerminated = YES;
    
#ifndef SNS_DISABLE_FACEBOOK
    if([[SystemUtils getiOSVersion] compare:@"5.0"]<0) {
        [[FacebookHelper helper] closeSession];
    }
#endif
    /*
	[[NetworkHelper helper] release];
	[[InAppStore store] release];
	[[TapjoyHelper helper] release];
	[[FlurryHelper helper] release];
     */
	[_globalConfig release]; _globalConfig = nil;
	[_systemInfo release]; _systemInfo = nil;
	[_digestInfo release]; _digestInfo = nil;
	[_gameStatsTotal release]; _gameStatsTotal = nil;
    [_gameStatsToday release]; _gameStatsToday = nil;
	[_playerSetting release]; _playerSetting = nil;
	[_emailController release]; _emailController = nil;
    [currentUserID release]; currentUserID = nil;
	// [[FlurryHelper helper] release];
}


+ (NSString*)getDeviceModel
{
	NSMutableDictionary *dict = [self systemInfo];
	NSString *_deviceModel = [dict objectForKey:kDeviceModeKey];
	if(!_deviceModel) {
		size_t size;
		sysctlbyname("hw.machine", NULL, &size, NULL, 0);
		char *machine = malloc(size);
		sysctlbyname("hw.machine", machine, &size, NULL, 0);
		/*
		for(int i=0;i<size;i++) {
			if(machine[i]==',') machine[i] = '-';
		}
		 */
		_deviceModel = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
		[dict setObject:_deviceModel forKey:kDeviceModeKey];
		// [_deviceModel retain];
		SNSLog(@"device model: %@", _deviceModel);
		
		//分配了内存要记得free啊⋯⋯唉
		free(machine);
		/*
		 NSString *platform = [self platform];
		 if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
		 if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
		 if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
		 if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
		 if ([platform isEqualToString:@"iPhone3,2"])    return @"Verizon iPhone 4";
		 if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
		 if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
		 if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
		 if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
		 if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
		 if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
		 if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
		 if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
		 if ([platform isEqualToString:@"i386"])         return @"Simulator";
		 return platform;
		 */
	}
	return _deviceModel;
}


+ (NSString*)getDeviceType
{
	NSString *platform = [self getDeviceModel];
	if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
	if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
	if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
	if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
	if ([platform isEqualToString:@"iPhone3,2"])    return @"Verizon iPhone 4";
	if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
	if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
	if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
	if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
	if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
	if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
	if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
	if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
	if ([platform isEqualToString:@"i386"])         return @"Simulator";
	//NSArray *arr = [platform componentsSeparatedByString:@","];
	//NSString *model = [arr objectAtIndex:0];
	//return [arr objectAtIndex:0];
	return platform;
}
// check if this device is iPad
int g_SysUtilDeviceType = 0; // 0-unknown, 1-iPhone, 2-iPad, 3-iPod
+ (BOOL)isiPad
{
    if(g_SysUtilDeviceType>0) {
        if(g_SysUtilDeviceType==2) return YES;
        return NO;
    }
    if([[self getSystemInfo:@"kiPhoneOnly"] intValue]==1) {
        g_SysUtilDeviceType = 1;
        return NO;
    }
    
	NSString *deviceType = [self getDeviceType];
    SNSLog(@"deviceType:%@",deviceType);
	if([[deviceType substringToIndex:4] isEqualToString:@"iPad"]) {
        g_SysUtilDeviceType = 2;
        return YES;
    }
	if([[deviceType substringToIndex:4] isEqualToString:@"iPho"]) {
        g_SysUtilDeviceType = 1;
        return NO;
    }
	if([[deviceType substringToIndex:4] isEqualToString:@"iPod"]) {
        g_SysUtilDeviceType = 3;
        return NO;
    }
	
    if([deviceType isEqualToString:@"x86_64"]) {
        CGRect bound = [[UIScreen mainScreen] bounds];
        SNSLog(@"size:%.0fx%.0f",bound.size.width,bound.size.height);
        if(bound.size.width>320) {
            g_SysUtilDeviceType = 2;
            return YES;
        }
    }
    g_SysUtilDeviceType = 3;
	return NO;
}
// check if is iPhone5
+ (BOOL) isiPhone5Screen
{
    if([self isiPad]) return NO;
	// check screen size
	CGRect mainFrame = [[UIScreen mainScreen] bounds];
	if(mainFrame.size.width == 568 || mainFrame.size.height == 568) return YES;
    return NO;
}

// check if is retina
+ (BOOL) isRetina
{
	// if([self isiPad]) return NO;
	if ([UIScreen instancesRespondToSelector:@selector(scale)]) 
	{
		CGFloat scale = [[UIScreen mainScreen] scale];
		
		if (scale > 1.0) 
		{
			//iphone retina screen
			return YES;
		}
	}	
	return NO;
}

// iOS version
+ (NSString *) getiOSVersion
{
	return [UIDevice currentDevice].systemVersion;
}

+ (NSString*)getDeviceID
{
	NSString *udid = [self getMACAddress];
	//if(!udid) udid = [UIDevice currentDevice].uniqueIdentifier;
	return udid;
}

+ (int) getInstallTime
{
	if(_gInstallTime>0) return _gInstallTime;
	
	_gInstallTime = [[self getGlobalSetting:kInstallTime] intValue];
	if(_gInstallTime>0) return _gInstallTime;
	
	NSString *path = [[NSBundle mainBundle] bundlePath];
	NSDictionary *info = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
	NSDate *createDate = [info fileCreationDate];
	_gInstallTime = [createDate timeIntervalSince1970];
	[self setGlobalSetting:[NSNumber numberWithInt:_gInstallTime] forKey:kInstallTime];
	return _gInstallTime;
}


+ (NSString*)getMACAddress
{
	int                 mib[6];
	size_t              len;
	char                *buf;
	unsigned char       *ptr;
	struct if_msghdr    *ifm;
	struct sockaddr_dl  *sdl;
	
	mib[0] = CTL_NET;
	mib[1] = AF_ROUTE;
	mib[2] = 0;
	mib[3] = AF_LINK;
	mib[4] = NET_RT_IFLIST;
	
	if ((mib[5] = if_nametoindex("en0")) == 0) 
	{
		SNSLog(@"Error: if_nametoindex error\n");
		return NULL;
	}
	
	if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
	{
		SNSLog(@"Error: sysctl, take 1\n");
		return NULL;
	}
	
	if ((buf = malloc(len)) == NULL) 
	{
		SNSLog(@"Could not allocate memory. error!\n");
		return NULL;
	}
	
	if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) 
	{
		SNSLog(@"Error: sysctl, take 2");
		return NULL;
	}
	
	ifm = (struct if_msghdr *)buf;
	sdl = (struct sockaddr_dl *)(ifm + 1);
	ptr = (unsigned char *)LLADDR(sdl);
	NSString *macAddress = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X", 
							*ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
	macAddress = [macAddress lowercaseString];
	free(buf);
	
    NSString *macPrefix = [self getSystemInfo:@"kHMACPrefix"];
    if(macPrefix!=nil)
        return [macPrefix stringByAppendingString:macAddress];
    
	return macAddress;
}

+ (NSString*)getOriginalMACAddress
{
	int                 mib[6];
	size_t              len;
	char                *buf;
	unsigned char       *ptr;
	struct if_msghdr    *ifm;
	struct sockaddr_dl  *sdl;
	
	mib[0] = CTL_NET;
	mib[1] = AF_ROUTE;
	mib[2] = 0;
	mib[3] = AF_LINK;
	mib[4] = NET_RT_IFLIST;
	
	if ((mib[5] = if_nametoindex("en0")) == 0)
	{
		SNSLog(@"Error: if_nametoindex error\n");
		return NULL;
	}
	
	if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
	{
		SNSLog(@"Error: sysctl, take 1\n");
		return NULL;
	}
	
	if ((buf = malloc(len)) == NULL)
	{
		SNSLog(@"Could not allocate memory. error!\n");
		return NULL;
	}
	
	if (sysctl(mib, 6, buf, &len, NULL, 0) < 0)
	{
		SNSLog(@"Error: sysctl, take 2");
		return NULL;
	}
	
	ifm = (struct if_msghdr *)buf;
	sdl = (struct sockaddr_dl *)(ifm + 1);
	ptr = (unsigned char *)LLADDR(sdl);
	NSString *macAddress = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X",
							*ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
	macAddress = [macAddress lowercaseString];
	free(buf);
	
	return macAddress;
}
+ (NSDictionary *)getDeviceInfo
{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    [info setObject:[self getDeviceModel] forKey:@"model"];
    [info setObject:[self getDeviceType] forKey:@"type"];
    [info setObject:[self getiOSVersion] forKey:@"osVer"];
    [info setObject:[self getDeviceID] forKey:@"ID"];
    [info setObject:[self getClientVersion] forKey:@"clientVer"];
    [info setObject:[self getCountryCode] forKey:@"country"];
    [info setValue:[NSNumber numberWithBool:[self isiPad]] forKey:@"iPad"];
    [info setObject:[self getCurrentLanguage] forKey:@"lang"];
    [info setObject:[self getMACAddress] forKey:@"hmac"];
    // [info setObject:[self getCurrentUserID] forKey:@"uid"];
    return info;
}
// get device name
+ (NSString *)getDeviceName
{
    return [UIDevice currentDevice].name;
}

+(NSString *)getIDFA
{
    if([[SystemUtils getiOSVersion] compare:@"6.0"]>=0) {
        if([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) {
            NSString *idfa = [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
            if([idfa isEqualToString:@"00000000-0000-0000-0000-000000000000"]) idfa = @"";
            return idfa;
        }
    }
    return @"";
}
+ (NSString *) getIDFV
{
    if([[SystemUtils getiOSVersion] compare:@"6.0"]>=0) {
        NSString *idfv  = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        if([idfv isEqualToString:@"00000000-0000-0000-0000-000000000000"]) idfv = @"";
        return idfv;
    }
    return @"";
}

// 获取当前UID
+ (NSString *)getCurrentUID
{
    return currentUserID;
}
// 设置当前UID
+ (void) setCurrentUID:(NSString *)uid
{
    if(!uid || [uid intValue]==0) return;
    if(currentUserID && [currentUserID isEqualToString:uid]) return;
    if(currentUserID && ![currentUserID isEqualToString:@"0"])
    {
		// clear user related info
		[self saveGameStat];
		[_gameStatsTotal release]; _gameStatsTotal = nil;
        [_gameStatsToday release]; _gameStatsToday = nil;
        [_playerSetting release]; _playerSetting = nil;
        [currentUserID release];
    }
    currentUserID = [uid retain];
    [self setGlobalSetting:uid forKey:@"userID"];
    [self setNSDefaultObject:uid forKey:@"SGUserID"];
    [self playerSetting];
    [[SnsStatsHelper helper] setCurrentUID:uid];
    [self resetGameStats];
}

+ (int) getCurrentUserID
{
	return [currentUserID intValue];
}

+ (void) setCurrentUserID:(int)userID
{
    if(userID<=0) return;
    [self setCurrentUID:[NSString stringWithFormat:@"%i", userID]];
}



// sessionKey
+ (NSString *)getSessionKey
{
	NSString *sessionKey = [self getPlayerDefaultSetting:kSessionKeyID];
	if(!sessionKey || [sessionKey length]<3) {
		sessionKey = [self getGlobalSetting:kSessionKeyID];
		if(sessionKey && [sessionKey length]>=3) {
			[self setPlayerDefaultSetting:sessionKey forKey:kSessionKeyID];
		}
	}
	return sessionKey;
}
// clear sessionKey
+ (void) clearSessionKey
{
    [self setGlobalSetting:@"" forKey:kSessionKeyID];
    [self setPlayerDefaultSetting:@"" forKey:kSessionKeyID];
}


// get language
+ (NSString *)getCurrentLanguage
{
	// NSMutableDictionary *dict = [self systemInfo];
	// NSString *lang = [dict objectForKey:kCurrentLanguageKey];
    NSString *lang = [self getSystemInfo:@"kUseSingleLanguage"];
	if(!lang || [lang length]<2) {
		NSArray *languages = [self getNSDefaultObject:@"AppleLanguages"];
		lang = [languages objectAtIndex:0]; 
		// [language retain];
		// [dict setObject:lang forKey:kCurrentLanguageKey];
	}
	return lang;
}

// get country
+ (NSString *)getCountryCode
{
	NSMutableDictionary *dict = [self systemInfo];
	NSString *country = [dict objectForKey:kCountryCodeKey];
	if(!country) {
		country = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
        if(country==nil) {
            NSLocale *loc = [NSLocale systemLocale];
            country = [loc objectForKey:NSLocaleCountryCode];
            // SNSLog(@"%@",country);
            if(country==nil) country = @"US";
        }
		// [country retain];
		//[dict setObject:country forKey:kCountryCodeKey];
	}
	return country;
}

// get original country code
+ (NSString *)getOriginalCountryCode
{
	NSMutableDictionary *dict = [self config];
	NSString *country = [dict objectForKey:@"origCountry"];
    if(!country) 
        country = [self getSystemInfo:@"kUseSingleCountry"];
	if(!country || [country length]<2) {
		country = [self getCountryCode];
		[self setGlobalSetting:country forKey:@"origCountry"];
	}
	return country;
}

// set device Token
+ (void)setDeviceToken:(NSString *)token
{
	[self setGlobalSetting:token forKey:kDeviceTokenKey];
	// NSMutableDictionary *dict = [self systemInfo];
	// [dict setObject:token forKey:kDeviceTokenKey];
}

// get device token
+ (NSString *)getDeviceToken
{
	// NSMutableDictionary *dict = [self systemInfo];
	// return [dict objectForKey:kDeviceTokenKey];
	return [self getGlobalSetting:kDeviceTokenKey];
}


+ (NSString *)getBundleVersion
{
    return [self getClientVersion];
}

// get client version
+ (NSString *)getClientVersion
{
	NSString *bundleVer = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    if(bundleVer==nil || [bundleVer length]==0) bundleVer = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
#ifdef DEBUG
    return [bundleVer stringByAppendingString:@"D"];
#else
    return bundleVer;
#endif
    /*
    int i = 0;
    for(i=0;i<[bundleVer length];i++)
    {
        char ch = [bundleVer characterAtIndex:i];
        if(ch=='.' || (ch>='0' && ch<='9')) continue;
        break;
    }
    if(i== [bundleVer length]) return bundleVer;
    return [bundleVer substringToIndex:i];
     */
}
// get version info
+ (NSString *)getVersionInfo
{
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;
    // NSLog(@"bundle info:%@", info);
    // NSLog(@"app version: %@(%@)", [info objectForKey:@"CFBundleVersion"], [info objectForKey:@"CFBundleShortVersionString"]);
    NSString *str = [NSString stringWithFormat:@"V%@(%@)",[info objectForKey:@"CFBundleShortVersionString"], [info objectForKey:@"CFBundleVersion"]];
    return str;
}


// 获取下载配置文件列表
+ (NSArray *) getLoadedConfigFileNames
{
    NSDictionary *dict = [self getSystemInfo:kRemoteConfigFileDict];
    if(dict && [dict isKindOfClass:[NSDictionary class]] && [dict count]>0) return [dict allValues];
	return [self getSystemInfo:kRemoteConfigFiles];
	// return [NSArray arrayWithObjects:@"combinedata", @"leveldata", @"itemdata", @"extdata", nil];
}

// 获取游戏的屏幕横竖设置
+ (UIDeviceOrientation) getGameOrientation
{
	NSString *direction = [self getSystemInfo:kGameOrientation];
	if(!direction || [direction length]<3) return UIDeviceOrientationPortrait;
	if([direction isEqualToString:@"LandscapeRight"]) return UIDeviceOrientationLandscapeRight;
	if([direction isEqualToString:@"Landscape"] || [direction isEqualToString:@"LandscapeLeft"]) return UIDeviceOrientationLandscapeLeft;
	return UIDeviceOrientationPortrait;
}

#pragma mark -

#pragma mark serverName

// get server name
+ (NSString *) getServerName
{
	NSString *key = kGameServerGlobal;
	NSString *country = [self getOriginalCountryCode];
	if([country isEqualToString:@"CN"]) key = kGameServerChina;
#ifdef SNS_CHINESE_VERSION_ONLY
    key = kGameServerChina;
#endif
    int useBackup = [[self getNSDefaultObject:@"kUseBackupServer"] intValue];
    if(useBackup==1) {
        NSString *key2 = [key stringByAppendingString:@"Backup"];
        if([self getSystemInfo:key2]!=nil) key = key2;
    }
	return [self getSystemInfo:key];
}

// get download server name
+ (NSString *) getDownloadServerName
{
    NSString *serverList = [self getGlobalSetting:@"kDownloadServerList"];
    if([[self getCountryCode] isEqualToString:@"CN"]) {
        NSString *svr2 = [self getGlobalSetting:@"kDownloadServerListCN"];
        if(svr2!=nil && [svr2 length]>3) serverList = svr2;
    }
    if(serverList!=nil && [serverList length]>5) {
        NSArray *arr = [serverList componentsSeparatedByString:@","];
        if([arr count]==1) return [arr objectAtIndex:0];
        int idx = rand()%[arr count];
        return [arr objectAtIndex:idx];
    }
    
	NSString *key = kImageServerGlobal;
	NSString *country = [self getOriginalCountryCode];
	if([country isEqualToString:@"CN"]) key = kImageServerChina;
    int useBackup = [[self getNSDefaultObject:@"kUseBackupServer"] intValue];
    if(useBackup==1) {
        NSString *key2 = [key stringByAppendingString:@"Backup"];
        if([self getSystemInfo:key2]!=nil) key = key2;
    }
	return [self getSystemInfo:key];
}

/*
// get stat report server name
+ (NSString *) getStatServerName
{
	NSString *key = kStatServerGlobal;
	NSString *country = [self getOriginalCountryCode];
	if([country isEqualToString:@"CN"]) key = kStatServerChina;
	
	return [self getSystemInfo:key];
}
 */

// get feed image server name
+ (NSString *) getFeedImageServerName
{
	NSString *key = kFeedImageServerGlobal;
	// NSString *country = [self getOriginalCountryCode];
	// if([country isEqualToString:@"CN"]) key = kFeedImageServerChina;
    int useBackup = [[self getNSDefaultObject:@"kUseBackupServer"] intValue];
    if(useBackup==1) {
        NSString *key2 = [key stringByAppendingString:@"Backup"];
        if([self getSystemInfo:key2]!=nil) key = key2;
    }
	return [self getSystemInfo:key];
}
// get feed image link
+ (NSString *) getFeedImageLink:(NSString *)fileName
{
	NSString *server = [self getFeedImageServerName];
	return [NSString stringWithFormat:@"http://%@/feedImage/%@", server, fileName];
}
// get download link
+ (NSString *)getAppDownloadLink
{
	NSString *link = [self getGlobalSetting:kiTunesAppDownloadLink];
	if(!link || [link length]<10) link = [self getSystemInfo:kiTunesAppDownloadLink];
    if(!link || [link length]<10) {
        // generate by appID
        NSString *appID = [self getGlobalSetting:@"kiTunesAppID"];
        if(!appID || [appID length]<5) appID = [self getSystemInfo:@"kiTunesAppID"];
        if(appID) link = [NSString stringWithFormat:@"http://itunes.apple.com/us/app/id%@?ls=1&mt=8", appID];
    }
    if(!link) return nil;
    // replace /us/ with /cn/
    NSString *country = [[self getCountryCode] lowercaseString];
    if(![country isEqualToString:@"us"])
    {
        NSString *newStr = [NSString stringWithFormat:@"/%@/", country];
        link = [link stringByReplacingOccurrencesOfString:@"/us/" withString:newStr];
        SNSLog(@"%s: %@", __func__, link);
    }
	return link;
}

// get download link
+ (NSString *)getAppDownloadShortLink
{
    NSString *link = [self getGlobalSetting:kFacebookFeedLink];
    if(!link || [link length]<10) link = [self getSystemInfo:kFacebookFeedLink];
    if(link && [link length]>10) return link;
    return [self getAppDownloadLink];
}

// get rate link
+ (NSString *)getAppRateLink
{
	NSString *link = [self getGlobalSetting:kiTunesAppRateLink];
	if(!link || [link length]<10) link = [self getSystemInfo:kiTunesAppRateLink];
    if(!link || [link length]<10) {
        // generate by appID
        NSString *appID = [self getGlobalSetting:@"kiTunesAppID"];
        if(!appID || [appID length]<5) appID = [self getSystemInfo:@"kiTunesAppID"];
        if(appID) link = [NSString stringWithFormat:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&pageNumber=0&sortOrdering=1&type=Purple+Software&mt=8", appID];
    }
	return link;
}
// get flurry reward link
+ (NSString *)getFlurryRewardServerName
{
	// NSString *key = kFlurryCallbackServer;
	// NSString *country = [self getOriginalCountryCode];
	// if([country isEqualToString:@"CN"]) key = kFeedImageServerChina;
	NSString *server = [self getSystemInfo:kFlurryCallbackServer];
    if(!server) server = [self getSystemInfo:kGameServerGlobal];
    return server;
}
// get top click server name
+ (NSString *)getTopClickServerName
{
	NSString *key = kGameServerGlobal;
	return [self getSystemInfo:key];
}

#pragma mark -

#pragma mark filePath

// get topgame service root
+ (NSString *) getTopgameServiceRoot
{
    NSString *root = [self getGlobalSetting:@"kTopgameServiceRoot"];
    if(root==nil || [root length]<3) root = [self getSystemInfo:@"kTopgameServiceRoot"];
    return root;
}

// get server Root
+ (NSString *) getServerRoot
{
	NSMutableDictionary *dict = [self systemInfo];
	NSString *str = [dict objectForKey:kServerRootPath];
	if(!str) {
		str = [NSString stringWithFormat:@"http://%@/api/", [self getServerName]];
	}
	return str;
}

+ (NSString *) getSocialServerRoot
{
	return [NSString stringWithFormat:@"http://%@/sns/", [self getServerName]];
}

+ (void) setNoBackupPath:(NSString *)path
{
    NSString *osVer = [SystemUtils getiOSVersion];
    // if([osVer characterAtIndex:0]<'5') return;
    if([osVer compare:@"5.0"]>0 && [osVer compare:@"5.1"]<0) {
        // if([osVer isEqualToString:@"5.0"]) return;
        const char* filePath = [path fileSystemRepresentation];
        
        const char* attrName = "com.apple.MobileBackup";
        u_int8_t attrValue = 1;
        
        setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    }
    else if([osVer compare:@"5.1"]>=0) {
        NSError *error = nil;
        NSURL *url = [NSURL fileURLWithPath:path isDirectory:YES];
        BOOL success = [url setResourceValue: [NSNumber numberWithBool: YES]
                                      forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!success){
            SNSLog(@"Error excluding %@ from backup %@", path, error);
        }
        else {
            SNSLog(@"exclude %@ from backup success", path);
        }
    }
}

// upgrade path
+ (void) relocateCachePath
{
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    path = [path stringByDeletingLastPathComponent];
    NSString *cachePath = [path stringByAppendingPathComponent:@"Library/Caches"];
    NSString *itemPath = [cachePath stringByAppendingPathComponent:@"Items"];
    
    NSString *cachePath2 = [path stringByAppendingPathComponent:@"Documents/Cache"];
    NSString *itemPath2 = [cachePath2 stringByAppendingPathComponent:@"Items"];
    
    if([mgr fileExistsAtPath:itemPath]) {
        // move to documents
        if([mgr fileExistsAtPath:itemPath2]) [mgr removeItemAtPath:itemPath2 error:nil];
        [mgr moveItemAtPath:itemPath toPath:itemPath2 error:nil];
        
        NSString *confPath = [cachePath stringByAppendingPathComponent:@"Conf"];
        NSString *confPath2 = [path stringByAppendingPathComponent:@"Documents/Conf"];
        if([mgr fileExistsAtPath:confPath]) [mgr removeItemAtPath:confPath error:nil];
        [mgr moveItemAtPath:confPath toPath:confPath2 error:nil];
        
        // set attribute
        [self setNoBackupPath:itemPath2];
    }
    
}

+ (NSString *) getPathForiOS8
{
    NSArray *arr = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    // self.labelHint.text = [NSString stringWithFormat:@"%@", arr];
    NSURL *url = [arr lastObject];
    return url.path;
}

+ (NSString *) getLibraryCacheImagePath
{
    NSArray *arr = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    // self.labelHint.text = [NSString stringWithFormat:@"%@", arr];
    NSURL *url = [arr lastObject];
    return url.path;
}

// get document path
+ (NSString *)getDocumentRootPath
{
	NSMutableDictionary *dict = [self systemInfo];
	NSString *str = [dict objectForKey:kDocumentRootPath];
	if(!str) {
        /*
		NSString *path = [[NSBundle mainBundle] bundlePath];
		path = [path stringByDeletingLastPathComponent];
		path = [path stringByAppendingPathComponent:@"Documents"];
         */
        NSString *path = [self getPathForiOS8];
		NSString *cachePath = [path stringByAppendingPathComponent:@"Cache"];
		NSFileManager *mgr = [NSFileManager defaultManager]; NSError *err = nil;
		if(![mgr fileExistsAtPath:path]) [mgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];
		// [country retain];
		// path2 = [path2 stringByAppendingPathComponent:@"Image"];
		// if(![mgr fileExistsAtPath:path2]) [mgr createDirectoryAtPath:path2 withIntermediateDirectories:YES attributes:nil error:&err];
		str = path;			  
		[dict setObject:str forKey:kDocumentRootPath];
		if(![mgr fileExistsAtPath:cachePath]) {
			[mgr createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&err];
            [self setNoBackupPath:cachePath];
		}
		NSString *cachePath2 = [cachePath stringByAppendingPathComponent:@"Items"];
		if(![mgr fileExistsAtPath:cachePath2]) {
            [mgr createDirectoryAtPath:cachePath2 withIntermediateDirectories:YES attributes:nil error:&err];
        }        
		cachePath2 = [path stringByAppendingPathComponent:@"Conf"];
		if(![mgr fileExistsAtPath:cachePath2]) {
			[mgr createDirectoryAtPath:cachePath2 withIntermediateDirectories:YES attributes:nil error:&err];
		}
		
	}
	return str;
}

// get cache path
+ (NSString *)getCacheRootPath
{
	NSString *path = [self getDocumentRootPath];
	return [path stringByAppendingPathComponent:@"Cache"];
}

// get cache path
+ (NSString *)getCacheImagePath
{
	NSString *path = [self getCacheRootPath];
	path = [path stringByAppendingPathComponent:@"Image"];
	return path;
}

// get save path
+ (NSString *)getSaveRootPath
{
	NSString *path = [self getDocumentRootPath];
	return [path stringByAppendingPathComponent:@"Save"];
}
// get item file path
+ (NSString *)getItemRootPath
{
	NSString *path = [self getDocumentRootPath];
	return [path stringByAppendingPathComponent:@"Conf"];
}

// get item image path
+ (NSString *)getItemImagePath
{
	NSString *path = [self getCacheRootPath];
	return [path stringByAppendingPathComponent:@"Items"];
}

// get item image path
+ (NSString *)getNoticeImagePath
{
	// NSString *path = [self getItemRootPath];
	// return [path stringByAppendingPathComponent:@"Image"];
    /*
	NSString *path = [[NSBundle mainBundle] bundlePath];
	path = [path stringByDeletingLastPathComponent];
     NSCachesDirectory
     */
    NSArray *arr = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    NSURL *url = [arr lastObject];
    NSString *path = url.path;
	path = [path stringByAppendingPathComponent:@"Notice"];
	NSFileManager *mgr = [NSFileManager defaultManager];
	if(![mgr fileExistsAtPath:path]) 
		[mgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
	return path;
}

// get notice image file 
+ (NSString *)getNoticeImageFile:(int)noticeID withVer:(int)ver
{
	NSString *path = [self getNoticeImagePath];
	NSString *fileName = [NSString stringWithFormat:@"%i-%i.png", noticeID, ver];
	if([self isRetina]) {
		fileName = [NSString stringWithFormat:@"%i-%i@2x.png",noticeID, ver];
	}
	return [path stringByAppendingPathComponent:fileName];
}

// get new format notice image file, with country code
+ (NSString *)getNoticeImageFile:(int)noticeID withVer:(int)ver andCountry:(NSString *)country
{
	NSString *path = [self getNoticeImagePath];
	NSString *fileName = [NSString stringWithFormat:@"%i-%@-%i.png", noticeID, country, ver];
	if([self isRetina]) {
		fileName = [NSString stringWithFormat:@"%i-%@-%i@2x.png",noticeID, country, ver];
	}
	return [path stringByAppendingPathComponent:fileName];
}

// 读取JSON文本文件为一个Array
+ (NSArray *) readRemoteConfigAsArray:(NSString *)file
{
    NSString *path = [[self getItemRootPath] stringByAppendingPathComponent:file];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) return nil;
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if(!text) return nil;
    NSArray *info = [text JSONValue];
    if(!info || ![info isKindOfClass:[NSArray class]]) return nil;
    return info;
}

// 检查远程道具文件是否已经下载过了
+ (BOOL) isRemoteFileExist:(NSString *)fileName withVer:(int)ver
{
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSString *localFileRoot = [SystemUtils getItemImagePath];
	
	NSString *localFile = [NSString stringWithFormat:@"%@/%@", localFileRoot, fileName];
	
    NSString *verKey = [NSString stringWithFormat:@"remoteFileVer-%@",fileName];
    int oldVer = [[SystemUtils getNSDefaultObject:verKey] intValue];
    
	// NSLog(@"%s: load %@ to %@", __FUNCTION__, fileName, localFile);
    
	if([mgr fileExistsAtPath:localFile] && oldVer == ver) {
		// NSLog(@"use cache for %@", fileName);
		return YES;
	}
    return NO;
}

// 下载某个远程道具的资源文件
// info里必须包含3个字段，都是NSString类型：ID-道具ID，RemoteFile－资源文件名，RemoteFileVer－版本号
// 返回值含义：0－排入下载队列；1－文件最新版已经存在，不需要下载；－1－无效参数，不能下载
+ (int) loadRemoteItemAsset:(NSDictionary *)info
{
    if(!info || ![info isKindOfClass:[NSDictionary class]]) return -1;
    SNSLog(@"info:%@",info);
    NSString *itemID = [info objectForKey:@"ID"];
    NSString *fileName = [info objectForKey:@"RemoteFile"];
    if(!itemID || ![itemID isKindOfClass:[NSString class]] || [itemID length]==0) return -1;
    if(!fileName || ![fileName isKindOfClass:[NSString class]] || [fileName length]==0) return -1;
    int ver = [[info objectForKey:@"RemoteFileVer"] intValue];
    
    // if([self isRemoteFileExist:fileName withVer:ver]) return 1;
    
	NSString *remoteURLRoot = [NSString stringWithFormat:@"http://%@/item_files/general", [SystemUtils getDownloadServerName]];
	NSString *localFileRoot = [SystemUtils getItemImagePath];
	
	NSString *remoteURL = [NSString stringWithFormat:@"%@/%@", remoteURLRoot, fileName];
	NSString *localFile = [NSString stringWithFormat:@"%@/%@", localFileRoot, fileName];
	
    NSString *verKey = [NSString stringWithFormat:@"remoteFileVer-%@",fileName];
    
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                          remoteURL, @"url", localFile, @"path", 
                          fileName, @"name",
                          [NSString stringWithFormat:@"%i",ver], @"ver",
                          verKey, @"verKey",
                              itemID, @"itemID",
                          nil];
    
	[[ItemLoadingQueue mainLoadingQueue] pushLoadingTask:taskinfo];
    return 0;
}



#pragma mark -


#pragma mark globalSetting

// save global setting to file
+ (void) saveGlobalSetting
{
	NSString *cachePath = [self getCacheRootPath];
	NSString *cacheFile = [cachePath stringByAppendingPathComponent:@"globalInfo.dat"];
	NSString *cacheFile2 = [cacheFile stringByAppendingString:@".bak"];
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSError *err = nil;
	if([mgr fileExistsAtPath:cacheFile2]) {
		[mgr removeItemAtPath:cacheFile2 error:&err];
	}
	NSString *str = [[self config] JSONRepresentation]; 
    str = [self addHashToSaveData:str];
	// [str writeToFile:cacheFile atomically:YES
	if([str writeToFile:cacheFile2 atomically:YES encoding:NSUTF8StringEncoding error:&err] ) 
	{
		if([mgr fileExistsAtPath:cacheFile]) [mgr removeItemAtPath:cacheFile error:&err];
		[mgr moveItemAtPath:cacheFile2 toPath:cacheFile error:&err];
		//NSLog(@"write to %@ ok", cacheFile);
	}
	else
	{
		//NSLog(@"write to %@ failed error:%@", cacheFile, err);
	}
}

// set global setting
+ (void)setGlobalSettingByDictionary:(NSDictionary *)info
{
    if(![info isKindOfClass:[NSDictionary class]]) return;
	NSMutableDictionary *dict = [self config];
	[dict addEntriesFromDictionary:info];
	
	// add ad info
	NSDictionary *adInfo = [dict objectForKey:@"adInfo"];
	if(adInfo && [adInfo isKindOfClass:[NSDictionary class]])
	{
		[dict removeObjectForKey:@"adInfo"];
		[dict addEntriesFromDictionary:adInfo];
	}
	
	/*
	// set notice version
	int ver = [[info objectForKey:@"noticeVer"] intValue]; // ![ver isKindOfClass:NSNull]
	if(ver > 0)
	{
		NSString *verKey = [NSString stringWithFormat:@"noticeVer-%@", [self getCountryCode]];
		[dict setObject:[NSNumber numberWithInt:ver] forKey:verKey];
	}
	 */
	
	// set time diff
	// NSNumber *deviceTime = [NSNumber numberWithInt:[self getCurrentDeviceTime]];
	// [dict setObject:deviceTime forKey:@"deviceTime"];
	NSNumber *serverTime = [dict objectForKey:@"serverTime"];
	if(serverTime!=nil && [serverTime intValue]>0 && [serverTime intValue]>kMinServerTime) 
	{
        /*
		timeDiff = [serverTime intValue] - [deviceTime intValue];
		if(timeDiff < kMinTimeDiff) timeDiff = 0;
		[dict setObject:[NSNumber numberWithInt:timeDiff] forKey:@"timeDelay"];
		NSLog(@"timeDelay:%i", timeDiff);
         */
        [self setServerTime:[serverTime intValue]];
	}
	
	// save current user id
	NSString  *userID = [NSString stringWithFormat:@"%@",[info objectForKey:@"userID"]];
    [SystemUtils setCurrentUID:userID];
	
	// hackTime
	NSNumber *hackTime = [info objectForKey:kHackTime];
	if(hackTime)
	{
		[self setPlayerDefaultSetting:hackTime forKey:kHackTime];
	}
	// session key
	NSString *sessionKey = [info objectForKey:kSessionKeyID];
	if(sessionKey) {
		[self setPlayerDefaultSetting:sessionKey forKey:kSessionKeyID];
	}
	
	// set promotion date
	NSString *stTime = [dict objectForKey:kPromotionStartTime];
	NSString *endTime = [dict objectForKey:kPromotionEndTime];
	if(stTime && [stTime isKindOfClass:[NSString class]] 
	   && endTime && [endTime isKindOfClass:[NSString class]])
	{
		NSDate *stDate = [StringUtils convertStringToDate:stTime];
		NSDate *endDate = [StringUtils convertStringToDate:endTime];
		if(stDate)  [dict setObject:[NSNumber numberWithDouble:[stDate timeIntervalSince1970]]  forKey:kPromotionStartTime];
		else [dict removeObjectForKey:kPromotionStartTime];
		if(endDate) [dict setObject:[NSNumber numberWithDouble:[endDate timeIntervalSince1970]] forKey:kPromotionEndTime];
		else [dict removeObjectForKey:kPromotionEndTime];
		SNSLog(@"promotion start:%@ end:%@",stDate,endDate);
	}
	
	[self saveGlobalSetting];
}

// get global setting
+ (id)getGlobalSetting:(id)key
{
	NSMutableDictionary *dict = [self config];
	return [dict objectForKey:key];
}

// set global setting with key
+ (void)setGlobalSetting:(id)val forKey:(id)key
{
	[[self config] setObject:val forKey:key];
	[self saveGlobalSetting];
}
// remove global setting
+ (void) removeGlocalSettingForKey:(id)key
{
	[[self config] removeObjectForKey:key];
	[self saveGlobalSetting];
}

static NSUserDefaults *_gUserDefault = nil; 

+ (void) setNSDefaultObject:(id)obj forKey:(NSString *)key
{
    if(!_gUserDefault) _gUserDefault = [NSUserDefaults standardUserDefaults];
    if(obj==nil) [_gUserDefault removeObjectForKey:key];
    else [_gUserDefault setObject:obj forKey:key];
    [_gUserDefault synchronize];
}
+ (id) getNSDefaultObject:(NSString *)key
{
    if(!_gUserDefault) _gUserDefault = [NSUserDefaults standardUserDefaults];
    return [_gUserDefault objectForKey:key];
}

// get facebook appID
+ (NSString *)getFacebookAppID
{
    NSString *appID = [self getGlobalSetting:@"kFacebookAppID"];
    if(!appID || [appID length]<3) {
        appID = [self getSystemInfo:@"kFacebookAppID"];
    }
    return appID;
}

// get weibo appID
+ (NSString *)getWeiboAppID
{
    NSString *appID = [self getGlobalSetting:@"kFacebookAppID"];
    if(!appID || [appID length]<3) {
        appID = [self getSystemInfo:@"kFacebookAppID"];
    }
    return appID;
}

#pragma mark -

#pragma mark language

+ (void) initLanguageInfo
{
	NSString *fileName = [NSString stringWithFormat:@"lang2.%@",[self getCurrentLanguage]];
	NSNumber *langChecked = [[self systemInfo] objectForKey:fileName];
	if(langChecked == nil) {
		[_systemInfo setObject:[NSNumber numberWithInt:1] forKey:fileName];
		// try to initialize lang info
		NSString *file = [[self getCacheRootPath] stringByAppendingPathComponent:fileName];
		if([[NSFileManager defaultManager] fileExistsAtPath:file]) 
        {
            NSString *str = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
            _langInfo = [str JSONValue];
            if(_langInfo) [_langInfo retain];
        }
        else {
            // 读取旧版
            NSString *file2 = [[self getCacheRootPath] stringByAppendingFormat:@"/lang.%@",[self getCurrentLanguage]];
            if([[NSFileManager defaultManager] fileExistsAtPath:file2]) {
                _langInfo = [[NSDictionary alloc] initWithContentsOfFile:file2];
                [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
                NSString *str = [_langInfo JSONRepresentation];
                [str writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
        }
		// else _langInfo = [[NSDictionary alloc] initWith];
        // create empty lang info
        if(!_langInfo) _langInfo = [[NSDictionary alloc] init];
	}
}

// get localized string
+ (NSString *)getLocalizedString:(NSString *)key
{
	if(!_langInfo) {
		[self initLanguageInfo];
	}
	
	NSString *info = nil;
	if(_langInfo) info = [_langInfo objectForKey:key];
	if(!info || ![info isKindOfClass:[NSString class]] || [info length]==0) 
        info = NSLocalizedStringFromTable(key, @"SNSGameLocalizable", nil);
    if([info isEqualToString:key])
        info = NSLocalizedStringFromTable(key,@"GameLocalizable",nil);
    if([info isEqualToString:key])
        info = NSLocalizedString(key,nil);
	return info;
}

// check language file
+ (BOOL) isLanguageFileExist
{
    NSString *file2 = [[self getCacheRootPath] stringByAppendingFormat:@"/lang2.%@",[self getCurrentLanguage]];
    if([[NSFileManager defaultManager] fileExistsAtPath:file2]) return YES;
    return NO;
}

// set language info
+ (void) setLanguageInfo:(NSDictionary *)info
{
	if(!info) return;
	if(![info isKindOfClass:[NSDictionary class]]) return;
	if(_langInfo) [_langInfo release];
	_langInfo = [info retain];
	// save to file
	NSString *fileName = [NSString stringWithFormat:@"lang2.%@",[self getCurrentLanguage]];
	NSString *file = [[self getCacheRootPath] stringByAppendingPathComponent:fileName];
	NSError *err = nil;
	if([[NSFileManager defaultManager] fileExistsAtPath:file]) 
		[[NSFileManager defaultManager] removeItemAtPath:file error:&err];
    NSString *jsonStr = [_langInfo JSONRepresentation];
    BOOL res = [jsonStr writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:&err];
	// BOOL res = [_langInfo writeToFile:file atomically:YES];
	if(!res) {
		SNSLog(@"%s: failed to save language file:%@ error:%@", __func__, file, err);
	}
}

#pragma mark -

#pragma mark time

// get current timestamp
+ (int)getCurrentTime
{
#ifdef DEBUG
    return [self getCurrentDeviceTime];
#endif
	return [self getCurrentDeviceTime] + timeDiff;
}


// get current device timestamp
+ (int)getCurrentDeviceTime
{
	NSDate *dt = [NSDate date];
	int time = [dt timeIntervalSince1970];
	// int time = time1;
	//NSLog(@"time:%i time1:%lf", time, time1);
    
	return time + g_deviceTimeDiff;
}

//get current Millisecond
+ (double)getCurrentMillisecond
{
	// NSDate *dt = [NSDate date];
	return [[NSDate date] timeIntervalSince1970]*1000;
}

// set current server time
+ (void)setServerTime:(int)time
{
    [self saveDeviceTimeCheckPoint:YES];
	// set time diff
	NSNumber *deviceTime = [NSNumber numberWithInt:[self getCurrentDeviceTime]];
	NSNumber *serverTime = [NSNumber numberWithInt:time];
	timeDiff = [serverTime intValue] - [deviceTime intValue];
	NSMutableDictionary *dict = [self config];
	[dict setObject:deviceTime forKey:@"deviceTime"];
	[dict setObject:[NSNumber numberWithInt:timeDiff] forKey:@"timeDelay"];
	[dict setObject:serverTime forKey:@"serverTime"];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:time], @"time", nil];
    NSNotification *note = [NSNotification notificationWithName:kNotificationSetServerTime object:nil userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotification:note];
}


//增加设备时间
+(void)addDeviceTime:(int)time{
    timeDiff+=time;
}

//得到当前时间
+ (int) getCurrentYear
{
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:[self getCurrentTime]];
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *todayComp =
	[gregorian components:(NSYearCalendarUnit)
				 fromDate:date];
    
	int year = [todayComp year];
	[gregorian release];
    
	return year;
}
+ (int) getCurrentMonth
{
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:[self getCurrentTime]];
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *todayComp =
	[gregorian components:(NSMonthCalendarUnit)
				 fromDate:date];
    
	int month = [todayComp month];
	[gregorian release];
    
	return month;
}
+ (int) getCurrentDay
{
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:[self getCurrentTime]];
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *todayComp =
	[gregorian components:(NSDayCalendarUnit)
				 fromDate:date];
    
	int day = [todayComp day];
	[gregorian release];
    
	return day;
}

+ (int) getCurrentHour
{
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:[self getCurrentTime]];
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *todayComp =
	[gregorian components:(NSHourCalendarUnit)
				 fromDate:date];
    
	int hour = [todayComp hour];
	[gregorian release];
    
	return hour;
	
}

+ (int) getCurrentMinute
{
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:[self getCurrentTime]];
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *todayComp =
	[gregorian components:(NSMinuteCalendarUnit)
				 fromDate:date];
    
	int minute = [todayComp minute];
	[gregorian release];
    
	return minute;
	
}

+ (int) getCurrentSecond
{
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:[self getCurrentTime]];
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *todayComp =
	[gregorian components:(NSSecondCalendarUnit)
				 fromDate:date];
    
	int second = [todayComp second];
	[gregorian release];
    
	return second;
	
}

#pragma mark -


#pragma mark digest

// update file digest
+ (BOOL) updateFileDigest:(NSString *)file
{
	NSMutableData *dat = [[NSMutableData alloc] initWithContentsOfFile:file];
	if(!dat) {
		NSLog(@"%s: file not exist", __func__);
		return NO;
	}
	NSString *secret = kFileDigestKey;
	[dat appendData:[secret dataUsingEncoding:NSUTF8StringEncoding]];
	NSString *sig1 = [StringUtils stringByHashingDataWithMD5:dat];
	[dat release]; dat = nil;
	
	NSString *path = [[NSBundle mainBundle] bundlePath];
	path = [path stringByDeletingLastPathComponent];
	int len = [path length];
	if([file length]>len && [path isEqualToString:[file substringToIndex:len]]) file = [file substringFromIndex:len];
	
	NSString *pattern = [file stringByAppendingPathComponent:secret];
	NSString *key  = [StringUtils stringByHashingStringWithMD5:pattern];
	
    [self setNSDefaultObject:sig1 forKey:key];
#ifdef DEBUG
	SNSLog(@"file:%@ key:%@ sig:%@", file, key, sig1);
#endif
	return YES;
}

// verify file digest
+ (BOOL) checkFileDigest:(NSString *)file
{
	double ver = [[[UIDevice currentDevice] systemVersion] doubleValue];
	if(ver<4.0f) return YES;
	NSFileManager *mgr = [NSFileManager defaultManager];
	if(![mgr fileExistsAtPath:file]) return NO;

	NSMutableData *dat = [[NSMutableData alloc] initWithContentsOfFile:file];
	NSString *secret = kFileDigestKey;
	[dat appendData:[secret dataUsingEncoding:NSUTF8StringEncoding]];
	NSString *sig1 = [StringUtils stringByHashingDataWithMD5:dat];
	[dat release]; dat = nil;
	
	NSString *path = [[NSBundle mainBundle] bundlePath];
	path = [path stringByDeletingLastPathComponent];
	int len = [path length];
	if([file length]>len && [path isEqualToString:[file substringToIndex:len]]) file = [file substringFromIndex:len];
	
	NSString *pattern = [file stringByAppendingPathComponent:secret];
	NSString *key  = [StringUtils stringByHashingStringWithMD5:pattern];
	//NSLog(@"%s: file:%@ key:%@", __func__, file, key);
	
	NSString *sig2 = [self getNSDefaultObject:key];
	BOOL res = [sig1 isEqualToString:sig2];
#ifdef DEBUG
	if(!res) {
		NSLog(@"%s: ver=%.1lf invalid digest for %@\ncorrect: %@\nsave: %@\nkey: %@", __func__, ver, file, sig1, sig2, key);
	}
#endif
	return res;
}

// verify config file digest
+ (BOOL) checkConfigFileDigest:(NSString *)file
{
	double ver = [[[UIDevice currentDevice] systemVersion] doubleValue];
	if(ver<4.0) return YES;
	NSString *sig = [[self digestInfo] objectForKey:file];
	if(!sig) {
		SNSLog(@"%s:no sig for %@ defined", __FUNCTION__, file);
		return NO;
	}
	
	NSString *filePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:file];
	NSFileManager *mgr = [NSFileManager defaultManager];
	if(![mgr fileExistsAtPath:filePath]) {
#ifdef DEBUG
		SNSLog(@"%s: %@ not exist!", __FUNCTION__, file);
#endif
		return NO;
	}
	
	NSMutableData *dat = [[NSMutableData alloc] initWithContentsOfFile:filePath];
	NSString *secret = kFileDigestKey;
	[dat appendData:[secret dataUsingEncoding:NSUTF8StringEncoding]];
	NSString *sig1 = [StringUtils stringByHashingDataWithMD5:dat];
	[dat release]; dat = nil;
	BOOL res = [sig1 isEqualToString:sig];
#ifdef DEBUG
	if(!res) {
		NSLog(@"%s: corrupt digest for %@\ncorrect: %@\nsave: %@", __FUNCTION__, file, sig1, sig);
	}
#endif
	return res;
}

// 检查所有的配置文件是否有效   
+ (BOOL) verifyAllConfigFiles
{
	// first check SystemConfig.plist
	BOOL res = [self checkConfigFileDigest:@"SystemConfig.plist"];
	BOOL allOK = YES;
	if(!res) allOK = NO;
	NSArray *files = [[self systemInfo] objectForKey:@"protectedFiles"];
	if(!files) return allOK;
	for(int i=0;i<[files count];i++)
	{
		res = [self checkConfigFileDigest:[files objectAtIndex:i]];
		if(!res) allOK = NO;
	}
	return allOK;
}

// 检查下载配置文件是否有效
+ (BOOL) verifyAllLoadedConfigFiles
{
	BOOL res = NO; BOOL allOK = YES;
	NSFileManager *mgr = [NSFileManager defaultManager]; NSError *err = nil;
	NSString *path = [self getItemRootPath];
	NSArray *files = [self getLoadedConfigFileNames];
    
	for(int i=0;i<[files count];i++)
	{
		NSString *filePath = [path stringByAppendingPathComponent:[files objectAtIndex:i]];
		if(![mgr fileExistsAtPath:filePath]) continue;
        NSString *text = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        if(!text || [text length]==0) {
            allOK = NO; continue;
        }
        if([text characterAtIndex:0]=='|') 
            res = [self verifySaveDataWithHash:text];
        else
            res = [self checkFileDigest:filePath];
		if(!res) {
			SNSLog(@"%s:invalid digest of %@", __FUNCTION__, filePath);
			[mgr removeItemAtPath:filePath error:&err];
			allOK = NO;
			// return NO;
		}
        [text release];
	}
	if(!allOK) {
		// reset itemVer
		NSString *key = kItemFileVerKey;
		NSNumber *zero = [NSNumber numberWithInt:0];
		[SystemUtils setPlayerDefaultSetting:zero forKey:key];
		[SystemUtils setPlayerDefaultSetting:zero forKey:kDownloadItemRequired];
	}
    // check kRemoteProtectFiles
    NSString *rootPath = [self getItemImagePath];
    NSDictionary *protectFiles = [SystemUtils getSystemInfo:@"kProtectRemoteFiles"];
    if(protectFiles!=nil) {
        NSArray *pfiles = [protectFiles allValues];
        for(NSString *files in pfiles) {
            // NSString *files = [protectFiles objectForKey:fileName];
            NSArray *arr = [files componentsSeparatedByString:@","];
            for (NSString *file in arr) {
                // generate hash for each file
                NSString *fn = [rootPath stringByAppendingPathComponent:file];
                if(![mgr fileExistsAtPath:fn]) continue;
                if(![self checkFileDigest:fn]) {
                    SNSLog(@"Invalid config file:%@", fn);
                    allOK = NO;
                }
            }
        }
    }

	return allOK;
}
// 更新存档文件签名
+ (void) updateSaveDataHash:(NSString *)saveData
{
    // save hash
    NSString *uid = [SystemUtils getCurrentUID];
    if([uid intValue]>0) {
        NSString *str = [NSString stringWithFormat:@"%@-xxdfir-%@",[StringUtils stringByHashingStringWithMD5:saveData], uid];
        NSString *hash = [StringUtils stringByHashingStringWithMD5:str];
        [SystemUtils setGlobalSetting:hash forKey:@"saveDataTag"];
    }
}

// 检查存档文件签名
+ (BOOL) checkSaveDataHash:(NSString *)saveData
{
    NSString *uid = [SystemUtils getCurrentUID];
    if([uid intValue]==0) return YES;
    NSString *hash = [self getGlobalSetting:@"saveDataTag"];
    if(hash==nil) return YES;
    NSString *str = [NSString stringWithFormat:@"%@-xxdfir-%@",[StringUtils stringByHashingStringWithMD5:saveData], uid];
    return [hash isEqualToString:[StringUtils stringByHashingStringWithMD5:str]];
}

// 检查远程配置文件的版本号，如果本地目前配置文件版本号与SystemConfig.plist中的kRemoteConfigVersion不同，
// 就会清除所有远程配置文件并重新下载；如果这时kRemoteConfigCleanAssets＝1，就会同时清除图片文件目录。
+ (void) checkRemoteConfigVersion
{
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSString *path = [self getItemRootPath];
    // 检查存储格式版本号
    if([self getSystemInfo:@"kRemoteConfigVersion"]==nil) return;
    
    NSString *verFile   = [path stringByAppendingPathComponent:@"ver"];
    NSString *remoteVer = [self getSystemInfo:@"kRemoteConfigVersion"];
    NSString *localVer  = nil;
    if([mgr fileExistsAtPath:verFile])
        localVer = [NSString stringWithContentsOfFile:verFile encoding:NSUTF8StringEncoding error:nil];
    if(localVer==nil || ![localVer isEqualToString:remoteVer]) {
        // 删除配置文件目录
        [mgr removeItemAtPath:path error:nil];
        // 创建配置文件目录
        [mgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        // 设置新版本号
        [remoteVer writeToFile:verFile atomically:NO encoding:NSASCIIStringEncoding error:nil];
        
        if([[SystemUtils getSystemInfo:@"kRemoteConfigCleanAssets"] intValue]==1) {
            // 删除图片目录
            NSString *imgPath = [self getItemImagePath];
            [mgr removeItemAtPath:imgPath error:nil];
            // 创建图片目录
            [mgr createDirectoryAtPath:imgPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    
}

#pragma mark -

#pragma mark utilites

// check if network required
+ (BOOL) isNetworkRequired
{
    if([[self getRemoteConfigValue:@"kDisableNetworkCheck"] intValue]==1) return NO;
	NSMutableDictionary *dict = [self config];
	int hackTime = [[dict objectForKey:kHackTime] intValue];
	if(![dict objectForKey:kHackTime]) {
		hackTime = [[self getPlayerDefaultSetting:kHackTime] intValue];
	}
	if(hackTime>=1) return YES;
	return NO;
}

// 是否付费版
+ (BOOL) isPaidVersion
{
    // check paid version
    static int isPaidVersion = -1;
    if(isPaidVersion == -1) 
        isPaidVersion = [[self getSystemInfo:@"kPaidVersion"] intValue];
    if(isPaidVersion==1) return YES;
    return NO;
}


// check if some feature enabled
+ (BOOL) checkFeature:(kFeatureType)type
{
	if(type == kFeatureShowAd)
	{
		NSString *key = [[self config] objectForKey:kCurrentReviewVersionKey];
		if (key && [key isKindOfClass:[NSString class]] && [key length]>0) {
            NSString *ver = [self getClientVersion];
            if([ver isEqualToString:key]) return NO;
        }
		return YES;
	}
    NSString *adList = [self getGlobalSetting:@"kEnableAdList"];
	if(type == kFeatureTapjoy)
	{
		NSString *key = [[self config] objectForKey:kTapjoyAppIDKey];
		if (!key || ![key isKindOfClass:[NSString class]] || [key length]==0) {
			return NO;
		}
        if(adList) {
            NSRange r = [adList rangeOfString:@"tapjoy"];
            if(r.location == NSNotFound) return NO;
        }
		return YES;
	}
	if(type == kFeatureFlurry)
	{
		NSString *key = [[self config] objectForKey:kFlurryAppIdKey];
		if (!key || ![key isKindOfClass:[NSString class]] || [key length]==0) {
			return NO;
		}
        if(adList) {
            NSRange r = [adList rangeOfString:@"flurry"];
            if(r.location == NSNotFound) return NO;
        }
		return YES;
	}
	if(type == kFeatureAdColony)
	{
		NSString *key = [self getSystemInfo:kAdColonyAppID];
		if (!key || ![key isKindOfClass:[NSString class]] || [key length]==0) {
			return NO;
		}
        if(adList) {
            NSRange r = [adList rangeOfString:@"adcolony"];
            if(r.location == NSNotFound) return NO;
        }
		return YES;
	}
	if(type == kFeatureChartBoost)
	{
		NSString *key = [self getSystemInfo:kChartBoostAppID];
		if (!key || ![key isKindOfClass:[NSString class]] || [key length]==0) {
			return NO;
		}
        if(adList) {
            NSRange r = [adList rangeOfString:@"chartboost"];
            if(r.location == NSNotFound) return NO;
        }
		return YES;
	}
	if(type == kFeatureAdMob)
	{
		NSString *key = [self getSystemInfo:@"kAdMobPublisherID"];
		if (!key || ![key isKindOfClass:[NSString class]] || [key length]==0) {
			return NO;
		}
        if(adList) {
            NSRange r = [adList rangeOfString:@"admob"];
            if(r.location == NSNotFound) return NO;
        }
		return YES;
	}
	if(type == kFeatureGreystripe)
	{
		NSString *key = [self getSystemInfo:@"kGreystripeAppID"];
		if (!key || ![key isKindOfClass:[NSString class]] || [key length]==0) {
			return NO;
		}
        if(adList) {
            NSRange r = [adList rangeOfString:@"greystripe"];
            if(r.location == NSNotFound) return NO;
        }
		return YES;
	}
	if(type == kFeatureLiMei)
	{
		NSString *key = [self getGlobalSetting:@"kLiMeiEntranceID"];
		if (!key || ![key isKindOfClass:[NSString class]] || [key length]==0) {
            key = [self getSystemInfo:@"kLiMeiEntranceID"];
        }
		if (!key || ![key isKindOfClass:[NSString class]] || [key length]==0) {
			return NO;
		}
        // only valid for cn/tw/hk
        NSString *country = [self getCountryCode];
        if(!([country isEqualToString:@"CN"] || [country isEqualToString:@"TW"] || [country isEqualToString:@"HK"])) 
            return NO;
        if(adList) {
            NSRange r = [adList rangeOfString:@"limei"];
            if(r.location == NSNotFound) return NO;
        }
		return YES;
	}
	if(type == kFeatureKiip)
	{
        if(adList) {
            NSRange r = [adList rangeOfString:@"kiip"];
            if(r.location == NSNotFound) return NO;
        }
		return YES;
	}
	if(type == kFeatureTinyMobi)
	{
        if(adList) {
            NSRange r = [adList rangeOfString:@"tinymobi"];
            if(r.location == NSNotFound) return NO;
        }
		return YES;
	}
	if(type == kFeatureAppDriver)
	{
        if(adList) {
            NSRange r = [adList rangeOfString:@"appdriver"];
            if(r.location == NSNotFound) return NO;
        }
		return YES;
	}
	return NO;
}

// 是否显示广告
+ (BOOL) isAdVisible
{
    // if(![[self getNSDefaultObject:@"kServerConnected"] boolValue]) return NO;
    
    // if([[SnsStatsHelper helper] getTotalPay]>0) return NO;
    if([self getGameDataDelegate])
    {
        // check noAds
        if([[_currentGameDataDelegate getExtraInfo:@"noAds"] intValue]==1) return NO;
        // check kMinLevelToShowBonus
        int minLevel = [[SystemUtils getGlobalSetting:kMinLevelToShowBonus] intValue];
        if(minLevel == 0)
            minLevel = [[SystemUtils getSystemInfo:kMinLevelToShowBonus] intValue];
        if(minLevel > [[self getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel])
        {
            SNSLog(@"not show ad: minLevel=%d", minLevel);
            return NO;
        }
        // check register days
        int noAdDays = [[self getGlobalSetting:@"kDaysToShowAd"] intValue];
        int regtime = [[SnsStatsHelper helper] getInstallTime];
        if(noAdDays>0) {
            if(regtime>0 && regtime+noAdDays*86400<[self getCurrentTime]) return YES;
            SNSLog(@"not show ad: kDaysToShowAd=%d", noAdDays);
            return NO;
        }
    }
    // if(![[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) return NO;
    
	return [self checkFeature:kFeatureShowAd];
}


// 启动ChartBoost
+ (void) startChartBoost
{
	if(![self isAdVisible]) {
		SNSLog(@"ad feature not enabled");
		return;
	}
    
	// if(YES) return;
#ifndef SNS_DISABLE_CHARTBOOST
    [[ChartBoostHelper helper] showChartBoostOffer];
	// SNSLog(@"cb is ready");
#endif
}

// 显示视频广告
+ (void) showFreeVideoOffer
{
	if(![self isAdVisible]) return;
	if(![NetworkHelper isConnected]) return;
	
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	int lastTime = [def integerForKey:@"lastVideoTime"];
	int now = [SystemUtils getCurrentTime];
	if(lastTime > now - 7200) return;
    BOOL res = NO;
    
#ifndef SNS_DISABLE_FLURRY_V1
	res = [FlurryHelper hasVideoOffer];
	if(res) {
		[FlurryHelper showVideoOffer];
	}
#endif
#ifndef SNS_DISABLE_ADCOLONY
	if(!res) {
		res = [[AdColonyHelper helper] showOffers:NO];
	}
#endif
	if(res) {
		[def setInteger:now forKey:@"lastVideoTime"];
		[def synchronize];
	}
}

// unzip files to a path
+ (BOOL) unzipFile:(NSString *)zipFile toPath:(NSString *)path
{
	if (![[NSFileManager defaultManager] fileExistsAtPath:zipFile]) {
		return NO;
	}
	BOOL ret = NO;
	ZipArchive* za = [[ZipArchive alloc] init];
	if( [za UnzipOpenFile:zipFile] )
		// if the Password is empty, get same  effect as if( [za UnzipOpenFile:@"/Volumes/data/testfolder/Archive.zip"] )
	{
		ret = [za UnzipFileTo:path overWrite:YES];
		[za UnzipCloseFile];
	}
	[za release];
	return ret;
}


// 获取指定时间是周几，1－周日，2－周一，7－周六
+ (int) getWeekDayOfTime:(int)time
{
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
	
	NSDateComponents *weekdayComponents =
    [gregorian components:NSWeekdayCalendarUnit fromDate:date];
	int weekday = [weekdayComponents weekday];
	[gregorian release];
	return weekday;
	
}

// 获取今天日期，110731
+(int)getTodayDate
{
	int time = [self getCurrentTime];
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
	
	NSDateComponents *weekdayComponents =
    [gregorian components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
	int year = [weekdayComponents year];
	int mon  = [weekdayComponents month];
	int day  = [weekdayComponents day];
	[gregorian release];
	int res = (year-2000)*10000+mon*100+day;
    if(res<100101) res = 100101;
    return res;
}

// 获取当前是周几，1－周日，2－周一，7－周六
+ (int) getCurrentWeekDay
{
	return [self getWeekDayOfTime:[self getCurrentTime]];
}


+ (int)getWeekIndexInYear:(int)time{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    
	NSCalendar *calendar = [[NSCalendar alloc]
                            initWithCalendarIdentifier:NSGregorianCalendar];
    [calendar setMinimumDaysInFirstWeek:7];
    [calendar setFirstWeekday:2];
    
    
    NSDateComponents *weekdayComponents =  [calendar components:(NSWeekCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit)  fromDate:date];
    
    int result = [weekdayComponents week];
    [calendar release];
    return  result;
}
+ (int)getWeekIndexInYear:(int)year month:(int)month day:(int)day{
    NSCalendar*calendar = [NSCalendar currentCalendar];
    [calendar setMinimumDaysInFirstWeek:7];
    [calendar setFirstWeekday:2];
    
    NSDateComponents *dc = [[NSDateComponents alloc] init];
    [dc setYear: year];
    [dc setMonth: month];
    [dc setDay: day];
    NSDate *date = [calendar dateFromComponents:dc];
    
    
    NSDateComponents* comps =[calendar components:(NSWeekCalendarUnit | NSWeekdayCalendarUnit |NSWeekdayOrdinalCalendarUnit)
                              
                                         fromDate:date];
    
    int result = [comps week];
    [dc release];
    return  result;
    
}
+(int)getWeekIndexInYear{
    return [self getWeekIndexInYear:[self getCurrentTime]];
}



+(BOOL) isGameCenterAPIAvailable
{
    // Check for presence of GKLocalPlayer class.
    BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
	
    // The device must be running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
	
    return (localPlayerClassAvailable && osVersionSupported);
}

// 获得一个随机整数
+ (int) getRandomNumber:(int)max
{
	srandom(time(NULL));
	return random() % max;
}


// 避开睡眠时间
+ (NSDate *)delayDateToAvoidSleepHour:(NSDate *)date
{
	// avoid today notice
	if([date timeIntervalSinceNow]<1800) {
		int minutes =[self getRandomNumber:180];
		date = [[NSDate date] dateByAddingTimeInterval:(20+minutes)*60];
	}
	
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *todayComp =
	[gregorian components:(NSHourCalendarUnit | NSMinuteCalendarUnit) 
				 fromDate:date];
	if([todayComp hour]<10) {
		int delay = (10-[todayComp hour])*3600;
		date = [date dateByAddingTimeInterval:delay];
	}
	else if([todayComp hour]>=22) {
		int delay = 12*3600;
		date = [date dateByAddingTimeInterval:delay];
	}
	[gregorian release];
	return date;
}


// 从文件中读取JSON字符串并转换为NSObject
+ (id) readJsonObjectFromFile:(NSString *)file
{
	NSError *err = nil;
	NSString *str = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:&err ];
	if(err) {
		SNSLog(@"%s: read %@ failed, error: %@", __FUNCTION__, file, err);
	}
	return [StringUtils convertJSONStringToObject: str];
}



// 执行一个窗口命令
+ (void) runCommand:(NSString *)cmd
{
	SNSLog(@"%s: cmd:%@", __func__, cmd);
    
    if([cmd isEqualToString:@"buySpecialIAP"])
    {
        [self buySpecialIAP];
        return;
    }
    if([cmd isEqualToString:@"openRateLink"]) {
		NSString *link = [SystemUtils getAppRateLink];
		if(link) {
            NSURL *url = [NSURL URLWithString:link];
            [[UIApplication sharedApplication] openURL:url];
		}
        return;
    }
#ifndef SNS_DISABLE_TAPJOY
	if([cmd isEqualToString:@"showTapjoy"]) {
		[TapjoyHelper showOffers];
		return;
	}
#endif
#ifdef SNS_ENABLE_TAPJOY2
	if([cmd isEqualToString:@"showTapjoy"]) {
		[[TapjoyHelper2 helper] showOffers];
		return;
	}
#endif
#ifdef SNS_ENABLE_FLURRY_V2
	if([cmd isEqualToString:@"showFlurry"] || [cmd isEqualToString:@"showFlurryLeaf"] || [cmd isEqualToString:@"showFlurryVideo"]) {
        [[FlurryHelper2 helper] showOffer];
    }
#endif
#ifndef SNS_DISABLE_FLURRY_V1
	if([cmd isEqualToString:@"showFlurry"]) {
        int userLevel = [[self getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel];
        int flurryLevel = [[self getGlobalSetting:@"kiOSFlurryMinLevel"] intValue];
        if(userLevel < flurryLevel) {
#ifndef SNS_DISABLE_TAPJOY
            [TapjoyHelper showOffers];
#endif
        }
        else {
            BOOL showNoOfferHint = ([[self getNSDefaultObject:@"showNoOfferHint"] intValue] == 1);
            [FlurryHelper showOffers:showNoOfferHint];
        }
		return;
	}
	if([cmd isEqualToString:@"showFlurryLeaf"]) {
        int userLevel = [[self getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel];
        int flurryLevel = [[self getGlobalSetting:@"kiOSFlurryMinLevel"] intValue];
        if(userLevel < flurryLevel) {
#ifndef SNS_DISABLE_TAPJOY
            [TapjoyHelper showOffers];
#endif
        }
        else
            [FlurryHelper showOffers:NO prizeType:1];
		return;
	}
	if([cmd isEqualToString:@"showFlurryVideo"]) {
		[FlurryHelper showVideoOffer];
		return;
	}
#endif
#ifndef SNS_DISABLE_ADCOLONY
	if([cmd isEqualToString:@"showAdColony"]) {
		[[AdColonyHelper helper] showOffers:NO];
		return;
	}
#endif
    
#ifndef SNS_DISABLE_GREYSTRIPE
	if([cmd isEqualToString:@"showGreystripe"]) {
		[[GreystripeHelper helper] showOffers:NO];
		return;
	}
	if([cmd isEqualToString:@"hideGreystripe"]) {
		[[GreystripeHelper helper] hideOffers];
		return;
	}
#endif
    if([cmd isEqualToString:@"showInviteWindow"]) {
        [[TinyiMailHelper helper] showInviteFriendsPopup:YES];
        return;
    }
#ifndef SNS_DISABLE_CHARTBOOST
	if([cmd isEqualToString:@"showChartboost"]) {
		[[ChartBoostHelper helper] showChartBoostOffer];
		return;
	}
#endif
#ifdef SNS_ENABLE_LIMEI
	if([cmd isEqualToString:@"showLiMei"]) {
		// [[GreystripeHelper helper] showOffers:NO];
        [[LiMeiHelper helper] showOffers];
		return;
	}
#endif
#ifdef SNS_ENABLE_LIMEI2
	if([cmd isEqualToString:@"showLiMei"]) {
		// [[GreystripeHelper helper] showOffers:NO];
        [[LiMeiHelper2 helper] showOffers];
		return;
	}
	if([cmd isEqualToString:@"showLiMeiPopup"]) {
		// [[GreystripeHelper helper] showOffers:NO];
        [[LiMeiHelper2 helper] showInterstitial];
		return;
	}
#endif
#ifdef SNS_ENABLE_TINYMOBI
    if([cmd isEqualToString:@"showTinyMobiOfferWall"]) {
        [[TinyMobiHelper helper] showOffer];
    }
#endif
#ifdef SNS_ENABLE_APPDRIVER
    if([cmd isEqualToString:@"showAppDriver"]) {
        [[AppDriverHelper helper] showOffer];
    }
#endif
    
#ifdef SNS_ENABLE_ADMOB
    if([cmd isEqualToString:@"showAdMob"]) {
        [[SnsServerHelper helper] showAdmobBanner];
        return;
    }
    if([cmd isEqualToString:@"hideAdMob"]) {
        [[SnsServerHelper helper] hideAdmobBanner];
        return;
    }
#endif
#ifndef SNS_DISABLE_PLAYHAVEN
    if([cmd isEqualToString:@"showPlayhaven"]) {
        [[PlayHavenHelper helper] showFeaturedApp];
        return;
    }
    if([cmd isEqualToString:@"showPlayhavenOffer"]) {
        [[PlayHavenHelper helper] showOffer:NO];
        return;
    }
#endif
    
#ifdef SNS_ENABLE_AARKI
    if([cmd isEqualToString:@"showAarkiOfferWall"]) {
        [[AarkiHelper helper] showOfferWall];
        return;
    }
    else if([cmd isEqualToString:@"showAarkiPopup"]) {
        [[AarkiHelper helper] showPopupOffer];
        return;
    }
    else if([cmd isEqualToString:@"showAarkiVideo"]) {
        [[AarkiHelper helper] showVideoOffer];
        return;
    }
#endif
#ifdef SNS_ENABLE_SPONSORPAY
    if([cmd isEqualToString:@"showSponsorpayOfferWall"]) {
        [[SponsorPayHelper helper] showOfferWall];
        return;
    }
    else if([cmd isEqualToString:@"showSponsorpayPopup"]) {
        [[SponsorPayHelper helper] showPopupOffer];
        return;
    }
    else if([cmd isEqualToString:@"showSponsorpayVideo"]) {
        [[SponsorPayHelper helper] showVideoOffer];
        return;
    }
#endif
#ifdef SNS_ENABLE_APPLOVIN
    if([cmd isEqualToString:@"showApplovin"]) {
        [[AppLovinHelper helper] showPopupOffer];
        return;
    }
    if([cmd isEqualToString:@"showApplovinVideo"]) {
        [[AppLovinHelper helper] showRewardVideoOffer];
        return;
    }
#endif
    
#ifdef SNS_ENABLE_GUOHEAD
    if([cmd isEqualToString:@"showGuohead"]) {
        [[MixGHHelper helper] showPopupOffer];
        return;
    }
#endif
    
#ifdef SNS_ENABLE_DOMOB
    if([cmd isEqualToString:@"showDomob"]) {
        [[DomobHelper helper] showOffers];
        return;
    }
#endif
#ifdef SNS_ENABLE_YOUMI
    if([cmd isEqualToString:@"showYoumi"]) {
        [[YoumiHelper helper] showOffers];
        return;
    }
#endif

#ifdef SNS_ENABLE_DIANRU
    if([cmd isEqualToString:@"showDianru"]) {
        [[DianruHelper helper] showOffers];
        return;
    }
#endif
#ifdef SNS_ENABLE_ADWO
    if([cmd isEqualToString:@"showAdwo"]) {
        [[AdwoHelper helper] showOffers];
        return;
    }
    
    if([cmd isEqualToString:@"showAdwoPopup"]) {
        [[AdwoHelper helper] showInterstitial];
        return;
    }
#endif
#ifdef SNS_ENABLE_IAD
    if([cmd isEqualToString:@"showiAd"]) {
        [[iAdHelper helper] showPopupOffer];
        return;
    }
#endif
    
#ifdef SNS_ENABLE_CHUKONG
    if([cmd isEqualToString:@"showChukong"]) {
        [[ChukongHelper helper] showOffers];
        return;
    }
    if([cmd isEqualToString:@"showChukongPopup"]) {
        [[ChukongHelper helper] showInterstitial];
        return;
    }
#endif
    
#ifdef SNS_ENABLE_YIJIFEN
    if([cmd isEqualToString:@"showYiJiFen"]) {
        [[YijifenHelper helper] showOffers];
        return;
    }
    if([cmd isEqualToString:@"showYiJiFenPopup"]) {
        [[YijifenHelper helper] showInterstitial];
        return;
    }
#endif
    
#ifdef SNS_ENABLE_WAPS
    if([cmd isEqualToString:@"showWaps"]) {
        [[WapsHelper helper] showOffers];
        return;
    }
    if([cmd isEqualToString:@"showWapsPopup"]) {
        [[WapsHelper helper] showInterstitial];
        return;
    }
#endif
    
#ifdef SNS_ENABLE_MOBISAGE
    if([cmd isEqualToString:@"showMobiSage"]) {
        [[MobiSageHelper helper] showOffers];
        return;
    }
    if([cmd isEqualToString:@"showMobiSagePopup"]) {
        [[MobiSageHelper helper] showInterstitial];
        return;
    }
#endif

    
#ifndef SNS_DISABLE_BONUS_WINDOW
    if([cmd isEqualToString:@"showDailyBonusOffer"])
    {
#ifdef SNS_ENABLE_TINYMOBI
        [[TinyMobiHelper helper] showOffer];
#else
        // TODO: show daily bonus window
		//这里不能放在列队里，否则点了PlayHaven的按钮之后总是被阻塞住
        smPopupWindowBonusCollection *collection = [[smPopupWindowBonusCollection alloc] initBouns];
        // [[smPopupWindowQueue createQueue] pushToQueue:collection timeOut:0];
        [collection showHard];
        [collection release];
#endif
        return;
    }
#endif
    NSArray *arr = [cmd componentsSeparatedByString:@"#"];
    NSString *action = [arr objectAtIndex:0];
    if([arr count]==2 && [action isEqualToString:@"buyIAP"])
    {
		[[InAppStore store] buyAppStoreItem:[arr objectAtIndex:1] amount:1 withDelegate:[SnsServerHelper helper]];
        return;
    }
    // send notification
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:cmd, @"command", nil];
	// save to history
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationRunCommand object:nil userInfo:info];
}

// 显示Loading界面
+ (void) showLoadingScreen
{
    // send notification
	// NSMutableDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:cmd, @"command", nil];
	// save to history
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationShowLoadingScreen object:nil userInfo:nil];
}

// 设置Loading文字
+ (void) setLoadingScreenText:(NSString *)mesg
{
	NSDictionary *info2 = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"message", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSetLoadingScreenText object:nil userInfo:info2];
}

// 关闭Loading界面
+ (void) hideLoadingScreen
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationHideLoadingScreen object:nil userInfo:nil];
}

// 显示游戏内Loading界面
+ (void) showInGameLoadingView
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationShowInGameLoadingView object:nil userInfo:nil];
}

// 关闭游戏内Loading界面
+ (void) hideInGameLoadingView
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationHideInGameLoadingView object:nil userInfo:nil];
}

// 显示弹出窗口
+ (void) showPopupView:(UIViewController *)vc
{
    UIViewController *root = [self getRootViewController];
    if(!root) return;
    // if(vc.view.superview == root.view) return;
    // 设置坐标
    if([[UIDevice currentDevice].systemVersion compare:@"5.0"]>=0) {
        [root presentViewController:vc animated:YES completion:^(void){}];
    }
    else {
        [root presentModalViewController:vc animated:YES];
    }
    // [root.view addSubview:vc];
}
// 关闭弹出窗口
+ (void) closePopupView:(UIViewController *)vc
{
    UIViewController *root = [self getRootViewController];
    if(!root) return;
    if([[UIDevice currentDevice].systemVersion compare:@"5.0"]>=0) {
        // if(root.presentingViewController!=vc) return;
        [root dismissViewControllerAnimated:NO completion:NULL];
    }
    else {
        // if(vc.parentViewController!=root) return;
        [root dismissModalViewControllerAnimated:NO];
    }
}

// 解析多语言内容，返回当前设备语言对应的内容
+ (NSString *)parseMultiLangStrForCurrentLang:(NSString *)mesg
{
    if(!mesg || [mesg length]<10) return mesg;
    if([mesg characterAtIndex:0]=='[' && [mesg characterAtIndex:[mesg length]-1]==']')
    {
        NSString *lang = [self getCurrentLanguage];
        BOOL found = NO;
        NSString *pat1 = [NSString stringWithFormat:@"[%@]", lang];
        NSString *pat2 = [NSString stringWithFormat:@"[/%@]", lang];
        NSRange r1 = [mesg rangeOfString:pat1];
        NSRange r2 = [mesg rangeOfString:pat2];
        if(r1.location!=NSNotFound && r2.location!=NSNotFound && r2.location>r1.location) {
            r1.location += r1.length;
            r1.length = r2.location - r1.location;
            found = YES; mesg = [mesg substringWithRange:r1];
        }
        else {
            // SNSLog(@"pattern not found p1=%@ p2=%@", pat1, pat2);
        }
        if(!found) {
            // 取英文
            pat1 = @"[en]";
            pat2 = @"[/en]";
            r1 = [mesg rangeOfString:pat1];
            r2 = [mesg rangeOfString:pat2];
            if(r1.location!=NSNotFound && r2.location!=NSNotFound && r2.location>r1.location) {
                r1.location += r1.length;
                r1.length = r2.location - r1.location;
                found = YES; mesg = [mesg substringWithRange:r1];
            }
        }
        if(!found) {
            // 取第一个
            pat1 = @"[";
            pat2 = @"]";
            r1 = [mesg rangeOfString:pat1]; r1.length = [mesg length]-r1.location;
            r2.location = NSNotFound;
            if(r1.location!=NSNotFound) {
                r2 = [mesg rangeOfString:pat2 options:0 range:r1];
                r2.length = [mesg length] - r2.location;
            }
            if(r2.location != NSNotFound) {
                r1 = [mesg rangeOfString:pat1 options:0 range:r2];
                r1.length = [mesg length] - r1.location;
            }
            if(r1.location!=NSNotFound && r2.location!=NSNotFound && r2.location<r1.location) {
                r2.location++;
                r2.length = r1.location - r2.location;
                found = YES; mesg = [mesg substringWithRange:r2];
            }
        }
    }
    return mesg;
}

+ (void) pauseDirector
{
#ifndef MODE_COCOS2D_X
#ifndef SNS_DISABLE_DIRECTOR_RESUME
	[[CCDirector sharedDirector] pause];
	[[CCDirector sharedDirector] stopAnimation];
#endif
#endif
}
+ (void) resumeDirector
{
#ifndef MODE_COCOS2D_X
#ifndef SNS_DISABLE_DIRECTOR_RESUME
	[[CCDirector sharedDirector] startAnimation];
	[[CCDirector sharedDirector] resume];
#endif
#endif
}

// 对于iOS6直接在应用内打开appstore
+ (void) openAppLink:(NSString *)link
{
    NSURL *url = [NSURL URLWithString:link];
    // if(!NSClassFromString(@"SKStoreProductViewController"))
    /*
    if(YES)
    {
        [[UIApplication sharedApplication] openURL:url];
        return;
    }
     */
    
    BOOL isAppLink = NO;
    // http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=300136119&mt=8
    // http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=300136119&mt=8
    // http://itunes.apple.com/us/app/id554425888?mt=8
    NSString *appID = nil;
    NSString *host = [[url host] lowercaseString];
    if([host isEqualToString:@"itunes.apple.com"] || [host isEqualToString:@"itunes.com"]
       || [host isEqualToString:@"phobos.apple.com"])
    {
        // try to find the appstore ID
        NSRange r = [link rangeOfString:@"id="];
        if(r.location==NSNotFound) r = [link rangeOfString:@"/id"];
        if(r.location!=NSNotFound) {
            char buf[21]; int i=0; int offset = r.location+r.length;
            char ch = [link characterAtIndex:offset];
            while (ch>='0' && ch<='9') {
                buf[i++] = ch;
                offset++;
                if(offset>=[link length] || i>=20) break;
                ch = [link characterAtIndex:offset];
            }
            if(i>0) {
                isAppLink = YES;
                buf[i] = '\0';
                appID = [NSString stringWithCString:buf encoding:NSASCIIStringEncoding];
            }
        }
    }
    
    if(isAppLink) { // Checks for iOS 6 feature.
        [[SnsServerHelper helper] showAppStoreView:appID withLink:link];
    } else { // Before iOS 6, we can only open the URL
        [[UIApplication sharedApplication] openURL:url];
    }
}


// 获取Feed文字内容，多条记录由三条竖线 ||| 分割
+ (NSString *)getRemoteFeedText:(int) feedType
{
    NSString *key = nil;
    if(feedType==kFeedTextInviteFriend) key = @"kFeedTextInviteFriend";
    if(feedType==kFeedTextSharePicture) key = @"kFeedTextSharePicture";
    if(feedType==kFeedTextShowUID) key = @"kFeedTextShowUID";
    if(!key) return nil;
    NSString *text = [self getGlobalSetting:key];
    if(text) {
        NSRange r = [text rangeOfString:@"["];
        if(r.location == NSNotFound) return text;
        NSArray *arr = [text componentsSeparatedByString:@"|||"];
        // NSMutableArray *arr2 = [NSMutableArray arrayWithCapacity:[arr count]];
        NSMutableString *resText = [NSMutableString stringWithString:@""];
        for(int i=0;i<[arr count];i++) {
            text = [arr objectAtIndex:i];
            text = [self parseMultiLangStrForCurrentLang:text];
            if(text) {
                if([resText length]>0) [resText appendString:@"|||"];
                [resText appendString:text];
            }
        }
        return resText;
    }
    return nil;
}

// 让设备震动
+ (void) playVibrate
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

// 给好友发送邀请链接
+ (void) shareAppLink
{
    if((NSClassFromString(@"UIActivityViewController")) != nil)
    {
        NSString *textToShare = [self getLocalizedString:@"Come to play __APP_NAME__ together!"];
        NSString *imageName   = @"Icon.png";
        NSString *shareLink   = [self getAppDownloadLink];
        
        NSDictionary *info = [self getSystemInfo:@"kSharingInfo"];
        if(info) {
            NSString *str = [info objectForKey:@"text"];
            if(str!=nil && [str length]>5) textToShare = str;
            str = [info objectForKey:@"image"];
            if(str!=nil && [str length]>3) imageName = str;
            str = [info objectForKey:@"link"];
            if(str!=nil && [str length]>5) shareLink = str;
        }
        NSString *gameName = [SystemUtils getLocalizedString:@"GameName"];
        textToShare = [textToShare stringByReplacingOccurrencesOfString:@"__APP_NAME__" withString:gameName];
        UIImage *imageToShare = [UIImage imageNamed:imageName];
        
        NSURL *urlToShare = [NSURL URLWithString:shareLink];
        
        NSArray *activityItems = @[textToShare, imageToShare, urlToShare];
        
        UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        controller.excludedActivityTypes = @[UIActivityTypePrint,UIActivityTypeCopyToPasteboard,UIActivityTypeAssignToContact,UIActivityTypeSaveToCameraRoll,UIActivityTypeAddToReadingList,UIActivityTypePostToFlickr];
        controller.completionHandler = ^(NSString *activityType, BOOL completed) {
            SNSLog(@"activityType:%@ completed:%d", activityType, completed);
            if(completed) {
                int today = [self getTodayDate];
                int last  = [[[self getGameDataDelegate] getExtraInfo:@"kShareDate"] intValue];
                if(last==today) return;
                int count = [[info objectForKey:@"prizeCount"] intValue];
                int type  = [[info objectForKey:@"prizeType"] intValue];
                NSString *mesg = [info objectForKey:@"prizeMesg"];
                if(mesg==nil) mesg = [self getLocalizedString: @"Thanks for sharing with your friends!"];
                if(count>0 && type>0) {
                    [self showSNSAlert:[self getLocalizedString:@"System Notice"] message:mesg];
                    [[self getGameDataDelegate] setExtraInfo:[NSString stringWithFormat:@"%d",today] forKey:@"kShareDate"];
                }
                
            }
        };
        UIViewController *root = [self getRootViewController];
        [root presentViewController:controller animated:YES completion:^(void){
            [controller release];
        }];
        return;
    }
    [[TinyiMailHelper helper] writeGiftEmail];
}

#pragma mark -

#pragma mark save file

+ (NSString *)getSaveIDKey
{
	return [NSString stringWithFormat:@"saveID-%@", [self getCurrentUID]];
}

// get current save id
+ (int) getSaveID
{
	NSString *key = [self getSaveIDKey];
	int saveID = [[self getNSDefaultObject:key] intValue];
    if(saveID==0) {
        saveID = [[self getPlayerDefaultSetting:key] intValue];
    }
    return saveID;
}

// set current save id
+ (void) setSaveID:(int)newID
{
    // SNSLog(@"call stack: %@", [self getStackTraceInfo]);
	NSString *key = [self getSaveIDKey];
    [self setNSDefaultObject:[NSNumber numberWithInt:newID] forKey:key];
	// [self setPlayerDefaultSetting:[NSNumber numberWithInt:newID] forKey:key];
}

// get save file path
+ (NSString *)getUserSaveFile
{
	return [self getUserSaveFileByUID:[self getCurrentUID]];
}

// get save file path
+ (NSString *)getUserSaveFileByUID:(NSString *)uid
{
	return [NSString stringWithFormat:@"%@/%@_user.plist", [self getDocumentRootPath], uid];
}

// get save file path
+ (NSString *)getUserSaveFileByID:(int)uid
{
	return [NSString stringWithFormat:@"%@/%i_user.plist", [self getDocumentRootPath], uid];
}

// check if user file exists
+ (BOOL) isSaveFileExists
{
	return [[NSFileManager defaultManager] fileExistsAtPath:[self getUserSaveFile]];
}

// 验证存档字符串签名是否正确
+(NSString *) getHashOfSaveData:(NSString *)saveData
{
    NSString *hash = [StringUtils stringByHashingStringWithSHA1:[saveData stringByAppendingString:@"32348294-()sdf2"]];
    return [hash substringToIndex:32];
}

// 从存档字符串里去掉签名
// format: |n|digest|[json data]
+(NSString *)stripHashFromSaveData:(NSString *)saveData
{
    if([saveData length]<=36) return saveData;
    if([saveData characterAtIndex:0]=='|' && [saveData characterAtIndex:2]=='|'
       && [saveData characterAtIndex:35]=='|')
        return [saveData substringFromIndex:36];
    return saveData;
}

// 给存档字符串加上签名
+(NSString *)addHashToSaveData:(NSString *)saveData
{
    NSString *hash = [self getHashOfSaveData:saveData];
    return [NSString stringWithFormat:@"|1|%@|%@",hash, saveData];
}

+(BOOL) verifySaveDataWithHash:(NSString *)text
{
    NSString *text2 = [self stripHashFromSaveData:text];
    
    NSString *hash  = [self getHashOfSaveData:text2];
    NSRange hashRange; hashRange.length = 32; hashRange.location = 3;
    if([text length]<=36 || ![hash isEqualToString:[text substringWithRange:hashRange]])
    {
        // invalid hash
        SNSLog(@"save data is invalid: %@", text);
        return NO;
    }
    return YES;
}

// 从带签名的存档文件中读取数据字符串
+(NSString *)readHashedSaveData:(NSString *)file
{
    NSString *text = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    if(text==nil) return nil;
    if(![self verifySaveDataWithHash:text]) return nil;
    return [self stripHashFromSaveData:text];
}

// 解析服务器存档格式
+(NSDictionary *)parseSaveDataFromServer:(NSString *)saveData
{
    // |SNSUserInfo|len|{json data}|SAVEDATA|len|<savedata>|stats|len|{json data}|todayStats|len|{json data}
    int lastPos = 0; int saveLen = [saveData length];
    NSMutableDictionary *info = [[NSMutableDictionary alloc] initWithCapacity:4];
    while(lastPos<saveLen && [saveData characterAtIndex:lastPos]=='|') 
    {
        lastPos++;
        int pos=lastPos;
        while(pos<saveLen) {
            if([saveData characterAtIndex:pos]=='|') break;
            pos++;
        }
        if(pos>=saveLen) break;
        NSRange r; r.location = lastPos; r.length = pos-lastPos; 
        NSString *key = [saveData substringWithRange:r];
        // SNSLog(@"find key:%@", key);
        
        pos++;
        lastPos = pos;
        while(pos<saveLen) {
            if([saveData characterAtIndex:pos]=='|') break;
            pos++;
        }
        if(pos>=saveLen) break;
        r.location = lastPos; r.length = pos-lastPos;
        int len = [[saveData substringWithRange:r] intValue];
        // SNSLog(@"find len:%i", len);
        pos++;
        if(pos+len>saveLen) break;
        
        lastPos = pos;
        r.location = lastPos; r.length = len;
        NSString *val = [saveData substringWithRange:r];
        // SNSLog(@"find val:%@", val);
        
        [info setValue:val forKey:key];
        lastPos += len;
    }
    return info;
}

#pragma mark -


#pragma mark Notice

// 获得当前公告版本号
+ (int) getNoticeVersion
{
	NSString *key = [NSString stringWithFormat:@"noticeVer-%@", [self getCountryCode]];
	NSNumber *ver = [[self config] objectForKey:key];
	return [ver intValue];
}

// 检查一个公告是否有效
+ (BOOL) isNoticeValid:(NSDictionary *)noticeInfo
{
    if(![self isSavedNoticeValid:noticeInfo]) return NO;
    // check version
    int noticeID = [[noticeInfo objectForKey:@"id"] intValue];
    int noticeVer = [[noticeInfo objectForKey:@"noticeVer"] intValue];
    NSString *key = [NSString stringWithFormat:@"noticeVer-%i", noticeID];
    int oldVer = [[self getGlobalSetting:key] intValue];
    int autoUpdate = [[noticeInfo objectForKey:@"auto_update"] intValue];
    if(autoUpdate==0) {
        if(noticeVer>0 && oldVer == noticeVer) {
            SNSLog(@"notice already shown: key:%@ ver:%i curVer:%i", key, oldVer, noticeVer);
            return NO;
        }
    }
    else {
        if(oldVer==[self getTodayDate]) {
            SNSLog(@"notice already shown: key:%@ date:%i", key, oldVer);
            return NO;
        }
    }
    return YES;
}

// 检查一个现有公告是否有效
+ (BOOL) isSavedNoticeValid:(NSDictionary *)noticeInfo
{
    if(![noticeInfo isKindOfClass:[NSDictionary class]]) {
        SNSLog(@"invalid notice:%@", noticeInfo);
        return NO;
    }
    // check os 
    int osType = [[noticeInfo objectForKey:@"os"] intValue];
    if(osType != 0) return NO;
    
#ifdef DEBUG
    // if([[noticeInfo objectForKey:@"id"] intValue]==5) return YES;
#endif
    
    // check start time and end time
    int sTime = [[noticeInfo objectForKey:@"startTime"] intValue];
    int eTime = [[noticeInfo objectForKey:@"endTime"] intValue];
    int now = [self getCurrentTime];
    if(sTime>0 && eTime>0 && (now < sTime || now>eTime)) {
        SNSLog(@"notice expired or not start: now:%i sTime:%i eTime:%i", now, sTime, eTime);
        return NO;
    }
    
    
#ifndef DEBUG
    // check level
    int level = [[noticeInfo objectForKey:@"level"] intValue];
    int userLevel = [[self getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel];
    if(level>userLevel) return NO;
#endif
    
    int type = [[noticeInfo objectForKey:@"type"] intValue];
    if(type==3 || type==4 || type==5) {
        // check country
        if(![SystemUtils getNoticeCountryCode:[noticeInfo objectForKey:@"country"]]) return NO;
    }
    
    // check payment: 单位是美分, 用户付费额度要位于设定的金额之间才显示
    int maxPayment = [[noticeInfo objectForKey:@"maxMoney"] intValue];
    int minPayment = [[noticeInfo objectForKey:@"minMoney"] intValue];
    int userMoney  = [[SnsStatsHelper helper] getTotalPay];
    if(maxPayment>0 && userMoney>maxPayment) return NO;
    if(minPayment>0 && userMoney<minPayment) return NO;
    
    NSString *prizeCond = [noticeInfo objectForKey:@"prizeCond"];
    NSString *urlScheme = [noticeInfo objectForKey:@"urlScheme"];
    if(prizeCond && urlScheme && [prizeCond length]>0 && [urlScheme length]>0)
    {
#ifndef DEBUG
        // 审核期间不显示带奖励安装
        if(![self isAdVisible]) return NO;
#endif
        NSURL *url = [NSURL URLWithString:urlScheme];
        if([prizeCond isEqualToString:@"install"]) {
            // 对于安装广告，如果用户已经安装过，就不再显示
            if([[UIApplication sharedApplication] canOpenURL:url]) return NO;
        }
        else {
            // 对于带条件的奖励广告，如果没有安装就不显示
            if(![[UIApplication sharedApplication] canOpenURL:url]) return NO;
        }
        // 对于奖励广告，如果已经点过就不再显示
        int noticeID = [[noticeInfo objectForKey:@"id"] intValue];
        NSString *clickKey = [NSString stringWithFormat:@"prizeClick_%d",noticeID];
        int clickTime = [[[SystemUtils getGameDataDelegate] getExtraInfo:clickKey] intValue];
        if(clickTime>0) return NO;
    }
    
    return YES;
}

// 获取当前公告的国家代码，如果当前公告不包含当前设备区域，将返回nil
+ (NSString *) getNoticeCountryCode:(NSString *)country
{
    // check country
    NSString *userCountry = [SystemUtils getOriginalCountryCode];
    BOOL isGeneral = NO; BOOL hasCountry = NO;
    // NSString *country = [notice objectForKey:@"country"];
    if(country && [country isKindOfClass:[NSString class]]) {
        NSArray *arr = [country componentsSeparatedByString:@","];
        for(NSString *c in arr) {
            if([c isEqualToString:@"GENERAL"]) isGeneral = YES;
            else if([c isEqualToString:userCountry]) {
                hasCountry = YES; break;
            }
        }
        // not for current player
        if(hasCountry) return userCountry;
        if(isGeneral) return @"GENERAL";
    }
    return nil;
}
// format: {"gid":123,"coin":100,"hint":"here is 100 coins.","leaf":0,"items":""}
+ (void) showGMPrize:(NSDictionary *)gmPrize
{
	if(gmPrize==nil || ![gmPrize isKindOfClass:[NSDictionary class]]) return;
    SNSLog(@"GMPrize:%@",gmPrize);
    // check if gid is duplicate
    NSString *gid = [gmPrize objectForKey:@"gid"];
    if(gid!=nil) {
        NSString *key = [NSString stringWithFormat:@"gmgift-%@",gid];
        NSString *val = [[self getGameDataDelegate] getExtraInfo:key];
        if(val==nil) {
            [[self getGameDataDelegate] setExtraInfo:@"1" forKey:key];
        }
        else {
            // duplicate
            SNSLog(@"This gid(%@) is already exists.",gid);
            return;
        }
    }
    
    int prizeCoin = [[gmPrize objectForKey:@"coin"] intValue];
    int prizeLeaf = [[gmPrize objectForKey:@"leaf"] intValue];
    int prizeExp  = [[gmPrize objectForKey:@"exp"]  intValue];
    int level  = [[gmPrize objectForKey:@"level"]  intValue];
    NSString *mesg = [gmPrize objectForKey:@"hint"];
    NSString *items = [gmPrize objectForKey:@"items"];
    
    if(mesg && [mesg length]>5 && (prizeCoin>0 || prizeLeaf>0 || prizeExp>0 || [items length]>1)) {
        
        smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
        swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"content", @"", @"action", [NSString stringWithFormat:@"%d",prizeCoin], @"prizeCoin",
                            [NSString stringWithFormat:@"%d", prizeLeaf], @"prizeLeaf",
                            [NSNumber numberWithInt:prizeExp], @"prizeExp",
                            [NSNumber numberWithInt:level], @"setLevel",
                            items, @"prizeItems", nil];
        [[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:10.0f];
        [swqAlert release];
        
        [[self config] removeObjectForKey:@"gmPrize"];
        [self saveGlobalSetting];
    }
}


// 显示有些内公告
+ (void) showInGameNotice
{
	// if(YES) return;
	// SNSLog(@"start");
    //NSNotification *note = [NSNotification notificationWithName:kSNSNotificationUpdateStatus object:nil userInfo:nil];
    //[[NSNotificationCenter defaultCenter] postNotification:note];
    
    if(!_currentGameDataDelegate || ![_currentGameDataDelegate isTutorialFinished]) return;
    
    //显示每日奖励
    int dailyBonusDelay = 0;
    if([self showDailyBonusPopup]) 
        dailyBonusDelay = 30;
    
	// 显示客服奖励, coin,leaf,exp,hint,items,level
	NSDictionary *gmPrize = [[self config] objectForKey:@"gmPrize"];
	[self showGMPrize:gmPrize];

    
#ifndef DEBUG
    if([self getLoginDayCount]<3) return;
#endif
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    int nowTime = [self getCurrentTime];

#ifndef SNS_ENABLE_MINICLIP
    if([[self getSystemInfo:@"kNoRateHint"] intValue]==0) {
        // 提示评价
        int rateTimes = [def integerForKey:@"kRateHintCounter"];
#ifdef DEBUG
        // rateTimes = 8;
#endif
        if(rateTimes==8) {
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
            [self addReviewHintNotice];
#else
            [self showReviewHint];
#endif
        }
        if(rateTimes<10) {
            [def setInteger:rateTimes+1 forKey:@"kRateHintCounter"];
            [def synchronize];
        }
        if(rateTimes==8) {
            return;
        }
    }
#endif
	// 检查新版更新提示
	NSString  *ver = [self getGlobalSetting:kCurrentOnlineVersionKey];
    if(!ver) ver = @"0";
	NSString *curVer = [self getClientVersion];
	//int checkTime  = [[SystemUtils getNSDefaultObject:@"updateHintCheckTime"] intValue];
	//int checkCount = [[SystemUtils getNSDefaultObject:@"updateHintCheckCount"] intValue];
    NSString *lastVer = [SystemUtils getNSDefaultObject:@"kLastNewVersion"];
    if(!lastVer || ![lastVer isKindOfClass:[NSString class]]) lastVer = @"0";
	// int deviceTime = [self getCurrentDeviceTime];
	BOOL showNotice = NO;
	// if([ver doubleValue] > [curVer doubleValue] && ![ver isEqualToString:lastVer]) showNotice = YES;
	if([ver compare:curVer]>0 && ![ver isEqualToString:lastVer]) showNotice = YES;
#ifdef DEBUG
	// showNotice = YES;
	// NSLog(@"%s: always show update notice", __func__);
#endif
	if(showNotice) {
		//[self setNSDefaultObject:[NSNumber numberWithInt:checkTime]  forKey:@"updateHintCheckTime"];
		//[self setNSDefaultObject:[NSNumber numberWithInt:checkCount] forKey:@"updateHintCheckCount"];
        [self setNSDefaultObject:ver forKey:@"kLastNewVersion"];
		NSString *title = [self getLocalizedString:@"Please update"];
        NSString *mesg = [self getGlobalSetting:kCurrentVersionDescKey];
		if(!mesg || [mesg isEqual:[NSNull null]]) mesg = @"New Version Available!";
        mesg = [self parseMultiLangStrForCurrentLang:mesg];
        mesg = [self getLocalizedString:mesg];
#ifdef SNS_CUSTOM_UPDATE_DIALOG
        // send notification
        // 发送通知
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: mesg, @"mesg", title, @"title", [NSNumber numberWithBool:NO], @"forceUpdate", nil];
        NSNotification *note = [NSNotification notificationWithName:kSNSNotificationOnShowUpdateDialog object:nil userInfo:info];
        [[NSNotificationCenter defaultCenter] postNotification:note];
#else
        
		// [self incAlertViewCount];
        SNSAlertView *av = [[SNSAlertView alloc] 
                            initWithTitle:title
                            message:mesg
                            delegate:appDelegate
                            cancelButtonTitle:[self getLocalizedString:@"No Thanks"]
                            otherButtonTitle:[self getLocalizedString:@"Download Now!"], nil];
        
		av.tag = kTagAlertViewDownloadApp;
        [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
		[av release];
#endif
		return;
	}
    if([curVer isEqualToString:ver])
    {
        // check current version info
        NSString *newFeatureVer = [self getNSDefaultObject:@"showNewFeatureVer"];
#ifdef DEBUG
        // newFeatureVer = nil;
#endif
        if(!newFeatureVer || ![newFeatureVer isKindOfClass:[NSString class]] || ![curVer isEqualToString:newFeatureVer])
        {
            [self setNSDefaultObject:curVer forKey:@"showNewFeatureVer"];
            NSString *mesg = [self getGlobalSetting:kCurrentNewFeatureKey];
            if(mesg && [mesg isKindOfClass:[NSString class]] && [mesg length]>10) {
                mesg = [self parseMultiLangStrForCurrentLang:mesg];
                SNSAlertView *av = [[SNSAlertView alloc] 
                                    initWithTitle:[self getLocalizedString:@"What's New"]
                                    message:[self getLocalizedString:mesg]
                                    delegate:nil
                                    cancelButtonTitle:[self getLocalizedString:@"OK"]
                                    otherButtonTitle: nil];
                
                [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
                [av release];
                return;
            }
        }
	}
	SNSLog(@"check ver ok");
	
	// 远程获取的游戏内公告
	BOOL adShown = NO;
	int noticeNum = 0;
    int userLevel = 0;
    if(_currentGameDataDelegate) 
        userLevel = [_currentGameDataDelegate getGameResourceOfType:kGameResourceTypeLevel];
    
	NSArray *noticeList = [[self config] objectForKey:@"noticeInfo"];
    
    /*
#ifdef DEBUG
    noticeList = @[@{
        @"action":@"https://itunes.apple.com/app/id538339878",
        @"auto_update": @0,
        @"country": @"GENERAL",
        @"country_limit":@0,
        @"endTime":@2899967800,
        @"hideClose":@0,
        @"id":@"100000",
        @"level":@0,
        @"message":@"在龙之魂中达到10级，可以获得10个宝石奖励，要接受挑战吗？",
        @"noticeVer":@3,
        @"os":@0,
        @"picBig":@"photo_hd5.png",
        @"picExt":@"png",
        @"picSmall":@"photo5.png",
        @"picVer":@0,
        @"prizeCond":@"install",
        @"prizeMesg":@"You've reached level 10 in Dragon Soul, you got 10 gems as bonus!",
        @"prizeGold":@0,
        @"prizeItem":@"",
        @"prizeId":@0,
        @"prizeLeaf":@10,
        @"startTime":@1389190200,
        @"subID":@"",
        @"type":@3,
        @"updateTime":@0,
        @"noClose":@1,
        @"urlScheme":@"dragonsoul://"
    }];
#endif
     */
    
	if(noticeList && [noticeList isKindOfClass:[NSArray class]])
	{
		for(NSDictionary *noticeInfo in noticeList)
		{
            if(![self isNoticeValid:noticeInfo]) continue;
			// check version
			int noticeID = [[noticeInfo objectForKey:@"id"] intValue];
			int noticeVer = [[noticeInfo objectForKey:@"noticeVer"] intValue];
            int showPopup = 1;
            
			NSString *key = [NSString stringWithFormat:@"noticeVer-%i", noticeID];
            
			int type = [[noticeInfo objectForKey:@"type"] intValue];
			NSString *mesg = [noticeInfo objectForKey:@"message"];
			if((type==1 || type==0) && mesg && [mesg length]>10) 
			{
				NSString *action = [noticeInfo objectForKey:@"action"]; // showPetRoomMarket
				int prizeCoin = [[noticeInfo objectForKey:@"prizeGold"] intValue];
				int prizeLeaf = [[noticeInfo objectForKey:@"prizeLeaf"] intValue];
				
				if([action isEqualToString:@"showTapjoy"]) {
                    continue;
					[self setGlobalSetting:[NSNumber numberWithInt:[self getCurrentTime]] forKey:kTapjoyShowTime];
					adShown = YES;
				}
				if([action isEqualToString:@"showFlurry"]) {
                    continue;
					[self setGlobalSetting:[NSNumber numberWithInt:[self getCurrentTime]] forKey:kFlurryShowTime];
					adShown = YES;
				}
				
				smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
				swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"content", action, @"action", [NSNumber numberWithInt:prizeCoin], @"prizeCoin", [NSNumber numberWithInt:prizeLeaf], @"prizeLeaf", [noticeInfo objectForKey:@"id"], @"noticeID", nil];
				[[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:3.0f+noticeNum*10];
				[swqAlert release];
				
			}
			if(type == 2) {
				// image notice
                int picVer = [[noticeInfo objectForKey:@"picVer"] intValue];
				NSString *imageFile = [self getNoticeImageFile:noticeID withVer:picVer];
				if(![[NSFileManager defaultManager] fileExistsAtPath:imageFile]) continue;
				
				NSString *action = [noticeInfo objectForKey:@"action"];
				int prizeCoin = [[noticeInfo objectForKey:@"prizeGold"] intValue];
				int prizeLeaf = [[noticeInfo objectForKey:@"prizeLeaf"] intValue];
				//开始显示广告窗口
                if([self isRetina]) imageFile = [imageFile stringByReplacingOccurrencesOfString:@"@2x" withString:@""];
				smPopupWindowImageNotice *swqImageAlert = [[smPopupWindowImageNotice alloc] initWithNibName:@"smPopupWindowImageNotice" bundle:nil];
				swqImageAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:imageFile, @"image", action, @"action", [NSNumber numberWithInt:prizeCoin], @"prizeCoin", [NSNumber numberWithInt:prizeLeaf], @"prizeLeaf", [noticeInfo objectForKey:@"id"], @"noticeID", nil];
                if([[noticeInfo objectForKey:@"auto_update"] intValue]==1)
                    swqImageAlert.shouldDeleteImage = NO;
				[[smPopupWindowQueue createQueue] pushToQueue:swqImageAlert timeOut:3.0f+noticeNum*10];
				[swqImageAlert release];
			}
            NSString *action = [noticeInfo objectForKey:@"action"]; // showPetRoomMarket
            int prizeCoin = [[noticeInfo objectForKey:@"prizeGold"] intValue];
            int prizeLeaf = [[noticeInfo objectForKey:@"prizeLeaf"] intValue];
            int noClose   = [[noticeInfo objectForKey:@"noClose"] intValue];
            NSString *prizeItem = [noticeInfo objectForKey:@"prizeItem"];
            NSString *urlScheme = [noticeInfo objectForKey:@"urlScheme"];
            int pendingPrize = 0;
            if(urlScheme && [urlScheme length]>0) {
                prizeCoin = 0; prizeLeaf = 0; prizeItem = nil;
                pendingPrize = 1;
                [self setNSDefaultObject:noticeInfo forKey:[NSString stringWithFormat:@"prizeNotice-%d",noticeID]];
            }
            
			if(type==3 && mesg && [mesg length]>10)
			{
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
                showPopup = [[noticeInfo objectForKey:@"popup"] intValue];
                if(showPopup==0)
                    [SNSPromotionViewController addNotice:noticeInfo];
#endif
                if(showPopup==1) {
                mesg = [self parseMultiLangStrForCurrentLang:mesg];
				smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
				swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"content", action, @"action", [NSNumber numberWithInt:prizeCoin], @"prizeCoin", [NSNumber numberWithInt:prizeLeaf], @"prizeLeaf", [NSNumber numberWithInt:pendingPrize], @"pendingPrize", [NSNumber numberWithInt:noClose], @"noClose", [noticeInfo objectForKey:@"id"], @"noticeID", nil];
				[[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:3.0f+noticeNum*10];
				[swqAlert release];
                }
			}
            
			if(type == 4) {
				// new image notice
                int picVer = [[noticeInfo objectForKey:@"picVer"] intValue];
                NSString *countryCode = [self getNoticeCountryCode:[noticeInfo objectForKey:@"country"]];
				NSString *imageFile = [self getNoticeImageFile:noticeID withVer:picVer andCountry:countryCode];
				if(![[NSFileManager defaultManager] fileExistsAtPath:imageFile]) continue;
                if([self isRetina]) imageFile = [imageFile stringByReplacingOccurrencesOfString:@"@2x" withString:@""];
				
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
                showPopup = [[noticeInfo objectForKey:@"popup"] intValue];
                if(showPopup==0)
                    [SNSPromotionViewController addNotice:noticeInfo];
#endif
                if(showPopup==1) {
				//开始显示广告窗口
				smPopupWindowImageNotice *swqImageAlert = [[smPopupWindowImageNotice alloc] initWithNibName:@"smPopupWindowImageNotice" bundle:nil];
				swqImageAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:imageFile, @"image", action, @"action", [NSNumber numberWithInt:prizeCoin], @"prizeCoin", [NSNumber numberWithInt:prizeLeaf], @"prizeLeaf", [NSNumber numberWithInt:pendingPrize], @"pendingPrize", [NSNumber numberWithInt:noClose], @"noClose", [noticeInfo objectForKey:@"id"], @"noticeID", nil];
				[[smPopupWindowQueue createQueue] pushToQueue:swqImageAlert timeOut:3.0f+noticeNum*10];
				[swqImageAlert release];
                }
			}
            int autoUpdate = [[noticeInfo objectForKey:@"auto_update"] intValue];
            if(autoUpdate==1)
                [self setGlobalSetting:[NSNumber numberWithInt:[self getTodayDate]] forKey:key];
            else
                [self setGlobalSetting:[NSNumber numberWithInt:noticeVer] forKey:key];
			
            noticeNum++;
		}
		// [[self config] removeObjectForKey:@"noticeInfo"];
		// [self saveGlobalSetting];
	}
	SNSLog(@"remote notice ok");
	
    if(noticeNum>0) return;
    // 审核期间不显示广告
    BOOL adEnabled= [self isAdVisible];
    if(!adEnabled) return;
    if([self shouldIgnoreAd]) return;
    
#ifndef DEBUG
    // 对付费玩家不显示任何广告
    if([[SnsStatsHelper helper] getTotalPay]>0) return;
#endif
    // 显示定制的offer窗口, kDailyFreeOfferCommand, kDailyFreeOfferNotice, kDailyFreeOfferEnable
    int offerEnable = [[_globalConfig objectForKey:@"kDailyFreeOfferEnable"] intValue];
    int lastTime = [[self getNSDefaultObject:@"kDailyFreeOfferTime"] intValue];
#ifdef DEBUG
    // lastTime = 0;
#endif
    NSString *cmds = [_globalConfig objectForKey:@"kDailyFreeOfferCommand"];
    NSString *cmds2 = [_globalConfig objectForKey:@"kDailyFreeOfferCommand2"]; // 这个支持轮流
    if(cmds2!=nil && [cmds2 length]>3) cmds = cmds2;
    if(cmds==nil) cmds = @"";
    if(adEnabled && !adShown && offerEnable == 1 && lastTime < nowTime - (43200+3600) && [cmds length]>3)
    {
        [self setNSDefaultObject:[NSString stringWithFormat:@"%i",nowTime] forKey:@"kDailyFreeOfferTime"];
        int idx = [[self getNSDefaultObject:@"kDailyFreeOfferIndex"] intValue];
        NSArray *arr = [cmds componentsSeparatedByString:@","];
        if(idx>=[arr count]) idx = 0;
        NSString *cmd = [arr objectAtIndex:idx];
        [self setNSDefaultObject:[NSString stringWithFormat:@"%d",idx+1] forKey:@"kDailyFreeOfferIndex"];
        NSString *mesg = [_globalConfig objectForKey:@"kDailyFreeOfferNotice"];
        int prizeCoin = 0; int prizeLeaf = 0;
        if(mesg && [mesg length]>10)
        {
            SNSLog(@"show dailyFreeOffer: %@ withMesg:%@ ", cmd, mesg );
            // show notice
			smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
			swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"content", cmd, @"action", [NSString stringWithFormat:@"%d",prizeCoin], @"prizeCoin", [NSString stringWithFormat:@"%d", prizeLeaf], @"prizeLeaf", nil];
			[[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:30.0f+noticeNum*10];
			[swqAlert release];
        }
        else {
            SNSLog(@"show dailyFreeOffer: %@", cmd );
            _sysPendingCommand = [cmd retain];
            // run command directly
            [self performSelector:@selector(runPendingCommand) withObject:nil afterDelay:30.0f+noticeNum*10];
            // [self runCommand:cmd];
        }
        noticeNum += 3;
        return;
        // adShown = YES;
    }
    
#ifdef SNS_ENABLE_TINYMOBI
    // adShown = [[TinyMobiHelper helper] showPopupAd];
#endif
    // 轮换显示chartboost, tapjoy, flurry, playhaven
    // kPopupOfferList
    // 对付费玩家不显示任何广告
    if([[SnsStatsHelper helper] getTotalPay]>0) return;
    //  lastOfferTime < nowTime-3600
    NSString *offerList = [_globalConfig objectForKey:@"kPopupOfferList"];
    // 如果有 kPopupOfferList2，就用它
    NSString *offer2 = [_globalConfig objectForKey:@"kPopupOfferList2"];
    if(offer2!=nil && [offer2 length]>2) offerList = offer2;
    
    offerEnable = [[_globalConfig objectForKey:@"kPopupOfferEnable"] intValue];
#ifndef DEBUG
    int lastOfferTime = [def integerForKey:@"lastShowOfferTime"];
    if(lastOfferTime > nowTime-43200) offerList = nil;
#endif
    if(adEnabled && offerList && offerEnable==1 && [[SnsStatsHelper helper] getTotalPay]==0)
    {
        [self setNSDefaultObject:[NSString stringWithFormat:@"%i",nowTime] forKey:@"lastShowOfferTime"];
        [[self class] performSelector:@selector(showAutoPopupOffer:) withObject:offerList afterDelay:10.0f+dailyBonusDelay];
        // [self showPopupOffer:10.0f+dailyBonusDelay];
    }
#ifdef DEBUG
    // [[GreystripeHelper helper] showOffers:NO];
#endif
    
    // show Admob
    // [[SnsServerHelper helper] showAdmobBanner];
    
	// 提示用户授权
	SNSLog(@"all ok");
}

+ (void) runPendingCommand
{
    if(_sysPendingCommand==nil) return;
    [self runCommand:_sysPendingCommand];
    [_sysPendingCommand autorelease];
    _sysPendingCommand = nil;
}

+ (NSDictionary *)getSpecialIAPInfo
{
    NSString *offerStr = [self getGlobalSetting:@"kSpecialIAPOffer"];
    if(!offerStr) return nil;
    NSDictionary *offerInfo = [StringUtils convertJSONStringToObject:offerStr];
    if(!offerInfo || ![offerInfo isKindOfClass:[NSDictionary class]]) return nil;
    return offerInfo;
}

// 检查是否是特价IAP，如果是，就返回增加的数额，否则返回0
+ (int) getSpecialIapBonusAmount:(NSString *)iapID withCount:(int)count
{
    NSString *specialIapItem = [self getNSDefaultObject:@"kSpecialIapItem"];
    if(specialIapItem==nil || [specialIapItem rangeOfString:iapID].location==NSNotFound) return 0;
    
    NSDictionary *info = [self getSpecialIAPInfo];
    if(!info) return 0;
    
    // NSString *itemName = [NSString stringWithFormat:@"%@%@", [self getSystemInfo:@"kIapItemPrefix"], [info objectForKey:@"iap"]];
    NSString *itemName = [info objectForKey:@"iap"];
    if(![itemName isEqualToString:iapID]) {
        itemName = [NSString stringWithFormat:@"%@%@", [self getSystemInfo:@"kIapItemPrefix"], [info objectForKey:@"iap"]];
    }
    if(![itemName isEqualToString:iapID]) return 0;
    
    float rate = [[info objectForKey:@"bonusRate"] floatValue];
    int addup = rate * count;
    
    SNSLog(@"add special iap bonus %i", addup);
    [self setNSDefaultObject:nil forKey:@"kSpecialIapItem"];
    
    return addup;
}

// 显示IAP促销广告
+ (BOOL) showSpecialIapOffer:(NSString *)suffix
{
    NSDictionary *offerInfo = [self getSpecialIAPInfo];
    
    int now = [self getCurrentTime];
#ifndef DEBUG
    int delayHours = [[offerInfo objectForKey:@"delay"] intValue];
    int lastTime = [[self getNSDefaultObject:@"kSpecialIapOfferTime"] intValue];
    if(lastTime>now-delayHours*3600) return NO;
#endif
    // check start and end time
    NSString *startStr = [offerInfo objectForKey:@"start"];
    NSString *endStr   = [offerInfo objectForKey:@"end"];
    NSDate *stDate = [StringUtils convertStringToDate:startStr];
    NSDate *edDate = [StringUtils convertStringToDate:endStr];
    if([stDate timeIntervalSince1970]>now || [edDate timeIntervalSince1970]<now) return NO;
    // check if image ready
    NSString *imgName = [offerInfo objectForKey:@"imageName"];
    if(suffix!=nil) {
        NSString *newName = [offerInfo objectForKey:[NSString stringWithFormat:@"imageName%@",suffix]];
        if(newName!=nil) imgName = newName;
    }
    if(imgName==nil) return NO;
    NSString *path = [self getItemImagePath];
    NSString *imageFile = [NSString stringWithFormat:@"%@/%@.png", path, imgName];
    if(![[NSFileManager defaultManager] fileExistsAtPath:imageFile]) {
        SNSLog(@"image not found:%@", imageFile);
        return NO;
    }
    NSString *closeBtnImage = [NSString stringWithFormat:@"%@/%@-close.png", path, imgName];
    if(![[NSFileManager defaultManager] fileExistsAtPath:closeBtnImage])
        closeBtnImage = nil;
    
    // check if iap item ready
    NSString *itemName = [NSString stringWithFormat:@"%@%@", [self getSystemInfo:@"kIapItemPrefix"], [offerInfo objectForKey:@"iap"]];
    if(![[InAppStore store] isIAPItemDownloaded:itemName]) return NO;
    
    // show offer window now
    // image notice
    NSString *action = @"buySpecialIAP";
    //开始显示广告窗口
    smPopupWindowImageNotice *swqImageAlert = [[smPopupWindowImageNotice alloc] initWithNibName:@"smPopupWindowImageNotice" bundle:nil];
    swqImageAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:imageFile, @"image", action, @"action", [NSNumber numberWithInt:0], @"prizeCoin", [NSNumber numberWithInt:0], @"prizeLeaf", offerInfo, @"offerInfo", closeBtnImage, @"closeBtnImage", nil];
    swqImageAlert.shouldDeleteImage = NO;
    [[smPopupWindowQueue createQueue] pushToQueue:swqImageAlert timeOut:0];
    [swqImageAlert release];
    
    [self setNSDefaultObject:[NSNumber numberWithInt:now] forKey:@"kSpecialIapOfferTime"];
    return YES;
}

+ (BOOL) buySpecialIAP
{
    NSDictionary *offerInfo = [self getSpecialIAPInfo];
    NSString *itemName = [NSString stringWithFormat:@"%@%@", [self getSystemInfo:@"kIapItemPrefix"], [offerInfo objectForKey:@"iap"]];
    
    [self setNSDefaultObject:itemName forKey:@"kSpecialIapItem"];
    
    [[InAppStore store] buyAppStoreItem:itemName amount:1 withDelegate:nil];
    
    return YES;
}


// 显示某个广告商的弹窗广告，如果显示成功返回YES，否则NO
+ (BOOL) showPopupOfferOfType:(NSString *)vender
{
    SNSLog(@"show offer from %@", vender);
    if(vender==nil || [vender length]==0) return NO;
#ifndef DEBUG
#ifndef SNS_ENABLE_LIMEI2
    // 付费用户不显示广告
    if([[SnsStatsHelper helper] getTotalPay]>0) return NO;
#endif
#endif
    // 如果有未显示公告，就不显示广告
    if([[smPopupWindowQueue createQueue] queueCount]>0) return NO;
    
#ifndef SNS_DISABLE_CHARTBOOST
    if([vender isEqualToString:@"chartboost"]) {
        // show chartboost
        [[ChartBoostHelper helper] showPopupOffer];
        return YES;
    }
#endif
#ifndef SNS_DISABLE_TAPJOY
    if([vender isEqualToString:@"tapjoy"]) {
        // show tapjoy
        [[TapjoyHelper helper] startGettingTapjoyFeaturedApp];
        return YES;
    }
#endif
#ifdef SNS_ENABLE_TAPJOY2
    if([vender isEqualToString:@"tapjoy"]) {
        // show tapjoy
        [[TapjoyHelper2 helper] showOffers];
        return YES;
    }
    if([vender isEqualToString:@"tapjoyFeature"]) {
        // show tapjoy
        [[TapjoyHelper2 helper] startGettingTapjoyFeaturedApp];
        return YES;
    }
#endif
#ifndef SNS_DISABLE_PLAYHAVEN
    if([vender isEqualToString:@"playhaven"]) {
        return [[PlayHavenHelper helper] showFeaturedApp];
    }
    if([vender isEqualToString:@"playhavenOffer"]) {
        return [[PlayHavenHelper helper] showOffer:NO];
    }
#endif
#ifdef SNS_ENABLE_FLURRY_V2
    if([vender isEqualToString:@"flurry"]) {
        // show flurry offer
        BOOL res = [[FlurryHelper2 helper] showOffer2];
        if(res) return YES;
    }
#endif
#ifdef SNS_ENABLE_MDOTM
    if([vender isEqualToString:@"mdotm"]) {
        // show flurry offer
        BOOL res = [[MdotMHelper helper] showOffer:NO];
        if(res) return YES;
    }
#endif
    
#ifdef SNS_ENABLE_APPLOVIN
    if([vender isEqualToString:@"applovin"]) {
        return [[AppLovinHelper helper] showPopupOffer];
        // return YES;
    }
    if([vender isEqualToString:@"applovinVideo"]) {
        return [[AppLovinHelper helper] showRewardVideoOffer];
        // return YES;
    }
#endif
    
#ifdef SNS_ENABLE_SPONSORPAY
    if([vender isEqualToString:@"sponsorpay"]) {
        [[SponsorPayHelper helper] showPopupOffer];
        return YES;
    }
    if([vender isEqualToString:@"sponsorpayWall"]) {
        [[SponsorPayHelper helper] showOfferWall];
        return YES;
    }
#endif
#ifdef SNS_ENABLE_AARKI
    if([vender isEqualToString:@"aarki"]) {
        [[AarkiHelper helper] showPopupOffer];
        return YES;
    }
    if([vender isEqualToString:@"aarkiWall"]) {
        [[AarkiHelper helper] showOfferWall];
        return YES;
    }
#endif
#ifdef SNS_ENABLE_LIMEI2
    if([vender isEqualToString:@"limei"]) {
        [[LiMeiHelper2 helper] showOffers];
        return YES;
    }
    if([vender isEqualToString:@"limeiPopup"]) {
        [[LiMeiHelper2 helper] showInterstitial];
        return YES;
    }
#endif
#ifdef SNS_ENABLE_GUOHEAD
    if([vender isEqualToString:@"guohead"]) {
        [[MixGHHelper helper] showPopupOffer];
        return YES;
    }
#endif
#ifdef SNS_ENABLE_DOMOB
    if([vender isEqualToString:@"domob"]) {
        [[DomobHelper helper] showOffers];
        return YES;
    }
#endif
#ifdef SNS_ENABLE_YOUMI
    if([vender isEqualToString:@"youmi"]) {
        [[YoumiHelper helper] showOffers];
        return YES;
    }
#endif
#ifdef SNS_ENABLE_DIANRU
    if([vender isEqualToString:@"dianru"]) {
        [[DianruHelper helper] showOffers];
        return YES;
    }
#endif
#ifdef SNS_ENABLE_ADWO
    if([vender isEqualToString:@"adwo"]) {
        [[AdwoHelper helper] showOffers];
        return YES;
    }
    
    if([vender isEqualToString:@"adwoPopup"]) {
        [[AdwoHelper helper] showInterstitial];
        return YES;
    }
#endif
#ifdef SNS_ENABLE_IAD
    if([vender isEqualToString:@"iAd"]) {
        [[iAdHelper helper] showPopupOffer];
        return YES;
    }
#endif
#ifdef SNS_ENABLE_CHUKONG
    if([vender isEqualToString:@"chukong"]) {
        [[ChukongHelper helper] showOffers];
        return YES;
    }
    if([vender isEqualToString:@"chukongPopup"]) {
        [[ChukongHelper helper] showInterstitial];
        return YES;
    }
#endif
    
    
#ifdef SNS_ENABLE_YIJIFEN
    if([vender isEqualToString:@"yijifen"]) {
        [[YijifenHelper helper] showOffers];
        return YES;
    }
    if([vender isEqualToString:@"yijifenPopup"]) {
        [[YijifenHelper helper] showInterstitial];
        return YES;
    }
#endif
    
    
#ifdef SNS_ENABLE_WAPS
    if([vender isEqualToString:@"waps"]) {
        [[WapsHelper helper] showOffers];
        return YES;
    }
    if([vender isEqualToString:@"wapsPopup"]) {
        [[WapsHelper helper] showInterstitial];
        return YES;
    }
#endif
    
    
#ifdef SNS_ENABLE_MOBISAGE
    if([vender isEqualToString:@"mobisage"]) {
        [[MobiSageHelper helper] showOffers];
        return YES;
    }
    if([vender isEqualToString:@"mobisagePopup"]) {
        [[MobiSageHelper helper] showInterstitial];
        return YES;
    }
#endif
    
    return NO;
}
// 显示自动弹窗广告
+ (void) showAutoPopupOffer:(NSString *)offerList
{
    if(offerList==nil) return;
    NSString *vender = nil;
    NSArray *venderArr = [offerList componentsSeparatedByString:@","];
    int idx = 0;
    if([venderArr count]>1) idx = rand()%[venderArr count];
    vender = [venderArr objectAtIndex:idx];
    [self showPopupOfferOfType:vender];
    SNSLog(@"show offer type: %@", vender);
}
// 是否要忽略广告
+ (BOOL) shouldIgnoreAd
{
    int enableCloseAd = [[self getGlobalSetting:@"kCloseAdEnable"] intValue];
    if(enableCloseAd==0) return NO;
    int ignoreTime = [[self getNSDefaultObject:@"kAdCloseTime"] intValue];
    int now = [self getCurrentTime];
    if(now<ignoreTime && ignoreTime<now+864000) return YES;
    return NO;
}

// 增加忽略广告的次数
+ (void) addIgnoreAdCount
{
    int n = [[self getNSDefaultObject:@"kAdCloseCount"] intValue];
    n++;
    int max = [[self getGlobalSetting:@"kMaxCloseAdCount"] intValue];
    int delayDays = [[self getGlobalSetting:@"kCloseAdDays"] intValue];
    if(delayDays<=0) return;
    if(max<=0) max = 3;
    if(n>=max) {
        int now = [self getCurrentTime];
        [self setNSDefaultObject:[NSNumber numberWithInt:now+delayDays*86400] forKey:@"kAdCloseTime"];
    }
    [self setNSDefaultObject:[NSNumber numberWithInt:n] forKey:@"kAdCloseCount"];
}
// 重置忽略广告次数
+ (void) resetIgnoreAdCount
{
    [self setNSDefaultObject:@0 forKey:@"kAdCloseCount"];
}


+ (void) showPopupOffer // :(NSTimeInterval) delay
{
    
    if(!_gInterruptMode) {
        [[self class] performSelector:@selector(showPopupOffer) withObject:nil afterDelay:5.0f];
        return;
    }
    
    NSString *offerList = [_globalConfig objectForKey:@"kPopupOfferList"];
    // 如果有 kPopupOfferList2，就用它
    NSString *offer2 = [_globalConfig objectForKey:@"kPopupOfferList2"];
    if(offer2!=nil && [offer2 length]>2) offerList = offer2;
    NSArray *arr = [offerList componentsSeparatedByString:@","];
    int lastIndex = [[self getNSDefaultObject:@"kPopupOfferIndex"] intValue];
    if(lastIndex >= [arr count]) lastIndex = 0;
    [self setNSDefaultObject:[NSString stringWithFormat:@"%i",lastIndex+1] forKey:@"kPopupOfferIndex"];
    NSString *type = [arr objectAtIndex:lastIndex];
    [self showPopupOfferOfType:type];
    /*
    SNSLog(@"%s: show offer from %@", __func__, type);
#ifndef SNS_DISABLE_CHARTBOOST
    if([type isEqualToString:@"chartboost"])
        [[ChartBoostHelper helper] performSelector:@selector(showChartBoostOffer) withObject:nil afterDelay:delay];
#endif
#ifndef SNS_DISABLE_TAPJOY
    if([type isEqualToString:@"tapjoy"])
        [[TapjoyHelper helper] performSelector:@selector(startGettingTapjoyFeaturedApp) withObject:nil afterDelay:delay];
#endif
#ifndef SNS_DISABLE_FLURRY_V1
    else if([type isEqualToString:@"flurry"])
        [FlurryHelper performSelector:@selector(showRecommendation) withObject:nil afterDelay:delay];
#endif
#ifndef SNS_DISABLE_GREYSTRIPE
    else if([type isEqualToString:@"greystripe"] && ![self isiPad])
        [[GreystripeHelper helper] showOffers:NO];
#endif
#ifndef SNS_DISABLE_PLAYHAVEN
    // show playhaven
    if([type isEqualToString:@"playhaven"])
    {
        [[PlayHavenHelper helper] initSession];
        [[PlayHavenHelper helper] performSelector:@selector(showFeaturedApp) withObject:nil afterDelay:delay];
    }
#endif
     */
    
}

// 提示用户去Facebook Like我们
+ (BOOL) showFacebookLikePopup
{
    if(![self checkFeature:kFeatureShowAd]) return NO;
#ifndef DEBUG
    // no facebook for chinese
    if([[self getCountryCode] isEqualToString:@"CN"]) return NO;
#endif
    // Facebook Like
    NSString *link = [self getSystemInfo:@"kFacebookFansLink"];
    if(!link || [link length]<=10) return NO;
    // permanent once
    int lastDay = [[self getNSDefaultObject:@"kRandomPopupDate"] intValue];
    int today = [self getTodayDate];
#ifdef DEBUG
    // lastDay = 0;
#endif
    if(lastDay>0) return NO;
    [self setNSDefaultObject:[NSNumber numberWithInt:today] forKey:@"kRandomPopupDate"];
    if(link && [link length]>10)
    {
        int lastDay = [[self getNSDefaultObject:@"kFacebookLikeDate"] intValue];
#ifdef DEBUG
        // lastDay = 0;
#endif
#ifndef BRANCH_CN
        if(lastDay==0) {
            SNSAlertView *av = [[SNSAlertView alloc]
                                initWithTitle:[SystemUtils getLocalizedString: @"Having Fun?"]
                                message:[SystemUtils getLocalizedString: @"Love the game? Please like us on Facebook if you enjoy it!"]
                                delegate:appDelegate
                                cancelButtonTitle:[SystemUtils getLocalizedString:@"No Thanks"]
                                otherButtonTitle:[self getLocalizedString:@"Like!"], nil];
            
            av.tag = kTagAlertFacebookLikeUs;
            [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
            [av release];
            
            return YES;
        }
#endif
    }
    return NO;
}

// 获得打开游戏的次数
+ (int) getPlayTimes
{
    return [[self getNSDefaultObject:kPlayTimes] intValue];
}
// 获得邀请成功的人数
+ (int) getInviteSuccessTimes
{
    return [[[TinyiMailHelper helper] getTinyiMailObject:@"inviteSuccess"] intValue];
}

+ (int) getLoginDayPrizeCoin:(int)dayCount
{
    if(dayCount%5==0) return 0;
    return 1000;
}
// 显示邀请界面
+ (void) showInviteFriendsDialog
{
    [[TinyiMailHelper helper] showInviteFriendsPopup:YES];
}

+ (int) getLoginDayPrizeLeaf:(int)dayCount
{
    if(dayCount%5==0) return 1;
    return 0;
}

+(void)showLoginDayNum{
    [self showDailyBonusPopup];
}

// 获得连续登录次数
+ (int) getLoginDayCount
{
    int dayCount  = [[self getPlayerDefaultSetting:kLoginDateCount] intValue];
    return dayCount;
}
// 重置连续登陆天数
+ (void) resetLoginDayCount
{
    [self setPlayerDefaultSetting:@"0" forKey:kLoginDateCount];
}

// 获得前一天的日期
+ (int) getPrevDay:(int)date
{
	// 111125,111130,111201
	// 1201-1130=71
	// 0901-0830=71
	// 0801-0731=70
	// 0301-0228=73
	// 0301-0229=72
	// 120101-111231=20101-11231=10100-1230=9100-230=9000-130=8870
    int day = date%100;
    int mon = (date%10000-day)/100;
    int year = date/10000;
    if(day>1) return date-1;
    if(day<1) return 0;
    if(mon==2 || mon==4 || mon==6 || mon==8 || mon==9 || mon==11) 
        return date-70; // 1101-1031=70
    if(mon==1) return date-8870; // 120101-111231
    if(mon==3) {
        if(year%4==0) return date - 72; // 120301-120229=72
        return date - 73; // 110301-110228=73
    }
    if(mon==5 || mon==7 || mon==10 || mon==12) return date-71; // 1201-1130=71
    return 0;
}

+ (BOOL) showDailyBonusPopup
{
	// 连续登录
    if(!_currentGameDataDelegate || ![_currentGameDataDelegate isTutorialFinished]) return NO;
    // hackTime
    if([[self getGlobalSetting:kHackAlertTimes] intValue]>0 
       && ![NetworkHelper helper].connectedToInternet) return NO;
    // SNSLog(@"start");
    int todayDate = [self getTodayDate];
    int lastDate  = [[self getPlayerDefaultSetting:kLastLoginDate] intValue];
    if(lastDate == 0) 
        lastDate = [[_currentGameDataDelegate getExtraInfo:kLastLoginDate] intValue];
    int dayCount  = [[self getPlayerDefaultSetting:kLoginDateCount] intValue];
    if(dayCount == 0) 
        dayCount = [[_currentGameDataDelegate getExtraInfo:kLoginDateCount] intValue];
    
    // if(lastDate == todayDate) return;
    BOOL showAward = NO;
    // if(lastDate == [self getPrevDay:todayDate]) showAward = YES;
    if(lastDate != todayDate) {
		showAward = YES;
		//顺便清理一下giftbox的
		[self removeGlocalSettingForKey:@"faadWasClick"];
		[self removeGlocalSettingForKey:@"allOfferWasClick"];
	}
#ifdef DEBUG
    // showAward = YES;
#endif
    if(showAward)
    {
        dayCount++;
        // 发送通知
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:todayDate], @"today", nil];
        NSNotification *note = [NSNotification notificationWithName:kSNSNotificationSendDailyRewards object:nil userInfo:info];
        [[NSNotificationCenter defaultCenter] postNotification:note];
        
#ifndef SNS_DISABLE_DAILY_PRIZE
		int dayNum = dayCount%5; //连续登陆天数
		int userLevel = [[self getGameDataDelegate] getGameResourceOfType:4]-1;
		
		//每级奖励的用户金币（经验的话是这个数值的一半）
		NSArray *coinOrCashForLevel = [NSArray arrayWithObjects:@"70", @"140", @"280", @"420", @"580", @"810", @"1060", @"1320", @"1670", @"1940", @"2320", @"2610", nil];
        if(userLevel >= [coinOrCashForLevel count]) userLevel = [coinOrCashForLevel count]-1;
		//每天奖励的系数（第三天和第五天是轮盘，所以系数另算）
		// NSArray *coefficient = [NSArray arrayWithObjects:@"0.2", @"0.5", @"0.9", @"1.4", @"2.0", nil];
		NSArray *coefficient = [NSArray arrayWithObjects:@"0.2", @"0.3", @"0.9", @"0.4", @"2.0", nil];
		NSMutableDictionary *setting = [[NSMutableDictionary dictionary] retain];
		//设置每天访问送的数值
		int awardValue = [[coinOrCashForLevel objectAtIndex:userLevel] intValue];
		NSArray *awardData = [NSArray arrayWithObjects:
							  [NSDictionary dictionaryWithObjectsAndKeys:@"coin", @"type", [NSString stringWithFormat:@"%d", (int)([[coefficient objectAtIndex:0] floatValue] * awardValue)], @"value", nil],
							  [NSDictionary dictionaryWithObjectsAndKeys:@"coin", @"type", [NSString stringWithFormat:@"%d", (int)([[coefficient objectAtIndex:1] floatValue] * awardValue)], @"value", nil],
							  [NSDictionary dictionaryWithObjectsAndKeys:@"roulette", @"type", @"1", @"value", nil],
							  [NSDictionary dictionaryWithObjectsAndKeys:@"coin", @"type", [NSString stringWithFormat:@"%d", (int)([[coefficient objectAtIndex:3] floatValue] * awardValue)], @"value", nil],
							  [NSDictionary dictionaryWithObjectsAndKeys:@"roulette", @"type", @"1", @"value", nil],
							  nil];
		[setting setValue:awardData forKey:@"awardData"];
		//设置轮盘内数值与类型
		float coinCoefficient[4] = {0.7f, 0.9f, 1.1f, 1.3f};
		float expCoefficient[3] = {0.7f, 1.0f, 1.3f};
		int cashCoefficient = (dayNum == 0)?4:2; //根据天数计算可以获得货币的数量
		int dayAwardValue = [[coefficient objectAtIndex:dayNum] floatValue] * awardValue; //计算根据系数今天可以获得的金币和经验的数量
		NSArray *rouletteData = [NSArray arrayWithObjects:
								 [NSDictionary dictionaryWithObjectsAndKeys:@"cash", @"type", [NSString stringWithFormat:@"%d",cashCoefficient], @"value", nil], 
								 [NSDictionary dictionaryWithObjectsAndKeys:@"coin", @"type", [NSString stringWithFormat:@"%d", (int)(dayAwardValue * coinCoefficient[0])], @"value", nil], 
								 [NSDictionary dictionaryWithObjectsAndKeys:@"level", @"type", [NSString stringWithFormat:@"%d", (int)(dayAwardValue * expCoefficient[0] * 0.5f)], @"value", nil], 
								 [NSDictionary dictionaryWithObjectsAndKeys:@"coin", @"type", [NSString stringWithFormat:@"%d", (int)(dayAwardValue * coinCoefficient[1])], @"value", nil], 
								 [NSDictionary dictionaryWithObjectsAndKeys:@"level", @"type", [NSString stringWithFormat:@"%d", (int)(dayAwardValue * expCoefficient[1] * 0.5f)], @"value", nil], 
								 [NSDictionary dictionaryWithObjectsAndKeys:@"coin", @"type", [NSString stringWithFormat:@"%d", (int)(dayAwardValue * coinCoefficient[2])], @"value", nil], 
								 [NSDictionary dictionaryWithObjectsAndKeys:@"level", @"type", [NSString stringWithFormat:@"%d", (int)(dayAwardValue * expCoefficient[2] * 0.5f)], @"value", nil], 
								 [NSDictionary dictionaryWithObjectsAndKeys:@"coin", @"type", [NSString stringWithFormat:@"%d", (int)(dayAwardValue * coinCoefficient[3])], @"value", nil], 
								 nil];
		[setting setValue:rouletteData forKey:@"rouletteData"];
		//设置让轮盘停止在什么位置(根据数据索引计算，从0开始到7结束，概率平均分)
		int stopGrid = arc4random()%8;
		[setting setValue:[NSNumber numberWithInt:stopGrid] forKey:@"stopIndex"];
		//设置连续登陆的天数
		[setting setValue:[NSNumber numberWithInt:dayNum] forKey:@"dayNum"];
		smPopupWindowDailyAwards *awardsWin = [[smPopupWindowDailyAwards alloc] initWithSetting:setting];
		[[smPopupWindowQueue createQueue] pushToQueue:awardsWin timeOut:0];
		[awardsWin release];
        [setting release];
        SNSLog(@"end");
#endif
//        if(todayCoin>0) {
//            [SystemUtils logResourceChange:kLogTypeEarnCoin 
//                                    method:kLogMethodTypeDailyBonus 
//                                    itemID:[NSString stringWithFormat:@"%i", dayNum] 
//                                     count:todayCoin];
//        }
//        if(todayLeaf>0) {
//            [SystemUtils logResourceChange:kLogTypeEarnLeaf
//                                    method:kLogMethodTypeDailyBonus 
//                                    itemID:[NSString stringWithFormat:@"%i", dayNum] 
//                                     count:todayLeaf];
//        }
    }
    else {
        // dayCount = 1;
    }
    [self setPlayerDefaultSetting:[NSNumber numberWithInt:dayCount] forKey:kLoginDateCount saveToFile:NO];
    [self setPlayerDefaultSetting:[NSNumber numberWithInt:todayDate] forKey:kLastLoginDate];
    [_currentGameDataDelegate setExtraInfo:[NSNumber numberWithInt:dayCount] forKey:kLoginDateCount];
    [_currentGameDataDelegate setExtraInfo:[NSNumber numberWithInt:todayDate] forKey:kLastLoginDate];
    return showAward;
}

// 显示游戏公告窗口
// {"mesg":"xxxx","mesgID":"localized key","action":"","prizeGold":"0","prizeLeaf":"0"}
+ (void)showCustomNotice:(NSDictionary *)noticeInfo
{
	NSString *mesg = [noticeInfo objectForKey:@"mesg"];
	if(mesg==nil) mesg = [self getLocalizedString:[noticeInfo objectForKey:@"mesgID"]];
	if(mesg==nil) return;
	NSString *action = [noticeInfo objectForKey:@"action"]; // showPetRoomMarket
	int prizeCoin = [[noticeInfo objectForKey:@"prizeGold"] intValue];
	int prizeLeaf = [[noticeInfo objectForKey:@"prizeLeaf"] intValue];
    NSString *items = [noticeInfo objectForKey:@"items"]; // @"prizeItems",
	
	smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
	swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"content", action, @"action", [NSString stringWithFormat:@"%d",prizeCoin], @"prizeCoin", [NSString stringWithFormat:@"%d", prizeLeaf], @"prizeLeaf", items, @"prizeItems", nil];
	[[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:3.0f];
    [swqAlert release];
}

// 是否有新道具
+ (BOOL) isNewItemAvailable
{
    int now = [self getCurrentTime];
    int lastTime = [[self getNSDefaultObject:@"kNewRemoteItemAddTime"] intValue];
    if(now<lastTime+86400+86400+86400) {
        NSString *updateTime = [self getGlobalSetting:@"kNewRemoteItemAddTime"];
        if(updateTime && [updateTime length]>10) {
            NSDate *dt = [StringUtils convertStringToDate:updateTime];
            if([dt timeIntervalSince1970]>now-86400*10) 
                return YES;
        }
    }
    return NO;
}


static BOOL _gInterruptMode = YES;
// 设置免打扰模式
+ (void) setInterruptMode:(BOOL)canInterrupt
{
    _gInterruptMode = canInterrupt;
}
// 获取免打扰模式, YES-可以弹窗，NO－不可以弹窗
+ (BOOL) getInterruptMode
{
    return _gInterruptMode;
}

// 显示公告窗口
+(void) showPromotionNotice
{
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
    [SNSPromotionViewController createAndShow];
#endif
}
// 关闭公告窗口
+(void) closePromotionNotice
{
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
    [SNSPromotionViewController closePromotionView];
#endif
}
// 添加一个新通知
+(void) addPromotionNotice:(NSDictionary *)noticeInfo
{
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
    [SNSPromotionViewController addNotice:noticeInfo];
#endif
}

// 获得新通知数量
+(int) getPromotionNoticeUnreadCount
{
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
    return [SNSPromotionViewController getNewNoticeCount];
#endif
    return 0;
}
// 获得通知数量
+(int) getPromotionNoticeCount
{
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
    return [SNSPromotionViewController getNoticeCount];
#endif
    return 0;
}

#pragma mark -

#pragma mark Promotion

// 是否有促销
+ (BOOL) isPromotionReady
{
	int rate = [self getPromotionRate];
	return (rate>0 && rate<10);
}

// 促销折扣, 0-不促销，2／4／6／8：多送20／40／60／80％
+ (int) getPromotionRate
{
	NSDictionary *conf = [self config];
	NSNumber *stTime = [conf objectForKey:kPromotionStartTime];
	NSNumber *edTime = [conf objectForKey:kPromotionEndTime];
	int rate = [[conf objectForKey:kPromotionRate] intValue];
	if(rate==2 || rate==4 || rate==6 || rate==8)
	{
		int now = [self getCurrentTime];
		if(now>[stTime intValue] && now<[edTime intValue]) {
			SNSLog(@"promotion active: now:%i start:%@ end:%@", now, stTime, edTime);
			return rate;
		}
	}
	return 0;
}

// 促销截至时间
+ (int) getPromotionEndTime
{
	NSDictionary *conf = [self config];
	NSNumber *edTime = [conf objectForKey:kPromotionEndTime];
	return [edTime intValue];
}
// 促销开始时间
+ (int) getPromotionStartTime
{
	NSDictionary *conf = [self config];
	NSNumber *time = [conf objectForKey:kPromotionStartTime];
	return [time intValue];
}
// 显示促销倒计时提示
+ (void) showPromoteNotice
{
	NSString *lastLoginIdentifier = @"smLastLoginTime";
	int lastLoginDate = [[self getGlobalSetting:lastLoginIdentifier] intValue];
	int iDat =  (int)([self getCurrentTime]/86400);
	if (!lastLoginDate) {
		lastLoginDate = 1;
	}
	BOOL wasShow = NO;
	//NSLog(@"当前时间：%d 上次登陆时间：%d", iDat, lastLoginDate);
	
	if (iDat > lastLoginDate) {
		wasShow = YES;
	}

	
	//NSLog(@"今天是否已经显示过%d -- %d", canShowPromotion, wasShow);

	/*
    // 限时促销：30秒后显示
	if([_currentGameDataDelegate isTutorialFinished] && wasShow && [self isPromotionReady]) {
		[self setGlobalSetting:[NSString stringWithFormat:@"%d", iDat] forKey:lastLoginIdentifier];
		// 2,4,6,8
		//NSLog(@"开始探框显示优惠购买");
		int rate = [self getPromotionRate];
		int timeEnd = [self getPromotionEndTime];
		NSArray *arr = [[InAppStore store] getCountDownPromotions];
		if([arr count]==0) return;
		NSLog(@"rate:%i timeEnd:%i array:%@", rate, timeEnd, arr);
		//NSLog(@"rate:%d -- arr:%@ -- timeEnd:%d", rate, [arr description], timeEnd);

		smWinQueueCutRate *cutRate = [[[smWinQueueCutRate alloc] initWithNibName:@"smWinQueueCutRate" bundle:nil] autorelease];
		cutRate.setting = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", (10-rate)*10], @"persent", [NSString stringWithFormat:@"%d",timeEnd], @"timeStemp", arr, @"buttonArr", nil];
		[[smWindowQueue createQueue] pushToQueue:cutRate timeOut:30.0f];
	}
     */
	
}


// 奖励用户资源, kGameResourceTypeCoin, kGameResourceTypeLeaf, kGameResourceTypeExp, kGameResourceTypeIAPCoin, kGameResourceTypeIAPLeaf
+(void) addGameResource:(int)amount ofType:(int)type
{
	BOOL isIAP = NO;
    if(_currentGameDataDelegate == nil) {
        NSString *key = nil;
        if(type == kGameResourceTypeCoin) key = @"coin";
        else if(type == kGameResourceTypeLeaf) key = @"leaf";
        else if(type == kGameResourceTypeExp) key = @"exp";
        else if(type == kGameResourceTypeIAPCoin) { 
			key = @"iapCoin"; isIAP = YES;
		}
        else if(type == kGameResourceTypeIAPLeaf) {
			key = @"iapLeaf"; isIAP = YES;
		}
        if(!key) return;
        
        NSMutableDictionary *info = [self getPlayerDefaultSetting:kPendingGameResource];
        if(info) {
            if([info isKindOfClass:[NSMutableDictionary class]]) {
                // do nothing
            }
            else if([info isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *info2 = [[NSMutableDictionary alloc] initWithDictionary:info];
                info = info2;
                [info2 autorelease];
            }
            else {
                info = nil;
            }
        }
        if(!info) {
            info = [[NSMutableDictionary alloc] initWithCapacity:3];
            [info autorelease];
        }
        [info retain];
		if(isIAP) {
			NSString *str = [info objectForKey:key];
			if(str)
				str = [str stringByAppendingFormat:@",%i", amount];
			else 
				str = [NSString stringWithFormat:@"%i", amount];
			[info setObject:str forKey:key];
		}
		else {
			int val = [[info objectForKey:key] intValue];
			val += amount;
			[info setObject:[NSNumber numberWithInt:val] forKey:key];
		}
		[self setPlayerDefaultSetting:info forKey:kPendingGameResource];
        [info release];
        return;
    }
    int resType = type;
	if(type == kGameResourceTypeCoin) resType = 1;
	else if(type == kGameResourceTypeLeaf) resType = 2;
	else if(type == kGameResourceTypeExp) resType = 3;
	else if(type == kGameResourceTypeIAPCoin) {
		resType = 1; isIAP = YES;
	}
	else if(type == kGameResourceTypeIAPLeaf) {
		resType = 2; isIAP = YES;
	}
	else if(type == kGameResourceTypeIAPPromo) {
		resType = 3; isIAP = YES;
	}
    else if(type==kGameResourceTypeDisableAds) {
        [_currentGameDataDelegate setExtraInfo:[NSNumber numberWithInt:amount] forKey:@"noAds"];
        return;
    }
    
	if(isIAP) {
		[_currentGameDataDelegate onBuyIAP:amount ofType:resType];
	}
	else {
		[_currentGameDataDelegate addGameResource:amount ofType:resType];
	}
}

// IAP购买成功，给予奖励
+(void) addIapItem:(NSString *)itemName withCount:(int)count
{
    if(!itemName) return;
    if(_currentGameDataDelegate == nil || ![_currentGameDataDelegate respondsToSelector:@selector(onBuyIAPItem: withCount:)]) {
        NSString *key = [NSString stringWithFormat:@"%@|%i",itemName,count];
        
        NSMutableDictionary *info = [self getPlayerDefaultSetting:kPendingIAPItem];
        if(info) {
            if([info isKindOfClass:[NSMutableDictionary class]]) {
                // do nothing
            }
            else if([info isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *info2 = [[NSMutableDictionary alloc] initWithDictionary:info];
                info = info2;
                [info2 autorelease];
            }
            else {
                info = nil;
            }
        }
        if(!info) {
            info = [[NSMutableDictionary alloc] initWithCapacity:3];
            [info autorelease];
        }
        [info retain];
        int val = [[info objectForKey:key] intValue];
        val += count;
        [info setObject:[NSNumber numberWithInt:val] forKey:key];
		[self setPlayerDefaultSetting:info forKey:kPendingIAPItem];
        [info release];
        return;
    }
    [_currentGameDataDelegate onBuyIAPItem:itemName withCount:count];
}

// 增加某个道具
+(void) addItem:(NSString *)itemID withCount:(int)count
{
    if(!_currentGameDataDelegate) return;
    if([_currentGameDataDelegate respondsToSelector:@selector(onAddItem:withCount:)])
        [_currentGameDataDelegate onAddItem:itemID withCount:count];
}

// 获取tapjoy分数的key
+(NSString *)getTapjoyPointKey
{
	return [NSString stringWithFormat:@"%@-%@",kTapjoyPoint, [self getDeviceID]];
}

// 获取Tapjoy累计分数
+(int)getTapjoyPoint
{
	NSString *key = [self getTapjoyPointKey];
	NSNumber *point = [self getGlobalSetting:key];
	if(!point && _currentGameDataDelegate) point = [_currentGameDataDelegate getExtraInfo:key];
	if(!point) return 0;
	return [point intValue];
}
// 存储Tapjoy累计分数
+(void)setTapjoyPoint:(int)point
{
	NSString *key = [self getTapjoyPointKey];
	NSNumber *pt = [NSNumber numberWithInt:point];
	[self setGlobalSetting:pt forKey:key];
    if(_currentGameDataDelegate)
        [_currentGameDataDelegate setExtraInfo:pt forKey:key];
	// [self logTapjoyIncome:point];
}

// 获取特价动物信息，如果没有就返回 nil
+(NSDictionary *)getSpecialOfferInfo
{
	int animalID = [[self getGlobalSetting:kSpecialAnimalID] intValue];
	if(animalID == 0) return nil;
	
	NSMutableDictionary *info = [[NSMutableDictionary alloc] initWithCapacity:3];
	[info autorelease];
	[info setObject:[self getGlobalSetting:kSpecialAnimalID] forKey:kSpecialAnimalID];
	[info setObject:[self getGlobalSetting:kSpecialStartTime] forKey:kSpecialAnimalID];
	[info setObject:[self getGlobalSetting:kSpecialEndTime] forKey:kSpecialAnimalID];
	return info;
}

// 获取特价动物结束时间
+(int) getSpecialOfferEndTime
{
	int animalID = [[self getGlobalSetting:kSpecialAnimalID] intValue];
	if(animalID == 0) return 0;
	NSString *str = [self getGlobalSetting:kSpecialEndTime];
	if(!str || ![str isKindOfClass:[NSString class]]) return 0;
	NSDate *dt = [StringUtils convertStringToDate:str];
	int time = [dt timeIntervalSince1970];
	return time;
}

#pragma mark -


#pragma mark GameStats

+ (NSString *) getGameStatsFile
{
	return [[self getDocumentRootPath] stringByAppendingFormat:@"/stat-%@.log",[self getCurrentUID]];
}


+(void)resetGameStats
{
    [[SnsStatsHelper helper] resetStats];
    [[SnsStatsHelper helper] logStartTime:@"main"];
    /*
	if(_gameStatsTotal) {
        [_gameStatsTotal release];
        _gameStatsTotal = nil;
    }
    if(_gameStatsToday) {
        [_gameStatsToday release];
        _gameStatsToday = nil;
    }
    
    [self initGameStats];
    
    [self logPlayTimeStart];
    [self saveGameStat];
     */
}

// 加载游戏统计数据
+ (void) initGameStats
{
    [[SnsStatsHelper helper] initSession];
    /*
    if(_gameStatsTotal) return;
	_gameStatsTotal = [[SNSGameStat alloc] init];
	_gameStatsToday = [[SNSGameStat alloc] init];
    
    NSString *path = [self getGameStatsFile];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        NSDictionary *info = [text JSONValue];
        if(info && [info isKindOfClass:[NSDictionary class]]) {
            text = [info objectForKey:@"stats"];
            if(text && [text isKindOfClass:[NSString class]])
                [_gameStatsTotal importFromString:text];
            int today = [[info objectForKey:@"today"] intValue];
            text = [info objectForKey:@"todayStats"];
            if(today==[self getTodayDate] && text && [text isKindOfClass:[NSString class]])
                [_gameStatsToday importFromString:text];
        }
    }
     */
}


// 从下载进度中恢复统计信息
+(void)checkGameStatInLoadData:(NSDictionary *)userInfo
{
    NSString *text = [userInfo objectForKey:@"stat2"];
    if(text && [text isKindOfClass:[NSString class]])
    {
        NSDictionary *dict = [text JSONValue];
        if(dict && [dict isKindOfClass:[NSDictionary class]]) {
            [[SnsStatsHelper helper] importFromDictionary:dict];
            [[SnsStatsHelper helper] logStartTime:@"main"];
        }
    }
    /*
    [self initGameStats];
    NSString *text = [userInfo objectForKey:@"stats"];
    if(text && [text isKindOfClass:[NSString class]])
    {
        SNSGameStat *stat = [[SNSGameStat alloc] init];
        [stat importFromString:text];
        if(stat.userExp > _gameStatsTotal.userExp) {
            [_gameStatsTotal release];
            _gameStatsTotal = stat;
            [self logPlayTimeStart];
            [self saveGameStat];
        }
        else {
            [stat release];
        }
    }
     */
}


// 存储统计信息
+(void)saveGameStat
{
    [[SnsStatsHelper helper] saveStats];
    /*
    if([self getGameDataDelegate]) {
        _gameStatsTotal.userExp = [[self getGameDataDelegate] getGameResourceOfType:kGameResourceTypeExp];
        _gameStatsToday.userExp = _gameStatsTotal.userExp;
    }
    NSString *text1 = [_gameStatsTotal exportToString];
    NSString *text2 = [_gameStatsToday exportToString];
    NSDictionary *stats = [NSDictionary dictionaryWithObjectsAndKeys:text1, @"stats", text2, @"todayStats", [NSNumber numberWithInt:[self getTodayDate]], @"today", nil];
	NSString *text = [stats JSONRepresentation];
	NSString *path = [self getGameStatsFile];
	if(text) {
        BOOL res = [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        SNSLog(@"write to %@: %i", path, res);
    }
    else {
        SNSLog(@"fail to get json text of stat:%@", stats);
    }
    // SNSCrashLog(@"end");
     */
}


// 记录支付信息，单位是美分
+(void)logPaymentInfo:(int)cost withItem:(NSString *)iapID
{
    [[SnsStatsHelper helper] logPayment:cost withItem:iapID andTransactionID:@"none"];
    /*
	// save info to game data
    [_gameStatsTotal logPayment:cost withItem:iapID];
    [_gameStatsToday logPayment:cost withItem:iapID];
    [self saveGameStat];
     */
}

// 累计资源变化，最终只形成一条记录
+(void) addUpResource:(int)type method:(int)method count:(int) count
{
    /*
    [_gameStatsToday addUpResource:type method:method count:count];
    [_gameStatsTotal addUpResource:type method:method count:count];
     */
}

// 记录资源变化
+(void)logResourceChange:(int)type method:(int)method itemID:(NSString *)itemID count:(int) count
{
    /*
    [_gameStatsToday logResourceChange:type method:method itemID:itemID count:count];
    [_gameStatsTotal logResourceChange:type method:method itemID:itemID count:count];
     */
}


// 记录游戏开始时间
+(void)logPlayTimeStart
{
    [[SnsStatsHelper helper] logStartTime:@"main"];
    /*
    [_gameStatsTotal startPlaySession];
    
    if(_gameStatsToday.updateDate != [self getTodayDate]) {
        [_gameStatsToday release]; 
        _gameStatsToday = [[SNSGameStat alloc] init];
    }
    [_gameStatsToday startPlaySession];
     */
}

// 记录游戏结束时间
+(void)logPlayTimeEnd
{
    [[SnsStatsHelper helper] logStopTime:@"main"];
    /*
    [_gameStatsToday endPlaySession];
    [_gameStatsTotal endPlaySession];
     */
}

// 记录道具购买记录
+(void)logItemBuy:(int)type withID:(NSString *)ID
{
    [self logItemBuy:type withID:ID cost:0 resType:kCoinTypeNone];
}
// 记录道具购买记录
+(void)logItemBuy:(int)type withID:(NSString *)ID cost:(int)cost resType:(int)resType
{
    SNSLog(@"type:%i ID:%@", type, ID);
    /*
    [_gameStatsToday logItemBuy:type withID:ID];
    [_gameStatsTotal logItemBuy:type withID:ID];
     */
    [[SnsStatsHelper helper] logBuyItem:ID count:1 cost:cost resType:resType itemType:type];
    
}

// 记录升级记录
+(void)logLevelUp:(int)level
{
    //[_gameStatsToday logLevelUp:level];
    // [_gameStatsTotal logLevelUp:level];
    // [self saveGameStat];
    NSString *str = [NSString stringWithFormat:@"lv_%i",level];
    [[SnsStatsHelper helper] logAchievement:str];
}

// 记录玩小游戏的时间
+(void)logPlayMiniGame:(int)gameID forTime:(int)seconds
{
    //[_gameStatsToday logPlayMiniGame:gameID forTime:seconds];
    //[_gameStatsTotal logPlayMiniGame:gameID forTime:seconds];
}




#pragma mark -

#pragma mark playerSetting

//static int _gPlayerSettingNextSaveTime = 0;
//static int _gPlayerSettingIsSaving = 0;

+ (void) savePlayerSettingToFile
{
    /*
	int now = [self getCurrentTime];
	if(now<_gPlayerSettingNextSaveTime) return;
	if(_gPlayerSettingIsSaving == _gPlayerSettingNextSaveTime) return;
	_gPlayerSettingIsSaving = _gPlayerSettingNextSaveTime;
	 */
	NSString  *uid = [SystemUtils getCurrentUID];
	//NSLog(@"%s: uid=%i", __func__, uid);
	NSString *fileName = [NSString stringWithFormat:@"setting-%@.dat", uid];
 	NSString *cachePath = [self getCacheRootPath];
	NSString *cacheFile = [cachePath stringByAppendingPathComponent:fileName];
    NSString *cacheFile2 = [cacheFile stringByAppendingString:@".bak"];
	NSString *str = [[self playerSetting] JSONRepresentation]; 
    str = [self addHashToSaveData:str];
	// [str writeToFile:cacheFile atomically:YES
	NSError *err = nil;
	BOOL res = [str writeToFile:cacheFile2 atomically:YES encoding:NSUTF8StringEncoding error:&err];
	if(res) {
        NSFileManager *mgr = [NSFileManager defaultManager];
        [mgr removeItemAtPath:cacheFile error:nil];
        [mgr moveItemAtPath:cacheFile2 toPath:cacheFile error:nil];
	}
    else {
		SNSLog(@"%s:fail to write %@, error:%@", __FUNCTION__, cacheFile, err);
    }
}

+(void)savePlayerSetting
{
    [self savePlayerSettingToFile]; return;
	// _gPlayerSettingNextSaveTime = [self getCurrentTime]+1;
	// [self performSelector:@selector(savePlayerSettingToFile) withObject:nil afterDelay:1];
	/*
	NSString *cacheFile2 = [cacheFile stringByAppendingString:@".bak"];
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSError *err = nil;
	if([mgr fileExistsAtPath:cacheFile]) {
		if([mgr fileExistsAtPath:cacheFile2]) [mgr removeItemAtPath:cacheFile2 error:&err];
		[mgr moveItemAtPath:cacheFile toPath:cacheFile2 error:&err];
		// [mgr removeItemAtPath:cacheFile error:&err];
	}
	NSString *str = [[self config] JSONRepresentation]; 
	// [str writeToFile:cacheFile atomically:YES
	if([str writeToFile:cacheFile atomically:YES encoding:NSUTF8StringEncoding error:&err] ) 
	{
		NSLog(@"write to %@ ok", cacheFile);
		// [self updateFileDigest:cacheFile];
	}
	else
	{
		NSLog(@"write to %@ failed error:%@", cacheFile, err);
		if([mgr fileExistsAtPath:cacheFile2]) [mgr moveItemAtPath:cacheFile2 toPath:cacheFile error:&err];
	}
	 */
}

// 获取用户设置
+(id) getPlayerDefaultSetting:(id)key
{
    if(![_playerSetting isKindOfClass:[NSMutableDictionary class]]) 
        return nil;
	return [_playerSetting objectForKey:key];
}

// 存储用户设置
+(void) setPlayerDefaultSetting:(id)val forKey:(id)key
{
    if(![_playerSetting isKindOfClass:[NSMutableDictionary class]]) 
        return;
	[_playerSetting setObject:val forKey:key];
	[self savePlayerSetting];
}

// 存储用户设置
+(void) setPlayerDefaultSetting:(id)val forKey:(id)key saveToFile:(BOOL)save
{
	[[self playerSetting] setObject:val forKey:key];
	if(save)[self savePlayerSetting];
}

// 删除用户设置
+(void) removePlayerSetting:(id)key saveToFile:(BOOL)save
{
	[[self playerSetting] removeObjectForKey:key];
	if(save)[self savePlayerSetting];
}

// 增加好友, uid, country, fbid, name
+ (void) addFriend:(NSDictionary *)info
{
    @synchronized(self) {
        NSString *uid = [info objectForKey:@"uid"];
        if(uid==nil || [uid intValue]==0) return;
        NSArray *arr = [self getFriends];
        if(arr!=nil && (![arr isKindOfClass:[NSArray class]] || [arr count]==0)) arr = nil;
        if(arr!=nil) {
            // [friends addObjectsFromArray:arr];
            if([arr count]>=100) return;
            // check if duplicate
            for(NSDictionary *rec in arr) {
                NSString *uid2 = [rec objectForKey:@"uid"];
                if(uid2!=nil && [uid isEqualToString:uid2]) return;
            }
        }
        NSMutableArray *friends = [NSMutableArray array];
        if(arr!=nil) [friends addObjectsFromArray:arr];
        [friends addObject:info];
        [self setNSDefaultObject:friends forKey:@"kFriendList"];
    }
}
// 获得好友列表
+ (NSArray *) getFriends
{
    NSArray *arr = [self getNSDefaultObject:@"kFriendList"];
    if(arr==nil) {
        arr = [[self getGameDataDelegate] getExtraInfo:@"kFriendList"];
        if(arr!=nil) [self setNSDefaultObject:arr forKey:@"kFriendList"];
    }
    return arr;
}

// 获取远程配置参数，如果没有，就取本地systemconfig.plist里的参数
+(id) getRemoteConfigValue:(NSString *)key
{
    id val = [self getGlobalSetting:key];
    if(val==nil) val = [self getSystemInfo:key];
    return val;
}

#pragma mark -

#pragma mark debugInfo

+(NSString *)getDebugInfo
{
    NSString  *userID = [self getCurrentUID];
    NSDictionary *gameData = nil;
    if(userID==0) 
        gameData = [_currentGameDataDelegate exportToDictionary];
    if(!gameData) 
        gameData = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"userID", nil];
	NSString *iosVer = [UIDevice currentDevice].systemVersion;
	NSNumber *deviceTime = [NSNumber numberWithInt:[self getCurrentDeviceTime]];
	NSNumber *serverTime = [NSNumber numberWithInt:[self getCurrentTime]];
	
	NSDictionary *debugInfo = [NSDictionary dictionaryWithObjectsAndKeys:gameData, @"gameData", [self getDeviceID], @"deviceID", iosVer, @"iosVer",
							  _globalConfig, @"globalConfig", deviceTime, @"deviceTime", serverTime, @"serverTime", nil];
	NSString *str = [debugInfo JSONRepresentation];
	str = [Base64 encode:[str dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *crashLog = [self getCrashLogContent];
    return [NSString stringWithFormat:@"%@\n\ndata dump:\n%@", crashLog, str];
	// return @"TO be done";
}

+ (void)setUpMailAccountAlert {
	// [self incAlertViewCount];
    SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:[SystemUtils getLocalizedString:@"Can't Send Email"]
                        message:[SystemUtils getLocalizedString:@"Please check your email setting."]
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertInvalidEmailSetting;
    // [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
	[av show];
    [av release];
    
}

// 给客服发邮件
+ (void) writeEmailToSupport
{
	SNSLog(@"%s",__FUNCTION__);
	//安全检查
	if(![MFMailComposeViewController canSendMail]) {
		[self setUpMailAccountAlert];
		return;
	}
	
	// NSString *udid = [self getMACAddress];
	NSString *mailTitle = [NSString stringWithFormat:[self getLocalizedString:[self getSystemInfo:kSupportEmailTitle]], [self getLocalizedString:@"GameName"]];
    
	NSString *iosVer = [UIDevice currentDevice].systemVersion;
	NSString *title = [NSString stringWithFormat:@"%@ - UID:%@ country:%@ iOS:%@ ver:%@ hmac:%@ model:%@",mailTitle, [self getCurrentUID], [self getOriginalCountryCode], iosVer, [self getClientVersion], [self getMACAddress], [self getDeviceModel]];
#ifdef SNS_ENABLE_MINICLIP
    title = [NSString stringWithFormat:@"%@ - UID:%@ country:%@ iOS:%@ ver:%@ model:%@",mailTitle, [self getCurrentUID], [self getOriginalCountryCode], iosVer, [self getClientVersion],  [self getDeviceModel]];
#endif
	NSString *body = nil;
    NSString *emailtext = [SystemUtils getNSDefaultObject:@"kSupportEmailAttachment"];
    if(emailtext && [emailtext length]>0) {
        body = [NSString stringWithFormat:@"%@\n%@",[self getLocalizedString:[self getSystemInfo:kSupportEmailGreeting]], emailtext];
        // [emailtext retain];
        [SystemUtils setNSDefaultObject:@"" forKey:@"kSupportEmailAttachment"];
    }
    else {
        emailtext = nil;
        body = [NSString stringWithFormat:@"%@\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n%@\n%@", [self getLocalizedString:[self getSystemInfo:kSupportEmailGreeting]], [self getLocalizedString:[self getSystemInfo:kSupportEmailSuffix]], [self getDebugInfo]];
    }
	SendEmailViewController *messageView = [[SendEmailViewController alloc] init];
    messageView.useRootView = YES;
	//messageView.wantsFullScreenLayout = YES;
	//[[[CCDirector sharedDirector] openGLView] addSubview:messageView.view];
	
	//iPetHotelAppDelegate *applicationDelegate = (iPetHotelAppDelegate *)[[UIApplication sharedApplication]delegate];
//	[applicationDelegate.window addSubview:messageView.view];
	

	[messageView displayComposerSheet:[self getSystemInfo:kSupportEmail] 
							withTitle:title
							  andBody:body
						andAttachData:nil 
				   withAttachFileName:nil];
	
    [messageView release];
    // if(emailtext) [emailtext autorelease];
	// if(_emailController) [_emailController release];
	// _emailController = messageView;
}

#pragma mark -


#pragma mark CrashLog

#define kCrashStatus @"kCrashStatus"
#define kCrashLogFile  @"crash.log"

// #define kTGCrashDetected @"kTGCrashDetected"
#define kTGCrashInfo @"kTGCrashInfo"


static int _crashReportStatus  = 0;
static NSFileHandle *_crashLogFile = nil;

// 处理全局Exception
+ (void) setUncaughtExceptionMessage:(NSString *)info
{
    [self setNSDefaultObject:info forKey:kTGCrashInfo];
    
    if(_crashLogFile) {
        [_crashLogFile closeFile];
        _crashLogFile = nil;
    }
    SNSLog(@"exception info:%@", info);
    [self logPlayTimeEnd];
    [self saveGameStat];
}

// 处理全局CPP Exception
+ (void) uncaughtCppExceptionInfo:(NSString *)reason
{
    NSString *osVer = [self getiOSVersion];
    float ver = [osVer floatValue];
    NSArray *stackInfo = nil;
    if(ver<4.0f) stackInfo = [NSThread callStackReturnAddresses];
    else stackInfo = [NSThread callStackSymbols];
    //if(!stackInfo && ver>=4.0f) 
    //    stackInfo = [NSThread callStackSymbols];
    
    NSString *info = [NSString stringWithFormat:@"Exception name:CppException reason:%@\nstack trace:\n%@\ndeviceInfo:\n%@", reason, stackInfo, [self getDeviceInfo]];
    
    [self setUncaughtExceptionMessage:info];
    
}

// 处理全局Exception
+ (void) uncaughtExceptionHandler:(NSException *)exception
{
    NSString *osVer = [self getiOSVersion];
    float ver = [osVer floatValue];
    NSArray *stackInfo = nil;
    if(ver<4.0f) stackInfo = [exception callStackReturnAddresses];
    else stackInfo = [exception callStackSymbols];
    //if(!stackInfo && ver>=4.0f) 
    //    stackInfo = [NSThread callStackSymbols];
    
    NSString *info = [NSString stringWithFormat:@"Exception name:%@ reason:%@\nstack trace:\n%@\ndeviceInfo:\n%@", [exception name], [exception reason], stackInfo, [self getDeviceInfo]];
    [self setUncaughtExceptionMessage:info];
}

// 是否启用了崩溃日志
+ (BOOL) isCrashDetected
{
	if(_crashReportStatus == 1) return YES;
	return NO;
}

// 返回崩溃日志文件
+ (NSString *) getCrashLogFile
{
	NSString *path = [self getItemRootPath];
	return [path stringByAppendingPathComponent:kCrashLogFile];
}

// 检查崩溃状态
+ (void) startCrashLog
{
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	int crash = [def integerForKey:kCrashStatus];
	if(crash == 1) {
		// 上次进程崩溃，开始记录运行日志
		// 发送崩溃日志
		[self sendCrashLog];
		_crashReportStatus = 1;
		[def setInteger:2 forKey:kCrashStatus];
		[def synchronize];
		return;
	}
	if(crash == 2) {
		// 上次进程再次崩溃
		// 发送崩溃日志
		[self sendCrashLog];
		// 清理崩溃日志
		[self clearCrashLog];
		// 继续记录崩溃日志
		_crashReportStatus = 1;
		[def setInteger:2 forKey:kCrashStatus];
		[def synchronize];
		return;
	}
	[def setInteger:1 forKey:kCrashStatus];
	[def synchronize];
}

// 结束崩溃日志
+ (void) endCrashLog
{
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	[def setInteger:0 forKey:kCrashStatus];
    [def setObject:@"" forKey:kTGCrashInfo];
	[def synchronize];
	if(_crashReportStatus == 0) return;
	if(_crashLogFile) {
		[_crashLogFile closeFile];
		[_crashLogFile release];
		_crashLogFile = nil;
	}
	_crashReportStatus = 0;
	// 清除崩溃日志
	[self clearCrashLog];
}

// 发送崩溃日志
+ (void) sendCrashLog
{
    // first check if already fixed
    NSString *errInfo = [self getCrashLogContent];
    NSDictionary *fixedBugs = [NSDictionary dictionaryWithContentsOfFile:@"FixableCrash.plist"];
    if(fixedBugs && [fixedBugs isKindOfClass:[NSDictionary class]] && [fixedBugs objectForKey:@"bugs"]) {
        NSArray *arr = [fixedBugs objectForKey:@"bugs"];
        for(NSDictionary *bugInfo in arr) {
            NSString *exception = [bugInfo objectForKey:@"Exception"];
            NSString *keywords  = [bugInfo objectForKey:@"Keywords"];
            NSString *hint = [bugInfo objectForKey:@"Hint"];
            if(!exception || !keywords || !hint) continue;
            NSString *key1 = [NSString stringWithFormat:@"Exception name:%@", exception];
            NSRange r = [errInfo rangeOfString:key1];
            if(r.location == NSNotFound) continue;
            BOOL allKeyOK = YES;
            NSArray *arr2 = [keywords componentsSeparatedByString:@"|||"];
            for(key1 in arr2) {
                r = [errInfo rangeOfString:key1];
                if(r.location == NSNotFound) {
                    allKeyOK = NO;
                    break;
                }
            }
            if(!allKeyOK) continue;
            // find fixed bug
            /*
             "fixed" => 1,
             "hint" => $fixBugInfo["updateHint"],
             "fixVer" => $fixBugInfo["fixVer"]
             */

            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"1", @"fixed", hint, @"hint", 
                                  [self getClientVersion], @"fixVer", nil];
            
            [self showCrashBugFixed:info];
            return;
        }
    }
    
	// 发送错误日志
	SyncQueue* syncQueue = [SyncQueue syncQueue];
	CrashReportOperation* saveOp = [[CrashReportOperation alloc] initWithManager:syncQueue andDelegate:nil];
	saveOp.debugInfo = errInfo;
	[syncQueue.operations addOperation:saveOp];
	[saveOp release];
}

// 清除崩溃日志
+ (void) clearCrashLog
{
	// 删除错误日志文件
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSString *path = [self getCrashLogFile];
	if([mgr fileExistsAtPath:path]) 
		[mgr removeItemAtPath:path error:nil];
}

// 创建日志文件
+ (void) createCrashLogFile
{
	if(_crashLogFile) return;
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSString *path = [self getCrashLogFile];
	if(![mgr fileExistsAtPath:path]) {
		[mgr createFileAtPath:path contents:nil attributes:nil];
	}
	_crashLogFile = [NSFileHandle fileHandleForWritingAtPath:path];
	[_crashLogFile retain];
}

// 记录崩溃日志
+ (void) addCrashLog:(NSString *)info
{
	if(_crashReportStatus == 0) return;
	[self createCrashLogFile];
	NSString *date = [StringUtils convertDateToString:[NSDate date] withFormat:@"yy-mm-dd HH:MM:SS"];
	NSString *str = [[NSString alloc] initWithFormat:@"%@ - %@\n",date, info];
	[_crashLogFile writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
	[str release];
}

// 返回崩溃日志内容
+ (NSString *) getCrashLogContent
{
    NSString *info = [self getNSDefaultObject:kTGCrashInfo];
    
#ifdef DEBUG
    // if(!info || [info length]==0) info = @"Exception name:testException reason:this is just for test\nstack trace:\nxxxxxxxxxxxx\ndeviceInfo:\n";
#endif
    if(info && [info length]>0) return info;
    
    if(!info) info = @"";
    
	NSString *file = [self getCrashLogFile];
	NSString *logInfo = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    if(logInfo) info = [info stringByAppendingFormat:@"\nCrash Log:\n%@", logInfo];
    return info;
}

// 获取Thread的Stack Trace
+ (NSArray *)getStackTraceInfo
{
    NSString *osVer = [self getiOSVersion];
    int ver = [osVer floatValue];
    NSArray *stackInfo = nil;
    if(ver<4.0) stackInfo = [NSThread callStackReturnAddresses];
    else stackInfo = [NSThread callStackSymbols];
    return stackInfo;
}


#pragma mark -

#pragma mark installReport

// AdMob
// This method requires adding #import <CommonCrypto/CommonDigest.h> to your source file.
+ (NSString *)hashedISU {
	NSString *result = nil;
    NSString *isu = @"";
	//NSString *isu = [UIDevice currentDevice].uniqueIdentifier;
	
	if(isu) {
		unsigned char digest[16];
		NSData *data = [isu dataUsingEncoding:NSASCIIStringEncoding];
		CC_MD5([data bytes], [data length], digest);
		
		result = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
				  digest[0], digest[1],
				  digest[2], digest[3],
				  digest[4], digest[5],
				  digest[6], digest[7],
				  digest[8], digest[9],
				  digest[10], digest[11],
				  digest[12], digest[13],
				  digest[14], digest[15]];
		result = [result uppercaseString];
	}
	return result;
}

+ (void)reportAppOpenToAdMob {
    /*
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // we're in a new thread here, so we need our own autorelease pool
	NSString *appID = [self getSystemInfo:kiTunesAppID];
	// Have we already reported an app open?
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *appOpenPath = [documentsDirectory stringByAppendingPathComponent:@"admob_app_open"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if(![fileManager fileExistsAtPath:appOpenPath]) {
		// Not yet reported -- report now
		NSString *appOpenEndpoint = [NSString stringWithFormat:@"http://a.admob.com/f0?isu=%@&md5=1&app_id=%@",
									 [self hashedISU], appID];
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:appOpenEndpoint]];
		NSURLResponse *response;
		NSError *error;
		NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		if((!error) && ([(NSHTTPURLResponse *)response statusCode] == 200) && ([responseData length] > 0)) {
			[fileManager createFileAtPath:appOpenPath contents:nil attributes:nil]; // successful report, mark it as such
#ifdef DEBUG
            NSString *respStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NSLog(@"%s: resp: %@",__func__, respStr);
            [respStr release];
#endif
		}
	}
	[pool release];
     */
}
/*
+ (void) didFinishReportIAP:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	if (!error) {
		// NSString *response = [request responseString];
		NSLog(@"%s: response string:%@", __FUNCTION__, [request responseString]);
	}
	else {
		NSLog(@"%s: error info:%@", __FUNCTION__, error);
	}
}
 */

// 实时付费统计
+ (void) reportIAPToServer:(NSDictionary *)info
{
    // 上报统计已经与验证流程合并，此处不必做任何事
    /*
	SyncQueue* syncQueue = [SyncQueue syncQueue];
	PaymentSendOperation* saveOp = [[PaymentSendOperation alloc] initWithManager:syncQueue andDelegate:nil];
	saveOp.paymentInfo = info;
	[syncQueue.operations addOperation:saveOp];
	[saveOp release];
    return;
	// NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // we're in a new thread here, so we need our own autorelease pool
	NSString *iapID = [info objectForKey:@"ID"];
	NSString *userID = [self getCurrentUID];
	int price  = [[info objectForKey:@"price"] intValue];
	NSString *tid = [info objectForKey:@"tid"];
    NSString *sandbox = @"0";
#ifdef DEBUG
    sandbox = @"1";
#endif
    
	NSString *server = [self getServerName];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/paySend.php", server];
	// NSString *appOpenEndpoint = [NSString stringWithFormat:@"http://%@/api/paySend.php?userID=%@&iapID=%@&price=%i&tid=%@&country=%@",
	//							 server, userID, iapID, price, tid, [self getCountryCode]];
	// NSLog(@"%s: request %@", __FUNCTION__, appOpenEndpoint);
	NSURL *url = [NSURL URLWithString:urlStr];
    
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod: @"POST"];
    [request setDelegate:[SnsServerHelper helper]];
	[request setDidFinishSelector:@selector(didFinishReportIAP:)];
    [request addPostValue:userID forKey:@"userID"];
    [request addPostValue:sandbox forKey:@"debug"];
    [request addPostValue:iapID  forKey:@"iapID"];
    [request addPostValue:[NSString stringWithFormat:@"%i",price] forKey:@"price"];
    [request addPostValue:tid forKey:@"tid"];
    [request addPostValue:[self getCountryCode] forKey:@"country"];
    [request addPostValue:[info objectForKey:@"receiptData"] forKey:@"receiptData"];
    [request addPostValue:[info objectForKey:@"verifyPostData"] forKey:@"verifyPostData"];
	[request setTimeOutSeconds:3.0f];
	[request buildPostBody];
	NSLog(@"%s url: %@ post len:%i data: %s",__func__, urlStr, [request postBody].length, [request postBody].bytes);
    
	ASINetworkQueue *_networkQueue = [ASINetworkQueue queue];
	[_networkQueue addOperation: request];
	[_networkQueue go];
	// [pool release];
     */
}

// 某些旧设备上没有一些常用字体，用此函数来集中判断和替换
// 3.1.2平台上没有 Arial Bold
+ (NSString *) getSupportFont:(NSString *)font
{
	NSString *osVer = [[UIDevice currentDevice] systemVersion];
	if([osVer compare:@"3.1.2"]<=0)
	{
		if([font isEqualToString:@"Arial Bold"]) return @"Arial";
	}
	return font;
}

// replace [ADVID] and [APPID] below
+ (void)reportAppOpenToMdotM 
{
    /*
	NSString *kMdotMAdvID = [SystemUtils getSystemInfo:kMdotMAdvIDKey];
	NSString *kMdotMAppID = [SystemUtils getSystemInfo:kMdotMAppIDKey];
	if(!kMdotMAppID || !kMdotMAdvID || [kMdotMAdvID length]<10 || [kMdotMAppID length]<10) return;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
	NSString *appOpenEndpoint = [NSString stringWithFormat:@"http://ads.mdotm.com/ads/trackback.php?advid=%@&deviceid=%@&appid=%@", kMdotMAdvID,  [[UIDevice currentDevice] uniqueIdentifier],  kMdotMAppID];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:appOpenEndpoint]];
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if(!responseData) {
		// request fail
	}
#ifdef DEBUG
    NSString *respStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSLog(@"%s: resp: %@",__func__, respStr);
    [respStr release];
#endif
	[pool release];
	*/
}

// playhaven安装统计
+ (void) reportAppOpenToPlayHaven
{
    /*
     How to report
     
     http://partner-api.playhaven.com/v3/advertiser/open 
     
     Required Parameters: 
     device – iPhone UDID 
     token – token which corresponds to the secret being used in the signature 
     nonce - a randomly generated string 
     platform - “ ios ” or “android” 
     signature – hexdigest of the following SHA1 hash of the following pattern: 
     { token }:{device}:{nonce}:{secret}
     
     http://partner-api.playhaven.com/v3/advertiser/open?device=<device>&token=<token>&signature=<computed sig>&nonce=123456789&platform= ios 
     */
    /*
	NSString *phToken  = [SystemUtils getSystemInfo:kPlayHavenToken];
	NSString *phSecret = [SystemUtils getSystemInfo:kPlayHavenSecret];
	if(!phToken || !phSecret || [phToken length]<10 || [phSecret length]<10) return;
    
    int timeNow = [SystemUtils getCurrentDeviceTime]%10000000+10000000;
    NSString *deviceID = [[UIDevice currentDevice] uniqueIdentifier];
    NSString *hash = [NSString stringWithFormat:@"%@:%@:%i:%@",phToken, deviceID, timeNow, phSecret ];
    NSString *sig = [StringUtils stringByHashingStringWithSHA1:hash];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
	NSString *appOpenEndpoint = [NSString stringWithFormat:@"http://partner-api.playhaven.com/v3/advertiser/open?device=%@&token=%@&signature=%@&nonce=%i&platform=ios", deviceID,  phToken, sig, timeNow];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:appOpenEndpoint]];
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if(!responseData) {
		// request fail
	}
#ifdef DEBUG
    NSString *respStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSLog(@"%s: request:%@ resp: %@",__func__, appOpenEndpoint, respStr);
    [respStr release];
#endif
	[pool release];
	 */
}

// 安装统计
+ (void) reportInstallToServer
{
	/*
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // we're in a new thread here, so we need our own autorelease pool
#ifndef DEBUG
	int installed = [[self getGlobalSetting:kInstallReport] intValue];
	if(installed == 1) return;
#endif
	NSString *appId  = [self getSystemInfo:kFlurryCallbackAppID];
	NSString *server = [self getStatServerName];
	NSString *appOpenEndpoint = [NSString stringWithFormat:@"http://%@/api/install.php?udid=%@&appID=%@",
								 server, [self getDeviceID], appId];
	NSLog(@"%s: request %@", __FUNCTION__, appOpenEndpoint);
	NSURL *url = [NSURL URLWithString:appOpenEndpoint];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request startSynchronous];
	NSError *error = [request error];
	if (!error) {
		// NSString *response = [request responseString];
		[self setGlobalSetting:[NSNumber numberWithInt:1] forKey:kInstallReport];
		NSLog(@"%s ok: response string:%@", __FUNCTION__, [request responseString]);
	}
	else {
		NSLog(@"%s fail: error info:%@", __FUNCTION__, error);
	}
	// report to click stats
	// appID=123&udid=xxxxxxxx&country=CN&lang=zh-Hans&time=123456&sig=xxxxxxx
	NSString *appID = [self getSystemInfo:kTopClickAppID];
	NSString *appSecret = [self getSystemInfo:kTopClickAppSecret];
	if(appID && appSecret) {
		NSString *udid = [self getDeviceID];
		NSString *country = [self getCountryCode];
		NSString *lang = [self getCurrentLanguage];
		int time = [self getCurrentTime];
		NSString *timeStr = [NSString stringWithFormat:@"%i", time];
		NSString *hash = [NSString stringWithFormat:@"%@-%@-%@", appID, appSecret, timeStr];
		NSString *sig = [StringUtils stringByHashingStringWithMD5:hash];
		NSString *link = [NSString stringWithFormat:@"http://%@/api/appInstall.php?appID=%@&udid=%@&country=%@&lang=%@&time=%@&sig=%@",
						  [self getTopClickServerName], appID, udid, country, lang, timeStr, sig];
		ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:link]];
		NSLog(@"%s: request %@", __FUNCTION__, link);
		[req setTimeOutSeconds:5.0f];
		[req startSynchronous];
		error = [req error];
		if (!error) {
			NSLog(@"%s ok: response string:%@", __FUNCTION__, [req responseString]);
		}
		else {
			NSLog(@"%s fail: error info:%@", __FUNCTION__, error);
		}
	}
	[pool release];
	 */
}

// 记录已充值的IAP ID
+ (void) addIapTransactionID:(NSString *)tranID
{
	if(!tranID) return;
	NSMutableDictionary *tranList = [self getPlayerDefaultSetting:kTransactionList];
	if([tranList isKindOfClass:[NSMutableDictionary class]]) {
        // nothing to do
    }
	else if([tranList isKindOfClass:[NSDictionary class]]) {
		NSMutableDictionary *newList = [[NSMutableDictionary alloc] initWithDictionary:tranList];
		tranList = newList;
        [newList autorelease];
	}
	else {
		tranList = [[NSMutableDictionary alloc] init];
        [tranList autorelease];
	}
	[tranList setObject:[NSNumber numberWithInt:1] forKey:tranID];
	[self setPlayerDefaultSetting:tranList forKey:kTransactionList];
	SNSLog(@"%s: transaction list:%@", __FUNCTION__, tranList);
}

// 检查是否有这个IAP ID
+ (BOOL) isIapTransactionUsed:(NSString *)tranID
{
	if(!tranID) return YES;
	NSDictionary *tranList = [self getPlayerDefaultSetting:kTransactionList];
	if(tranList!=nil && [tranList isKindOfClass:[NSDictionary class]] && [tranList objectForKey:tranID]!=nil) return YES;
    if([[SnsStatsHelper helper] isTransactionIDExisting:tranID]) return YES;
	return NO;
}


#pragma mark -

#pragma mark Alert

// 提示需要网络
+(void)showNetworkRequired
{
	// [self incAlertViewCount];
    /*
	// kill app
    SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:[SystemUtils getLocalizedString: @"Network Required"]
                        message:[SystemUtils getLocalizedString: @"Please connect to network and restart the game again."]
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"Close"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertNetworkRequired;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
    */
    UIAlertView *aw = [[UIAlertView alloc] initWithTitle:[SystemUtils getLocalizedString: @"Network Required"]
                                                 message:[SystemUtils getLocalizedString: @"Please connect to network and restart the game again."]
                                                delegate:appDelegate
                                       cancelButtonTitle:[SystemUtils getLocalizedString:@"Close"]
                                       otherButtonTitles:nil];
    aw.tag = kTagAlertNetworkRequired;
    [aw show];
    [aw release];
    
}


// 提示需要下载远程市场
+(void)showRemoteItemRequired
{
	// [self incAlertViewCount];
	// kill app
	[SystemUtils setNSDefaultObject:[NSNumber numberWithInt:1] forKey:kDownloadItemRequired];
    
    SNSAlertView *av = [[SNSAlertView alloc]
                        initWithTitle:[SystemUtils getLocalizedString: @"Remote Item Required"]
                        message:[SystemUtils getLocalizedString: @"Remote items are required to load your save properly. Please connect to network and restart the game again."]
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"Close"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertNetworkRequired;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
    
}

// 显示购买成功提示
+(void)showPaymentNotice:(NSString *)mesg
{
	// [self incAlertViewCount];
	// kill app
    SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:[SystemUtils getLocalizedString: @"Yipee!"]
                        message:[SystemUtils getLocalizedString: mesg]
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertNone;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
}
// 显示购买失败提示
+(void)showPaymentFailNotice:(NSString *)errorMesg
{
    NSString *mesg = [NSString stringWithFormat:@"%@%@", [SystemUtils getLocalizedString:@"Transaction failed.\n"], errorMesg];
    NSString *title = [SystemUtils getLocalizedString: @"Oops!"];
#ifdef SNS_NOTICE_USE_ALERT_VIEW
    UIAlertView *aw = [[UIAlertView alloc] initWithTitle:title
                                                 message:mesg
                                                delegate:nil
                                       cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                                       otherButtonTitles:nil];
    [aw show];
    [aw release];
#else
    SNSAlertView *av = [[SNSAlertView alloc]
                        initWithTitle:title
                        message:mesg
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertNone;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
#endif
}

// 提示资源文件损坏
+(void)showConfigFileCorrupt
{
	// [self incAlertViewCount];
	// kill app
    SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:[SystemUtils getLocalizedString: @"Config File Corrupt"]
                        message:[SystemUtils getLocalizedString: @"Configuration file is corrupt, please reinstall this application."]
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"Close"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertFileCorrupt;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
}

// 提示需要下载远程进度
+(void)showReloadGameRequired
{
	// kTagAlertReloadGameRequired
	// [self incAlertViewCount];
    SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:[SystemUtils getLocalizedString: @"Reload Game Required"]
                        message:[SystemUtils getLocalizedString: @"Remote game is newer, you must restart the game to continue with new save file."]
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"Restart"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertReloadGameRequired;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
}

// 帐号切换提示
+(void)showSwitchAccountHint
{
    SNSAlertView *av = [[SNSAlertView alloc]
                        initWithTitle:[SystemUtils getLocalizedString: @"Reload Game Required"]
                        message:[SystemUtils getLocalizedString: @"OK, you must restart the game to continue with the original account."]
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"Restart"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertReloadGameRequired;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
}

// 提示重置存档完成
+(void)showResetGameDataFinished
{
	// kTagAlertReloadGameRequired
	// [self incAlertViewCount];
    SNSAlertView *av = [[SNSAlertView alloc]
                        initWithTitle:[SystemUtils getLocalizedString: @"Reset Game Data Finished"]
                        message:[SystemUtils getLocalizedString: @"Game data is reset now, you must restart the game to play as a new user."]
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"Restart"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertResetGameDataOK;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
}

// 显示无效支付提示
+(void) showInvalidTransactionAlert:(NSDictionary *)info
{
    SNSLog(@"info:%@",info);
    [self setNSDefaultObject:[info JSONRepresentation] forKey:@"kSnsPayVerifyResult"];
    SNSAlertView *av = [[SNSAlertView alloc]
                        initWithTitle:[SystemUtils getLocalizedString: @"Invalid Transaction"]
                        message:[SystemUtils getLocalizedString: @"We detect your transaction is invalid, if you are sure that your credit card is charged, you can send email to our support and we'll try to verify it again."]
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"Cancel"]
                        otherButtonTitle:[self getLocalizedString:@"Contact Us"], nil];
    
    av.tag = kTagAlertInvalidTransaction;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
    
}


// 崩溃检测提示
+ (void) showCrashDetectedHint
{
	// [self incAlertViewCount];
    SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:[SystemUtils getLocalizedString: @"Crash Detected"]
                        message:[SystemUtils getLocalizedString: @"We detect the game session crashed. Please write a email to describe how did it happen. Thanks."]
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"Not Now"]
                        otherButtonTitle:[self getLocalizedString:@"OK"], nil];
    
    av.tag = kTagAlertCrashDetected;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
}

// BUG修复提示
+ (void) showCrashBugFixed:(NSDictionary *)hintInfo
{
    if(!hintInfo || ![hintInfo objectForKey:@"hint"]) return;
    [hintInfo retain]; // kTagAlertViewDownloadApp
    
    NSString *mesg = [hintInfo objectForKey:@"hint"];
    
    if(![mesg isKindOfClass:[NSString class]] || [mesg length]<10) {
        mesg = [self getLocalizedString:@"We detect the game session crashed. This bug is fixed in lastest version. Please download and update now."];
    }
    
    mesg = [self parseMultiLangStrForCurrentLang:mesg];
    
    NSString *fixVer = [hintInfo objectForKey:@"fixVer"];
    NSString *curOnlineVer = [self getGlobalSetting:kCurrentOnlineVersionKey];
    
    if(!fixVer || [fixVer isEqualToString:@""] || [fixVer isEqualToString:@"0"]) {
        // no download
        SNSAlertView *av = [[SNSAlertView alloc] 
                            initWithTitle:[SystemUtils getLocalizedString: @"Crash Detected"]
                            message:mesg
                            delegate:appDelegate
                            cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                            otherButtonTitle:nil];
        
        av.tag = kTagAlertNone;
        [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
        [av release];
    }
    // else {
    else if([fixVer floatValue]>[[self getBundleVersion] floatValue] && [fixVer floatValue]<=[curOnlineVer floatValue]) {
        SNSAlertView *av = [[SNSAlertView alloc] 
                            initWithTitle:[SystemUtils getLocalizedString: @"Crash Detected"]
                            message:mesg
                            delegate:appDelegate
                            cancelButtonTitle:[SystemUtils getLocalizedString:@"Not Now"]
                            otherButtonTitle:[self getLocalizedString:@"Update"], nil];
        
        av.tag = kTagAlertViewDownloadApp;
        [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
        [av release];
    }
    [hintInfo release];
}

// 显示作弊警告
+(void)showHackAlert
{
	NSMutableDictionary *dict = [self config];
	int hackTime  = [[dict objectForKey:kHackTime] intValue];
	int alertTime = [[dict objectForKey:kHackAlertTimes] intValue];
	if(hackTime == alertTime) return;
	if(alertTime != 0) return;
	// set alert time
	[self setGlobalSetting:[NSNumber numberWithInt:hackTime] forKey:kHackAlertTimes];
	// don't alert for the first time
	if(alertTime == 0 || hackTime<=alertTime) return;
	// [self incAlertViewCount];
	SNSLog(@"%s: hackTime:%i alertTime:%i", __func__, hackTime, alertTime);
	// show alert
    SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:[SystemUtils getLocalizedString: @"Abnormal Device Time Changement"]
                        message:[SystemUtils getLocalizedString: @"We found that you just changed your device time to speed up the growth. If you do that again, you'll not be able to play the game in offline mode."]
                        delegate:nil
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                        otherButtonTitle:nil];
    
    av.tag = kTagAlertNone;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
}

// 提示被阻止
+(void) showBlockedAlert
{
    SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:[SystemUtils getLocalizedString: @"Cheating Behavior Detected"]
                        message:[SystemUtils getLocalizedString: @"Your account is frozen because of cheating behavior. You are forbidden to play this game. You can send us email if you have any question."]
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                        otherButtonTitle:[SystemUtils getLocalizedString:@"Email Us"], nil];
    
    av.tag = kTagAlertAppealForBlock;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
    
}

// 提示需要更新版本
+(void) showForceUpdateAlert
{
    NSString *mesg = [self getGlobalSetting:@"kForceUpdateMesg"];
    if(!mesg) mesg = [self getLocalizedString:@"You have to update to the newest version for playing this game properly."];
    
    mesg = [self parseMultiLangStrForCurrentLang:mesg];
    NSString *title = [SystemUtils getLocalizedString: @"Update Required"];
    
#ifdef SNS_CUSTOM_UPDATE_DIALOG
    // send notification
    // 发送通知
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: mesg, @"mesg", title, @"title",[NSNumber numberWithBool:YES], @"forceUpdate", nil];
    NSNotification *note = [NSNotification notificationWithName:kSNSNotificationOnShowUpdateDialog object:nil userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotification:note];
#else
    

    SNSAlertView *av = [[SNSAlertView alloc]
                        initWithTitle:title
                        message:mesg
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"Update Now"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertForceUpdate;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
#endif
}
// 提示进行评分
+ (void) addReviewHintNotice
{
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
    NSString *title = [SystemUtils getLocalizedString: @"Having Fun?"];
    NSString *mesg  = [SystemUtils getLocalizedString: @"Please rate the game if you enjoy it!"];
    NSString *noticeMesg = [NSString stringWithFormat:@"%@\n%@",title, mesg];
    NSDictionary *dict = @{@"action":@"openRateLink", @"message":noticeMesg, @"id":@RESERVE_NOTICE_ID_RATE_HINT};
    [SNSPromotionViewController addNotice:dict];
#endif
}
// 提示进行评分
+ (void) showReviewHint
{
#ifdef JELLYMANIA
    return;
#endif
    NSString *title = [SystemUtils getLocalizedString: @"Having Fun?"];
    NSString *mesg  = [SystemUtils getLocalizedString: @"Please rate the game if you enjoy it!"];
#ifdef SNS_CUSTOM_RATING_DIALOG
    // send notification
    // 发送通知
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: mesg, @"mesg", title, @"title", nil];
    NSNotification *note = [NSNotification notificationWithName:kSNSNotificationOnShowRatingDialog object:nil userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotification:note];
#else
	// int review = [[SystemUtils getPlayerDefaultSetting:kFollowReviewHint] intValue];
	// if(review == 1) return;
	// [self incAlertViewCount];
    SNSAlertView *av = [[SNSAlertView alloc]
                        initWithTitle:title
                        message:mesg
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"No Thanks"]
                        otherButtonTitle:[self getLocalizedString:@"Rate It!"], nil];
    
    av.tag = kTagAlertViewRateIt;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
#endif
}

// 提示语言包加载完成
+(void) showLangUpdateHint
{
    if(YES)return;
#ifdef DEBUG
	// [self incAlertViewCount];
    SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:[SystemUtils getLocalizedString: @"Language Updated"]
                        message:[SystemUtils getLocalizedString: @"Language file is updated. Sometimes you need restart the game to see the modified text. This hint only shows in DEBUG mode."]
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                        otherButtonTitle:[self getLocalizedString:@"Restart"], nil];
    
    av.tag = kTagAlertReloadLanguage;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
#endif
}

+(void)showSNSAlert:(NSString*)title message:(NSString*)message{
    SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:title
                        message:message
                        delegate:appDelegate
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertNone;
    [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av release];
}

// 显示时加1
+(void) incAlertViewCount
{
	_alertViewCount++;
}

// 关闭时减1
+(void) decAlertViewCount
{
	if(_alertViewCount>0) _alertViewCount--;
}

// 检查目前是否有View
+(BOOL) doesAlertViewShow
{
	if(_alertViewCount>0) return YES;
	return NO;
}


#pragma mark -

/*
//根据礼物ID获取到礼物信息
+(NSMutableDictionary*)getGifInfo:(int)gifID
{
	return [GameConfig getGifInfo:gifID];
}
 */


//打开好友空间
+(void)openFriendSpace:(NSDictionary *)friendData error:(NSError *)error
{
	NSDictionary* saveDict1 =[friendData objectForKey:@"data"];//取出第一层里的data
	NSDictionary* saveDict2 =[saveDict1 objectForKey:@"data"];//取出第二层里的data
	if ((saveDict2!=nil && [saveDict2 isKindOfClass:[NSDictionary class]])) 
    {
		SNSLog(@"社交空间返回的数据1111111========>%@",[friendData description]);
        /*
		CVisitScene* visitScene = [[CVisitScene alloc]initWithDictionary:friendData error:error];
		CCScene *sc = [CCScene node];
		[sc addChild:visitScene];
		[[CCDirector sharedDirector] replaceScene:sc];
		[visitScene release];
         */
	}
}

+ (UIViewController *)getRootViewController
{
    if(_gSNSRootViewController)
        return _gSNSRootViewController;
    return [self getAbsoluteRootViewController];
}

+ (void) setRootViewController:(UIViewController *)controller
{
    _gSNSRootViewController = controller;
}

// 返回绝对的rootViewController
+ (UIViewController *)getAbsoluteRootViewController
{
#ifndef SNS_POPUP_IN_TOP_WINDOW
    if(_gSNSRootViewController) return _gSNSRootViewController;
#endif
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	if (!window) {
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	}
    
    UIResponder *nextResponder = [window.subviews lastObject];
    while(nextResponder){
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }else{
            nextResponder = [nextResponder nextResponder];
        }
    }
    
    if(window.rootViewController) {
        return window.rootViewController;
    }
    
    if(_gSNSRootViewController) return _gSNSRootViewController;
	return nil;
}

// 是否启用growMobile
+(BOOL) isGrowMobileEnabled
{
    NSString *key = [self getSystemInfo:@"kGrowMobileAppKey"];
    if(key!=nil && [key length]>3) return YES;
    return NO;
}

+(BOOL) isJailbreak
{
    NSString *filePath = @"/Applications/Cydia.app";
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

@end
