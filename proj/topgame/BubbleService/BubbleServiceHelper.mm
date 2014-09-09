//
//  BC_ViewController.m
//  BubbleClient
//
//  Created by LEON on 12-10-26.
//  Copyright (c) 2012年 SNSGAME. All rights reserved.
//

#import "BubbleServiceHelper.h"
#import "ASIFormDataRequest.h"
#import "BubbleServiceUtils.h"
#import "SBJson.h"
// #import "ZBDataManager.h"
#import "BubbleServiceFunction.h"
#import "SystemUtils.h"

enum {
    kSyncStatusNone,
    kSyncStatusLoadingLevels,
    kSyncStatusLoadingLevelFiles,
    kSyncStatusUploadingSubLevel,
};

/***********************************
 ECPurchaseHTTPRequest
 ***********************************/
@interface BubbleServiceHTTPRequest:ASIHTTPRequest{
}
@property(nonatomic,retain) NSString * m_localFilePath;
@end

@implementation BubbleServiceHTTPRequest

@synthesize m_localFilePath;

-(void) dealloc
{
    self.m_localFilePath = nil;
    [super dealloc];
}

@end

@interface BubbleServiceHelper (Network)

- (void)loadLevelsComplete:(ASIHTTPRequest *)request;
- (void)loadLevelsFailed:(ASIHTTPRequest *)request;

- (void) addLoadFileTask:(NSString *)fileName linkPath:(NSString *)link;
- (void)loadLevelFileComplete:(ASIHTTPRequest *)request;
- (void)loadLevelFileFailed:(ASIHTTPRequest *)request;

- (void)uploadSubLevelComplete:(ASIHTTPRequest *)request;
- (void)uploadSubLevelFailed:(ASIHTTPRequest *)request;

@end

@implementation BubbleServiceHelper

static BubbleServiceHelper *_bubbleServiceHelper = nil;


+(BubbleServiceHelper *)helper
{
    if(_bubbleServiceHelper==nil) {
        _bubbleServiceHelper = [[BubbleServiceHelper alloc] init];
    }
    return _bubbleServiceHelper;
}

- (void) initLocalSavePath
{
    // check path
    /*
    NSString *path = [[NSBundle mainBundle] bundlePath];
    path = [path stringByDeletingLastPathComponent];
    // NSString *cachePath = [path stringByAppendingPathComponent:@"Documents/Cache"];
    path = [path stringByAppendingPathComponent:@"Documents"];
     */
    NSString *path = [SystemUtils getDocumentRootPath];
    path = [path stringByAppendingPathComponent:stLocalSavePath];
    stLocalSavePath = [path retain];
}

- (id) getConfigValue:(NSString *)key
{
    if(!key) return nil;
    // NSLog(@"dictConfig: %@",dictConfig);
    return [dictConfig objectForKey:key];
}

- (NSString *) getServiceRoot
{
    if(dictConfig == nil) return nil;
    int useBackupServer = [[SystemUtils getNSDefaultObject:@"kUseBackupBubbleServer"] intValue];
    
    NSString *key1 = @"";
    NSString *key2 = @"";
    NSString *val = nil;

    NSString *country = [SystemUtils getOriginalCountryCode];
    if([country isEqualToString:@"CN"]) {
        key1 = @"kServiceRootChina";
        key2 = @"kServiceRootChinaBackup";
        val = nil;
        if(useBackupServer==1) val = [dictConfig objectForKey:key2];
        if(val==nil) val = [dictConfig objectForKey:key1];
        if(val) return val;
    }
    
    key1 = @"kServiceRoot";
    key2 = @"kServiceRootBackup";
    val = nil;
    if(useBackupServer==1) val = [dictConfig objectForKey:key2];
    if(val==nil) val = [dictConfig objectForKey:key1];
    return val;
}

- (NSString *) getDownloadLinkRoot
{
    if(stDownloadServerRoot!=nil) return stDownloadServerRoot;
    NSString *serverList = [SystemUtils getGlobalSetting:@"kLevelDownloadServerList"];
    if([[SystemUtils getCountryCode] isEqualToString:@"CN"]) {
        NSString *svr2 = [SystemUtils getGlobalSetting:@"kLevelDownloadServerListCN"];
        if(svr2!=nil && [svr2 length]>3) serverList = svr2;
    }
    if(serverList!=nil && [serverList length]>5) {
        NSArray *arr = [serverList componentsSeparatedByString:@","];
        if([arr count]==1) return [arr objectAtIndex:0];
        int idx = rand()%[arr count];
        // http://topfarm.5pop.com:8001/static/upload/level/
        NSString *link = [NSString stringWithFormat:@"http://%@/static/upload/level/", [arr objectAtIndex:idx]];
        stDownloadServerRoot = [link retain];
        return link;
    }
    
    if(dictConfig == nil) return nil;
    
    int useBackupServer = [[SystemUtils getNSDefaultObject:@"kUseBackupBubbleServer"] intValue];
    
    NSString *key1 = @"";
    NSString *key2 = @"";
    NSString *val = nil;
    
    NSString *country = [SystemUtils getOriginalCountryCode];
    if([country isEqualToString:@"CN"]) {
        key1 = @"kDownloadLinkRootChina";
        key2 = @"kDownloadLinkRootChinaBackup";
        val = nil;
        if(useBackupServer==1) val = [dictConfig objectForKey:key2];
        if(val==nil) val = [dictConfig objectForKey:key1];
        if(val) return val;
    }
    
    key1 = @"kDownloadLinkRoot";
    key2 = @"kDownloadLinkRootBackup";
    val = nil;
    if(useBackupServer==1) val = [dictConfig objectForKey:key2];
    if(val==nil) val = [dictConfig objectForKey:key1];
    return val;
}

