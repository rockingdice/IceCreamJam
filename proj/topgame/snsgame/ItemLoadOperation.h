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

@class ItemLoadOperation;


@interface ItemLoadingQueue : NSObject<ASIHTTPRequestDelegate, ASIProgressDelegate>
{
	ItemLoadOperation *delegate;
	NSMutableDictionary *dictLoadingTask;
    // NSMutableArray *m_LoadingTask;
	int runningTaskCount;
	int successTaskCount;
	int failedTaskCount;
	int totalTaskCount;
    BOOL lazyLoadMode; // 延迟加载模式
    id loadingRequest; // 正在下载的文件
    int loadingPercent;    // 下载的百分比
}

@property (nonatomic, assign) ItemLoadOperation * delegate;
@property (nonatomic, assign) int failedTaskCount;
@property (nonatomic, assign) int successTaskCount;
@property (nonatomic, assign) BOOL lazyLoadMode;

-(void)pushLoadingTask:(NSDictionary *)info;
// -(void)pushLoadingTask:(NSString *)url withLocalPath:(NSString *)lPath;
-(void)startLoading;
-(void)loadFinish:(BOOL)isSuccess withRequest:(ASIHTTPRequest *)req;
-(void)resetTaskCount;
// 下载指定的远程文件，用于下载需要手动触发的文件
- (BOOL) downloadRemoteFile:(NSString *)fileID;

+(ItemLoadingQueue *) mainLoadingQueue;

@end


@interface ItemLoadOperation : SyncOperation<ASIHTTPRequestDelegate>
{
	ItemLoadingQueue *loadingQueue;
	NSArray *itemFiles;
	ASIHTTPRequest *req;
}


- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate;

- (void)beginLoad;
- (void)loadDone;
- (void)loadCancel;
//- (BOOL)loadPetsImages:(NSArray *)info;
- (void)setLoadingMessage:(NSString *)mesg;

@end