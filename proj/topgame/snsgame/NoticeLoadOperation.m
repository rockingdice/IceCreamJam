//
//  StatusCheckOperation.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import "NoticeLoadOperation.h"
#import "SystemUtils.h"
#import "ASIFormDataRequest.h"
#import "StringUtils.h"
#import "SBJson.h"
#import "smPopupWindowImageNotice.h"
#import "SNSAlertView.h"
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
#import "SNSPromotionViewController.h"
#endif
@interface NoticeLoadingRequest : ASIFormDataRequest
{
    // NSString *m_itemFileName;
}
@property (nonatomic,retain) NSString *m_itemFileName;

@end

@implementation NoticeLoadingRequest

@synthesize m_itemFileName;

- (void) dealloc
{
    self.m_itemFileName = nil;
    [super dealloc];
}

@end


@implementation NoticeLoadOperation


- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate
{
    self = [super initWithManager:manager andDelegate:theDelegate];
    
    if (self)
    {
		m_loadingFiles = nil; m_retainTimes = 0; m_runningTaskCount = 0;
    }
    
    return self;
}

- (void)start
{
	[super start];
	
    [self performSelectorOnMainThread:@selector(beginLoad) withObject:nil waitUntilDone:NO];
}

- (void)dealloc
{
    if(m_loadingFiles) [m_loadingFiles release];
    [super dealloc];
}

- (void)beginLoad
{
    if (delegate)
        [delegate statusMessage: [SystemUtils getLocalizedString:@"Loading Remote Notice"] cancelAfter:1];
	
    SNSLog(@"start loading notice");
	NSArray *noticeArr = [SystemUtils getGlobalSetting:@"noticeInfo"];
	if(!noticeArr || ![noticeArr isKindOfClass:[NSArray class]]) {
        SNSLog(@"invalid noticeInfo:%@",noticeArr);
        [self loadDone];
        return;
    }
	
	BOOL isiPad = [SystemUtils isiPad];
	BOOL isRetina = [SystemUtils isRetina];
	
	NSString *urlRoot = [NSString stringWithFormat:@"http://%@/item_files/notice/", [SystemUtils getDownloadServerName]];
	
	if(!m_loadingFiles) m_loadingFiles = [[NSMutableDictionary alloc] init];
	
	NSFileManager *mgr = [NSFileManager defaultManager];
	
	for(NSDictionary *notice in noticeArr)
	{
        if(![SystemUtils isNoticeValid:notice]) continue;
        
        SNSLog(@"check notice %@", notice);
        int type = [[notice objectForKey:@"type"] intValue];
		if(type==2) {
			// hasImage = YES; break;
			int noticeID = [[notice objectForKey:@"id"] intValue];
            int ver = [[notice objectForKey:@"picVer"] intValue];
			NSString *filePath = [SystemUtils getNoticeImageFile:noticeID withVer:ver];
			if([mgr fileExistsAtPath:filePath]) {
                SNSLog(@"file exists:%@",filePath);
                continue;
            }
			NSString *fileName = [notice objectForKey:@"picSmall"];
			if(isiPad || isRetina) fileName = [notice objectForKey:@"picBig"];
			
			if(!fileName || [fileName length]<4) continue;
			NSString *url = [urlRoot stringByAppendingFormat:@"%@?v=%i",fileName, ver];
            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:url, @"url", filePath, @"path", nil];
            SNSLog(@"load %@", info);
			// [m_loadingFiles setObject:filePath forKey:url];
            [m_loadingFiles setObject:info forKey:fileName];
		}
		if(type==4 || type==5) {
			// hasImage = YES; break;
			int noticeID = [[notice objectForKey:@"id"] intValue];
            int ver = [[notice objectForKey:@"picVer"] intValue];
            NSString *countryCode = [SystemUtils getNoticeCountryCode:[notice objectForKey:@"country"]];
			NSString *filePath = [SystemUtils getNoticeImageFile:noticeID withVer:ver andCountry:countryCode];
			if([mgr fileExistsAtPath:filePath]) continue;
            NSString *fileExt = [notice objectForKey:@"picExt"];
			NSString *fileName = [NSString stringWithFormat:@"%i-%@.%@", noticeID, countryCode, fileExt]; 
			if(isiPad || isRetina) fileName = [NSString stringWithFormat:@"%i-%@-hd.%@", noticeID, countryCode, fileExt];
			
			if(!fileName || [fileName length]<4) continue;
			NSString *url = [urlRoot stringByAppendingFormat:@"%@?v=%i",fileName, ver];
            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:url, @"url", filePath, @"path", nil];
			// [m_loadingFiles setObject:filePath forKey:fileName];
            [m_loadingFiles setObject:info forKey:fileName];
		}
	}
    if([m_loadingFiles count]==0) {
        [self loadDone];
        return;
    }
	SNSLog(@"loading notice image: %@", m_loadingFiles);
	[self startLoadingImage];
}

