//
//  StatusCheckOperation.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import "StatSendOperation.h"
#import "SystemUtils.h"
#import "ASIFormDataRequest.h"
#import "StringUtils.h"
#import "SBJson.h"
#import "InAppStore.h"
#import "SnsServerHelper.h"
#ifdef SNS_ENABLE_GROWMOBILE
#import "GrowMobileSDK.h"
#endif
#ifdef SNS_ENABLE_NANIGANS
#import "NanTracking.h"
#endif

@implementation StatSendOperation


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
	
    [self performSelectorOnMainThread:@selector(beginLoad) withObject:nil waitUntilDone:NO];
}

- (void)beginLoad
{
    if (delegate)
        [delegate statusMessage: [SystemUtils getLocalizedString:@"Checking Game Status"] cancelAfter:1];
	
	NSArray *statInfo = nil; // [SystemUtils getGameStatsLogArray];
	if(!statInfo || [statInfo count]==0) {
		[self loadDone]; return;
	}
	
	NSString *logStr = [statInfo JSONRepresentation];
	
	
	// send stat to server
	// action－load或者save，saveInfo－存储进度信息，time－本地设备时间，sessionKey－登录session，sig－签名＝md5(action+"-"+time+"-"+sessionKey+"-"+key)
	NSString *country = [SystemUtils getOriginalCountryCode];
	int serverID = 1; // foreign server
	if([country isEqualToString:@"CN"]) serverID = 2; // china server
	//NSString *appID = [SystemUtils getSystemInfo:kFlurryCallbackAppID];
	NSString *time  = [NSString stringWithFormat:@"%i",[SystemUtils getCurrentDeviceTime]];
	NSString *sessionKey = [SystemUtils getSessionKey];
	
	int isTestUser = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"kTestUser"] intValue];
	/*
	 uid 玩家ID bigint
	 cVer 客户端版本 int -- 1.1
	 device 设备型号 string, -- iPhone, iPod-2
	 lang 语言 string
	 country 国家 string
     osType 设备类型 int，0－iOS，1－android
	 osVer 设备软件版本 string, -- iOS版本号
	 testUser 是否测试用户 int -- 1.1
	 */
	
	NSDictionary *headInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  // appID, @"gameID",
							  [SystemUtils getCurrentUID], @"uid",
							  [SystemUtils getClientVersion], @"cVer",
							  [SystemUtils getDeviceType], @"device",
							  [SystemUtils getCurrentLanguage], @"lang",
							  country, @"country",
                              @"0",@"osType",
							  [SystemUtils getiOSVersion], @"osVer",
							  // [NSNumber numberWithInt:serverID], @"serverID",
							  [NSString stringWithFormat:@"%i",isTestUser], @"testUser", 
							  nil];
	NSString *headStr = [headInfo JSONRepresentation];
	
	int useZip = 0;
	if(useZip==1) {
		// write to a temp file
		/*
		 NSString *file1 = [[SystemUtils getCacheRootPath] stringByAppendingPathComponent:@"saveInfo.txt"];
		 NSString *file2 = [[SystemUtils getCacheRootPath] stringByAppendingPathComponent:@"saveInfo.zip"];
		 [saveStr writeToFile:path atomically:YES];
		 BOOL res = [ZipArchive CreateZipFile2:file2];
		 if(res) res = [ZipArchive addFileToZip:file1 newname:@"saveInfo"];
		 */
	}
	// NSDictionary *statInfo = [SystemUtils getGlobalSetting:kGameStats];
	// NSString *statStr = [[CJSONSerializer serializer] serializeDictionary:statInfo];
	
	NSString *action = @"save";
	
	// http://toplogs.sinaapp.com/action.php?head={"gameID":1,"serverID":2, ... }&data=[{"logType":"login","subLogtype":"topgame","logData":{XXXX}},{"logType":"login","subLogtype":"topgame","logData":{XXXX}},{"logType":"login","subLogtype":"topgame","logData":{XXXX}}, ... ]
	

	// NSString *server = [SystemUtils getStatServerName];
	NSString *api = [NSString stringWithFormat:@"http://%@/api/gameStats.php", [SystemUtils getServerName]];
	// NSLog(@"%s api:%@", __FUNCTION__, api);
	NSURL *url = [NSURL URLWithString:api];
	NSString *secret = [NSString stringWithFormat:@"%@-%@-%@-%@", action, time, sessionKey, kStatusCheckSecret];
	// md5(action+"-"+time+"-"+sessionKey+"-"+key)
	NSString *sig = [StringUtils stringByHashingStringWithMD5:secret];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
	[request setPostValue:time forKey:@"time"];
	[request setPostValue:sessionKey forKey:@"sessionKey"];
	[request setPostValue:sig forKey:@"sig"];
	[request setPostValue:headStr forKey:@"head"];
	[request setPostValue:logStr  forKey:@"data"];
	// [request setPostValue:[NSString stringWithFormat:@"%i",useZip] forKey:@"useZip"];
	// [request setPostValue:statStr forKey:@"statInfo"];
	[request buildPostBody];
	request.shouldContinueWhenAppEntersBackground = YES;
	[request setDelegate:self];
	req = [request retain];
	[self retain];
	retainTimes = 2;
	
	if([self isBackgroundModeEnabled]) [request startAsynchronous];
	else [request startSynchronous];
	
	SNSLog(@"url: %@ method: %@ post length:%i data: %s", api, [request requestMethod],[[request postBody] length], [request postBody].bytes);
	
	[self performSelector:@selector(loadCancel) withObject:nil afterDelay:20];
	
}