- (id) init
{
    self = [super init];
    if(self) {
        syncStatus = kSyncStatusNone; pendingFileCount = 0; uploadFailedMessage = nil; uploadSubLevelSuccess = NO;
        _hasUnsupportLevel = NO; _isUpdateVersionReady = NO; stDownloadServerRoot = nil;
        
        arrLevelList = nil; // [[NSArray alloc] init];
        dictLevels = [[NSMutableDictionary alloc] init];
        dictBlocks = [[NSMutableDictionary alloc] init];
        
        dictConfig = [SystemUtils getSystemInfo:@"BubbleServerConfig"];
        if(![dictConfig isKindOfClass:[NSDictionary class]]) dictConfig = nil;
        
        if(dictConfig==nil) {
            NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"BubbleServerConfig.plist"];
            NSFileManager *mgr = [NSFileManager defaultManager];
            if(![mgr fileExistsAtPath:path]) {
                NSLog(@"Oh, config file not found %@", path);
            }
            // load configuration
            dictConfig = [NSDictionary dictionaryWithContentsOfFile:path];
        }
        if(dictConfig == nil) {
            // use default config
            dictConfig = [NSDictionary dictionaryWithObjectsAndKeys:@"http://bubble.myzombiefarm.com/tms/", @"kServiceRoot", @"RemoteLevels", @"kLocalSavePath", @"http://bubble.myzombiefarm.com/static/upload/level/", @"kDownloadLinkRoot", nil];
        }
        
        [dictConfig retain];
        stServiceRoot   = [self getServiceRoot]; [stServiceRoot retain];
        stLocalSavePath = [dictConfig objectForKey:@"kLocalSavePath"];
        [self initLocalSavePath];
        [self loadLocalLevels];
        [self reloadBlocks];
    }
    return self;
}

- (void)dealloc
{
    if(defaultBlockIDs!=nil) [defaultBlockIDs release];
    [stServiceRoot release]; [stLocalSavePath release];
    [dictLevels release]; [arrLevelList release];
    [dictConfig release];
    [networkQueue release]; [dictBlocks release];
    [super dealloc];
}

// 获得某个关卡的图片所在目录
- (NSString *) getLevelImagePath:(NSString *)levelID
{
    return [stLocalSavePath stringByAppendingPathComponent:levelID];
}

- (NSString *) getLevelFile:(NSString *)levelID
{
    return [stLocalSavePath stringByAppendingPathComponent:[levelID stringByAppendingString:@".plist"]];
}

- (void) loadCachedLevelInPackage
{
    NSString *fileName = [dictConfig objectForKey:@"kLocalCacheFile"];
    fileName = [NSString stringWithFormat:@"%@/%@", [NSBundle mainBundle].bundlePath, fileName];
    NSString *str = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
    if(str==nil || [str length]==0) {
        NSLog(@"%s: failed to load cached file:%@",__func__, fileName);
        return;
    }
    NSArray *levels = [str JSONValue];
    if(levels==nil || ![levels isKindOfClass:[NSArray class]] || [levels count]==0) {
        NSLog(@"%s:invalid content of cache file:%@", __func__, levels);
        return;
    }
    [self saveLevelData:levels];
}

- (void) reloadBlocks
{
    // clear old levels
    if([dictLevels count]>0)
        [dictLevels removeAllObjects];
    if ([dictBlocks count] >0)
        [dictBlocks removeAllObjects];
    // init dictBlocks
    for (NSDictionary *levelInfo in arrLevelList) {
        int blockID = [[levelInfo objectForKey:@"blockID"] intValue];
        if(blockID<=0) blockID = 1;
        NSString *bid = [NSString stringWithFormat:@"%d",blockID];
        NSMutableArray *lvs = [dictBlocks objectForKey:bid];
        if(lvs==nil) {
            lvs = [NSMutableArray array];
            [dictBlocks setValue:lvs forKey:bid];
        }
        if (![lvs containsObject:levelInfo])
            [lvs addObject:levelInfo];
    }
    // NSLog(@"dictBlocks:%@",dictBlocks);
    [self checkApiVersion];
}

- (void)checkApiVersion
{
    NSArray* allBlockKeys = [dictBlocks allKeys];
    
    for (NSString* blockKey in allBlockKeys)
    {
        NSArray* blockAry = [dictBlocks objectForKey:blockKey];
        
        NSMutableArray* tmpAry = [[NSMutableArray alloc] initWithArray:blockAry];
        NSMutableArray* retAry = [[NSMutableArray alloc] init];
        int aryCount = [tmpAry count];
        for (int i =0; i < aryCount; ++i)
        {
            NSDictionary* dic = [tmpAry objectAtIndex:i];
            if ([dic isKindOfClass:[NSDictionary class]])
            {
                int apiVersion = [[dic objectForKey:@"apiVer"] intValue];
                if (apiVersion <= TOPFARM_CURRENT_APIVER)
                {
                    [retAry addObject:dic];
                    continue;
                }
                // else
                    // [ZBDataManager sharedInstance].hasNewItemToUpdate = YES;
            }
        }
        
        // if ([ZBDataManager sharedInstance].hasNewItemToUpdate)
        //    [dictBlocks setObject:retAry forKey:blockKey];
        
        [tmpAry release];
        [retAry release];
    }
}



