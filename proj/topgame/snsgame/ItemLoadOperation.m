//
//  StatusCheckOperation.m
//  ZombieFarm
//
//  Created by Matthew Fairfax on 4/22/11.
//  Copyright 2011 playforge. All rights reserved.
//
#import "SNSLogType.h"
#import "ItemLoadOperation.h"
#import "SystemUtils.h"
#import "ASIFormDataRequest.h"
#import "StringUtils.h"
// #import "GameConfig.h"
#import "SBJson.h"

@interface ItemLoadingRequest : ASIFormDataRequest
{
    // NSString *m_itemFileName;
    long long totalBytes;
    long long loadedBytes;
}
@property (nonatomic,retain) NSString *m_itemFileName;

@end

@implementation ItemLoadingRequest

@synthesize m_itemFileName;

- (void) dealloc
{
    self.m_itemFileName = nil;
    [super dealloc];
}

@end

static ItemLoadingQueue *_gSnsItemLoadingQueue = nil;

@implementation ItemLoadingQueue


@synthesize delegate;
@synthesize failedTaskCount;
@synthesize successTaskCount;
@synthesize lazyLoadMode;

+(ItemLoadingQueue *) mainLoadingQueue
{
    if(!_gSnsItemLoadingQueue) {
        _gSnsItemLoadingQueue = [[ItemLoadingQueue alloc] init];
        [_gSnsItemLoadingQueue setLazyLoadMode:YES];
    }
    return _gSnsItemLoadingQueue;
}

-(id)init
{
	self = [super init];
	delegate = nil; loadingRequest = nil;
	dictLoadingTask = [[NSMutableDictionary alloc] init];
	[self resetTaskCount];
	return self;
}

-(void)dealloc
{
    if(loadingRequest!=nil) [loadingRequest release];
	[dictLoadingTask release];
	[super dealloc];
}

-(void)resetTaskCount
{
	totalTaskCount = 0;
	runningTaskCount = 0;
	successTaskCount = 0;
	failedTaskCount = 0;
}
- (int) pendingTaskCount
{
    return totalTaskCount-successTaskCount;
}

/*
-(void)pushLoadingTask:(NSString *)url withLocalPath:(NSString *)lPath
{
	totalTaskCount++;
	[dictLoadingTask setObject:lPath forKey:url];
}
*/
// name,url,path,ver,verKey, itemID, itemInfo
-(void)pushLoadingTask:(NSDictionary *)info
{
    NSString *fileName = [info objectForKey:@"name"];
    if(!fileName) return;
    NSDictionary *oldInfo = [dictLoadingTask objectForKey:fileName];
    if(oldInfo) {
        // 不要重复加载
        if([info objectForKey:@"itemID"] && ![oldInfo objectForKey:@"itemID"])
        {
            // 替换为新的下载信息
            [dictLoadingTask setValue:info forKey:fileName];
        }
        return;
    }
    [dictLoadingTask setValue:info forKey:fileName];
    totalTaskCount++;
    [self startLoading];
}


-(void)updateLoadingMessage
{
    NSString *mesgFormat = [SystemUtils getLocalizedString:@"Loading Item Assets(%i/%i)"];
    int finishedTask = successTaskCount + failedTaskCount;
    NSString *mesg = @"";
    if(finishedTask == totalTaskCount) {
        if(failedTaskCount==0) {
            mesgFormat = [SystemUtils getLocalizedString:@"%i Item Assets Loaded."];
            mesg = [NSString stringWithFormat:mesgFormat, successTaskCount];
        }
        else {
            mesgFormat = [SystemUtils getLocalizedString:@"Load Result:%i OK, %i failed."];
            mesg = [NSString stringWithFormat:mesgFormat, successTaskCount, failedTaskCount];
        }
    }
    else {
        mesg = [NSString stringWithFormat:mesgFormat, finishedTask, totalTaskCount];
    }
	if(delegate) {
		[delegate setLoadingMessage:mesg];
	}
    else {
        // 发送道具下载状态更新通知
        NSDictionary *info = [NSDictionary dictionaryWithObject:mesg forKey:@"mesg"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kSNSNotificationUpdateItemLoadingStatus object:nil userInfo:info];
    }
}

-(void) setLazyLoadMode:(BOOL)mode
{
    lazyLoadMode = mode;
}

- (void) updateLoadingPercent
{
    if(loadingRequest==nil) return;
    ItemLoadingRequest *req = loadingRequest;
    if([req responseHeaders]!=nil) {
        unsigned long bytesReceived = [req totalBytesRead];
        id headerVal = [[req responseHeaders] objectForKey:@"Content-Length"];
        if(headerVal!=nil) {
            int totalBytes = [headerVal intValue];
            loadingPercent = bytesReceived/totalBytes;
            SNSLog(@"loading %@:%d%%", req.m_itemFileName, loadingPercent);
        }
    }
    // SNSLog(@"Content-Length:%@", headerVal);
    [self performSelector:@selector(updateLoadingPercent) withObject:nil afterDelay:5.0f];
}


- (BOOL) downloadRemoteFile:(NSString *)fileID
{
    NSString *infoKey = [NSString stringWithFormat:@"manual-info-%@",fileID];
    NSDictionary *dict = [SystemUtils getNSDefaultObject:infoKey];
    if(dict==nil) return NO;
    int ver = [[dict objectForKey:@"remoteVer"] intValue];
    NSString *fileName = [dict objectForKey:@"fileName"];
    NSDictionary *itemInfo = [dict objectForKey:@"info"];
    BOOL res = [self loadItemFile:fileName withVer:ver andInfo:itemInfo];
    [self startLoading];
    return res;
}

