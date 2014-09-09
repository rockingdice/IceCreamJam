//
//  TMBCommon.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-2.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMBCommon : NSObject

+ (NSString *)getMacAddress;

+ (NSString *)getUUID;

+ (NSString *)getIDFV;

+ (NSString *)getADID;

+ (NSString *)getSysVersion;

+ (NSString *)getPlatform;

+ (NSString *)getAppName;

+ (NSString *)getAppVersion;

+ (NSString *)getAppBundleVersion;

+ (NSString *)getSystemLanguage;

+ (NSString *)getSystemCountry;

+ (NSString *)getTimeStamp;

+ (NSString *)getOpenUDID;

+ (NSString *)getNet;

+ (NSDictionary *)getSysInfo;

+ (void)initSysInfo;

+ (NSString *)getScreenSize;

+ (NSString *)getOrientation;

+ (UIInterfaceOrientation) getSharedOrientation;

+ (void) setAppOrientation:(NSString *)_orientation;

+ (NSString *)getAppOrientation;

+ (UIViewController *)getRootViewController;

@end
