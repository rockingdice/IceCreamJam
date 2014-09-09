//
//  RemoteDataHelper.m
//  FarmSlots
//
//  Created by lcg on 8/15/14.
//
// 所有的请求，都需要sig签名。 当没有针对用户的secret时， app会有一个默认的secret用于签名，现在是 'default key’
// 当传数中存在token并有效时， 必需使用用户的secret.
// http://fbjellyth.topgame.com:3000/
// sig签名规则
// 所有传递的参数，除sig以外，按参数名从小到大的顺序， 对参数值进行hmac(md5)签名。

#import "RemoteDataHelper.h"
#import "SystemUtils.h"
#import "StringUtils.h"

#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

#define REMOTE_DATA_URL @"http://fbjellyth.topgame.com:3000/"

enum {
    kRemoteDataHelperRequestTypeNone = 0,
    kRemoteDataHelperRequestTypeCreateAuth = 1,
    kRemoteDataHelperRequestTypeUpdateData = 2,
    kRemoteDataHelperRequestTypeGetData = 3
};

@implementation RemoteDataHelper

static RemoteDataHelper  *_gRemoteDataHelper = nil;

+ (RemoteDataHelper *) helper{
    @synchronized(self)
    {
        if(_gRemoteDataHelper==nil) {
            _gRemoteDataHelper = [[RemoteDataHelper alloc] init];
        }
    }
    return _gRemoteDataHelper;
}

- (id) init{
    self = [super init];
    if(self!=nil) {
    }
    return self;
}

- (void) dealloc{
    [super dealloc];
}

#pragma mark -
// 初始化身份
// url: /auth/create
//message Create {
//    required string app_id = 1; //项目名,如jelly
//    required string uuid = 2; //用户标识，数字或字符串
//    required string ostype = 3, // 系统类型，0-iOS，1-android
//    required string prefix = 4,  // 默认为空，如果有值的话就是两个字符，比如 hd
//    optional string password = 4; //可选密码
//    optional string unique = 5; //当传递时,会使之前的secret失效
//    required string sig = 6;
//}
- (void)createAuthWithUUID:(NSString*)uuid password:(NSString*)password secret:(NSString*)secret{
    NSString *sessionKey = [SystemUtils getSessionKey];
    if(!sessionKey) {
        return;
    }
    
    NSString *appID = [SystemUtils getSystemInfo:@"kFlurryCallbackAppID"];
    NSString *ostype = @"0";// 0-ios, 1-android
    NSString *prefix = [SystemUtils getSystemInfo:@"kHMACPrefix"];
    if(prefix==nil) prefix = @"";
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:appID forKey:@"app_id"];
    [dict setValue:uuid forKey:@"uuid"];
    [dict setValue:ostype forKey:@"ostype"];
    [dict setValue:prefix forKey:@"prefix"];
    [dict setValue:@"1" forKey:@"unique"];
    if(password){
        [dict setValue:password forKey:@"password"];
    }
    
	NSString *link = [NSString stringWithFormat:@"%@auth/create", REMOTE_DATA_URL];
    ASIFormDataRequest *request = [self makeHMACPostWithLink:link secret:secret valueDic:dict];
    [request setTag:kRemoteDataHelperRequestTypeCreateAuth];
    [request setDelegate:self];
    [request startAsynchronous];
}

- (void)createAuthWithUUID:(NSString*)uuid secret:(NSString*)secret{
    [self createAuthWithUUID:uuid password:nil secret:secret];
}

// 更新存档,
// url, /data/update
//message Update {
//    required string token = 1; //前面的token
//    required string data = 2; //游戏数据
//    required string sig = 3; //使用secret对data签名 hash_hmac(md5)
//    optional int32 cas = 4; //用于判断是否可更新,可选。不传或非数字时总是操作
//    optional string key = 5; //可以自定议细粒度的存档，并且该存档对其它玩家可见。
//}
//
//message UpdateResponse {
//    required int32 ret = 1; //0是正常，其它是失败
//    optional string msg = 2; //错误说明
//}
- (void)updateDataWithToken:(NSString*)token data:(NSString*)data secret:(NSString*)secret{
    [self updateDataWithToken:token data:data secret:secret cas:nil key:nil];
}

