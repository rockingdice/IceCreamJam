//
//  TMBNetWork.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-6-25.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import "TMBConfig.h"
#import "TMBNetWork.h"
#import "TMBCommon.h"
#import "TMBJSONKit.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import "TMBGTMBase64.h"

#import "TMBLog.h"

static NSString *_TMB_SERVER_HOST = TMB_SERVICE_URL;
static BOOL _TMB_SANDBOX_URL_FLAG = FALSE;

@interface TMBNetWork ()
{
    id async;
    SEL asyncMethod;
    NSString *asyncUrl;
    NSMutableData *receiveData;
}
@end

@implementation TMBNetWork
@synthesize timeout;
@synthesize secretKey;
@synthesize withoutSysParam;

-(id) initWithSecretKey:(NSString *)_secretKey
{
    if(self = [super init]){
        secretKey = _secretKey;
    }
    return self;
}

//sync request
-(NSData *) sendRequestWithURL: (NSString *)url Data: (NSDictionary *)postData
{
    //args check
    if([url length]<1){
        return nil;
    }
    NSMutableURLRequest *request = [self makeRequest:url Data:postData];
    
    NSHTTPURLResponse *urlResponse = nil;  
	NSError *error = nil;  
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
	if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300) {
        [TMBLog log:@"NET SYNC FINFISH":[NSString stringWithFormat:@"%@ : %@",url, [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]]];
        return responseData;
	}else{
        [TMBLog log:@"NET SYNC FAIL":[NSString stringWithFormat:@"%@ : %@",url, error]];
        return nil;
    }
}

