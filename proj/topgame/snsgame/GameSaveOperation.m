//
//  StatusCheckOperation.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import "GameSaveOperation.h"
#import "SystemUtils.h"
#import "ASIFormDataRequest.h"
#import "StringUtils.h"
//#import "NSDictionary_JSONExtensions.h"
#import "SBJson.h"
#import "NSData+Compression.h"
// #import "GameData.h"
#import "SnsStatsHelper.h"

@implementation GameSaveOperation


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
        [delegate statusMessage: [SystemUtils getLocalizedString:@"Sending Save File to Server"] cancelAfter:1];
	
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
    int today = [SystemUtils getTodayDate];
    // NSString *stats = [SystemUtils getGameStatsTotal];
    // NSString *statsToday = [SystemUtils getGameStatsToday];
    NSString *stats = [[[SnsStatsHelper helper] exportToDictionary] JSONRepresentation];
    
    NSString  *apiVersion = @"0";
    
    NSString *saveStr = nil;
    
    if([gameData respondsToSelector:@selector(exportToString)])
    {
        // use new format
        apiVersion = @"3";
        NSString *saveInfo = [gameData exportToString];
        if(!saveInfo || [saveInfo length]<3) {
            SNSLog(@"failed to get gamedata.");
            [self loadCancel];
            return;
        }
        
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:7];
        [userInfo setObject:userID forKey:@"UID"];
        [userInfo setObject:[NSNumber numberWithInt:exp] forKey:@"Exp"];
        [userInfo setObject:[NSNumber numberWithInt:level] forKey:@"Level"];
        [userInfo setObject:[NSNumber numberWithInt:leaf] forKey:@"Leaf"];
        [userInfo setObject:[NSNumber numberWithInt:gold] forKey:@"Gold"];
        [userInfo setObject:[NSNumber numberWithInt:saveTime] forKey:@"SaveTime"];
        [userInfo setValue:[SystemUtils getDeviceInfo] forKey:@"deviceInfo"];
        NSString *userStr = [userInfo JSONRepresentation];
        saveStr = [NSString stringWithFormat:@"|SNSUserInfo|%i|%@|SAVEDATA|%i|%@|stat2|%i|%@",[userStr length], userStr, [saveInfo length], saveInfo, 
                   [stats length], stats];
        [userInfo release];
    }
    else {
        // use old format
        apiVersion = @"1";
        NSDictionary *info = [gameData exportToDictionary];
        if(!info) {
            [self loadCancel];
            return;
        }
        NSMutableDictionary *saveInfo = [[NSMutableDictionary alloc] initWithDictionary:info];
        
        NSMutableDictionary *userInfo = [saveInfo objectForKey:@"SNSUserInfo"];
        if(userInfo) {
            if([userInfo isKindOfClass:[NSMutableDictionary class]])
            {
                // It's ok
                [userInfo retain];
            }
            else if([userInfo isKindOfClass:[NSDictionary class]])
            {
                userInfo = [[NSMutableDictionary alloc] initWithDictionary:userInfo];
            }
            else
                userInfo = nil;
        }
        if(!userInfo) 
            userInfo = [[NSMutableDictionary alloc] initWithCapacity:6];
        
        NSString *saveUID = [userInfo objectForKey:@"UID"];
        if(saveUID && [saveUID isKindOfClass:[NSString class]]) 
        {
            if(![saveUID isEqualToString:userID]) {
                SNSLog(@"This data belongs to #%@, not you #%@", saveUID, userID);
                [self loadCancel];
                return;
            }
        }
        
        [userInfo setObject:userID forKey:@"UID"];
        [userInfo setObject:[NSNumber numberWithInt:exp] forKey:@"Exp"];
        [userInfo setObject:[NSNumber numberWithInt:level] forKey:@"Level"];
        [userInfo setObject:[NSNumber numberWithInt:leaf] forKey:@"Leaf"];
        [userInfo setObject:[NSNumber numberWithInt:gold] forKey:@"Gold"];
        [userInfo setObject:[NSNumber numberWithInt:saveTime] forKey:@"SaveTime"];
        
        [userInfo setValue:stats forKey:@"stats"];
        // [userInfo setValue:[NSNumber numberWithInt:today] forKey:@"today"];
        // [userInfo setValue:statsToday forKey:@"statsToday"];
        
        [userInfo setValue:[SystemUtils getDeviceInfo] forKey:@"deviceInfo"];
        
        [saveInfo setObject:userInfo forKey:@"SNSUserInfo"];
        [userInfo release];
        // set deviceInfo
        
        saveStr = [saveInfo JSONRepresentation];
        if(!saveStr || [saveStr length]==0) {
            SNSLog(@"invalid saveStr: %@", saveInfo);
        }
        [saveInfo release];
        
    }
	
	// loading remote save
	// action－load或者save，saveInfo－存储进度信息，time－本地设备时间，sessionKey－登录session，sig－签名＝md5(action+"-"+time+"-"+sessionKey+"-"+key)
	NSString *time = [NSString stringWithFormat:@"%i",[SystemUtils getCurrentTime]];
	NSString *sessionKey = [SystemUtils getSessionKey];
    if(!sessionKey) {
        [self loadCancel]; return;
    }
    
    [SystemUtils setSaveID:exp];
    int isUsingRecover = [[SystemUtils getGlobalSetting:@"kIsRecoveredSaveFile"] intValue];
    int minSaveID = [[SystemUtils getGlobalSetting:@"kMinUploadSaveID"] intValue];
    if(isUsingRecover==1 && exp<minSaveID) {
        [self loadCancel]; return;
    }
    
	// sid += 2;
	NSString *saveID = [NSString stringWithFormat:@"%i", exp];
	
	// [SystemUtils setSaveID:sid+1];
	// int time = [SystemUtils getCurrentDeviceTime];
	[SystemUtils setPlayerDefaultSetting:time forKey:kLastUploadTimeKey];
	
	
	int useZip = 0;
    if([saveStr length]>2048) useZip = 1;
	if(useZip==1) {
        NSData *data = [[saveStr dataUsingEncoding:NSUTF8StringEncoding] zlibDeflate];
        saveStr = [Base64 encode:data];
	}
	// NSDictionary *statInfo = [SystemUtils getGlobalSetting:kGameStats];
	// NSString *statStr = [[CJSONSerializer serializer] serializeDictionary:statInfo];
	
	NSString *action = @"save";
	NSString *api = [SystemUtils getServerRoot];
	api = [api stringByAppendingFormat:@"syncSave2.php"];
	SNSLog(@"%s api:%@", __FUNCTION__, api);
	NSURL *url = [NSURL URLWithString:api];
	NSString *secret = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", action, time, sessionKey, kStatusCheckSecret, saveStr];
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
	[request setPostValue:saveStr forKey:@"saveInfo"];
    [request addPostValue:[NSBundle mainBundle].bundleIdentifier forKey:@"package"];
	[request setPostValue:[NSString stringWithFormat:@"%i",useZip] forKey:@"useZip"];
	// [request setPostValue:statStr forKey:@"statInfo"];
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
	SNSLog(@"game save result: %@", jsonString);
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
    // set save info
    int exp = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeExp];
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setInteger:exp forKey:kLastUploadSaveID];
    [def setInteger:[SystemUtils getTodayDate] forKey:@"kLastUploadSaveDate"];
    [def synchronize];
    
    int isUsingRecover = [[SystemUtils getGlobalSetting:@"kIsRecoveredSaveFile"] intValue];
    if(isUsingRecover==1) {
        [SystemUtils setGlobalSetting:@"0" forKey:@"kIsRecoveredSaveFile"];
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