- (void)releaseRequest
{
	if(retainTimes<=0) return;
	@synchronized(self) {
		retainTimes--;
		if(retainTimes==0) {
			[self release];
			[req release]; req = nil;
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
	SNSLog(@"resp:%@", [request responseString]);
	
	[SystemUtils resetGameStats];
	
	[self loadDone];
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
#ifdef DEBUG
	NSError *error = [request error];
	NSLog(@"%s - error: %@", __FUNCTION__, error);
#endif
	[self loadCancel];
}

#pragma mark -

@end


@implementation PaymentSendOperation

@synthesize  paymentInfo;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate
{
    self = [super initWithManager:manager andDelegate:theDelegate];
    
    if (self)
    {
        respHeaders = nil; paymentInfo = nil;
    }
    
    return self;
}

- (void)start
{
	[super start];
	
    [self performSelectorOnMainThread:@selector(beginLoad) withObject:nil waitUntilDone:NO];
}

- (void) dealloc
{
    if(respHeaders) {
        [respHeaders release];
        respHeaders = nil;
    }
    self.paymentInfo = nil;
    [super dealloc];
}

- (void)beginLoad
{
    if (delegate)
        [delegate statusMessage: [SystemUtils getLocalizedString:@"Sending Payment Info"] cancelAfter:1];

    if(!paymentInfo) {
        [self loadCancel]; return;
    }
    NSDictionary *info = paymentInfo;
	NSString *iapID = [info objectForKey:@"ID"];
	NSString *userID = [SystemUtils getCurrentUID];
	int price  = [[info objectForKey:@"price"] intValue];
	NSString *tid = [info objectForKey:@"tid"];
    NSString *ver = [SystemUtils getClientVersion];
    NSString *sandbox = @"0";
    
    NSDictionary *kochavaInfo = [SystemUtils getNSDefaultObject:@"kKochavaCampaignAttribution"];

#ifdef DEBUG
    sandbox = @"1";
#endif
    int level = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel];
    
	NSString *server = [SystemUtils getServerName];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/paySend.php", server];
	// NSString *appOpenEndpoint = [NSString stringWithFormat:@"http://%@/api/paySend.php?userID=%@&iapID=%@&price=%i&tid=%@&country=%@",
	//							 server, userID, iapID, price, tid, [self getCountryCode]];
	// NSLog(@"%s: request %@", __FUNCTION__, appOpenEndpoint);
	NSURL *url = [NSURL URLWithString:urlStr];
    SNSLog(@" url: %@", urlStr);
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod: @"POST"];
    [request addPostValue:userID  forKey:@"userID"];
    [request addPostValue:[NSString stringWithFormat:@"%i",level]  forKey:@"level"];
    [request addPostValue:sandbox forKey:@"debug"];
    [request addPostValue:ver forKey:@"ver"];
    [request addPostValue:iapID   forKey:@"iapID"];
    [request addPostValue:[NSString stringWithFormat:@"%i",price] forKey:@"price"];
    [request addPostValue:tid forKey:@"tid"];
    [request addPostValue:[info objectForKey:@"isRestore"] forKey:@"isRestore"];
    [request addPostValue:[SystemUtils getCountryCode] forKey:@"country"];
    NSString *subID = [SystemUtils getSystemInfo:@"kSubAppID"];
    if(!subID) subID = @"0";
    [request addPostValue:subID forKey:@"subID"];
    [request addPostValue:[info objectForKey:@"receiptData"] forKey:@"receiptData"];
    [request addPostValue:[info objectForKey:@"verifyPostData"] forKey:@"verifyPostData"];
    
    if(kochavaInfo!=nil) {
        [request addPostValue:[StringUtils convertObjectToJSONString:kochavaInfo] forKey:@"kochavaInfo"];
    }
    
	[request setTimeOutSeconds:30.0f];
	[request buildPostBody];
	// NSLog(@"method: %@ post data: %s",[request requestMethod], [request postBody].bytes);
    
	request.shouldContinueWhenAppEntersBackground = YES;
	[request setDelegate:self];
	req = [request retain];
	[self retain];
	retainTimes = 1;
	
	[request startAsynchronous];
	
}