- (void) loadLocalLevels
{
    // check path
    NSString *path = stLocalSavePath;
    NSFileManager *mgr = [NSFileManager defaultManager];
    if(![mgr fileExistsAtPath:path]) {
        [mgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        [SystemUtils setNoBackupPath:path];
        [self loadCachedLevelInPackage];
        return;
    }
    [SystemUtils setNoBackupPath:path];
    // check index file
    NSString *indexFile = [path stringByAppendingPathComponent:@"index.plist"];
    NSArray *arr = nil;
    if([mgr fileExistsAtPath:indexFile])
        arr = [NSArray arrayWithContentsOfFile:indexFile];
    if(arr==nil) {
        [self loadCachedLevelInPackage];
        return;
    }
    if(arrLevelList) [arrLevelList release];
    arrLevelList = [arr retain];
    // 每次新版安装后，会重新读取安装包里的关卡
    NSString *ver = [SystemUtils getNSDefaultObject:@"kBubbleLevelClientVersion"];
    NSString *cver = [SystemUtils getClientVersion];
    if(ver==nil || [ver compare:cver]<0) {
        [SystemUtils setNSDefaultObject:cver forKey:@"kBubbleLevelClientVersion"];
        [self loadCachedLevelInPackage]; return;
    }
}

// 获得关卡数量
- (int) getLevelCount
{
    NSString* idList = [SystemUtils getGlobalSetting:@"kBubbleBlockList"];
    
    if ( nil == idList || [idList isEqualToString:@""])
    {
        idList = @"1";
    }
    
    NSArray* ary = [idList componentsSeparatedByString:@","];
    
    int allCount = 0;
    for (int i = 0; i< [ary count] ; ++i)
    {
        NSString* str = [ary objectAtIndex:i];
        allCount += [self getLevelCount:[str intValue]];
    }
    
    return allCount;//[self getLevelCount:1];
}
// 获得某个block的关卡数量
- (int) getLevelCount:(int) blockID
{
    NSString *bid = [NSString stringWithFormat:@"%d",blockID];
    NSArray *lvs = [dictBlocks objectForKey:bid];
    if(lvs==nil) return 0;
    return [lvs count];
}

// 获取block数量
- (int)getBlockCount
{
    return [[self getBlockAry] count];
}

// 获得当前版本blockID的数组，元素为NSString
- (NSArray* )getBlockAry
{
    NSArray* ary;
    NSString *idList = [SystemUtils getGlobalSetting:@"kBubbleBlockList"];
    
    if ( nil == idList || [idList isEqualToString:@""])
    {
        NSDictionary* dicty = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BubbleBlock" ofType:@"plist"]];
        ary = [dicty objectForKey:@"kBlockIdAry"];
    }
    else
        ary = [idList componentsSeparatedByString:@","];
    
    return ary;
}



// 根据关卡内部id获得某个关卡的信息
- (NSDictionary *) getLevelByID:(NSString *)levelID
{
    NSDictionary *info = [dictLevels objectForKey:levelID];
    if(info) return info;
    // load from level file
    info = [NSDictionary dictionaryWithContentsOfFile:[self getLevelFile:levelID]];
    if(info) [dictLevels setObject:info forKey:levelID];
    return info;
}

// 获得某个关卡的信息，idx必须小于关卡数量，第一个关卡idx=0，最后一个关卡idx=count-1
// 返回的数据格式，注意所有数据类型都是NSString：
// 如果出现数据异常（关卡文件不存在之类的），会返回nil
/* 
 {"id":"123","name":"first level","introduction":"detail info", "etime":"12348343",
   "subLevel1":"sdfsfsfsf",  "subID1":"123",  "subTime1":"1234234",
   "subLevel2":"sdfsfsfsfsf", "subID2":"124", "subTime2":"1234234",
   "subLevel3":"sdfsfsfsfsf", "subID3":"125", "subTime3":"1234234",
   "subLevel4":"sdfsfsfsfsf", "subID4":"126", "subTime4":"1234234",
   "subLevel5":"sdfsfsfsfsf", "subID5":"127", "subTime5":"1234234",
   "subLevel6":"sdfsfsfsfsf", "subID6":"128", "subTime6":"1234234",
   "iPhone":"123-2-iPhone.zip", "iPad":"123-3-iPad.zip", "linkPath":"33/", "subLevelCount":6}
 */
- (NSDictionary *) getLevelAtIndex:(NSInteger) idx
{
    return [self getLevelAtIndex:idx ofBlock:1];
}
- (NSDictionary *) getLevelAtIndex:(NSInteger) idx ofBlock:(int)blockID
{
    NSString *bid = [NSString stringWithFormat:@"%d",blockID];
    NSArray *lvs = [dictBlocks objectForKey:bid];
    if(lvs==nil) return nil;
    [lvs retain];
    if(idx<0 || idx>=[lvs count]) return nil;
    NSDictionary *info = [lvs objectAtIndex:idx];
    NSString *levelID = [info objectForKey:@"id"];
    if(!levelID) return nil;
    NSDictionary * retVal = [self getLevelByID:levelID];
    [lvs release];
    return retVal;
}

// 检查是否有新版本
- (BOOL) hasUnsupportLevels
{
    return _hasUnsupportLevel;
}
// 检查是否可以更新
- (BOOL) isUpdateVersionReady
{
    if(!_hasUnsupportLevel) return NO;
    return _isUpdateVersionReady;
}

#pragma mark sync levels

- (void) checkNetworkQueue
{
	if (!networkQueue) {
		networkQueue = [[ASINetworkQueue alloc] init];
        [networkQueue setDelegate:self];
        [networkQueue setShouldCancelAllRequestsOnFailure:NO];
	}
    
}

// 与服务器同步关卡  
- (void) startSyncWithServer
{
    NSString* idList = [SystemUtils getGlobalSetting:@"kBubbleBlockList"];

    if ( nil == idList || [idList isEqualToString:@""])
    {
        idList = @"1";
    }
    [self startSyncWithServer:idList];
}
// 与服务器同步关卡
- (void) startSyncWithServer:(NSString *)blockIDs
{
#ifdef DEBUG
    NSLog(@"%s: syncStatus:%d", __func__, syncStatus);
#endif
    if(defaultBlockIDs==nil || ![defaultBlockIDs isEqualToString:blockIDs]) {
        if(defaultBlockIDs!=nil) [defaultBlockIDs release];
        defaultBlockIDs = [blockIDs retain];
    }
    if(syncStatus != kSyncStatusNone) return;
    
    syncStatus = kSyncStatusLoadingLevels;
    syncSuccess = NO;
    if(strSyncMessage) {
        [strSyncMessage release];
        strSyncMessage = nil;
    }
    // failed = NO;
    [self checkNetworkQueue];
	// [networkQueue setDownloadProgressDelegate:progressIndicator];
	[networkQueue setRequestDidFinishSelector:@selector(loadLevelsComplete:)];
	[networkQueue setRequestDidFailSelector:@selector(loadLevelsFailed:)];
	// [networkQueue setShowAccurateProgress:[accurateProgress isOn]];
    
    /*
	ASIHTTPRequest *request;
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/images/small-image.jpg"]];
	[request setDownloadDestinationPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"1.png"]];
	[request setDownloadProgressDelegate:imageProgressIndicator1];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"request1" forKey:@"name"]];
	[networkQueue addOperation:request];
	 */
    NSMutableString *levels = [[NSMutableString alloc] initWithString:@""];
    int i=0;
    for (NSDictionary *info in arrLevelList) {
        if(i>0) [levels appendString:@","];
        [levels appendFormat:@"%@:%@",[info objectForKey:@"id"], [info objectForKey:@"etime"]];
        i++;
    }
    
    NSString *time = [NSString stringWithFormat:@"%i",[BubbleServiceUtils getCurrentDeviceTime]];
    NSString *hmac = [BubbleServiceUtils getClientHMAC];
    NSString *text = [NSString stringWithFormat:@"%@-dsfiwerw-%@-%@",time,hmac,levels];
    NSString *hash = [BubbleServiceUtils stringByHashingStringWithSHA1:text];
    NSString *sandbox = @"0";
#ifdef DEBUG
    sandbox = @"1";
#endif
    // NSString *bid = [NSString stringWithFormat:@"%i",blockID];
    NSString *link = [stServiceRoot stringByAppendingString:@"level/sync"];
    NSURL *url = [NSURL URLWithString:link];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod: @"POST"];
    [request addPostValue:time  forKey:@"time"];
    [request addPostValue:hmac  forKey:@"hmac"];
    [request addPostValue:sandbox forKey:@"debug"];
    [request addPostValue:hash   forKey:@"hash"];
    [request addPostValue:levels forKey:@"levels"];
    [request addPostValue:blockIDs forKey:@"bid"];
    [request addPostValue:[BubbleServiceUtils getClientCountry] forKey:@"country"];
    [request addPostValue:[BubbleServiceUtils getClientLanguage] forKey:@"lang"];
    [request addPostValue:[BubbleServiceUtils getClientVersion] forKey:@"ver"];
    [request addPostValue:[BubbleServiceUtils getDeviceModel]   forKey:@"model"];
	[request setTimeOutSeconds:10.0f];
	[request buildPostBody];
	request.shouldContinueWhenAppEntersBackground = YES;
    [networkQueue addOperation:request];
	// [request setDelegate:self];
    // [request startAsynchronous];
    [networkQueue go];
    
#ifdef DEBUG
    NSLog(@"%s: %@\ndata:%s", __func__, link, [request postBody].bytes);
#endif
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex==1)
        [self startSyncWithServer:defaultBlockIDs];
    else {
        exit(0);
    }
}