- (BOOL) loadItemFile:(NSString *)fileName withVer:(int)ver andInfo:(NSDictionary *)itemInfo
{
    NSString *itemID = nil;
    if(itemInfo!=nil) itemID = [itemInfo objectForKey:@"ID"];
    if([SystemUtils isRemoteFileExist:fileName withVer:ver]) {
        SNSLog(@"%@(ver:%d) already exists.", fileName, ver);
        return YES;
    }
	NSString *remoteURLRoot = [NSString stringWithFormat:@"http://%@/item_files/general", [SystemUtils getDownloadServerName]];
	NSString *localFileRoot = [SystemUtils getItemImagePath];
	
    if(itemID!=nil) {
        // 如果上次加载失败了，就使用更可靠的下载源
        NSString *keyName = [NSString stringWithFormat:@"loadRemoteFail_%@",itemID];
        int failStatus = [[SystemUtils getNSDefaultObject:keyName] intValue];
        if(failStatus==1) {
            // 使用备用下载源，清除状态
            SNSLog(@"try use kBackupDownloadServer: %@",keyName);
            [SystemUtils setNSDefaultObject:nil forKey:keyName];
            NSString *backupDownloadServer = [SystemUtils getGlobalSetting:@"kBackupDownloadServer"];
            if(backupDownloadServer!=nil && [backupDownloadServer length]>5) {
                remoteURLRoot = [NSString stringWithFormat:@"http://%@/item_files/general", backupDownloadServer];
            }
        }
        else {
            // 设置失败状态，下载成功后清除状态
            SNSLog(@"set fail status: %@",keyName);
            [SystemUtils setNSDefaultObject:@"1" forKey:keyName];
        }
    }
    
	NSString *remoteURL = [NSString stringWithFormat:@"%@/%@", remoteURLRoot, fileName];
	NSString *localFile = [NSString stringWithFormat:@"%@/%@", localFileRoot, fileName];
	
    NSString *verKey = [NSString stringWithFormat:@"remoteFileVer-%@",fileName];
    
#ifdef DEBUG
	SNSLog(@"load %@ to %@", fileName, localFile);
#endif
    
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 remoteURL, @"url", localFile, @"path",
                                 fileName, @"name",
                                 [NSString stringWithFormat:@"%i",ver], @"ver",
                                 verKey, @"verKey",
                                 nil];
    if(itemID!=nil) [info setObject:itemID forKey:@"itemID"];
    if(itemInfo!=nil) [info setObject:itemInfo forKey:@"itemInfo"];
    
	[self pushLoadingTask:info];
	return YES;
}


-(void)startLoading
{
	[self updateLoadingMessage];
	
	if([dictLoadingTask count]==0)
	{
		if(delegate) [delegate loadDone];
		return;
	}
	
	if(runningTaskCount>0) return;
	
    int isBgMode = [[SystemUtils getNSDefaultObject:@"kLoadItemInBG"] intValue];
	// start next three task
	NSArray *arr = [dictLoadingTask allKeys];
	int i = 0;
	for(i=0;i<[arr count]; i++)
	{
        if(isBgMode==1 && i==1) break;
		if(i==2) break;
		
        NSString *fileName = [arr objectAtIndex:i];
        NSDictionary *info = [dictLoadingTask objectForKey:fileName];
        
        /*
        // 再次检查道具文件是否已经存在
        int ver = [[info objectForKey:@"ver"] intValue];
        if([SystemUtils isRemoteFileExist:fileName withVer:ver]) {
            [self startLoading];
            return;
        }
         */
        
		NSString *url = [info objectForKey:@"url"];
		
		ItemLoadingRequest *request = [ItemLoadingRequest requestWithURL:[NSURL URLWithString:url]];
        request.m_itemFileName = fileName;
        
        SNSLog(@"start loading %@", url);
        
        [request setDownloadDestinationPath:[info objectForKey:@"path"]];
        // request.m_localFilePath = localFile;
        [request setTimeOutSeconds:10.0f];
		
		[request setRequestMethod:@"GET"];
		[request setDelegate:self];
        request.downloadProgressDelegate = self;
		[request startAsynchronous];
		[request retain];
        if(loadingRequest!=nil) [loadingRequest release];
        loadingRequest = [request retain];
        loadingPercent = 0;
        // [self performSelector:@selector(updateLoadingPercent) withObject:nil afterDelay:5.0f];
	}
	runningTaskCount = i;
}

-(void)loadFinish:(BOOL)isSuccess withRequest:(ASIHTTPRequest *)req
{
	runningTaskCount--;
	if(isSuccess) successTaskCount++;
	else failedTaskCount++;
	
	[self updateLoadingMessage];
    if(loadingRequest==req) {
        [loadingRequest release]; loadingRequest = nil;
    }
    
    ItemLoadingRequest *req2 = (ItemLoadingRequest *)req;
    NSString *fileName = req2.m_itemFileName;
	if(isSuccess) {
        // set remote file version
        NSDictionary *info = [dictLoadingTask objectForKey:fileName];
        NSString *verKey = [info objectForKey:@"verKey"];
        NSString *ver = [info objectForKey:@"ver"];
        if(ver && [ver intValue]!=0 && verKey!=nil) {
            SNSLog(@"load ok: set version of %@: %@=%@ url:%@", fileName, verKey, ver, [req.url absoluteString]);
            [SystemUtils setNSDefaultObject:ver forKey:verKey];
        }
        NSDictionary *itemInfo = [info objectForKey:@"itemInfo"];
        if(itemInfo!=nil) {
            NSString *infoKey = [NSString stringWithFormat:@"%@_itemInfo", [itemInfo objectForKey:@"ID"]];
            SNSLog(@"itemInfo:%@",itemInfo);
            [SystemUtils setNSDefaultObject:itemInfo forKey:infoKey];
            //infoKey = [NSString stringWithFormat:@"manual-info-%@", [itemInfo objectForKey:@"ID"]];
            //[SystemUtils setNSDefaultObject:nil forKey:infoKey];
        }
        
        NSString *itemID = [info objectForKey:@"itemID"];
        if(itemID!=nil) {
            // 清除失败状态
            NSString *keyName = [NSString stringWithFormat:@"loadRemoteFail_%@",itemID];
            SNSLog(@"clear fail status: %@",keyName);
            [SystemUtils setNSDefaultObject:nil forKey:keyName];
        }

        //if(lazyLoadMode) {
        NSObject<GameDataDelegate> *game = [SystemUtils getGameDataDelegate];
        if([info objectForKey:@"itemID"] && game!=nil && [game respondsToSelector:@selector(onRemoteItemImageLoaded:)])
        {
            [game onRemoteItemImageLoaded:[info objectForKey:@"itemID"]];
        }
        SNSLog(@"taskInfo:%@",info);
        // post notification
        // info: name,url,path,ver,verKey, itemID, itemInfo
        [[NSNotificationCenter defaultCenter] postNotificationName:kSNSNotificationRemoteFileLoaded object:nil userInfo:info];
        //}
    }
    
	[dictLoadingTask removeObjectForKey:req2.m_itemFileName];
    
	[req release];
	
	if(runningTaskCount<=0) {
        int isBgMode = [[SystemUtils getNSDefaultObject:@"kLoadItemInBG"] intValue];
        if(isBgMode==1 && !lazyLoadMode)
            [self performSelector:@selector(startLoading) withObject:nil afterDelay:5.0f];
        else 
            [self startLoading];
    }
}

