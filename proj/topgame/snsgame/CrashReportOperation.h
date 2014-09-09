//
//  StatusCheckOperation.h
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SyncOperation.h"
#import "ASIHTTPRequestDelegate.h"
#import "ASIHTTPRequest.h"

@interface CrashReportOperation : SyncOperation<ASIHTTPRequestDelegate>
{
	ASIHTTPRequest *req;
	NSString  *debugInfo;
}

@property(nonatomic,retain) NSString *debugInfo;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate;

- (void)beginLoad;
- (void)loadDone;
- (void)loadCancel;

@end