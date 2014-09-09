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

@interface NoticeLoadOperation : SyncOperation<ASIHTTPRequestDelegate>
{
	NSMutableDictionary *m_loadingFiles;
    int m_retainTimes;
    int m_runningTaskCount;
}


- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate;

- (void)beginLoad;
- (void)loadDone;
- (void)loadCancel;

- (void)startLoadingImage;

@end