#pragma mark ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
	SNSLog(@"status code:%i", request.responseStatusCode);
	
    ItemLoadingRequest *req = (ItemLoadingRequest *)request;
    NSString *fileName = req.m_itemFileName;
    NSDictionary *info = [dictLoadingTask objectForKey:fileName];
    
	NSString *url = [info objectForKey:@"url"];
	NSString *path = [info objectForKey:@"path"];
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		SNSLog(@"fail to load %@", url);
		[self loadFinish:NO withRequest:request];
		return;
	}
    /*
	// NSString *response = [request responseString];
	NSData *data = [request responseData];
	if(!data || [data length]==0) {
		NSLog(@"Empty response");
		[self loadFinish:NO withRequest:request];
		return;
	}
	NSLog(@"load %@ ok", url);
	 */
	// BOOL res = [data writeToFile:path atomically:YES];
    BOOL res = YES;
    // unzip file
    int len = [path length];
    NSString *suffix = [path substringFromIndex:len-4];
    if([suffix isEqualToString:@".zip"]) {
        NSString *localFileRoot = [SystemUtils getItemImagePath];
        res = [SystemUtils unzipFile:path toPath:localFileRoot];
        if(!res) {
            SNSLog(@"fail to unzip %@", path);
            NSError *err = nil;
            [[NSFileManager defaultManager] removeItemAtPath:path error:&err];
        }
        else {
            // 下载成功，用一个空文件代替，减少空间占用
            NSData *emptyData = [[NSData alloc] init];
            [emptyData writeToFile:path atomically:NO];
            // [[NSFileManager defaultManager] createFileAtPath:path contents:emptyData attributes:nil];
            [emptyData release];
            // 如果解压出来是个同名目录，就把里面所有文件移动到上级目录
            NSString *dirPath = [path substringToIndex:len-4];
            NSFileManager *mgr = [NSFileManager defaultManager];
            BOOL isDir = NO;
            BOOL exist = [mgr fileExistsAtPath:dirPath isDirectory:&isDir];
            if(exist && isDir)
            {
                NSArray *subFiles = [mgr contentsOfDirectoryAtPath:dirPath error:nil];
                if(subFiles) {
                    for(NSString *fileName in subFiles) {
                        NSString *file1 = [dirPath stringByAppendingPathComponent:fileName];
                        NSString *file2 = [localFileRoot stringByAppendingPathComponent:fileName];
                        [mgr moveItemAtPath:file1 toPath:file2 error:nil];
                    }
                    [mgr removeItemAtPath:dirPath error:nil];
                }
            }
            // 检查是否有需要保护的文件
            SNSLog(@"Loaded file:%@",fileName);
            NSDictionary *protectFiles = [SystemUtils getSystemInfo:@"kProtectRemoteFiles"];
            if(protectFiles && [protectFiles objectForKey:fileName]) {
                NSString *files = [protectFiles objectForKey:fileName];
                NSArray *arr = [files componentsSeparatedByString:@","];
                for (NSString *file in arr) {
                    // generate hash for each file
                    [SystemUtils updateFileDigest:[localFileRoot stringByAppendingPathComponent:file]];
                }
            }
        }
	}
	else {
		SNSLog(@"fail to write %@", path);
	}
	[self loadFinish:res withRequest:request];
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSString *url = [request.url absoluteString];
	// NSString *path = [dictLoadingTask objectForKey:url];
	NSError *error = [request error];
	SNSLog(@"fail to load:%@ error: %@", url, error);
	[self loadFinish:NO withRequest:request];
}

#pragma mark -

#pragma mark ASIProgressDelegate
// Called when the request receives some data - bytes is the length of that data
- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes
{
    ItemLoadingRequest *req = (ItemLoadingRequest *)request;
    NSString *fileName = req.m_itemFileName;
    NSDictionary *taskInfo = [dictLoadingTask objectForKey:fileName];
    NSString *itemID = [taskInfo objectForKey:@"itemID"];
    int percent = 0;
    if(req.contentLength>0)
        percent = req.totalBytesRead*100/req.contentLength;
    SNSLog(@"%@: %lld/%lld  percent:%d%%",fileName, req.totalBytesRead, req.contentLength, percent);
    if(percent==0) return;
    // post notification
    // info: name,url,path,ver,verKey, itemID
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:fileName, @"file", [NSNumber numberWithInt:percent], @"percent", itemID, @"itemID", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSNSNotificationFileLoadingProgress object:nil userInfo:info];
    //}
    
}
#pragma mark -

@end



@implementation ItemLoadOperation


- (id)initWithManager:(SyncQueue*)manager andDelegate:(id<SyncQueueDelegate>)theDelegate
{
    self = [super initWithManager:manager andDelegate:theDelegate];
    
    if (self)
    {
		loadingQueue = [[ItemLoadingQueue alloc] init];
		loadingQueue.delegate = self;
		itemFiles = [SystemUtils getLoadedConfigFileNames];
        SNSLog(@"remote config files:%@", itemFiles);
		[itemFiles retain];
    }
    
    return self;
}

-(void)dealloc
{
	[loadingQueue release];
	[itemFiles release];
	[super dealloc];
}

- (void)start
{
	[super start];
	
    [self performSelectorOnMainThread:@selector(beginLoad) withObject:nil waitUntilDone:NO];
}

