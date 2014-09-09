//
//  StatusCheckOperation.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import "TinyiMailStatusOperation.h"
#import "SystemUtils.h"
#import "ASIFormDataRequest.h"
#import "StringUtils.h"
#import "SBJson.h"
#import "TinyiMailHelper.h"
#import "NetworkHelper.h"


@implementation TinyiMailStatusOperation

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate
{
    self = [super initWithManager:manager andDelegate:theDelegate];
    
    if (self)
    {
        isResponseValid = NO;
    }
    
    return self;
}


- (void)start
{
	[super start];
	
    [self performSelectorOnMainThread:@selector(beginStatusCheck) withObject:nil waitUntilDone:NO];
}

- (void)beginStatusCheck
{
    if (delegate)
        [delegate statusMessage: [SystemUtils getLocalizedString:@"Checking Game Status"] cancelAfter:1];
    /*
     网卡MAC地址－hmac，
     来自应用－appID，
     用户邮箱－email，
     用户ID－userID（用户的唯一ID，字符串形式的整数，初次访问为0），
     参数签名－sig，
     应用版本－appVer，字符串
     国家-country，2字母，CN，TW
     语言－lang，zh-Hans, en
     设备型号－model，字符串
     操作系统版本号－osVer，字符串
     操作系统类型－osType, 0-iOS, 1-Android
     是否测试帐号 - isTestUser, 0-正常用户，1－测试用户
     时间戳 － time
     */
    NSString *appID = [SystemUtils getSystemInfo:@"kTinyiMailAppID"];
    
    if(!appID || ![NetworkHelper isConnected]) {
        [self statusCheckCancel]; return;
    }
    
    NSString *host = [SystemUtils getSystemInfo:@"kTinyiMailHost"];
    if(host==nil || [host length]<3) {
        [self statusCheckCancel]; return;
    }
    
    NSString *hmac = [SystemUtils getMACAddress];
    NSString *email = [[TinyiMailHelper helper] getTinyiMailObject:@"email"];
    if(!email) email = @"";
    NSString *userID  = [[TinyiMailHelper helper] getTinyiMailObject:@"uid"];
    if(!userID) userID = @"0";
    
    NSString *inviteCode = [[TinyiMailHelper helper] getTinyiMailObject:@"inviteCode"];
    if(!inviteCode) inviteCode = @"0";
    NSString *invitePrizeCount = [[TinyiMailHelper helper] getTinyiMailObject:@"invitePrizeCount"];
    if(!invitePrizeCount) invitePrizeCount = @"0";
    
    NSString *appVer = [SystemUtils getClientVersion];
	NSString *country = [SystemUtils getCountryCode];
    NSString *lang = [SystemUtils getCurrentLanguage];
    NSString *model = [SystemUtils getDeviceModel];
    NSString *osVer = [SystemUtils getiOSVersion];
    
    // 签名验证方式：sig=md5(appID+hmac+email+"dfwe234gdgit8"+time)
    
	int timestamp = [SystemUtils getCurrentDeviceTime];
	NSString *time = [NSString stringWithFormat:@"%i",timestamp];
	NSString *secret = [NSString stringWithFormat:@"%@%@%@%@%@", appID, hmac, email, kTinyiMailSecretKey, time];
	// sig＝md5(UDID+"-"+time+"-"+userID+"-"+clientVer+"-"+key)
	NSString *sig = [StringUtils stringByHashingStringWithMD5:secret];
	NSString *isTestUser = @"0";
#ifdef DEBUG
	isTestUser = @"1";
#endif
	// loading system status
	NSString *api = [NSString stringWithFormat:@"http://%@/api/getStatus.php", [SystemUtils getSystemInfo:@"kTinyiMailHost"]];
	SNSLog(@"%s api:%@", __FUNCTION__, api);
	NSURL *url = [NSURL URLWithString:api];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	
	[request setRequestMethod:@"POST"];
	[request addPostValue:hmac forKey:@"hmac"];
	[request addPostValue:email forKey:@"email"];
	[request addPostValue:appID forKey:@"appID"];
	[request addPostValue:userID forKey:@"userID"];
	[request addPostValue:sig  forKey:@"sig"];
	[request addPostValue:lang forKey:@"lang"];
	[request addPostValue:appVer forKey:@"appVer"];
	[request addPostValue:country forKey:@"country"];
	[request addPostValue:model forKey:@"model"];
	[request addPostValue:osVer forKey:@"osVer"];
	[request addPostValue:@"0" forKey:@"osType"];
	[request addPostValue:time forKey:@"time"];
	[request addPostValue:inviteCode forKey:@"inviteCode"];
	[request addPostValue:invitePrizeCount forKey:@"invitePrizeCount"];
	[request addPostValue:isTestUser forKey:@"isTestUser"];
	[request buildPostBody];
	
	[request setDelegate:self];
	[request setTimeOutSeconds:5.0f];
	[request startAsynchronous];
	SNSLog(@"method: %@ post data: %s",[request requestMethod], [request postBody].bytes);
	req = [request retain];
	[self retain];
	retainTimes = 1;
	// [self performSelector:@selector(statusCheckCancel) withObject:nil afterDelay:10];
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

- (void)statusCheckDone
{
	SNSLog(@"======这里走statusCheckDone函数======");
	[self releaseRequest];
	if(finished) return;
    // [[NSNotificationCenter defaultCenter] removeObserver:self name:kStatusCheckDoneNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTinyiMailCheckStatusDone object:nil userInfo:nil];
    [queueManager operationDone:self];
}

- (void)statusCheckCancel
{
	[self releaseRequest];
	if(finished) return;
	// failed = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTinyiMailCheckStatusDone object:nil userInfo:nil];
    [queueManager operationDone:self];
}

#pragma mark ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
	SNSLog(@"%s status code:%i",__FUNCTION__, request.responseStatusCode);
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		[self statusCheckCancel];
		return;
	}
	// NSString *response = [request responseString];
	NSData *jsonData = [request responseData];
	if(!jsonData || [jsonData length]==0) {
		SNSLog(@"Empty response");
		[self statusCheckCancel];
		return;
	}
	// [request responseData];
	// NSString *jsonString = @"yourJSONHere";
	// NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	NSError *error = nil;
	NSString *jsonString = [[NSString alloc] initWithBytes:jsonData.bytes length:jsonData.length encoding:NSUTF8StringEncoding];
	[jsonString autorelease];
	NSDictionary *dictionary = [jsonString JSONValue]; 
	if(!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
		SNSLog(@"deserialize error:%@\ncontent:%s", error, jsonData.bytes);
		[self statusCheckCancel];
		return;
	}
    // check uid
    if(![dictionary objectForKey:@"userID"]) {
		SNSLog(@"invalid response: %@", jsonString);
		[self statusCheckCancel];
		return;
    }
    NSString *userID = [NSString stringWithFormat:@"%@", [dictionary objectForKey:@"userID"]];
    if([userID isEqualToString:@"0"] || [userID length]==0) 
    {
		SNSLog(@"invalid response: %@", jsonString);
		[self statusCheckCancel];
		return;
    }
    SNSLog(@"resp:%@",dictionary);
    
    isResponseValid = YES;
    [TinyiMailHelper helper].isServerOK = YES;
	//[self statusCheckCancel]; return;
    
    [[TinyiMailHelper helper] updateTinyiMailInfo:dictionary];
	
	[self statusCheckDone];
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	SNSLog(@"%s - error: %@", __FUNCTION__, error);
	[self statusCheckCancel];
}

#pragma mark -

@end