- (BOOL) hasLocalLevels
{
    if(arrLevelList==nil || [arrLevelList count]==0) return NO;
    
    return YES;
}

- (void) syncFinished
{
    syncStatus = kSyncStatusNone;
    // post notification
    NSString *mesg = @"Bubble Dash requires Internet access.";
    if(strSyncMessage) {
        mesg = strSyncMessage;
    }
    
    if(![self hasLocalLevels]) {
        // show no level alert
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Network Required" message:mesg delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry",nil] autorelease];
        [alertView show];
        return;
    }
    
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:syncSuccess], @"success", mesg, @"mesg", nil];
    NSNotification *note = [NSNotification notificationWithName:kBubbleServiceNotificationSyncLevelFinished object:nil userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotification:note];
    if(strSyncMessage) {
        [strSyncMessage release]; strSyncMessage = nil;
    }
    
    BubbleServiceFunction_onLoadLevelComplete();

#ifdef DEBUG
    // test stats send
    BubbleLevelStatInfo *p = new BubbleLevelStatInfo();
    sprintf(p->levelIndex,"test");
    p->levelID = 1; p->success = 0; p->score = 123;
    BubbleServiceFunction_sendLevelStats(p);
    delete p;
    
    BubbleUnlockEpisodeStatInfo *p1 = new BubbleUnlockEpisodeStatInfo();
    p1->episodeIndex = 1;
    p1->episodeID = 1; p1->passUnlockLevelCount = 3; p1->useLifeCount = 5;
    p1->buyUnlockIAP = 0; p1->delayTime = 10234;
    BubbleServiceFunction_sendEpisodeStats(p1);
    delete p1;
    
#endif
}

