//
//  StatusCheckOperation.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import "GameLoadOperation.h"
#import "SystemUtils.h"
#import "ASIFormDataRequest.h"
#import "StringUtils.h"
#import "SBJson.h"
#import "NSData+Compression.h"
#import "SNSLogType.h"
#ifdef SNS_HAS_SNS_GAME_HELPER
#import "SnsGameHelper.h"
#endif

@implementation GameLoadOperation


- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate
{
    self = [super initWithManager:manager andDelegate:theDelegate];
    
    if (self)
    {
        loadBackupSaveID = 1;
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
    
    if([SystemUtils isAppAlreadyTerminated] || [[SystemUtils getSystemInfo:@"kDisableUploadSave"] boolValue])
    {
		[self loadDone];
		return;
    }
    
    if(loadBackupSaveID>5) {
		[self loadDone];
		return;
    }
    
    if (delegate)
        [delegate statusMessage: [SystemUtils getLocalizedString:@"Loading Remote Save File"] cancelAfter:1];
	
	// loading remote save
	// action－load或者save，saveInfo－存储进度信息，time－本地设备时间，sessionKey－登录session，sig－签名＝md5(action+"-"+time+"-"+sessionKey+"-"+key)
	int timestamp = [SystemUtils getCurrentDeviceTime];
	NSString *time = [NSString stringWithFormat:@"%i",timestamp];
	NSString *sessionKey = [SystemUtils getSessionKey];
	
	int localSaveID = [SystemUtils getSaveID];
	int loadRemote = [[SystemUtils getGlobalSetting:@"loadSave"] intValue];
	int remoteSaveID = [[SystemUtils getGlobalSetting:@"saveID"] intValue];
	if(remoteSaveID == 0) remoteSaveID = [[SystemUtils getGlobalSetting:@"saveId"] intValue];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:remoteSaveID] forKey:@"kRemoteSaveID"];
	if(loadRemote>0) localSaveID = remoteSaveID;
	NSString *saveID = [NSString stringWithFormat:@"%i", localSaveID];
	
	NSString *action = @"load";
	NSString *api = [SystemUtils getServerRoot];
	api = [api stringByAppendingFormat:@"syncSave2.php"];
	SNSLog(@"%s api:%@", __FUNCTION__, api);
	NSURL *url = [NSURL URLWithString:api];
	NSString *secret = [NSString stringWithFormat:@"%@-%@-%@-%@", action, time, sessionKey, kStatusCheckSecret];
	// md5(action+"-"+time+"-"+sessionKey+"-"+key)
	NSString *sig = [StringUtils stringByHashingStringWithMD5:secret];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
	[request setPostValue:action forKey:@"action"];
	[request setPostValue:saveID forKey:@"saveID"];
	[request setPostValue:time forKey:@"time"];
	[request setPostValue:[NSString stringWithFormat:@"%d",loadBackupSaveID] forKey:@"loadOldSave"];
	[request setPostValue:sessionKey forKey:@"sessionKey"];
	[request setPostValue:@"2" forKey:@"sVer"];
	[request setPostValue:sig forKey:@"sig"];
	[request buildPostBody];
	
	SNSLog(@"method: %@ post data: %s",[request requestMethod], [request postBody].bytes);
	[request setDelegate:self];
    [request setTimeOutSeconds:20.0f];
	[request startAsynchronous];
	req = [request retain];
	[self retain]; retainTimes = 1;
	
	// [self performSelector:@selector(loadCancel) withObject:nil afterDelay:10];
	
	// NSLog(@"asdfadsfadsfds");
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
	SNSLog(@"%s", __func__);
	[self releaseRequest];
	if(finished) return;
    [queueManager operationDone:self];
}

