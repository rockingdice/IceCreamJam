//
//  StatusCheckOperation.h
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SyncOperation.h"
#import "ASIHTTPRequest.h"

@interface StatusCheckOperation : SyncOperation<ASIHTTPRequestDelegate>
{
    NSString* profileID;
	ASIHTTPRequest *req;
    NSDictionary *respHeaders;
}

@property (nonatomic, retain) NSString* profileID;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate;
- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate andProfileID:(NSString*)theProfileID;

- (void)beginStatusCheck;
- (void)statusCheckDone;
- (void)statusCheckCancel;

@end