- (void)setLoadingMessage:(NSString *)mesg
{
    if (delegate)
        [delegate statusMessage:mesg cancelAfter:0];
}

- (void)beginLoad
{
    SNSLog(@"delegate:%@",delegate);
	// loading language info
	int remoteVer = [[SystemUtils getGlobalSetting:kItemFileVerKey] intValue];
	NSString *localKey = [NSString stringWithFormat:@"%@-%@",kItemFileLocalVerKey, [SystemUtils getCurrentLanguage]];
    int localVer  = [[SystemUtils getGlobalSetting:localKey] intValue];
    if(localVer == 0) {
        localVer = [[SystemUtils getGlobalSetting:kItemFileLocalVerKey] intValue];
    }
    
    int forceLoad = [[SystemUtils getNSDefaultObject:kDownloadItemRequired] intValue];
	if(forceLoad==0 && ( remoteVer == localVer && localVer>0)) {
		SNSLog(@"%s remoteVer:%i localVer:%i", __FUNCTION__, remoteVer, localVer);
		[self loadDone]; return;
	}
    
    if(forceLoad == 1) localVer = 0;
	// if(localVer == 0) localVer = 1;
	NSString *userID = [SystemUtils getCurrentUID];
	
	NSString *api = [SystemUtils getServerRoot];
    /*
    NSString *fileFormat = [SystemUtils getSystemInfo:@"kRemoteItemFileFormat"];
    if(fileFormat==nil) fileFormat = @"dict";
    
	api = [api stringByAppendingFormat:@"getItemList.php?itemVer=%i&userID=%@&format=%@", localVer,userID, fileFormat];
     */
	api = [api stringByAppendingFormat:@"getItemList.php?itemVer=%i&userID=%@", localVer,userID];
	SNSLog(@"%s api:%@ remoteVer:%i", __FUNCTION__, api, remoteVer);
	NSURL *url = [NSURL URLWithString:api];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"GET"];
	[request setDelegate:self];
    if(delegate) {
        [request setTimeOutSeconds:3.0f];
    }
    else {
        [request setTimeOutSeconds:20.0f];
    }
	[request startAsynchronous];
	req = [request retain];
	[self retain];
	retainTimes = 1;
	// [self performSelector:@selector(loadCancel) withObject:nil afterDelay:10];
}


- (void)releaseRequest
{
	if(retainTimes<=0) return;
	@synchronized(self) {
		retainTimes--;
		if(retainTimes==0) {
			[req release]; req = nil;
			[self release];
		}
	}
}

- (void)loadDone
{
	BOOL isSkip = (retainTimes == 0);
	[self releaseRequest];
    if([loadingQueue pendingTaskCount]==0) {
        NSNumber *ver = [SystemUtils getGlobalSetting:kItemFileVerKey];
        if(!ver) ver = [NSNumber numberWithInt:0];
        NSString *localKey = [NSString stringWithFormat:@"%@-%@",kItemFileLocalVerKey, [SystemUtils getCurrentLanguage]];
        [SystemUtils setGlobalSetting:ver forKey:localKey];
		SNSLog(@"%s: set local ver to %@", __func__, ver);
    }
    
	if(finished) return;
	if(!isSkip && (loadingQueue.failedTaskCount == 0 || loadingQueue.lazyLoadMode)) {
		// rename file name
		NSString *itemPath = [SystemUtils getItemRootPath];
		NSFileManager *mgr = [NSFileManager defaultManager]; NSError *err = nil;
		for(int i=0; i<[itemFiles count]; i++)
		{
			NSString *aKey = [itemFiles objectAtIndex:i];
			NSString *newFile = [itemPath stringByAppendingFormat:@"/%@_new",aKey];
			NSString *oldFile = [itemPath stringByAppendingFormat:@"/%@",aKey];
			if(![mgr fileExistsAtPath:newFile]) continue;
			if([mgr fileExistsAtPath:oldFile]) [mgr removeItemAtPath:oldFile error:&err];
			BOOL res = [mgr moveItemAtPath:newFile toPath:oldFile error:&err];
			if(!res) {
				SNSLog(@"rename %@ res:%i err:%@", oldFile, res, err);
			}
            
            // 发送道具下载状态更新通知
            NSDictionary *info = [NSDictionary dictionaryWithObject:aKey forKey:@"file"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kSNSNotificationRemoteConfigLoaded object:nil userInfo:info];
		
		}
        if(YES) {
			NSString *aKey = @"remoteFiles";
			NSString *newFile = [itemPath stringByAppendingFormat:@"/%@_new",aKey];
			NSString *oldFile = [itemPath stringByAppendingFormat:@"/%@",aKey];
			if([mgr fileExistsAtPath:newFile]) {
                if([mgr fileExistsAtPath:oldFile]) [mgr removeItemAtPath:oldFile error:&err];
                BOOL res = [mgr moveItemAtPath:newFile toPath:oldFile error:&err];
                if(!res) {
                    SNSLog(@"rename %@ res:%i err:%@", oldFile, res, err);
                }
                // [SystemUtils updateFileDigest:oldFile];
            }
            // 发送道具下载状态更新通知
            NSDictionary *info = [NSDictionary dictionaryWithObject:aKey forKey:@"file"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kSNSNotificationRemoteConfigLoaded object:nil userInfo:info];
        }
		
		[SystemUtils setNSDefaultObject:[NSNumber numberWithInt:0] forKey:kDownloadItemRequired];
        int isBgLoading = [[SystemUtils getNSDefaultObject:@"kLoadItemInBG"] intValue];
        if(isBgLoading==1) {
            [SystemUtils setNSDefaultObject:@"0" forKey:@"kLoadItemInBG"];
            if(loadingQueue.successTaskCount>0) {
                [SystemUtils setNSDefaultObject:@"1" forKey:@"kForceQuitOnBgMode"];
            }
        }
		// update remote file
		// [GameConfig updateRemoteFile];
        // 更新道具下载时间
        if(loadingQueue.successTaskCount>0) {
            int now = [SystemUtils getCurrentTime];
            [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:now] forKey:@"kNewRemoteItemAddTime"];
        }
        // 发送道具配置更新通知
        [[NSNotificationCenter defaultCenter] postNotificationName:kSNSNotificationNewItemLoaded object:nil userInfo:nil];
	}
		
    [queueManager operationDone:self];
}

