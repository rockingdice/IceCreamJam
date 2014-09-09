//
//  StatusCheckOperation.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import "LangLoadOperation.h"
#import "SystemUtils.h"
#import "ASIFormDataRequest.h"
#import "StringUtils.h"
#import "SBJson.h"

@implementation LangLoadOperation


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
        [delegate statusMessage: [SystemUtils getLocalizedString:@"Loading Language File"] cancelAfter:1];
	
	// loading language info
	NSString *lang = [SystemUtils getCurrentLanguage];
	id str = [SystemUtils getGlobalSetting:kLangFileVerKey];
	int remoteVer = 0; 
	if([str isKindOfClass:[NSString class]] || [str isKindOfClass:[NSNumber class]]) remoteVer = [str intValue];
	NSString *key = [NSString stringWithFormat:@"%@-%@", kLangFileVerKey, lang];
	int localVer = [[SystemUtils getGlobalSetting:key] intValue];
	SNSLog(@"%s: remoteVer:%i localVer:%i", __FUNCTION__, remoteVer, localVer);
    // check language file
//#ifndef DEBUG
	if(remoteVer == localVer && localVer>0 && [SystemUtils isLanguageFileExist]) {
		[self loadDone]; return;
	}
    localVer = 0;
//#endif
#ifdef DEBUG
	// localVer = 0;
#endif
	NSString *api = [SystemUtils getServerRoot];
	api = [api stringByAppendingFormat:@"getLangFile.php?lang=%@&langVer=%i", lang, localVer];
	SNSLog(@"%s api:%@", __FUNCTION__, api);
	NSURL *url = [NSURL URLWithString:api];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"GET"];
	[request setDelegate:self];
    if(delegate) {
        [request setTimeOutSeconds:3.0f];
    }
    else {
        [request setTimeOutSeconds:20.0f];
    }
	[request startAsynchronous];
	req = [request retain];
	[self retain];
    if(delegate) {
        retainTimes = 2;
        [self performSelector:@selector(loadCancel) withObject:nil afterDelay:10];
    }
    else {
        // 后台加载
        retainTimes = 1;
    }
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
	// NSLog(@"%s: response %@", __FUNCTION__, [request responseString]);
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
	//NSLog(@"get language response: %@", jsonString);
	NSDictionary *dictionary = [jsonString JSONValue]; 
	if(!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
        SNSLog(@"get invalid language info:%@", jsonString);
		[self loadCancel];
		return;
	}
    if(![dictionary objectForKey:@"langInfo"] || ![dictionary objectForKey:kLangFileVerKey])
    {
        SNSLog(@"get invalid language info:%@", jsonString);
		[self loadCancel];
		return;
    }
	SNSLog(@"get valid language info");
	// update language info
	NSString *lang = [SystemUtils getCurrentLanguage];
	NSString *key = [NSString stringWithFormat:@"%@-%@", kLangFileVerKey, lang];
	NSString *ver = [dictionary objectForKey:kLangFileVerKey];
	[SystemUtils setLanguageInfo:[dictionary objectForKey:@"langInfo"]];
	[SystemUtils setGlobalSetting:ver forKey:key];
	
	[SystemUtils showLangUpdateHint];
	
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
