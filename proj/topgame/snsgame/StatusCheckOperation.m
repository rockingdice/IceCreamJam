//
//  StatusCheckOperation.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import <AdSupport/ASIdentifierManager.h>
#import "StatusCheckOperation.h"
#import "SystemUtils.h"
#import "ASIFormDataRequest.h"
#import "StringUtils.h"
#import "SBJson.h"
#import "SnsServerHelper.h"

// #import "CJSONDeserializer.h"

@implementation StatusCheckOperation

@synthesize profileID;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate
{
    self = [super initWithManager:manager andDelegate:theDelegate];
    
    if (self)
    {
        profileID = nil; respHeaders = nil;
    }
    
    return self;
}

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate andProfileID:(NSString*)theProfileID
{
    self = [super initWithManager:manager andDelegate:theDelegate];
    
    if (self)
    {
        profileID = theProfileID;
    }
    
    return self;
}

- (void) dealloc
{
    if(respHeaders) {
        [respHeaders release];
        respHeaders = nil;
    }
    [super dealloc];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector: @selector(statusCheckDone)
                                                 name: kStatusCheckDoneNotification
                                               object: nil];
    // Register to receive the message that the user canceled the status message
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(statusCheckCancel) 
                                                 name:kStatusMessageCanceledNotification 
                                               object:nil];
	
    if([SystemUtils getGameDataDelegate] && ![[SystemUtils getGameDataDelegate] isCurrentPlayer])
    {
        [self statusCheckDone];
        return;
    }
    
	NSString *country = [SystemUtils getCountryCode];
	//NSLog(@"country=%@",country);
	int timestamp = [SystemUtils getCurrentDeviceTime];
	NSString *time = [NSString stringWithFormat:@"%i",timestamp];
	// NSString *udid = [SystemUtils getDeviceID];
	// udid = @"testid";
	NSString *clientVer = [SystemUtils getClientVersion];
	NSString *userID = [SystemUtils getCurrentUID];
	NSString *saveID = [NSString stringWithFormat:@"%i", [SystemUtils getSaveID]];
	// NSString *noticeVer = [NSString stringWithFormat:@"%i", [SystemUtils getNoticeVersion]];
    NSString *hmac = [SystemUtils getMACAddress];
    NSString *subID = [SystemUtils getSystemInfo:@"kSubAppID"];
    if(!subID) subID = @"0";

    NSString *ad_id = [SystemUtils getIDFA];
    NSString *idfv  = [SystemUtils getIDFA];
    NSString *udid = @"";
#ifdef DEBUG
    //ad_id = @"00000000-0000-0000-0000-000000000002";
    //idfv  = @"00000000-0000-0000-0000-000000000002";
    // idfv = @"00000000-0000-0000-0000-000000000001";
#endif
    
	
    NSString *isTestUser = @"0";
#ifdef DEBUG
	isTestUser = @"1";
    // idfv = @"C3C36B1A-FACC-43A9-B726-784AC47A6FBC";
    // hmac = @"";
#endif
	NSString *secret = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", hmac, time, userID, clientVer, kStatusCheckSecret];
	// sig＝md5(UDID+"-"+time+"-"+userID+"-"+clientVer+"-"+key)
	NSString *sig = [StringUtils stringByHashingStringWithMD5:secret];

    NSString *hackTime = [SystemUtils getGlobalSetting:kHackTime];
    if(!hackTime) hackTime = @"0";
    
    NSDictionary *kochavaInfo = [SystemUtils getNSDefaultObject:@"kKochavaCampaignAttribution"];
    
    int requireNetwork = [[SystemUtils getSystemInfo:@"kForceNetwork"] intValue];
    
	// loading system status
	NSString *api = [SystemUtils getServerRoot];
	api = [api stringByAppendingString:@"getStatus3.php"];
	SNSLog(@"api:%@", api);
	NSURL *url = [NSURL URLWithString:api];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    
	[request setRequestMethod:@"POST"];
	[request addPostValue:country forKey:@"country"];
	[request addPostValue:[SystemUtils getCurrentLanguage] forKey:@"lang"];
	[request addPostValue:[SystemUtils getDeviceToken] forKey:@"tokenID"];
	[request addPostValue:udid forKey:@"udid"];
	[request addPostValue:ad_id forKey:@"adid"];
	[request addPostValue:idfv forKey:@"idfv"];
	[request addPostValue:hmac forKey:@"hmac"];
	[request addPostValue:time forKey:@"time"];
	[request addPostValue:hackTime forKey:@"htime"];
	[request addPostValue:[SystemUtils getDeviceModel] forKey:@"devModel"];
	[request addPostValue:@"" forKey:@"email"];
	[request addPostValue:isTestUser forKey:@"isTestUser"];
	[request addPostValue:userID forKey:@"userID"];
	[request addPostValue:saveID forKey:@"saveID"];
	[request addPostValue:clientVer forKey:@"clientVer"];
	[request addPostValue:subID forKey:@"subID"];
	[request addPostValue:@"0" forKey:@"osType"];
	[request addPostValue:[SystemUtils getiOSVersion] forKey:@"osVer"];
	[request addPostValue:sig forKey:@"sig"];
    [request addPostValue:[NSBundle mainBundle].bundleIdentifier forKey:@"package"];
    if(kochavaInfo!=nil) {
        [request addPostValue:[StringUtils convertObjectToJSONString:kochavaInfo] forKey:@"kochavaInfo"];
    }
	[request buildPostBody];
	
	[request setDelegate:self];
    if(requireNetwork==1)
        [request setTimeOutSeconds:60.0f];
    else
        [request setTimeOutSeconds:15.0f];
	[request startAsynchronous];