- (void)loadCancel
{
	[self releaseRequest];
	if(finished) return;
	SNSLog(@"%s", __func__);
	failed = YES;
    [queueManager operationDone:self];
}

- (BOOL) loadItemFile:(NSString *)fileName withVer:(int)ver andInfo:(NSDictionary *)itemInfo
{
    return [loadingQueue loadItemFile:fileName withVer:ver andInfo:itemInfo];
    /*
    NSString *itemID = nil;
    if(itemInfo!=nil) itemID = [itemInfo objectForKey:@"ID"];
    if([SystemUtils isRemoteFileExist:fileName withVer:ver]) {
        SNSLog(@"%@(ver:%d) already exists.", fileName, ver);
        return YES;
    }
	NSString *remoteURLRoot = [NSString stringWithFormat:@"http://%@/item_files/general", [SystemUtils getDownloadServerName]];
	NSString *localFileRoot = [SystemUtils getItemImagePath];
	
	NSString *remoteURL = [NSString stringWithFormat:@"%@/%@", remoteURLRoot, fileName];
	NSString *localFile = [NSString stringWithFormat:@"%@/%@", localFileRoot, fileName];
	
    NSString *verKey = [NSString stringWithFormat:@"remoteFileVer-%@",fileName];
    
#ifdef DEBUG
	SNSLog(@"load %@ to %@", fileName, localFile);
#endif
    
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 remoteURL, @"url", localFile, @"path",
                                 fileName, @"name",
                                 [NSString stringWithFormat:@"%i",ver], @"ver",
                                 verKey, @"verKey",
                                 nil];
    if(itemID!=nil) [info setObject:itemID forKey:@"itemID"];
    if(itemInfo!=nil) [info setObject:itemInfo forKey:@"itemInfo"];
    
	[loadingQueue pushLoadingTask:info];
	return YES;
     */
}

- (BOOL) loadItemFile:(NSString *)fileName withVer:(int)ver andID:(NSString *)itemID
{
    NSDictionary *info = nil;
    if(itemID!=nil) info = [NSDictionary dictionaryWithObjectsAndKeys:itemID, @"ID", nil];
    [self loadItemFile:fileName withVer:ver andInfo:info];
}

- (BOOL) loadItemFile:(NSString *)fileName
{
    return [self loadItemFile:fileName withVer:0 andID:nil];
}


- (BOOL)loadImages:(NSArray *)pets ofFile:(NSString *)file
{
    if([pets count]==0) return YES;
    NSDictionary *info2 = [pets objectAtIndex:0];
    BOOL hasRemoteFileField = NO;
    if([info2 isKindOfClass:[NSDictionary class]]) 
    {
        if([info2 objectForKey:@"RemoteFile"]) hasRemoteFileField = YES;
    }

	// NSString *mesgFormat = [SystemUtils getLocalizedString:@"Loading Item Images(%i/%i)"];
	// int num = [pets count];
	// NSString *mesg = [NSString stringWithFormat:mesgFormat, 0, num];
	// if(delegate) [delegate statusMessage:mesg cancelAfter:0];
	// NSFileManager *mgr = [NSFileManager defaultManager];
	NSString *fieldKey = [NSString stringWithFormat:@"kConfigFileField-%@", file];
	NSDictionary *fieldList = [SystemUtils getSystemInfo:fieldKey];
	
	if(!hasRemoteFileField && (!fieldList || [fieldList count]==0)) return YES;
	NSString *typeFieldName = nil; 
	NSString *allFieldName = nil;
    NSString *IDFieldName = nil;
    IDFieldName   = [fieldList objectForKey:@"IDFieldName"];
    if(!hasRemoteFileField) {
        typeFieldName = [fieldList objectForKey:@"TypeFieldName"];
        allFieldName  = [fieldList objectForKey:@"FieldName"];
    }
	
	BOOL loadAllOK = YES;
	for(int i=0;i<[pets count];i++)
	{
		// mesg = [NSString stringWithFormat:mesgFormat, i, num];
		// if(delegate)[delegate statusMessage:mesg cancelAfter:0];
		NSDictionary *info = [pets objectAtIndex:i];
        if(![info isKindOfClass:[NSDictionary class]]) continue;
		int isRemote = [[info objectForKey:@"Remote"] intValue];
		if(isRemote==0) continue;
        NSString *itemID = nil;
        if(IDFieldName!=nil) itemID = [info objectForKey:IDFieldName];
        if(itemID==nil) itemID = [info objectForKey:@"ID"];
		if(itemID==nil) continue;
        /*
        if([itemID isEqualToString:@"35"]) {
            NSLog(@"info:%@", info);
        }
         */
		// NSString *remoteURL = nil; NSString *localFile = nil; 
		// NSString *remoteURLRoot = [NSString stringWithFormat:@"http://%@/item_files/general", [SystemUtils getServerName]];
		// BOOL loadOK = NO; BOOL unzipOK = NO;
		BOOL loadOK = NO; BOOL useiPadVer = NO;
		// NSString *localFileRoot = [SystemUtils getItemImagePath];
		NSString *fileName = [info objectForKey:@"RemoteFile"];
        if([SystemUtils isiPad])
        {
            if([info objectForKey:@"iPadRemoteFile"]) {
                fileName = [info objectForKey:@"iPadRemoteFile"];
                useiPadVer = YES;
            }
        }
        if(hasRemoteFileField && fileName && [fileName length]>4) {
            int fileVer = [[info objectForKey:@"RemoteFileVer"] intValue];
            if(useiPadVer) fileVer =  [[info objectForKey:@"iPadRemoteFileVer"] intValue];
            loadOK = [self loadItemFile:fileName withVer:fileVer andID:itemID];
            if(!loadOK)
                loadAllOK = NO;
            continue;
        }
		if(typeFieldName!=nil) {
			NSString *type = [info objectForKey:typeFieldName];
			
			NSString *fieldName = [fieldList objectForKey:type];
			if(!fieldName) continue;
			NSArray *fieldNameList = [fieldName componentsSeparatedByString:@";"];
			for(fieldName in fieldNameList) {
				NSArray *arr = [fieldName componentsSeparatedByString:@","];
				fieldName = [arr objectAtIndex:0];
				BOOL hasSuffix = ([arr count]>=2);
				NSString *suffix = nil;
				if(hasSuffix) suffix = [arr objectAtIndex:1]; 
				fileName = [info objectForKey:fieldName];
				if(!fileName) continue;
				if(hasSuffix)
					fileName = [NSString stringWithFormat:@"%@.%@", fileName, suffix];
				loadOK = [self loadItemFile:fileName withVer:0 andID:itemID];
				if(!loadOK) {
					loadAllOK = NO; continue;
				}
			}
		}
		if(allFieldName!=nil) {
			NSString *fieldName = allFieldName;
			NSArray *fieldNameList = [fieldName componentsSeparatedByString:@";"];
			for(fieldName in fieldNameList) {
				NSArray *arr = [fieldName componentsSeparatedByString:@","];
				fieldName = [arr objectAtIndex:0];
				BOOL hasSuffix = ([arr count]>=2);
				NSString *suffix = nil;
				if(hasSuffix) suffix = [arr objectAtIndex:1]; 
				fileName = [info objectForKey:fieldName];
				if(!fileName) continue;
				if(hasSuffix)
					fileName = [NSString stringWithFormat:@"%@.%@", fileName, suffix];
				loadOK = [self loadItemFile:fileName withVer:0 andID:itemID];
				if(!loadOK) {
					loadAllOK = NO; continue;
				}
			}
		}
	}
	return loadAllOK;
}