- (void)releaseRequest
{
	if(retainTimes<=0) return;
	@synchronized(self) {
		retainTimes--;
		if(retainTimes==0) {
			[self release];
			[req release]; req = nil;
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
    // 通过向苹果服务器请求验证
    [[InAppStore store] verifyPendingTransaction];
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
	SNSLog(@"%s status code:%i",__FUNCTION__, request.responseStatusCode);
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		[self loadCancel];
		return;
	}
    NSData *jsonData = [request responseData];
	if(!jsonData || [jsonData length]==0) {
		SNSLog(@"Empty response");
		[self loadCancel];
		return;
	}
    
	NSString *jsonString = [[NSString alloc] initWithBytes:jsonData.bytes length:jsonData.length encoding:NSUTF8StringEncoding];
	
    [jsonString autorelease];
    SNSLog(@"resp:%@", jsonString);
    
    // validate response
    NSString *hash = [respHeaders objectForKey:@"Sg-Hash-Info"];
    NSString *hash2 = [StringUtils stringByHashingStringWithMD5:[jsonString stringByAppendingString:@"-2dfer3t45wr"]];
    
	if(!hash || ![hash isEqualToString:hash2]) {
		SNSLog(@"invalid digest of response");
		[self loadCancel];
		return;
	}
	
    // remove pending transaction
    [[InAppStore store] removeSavedPendingTransaction:[paymentInfo objectForKey:@"tid"]];
    
    NSDictionary *info = [StringUtils convertJSONStringToObject:jsonString];
    int success = 0;
    if(info && [info isKindOfClass:[NSDictionary class]])
        success = [[info objectForKey:@"success"] intValue];
    if(success == 1) {
        // verify ok
        [[InAppStore store] acceptPendingTransactionResponse:info];
        int isSandBox = [[info objectForKey:@"isSandbox"] intValue];
        if(isSandBox==0) {
            [self performSelectorInBackground:@selector(reportToStatPayment) withObject:nil];
        }
        NSString *price = [NSString stringWithFormat:@"%@", [paymentInfo objectForKey:@"price"]];
#ifdef SNS_ENABLE_KOCHAVA
        /*
        NSString *iapID = [paymentInfo objectForKey:@"ID"];
        NSArray *arr = [iapID componentsSeparatedByString:@"."];
        iapID = [arr objectAtIndex:[arr count]-1];
        for(int i=0;i<[iapID length];i++) {
            unichar ch = [iapID characterAtIndex:i];
            if(ch>='0' && ch<='9') {
                iapID = [iapID substringToIndex:i];
                break;
            }
        }
        // iapID = [NSString stringWithFormat:@"BuyIAP%@",iapID];
        */
        if(isSandBox==0) {
            NSString *iapID = @"BuyIAP";
            iapID = [NSString stringWithFormat:@"test%@",iapID];
        
            if([SnsServerHelper helper].kochavaTracker!=nil) {
                [[SnsServerHelper helper].kochavaTracker trackEvent:iapID :price];
                SNSLog(@"tracking payments in kochava: iapID:%@ price:%@", iapID, price);
            }
        }
#endif
#ifdef SNS_ENABLE_NANIGANS
        if(isSandBox==0) {
            NSString *iapID2 = @"BuyIAP";
            iapID2 = [NSString stringWithFormat:@"test%@",iapID2];
            [NanTracking trackPurchaseEvent:price itemID:iapID2];
        }
#endif
        
#if 0
        NSDictionary *info2 = [NSDictionary dictionaryWithObjectsAndKeys:info, @"resp", paymentInfo, @"request", nil];
        [SystemUtils showInvalidTransactionAlert:info2];
#endif
    }
    else if(success == -2) {
        // iap hacker
        [SystemUtils setGlobalSetting:[NSNumber numberWithInt:100] forKey:@"hackTime"];
        // No need to block failed user
        // [SystemUtils setGlobalSetting:@"1" forKey:@"isBlockedUser"];
        // [SystemUtils showBlockedAlert];
        [[InAppStore store] transactionFinished:nil];
        if([[info objectForKey:@"status"] intValue]==21002) {
            NSDictionary *info2 = [NSDictionary dictionaryWithObjectsAndKeys:info, @"resp", paymentInfo, @"request", nil];
            // show failed hint
            [SystemUtils showInvalidTransactionAlert:info2];
        }
    }
    else {
        [[InAppStore store] verifyPendingTransaction];
    }
    
	[self loadDone];
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
#ifdef DEBUG
	NSError *error = [request error];
	NSLog(@"%s - error: %@", __FUNCTION__, error);
#endif
	[self loadCancel];
}



- (void) reportToStatPayment
{
    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSDictionary *info = paymentInfo;
	NSString *iapID = [info objectForKey:@"ID"];
	NSString *userID = [SystemUtils getCurrentUID];
	int price  = [[info objectForKey:@"price"] intValue];
	NSString *tid = [info objectForKey:@"tid"];
    NSString *ver = [SystemUtils getClientVersion];
    NSString *sandbox = @"0";
    
#ifdef DEBUG
    sandbox = @"1";
#endif
    
#ifdef SNS_ENABLE_GROWMOBILE
    if([SystemUtils isGrowMobileEnabled]) {
        float pricef = price; pricef = pricef/100;
        NSString *priceStr = [NSString stringWithFormat:@"%.2f",pricef];
        [GrowMobileSDK reportInAppPurchaseWithCurrency:@"USD" andAmount:priceStr];
        SNSLog(@"report iap to growMobile:%@", priceStr);
    }
#endif
    
    NSString *statLink = [SystemUtils getSystemInfo:@"kTopStatLinkPayment"];
    NSString *appID = [SystemUtils getSystemInfo:@"kTopStatAppID"];
    if(statLink==nil || [statLink length]<10 || appID==nil || [appID length]<2) {
        [pool release];
        return;
    }
    
    NSDictionary *kochavaInfo = [SystemUtils getNSDefaultObject:@"kKochavaCampaignAttribution"];
    
    int level = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel];
	NSURL *url = [NSURL URLWithString:statLink];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod: @"POST"];
    [request addPostValue:appID  forKey:@"appID"];
    [request addPostValue:userID  forKey:@"userID"];
    [request addPostValue:[NSString stringWithFormat:@"%i",level]  forKey:@"level"];
    [request addPostValue:sandbox forKey:@"debug"];
    [request addPostValue:ver forKey:@"ver"];
    [request addPostValue:iapID   forKey:@"iapID"];
    [request addPostValue:[NSString stringWithFormat:@"%i",price] forKey:@"price"];
    [request addPostValue:tid forKey:@"tid"];
    [request addPostValue:[SystemUtils getCountryCode] forKey:@"country"];
    NSString *subID = [SystemUtils getSystemInfo:@"kSubAppID"];
    if(!subID) subID = @"0";
    [request addPostValue:subID forKey:@"subID"];
    
    if(kochavaInfo!=nil) {
        [request addPostValue:[StringUtils convertObjectToJSONString:kochavaInfo] forKey:@"kochavaInfo"];
    }
    
    // [request addPostValue:[info objectForKey:@"receiptData"] forKey:@"receiptData"];
    // [request addPostValue:[info objectForKey:@"verifyPostData"] forKey:@"verifyPostData"];
	[request setTimeOutSeconds:30.0f];
	[request buildPostBody];
	// NSLog(@"method: %@ post data: %s",[request requestMethod], [request postBody].bytes);
    
