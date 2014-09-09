//
//  BubbleServiceUtils.h
//  BubbleClient
//
//  Created by LEON on 12-10-26.
//  Copyright (c) 2012年 SNSGAME. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BubbleServiceUtils : NSObject

+(NSString *)stringByUrlEncodingString:(NSString *)input;

+(NSString *)stringByHashingDataWithSHA1:(NSData *)input;
+(NSString *)stringByHashingStringWithSHA1:(NSString *)input;

+(NSString *)stringByHashingDataWithMD5:(NSData *)input;
+(NSString *)stringByHashingStringWithMD5:(NSString *)input;

+ (NSString *) getClientLanguage;
+ (NSString *) getClientCountry;
+ (NSString *) getDeviceModel;
+ (NSString *) getClientHMAC;
+ (NSString *) getClientVersion;
// get current device timestamp
+ (int) getCurrentDeviceTime;
// 获得设备类型：1-iPhone，2-iPad，3-iPod
+ (int) getDeviceType;
// unzip files to a path
+ (BOOL) unzipFile:(NSString *)zipFile toPath:(NSString *)path;

@end