- (BOOL)loadStaffImages:(NSArray *)pets
{
	// NSString *mesgFormat = [SystemUtils getLocalizedString:@"Loading Staff Images(%1$i/%2$i)"];
	// int num = [pets count];
	// NSString *mesg = [NSString stringWithFormat:mesgFormat, 0, num];
	// if(delegate) [delegate statusMessage:mesg cancelAfter:0];
	NSFileManager *mgr = [NSFileManager defaultManager];
	BOOL loadAllOK = YES;
	for(int i=0;i<[pets count];i++)
	{
		// mesg = [NSString stringWithFormat:mesgFormat, i, num];
		// if(delegate)[delegate statusMessage:mesg cancelAfter:0];
		NSDictionary *info = [pets objectAtIndex:i];
		int isRemote = [[info objectForKey:@"remote"] intValue];
		if(isRemote==0) continue;
		// NSString *remoteURL = nil; NSString *localFile = nil; 
		// NSString *remoteURLRoot = [NSString stringWithFormat:@"http://%@/item_files/general", [SystemUtils getServerName]];
		BOOL loadOK = NO; // BOOL unzipOK = NO;
		NSString *localFileRoot = [SystemUtils getItemImagePath];
		NSString *fileName = nil;
		// NSString *type = [info objectForKey:@"Type"];
		
		// load Animation zip
		fileName = [NSString stringWithFormat:@"%@.zip", [info objectForKey:@"Animation"]];
		SNSLog(@"%s:fileName=%@",__FUNCTION__, fileName);
		if([fileName isEqualToString:@"0.zip"]) continue;
		NSString *localFile = [NSString stringWithFormat:@"%@/%@", localFileRoot, fileName];
		if([mgr fileExistsAtPath:localFile]) continue;
		loadOK = [self loadItemFile:fileName];
		if(!loadOK) {
			loadAllOK = NO; continue;
		}
		// unzipOK = [SystemUtils unzipFile:localFile toPath:localFileRoot];
		// if(!unzipOK) loadAllOK = NO;
		// NSLog(@"unzip result:%i", unzipOK);
	}
	return loadAllOK;
}


- (BOOL)loadConnectorImages:(NSArray *)pets
{
	// NSString *mesgFormat = [SystemUtils getLocalizedString:@"Loading Connector Images(%1$i/%2$i)"];
	// int num = [pets count];
	// NSString *mesg = [NSString stringWithFormat:mesgFormat, 0, num];
	// if(delegate) [delegate statusMessage:mesg cancelAfter:0];
	NSFileManager *mgr = [NSFileManager defaultManager];
	BOOL loadAllOK = YES;
	for(int i=0;i<[pets count];i++)
	{
		// mesg = [NSString stringWithFormat:mesgFormat, i, num];
		// if(delegate)[delegate statusMessage:mesg cancelAfter:0];
		NSDictionary *info = [pets objectAtIndex:i];
		int isRemote = [[info objectForKey:@"remote"] intValue];
		if(isRemote==0) continue;
		// NSString *remoteURL = nil; NSString *localFile = nil; 
		// NSString *remoteURLRoot = [NSString stringWithFormat:@"http://%@/item_files/general", [SystemUtils getServerName]];
		BOOL loadOK = NO; BOOL unzipOK = NO;
		NSString *localFileRoot = [SystemUtils getItemImagePath];
		NSString *fileName = nil;
		// NSString *type = [info objectForKey:@"Type"];
		
		// load IconName
		fileName = [info objectForKey:@"IconName"];
		NSString *localFile = [NSString stringWithFormat:@"%@/%@", localFileRoot, fileName];
		if([mgr fileExistsAtPath:localFile]) continue;
		loadOK = [self loadItemFile:fileName];
		if(!loadOK) {
			loadAllOK = NO; continue;
		}
		
		// unzipOK = [SystemUtils unzipFile:localFile toPath:localFileRoot];
		if(!unzipOK) loadAllOK = NO;
		// NSLog(@"unzip result:%i", unzipOK);
	}
	return loadAllOK;
}