#ifdef DEBUG
	NSLog(@"%s: url:%@\npost len:%i data: %s", __func__, statLink, [request postBody].length, [request postBody].bytes);
#endif
    [request startSynchronous];
#ifdef DEBUG
    NSLog(@"%s: response: %@",__func__, [request responseString]);
#endif
	[pool release];
}

#pragma mark -

@end

@implementation NoticeReportOperation

@synthesize  noticeID, actionType;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate
{
    self = [super initWithManager:manager andDelegate:theDelegate];
    
    if (self)
    {
        // respHeaders = nil; paymentInfo = nil;
    }
    
    return self;
}

- (void)start
{
	[super start];
	
    [self performSelectorOnMainThread:@selector(beginLoad) withObject:nil waitUntilDone:NO];
}

- (void) dealloc
{
    /*
    if(respHeaders) {
        [respHeaders release];
        respHeaders = nil;
    }
     */
    [super dealloc];
}

- (void)beginLoad
{
    if (delegate)
        [delegate statusMessage: [SystemUtils getLocalizedString:@"Sending Notice Report"] cancelAfter:1];
    
    if(noticeID==0) {
        [self loadCancel]; return;
    }
	NSString *userID = [SystemUtils getCurrentUID];
    // NSString *udid = [UIDevice currentDevice].uniqueIdentifier;
    NSString *udid = @"";
    NSString *hmac = [SystemUtils getMACAddress];
    
	NSString *server = [SystemUtils getServerName];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/noticeReport.php", server];
	NSURL *url = [NSURL URLWithString:urlStr];
    SNSLog(@" url: %@", urlStr);
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod: @"POST"];
    [request addPostValue:[NSString stringWithFormat:@"%i",noticeID] forKey:@"noticeID"];
    [request addPostValue:[NSString stringWithFormat:@"%i",actionType] forKey:@"actionType"];
    [request addPostValue:userID forKey:@"userID"];
    [request addPostValue:udid forKey:@"udid"];
    [request addPostValue:hmac forKey:@"hmac"];
    [request addPostValue:[SystemUtils getCountryCode] forKey:@"country"];
	[request addPostValue:[SystemUtils getDeviceModel] forKey:@"devModel"];
	[request addPostValue:[SystemUtils getClientVersion] forKey:@"clientVer"];
	[request addPostValue:@"0" forKey:@"osType"];
	[request addPostValue:[SystemUtils getiOSVersion] forKey:@"osVer"];
    NSString *subID = [SystemUtils getSystemInfo:@"kSubAppID"];
    if(!subID) subID = @"0";
    [request addPostValue:subID forKey:@"subID"];
	[request setTimeOutSeconds:20.0f];
	[request buildPostBody];
	SNSLog(@"method: %@ post data: %s",[request requestMethod], [request postBody].bytes);
    // noticeID,actionType,userID,udid,hmac,country,devModel,clientVer,osType,osVer
    
	request.shouldContinueWhenAppEntersBackground = YES;
	[request setDelegate:self];
	req = [request retain];
	[self retain];
	retainTimes = 1;
	
	[request startAsynchronous];
	
}


