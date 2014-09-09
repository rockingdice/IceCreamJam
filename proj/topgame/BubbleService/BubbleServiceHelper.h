//
//  BC_ViewController.h
//  BubbleClient
//
//  Created by LEON on 12-10-26.
//  Copyright (c) 2012年 SNSGAME. All rights reserved.
//
/*
 required framework: libz, MobileCoreServices, CFNetwork, SystemConfiguration
 */

#import "ASIHTTPRequest.h"
#import "ASIHTTPRequestDelegate.h"
#import "ASINetworkQueue.h"

#define TOPFARM_CURRENT_APIVER  3


#define kBubbleServiceNotificationSyncLevelFinished   @"kBubbleServiceNotificationSyncLevelFinished"
#define kBubbleServiceNotificationUploadSubLevelFinished   @"kBubbleServiceNotificationUploadSubLevelFinished"
#define kBubbleServiceNotificationLoadLevelFileFinished   @"kBubbleServiceNotificationLoadLevelFileFinished"

@interface BubbleServiceHelper : NSObject
{
    NSString *stServiceRoot;
    NSString *stLocalSavePath;
    
    NSDictionary *dictConfig;
    NSMutableDictionary *dictLevels;
    // 关卡列表，只包含id和最后更新时间，格式为 [{"id":"1","etime":12345353},{"id":"2","etime":12345353}]
    NSArray  *arrLevelList;
    NSMutableDictionary *dictBlocks;
    
	ASINetworkQueue *networkQueue;
    int  syncStatus;
    int  pendingFileCount;
    BOOL syncSuccess;
    NSString *strSyncMessage;
    
    BOOL uploadSubLevelSuccess;
    NSString *uploadFailedMessage;
    NSString *defaultBlockIDs;
    BOOL _hasUnsupportLevel; // 是否有新的不支持的关卡
    BOOL _isUpdateVersionReady; // 新版是否已经上线了
    NSString *stDownloadServerRoot;
}


+(BubbleServiceHelper *)helper;

- (void) loadLocalLevels;

- (BOOL) hasLocalLevels;

// 获得blockID=1的关卡数量
- (int) getLevelCount;
// 获得某个block的关卡数量
- (int) getLevelCount:(int) blockID;
// 获得block数量
- (int) getBlockCount;
// 获得当前版本blockID的数组，元素为NSString
- (NSArray* )getBlockAry;

// 获得blockID=1下的某个关卡的信息，idx必须小于关卡数量，第一个关卡idx=0，最后一个关卡idx=count-1
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
 "iPhone":"123-2-iPhone.zip", "iPad":"123-3-iPad.zip", "linkPath":"33/"}
 */
- (NSDictionary *) getLevelAtIndex:(NSInteger) idx;
// 获得某个block下第idx号关卡信息
- (NSDictionary *) getLevelAtIndex:(NSInteger) idx ofBlock:(int)blockID;
// 根据关卡内部id获得某个关卡的信息
- (NSDictionary *) getLevelByID:(NSString *)levelID;

// 获得某个关卡的图片所在目录
- (NSString *) getLevelImagePath:(NSString *)levelID;

// 与服务器同步关卡
- (void) startSyncWithServer;
// 与服务器同步关卡，多个blockID用英文逗号分开，比如“1,2,3”
- (void) startSyncWithServer:(NSString *)blockIDs;

// 上传某个子关卡到服务器
// subID:子关卡ID，取值为字符串1-15
// levelID: 关卡ID
// content: 新的关卡内容
// type: 0-subLevel, 1-questLevel
- (void) uploadSubLevel:(NSString *)subID ofLevel:(NSString *)levelID withContent:(NSString *)content andType:(int)type;

- (id) getConfigValue:(NSString *)key;

// 检查是否有新版本
- (BOOL) hasUnsupportLevels;
// 检查是否可以更新
- (BOOL) isUpdateVersionReady;

// 发送闯关数据统计
- (void) reportToStatLevel:(NSString *) data;
// 发送解锁章节统计
- (void) reportToStatUnlockEpisode:(NSString *) data;


@end