- (BOOL)loadRemoteFiles:(NSArray *)files
{
	NSFileManager *mgr = [NSFileManager defaultManager];
	BOOL loadAllOK = YES; BOOL isRetina = [SystemUtils isRetina]; BOOL isiPad = [SystemUtils isiPad];
    
    NSString *lang = [SystemUtils getCurrentLanguage];
    NSString *subID = [SystemUtils getSystemInfo:@"kSubAppID"];
    if(subID==nil || [subID length]==0) subID = @"0";
	for(int i=0;i<[files count];i++)
	{
		// mesg = [NSString stringWithFormat:mesgFormat, i, num];
		// if(delegate)[delegate statusMessage:mesg cancelAfter:0];
		NSDictionary *info = [files objectAtIndex:i];
#ifdef DEBUG
        SNSLog(@"info:%@",info);
#endif
        // check name
        NSString *fileName = [info objectForKey:@"RemoteFile"];
        NSString *fn = nil;
        int useiPadVer = 0;
        fn = [info objectForKey:@"iPadRemoteFile"];
        if(isiPad && fn!=nil && [fn length]>0) {
            fileName = fn;
            useiPadVer = 1;
        }
        fn = [info objectForKey:@"iPad3RemoteFile"];
        if(isiPad && isRetina && fn!=nil && [fn length]>0) {
            fileName = fn;
            useiPadVer = 2;
        }
        if(!fileName || ![fileName isKindOfClass:[NSString class]] || [fileName length]<3)
            continue;
        // 检查语言
        NSString *fileLang = [info objectForKey:@"lang"]; // 只运行这些语言的客户端下载
        NSString *fileExLang = [info objectForKey:@"exLang"]; // 不允许这些语言的客户端下载
        
        BOOL shouldSkip = NO;
        if(fileLang && [fileLang isKindOfClass:[NSString class]] && [fileLang length]>0)
        {
            shouldSkip = YES;
            NSArray *arr = [fileLang componentsSeparatedByString:@","];
            if([StringUtils stringArrayExists:arr keyword:lang]) shouldSkip = NO;
        }
        if(shouldSkip) continue;
        if(fileExLang && [fileExLang isKindOfClass:[NSString class]] && [fileExLang length]>0) {
            NSArray *arr = [fileExLang componentsSeparatedByString:@","];
            if([StringUtils stringArrayExists:arr keyword:lang]) shouldSkip = YES;
        }
        if(shouldSkip) continue;
        
        // 检查子版本
        NSString *fileSubID = [info objectForKey:@"subID"];
        if(fileSubID && [fileSubID isKindOfClass:[NSString class]] && [fileSubID length]>0)
        {
            shouldSkip = YES;
            if([fileSubID isEqualToString:@"all"]) shouldSkip = NO;
            else {
                NSArray *arr = [fileSubID componentsSeparatedByString:@","];
                if([StringUtils stringArrayExists:arr keyword:subID]) shouldSkip = NO;
            }
        }
        if(shouldSkip) continue;
        fileSubID = [info objectForKey:@"excludeSubID"];
        if(fileSubID && [fileSubID isKindOfClass:[NSString class]] && [fileSubID length]>0)
        {
            NSArray *arr = [fileSubID componentsSeparatedByString:@","];
            if([StringUtils stringArrayExists:arr keyword:subID]) shouldSkip = YES;
        }
        if(shouldSkip) continue;
        
        // 检查版本号 cVerRange
        // 冒号分割的两个版本号，c1:c2 只有版本号位于或者等于这两个版本之间的客户端才会下载；
        // 如果只设置c1，那么只有版本大于等于c1的才会下载
        NSString *clientVer = [info objectForKey:@"cVerRange"];
        if(clientVer && [clientVer isKindOfClass:[NSString class]] && [clientVer length]>0)
        {
            NSArray *arr = [clientVer componentsSeparatedByString:@":"];
            NSString *ver = [SystemUtils getClientVersion];
            if([ver compare:[arr objectAtIndex:0]]<0) shouldSkip = YES;
            if([arr count]>=2) {
                if([ver compare:[arr objectAtIndex:1]]>0) shouldSkip = YES;
            }
        }
        if(shouldSkip) continue;
        
        int remoteVer = [[info objectForKey:@"RemoteFileVer"] intValue];
        if(useiPadVer==1) remoteVer = [[info objectForKey:@"iPadRemoteFileVer"] intValue];
        if(useiPadVer==2) remoteVer = [[info objectForKey:@"iPad3RemoteFileVer"] intValue];
		NSString *localFileRoot = [SystemUtils getItemImagePath];
		NSString *localFile = [NSString stringWithFormat:@"%@/%@", localFileRoot, fileName];
		if([mgr fileExistsAtPath:localFile]) {
            // check version
            NSString *verKey = [NSString stringWithFormat:@"remoteFileVer-%@",fileName];
            int localVer  = [[SystemUtils getGlobalSetting:verKey] intValue];
            if(remoteVer == localVer) continue;
        }
                        
        // 检查是否是手动下载的版本
        int manualDownload = [[info objectForKey:@"manual"] intValue];
        if(manualDownload==1) {
            NSString *key = [NSString stringWithFormat:@"manual-info-%@",[info objectForKey:@"ID"]];
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:fileName, @"fileName", [NSNumber numberWithInt:remoteVer], @"remoteVer", info, @"info", nil];
            [SystemUtils setNSDefaultObject:dict forKey:key];
            shouldSkip = YES;
        }
        if(shouldSkip) continue;
        
		BOOL loadOK = NO;
		// NSString *type = [info objectForKey:@"Type"];
		
		loadOK = [self loadItemFile:fileName withVer:remoteVer andInfo:info];
		// loadOK = [self loadItemFile:fileName withVer:remoteVer andID:[info objectForKey:@"ID"]];
		if(!loadOK) {
			loadAllOK = NO; continue;
		}
		
		// unzipOK = [SystemUtils unzipFile:localFile toPath:localFileRoot];
		// if(!unzipOK) loadAllOK = NO;
		// NSLog(@"unzip result:%i", unzipOK);
	}
	return loadAllOK;
}