- (void)releaseRequest
{
	if(retainTimes<=0) return;
	@synchronized(self) {
		retainTimes--;
		if(retainTimes==0) {
			[self release];
			[req release]; req = nil;
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

#pragma mark ASIHTTPRequestDelegate

- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders
{
    //if(respHeaders) [respHeaders release];
    //respHeaders = [responseHeaders retain];
    //SNSLog(@"got headers: %@", respHeaders);
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	SNSLog(@"%s status code:%i",__FUNCTION__, request.responseStatusCode);
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		[self loadCancel];
		return;
	}
    
    if(actionType == 2) {
        // remove saved notice id
        int nid = [[SystemUtils getNSDefaultObject:kClickedNoticeID] intValue];
        if(nid == noticeID) 
            [SystemUtils setNSDefaultObject:@"0" forKey:kClickedNoticeID];
    }
	[self loadDone];
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
#ifdef DEBUG 
	NSError *error = [request error];
	NSLog(@"%s - error: %@", __FUNCTION__, error);
#endif
	[self loadCancel];
}

#pragma mark -

@end


@implementation BuyItemReportOperation

@synthesize  itemID, itemType,cost,costType;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate
{
    self = [super initWithManager:manager andDelegate:theDelegate];
    
    if (self)
    {
        // respHeaders = nil; paymentInfo = nil;
        itemID = nil; itemType = 0;
    }
    
    return self;
}

- (void)start
{
	[super start];
	
    [self performSelectorOnMainThread:@selector(beginLoad) withObject:nil waitUntilDone:NO];
}

- (void) dealloc
{
    /*
     if(respHeaders) {
     [respHeaders release];
     respHeaders = nil;
     }
     */
    self.itemID = nil;
    [super dealloc];
}

- (void)beginLoad
{
    if (delegate)
        [delegate statusMessage: [SystemUtils getLocalizedString:@"Sending Notice Report"] cancelAfter:1];
    
    if(!itemID || [itemID length]==0) {
        [self loadCancel]; return;
    }
	NSString *userID = [SystemUtils getCurrentUID];
    NSString *udid = @""; // [UIDevice currentDevice].uniqueIdentifier;
    NSString *hmac = [SystemUtils getMACAddress];
    int level = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel];
    
	NSString *server = [SystemUtils getServerName];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/buyItemReport.php", server];
	NSURL *url = [NSURL URLWithString:urlStr];
    SNSLog(@" url: %@", urlStr);
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod: @"POST"];
    [request addPostValue:itemID forKey:@"itemID"];
    [request addPostValue:[NSString stringWithFormat:@"%i",itemType] forKey:@"itemType"];
    [request addPostValue:userID forKey:@"userID"];
    
    [request addPostValue:[NSString stringWithFormat:@"%i",level]  forKey:@"level"];
    [request addPostValue:[NSString stringWithFormat:@"%i",cost]  forKey:@"cost"];
    [request addPostValue:[NSString stringWithFormat:@"%i",costType]  forKey:@"costType"];
    
    [request addPostValue:udid forKey:@"udid"];
    [request addPostValue:hmac forKey:@"hmac"];
    [request addPostValue:[SystemUtils getCountryCode] forKey:@"country"];
	[request addPostValue:[SystemUtils getDeviceModel] forKey:@"devModel"];
	[request addPostValue:[SystemUtils getClientVersion] forKey:@"clientVer"];
	[request addPostValue:@"0" forKey:@"osType"];
	[request addPostValue:[SystemUtils getiOSVersion] forKey:@"osVer"];
    NSString *subID = [SystemUtils getSystemInfo:@"kSubAppID"];
    if(!subID) subID = @"0";
    [request addPostValue:subID forKey:@"subID"];
	[request setTimeOutSeconds:30.0f];
	[request buildPostBody];
	SNSLog(@"method: %@ post data: %s",[request requestMethod], [request postBody].bytes);
    // itemID,itemType,userID,udid,hmac,country,devModel,clientVer,osType,osVer
    
	request.shouldContinueWhenAppEntersBackground = YES;
	[request setDelegate:self];
	req = [request retain];
	[self retain];
	retainTimes = 1;
	
	[request startAsynchronous];
	
}


- (void)releaseRequest
{
	if(retainTimes<=0) return;
	@synchronized(self) {
		retainTimes--;
		if(retainTimes==0) {
			[self release];
			[req release]; req = nil;
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

#pragma mark ASIHTTPRequestDelegate

- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders
{
    //if(respHeaders) [respHeaders release];
    //respHeaders = [responseHeaders retain];
    //SNSLog(@"got headers: %@", respHeaders);
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	SNSLog(@"%s status code:%i",__FUNCTION__, request.responseStatusCode);
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		[self loadCancel];
		return;
	}
    
	[self loadDone];
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
#ifdef DEBUG 
	NSError *error = [request error];
	NSLog(@"%s - error: %@", __FUNCTION__, error);
#endif
	[self loadCancel];
}

#pragma mark -

@end


