//
//  TMBCommon.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-2.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import "TMBCommon.h"
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import "TMBConfig.h"
#import "TMBReachability.h"

#ifdef __IPHONE_6_0
#import <AdSupport/AdSupport.h>
#endif

#import "TMBLog.h"

#define TMB_NET_WIFI @"WIFI"
#define TMB_NET_3G @"3G"
#define TMB_NET_GSM @"GSM"

static NSMutableDictionary *_sharedTMBSysEnv = nil;

static UIInterfaceOrientation _sharedTMBOrientation;

static NSString *_sharedTMBAppOrientation = nil;

@implementation TMBCommon

+ (NSString*) getSysInfoByName:(char *)typeSpecifier
{
	size_t size;
	sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    char answer[size];
	sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
	NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
	return results;
}

//mac
+ (NSString *)getMacAddress
{  
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;  
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)  
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem  
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info  
    mgmtInfoBase[2] = 0;                
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information  
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces  
    
    // With all configured interfaces requested, get handle index  
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)   
        errorFlag = @"if_nametoindex failure";  
    else  
    {  
        // Get the size of the data available (store in len)  
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)   
            errorFlag = @"sysctl mgmtInfoBase failure";  
        else  
        {  
            // Alloc memory based on above call  
            if ((msgBuffer = malloc(length)) == NULL)  
                errorFlag = @"buffer allocation failure";  
            else  
            {  
                // Get system information, store in buffer  
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)  
                    errorFlag = @"sysctl msgBuffer failure";  
            }  
        }  
    }  
    
    // Befor going any further...  
    if (errorFlag != NULL)  
    {
        return errorFlag;
    }  
    
    // Map msgbuffer to interface message structure  
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;  
    
    // Map to link-level socket structure  
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);  
    
    // Copy link layer address data in socket structure to an array  
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);  
    
    // Read from char array into a string object, into traditional Mac address format  
    NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",   
                                  macAddress[0], macAddress[1], macAddress[2],   
                                  macAddress[3], macAddress[4], macAddress[5]];  

    // Release the buffer memory  
    free(msgBuffer);  
    return macAddressString;  
}

//uuid 
+ (NSString *)getUUID
{
    NSString *key = @"TMB_SDK_UUID";
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [userDefaults objectForKey:key];
    if (!uuid || [uuid length]<1) {
        CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef uuidStringRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
        CFRelease(uuidRef);
        uuid = [NSString stringWithString:(NSString *)uuidStringRef];
        CFRelease(uuidStringRef);
        [userDefaults setObject:uuid forKey:key];
    }
    return uuid;
}

//ADF
+ (NSString *)getIDFV
{
#ifdef __IPHONE_6_0
    if ([UIDevice instancesRespondToSelector:@selector(identifierForVendor)]) {
        return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    return @"";
#endif
    return @"";
}

//adid
+ (NSString *)getADID
{
#ifdef __IPHONE_6_0
    if (NSClassFromString(@"ASIdentifierManager")) {
        id adManager = [NSClassFromString(@"ASIdentifierManager") sharedManager];
        if ([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) {
            return [[adManager advertisingIdentifier] UUIDString];
        }
    }
    return @"";
#endif
    return @"";
}

//system version
+ (NSString *)getSysVersion
{
    UIDevice *device = [UIDevice currentDevice];
    NSString *sysVersion = [NSString stringWithFormat:@"%@%@", [device systemName], [device systemVersion]];
    return sysVersion;
}

+ (NSString *)getPlatform{
    NSString *platform = [self getSysInfoByName:"hw.machine"];
    if ([platform isEqualToString:@"i386"] || [platform isEqualToString:@"x86_64"]){
        if ([[UIScreen mainScreen] bounds].size.width < 760) {
            return @"iPhone Simulator";
        }else{
            return @"iPad Simulator";
        }
    }
    return platform;
}

+ (NSString *)getAppName
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    return appName;
}

+ (NSString *)getAppVersion
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    return appVersion;
}

+ (NSString *)getAppBundleVersion
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appBundleVer = [infoDictionary objectForKey:@"CFBundleVersion"];
    return appBundleVer;
}

+ (NSString *)getSystemLanguage
{
    NSString *languageCode = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    return languageCode;
}

+ (NSString *)getSystemCountry
{
    NSString *countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    return countryCode;
}

+ (NSString*)getTimeStamp
{
	NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
	// Get seconds since Jan 1st, 1970.
	NSString *timeStamp = [NSString stringWithFormat:@"%d", (int)timeInterval];
	return timeStamp;
}

+ (NSString *)getOpenUDID
{
    return @"";
}