- (void) refreshImageNoticeStatus
{
	NSArray *noticeArr = [SystemUtils getGlobalSetting:@"noticeInfo"];
	if(!noticeArr || ![noticeArr isKindOfClass:[NSArray class]]) {
        SNSLog(@"invalid noticeInfo:%@",noticeArr);
        return;
    }
	
	BOOL isiPad = [SystemUtils isiPad];
	BOOL isRetina = [SystemUtils isRetina];
	
	NSString *urlRoot = [NSString stringWithFormat:@"http://%@/item_files/notice/", [SystemUtils getDownloadServerName]];
	
	if(!m_loadingFiles) m_loadingFiles = [[NSMutableDictionary alloc] init];
	
	NSFileManager *mgr = [NSFileManager defaultManager];
	int noticeNum = 0;
	for(NSDictionary *notice in noticeArr)
	{
        if(![SystemUtils isNoticeValid:notice]) continue;
        
        SNSLog(@"check notice %@", notice);
        int type = [[notice objectForKey:@"type"] intValue];
		if(type==4 || type==5) {
			// hasImage = YES; break;
			int noticeID = [[notice objectForKey:@"id"] intValue];
            int ver = [[notice objectForKey:@"picVer"] intValue];
            NSString *countryCode = [SystemUtils getNoticeCountryCode:[notice objectForKey:@"country"]];
			NSString *filePath = [SystemUtils getNoticeImageFile:noticeID withVer:ver andCountry:countryCode];
            if([SystemUtils isRetina]) filePath = [filePath stringByReplacingOccurrencesOfString:@"@2x" withString:@""];
			if([mgr fileExistsAtPath:filePath]) continue;
#ifdef SNS_SHOW_NEW_NOTICE_VIEW
            [SNSPromotionViewController addNotice:notice];
#else
            NSDictionary *noticeInfo = notice;
            NSString *action = [noticeInfo objectForKey:@"action"]; // showPetRoomMarket
            int prizeCoin = [[noticeInfo objectForKey:@"prizeGold"] intValue];
            int prizeLeaf = [[noticeInfo objectForKey:@"prizeLeaf"] intValue];
            int noClose   = [[noticeInfo objectForKey:@"noClose"] intValue];
            NSString *prizeItem = [noticeInfo objectForKey:@"prizeItem"];
            NSString *urlScheme = [noticeInfo objectForKey:@"urlScheme"];
            int pendingPrize = 0;
            if(urlScheme && [urlScheme length]>0) {
                prizeCoin = 0; prizeLeaf = 0; prizeItem = nil;
                pendingPrize = 1;
                [SystemUtils setNSDefaultObject:noticeInfo forKey:[NSString stringWithFormat:@"prizeNotice-%d",noticeID]];
            }
            //开始显示广告窗口
            smPopupWindowImageNotice *swqImageAlert = [[smPopupWindowImageNotice alloc] initWithNibName:@"smPopupWindowImageNotice" bundle:nil];
            swqImageAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:filePath, @"image", action, @"action", [NSNumber numberWithInt:prizeCoin], @"prizeCoin", [NSNumber numberWithInt:prizeLeaf], @"prizeLeaf", [NSNumber numberWithInt:pendingPrize], @"pendingPrize", [NSNumber numberWithInt:noClose], @"noClose", [notice objectForKey:@"id"], @"noticeID", nil];
            [[smPopupWindowQueue createQueue] pushToQueue:swqImageAlert timeOut:3.0f+noticeNum*10];
            [swqImageAlert release];
            noticeNum++;
#endif
            
		}
	}
    
}


- (void)startLoadingImage
{
    if(m_runningTaskCount>0) {
        m_runningTaskCount--;
        if(m_runningTaskCount>0) return;
    }
	if([m_loadingFiles count]==0) {
		[self loadDone];
		return;
	}
	NSArray *keys = [m_loadingFiles allKeys];
	int i=0;
	for(i=0;i<[keys count];i++)
	{
		if(i==2) break;
		NSString *file = [keys objectAtIndex:i];
        NSDictionary *info = [m_loadingFiles objectForKey:file];
        NSString *url = [info objectForKey:@"url"];
		
		NoticeLoadingRequest *request = [NoticeLoadingRequest requestWithURL:[NSURL URLWithString:url]];
        request.m_itemFileName = file;
		[request setTimeOutSeconds:10.0f];
		[request setRequestMethod:@"GET"];
		[request setDelegate:self];
		[request startAsynchronous];
		[request retain];
	}
    m_runningTaskCount = i;
}



- (void)loadDone
{
	if(finished) return;
    
    [self refreshImageNoticeStatus];
    
    [queueManager operationDone:self];
    // [[NSNotificationCenter defaultCenter] postNotificationName:@"snsgame.NoticeLoadFinished" object:nil userInfo:nil];
}

- (void)loadCancel
{
	if(finished) return;
	failed = YES;
    [queueManager operationDone:self];
}

#pragma mark ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
	SNSLog(@"%s status code:%i",__FUNCTION__, request.responseStatusCode);
	
    NoticeLoadingRequest *req = (NoticeLoadingRequest *)request;
    
    NSDictionary *info = [m_loadingFiles objectForKey:req.m_itemFileName];
	NSString *filePath = nil;
    if(info) filePath = [info objectForKey:@"path"];
	if(filePath) {
		[filePath retain];
		[filePath autorelease];
	}
    [m_loadingFiles removeObjectForKey:req.m_itemFileName];
	
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		[request release];
		[self startLoadingImage];
		return;
	}
	// NSString *response = [request responseString];
	NSData *jsonData = [request responseData];
	if(!jsonData || [jsonData length]==0) {
		[request release];
		[self startLoadingImage];
		return;
	}
	
	[jsonData writeToFile:filePath atomically:YES];
    [request release];
	[self startLoadingImage];
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
	// NSError *error = [request error];
	SNSLog(@"%s - error: %@", __FUNCTION__, [request error]);
    NoticeLoadingRequest *req = (NoticeLoadingRequest *)request;
    
    NSDictionary *info = [m_loadingFiles objectForKey:req.m_itemFileName];
	NSString *filePath = nil;
    if(info) filePath = [info objectForKey:@"path"];
	if(filePath) {
		[m_loadingFiles removeObjectForKey:req.m_itemFileName];
	}
    [request release];
	[self startLoadingImage];
}

#pragma mark -

@end
