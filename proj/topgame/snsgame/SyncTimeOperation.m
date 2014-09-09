//
//  StatusCheckOperation.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import "SyncTimeOperation.h"
#import "SystemUtils.h"
#import "ASIFormDataRequest.h"
#import "StringUtils.h"
#import "NetworkHelper.h"
// #import "CTimerManager.h"
#import "TapjoyHelper.h"
#import "InAppStore.h"
#import "SnsServerHelper.h"


@implementation SyncTimeOperation


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
        [delegate statusMessage: [SystemUtils getLocalizedString:@"Loading Remote Save File"] cancelAfter:1];

    int requireNetwork = [[SystemUtils getSystemInfo:@"kForceNetwork"] intValue];
    
	NSString *link = [NSString stringWithFormat:@"%@getCurrentTime.php", [SystemUtils getServerRoot]];
	NSURL *url = [NSURL URLWithString:link];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setDelegate:self];
    if(requireNetwork==1)
        [request setTimeOutSeconds:60.0f];
    else
        [request setTimeOutSeconds:10.0f];
	// [request startAsynchronous];
	
	req = [request retain];
	[self retain];
	retainTimes = 2;
	
	if([self isBackgroundModeEnabled]) [request startAsynchronous];
	else [request startSynchronous];
	
	SNSLog(@"%s: url:%@ method: %@", __FUNCTION__, link, [request requestMethod]);
	
    if(requireNetwork==1)
        [self performSelector:@selector(loadCancel) withObject:nil afterDelay:120.0f];
    else
        [self performSelector:@selector(loadCancel) withObject:nil afterDelay:10.0f];
	
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
    [[SnsServerHelper helper] setNetworkStatus:YES];
    [queueManager operationDone:self];
}

- (void)loadCancel
{
	[self releaseRequest];
	if(finished) return;
    [[SnsServerHelper helper] setNetworkStatus:NO];
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
	
	[NetworkHelper helper].connectedToInternet = YES;
	int serverTime = [[request responseString] intValue];
	if(serverTime < kMinServerTime) {
		SNSLog(@"invalid time response:%@", [request responseString]);
		[self loadCancel];
		return;
	}
	//serverTime = 0;
 	[SystemUtils setServerTime:serverTime];
    [SystemUtils saveGlobalSetting];
	// [[CTimerManager sharedTimerManager] resetDate];
	// [[CTimerManager sharedTimerManager] setCurrentTime:[SystemUtils getCurrentTime]];
	SNSLog(@"serverTime:%i localTime:%i deviceTIme:%i", serverTime, [SystemUtils getCurrentTime], [SystemUtils getCurrentDeviceTime]);

	[self loadDone];
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	SNSLog(@"%s - error: %@", __FUNCTION__, error);
	[NetworkHelper helper].connectedToInternet = NO;
#ifndef DEBUG
	if([SystemUtils isNetworkRequired])
	{
		[SystemUtils showNetworkRequired];
	}
#endif
	[self loadCancel];
}

#pragma mark -

@end
