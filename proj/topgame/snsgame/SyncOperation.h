//
//  SyncOperation.h
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/21/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SyncQueue.h"

@interface SyncOperation : NSOperation
{
    BOOL executing;
	BOOL finished;
	BOOL failed;
	NSDate* startTime;
	int  retainTimes;
    
    id<SyncQueueDelegate> delegate;
    
    SyncQueue* queueManager;
}

@property (nonatomic, retain) id<SyncQueueDelegate>delegate;
@property (nonatomic, retain) SyncQueue* queueManager;
@property (nonatomic, assign) BOOL failed;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate;
- (void)stop;
-(BOOL) isBackgroundModeEnabled;

@end
