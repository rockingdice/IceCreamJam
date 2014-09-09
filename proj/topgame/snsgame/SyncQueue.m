//
//  SyncQueue.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/21/11.
//  Copyright 2011 playforge. All rights reserved.
//

#import "SyncQueue.h"

#import "SyncOperation.h"

static SyncQueue *_syncQueue = nil;

@implementation SyncQueue

@synthesize	operations;

+ (SyncQueue*)syncQueue
{
    @synchronized(self)
    {
        if (_syncQueue == NULL)
		{
			_syncQueue = [[self alloc] init];
            
		}
    }
	
    return (_syncQueue);
}

+(id)alloc
{	
	@synchronized([SyncQueue class])
	{ 
		NSAssert(_syncQueue == nil, @"Attempted to allocate a second instance of a singleton.");
		_syncQueue = [super alloc];
        
		return _syncQueue;
	}
	
	return nil;
}

-(id) init
{
    self = [super init];
    if(self) {
        NSOperationQueue *ops = [[NSOperationQueue alloc] init];
        self.operations = ops;
        [operations setMaxConcurrentOperationCount:1];
        [ops release];
    }
    return self;
}

-(void)dealloc
{
    self.operations = nil;
    
	[super dealloc];
}

- (BOOL)addOperation:(SyncOperation*)operation
{
    // Loop through the operations already in the queue and
    // check to see if this operation already exists
    for(SyncOperation* op in [operations operations])
    {
        if ([op class] == [operation class])
        {
            // If it is the same operation then there is
            // no need to add it to the queue
            if ([op isSameOperation:operation])
                return NO;
        }
    }
    
    // If we didn't find an identical operation
    // then add this one to the queue
    [operations addOperation:operation];
    
    // Let the caller know it got added
    return YES;
}

- (void)operationDone:(NSOperation*)operation
{
    if ([operation isKindOfClass:[SyncOperation class]])
    {
        SyncOperation* syncOp = (SyncOperation*)operation;
        
        // If this is the last operation with this delegate
        // in the queue then let it know that all operations
        // are finished
        int numOpsLeft = 0;
        
        for(SyncOperation* op in [operations operations])
        {
            if (op.delegate == syncOp.delegate)
                numOpsLeft++;
        }
        
        if (numOpsLeft == 1)
        {
            if (syncOp.delegate) {
				if(syncOp.failed) 
					[syncOp.delegate syncFailed];
				else 
					[syncOp.delegate syncFinished];
			}
        }
        
        // Now that we've handled notifying the
        // delegate, end the operation
        [syncOp stop];
    }
    
    
}

@end