- (void)loadLevelsComplete:(ASIHTTPRequest *)request
{
    
    if(stDownloadServerRoot!=nil) {
        [stDownloadServerRoot release]; stDownloadServerRoot = nil;
    }
    
    if(request.responseStatusCode!=200) {
#ifdef DEBUG
        NSLog(@"%s: download failed, status: %@ resp:%@", __func__, request.responseStatusMessage, [request responseString]);
#endif
        strSyncMessage = [[request responseStatusMessage] retain];
        [self syncFinished];
        return;
    }
    
    NSData *data = [request responseData];
    if(!data || [data length]<=0) {
        strSyncMessage = @"Empty response from server!";
        [strSyncMessage retain];
        [self syncFinished];
        return;
    }
    
    NSString *respText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#ifdef DEBUG
    SNSLog(@"%@", respText);
#endif
    
    
    NSArray *arr = [respText JSONValue];
    if(!arr || ![arr isKindOfClass:[NSArray class]] || [arr count]==0) {
        strSyncMessage = [respText retain];
        [self syncFinished]; return;
    }
    
    pendingFileCount = 0;
    
    [self saveLevelData:arr];
    [self reloadBlocks];

    // [[ZBDataManager sharedInstance] loadFromServerDataWithBlockId:[ZBDataManager sharedInstance].curBlockID];
    
#ifdef DEBUG
    int levelCount = [self getLevelCount];
    NSLog(@"%s: levelCount=%d", __func__, levelCount);
    for(int i=0;i<levelCount;i++) {
        NSDictionary *d = [self getLevelAtIndex:i];
        NSLog(@"level at #%d:\n%@",i, d);
    }
#endif
    
    syncSuccess = YES;

#ifndef SNS_BUBBLE_SERVICE_DISABLE_LOAD_IMAGE
    // 检查缺失的资源文件并重新下载
    if(pendingFileCount==0) {
        NSFileManager *mgr = [NSFileManager defaultManager];
        for(NSDictionary *info2 in arrLevelList) {
            NSString *levelID = [info2 objectForKey:@"id"];
            NSString *path = [self getLevelImagePath:levelID];
            if([mgr fileExistsAtPath:path]) continue;
            // 资源丢失，尝试下载
            NSDictionary *info = [self getLevelByID:levelID];
            if(!info) continue;
            // 检查图片资源文件是否存在
            NSString *zipFile = [info objectForKey:@"iPhone"];
            int deviceType = [BubbleServiceUtils getDeviceType];
            if(deviceType == 0 &&  UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                zipFile = [info objectForKey:@"iPad"];
            else if (deviceType == 2)
                zipFile = [info objectForKey:@"iPad"];
            
            if(![[NSFileManager defaultManager] fileExistsAtPath:[stLocalSavePath stringByAppendingPathComponent:zipFile]])
            {
                // 需要下载图片
                [self addLoadFileTask:zipFile linkPath:[info objectForKey:@"linkPath"]];
                pendingFileCount++;
            }
        }
    }
#endif
    if(pendingFileCount>0)
    {
        [networkQueue setRequestDidFinishSelector:@selector(loadLevelFileComplete:)];
        [networkQueue setRequestDidFailSelector:@selector(loadLevelFileFailed:)];
        syncStatus = kSyncStatusLoadingLevelFiles;
        [networkQueue go];
    }
    
    [self syncFinished];
}

- (void) saveLevelData:(NSArray *)arr
{
    NSMutableArray *arrLevelNew = [[NSMutableArray alloc] initWithCapacity:[arr count]];
    for(NSDictionary *info in arr)
    {
        if(![info isKindOfClass:[NSDictionary class]]) continue;
#ifdef DEBUG
        // NSLog(@"%s:%@",__func__, info);
#endif
        if([[info objectForKey:@"apiVer"] intValue]>TOPFARM_CURRENT_APIVER) {
#ifdef DEBUG
            NSLog(@"%s unsupport level:%@",__func__, [info objectForKey:@"id"]);
#endif
            NSString *subIDs = [info objectForKey:@"subAppID"];
            _isUpdateVersionReady = NO;
            int subID = [[SystemUtils getSystemInfo:@"kSubAppID"] intValue];
            if(subIDs!=nil && [subIDs length]>0) {
                NSArray *arr = [subIDs componentsSeparatedByString:@","];
                for(NSString *str in arr) {
                    if([str length]>0 && subID==[str intValue]) {
                        _isUpdateVersionReady = YES;
                    }
                }
            }
            _hasUnsupportLevel = YES; break;
        }
        if([info objectForKey:@"subLevel1"]) {
            // update detail
            NSString *levelID = [info objectForKey:@"id"];
            if([dictLevels objectForKey:levelID])
                [dictLevels setValue:info forKey:levelID];
            // save to local file
            [info writeToFile:[self getLevelFile:levelID] atomically:YES];
            
#ifndef SNS_BUBBLE_SERVICE_DISABLE_LOAD_IMAGE
            // 检查图片资源文件是否存在
            NSString *zipFile = [info objectForKey:@"iPhone"];
            
            int deviceType = [BubbleServiceUtils getDeviceType];
            if(deviceType == 0 &&  UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                zipFile = [info objectForKey:@"iPad"];
            else if(deviceType == 2)
                zipFile = [info objectForKey:@"iPad"];
            
            if(![[NSFileManager defaultManager] fileExistsAtPath:[stLocalSavePath stringByAppendingPathComponent:zipFile]])
            {
                // 需要下载图片
                [self addLoadFileTask:zipFile linkPath:[info objectForKey:@"linkPath"]];
                pendingFileCount++;
            }
#endif
            NSDictionary *info2 = [NSDictionary dictionaryWithObjectsAndKeys:levelID, @"id", [info objectForKey:@"etime"], @"etime", [info objectForKey:@"blockID"],@"blockID", [info objectForKey:@"apiVer"],@"apiVer", [info objectForKey:@"subLevelCount"], @"subLevelCount", [info objectForKey:@"unlockLevelCount"],@"unlockLevelCount", nil];

            [arrLevelNew addObject:info2];
        }
        else {
            [arrLevelNew addObject:info];
        }
        
    }
    
    // 如果本地关卡比服务器端的要多，就保留多出来的本地关卡
    if([arrLevelNew count]<[arrLevelList count]) {
        // append local new levels to the list
        for(int i=[arrLevelNew count];i<[arrLevelList count];i++) {
            [arrLevelNew addObject:[arrLevelList objectAtIndex:i]];
        }
    }
    
    [arrLevelList release];
    arrLevelList = arrLevelNew;

    // save to local file
    NSString *indexFile = [stLocalSavePath stringByAppendingPathComponent:@"index.plist"];
    [arrLevelNew writeToFile:indexFile atomically:YES];
    
    SNSLog(@"%d levels saved.", [arrLevelNew count]);
    
    
}

- (void)loadLevelsFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
#ifdef DEBUG
	NSLog(@"%s - error: %@", __FUNCTION__, error);
#endif
    if(error.code == 2 && [error.domain isEqualToString:@"ASIHTTPRequestErrorDomain"])
    {
        int useBackupServer = [[SystemUtils getNSDefaultObject:@"kUseBackupBubbleServer"] intValue];
        if(useBackupServer==1) useBackupServer = 0;
        else useBackupServer = 1;
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:useBackupServer] forKey:@"kUseBackupBubbleServer"];
        [stServiceRoot release];
        stServiceRoot = [self getServiceRoot]; [stServiceRoot retain];
    }
    
    [self syncFinished];
}

