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

@interface TinyiMailStatusOperation : SyncOperation<ASIHTTPRequestDelegate>
{
	ASIHTTPRequest *req;
    BOOL  isResponseValid;
}


- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate;

- (void)beginStatusCheck;
- (void)statusCheckDone;
- (void)statusCheckCancel;

@end