- (void)updateDataWithToken:(NSString*)token data:(NSString*)data secret:(NSString*)secret cas:(NSNumber*)cas key:(NSString*)key{
    NSString *sessionKey = [SystemUtils getSessionKey];
    if(!sessionKey) {
        return;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:token forKey:@"token"];
    [dict setValue:data forKey:@"data"];
    if(cas){
        [dict setValue:cas forKey:@"cas"];
    }
    if(key){
        [dict setValue:key forKey:@"key"];
    }
    
	NSString *link = [NSString stringWithFormat:@"%@data/update", REMOTE_DATA_URL];
    ASIFormDataRequest *request = [self makeHMACPostWithLink:link secret:secret valueDic:dict];
    [request setTag:kRemoteDataHelperRequestTypeUpdateData];
    [request setDelegate:self];
    [request startAsynchronous];
}

// 查询存档
// url: /data/get
//message Get {
//    required string token = 1; //前面的token
//    optional string uuid = 2; //用户标识，查询其它用户数据时使用
//    optional string uid = 3; //用户标识，查询其它用户数据时使用
//    optional string key = 4; //存档的key, 查询其它用户是必需
//    required string sig = 5; //sig
//}
//
//message Data {
//    optional string uuid = 1;
//    optional string uid = 2;
//    optional string key = 3;
//    required string val = 4; // 结果字符串
//}
//
//message GetResponse {
//    required int32 ret = 1; //0是正常，其它是失败
//    repeated Data data = 2; //这是个数组
//}
- (void)getDataWithToken:(NSString*)token secret:(NSString*)secret{
    [self getDataWithToken:token secret:secret uuid:nil uid:nil key:nil];
}

- (void)getDataWithToken:(NSString*)token secret:(NSString*)secret uuid:(NSString*)uuid uid:(NSString*)uid key:(NSString*)key{
    NSString *sessionKey = [SystemUtils getSessionKey];
    if(!sessionKey) {
        return;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:token forKey:@"token"];
    if(uuid){
        [dict setValue:uuid forKey:@"uuid"];
    }
    if(uid){
        [dict setValue:uuid forKey:@"uid"];
    }
    if(key){
        [dict setValue:key forKey:@"key"];
    }
    
	NSString *link = [NSString stringWithFormat:@"%@data/get", REMOTE_DATA_URL];
    ASIFormDataRequest *request = [self makeHMACGetWithLink:link secret:secret valueDic:dict];
    [request setTag:kRemoteDataHelperRequestTypeGetData];
    [request setDelegate:self];
    [request startAsynchronous];
}

static void _setDictValToAnother(NSDictionary *from, NSMutableDictionary *to, NSString *key, ...){
    va_list args;
    va_start(args, key);

    if(key){
        [to setValue:[from valueForKey:key] forKey:key];
        
        NSString *i = va_arg(args, NSString*);
        while(i){
            [to setValue:[from valueForKey:i] forKey:i];
            i = va_arg(args, NSString*);
        }
    }
    
    va_end(args);
}

#pragma mark -
#pragma mark request callback
//message CreateResponse {
//    required int32 ret = 1; // 0是正常，其它是失败
//    optional string msg = 2; // 错误说明
//    optional string token = 3; // 以后用于通信的验证串
//    optional string secret = 4; // 存放于本地，用于签名，方法为hmac(md5)
//    optional int32 uid = 5; // 服务器端生的序列ID，可选使用
//    optional int32 newuser = 6; // 如果是新创建的用户，newuser＝1
//}

//message UpdateResponse {
//    required int32 ret = 1; //0是正常，其它是失败
//    optional string msg = 2; //错误说明
//}