- (void) addLoadFileTask:(NSString *)fileName linkPath:(NSString *)linkPath
{
    NSString *linkRoot = [self getDownloadLinkRoot];
    NSString *link = [linkRoot stringByAppendingFormat:@"%@%@",linkPath, fileName];
    NSString *localFile = [stLocalSavePath stringByAppendingPathComponent:fileName];
	ASIHTTPRequest *request;
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:link]];
	[request setDownloadDestinationPath:localFile];
    // request.m_localFilePath = localFile;
    [request setTimeOutSeconds:10.0f];
    // [request setDownloadProgressDelegate:imageProgressIndicator1];
    // [request setUserInfo:[NSDictionary dictionaryWithObject:@"request1" forKey:@"name"]];
	[networkQueue addOperation:request];
}
- (void)loadLevelFileComplete:(ASIHTTPRequest *)request
{
    if(request.responseStatusCode!=200) {
#ifdef DEBUG
        NSLog(@"%s: download failed, status: %@ file:%@", __func__, request.responseStatusMessage, [request.url absoluteString]);
#endif
        [[NSFileManager defaultManager] removeItemAtPath:[request downloadDestinationPath] error:nil];
        pendingFileCount--;
        if(pendingFileCount==0) [self syncFinished];
        return;
    }
    NSData *data = [request responseData];
#ifdef DEBUG
    NSLog(@"%s: download ok %@ datalen:%i pending:%i", __func__, [request url].absoluteString, [data length], pendingFileCount-1);
#endif
    // unzip file
    // BubbleServiceHTTPRequest *req2 = request;
    NSString *zipFile = [request downloadDestinationPath];
    [data writeToFile:zipFile atomically:NO];
    NSString *fileName = [zipFile lastPathComponent];
    NSRange r = [fileName rangeOfString:@"-"];
    NSString *levelID = [fileName substringToIndex:r.location];
    NSString *levelPath = [self getLevelImagePath:levelID];
    NSFileManager *mgr = [NSFileManager defaultManager];
    BOOL emptyPath = NO;
    if(![mgr fileExistsAtPath:levelPath]) {
        [mgr createDirectoryAtPath:levelPath withIntermediateDirectories:YES attributes:nil error:nil];
        emptyPath = YES;
    }
    
    BOOL res = [BubbleServiceUtils unzipFile:zipFile toPath:levelPath];
    if(res) {
#ifdef DEBUG
        NSLog(@"succeed unzip file %@ to path: %@", zipFile, levelPath);
#else
        // truncate the zip file to save space
        NSData *emptyData = [[NSData alloc] init];
        [emptyData writeToFile:zipFile atomically:NO];
        [emptyData release];
#endif
        // send notification, kBubbleServiceNotificationLoadLevelFileFinished
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: levelID, @"levelID", nil];
        NSNotification *note = [NSNotification notificationWithName:kBubbleServiceNotificationLoadLevelFileFinished object:nil userInfo:info];
        [[NSNotificationCenter defaultCenter] postNotification:note];
        
    }
    else {
#ifdef DEBUG
        NSLog(@"failed to unzip file %@ to path: %@", zipFile, levelPath);
#endif
        if(emptyPath)
            [mgr removeItemAtPath:levelPath error:nil];
    }
    
    pendingFileCount--;
    // if(pendingFileCount==0) [self syncFinished];
}

- (void)loadLevelFileFailed:(ASIHTTPRequest *)request
{
#ifdef DEBUG
    NSLog(@"%s: %@ file:%@ pending:%i", __func__, [request error], [request.url absoluteString], pendingFileCount-1);
#endif
    pendingFileCount--;
    // if(pendingFileCount==0) [self syncFinished];
}

/*
- (void)loadLevelsComplete:(ASIHTTPRequest *)request
{
	UIImage *img = [UIImage imageWithContentsOfFile:[request downloadDestinationPath]];
	if (img) {
		if ([imageView1 image]) {
			if ([imageView2 image]) {
				[imageView3 setImage:img];
			} else {
				[imageView2 setImage:img];
			}
		} else {
			[imageView1 setImage:img];
		}
	}
}

- (void)loadLevelsFailed:(ASIHTTPRequest *)request
{
	if (!failed) {
		if ([[request error] domain] != NetworkRequestErrorDomain || [[request error] code] != ASIRequestCancelledErrorType) {
			UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Download failed" message:@"Failed to download images" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
			[alertView show];
		}
		failed = YES;
	}
}
 */


- (void) uploadSubLevelFinished
{
    syncStatus = kSyncStatusNone;
    NSString *mesg = @"";
    if(uploadFailedMessage) mesg = uploadFailedMessage;
    // post notification
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:uploadSubLevelSuccess], @"success", mesg, @"mesg", nil];
    NSNotification *note = [NSNotification notificationWithName:kBubbleServiceNotificationUploadSubLevelFinished object:nil userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotification:note];
    
    if(uploadFailedMessage) {
        [uploadFailedMessage release];
        uploadFailedMessage = nil;
    }
}

