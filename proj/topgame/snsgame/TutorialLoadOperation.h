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

@interface TutorialLoadOperation : SyncOperation<ASIHTTPRequestDelegate>
{
	ASIHTTPRequest *req;
	NSString *fileName;
}

@property (nonatomic,retain) NSString * fileName;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate;

- (void)beginLoad;
- (void)loadDone;
- (void)loadCancel;

@end