//message Data {
//    optional string uuid = 1;
//    optional string uid = 2;
//    optional string key = 3;
//    required string val = 4; // 结果字符串
//}
//
//message GetResponse {
//    required int32 ret = 1; //0是正常，其它是失败
//    repeated Data data = 2; //这是个数组
//}
- (void)requestFinished:(ASIHTTPRequest *)request{
	int status = request.responseStatusCode;
	if(status>=400) {
		return;
	}
    
    NSString *text = [request responseString];
    NSDictionary *dict = [StringUtils convertJSONStringToObject:text];
    int type = request.tag;
    // 此处不存储相关数据, 请在具体业务代码中存储
    if(kRemoteDataHelperRequestTypeCreateAuth == type){
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        _setDictValToAnother(dict, userInfo, @"ret", @"msg", @"token", @"secret", @"uid", nil);
        [[NSNotificationCenter defaultCenter] postNotificationName:kRemoteDataHelperNotificationCreateAuthFinished object:nil userInfo:userInfo];
    }
    else if(kRemoteDataHelperRequestTypeUpdateData == type){
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        _setDictValToAnother(dict, userInfo, @"ret", @"msg", nil);
        [[NSNotificationCenter defaultCenter] postNotificationName:kRemoteDataHelperNotificationUpdateDataFinished object:nil userInfo:userInfo];
    }
    else if(kRemoteDataHelperRequestTypeGetData == type){
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        _setDictValToAnother(dict, userInfo, @"ret", @"data", nil);
        [[NSNotificationCenter defaultCenter] postNotificationName:kRemoteDataHelperNotificationGetDataFinished object:nil userInfo:userInfo];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request{
	NSError *error = [request error];
	SNSLog(@"%s - error: %@", __FUNCTION__, error);
}

#pragma mark -
#pragma mark request with hmac(md5)

- (ASIFormDataRequest*)makeHMACPostWithLink:(NSString*)link secret:(NSString*)secret valueDic:(NSDictionary*)dict{
    NSURL *url = [NSURL URLWithString:link];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
    
    NSArray *keys = [dict allKeys];
    for(NSString *key in keys){
        id <NSObject>val = [dict valueForKey:key];
        [request setPostValue:val forKey:key];
    }
    
    NSString *sig = [self HMacMD5WithSecret:secret valueDic:dict];
    [request setPostValue:sig forKey:@"sig"];
    return request;
}

- (ASIFormDataRequest*)makeHMACGetWithLink:(NSString*)link secret:(NSString*)secret valueDic:(NSDictionary*)dict{
    NSMutableString *mlink = [NSMutableString stringWithString:link];
    NSArray *keys = [dict allKeys];
    BOOL isStart = YES;
    for(NSString *key in keys){
        if(isStart){
            id val = [dict valueForKey:key];
            if([val isKindOfClass:[NSNumber class]]){
                val = [val stringValue];
            }
            if(val){
                [mlink appendFormat:@"/?%@=%@", key, val];
                isStart = NO;
            }
        }
        else{
            NSString *val = [[dict valueForKey:key] stringValue];
            if(val){
                [mlink appendFormat:@"&%@=%@", key, val];
            }
        }
        
    }
    
    NSString *sig = [self HMacMD5WithSecret:secret valueDic:dict];
    if([keys count] > 0 && [sig length] > 0){
        [mlink appendFormat:@"&sig=%@", sig];
    }
    
    NSURL *url = [NSURL URLWithString:mlink];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"GET"];
    
    return request;
}

- (NSString*) HMacMD5WithSecret:(NSString*)secret valueDic:(NSDictionary*)dict{
    NSArray *sortedKeys = [[dict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString*)obj1 compare:(NSString*)obj2];
    }];
    
    
    const char *_secret = [secret UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH] = {0};
    char hexmac[2 * CC_MD5_DIGEST_LENGTH + 1];
    char *p;

    CCHmacContext    ctx;
    CCHmacInit(&ctx, kCCHmacAlgMD5, _secret, strlen(_secret));
    for(NSString *key in sortedKeys){
        id value = [dict valueForKeyPath:key];
        const char *cval = NULL;
        if([value isKindOfClass:[NSNumber class]]){
            cval = [[value stringValue] UTF8String];
        }
        else if([value isKindOfClass:[NSString class]]){
            cval = [value UTF8String];
        }
        CCHmacUpdate(&ctx, cval, strlen(cval));
    }
    CCHmacFinal(&ctx, digest);
    
    p = hexmac;
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        snprintf(p, 3, "%02x", digest[i]);
        p += 2;
    }
    
    return [NSString stringWithUTF8String:hexmac];
}

@end