//async net request
-(BOOL) sendAsyncRequestWithURL: (NSString *)url Data: (NSDictionary *)postData ResponseObj: (id)respons Method: (SEL)method;
{
    //args check
    if(!url || [url length]<1 || respons==nil){
        return FALSE;
    }
    NSMutableURLRequest *request = [self makeRequest:url Data:postData];
    async = [respons retain];
    asyncMethod = method;
    asyncUrl = url;
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(conn){
        receiveData = [[NSMutableData data] retain];
        [conn start];
        return TRUE;
    }else{
        return FALSE;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [receiveData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receiveData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    [connection release];
    // receivedData is declared as a method instance elsewhere
    [receiveData release];
    
    // inform the user
    [TMBLog log:@"NET ASYNC FAIL":[NSString stringWithFormat:@"%@ : %@", asyncUrl, error]];
    if ([async respondsToSelector:asyncMethod]) {
        [async performSelector:asyncMethod withObject:nil];
    }
    [async release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [TMBLog log:@"NET ASYNC FINFISH":[NSString stringWithFormat:@"%@ : %@",asyncUrl, [[[NSString alloc] initWithData:receiveData encoding:NSUTF8StringEncoding] autorelease]]];
    if ([async respondsToSelector:asyncMethod]) {
        [async performSelector:asyncMethod withObject:receiveData];
    }
    [async release];
    // release the connection, and the data object
    [connection release];
    [receiveData release];
}

//make request
-(NSMutableURLRequest *)makeRequest: (NSString *)url Data: (NSDictionary *)postData
{
    //make request
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setURL:[NSURL URLWithString:url]];
    if(timeout > 0){
        [request setTimeoutInterval:timeout];
    }else{
        [request setTimeoutInterval:60];
    }
    //add sys params
    NSMutableDictionary *allPostData = [[[NSMutableDictionary alloc] init] autorelease];
    if(![self withoutSysParam]){
        [allPostData setDictionary:[TMBCommon getSysInfo]];
        [allPostData setValue:[TMBCommon getTimeStamp] forKey:@"sys_time"];
    }
    if(postData != nil){
        [allPostData addEntriesFromDictionary:postData];
    }
    if ([allPostData count] > 0) {
        //json
        NSString *jsonStr = [allPostData JSONString];
        NSString *signData = [NSString stringWithFormat:@"data=%@", [self encodeString:jsonStr]];
        [request setHTTPBody:[signData dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:[NSString stringWithFormat:@"%d", [signData length]]forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod:@"POST"];
        //[TMBLog log:@"NET REQUEST POST" :[NSString stringWithFormat:@"%@ : %@ : %@",url, jsonStr, signData]];
        [TMBLog log:@"NET REQUEST POST" :[NSString stringWithFormat:@"%@ : %@",url, jsonStr]];
    }
    return request;
}

//DES encode
- (NSData *) encryptDES:(NSString *)plainText key:(NSString *)key
{
    char keyPtr[kCCKeySizeDES+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [plainData length];
    size_t bufferSize = dataLength + kCCBlockSizeDES;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding,
                                          keyPtr,
                                          kCCKeySizeDES,
                                          NULL,
                                          [plainData bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        NSData *desData = [[[NSData alloc] initWithBytesNoCopy:buffer length:numBytesEncrypted freeWhenDone:YES] autorelease];
        return desData;
    }
    return nil;
}

//DES decode
- (NSString *) decryptDES:(NSData *)desData key:(NSString *)key
{
    //Byte iv[] = {1, 2, 3, 4, 5, 6, 7, 8};
    char keyPtr[kCCKeySizeDES+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [desData length];
    size_t bufferSize = dataLength + kCCBlockSizeDES;
    void *buffer = malloc(bufferSize);

    size_t numBytesDecrypted = 0;  
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,   
                                          kCCAlgorithmDES,   
                                          kCCOptionPKCS7Padding,   
                                          keyPtr,
                                          kCCKeySizeDES,   
                                          NULL,   
                                          [desData bytes],   
                                          dataLength,
                                          buffer,   
                                          bufferSize,   
                                          &numBytesDecrypted);  
    if (cryptStatus == kCCSuccess) {
        NSString* plainText = [[[NSString alloc] initWithBytesNoCopy:buffer length:numBytesDecrypted encoding:NSUTF8StringEncoding freeWhenDone:YES] autorelease];
        return plainText; 
    }  
    return nil;  
}

//encode data
-(NSString *)encodeString: (NSString *)data
{
    //des
    NSData *desData = [self encryptDES:data key:secretKey];
    //base64
    NSString *base64Str = [TMBGTMBase64 stringByWebSafeEncodingData:desData padded:YES];
    return base64Str;
}

//decode data
-(NSString *)decodeString: (NSString *)base64Str
{
    //base64
    //des
    NSData *desData = [TMBGTMBase64 webSafeDecodeString:base64Str];
    NSString *data = [self decryptDES:desData key:secretKey];
    return data;
}




//decode json
+(id) decodeServerJsonResult: (NSString *)jsonStr
{
    if(!jsonStr || [jsonStr length]<1){
        return nil;
    }
    id jsonObj = [jsonStr objectFromJSONString];
    if(!jsonObj || ![jsonObj isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    NSDictionary *json = jsonObj;
    if([[json valueForKey:@"ret"]isEqual:@"1"] || [[json valueForKey:@"ret"] isEqual:[NSNumber numberWithInt:1]]){
        return [json valueForKey:@"data"];
    }else{
        return nil;
    }
}

+(void) setHost: (NSString *)host
{
    _TMB_SERVER_HOST = host;
}

+(NSString *) host
{
    return _TMB_SERVER_HOST;
}

+(NSString *) fullUrl: (NSString *)url
{
    if (_TMB_SANDBOX_URL_FLAG && [url hasPrefix:@"%@/"]) {
        NSMutableString *demoUrl = [NSMutableString stringWithString:url];
        [demoUrl insertString:@"sandbox/" atIndex:3];
        return demoUrl;
    }
    return url;
}

+(void) setSandboxUrlFlag: (BOOL)flag
{
    _TMB_SANDBOX_URL_FLAG = flag;
}

@end