// 上传某个子关卡到服务器
// subID:子关卡ID，取值为字符串1-15
// levelID: 关卡ID
// content: 新的关卡内容
// type: 0-子关卡，1-解锁关卡
- (void) uploadSubLevel:(NSString *)subID ofLevel:(NSString *)levelID withContent:(NSString *)content andType:(int)type
{
    [self checkNetworkQueue];
    
    uploadSubLevelSuccess = NO;
    
    if(!subID || !levelID || !content) {
#ifdef DEBUG
        NSLog(@"%s: invalid parameter. subID: %@ levelID:%@ content:%@", __func__, subID, levelID, content);
#endif
        [self uploadSubLevelFinished]; return;
    }
    
    NSDictionary *info = nil;
    info = [dictLevels objectForKey:levelID];
    if(!info) {
        // load from level file
        info = [NSDictionary dictionaryWithContentsOfFile:[self getLevelFile:levelID]];
        if(info) [dictLevels setObject:info forKey:levelID];
        else {
#ifdef DEBUG
            NSLog(@"can't load level info: %@", [self getLevelFile:levelID]);
#endif
        }
    }
    if(!info) {
        uploadFailedMessage = @"Failed to load Level Info.";
        [uploadFailedMessage retain];
        [self uploadSubLevelFinished]; return;
    }
    NSString *key = [NSString stringWithFormat:@"subLevel%@",subID];
    if(type==1) key = [NSString stringWithFormat:@"unlockLevel%@",subID];
    if([content isEqualToString:[info objectForKey:key]]) {
#ifdef DEBUG
        NSLog(@"content not changed");
#endif
        uploadFailedMessage = @"content is the same as stored.";
        [uploadFailedMessage retain];
        uploadSubLevelSuccess = YES;
        [self uploadSubLevelFinished];
        return;
    }
    NSString *subLevelID = [info objectForKey:[NSString stringWithFormat:@"subID%@",subID]];
    NSString *subTime = [info objectForKey:[NSString stringWithFormat:@"subTime%@",subID]];
    if(type==1) {
        subLevelID = [info objectForKey:[NSString stringWithFormat:@"unlockID%@",subID]];
        subTime = [info objectForKey:[NSString stringWithFormat:@"unlockTime%@",subID]];
    }
    if(!subTime) subTime = @"0";
    
    // save local file
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:info];
    [dict setObject:content forKey:@"pendingContent"];
    [dict setObject:key forKey:@"pendingKey"];
    [dictLevels setObject:dict  forKey:levelID];
    [dict writeToFile:[self getLevelFile:levelID] atomically:YES];
    
    
    // start upload
    syncStatus = kSyncStatusUploadingSubLevel;
    [networkQueue setRequestDidFinishSelector:@selector(uploadSubLevelComplete:)];
    [networkQueue setRequestDidFailSelector:@selector(uploadSubLevelFailed:)];
    // [networkQueue setDelegate:self];
    
    NSString *time = [NSString stringWithFormat:@"%i",[BubbleServiceUtils getCurrentDeviceTime]];
    NSString *hmac = [BubbleServiceUtils getClientHMAC];
    NSString *adid = [SystemUtils getIDFA];
    if([hmac isEqualToString:@"020000000000"])
        if(adid!=nil && [adid length]>0 && ![adid isEqualToString:@"00000000-0000-0000-0000-000000000000"]) hmac = adid;
    NSString *text = [NSString stringWithFormat:@"%@-dsfiwerw-%@-%@",time,hmac,subLevelID];
    NSString *hash = [BubbleServiceUtils stringByHashingStringWithSHA1:text];
    NSString *sandbox = @"0";
#ifdef DEBUG
    sandbox = @"1";
#endif
    NSString *link = [stServiceRoot stringByAppendingString:@"level/upload"];
    NSURL *url = [NSURL URLWithString:link];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod: @"POST"];
    [request addPostValue:time  forKey:@"time"];
    [request addPostValue:hmac  forKey:@"hmac"];
    [request addPostValue:sandbox forKey:@"debug"];
    [request addPostValue:hash   forKey:@"hash"];
    [request addPostValue:levelID forKey:@"levelID"];
    [request addPostValue:subLevelID forKey:@"subID"];
    [request addPostValue:subTime forKey:@"subTime"];
    [request addPostValue:content forKey:@"content"];
    [request addPostValue:[NSString stringWithFormat:@"%d",type] forKey:@"subType"];
    [request addPostValue:[BubbleServiceUtils getClientCountry] forKey:@"country"];
    [request addPostValue:[BubbleServiceUtils getClientLanguage] forKey:@"lang"];
    [request addPostValue:[BubbleServiceUtils getClientVersion] forKey:@"ver"];
    [request addPostValue:[BubbleServiceUtils getDeviceModel]   forKey:@"model"];
	[request setTimeOutSeconds:10.0f];
	[request buildPostBody];
	request.shouldContinueWhenAppEntersBackground = YES;
    [networkQueue addOperation:request];
	// [request setDelegate:self];
    // [request startAsynchronous];
    [networkQueue go];
    
#ifdef DEBUG
    NSLog(@"%s: hmac: %@ url: %@", __func__, hmac, link);
#endif
    
}

- (void)uploadSubLevelComplete:(ASIHTTPRequest *)request
{
    if(request.responseStatusCode!=200) {
#ifdef DEBUG
        NSLog(@"%s: download failed, status: %@ resp:%@", __func__, request.responseStatusMessage, [request responseString]);
#endif
        uploadFailedMessage = [request.responseStatusMessage retain];
        [self uploadSubLevelFinished];
        return;
    }
#ifdef DEBUG
    NSLog(@"%s: upload ok %@", __func__, [request url].absoluteString);
#endif
    NSData *data = [request responseData];
    if(!data || [data length]<=0) {
        uploadFailedMessage = @"No response from server!";
        [uploadFailedMessage retain];
        [self uploadSubLevelFinished];
        return;
    }
    
    NSString *respText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#ifdef DEBUG
    NSLog(@"%s: %@", __func__, respText);
#endif
    
    // response format: {"success":1,"id":"1234","etime":"234234"}
    NSDictionary *dict = [respText JSONValue];
    if(!dict || ![dict isKindOfClass:[NSDictionary class]])
    {
        uploadFailedMessage = respText;
        [uploadFailedMessage retain];
        [self uploadSubLevelFinished];
        return;
    }
    
    uploadFailedMessage = [dict objectForKey:@"mesg"];
    if(uploadFailedMessage) [uploadFailedMessage retain];
    
    if([[dict objectForKey:@"success"] intValue]!=1) {
        [self uploadSubLevelFinished];
        return;
    }
    
    // update etime of local info
    NSString *etime = [dict objectForKey:@"etime"];
    NSString *subTime = [dict objectForKey:@"subTime"];
    NSString *subID   = [dict objectForKey:@"subID"];
    NSString *levelID = [dict objectForKey:@"id"];
    int subType   = [[dict objectForKey:@"subType"] intValue];
    NSMutableDictionary *info = [dictLevels objectForKey:levelID];
    if(![info isKindOfClass:[NSMutableDictionary class]]) {
        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:info];
        info = d;
        [dictLevels setValue:info forKey:levelID];
    }
    [info setObject:etime forKey:@"etime"];
    NSString *key = [info objectForKey:@"pendingKey"];
    NSString *cont = [info objectForKey:@"pendingContent"];
    if(key!=nil && cont!=nil) {
        [info setValue:cont forKey:key];
        [info removeObjectForKey:@"pendingKey"];
        [info removeObjectForKey:@"pendingContent"];
    }
    if(subType==0) {
        // update subTime
        for (int i=1; i<=15; i++) {
            NSString *key2 = [NSString stringWithFormat:@"subID%i",i];
            if([info objectForKey:key2]!=nil && [subID isEqualToString:[info objectForKey:key2]])
            {
                key2 = [NSString stringWithFormat:@"subTime%i",i];
                [info setValue:subTime forKey:key2];
                break;
            }
        }
    }
    else {
        // update unlockTime
        for (int i=1; i<=3; i++) {
            NSString *key2 = [NSString stringWithFormat:@"unlockID%i",i];
            if([info objectForKey:key2]!=nil && [subID isEqualToString:[info objectForKey:key2]])
            {
                key2 = [NSString stringWithFormat:@"unlockTime%i",i];
                [info setValue:subTime forKey:key2];
                break;
            }
        }
    }
    [info writeToFile:[self getLevelFile:levelID] atomically:YES];
    
    // update arrLevelList
    NSMutableArray *arr = arrLevelList;
    if(![arr isKindOfClass:[NSMutableArray class]]) {
        arr = [NSMutableArray arrayWithArray:arrLevelList];
        [arrLevelList release];
        arrLevelList = [arr retain];
    }
    int i = 0;
    for(i=0;i<[arr count];i++)
    {
        NSDictionary *d = [arr objectAtIndex:i];
        if([levelID isEqualToString:[d objectForKey:@"id"]])
        {
            NSMutableDictionary *d1 = [NSMutableDictionary dictionaryWithDictionary:d];
            [d1 setValue:etime forKey:@"etime"];
            // d = [NSDictionary dictionaryWithObjectsAndKeys:levelID,@"id", etime, @"etime", nil];
            [arr replaceObjectAtIndex:i withObject:d1];
            break;
        }
    }
    
    uploadSubLevelSuccess = YES;
    [self uploadSubLevelFinished];
}
- (void)uploadSubLevelFailed:(ASIHTTPRequest *)request
{
#ifdef DEBUG
    NSLog(@"%s: %@ link:%@", __func__, [request error], [request.url absoluteString]);
#endif
    uploadFailedMessage = [NSString stringWithFormat:@"%@", [request error]];
    [uploadFailedMessage retain];
    [self uploadSubLevelFinished];
}