#ifdef DEBUG
	NSLog(@"method: %@ post data: %s",[request requestMethod], [request postBody].bytes);
#endif
	req = [request retain];
	[self retain]; retainTimes = 2;
	
    if(requireNetwork==1)
        [self performSelector:@selector(statusCheckCancel) withObject:nil afterDelay:120.0f];
    else
        [self performSelector:@selector(statusCheckCancel) withObject:nil afterDelay:20.0f];
}

- (void)releaseRequest
{
	if(retainTimes<=0) return;
	@synchronized(self) {
		retainTimes--;
		if(retainTimes==0) {
			[req release]; req = nil;
            if(respHeaders) {
                [respHeaders release];
                respHeaders = nil;
            }
			[self release];
		}
	}
}

- (void)statusCheckDone
{
	// NSLog(@"======这里走statusCheckDone函数======");
	[self releaseRequest];
	if(finished) return;
    [[SnsServerHelper helper] setNetworkStatus:YES];
    // [[NSNotificationCenter defaultCenter] removeObserver:self name:kStatusCheckDoneNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if([queueManager isKindOfClass:[SyncQueue class]])
        [queueManager operationDone:self];
}

- (void)statusCheckCancel
{
	[self releaseRequest];
	if(finished) return;
    
    [[SnsServerHelper helper] setNetworkStatus:NO];
    
	// failed = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if([queueManager isKindOfClass:[SyncQueue class]])
        [queueManager operationDone:self];
}

#pragma mark ASIHTTPRequestDelegate

- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders
{
    if(respHeaders) [respHeaders release];
    respHeaders = [responseHeaders retain];
    SNSLog(@"got headers: %@", respHeaders);
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	SNSLog(@"status code:%i", request.responseStatusCode);
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
    
    // validate response
    NSString *hash = [respHeaders objectForKey:@"Sg-Hash-Info"];
    NSString *hash2 = [StringUtils stringByHashingStringWithMD5:[jsonString stringByAppendingString:@"-sdfewerpir"]];
    
	if(!hash || ![hash isEqualToString:hash2]) {
		SNSLog(@"invalid digest of response:%@", jsonString);
		[self statusCheckCancel];
		return;
	}
    // SNSLog(@"response digest is valid");
    
	NSDictionary *dictionary = [StringUtils convertJSONStringToObject:jsonString];
	if(!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
		SNSLog(@"deserialize error:%@\ncontent:%s", error, jsonData.bytes);
		[self statusCheckCancel];
		return;
	}
    if(![dictionary objectForKey:@"userID"] || [[dictionary objectForKey:@"userID"] intValue]==0) {
		SNSLog(@"invalid response: %@", jsonString);
		[self statusCheckCancel];
		return;
    }
	//[self statusCheckCancel]; return;
	SNSLog(@"getStatus reply: %@", dictionary );
    NSString *oldUserID = [SystemUtils getCurrentUID];
    BOOL isNewUser = NO;
    if(oldUserID==nil || [oldUserID isEqualToString:@"0"]) isNewUser = YES;
	[SystemUtils setGlobalSettingByDictionary:dictionary];
	
	// 检查本地进度，如果没有，就把ID为0的存档重命名为初始化进度
	NSString *userFile = [SystemUtils getUserSaveFile];
	NSFileManager *mgr = [NSFileManager defaultManager];
	if(![mgr fileExistsAtPath:userFile])
	{
		NSString *oldUserFile = [SystemUtils getUserSaveFileByUID:@"0"];
		if([mgr fileExistsAtPath:oldUserFile])
		{
			[mgr moveItemAtPath:oldUserFile toPath:userFile error:&error];
			[SystemUtils updateFileDigest:userFile];
		}
	}
	NSDictionary *statInfo = [dictionary objectForKey:@"statInfo"];
    if(statInfo!=nil && [statInfo isKindOfClass:[NSDictionary class]]) {
        [self performSelectorInBackground:@selector(reportToStatLogin:) withObject:statInfo];
    }
    NSNumber * lastExp = [statInfo objectForKey:@"last_exp"];
    if (lastExp!=nil && [lastExp intValue] == 0) {
        [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationRegisterSuccess object:NULL];
    }
	[self statusCheckDone];
    
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	SNSLog(@"- error: %@", error);
    if(error.code == 2 && [error.domain isEqualToString:@"ASIHTTPRequestErrorDomain"])
    {
        int useBackupServer = [[SystemUtils getNSDefaultObject:@"kUseBackupServer"] intValue];
        if(useBackupServer==1) useBackupServer = 0;
        else useBackupServer = 1;
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:useBackupServer] forKey:@"kUseBackupServer"];
    }
	[self statusCheckCancel];
}

