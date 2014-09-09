//
//  TMBJob.m
//  TMBDemo
//
//  Created by 高 峰 on 13-3-7.
//
//

#import "TMBJob.h"

static NSOperationQueue *jobQueue = nil;
static NSOperationQueue *cacheQueue = nil;

@implementation TMBJob

+ (void) addJobQueueWithTarget:(id)target selectot:(SEL)sel object:(id)arg
{
    if (!jobQueue) {
        jobQueue = [[NSOperationQueue alloc] init];
        [jobQueue setMaxConcurrentOperationCount:1];
    }
    NSInvocationOperation *job = [[[NSInvocationOperation alloc] initWithTarget:target selector:sel object:arg] autorelease];
    [jobQueue addOperation:job];
}

+ (void) addCacheQueueWithTarget:(id)target selectot:(SEL)sel object:(id)arg
{
    if (!cacheQueue) {
        cacheQueue = [[NSOperationQueue alloc] init];
        [cacheQueue setMaxConcurrentOperationCount:1];
    }
    NSInvocationOperation *job = [[[NSInvocationOperation alloc] initWithTarget:target selector:sel object:arg] autorelease];
    [cacheQueue addOperation:job];
}

@end
