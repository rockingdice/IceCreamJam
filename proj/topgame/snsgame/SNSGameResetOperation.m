//
//  StatusCheckOperation.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import "SNSGameResetOperation.h"
#import "SystemUtils.h"
#import "ASIFormDataRequest.h"
#import "StringUtils.h"
//#import "NSDictionary_JSONExtensions.h"
#import "SBJson.h"
#import "NSData+Compression.h"
// #import "GameData.h"
#import "SnsStatsHelper.h"


@implementation SNSGameResetOperation


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
    if([SystemUtils isAppAlreadyTerminated] || [[SystemUtils getSystemInfo:@"kDisableUploadSave"] boolValue])
    {
		[self loadDone];
		return;
    }
    if (delegate)
        [delegate statusMessage: [SystemUtils getLocalizedString:@"Reset save data on server"] cancelAfter:1];
	
	NSString  *userID = [SystemUtils getCurrentUID];
    
	if(!userID) {
		[self loadCancel];
		return;
	}
    if(![[SystemUtils getGameDataDelegate] isCurrentPlayer])
    {
        SNSLog(@"not upload friend's data.");
		[self loadCancel];
		return;
    }
    
    NSObject<GameDataDelegate> *gameData = [SystemUtils getGameDataDelegate];
    
    int exp = [gameData getGameResourceOfType:kGameResourceTypeExp];
    int level = [gameData getGameResourceOfType:kGameResourceTypeLevel];
    int leaf = [gameData getGameResourceOfType:kGameResourceTypeLeaf];
    int gold = [gameData getGameResourceOfType:kGameResourceTypeCoin];
    int saveTime = [SystemUtils getCurrentTime];

	// loading remote save
	// action－load或者save，saveInfo－存储进度信息，time－本地设备时间，sessionKey－登录session，sig－签名＝md5(action+"-"+time+"-"+sessionKey+"-"+key)
	NSString *time = [NSString stringWithFormat:@"%i",[SystemUtils getCurrentTime]];
	NSString *sessionKey = [SystemUtils getSessionKey];
    if(!sessionKey) {
        [self loadCancel]; return;
    }
    
	// sid += 2;
	NSString *saveID = [NSString stringWithFormat:@"%i", exp];
	NSString *apiVersion = @"3";
    
	NSString *action = @"resetSaveData";
	NSString *api = [SystemUtils getServerRoot];
	api = [api stringByAppendingFormat:@"resetAccount.php"];
	SNSLog(@"%s api:%@", __FUNCTION__, api);
	NSURL *url = [NSURL URLWithString:api];
	NSString *secret = [NSString stringWithFormat:@"%@-%@-%@-%@", action, time, sessionKey, kStatusCheckSecret];
	// md5(action+"-"+time+"-"+sessionKey+"-"+key)
	NSString *sig = [StringUtils stringByHashingStringWithMD5:secret];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
	[request setPostValue:action forKey:@"action"];
	[request setPostValue:time forKey:@"time"];
	[request setPostValue:saveID forKey:@"saveID"];
	[request setPostValue:@"0" forKey:@"loadOldSave"];
	[request setPostValue:apiVersion forKey:@"sVer"];
	[request setPostValue:sessionKey forKey:@"sessionKey"];
	[request setPostValue:sig forKey:@"sig"];
	// [request setPostValue:[NSString stringWithFormat:@"%i",useZip] forKey:@"useZip"];
	// [request setPostValue:statStr forKey:@"statInfo"];
	[request buildPostBody];
	request.shouldContinueWhenAppEntersBackground = YES;
	[request setDelegate:self];
	req = [request retain];
	[self retain];
	retainTimes = 2;
	[request startAsynchronous];
    
	SNSLog(@"method: %@ post length:%i data: %s",[request requestMethod],[[request postBody] length], [request postBody].bytes);
	
	[self performSelector:@selector(loadCancel) withObject:nil afterDelay:20];
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
    [SystemUtils hideInGameLoadingView];
    [queueManager operationDone:self];
}

- (void)loadCancel
{
	[self releaseRequest];
	if(finished) return;
	failed = YES;
    [SystemUtils hideInGameLoadingView];
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
	// NSString *response = [request responseString];
	NSData *jsonData = [request responseData];
	if(!jsonData || [jsonData length]==0) {
		[self loadCancel];
		return;
	}
	// [request responseData];
	// NSString *jsonString = @"yourJSONHere";
	// NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	// NSError *error = nil;
	NSString *jsonString = [[NSString alloc] initWithBytes:jsonData.bytes length:jsonData.length encoding:NSUTF8StringEncoding];
	[jsonString autorelease];
	SNSLog(@"game reset result: %@", jsonString);
	NSDictionary *dictionary = [jsonString JSONValue]; 
	
	if(!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
		[self loadCancel];
		return;
	}
	
	
	int loadOK = [[dictionary objectForKey:@"success"] intValue];
	if(loadOK != 1) {
		[self loadCancel];
		//int forceLoad = [[dictionary objectForKey:@"forceLoad"] intValue];
		//if(forceLoad==1) exit(0);
		return;
	}
    // clear save file
    NSString *saveFile = [SystemUtils getUserSaveFile];
    [[NSFileManager defaultManager] removeItemAtPath:saveFile error:nil];
    [SystemUtils setGameDataDelegate:nil];
    // set save info
    int exp = 0;
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setInteger:exp forKey:kLastUploadSaveID];
    [def setInteger:[SystemUtils getTodayDate] forKey:@"kLastUploadSaveDate"];
    [def synchronize];
    
	[self loadDone];
    // exit(0);
    [SystemUtils showResetGameDataFinished];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	SNSLog(@"%s - error: %@", __FUNCTION__, error);
	[self loadCancel];
}

#pragma mark -

@end