#pragma mark -

- (void) reportToStatLogin:(NSDictionary *) statInfo
{
    
	@autoreleasepool {

    NSString *statLink = [SystemUtils getSystemInfo:@"kTopStatLinkLogin"];
    NSString *appID = [SystemUtils getSystemInfo:@"kTopStatAppID"];
    if(statLink==nil || [statLink length]<10 || appID==nil || [appID length]<2) {
        return;
    }
    
    // NSString *isNew = @"0";
    // if([isNewUser boolValue]) isNew = @"1";
    
	NSString *country = [SystemUtils getCountryCode];
	int timestamp = [SystemUtils getCurrentDeviceTime];
	NSString *time = [NSString stringWithFormat:@"%i",timestamp];
	NSString *clientVer = [SystemUtils getClientVersion];
	NSString *userID = [SystemUtils getCurrentUID];
    NSString *hmac = [SystemUtils getMACAddress];
    NSString *subID = [SystemUtils getSystemInfo:@"kSubAppID"];
    if(!subID) subID = @"0";
	
    NSString *ad_id = @"";
    NSString *idfv = @"";
    if([[SystemUtils getiOSVersion] compare:@"6.0"]>=0) {
        if([ASIdentifierManager sharedManager].isAdvertisingTrackingEnabled)
            ad_id = [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
        idfv = [[UIDevice currentDevice].identifierForVendor UUIDString];
        
    }
    
    NSString *isTestUser = @"0";

    
#ifdef DEBUG
	isTestUser = @"1";
#endif
	NSString *secret = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", hmac, time, userID, clientVer, kStatusCheckSecret];
	// sig＝md5(UDID+"-"+time+"-"+userID+"-"+clientVer+"-"+key)
	NSString *sig = [StringUtils stringByHashingStringWithMD5:secret];
    
    NSString *udid = @"";
    //if([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)])
    //    udid = [UIDevice currentDevice].uniqueIdentifier;
    NSDictionary *kochavaInfo = [SystemUtils getNSDefaultObject:@"kKochavaCampaignAttribution"];
    
	NSURL *url = [NSURL URLWithString:statLink];
    
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
	[request addPostValue:appID forKey:@"appID"];
	// [request addPostValue:isNew forKey:@"isNewUser"];
	[request addPostValue:country forKey:@"country"];
	[request addPostValue:[SystemUtils getCurrentLanguage] forKey:@"lang"];
	[request addPostValue:[SystemUtils getDeviceToken] forKey:@"tokenID"];
	[request addPostValue:udid forKey:@"udid"];
	[request addPostValue:ad_id forKey:@"adid"];
	[request addPostValue:idfv forKey:@"idfv"];
	[request addPostValue:hmac forKey:@"hmac"];
	[request addPostValue:time forKey:@"time"];
	[request addPostValue:[SystemUtils getDeviceModel] forKey:@"devModel"];
	[request addPostValue:@"" forKey:@"email"];
	[request addPostValue:isTestUser forKey:@"isTestUser"];
	[request addPostValue:userID forKey:@"userID"];
	[request addPostValue:clientVer forKey:@"clientVer"];
	[request addPostValue:subID forKey:@"subID"];
	[request addPostValue:@"0" forKey:@"osType"];
	[request addPostValue:[SystemUtils getiOSVersion] forKey:@"osVer"];
    [request addPostValue:[NSBundle mainBundle].bundleIdentifier forKey:@"package"];
	[request addPostValue:sig forKey:@"sig"];
    if(kochavaInfo!=nil) {
        [request addPostValue:[StringUtils convertObjectToJSONString:kochavaInfo] forKey:@"kochavaInfo"];
    }
    
    NSArray *keys = [statInfo allKeys];
    for(NSString *k in keys) {
        NSString *val = [NSString stringWithFormat:@"%@",[statInfo objectForKey:k]];
        [request addPostValue:val forKey:k];
    }
    
	[request setTimeOutSeconds:10.0f];
	[request buildPostBody];
#ifdef DEBUG
    
	NSLog(@"%s: url:%@\npost len:%i data: %s", __func__, statLink, [request postBody].length, [request postBody].bytes);
#endif
    [request startSynchronous];
#ifdef DEBUG
    NSLog(@"%s: response: %@",__func__, [request responseString]);
#endif
        
    }

}

@end