#pragma mark -

#pragma mark Reporting

- (void) reportToStatLevel:(NSString *) data
{
    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *data2 = [NSString stringWithString:data];
    NSString *statLink = [SystemUtils getSystemInfo:@"kTopStatLinkRoot"];
    NSString *appID = [SystemUtils getSystemInfo:@"kTopStatAppID"];
    if(statLink==nil || [statLink length]<10 || appID==nil || [appID length]<2) {
        [pool release];
        return;
    }
    statLink = [statLink stringByAppendingString:@"statFinishLevel.php"];
    
    // NSString *isNew = @"0";
    // if([isNewUser boolValue]) isNew = @"1";
    
	NSString *country = [SystemUtils getCountryCode];
	NSString *clientVer = [SystemUtils getClientVersion];
	NSString *userID = [SystemUtils getCurrentUID];
    NSString *subID = [SystemUtils getSystemInfo:@"kSubAppID"];
    if(!subID) subID = @"0";
	NSString *isTestUser = @"0";
#ifdef DEBUG
	isTestUser = @"1";
#endif
    
    
	NSURL *url = [NSURL URLWithString:statLink];
    
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
	[request addPostValue:appID forKey:@"appID"];
	// [request addPostValue:isNew forKey:@"isNewUser"];
	[request addPostValue:country forKey:@"country"];
	[request addPostValue:isTestUser forKey:@"isTestUser"];
	[request addPostValue:userID forKey:@"userID"];
	[request addPostValue:clientVer forKey:@"clientVer"];
	[request addPostValue:subID forKey:@"subID"];
	[request addPostValue:@"0" forKey:@"osType"];
	[request addPostValue:data2 forKey:@"data"];
    
	[request setTimeOutSeconds:10.0f];
	[request buildPostBody];
#ifdef DEBUG
	NSLog(@"%s: url:%@\npost len:%i data: %s", __func__, statLink, [request postBody].length, [request postBody].bytes);
#endif
    [request startSynchronous];
#ifdef DEBUG
    NSLog(@"%s: response: %@",__func__, [request responseString]);
#endif
	[pool release];
}


- (void) reportToStatUnlockEpisode:(NSString *) data
{
    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *data2 = [NSString stringWithString:data];
    NSString *statLink = [SystemUtils getSystemInfo:@"kTopStatLinkRoot"];
    NSString *appID = [SystemUtils getSystemInfo:@"kTopStatAppID"];
    if(statLink==nil || [statLink length]<10 || appID==nil || [appID length]<2) {
        [pool release];
        return;
    }
    statLink = [statLink stringByAppendingString:@"statUnlockEpisode.php"];
    
    // NSString *isNew = @"0";
    // if([isNewUser boolValue]) isNew = @"1";
    
	NSString *country = [SystemUtils getCountryCode];
	NSString *clientVer = [SystemUtils getClientVersion];
	NSString *userID = [SystemUtils getCurrentUID];
    NSString *subID = [SystemUtils getSystemInfo:@"kSubAppID"];
    if(!subID) subID = @"0";
	NSString *isTestUser = @"0";
#ifdef DEBUG
	isTestUser = @"1";
#endif
    
    
	NSURL *url = [NSURL URLWithString:statLink];
    
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
	[request addPostValue:appID forKey:@"appID"];
	// [request addPostValue:isNew forKey:@"isNewUser"];
	[request addPostValue:country forKey:@"country"];
	[request addPostValue:isTestUser forKey:@"isTestUser"];
	[request addPostValue:userID forKey:@"userID"];
	[request addPostValue:clientVer forKey:@"clientVer"];
	[request addPostValue:subID forKey:@"subID"];
	[request addPostValue:@"0" forKey:@"osType"];
	[request addPostValue:data2 forKey:@"data"];
    
	[request setTimeOutSeconds:10.0f];
	[request buildPostBody];
#ifdef DEBUG
	NSLog(@"%s: url:%@\npost len:%i data: %s", __func__, statLink, [request postBody].length, [request postBody].bytes);
#endif
    [request startSynchronous];
#ifdef DEBUG
    NSLog(@"%s: response: %@",__func__, [request responseString]);
#endif
	[pool release];
}


@end
