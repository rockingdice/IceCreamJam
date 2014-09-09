//
//  BubbleServiceUtils.m
//  BubbleClient
//
//  Created by LEON on 12-10-26.
//  Copyright (c) 2012年 SNSGAME. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <sys/sysctl.h>
#include <sys/socket.h> // Per msqr
#include <net/if.h>
#include <net/if_dl.h>
#include <sys/xattr.h>
#import "ZipArchive.h"
// #import "SSZipArchive.h"
#import "BubbleServiceUtils.h"
// #import "SystemUtils.h"

@implementation BubbleServiceUtils

+(NSString *)stringByUrlEncodingString:(NSString *)input
{
	if(!input) return nil;
	CFStringRef value = CFURLCreateStringByAddingPercentEscapes(
																kCFAllocatorDefault,
																(CFStringRef) input,
																NULL,
																(CFStringRef) @"!*'();:@&=+$,/?%#[]",
																kCFStringEncodingUTF8);
	
	NSString *result = [NSString stringWithString:(NSString *)value];
	CFRelease(value);
	
	return result;
}

+(NSString *)stringByHashingDataWithSHA1:(NSData *)input
{
	if(!input) return nil;
	
	uint8_t digest[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(input.bytes, input.length, digest);
	
	NSData *digestData = [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
	
	const uint8_t *bytes = digestData.bytes;
	NSMutableString *result = [NSMutableString stringWithCapacity:2 * digestData.length];
	
	for (int i = 0; i < digestData.length; i++)
		[result appendFormat:@"%02x", bytes[i]];
	
	return result;
}

+(NSString *)stringByHashingStringWithSHA1:(NSString *)input
{
	if(!input) return nil;
	NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
	return [self stringByHashingDataWithSHA1:data];
}

+(NSString *)stringByHashingDataWithMD5:(NSData *)input
{
	if(!input) return nil;
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	// const char *src = [input bytes];
	CC_MD5([input bytes], [input length], digest);
	NSString *sig = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
					 digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7],
					 digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]];
	return sig;
}

+(NSString *)stringByHashingStringWithMD5:(NSString *)input
{
	if(!input) return nil;
	NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
	return [self stringByHashingDataWithMD5:data];
}



+ (NSString *) getClientVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}


+ (NSString *) getSubID
{
    // NSString *appID = [SystemUtils getSystemInfo:@"kSubAppID"];
    /*
    NSString *appID = nil;
    if(appID==nil) appID = @"0";
    return appID;
     */
    return @"0";
}

+ (NSString *) getClientHMAC
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
		NSLog(@"Error: if_nametoindex error\n");
		return NULL;
	}
	
	if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
	{
		NSLog(@"Error: sysctl, take 1\n");
		return NULL;
	}
	
	if ((buf = malloc(len)) == NULL)
	{
		NSLog(@"Could not allocate memory. error!\n");
		return NULL;
	}
	
	if (sysctl(mib, 6, buf, &len, NULL, 0) < 0)
	{
		NSLog(@"Error: sysctl, take 2");
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

+ (NSString *) getClientLanguage
{
    NSArray *languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
    return [languages objectAtIndex:0];
}

+ (NSString *) getClientCountry
{
    return [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
}

+ (NSString *) getDeviceModel
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *model = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    return model;
}
// 获得设备类型：1-iPhone，2-iPad，3-iPod, 0-unknown
+ (int) getDeviceType
{
    NSString *model = [self getDeviceModel];
    if([model rangeOfString:@"iPhone"].location == 0) return 1;
    if([model rangeOfString:@"iPad"].location == 0) return 2;
    if([model rangeOfString:@"iPod"].location == 0) return 3;
    // if([SystemUtils isiPad]) return 2;
    return 0;
}

// get current device timestamp
+ (int)getCurrentDeviceTime
{
	NSDate *dt = [NSDate date];
	double time1 = [dt timeIntervalSince1970];
	int time = time1;
	//NSLog(@"time:%i time1:%lf", time, time1);
	return time;
}

// unzip files to a path
+ (BOOL) unzipFile:(NSString *)zipFile toPath:(NSString *)path
{
	if (![[NSFileManager defaultManager] fileExistsAtPath:zipFile]) {
		return NO;
	}
	BOOL ret = NO;
    
    /*
	// SSZipArchive* za = [[SSZipArchive alloc] init];
        NSError *err = nil;
		ret = [SSZipArchive unzipFileAtPath:zipFile toDestination:path overwrite:YES password:nil error:&err];
        if(!ret) {
#ifdef DEBUG
            NSLog(@"failed to unzip file %@: %@", zipFile, err);
#endif
        }
	// [za release];
     */
    
    ZipArchive *za = [[ZipArchive alloc] init];
    if([za UnzipOpenFile:zipFile]) {
        ret = [za UnzipFileTo:path overWrite:YES];
        [za UnzipCloseFile];
    }
    [za release];
    
	return ret;
}


@end
