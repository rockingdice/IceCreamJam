//
//  SyncOperation.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/21/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import "SyncOperation.h"


@implementation SyncOperation

@synthesize delegate;
@synthesize queueManager;
@synthesize failed;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate
{
    self = [super init];
    
    if (self)
    {
        queueManager = manager;
        delegate = theDelegate;
		failed = NO;
		retainTimes = 0;
    }
    
    return self;
}


- (void)start
{
	@synchronized(self)
	{
		[self willChangeValueForKey:@"isExecuting"];
		executing = YES;
		[self didChangeValueForKey:@"isExecuting"];
	}
	
	// Store the time this operation starts
	startTime = [[NSDate date] retain];
}

- (void)stop
{
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];
    
	executing = NO;
	finished = YES;
	
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isConcurrent
{
	return YES;
}

- (BOOL)isExecuting
{
	return executing;
}

- (BOOL)isFinished
{
	return finished;
}

- (void)dealloc
{
	[startTime release]; startTime = nil;
	[super dealloc];
}

-(BOOL) isBackgroundModeEnabled
{
	BOOL enabled = NO;
	NSString *reqSysVer = @"4.0";
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
		enabled = TRUE;
	return enabled;
}

@end
