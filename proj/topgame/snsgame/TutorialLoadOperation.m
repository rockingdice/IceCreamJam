//
//  StatusCheckOperation.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import "TutorialLoadOperation.h"
#import "SystemUtils.h"
#import "ASIFormDataRequest.h"
#import "StringUtils.h"


@implementation TutorialLoadOperation

@synthesize fileName;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate
{
    self = [super initWithManager:manager andDelegate:theDelegate];
    
    if (self)
    {
		fileName = nil;
    }
    
    return self;
}

- (void)dealloc
{
	self.fileName = nil;
	[super dealloc];
}

- (void)start
{
	[super start];
	
    [self performSelectorOnMainThread:@selector(beginLoad) withObject:nil waitUntilDone:NO];
}

- (void)beginLoad
{
    if (delegate)
        [delegate statusMessage: [SystemUtils getLocalizedString:@"Loading Tutorial File"] cancelAfter:1];
	
	int tutorialLoaded = [[SystemUtils getGlobalSetting:kTutorialLoaded] intValue];
	if(tutorialLoaded == 1) {
		[self loadDone]; return;
	}
	
	self.fileName = @"tutorial-ipad.zip";
	
	NSString *remoteURLRoot = [NSString stringWithFormat:@"http://%@/item_files/general", [SystemUtils getDownloadServerName]];
	// NSString *localFileRoot = [SystemUtils getItemImagePath];
	
	NSString *remoteURL = [NSString stringWithFormat:@"%@/%@", remoteURLRoot, fileName];
	// NSString *localFile = [NSString stringWithFormat:@"%@/%@", localFileRoot, fileName];
	NSLog(@"%s:%@", __FUNCTION__, remoteURL);
	NSURL *url = [NSURL URLWithString:remoteURL];
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setRequestMethod:@"GET"];
	[request setDelegate:self];
	[request startAsynchronous];
	req = [request retain];
	[self retain];
	retainTimes = 2;
	
	[self performSelector:@selector(loadCancel) withObject:nil afterDelay:10];
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
	NSLog(@"%s status code:%i",__FUNCTION__, request.responseStatusCode);
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		[self loadCancel];
		return;
	}
	// NSString *response = [request responseString];
	NSData *respData = [request responseData];
	if(!respData || [respData length]==0) {
		[self loadCancel];
		return;
	}
	// [request responseData];
	// NSString *jsonString = @"yourJSONHere";
	// NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	NSString *localFileRoot = [SystemUtils getItemImagePath];
	NSString *localFile = [NSString stringWithFormat:@"%@/%@", localFileRoot, fileName];
	
	BOOL res = [respData writeToFile:localFile atomically:YES];
	if(!res) {
		NSLog(@"fail to write %@", localFile);
		[self loadCancel];
		return;
	}
	res = [SystemUtils unzipFile:localFile toPath:localFileRoot];
	if(!res) {
		NSLog(@"fail to unzip %@", localFile);
		[self loadCancel];
		return;
	}
	
	NSLog(@"%s:load %@ ok", __FUNCTION__, fileName);
	
	[SystemUtils setGlobalSetting:[NSNumber numberWithInt:1] forKey:kTutorialLoaded];
	
	[self loadDone];
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	NSLog(@"%s - error: %@", __FUNCTION__, error);
	[self loadCancel];
}

#pragma mark -

@end
