//
//  TMBNetWork.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-6-25.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//
#import "TMBConfig.h"

@interface TMBNetWork : NSObject <NSURLConnectionDataDelegate>
{
    NSInteger timeout;
    NSString *secretKey;
    BOOL withoutSysParam;
}

@property (nonatomic, assign) NSInteger timeout;
@property (nonatomic, assign) NSString *secretKey;
@property BOOL withoutSysParam;

-(id) initWithSecretKey:(NSString *)_secretKey;

//decode tmb json str
+(id) decodeServerJsonResult: (NSString *)jsonStr;

+(NSString *) host;

+(void) setHost: (NSString *)host;

+(NSString *) fullUrl: (NSString *)url;

+(void) setSandboxUrlFlag: (BOOL)flag;

//sync net request
-(NSData *) sendRequestWithURL: (NSString *)url Data: (NSDictionary *)postData;

//async net request
-(BOOL) sendAsyncRequestWithURL: (NSString *)url Data: (NSDictionary *)postData ResponseObj: (id)respons Method: (SEL)method;

@end