- (void)loadCancel
{
	SNSLog(@"%s", __func__);
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
	// NSString *response = [request responseString];
	NSData *jsonData = [request responseData];
	if(!jsonData || [jsonData length]==0) {
		SNSLog(@"Empty response");
		[self loadCancel];
		return;
	}
	// [request responseData];
	// NSString *jsonString = @"yourJSONHere";
	// NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	NSError *error = nil;
	NSString *jsonString = [[NSString alloc] initWithBytes:jsonData.bytes length:jsonData.length encoding:NSUTF8StringEncoding];
	[jsonString autorelease];
    // SNSLog(@"response: %@", jsonString);
    
	NSDictionary *dictionary = [jsonString JSONValue]; 
	
	if(!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
		SNSLog(@"deserialize error:%@\ncontent:%s", error, jsonData.bytes);
		[self loadCancel];
		return;
	}
    SNSLog(@"response:%@", dictionary);
    
	int loadOK = [[dictionary objectForKey:@"success"] intValue];
    NSString *saveStr = [dictionary objectForKey:@"save"];
    NSString *sig = [dictionary objectForKey:@"userKey"];
	NSNumber *saveID = [dictionary objectForKey:@"saveID"];
    int  apiVer = [[dictionary objectForKey:@"sVer"] intValue];
    if(apiVer>0) {
        if(!sig || !saveStr || ![saveStr isKindOfClass:[NSString class]] || !saveID) {
            SNSLog(@"invalid reply: no sig or saveStr %@", dictionary);
            [self loadCancel];
            return;
        }
        NSString *sig2 = [StringUtils stringByHashingStringWithMD5:[NSString stringWithFormat:@"%@-%@-23ewer32", saveStr, saveID]];
        if(![sig2 isEqualToString:sig]) {
            SNSLog(@"invalid sig of reply: %@", dictionary);
            [self loadCancel];
            return;
        }
        int useZip = [[dictionary objectForKey:@"useZip"] intValue];
        if(useZip==1) {
            NSData *zipData = [[Base64 decode:saveStr] zlibInflate];
            saveStr = [[NSString alloc] initWithBytes:[zipData bytes] length:[zipData length] encoding:NSUTF8StringEncoding];
        }
        
        if(loadOK != 1 || !saveStr) {
            SNSLog(@"invalid saveInfo:%@", saveStr);
            [self loadCancel];
            return;
        }
    }
	
	int remoteSaveID = 0;
	if(saveID) remoteSaveID = [saveID intValue];
	int localSaveID = [SystemUtils getSaveID];
	if(localSaveID != remoteSaveID) {
		// [SystemUtils setSaveID:remoteSaveID];
	}
	// reset loadSave status
	int loadSave = [[SystemUtils getGlobalSetting:@"loadSave"] intValue];
	if(loadSave>0)
	{
		[SystemUtils setGlobalSetting: [NSNumber numberWithInt:0] forKey:@"loadSave"];
	}
	
	// save the progress to local file
	NSFileManager *mgr = [NSFileManager defaultManager];
	// 更新本地存档
	NSString *userFile = [SystemUtils getUserSaveFile];
	NSString *bakFile = [userFile stringByAppendingString:@".new"];
	NSString *saveFileRootKey = [SystemUtils getSystemInfo:kSaveFileRootKey];
    if(apiVer == 2) {
        // 解析存档格式：|SNSUserInfo|len|{json data}|SAVEDATA|len|<savedata>|stats|len|{json data}|todayStats|len|{json data}
        //SNSLog(@"parsing:%@", saveStr);
        NSDictionary *saveInfo = [SystemUtils parseSaveDataFromServer:saveStr];
        SNSLog(@"loaded saveInfo:%@", saveInfo);
        saveStr = [saveInfo objectForKey:@"SAVEDATA"];
        
#ifdef SNS_HAS_SNS_GAME_HELPER
        if(![SnsGameHelper verifyLoadedSaveInfo:saveStr]) {
            // start load again
            loadBackupSaveID++;
            [self releaseRequest];
            [self start];
            return;
        }
#endif
        if(loadBackupSaveID==1) {
            [SystemUtils setGlobalSetting:@"0" forKey:@"kIsRecoveredSaveFile"];
        }
        else {
            [SystemUtils setGlobalSetting:@"1" forKey:@"kIsRecoveredSaveFile"];
            [SystemUtils setGlobalSetting:[SystemUtils getGlobalSetting:@"saveID"] forKey:@"kMinUploadSaveID"];
        }
        [SystemUtils setNSDefaultObject:@"1" forKey:@"loadGameOK"];
        if([saveStr writeToFile:bakFile atomically:YES encoding:NSUTF8StringEncoding error:nil])
        {
            if([mgr fileExistsAtPath:userFile]) {
                [mgr removeItemAtPath:userFile error:&error];
            }
            [mgr moveItemAtPath:bakFile toPath:userFile error:&error];
            // [SystemUtils updateFileDigest:userFile];
            [SystemUtils updateSaveDataHash:saveStr];
        }
        if([saveInfo objectForKey:@"stat2"]) {
            [SystemUtils checkGameStatInLoadData:saveInfo];
        }
    }
    else {
        NSDictionary *saveInfo = nil;
        if([saveStr isKindOfClass:[NSString class]])
            saveInfo = [StringUtils convertJSONStringToObject:saveStr];
        else if([saveStr isKindOfClass:[NSDictionary class]]) {
            saveInfo = [dictionary objectForKey:@"save"];
        }
        NSDictionary *userInfo = nil;
        if(!saveFileRootKey || [saveFileRootKey isEqualToString:@"ROOT"]) 
            userInfo = saveInfo;
        else 
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:saveInfo, saveFileRootKey,nil];
        
        saveStr = [StringUtils convertObjectToJSONString:userInfo];
        
        if([saveStr writeToFile:bakFile atomically:YES encoding:NSUTF8StringEncoding error:nil])
        {
            if([mgr fileExistsAtPath:userFile]) {
                [mgr removeItemAtPath:userFile error:&error];
            }
            [mgr moveItemAtPath:bakFile toPath:userFile error:&error];
            [SystemUtils updateFileDigest:userFile];
        }
        
        NSDictionary *snsUserInfo = [saveInfo objectForKey:@"SNSUserInfo"];
        if(snsUserInfo && [snsUserInfo isKindOfClass:[NSDictionary class]])
        {
            [SystemUtils checkGameStatInLoadData:snsUserInfo];
        }
    }
    [SystemUtils setPlayerDefaultSetting:@"1" forKey:kDownloadItemRequired];
		
	[self loadDone];
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	SNSLog(@"%s - error: %@", __FUNCTION__, error);
	[self loadCancel];
    // [SystemUtils setGlobalSetting:@"0" forKey:@"saveID"];
}

#pragma mark -

@end