+ (NSString *)getNet
{
    if([[TMBReachability reachabilityForLocalWiFi] currentReachabilityStatus] != NotReachable){
        return TMB_NET_WIFI;
    }else if ([[TMBReachability reachabilityForInternetConnection] currentReachabilityStatus]!= NotReachable) {
        return TMB_NET_3G;
    }else {
        return TMB_NET_GSM;
    }
}

+ (NSString *)getScreenSize
{
    CGRect rect=[[UIScreen mainScreen] bounds];
    int w = rect.size.width;
    int h = rect.size.height;
    if (([[self getAppOrientation] isEqualToString:@"0"] && rect.size.width<rect.size.height)
        || ([[self getAppOrientation] isEqualToString:@"1"] && rect.size.width>rect.size.height)) {
        w = rect.size.height;
        h = rect.size.width;
    }
    NSString *size = [NSString stringWithFormat:@"%dx%d", w, h];
    return size;
}

+ (NSString *)getOrientation
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    UIDeviceOrientation currentOrientation = [ [UIDevice currentDevice] orientation];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    if (currentOrientation == UIDeviceOrientationLandscapeLeft) {
        _sharedTMBOrientation = UIInterfaceOrientationLandscapeRight;
        return @"0";
    }else if (currentOrientation == UIDeviceOrientationLandscapeRight){
        _sharedTMBOrientation = UIInterfaceOrientationLandscapeLeft;
        return @"0";
    }else if (currentOrientation == UIDeviceOrientationPortrait){
        _sharedTMBOrientation = UIInterfaceOrientationPortrait;
        return @"1";
    }else if (currentOrientation==UIDeviceOrientationPortraitUpsideDown){
        _sharedTMBOrientation = UIInterfaceOrientationPortraitUpsideDown;
        return @"1";
    }else{
        UIInterfaceOrientation sbOrientation = [UIApplication sharedApplication].statusBarOrientation;
        _sharedTMBOrientation = sbOrientation;
        if (sbOrientation==UIInterfaceOrientationLandscapeLeft || sbOrientation==UIInterfaceOrientationLandscapeRight) {
            return @"0";
        }else{
            return @"1";
        }
    }
}

+ (UIInterfaceOrientation) getSharedOrientation
{
    if (!_sharedTMBOrientation) {
        [self getOrientation];
    }
    return _sharedTMBOrientation;
}

+ (void) setAppOrientation:(NSString *)_orientation
{
    _sharedTMBAppOrientation = _orientation;
}

+ (NSString *)getAppOrientation
{
    if (_sharedTMBAppOrientation && ([_sharedTMBAppOrientation isEqualToString:@"0"] || [_sharedTMBAppOrientation isEqualToString:@"1"])) {
        return _sharedTMBAppOrientation;
    }else{
        NSString *ori = [self getOrientation];
        [self setAppOrientation:ori];
        return ori;
    }
    
}

+ (void)initSysInfo
{
    if (!_sharedTMBSysEnv) {
        _sharedTMBSysEnv = [[NSMutableDictionary alloc] init];
        [_sharedTMBSysEnv setValue:[self getAppVersion] forKey:@"app_version"];
        [_sharedTMBSysEnv setValue:[self getMacAddress] forKey:@"sys_mac"];
        [_sharedTMBSysEnv setValue:[self getPlatform] forKey:@"sys_platform"];
        [_sharedTMBSysEnv setValue:[self getUUID] forKey:@"sys_uuid"];
        [_sharedTMBSysEnv setValue:[self getOpenUDID] forKey:@"sys_udid"];
        [_sharedTMBSysEnv setValue:[self getADID] forKey:@"sys_adid"];
        [_sharedTMBSysEnv setValue:[self getIDFV] forKey:@"sys_idfv"];
        [_sharedTMBSysEnv setValue:[self getSysVersion] forKey:@"sys_version"];
        [_sharedTMBSysEnv setValue:[self getScreenSize] forKey:@"sys_size"];
        [_sharedTMBSysEnv setValue:TMB_SDK_VERSION forKey:@"sdk_version"];
        [_sharedTMBSysEnv setValue:[self getSystemCountry] forKey:@"sys_country"];
        [_sharedTMBSysEnv setValue:[self getSystemLanguage] forKey:@"sys_language"];
    }
}
//get system info
+(NSDictionary *)getSysInfo
{
    if(!_sharedTMBSysEnv){
        [self initSysInfo];
    }
    NSMutableDictionary *globalInfo = [NSMutableDictionary dictionaryWithDictionary:_sharedTMBSysEnv];
    [globalInfo setValue:[self getNet] forKey:@"sys_net"];
    [globalInfo setValue:[self getAppOrientation] forKey:@"sys_orientation"];
    return globalInfo;
}

+ (UIViewController *)getRootViewController
{
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
    if(window.rootViewController){
        return window.rootViewController;
    }
    return nil;
}

@end
