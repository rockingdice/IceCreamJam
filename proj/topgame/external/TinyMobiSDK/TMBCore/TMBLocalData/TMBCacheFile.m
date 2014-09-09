//
//  TMBCacheFile.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-8-29.
//
//

#import "TMBCacheFile.h"
#import "TMBConfig.h"
#import <CommonCrypto/CommonDigest.h>
#import "TMBNetWork.h"
#import "TMBLog.h"
#import "TMBJob.h"

@interface NSString (MyExtensions)
    - (NSString *) md5;
@end

@implementation NSString (TMBExtensions)
- (NSString *) md5
{
    const char *cStr = [self UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result );
    return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",result[0], result[1], result[2], result[3],result[4], result[5], result[6], result[7],result[8], result[9], result[10], result[11],result[12], result[13], result[14], result[15]];
}
@end

@implementation TMBCacheFile

+(NSString *)getFile: (NSString *)urlStr
{
    NSString *fileName = nil;
    if (urlStr) {
        NSURL *url = [NSURL URLWithString:urlStr];
        NSString *pathExtension = [[url path] pathExtension];
        fileName = [NSString stringWithFormat:@"%@/%@.%@", [[url path] stringByDeletingPathExtension], [urlStr md5], pathExtension];
    }
    if([fileName length] < 1){
        return nil;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    if (!cacheDirectory) {
        [TMBLog log:@"PLIST" :@"Documents directory not found!"];
        return nil;
    }else {
        NSString *cacheFile = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"tmb_sdk_cache/%@", fileName]];
        return cacheFile;
    }
}

-(void) saveCacheWithURL: (NSString *)url
{
    TMBNetWork *net = [[[TMBNetWork alloc] init] autorelease];
    [net setTimeout:TMB_NET_TIMEOUT];
    [net setWithoutSysParam:YES];
    NSData *response = [net sendRequestWithURL:url Data:nil];
    NSString *cachePath = [TMBCacheFile getFile:url];
    if (response && [response length]>0) {
        NSString *dir = [cachePath stringByDeletingLastPathComponent];
            NSFileManager *fm = [NSFileManager defaultManager];
            if (![fm fileExistsAtPath:dir]){
                [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
            }
            [response writeToFile:cachePath atomically:YES];
            [TMBLog log:@"CACHE OK" :cachePath];
        }else{
            [TMBLog log:@"CACHE FAIL" :cachePath];
        }
}

+(NSString *) getCacheFileWithURL: (NSString *)url
{
    NSString *filePath = [self getFile:url];
    NSFileManager *fm = [NSFileManager defaultManager];
    //[TMBLog log:@"CACHE FILE" :filePath];
    if ([fm fileExistsAtPath:filePath]) {
        return filePath;
    }else{
        TMBCacheFile *cache = [[[TMBCacheFile alloc] init] autorelease];
        [TMBJob addCacheQueueWithTarget:cache selectot:@selector(saveCacheWithURL:) object:url];
        return nil;
    }
}

@end
