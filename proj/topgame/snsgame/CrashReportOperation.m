//
//  StatusCheckOperation.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import "CrashReportOperation.h"
#import "SystemUtils.h"
#import "ASIFormDataRequest.h"
#import "StringUtils.h"
// #import "NSDictionary_JSONExtensions.h"
#import "SBJson.h"
// #import "GameData.h"

@implementation CrashReportOperation

@synthesize debugInfo;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate
{
    self = [super initWithManager:manager andDelegate:theDelegate];
    
    if (self)
    {
    }
    
    return self;
}

- (void)start
{
	[super start];
	
    [self beginLoad];
	// [self performSelectorOnMainThread:@selector(beginLoad) withObject:nil waitUntilDone:NO];
}


- (void)beginLoad
{
    if (delegate)
        [delegate statusMessage: [SystemUtils getLocalizedString:@"Sending Crash Report to Server"] cancelAfter:1];
	
	/*
	if(YES) {
		[self loadCancel];
		return;
	}
	 */
	// loading remote save
	// action－load或者save，saveInfo－存储进度信息，time－本地设备时间，sessionKey－登录session，sig－签名＝md5(action+"-"+time+"-"+sessionKey+"-"+key)
	// NSString *time = [NSString stringWithFormat:@"%i",[SystemUtils getCurrentDeviceTime]];
	// NSString *sessionKey = [SystemUtils getSessionKey];
	
	
    // NSDictionary *saveInfo = [NSDictionary dictionaryWithContentsOfFile:[SystemUtils getUserSaveFile]]; // [[SystemUtils getGameDataDelegate] exportToDictionary];
	// NSString *saveStr = [NSString stringWithContentsOfFile:[SystemUtils getUserSaveFile] encoding:NSUTF8StringEncoding error:nil];
    NSString *saveStr = @"none";
    
	NSString *crashLog = debugInfo; // [SystemUtils getCrashLogContent];
#ifdef DEBUG
    SNSLog(@"crashLog:%@",crashLog);
#endif
	NSString *userID = [SystemUtils getCurrentUID];
	NSString *iosVer = [UIDevice currentDevice].systemVersion;
	NSString *country = [SystemUtils getOriginalCountryCode];
	NSString *clientVer = [SystemUtils getClientVersion];
	NSString *macAddr   = [SystemUtils getMACAddress];
    NSString *devModel  = [SystemUtils getDeviceModel];
	
	// NSString *api = [SystemUtils getServerRoot];
	// api = [api stringByAppendingFormat:@"errorReport.php"];
    NSString *api = [NSString stringWithFormat:@"http://%@/api/errorReport.php", [SystemUtils getSystemInfo:kGameServerChina]];
	SNSLog(@"%s api:%@", __FUNCTION__, api);
	NSURL *url = [NSURL URLWithString:api];
	// NSString *secret = [NSString stringWithFormat:@"%@-%@-%@-%@", action, time, sessionKey, kStatusCheckSecret];
	// md5(action+"-"+time+"-"+sessionKey+"-"+key)
	// NSString *sig = [StringUtils stringByHashingStringWithMD5:secret];
	// 输入参数POST：UID－用户ID，iOS－系统版本号，ver－客户端版本号，country－所在国家，debugInfo－调试信息，saveInfo－存档信息
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
	[request setPostValue:userID forKey:@"UID"];
	[request setPostValue:iosVer forKey:@"iOS"];
	[request setPostValue:clientVer forKey:@"ver"];
    [request setPostValue:@"0" forKey:@"osType"]; // 0-iOS, 1-android
	[request setPostValue:devModel forKey:@"model"]; // 设备型号
	[request setPostValue:@"apple" forKey:@"brand"]; // 品牌
	[request setPostValue:country forKey:@"country"];
	[request setPostValue:macAddr forKey:@"hmac"];
	[request setPostValue:crashLog forKey:@"debugInfo"];
	[request setPostValue:saveStr forKey:@"saveInfo"];
	[request buildPostBody];
	request.shouldContinueWhenAppEntersBackground = YES;
	[request setDelegate:self];
	req = [request retain];
	[self retain];
	retainTimes = 2;
	
	if([self isBackgroundModeEnabled]) [request startAsynchronous];
	else [request startSynchronous];
	
	SNSLog(@"method: %@ post length:%i data: %s",[request requestMethod],[[request postBody] length], [request postBody].bytes);
	
	[self performSelector:@selector(loadCancel) withObject:nil afterDelay:20];
	
	// release debugInfo
	self.debugInfo = nil;
	
}


- (void)releaseRequest
{
	if(retainTimes<=0) return;
	@synchronized(self) {
		retainTimes--;
		if(retainTimes==0) {
			[req release]; req = nil;
			[self release];
		}
	}
}

- (void)loadDone
{
	[self releaseRequest];
	if(finished) return;
    [queueManager operationDone:self];
}

- (void)loadCancel
{
	[self releaseRequest];
	if(finished) return;
	failed = YES;
    [queueManager operationDone:self];
}

- (void) showBugFixHint:(NSDictionary *)info
{
    [SystemUtils showCrashBugFixed:info];
}

#pragma mark ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
	SNSLog(@"%s status code:%i",__FUNCTION__, request.responseStatusCode);
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		[self loadCancel];
		return;
	}
	NSString *response = [request responseString];
	SNSLog(@"%s: crash report result: %@", __func__, response);
	
    NSDictionary *info = [response JSONValue];
    if(info && [info isKindOfClass:[NSDictionary class]] && [info objectForKey:@"hint"] && [[info objectForKey:@"fixed"] intValue]==1)
    {
        // show notice to user
        [self performSelectorOnMainThread:@selector(showBugFixHint:) withObject:info waitUntilDone:YES];
    }
    
	[self loadDone];
	
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	SNSLog(@"%s - error: %@", __FUNCTION__, error);
	[self loadCancel];
}

#pragma mark -

@end
