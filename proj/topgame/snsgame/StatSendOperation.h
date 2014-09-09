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

@interface StatSendOperation : SyncOperation<ASIHTTPRequestDelegate>
{
	ASIHTTPRequest *req;
}


- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate;

- (void)beginLoad;
- (void)loadDone;
- (void)loadCancel;

@end

@interface PaymentSendOperation : SyncOperation<ASIHTTPRequestDelegate>
{
	ASIHTTPRequest *req;
    NSDictionary   *respHeaders;
    NSDictionary   *paymentInfo;
}

@property(nonatomic, retain) NSDictionary * paymentInfo;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate;

- (void)beginLoad;
- (void)loadDone;
- (void)loadCancel;

@end

#define kSNSNoticeActionTypeView    1
#define kSNSNoticeActionTypeClick   2


@interface NoticeReportOperation : SyncOperation<ASIHTTPRequestDelegate>
{
	ASIHTTPRequest *req;
    int   noticeID;
    int   actionType; // 1-view, 2-click
}

@property(nonatomic, assign) int noticeID;
@property(nonatomic, assign) int actionType;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate;

- (void)beginLoad;
- (void)loadDone;
- (void)loadCancel;

@end

@interface BuyItemReportOperation : SyncOperation<ASIHTTPRequestDelegate>
{
	ASIHTTPRequest *req;
    NSString *itemID;
    int   itemType;
}

@property(nonatomic, retain) NSString * itemID;
@property(nonatomic, assign) int itemType;
@property(nonatomic, assign) int cost;
@property(nonatomic, assign) int costType;

- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate;

- (void)beginLoad;
- (void)loadDone;
- (void)loadCancel;

@end

