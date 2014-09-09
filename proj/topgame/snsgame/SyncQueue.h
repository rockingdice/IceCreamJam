//
//  SyncQueue.h
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/21/11.
//  Copyright 2011 playforge. All rights reserved.
//
#import <Foundation/Foundation.h>

@class SyncOperation;

@protocol SyncQueueDelegate
- (void)statusMessage:(NSString*)text cancelAfter:(int)seconds;
- (void)syncFinished;
- (void)syncFailed;
@end

@interface SyncQueue : NSObject
{
    NSOperationQueue *operations;
}

@property (nonatomic, retain) NSOperationQueue *operations;

+ (SyncQueue*)syncQueue;

- (BOOL)addOperation:(SyncOperation*)operation;
- (void)operationDone:(NSOperation*)operation;

@end