#pragma mark ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
	SNSLog(@"status code:%i", request.responseStatusCode);
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		[self loadCancel];
		return;
	}
	NSData *jsonData = [request responseData];
	SNSLog(@"response length:%i", [jsonData length]); // , [request responseString]);
	// NSString *response = [request responseString];
	if(!jsonData || [jsonData length]==0) {
		SNSLog(@"no response data");
		[self loadCancel];
		return;
	}
	// [request responseData];
	// NSString *jsonString = @"yourJSONHere";
	// NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	NSError *error = nil;
	NSString *jsonString = [[NSString alloc] initWithBytes:jsonData.bytes length:jsonData.length encoding:NSUTF8StringEncoding];
	[jsonString autorelease];
	NSDictionary *dictionary = [StringUtils convertJSONStringToObject:jsonString];
	if(!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
		SNSLog(@"parse response error:%@ resp:%@", error, [request responseString]);
        // set force load status
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:0] forKey:kDownloadItemRequired];
		[self loadCancel];
		return;
	}
    if(![dictionary objectForKey:kItemFileVerKey])
    {
        SNSLog(@"invalid response:%@", dictionary);
		[self loadCancel];
		return;
    }
    NSString *fileSuffix = @"_new";

#ifdef DEBUG
	SNSLog(@"continue downloading files");
	// SNSLog(@"response:%@", dictionary);
#endif
	// combinedata, leveldata, itemdata, extdata
	BOOL loadAllAttachOK = YES;
	// save item files
	NSString *itemPath = [SystemUtils getItemRootPath];
	// NSFileManager *mgr = [NSFileManager defaultManager];
	NSError *err = nil;
    int noWaitingFileDownload = [[SystemUtils getSystemInfo:@"kNeverWaitLoadingResource"] intValue];
	// NSArray *itemFiles = [NSArray arrayWithObjects:@"connectors", @"exp", @"expansion", @"funroom", @"guestbook", @"iap", @"nannies",@"pets",@"rating",@"staff", nil];
	for(int i=0;i<[itemFiles count];i++)
	{
		NSString *aKey = [itemFiles objectAtIndex:i];
		NSArray *items = [dictionary objectForKey:aKey];
		if(!items || ![items isKindOfClass:[NSArray class]] || [items count]==0) {
			SNSLog(@"%s: %@ not exist", __FUNCTION__, aKey);
			continue;
		}
        NSString *fieldsKey = [aKey stringByAppendingString:@"_fields"];
        NSArray *fields = [dictionary objectForKey:fieldsKey];
        if(fields) {
            [SystemUtils setGlobalSetting:fields forKey:fieldsKey];
            // SNSLog(@"save %@:%@",fieldsKey,fields);
        }
		// 只有在SystemConfig.plist中定义了远程字段的，才尝试加载远程道具
		BOOL loadImageOK = YES;
		NSDictionary *fieldInfo = [SystemUtils getSystemInfo:[NSString stringWithFormat:@"kConfigFileField-%@", aKey]];
		if(fieldInfo) 
		{
			loadImageOK = [self loadImages:items ofFile:aKey];
			SNSLog(@"load %@:%i", aKey, loadImageOK);
		}
		/*
		else if([aKey isEqualToString:@"staff"])
		{
			loadImageOK = [self loadStaffImages:items];
			NSLog(@"load staff:%i", loadImageOK);
		}
		else if([aKey isEqualToString:@"connectors"])
		{
			// loadImageOK = [self loadConnectorImages:items];
			// NSLog(@"load staff:%i", loadImageOK);
		}
		 */
		if(!loadImageOK) { 
			loadAllAttachOK = NO; continue;
		}
		NSString *file = [itemPath stringByAppendingFormat:@"/%@%@",aKey, fileSuffix];
		// if([mgr fileExistsAtPath:file]) [mgr removeItemAtPath:file error:&err];
		NSString *text = [StringUtils convertObjectToJSONString:items];
        text = [SystemUtils addHashToSaveData:text];
		BOOL res = NO; 
        if(noWaitingFileDownload==1) {
            file = [itemPath stringByAppendingFormat:@"/%@",aKey];
            [text writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
            // 发送道具下载状态更新通知
            NSDictionary *info = [NSDictionary dictionaryWithObject:aKey forKey:@"file"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kSNSNotificationRemoteConfigLoaded object:nil userInfo:info];
        }
        else {
            res = [text writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:&err];
        }
		
        SNSLog(@"save to %@ res:%i err:%@", file, res, err);
		
        // if(res) [SystemUtils updateFileDigest:file];
	}
    
    // remoteFiles
    NSArray *remoteFiles = [dictionary objectForKey:@"remoteFiles"];
    if(remoteFiles == nil) remoteFiles = [dictionary objectForKey:@"item_remotefiles"];
    if(remoteFiles && [remoteFiles isKindOfClass:[NSArray class]] && [remoteFiles count]>0)
    {
        // load remote files
        [self loadRemoteFiles:remoteFiles];
		NSString *file = [itemPath stringByAppendingFormat:@"/remoteFiles%@", fileSuffix];
		// if([mgr fileExistsAtPath:file]) [mgr removeItemAtPath:file error:&err];
		NSString *text = [StringUtils convertObjectToJSONString:remoteFiles];
        text = [SystemUtils addHashToSaveData:text];
		BOOL res = [text writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:&err];
		if(!res) {
			SNSLog(@"save to %@ res:%i err:%@", file, res, err);
		}
        // if(res) [SystemUtils updateFileDigest:file];
    }
#ifdef SNS_ENABLE_LAZY_LOAD_REMOTE_ITEM
    int forceLoad = [[SystemUtils getNSDefaultObject:kDownloadItemRequired] intValue];
    if(forceLoad==0) {
    loadingQueue.delegate = nil;
    [loadingQueue setLazyLoadMode:YES];
    _gSnsItemLoadingQueue = [loadingQueue retain];
    }
#endif
	[loadingQueue startLoading];
	
	NSString *key = kItemFileVerKey;
	NSNumber *ver = [dictionary objectForKey:key];
    [SystemUtils setGlobalSetting:ver forKey:key];
	
#ifdef SNS_ENABLE_LAZY_LOAD_REMOTE_ITEM
    if(forceLoad==0) {
    [self loadDone];
    }
#endif

	// [self loadDone];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	SNSLog(@"- error: %@", error);
	[self loadCancel];
}

#pragma mark -

@end
