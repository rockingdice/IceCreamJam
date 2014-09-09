//
//  SnsGameHelper.m
//  DreamTrain
//
//  Created by XU LE on 12-4-20.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import "SnsGameHelper.h"
#import "SystemUtils.h"
#import "CSVFileRead.h"
#import "SBJson.h"
#import "StringUtils.h"
#import "GameConfig.h"
#import "InAppStore.h"
#import "FacebookHelper.h"
#import "SnsStatsHelper.h"
#import "ASIFormDataRequest.h"

// #import "FlurryHelper2.h"
#ifdef SNS_ENABLE_WEIXIN
#import "WeixinHelper.h"
#endif
#ifdef SNS_ENABLE_MINICLIP
#import "MiniclipHelper.h"
#endif
//#import "Game.h"

@interface SnsGameRequest:ASIFormDataRequest

@property(nonatomic,assign) int req_type;
@property(nonatomic,retain) NSObject *req_data;

@end

@implementation SnsGameRequest

@synthesize req_type, req_data;

- (void) dealloc
{
    self.req_data = nil;
    [super dealloc];
}

@end

enum {
    kSnsDragonRequestTypeLoadContestInfo = 1,  // 加载竞技场信息
    kSnsDragonRequestTypeAttackUser = 2, // 攻击某个玩家
    kSnsDragonRequestTypeLoadBattleList = 3, // 加载最近战斗列表
    kSnsDragonRequestTypeLoadBattleRecord = 4, // 加载某次战斗记录
};

@implementation SnsGameHelper

static SnsGameHelper *_gSnsGameHelper = nil;

+(SnsGameHelper *)helper
{
    if(_gSnsGameHelper == nil) {
        _gSnsGameHelper = [[SnsGameHelper alloc] init];
    }
    
    return _gSnsGameHelper;
}

// 验证加载的存档信息是否有效
+ (BOOL) verifyLoadedSaveInfo:(NSString *)info
{
    if([self parseSaveInfo:info]) return YES;
    return NO;
}

//DES 加密
+ (NSString *) encryptDESData:(NSData *)plainData key:(NSString *)key
{
    char keyPtr[kCCKeySizeDES+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSMutableData * dKey = [[key dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    [dKey setLength:kCCBlockSizeDES];
    
    NSUInteger dataLength = [plainData length];
    size_t bufferSize = dataLength + kCCBlockSizeDES;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding,
                                          [dKey bytes],
                                          kCCKeySizeDES,
                                          [dKey bytes],
                                          [plainData bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        NSData *desData = [[[NSData alloc] initWithBytesNoCopy:buffer length:numBytesEncrypted freeWhenDone:YES] autorelease];
        return [Base64 encode:desData];
    }
    return nil;
}

//DES 解密
+ (NSString *) decryptDES:(NSString *)desStr key:(NSString *)key zip:(int)usezip
{
    NSData * desData = [Base64 decode:desStr];
    char keyPtr[kCCKeySizeDES+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSMutableData * dKey = [[key dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    [dKey setLength:kCCBlockSizeDES];
    
    NSUInteger dataLength = [desData length];
    size_t bufferSize = dataLength + kCCBlockSizeDES;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding,
                                          [dKey bytes],
                                          kCCKeySizeDES,
                                          [dKey bytes],
                                          [desData bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        if (usezip == 1) {
            NSData * zipData = [[[[NSData alloc] initWithBytesNoCopy:buffer length:numBytesDecrypted freeWhenDone:true] autorelease] zlibInflate];
            
            NSString* plainText = [[[NSString alloc] initWithBytes:[zipData bytes] length:[zipData length] encoding:NSUTF8StringEncoding] autorelease];
            return plainText;
        }
        NSString* plainText = [[[NSString alloc] initWithBytesNoCopy:buffer length:numBytesDecrypted encoding:NSUTF8StringEncoding freeWhenDone:YES] autorelease];
        return plainText;
    }
    return nil;
}

- (id) init
{
    self = [super init];
    if(self) {
        showDailyBonus = NO; m_iapItemList = nil; m_extraInfo = nil;
        m_popupShown = 0;
        // register daily prize
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(updateDailyBonusStatus:) 
                                                     name:kSNSNotificationSendDailyRewards 
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(onSendInvitationEmailFinish:) 
                                                     name:kNotificationSendInvitationEmailFinish 
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onLoginFinish:)
                                                     name:kFacebookNotificationOnLoginFinished
                                                   object:nil];
        // kSNSNotificationFileLoadingProgress
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onUpdateRemoteFileLoadingProgress:)
                                                     name:kSNSNotificationFileLoadingProgress
                                                   object:nil];
        
    }
    return self;
}

-(void) dealloc
{
    if(m_iapItemList) {
        [m_iapItemList release];
    }
    if(networkQueue) [networkQueue release];
    // if(stBattleServiceRoot) [stBattleServiceRoot release];
    [super dealloc];
}

// 发放每日奖励
- (void) updateDailyBonusStatus:(NSNotification *)note
{
    showDailyBonus = YES;
}

// 加载IAP列表
- (void) loadIapItemList:(BOOL)forceReload
{
    if(m_iapItemList && !forceReload) return;
    if(m_iapItemList) {
        [m_iapItemList release];
        m_iapItemList = nil;
    }
    NSString *filename = @"IapItemList.csv";
    
	NSDictionary *remoteFiles = [SystemUtils getSystemInfo:kRemoteConfigFileDict];
    NSString *remoteFile = [remoteFiles objectForKey:filename];
    // if(!fileName2) 
    NSString *remoteFilePath = [NSString stringWithFormat:@"%@/%@", [SystemUtils getItemRootPath], remoteFile];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:remoteFilePath]) {   
        // if (0) { 
        // NSString *fileName2 = [[arr objectAtIndex:0] lowercaseString];
        NSString *text = nil;
        NSArray *content = nil;
        text = [NSString stringWithContentsOfFile:remoteFilePath encoding:NSUTF8StringEncoding error:nil];
        if([text characterAtIndex:0]=='|') {
            // 新格式：带验证信息，后面是JSON数组
            if([SystemUtils verifySaveDataWithHash:text]) {
                text = [SystemUtils stripHashFromSaveData:text];
            }
            else {
                text = nil;
            }
        }
        else {
            // 旧格式：JSON数组
        }
        if(text) content = [text JSONValue];
        if(content && [content isKindOfClass:[NSArray class]])
        {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:[content count]];
            for(NSDictionary * v in content) {
                NSString *k = [v objectForKey:@"ID"];
                [dict setValue:v forKey:k];
            }
            m_iapItemList = [dict retain];
        }
        if(m_iapItemList) {
            // 设置IAP道具数量
            GameConfig::setGoldsAmount();
            return;
        }
    }
    
    
    NSString *path = [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:filename];
    
    m_iapItemList = [CSVFileRead readFile:path];
    [m_iapItemList retain];
    // SNSLog(@"iap items:%@", m_iapItemList);
    // 设置IAP道具数量
    GameConfig::setGoldsAmount();
    
}

// 获取IAP道具对应的购买数量
- (int)  getIapItemQuantity:(NSString *)ID
{
    if(m_iapItemList==nil) [self loadIapItemList:NO];
    if(m_iapItemList==nil) return 0;
    NSDictionary *dict = [m_iapItemList objectForKey:ID];
    if(dict==nil) {
        NSArray *arr = [ID componentsSeparatedByString:@"."];
        if([arr count]>1) 
            dict = [m_iapItemList objectForKey:[arr objectAtIndex:[arr count]-1]];
    }
    if(dict==nil || ![dict objectForKey:@"Quantity"]) return 0;
    NSString *q = [dict objectForKey:@"Quantity"];
    return [q intValue];
}

// 获取IAP道具对应的名字
- (NSString *) getIapItemName:(NSString *)ID
{
    if(m_iapItemList==nil) [self loadIapItemList:NO];
    if(m_iapItemList==nil) return nil;
    NSDictionary *dict = [m_iapItemList objectForKey:ID];
    if(dict==nil) {
        NSArray *arr = [ID componentsSeparatedByString:@"."];
        if([arr count]>1)
            dict = [m_iapItemList objectForKey:[arr objectAtIndex:[arr count]-1]];
    }
    if(dict==nil || ![dict objectForKey:@"Quantity"]) return nil;
    return [dict objectForKey:@"ItemName"];
}

// 加载游戏数据
- (void) loadGameData
{
    currentLevelID = 0;
    NSString *file = [SystemUtils getUserSaveFile];
    NSDictionary *dict = nil;
    NSDictionary *dict2 = nil;
    dict2 = [self loadBackupSaveData];
    int backupLevelID = currentLevelID;
    
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:file];
#ifdef DEBUG
    // exist = NO;
#endif
    if(!exist) {
        dict = dict2;
    }
    else {
        NSString *cont = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    // if([SystemUtils checkSaveDataHash:cont]) {
        dict = [SnsGameHelper parseSaveInfo:cont];
        NSString *data = [dict objectForKey:@"gameData"];
        if(![self isGameDataValid:data]) {
            dict = dict2;
        }
        else {
            if(backupLevelID>currentLevelID) dict = dict2;
        }
    // }
    }
    
    if(dict && [dict isKindOfClass:[NSDictionary class]] && [dict objectForKey:@"extInfo"]) {
        m_extraInfo = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:@"extInfo"]];
        [m_extraInfo retain];
        // 检查UID是否一致
        NSString *oldUID = [m_extraInfo objectForKey:@"uid"];
        int uid = [oldUID intValue];
        NSString *curUID = [SystemUtils getCurrentUID];
        if(uid>0 && ![oldUID isEqualToString:curUID]) {
            [m_extraInfo release];
            m_extraInfo = [[NSMutableDictionary alloc] init];
            dict = nil;
        }
    }
    else {
        m_extraInfo = [[NSMutableDictionary alloc] init];
    }
    
    if(dict) {
        NSString *gameData = [dict objectForKey:@"gameData"];
        GameConfig::setGameData([gameData UTF8String]);
    }
    
    [SystemUtils setGameDataDelegate:self];
}


// 发放邀请奖励
- (void) onSendInvitationEmailFinish:(NSNotification *)note
{
    int today = [SystemUtils getCurrentTime]/86400;
    int lastday = [[SystemUtils getNSDefaultObject:@"kInviteEmailDate"] intValue];
    if(lastday < today) {
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:today] forKey:@"kInviteEmailDate"];
        // give prize
        // show notice
        int prize = 1500;
        [self addGameResource:prize ofType:1];
        NSString *coinName = nil;
        coinName = [SystemUtils getLocalizedString:@"CoinName1"];
        coinName = [StringUtils getPluralFormOfWord:coinName];
        
        NSString *title = [SystemUtils getLocalizedString:@"Invitation Bonus"];
        NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Thanks for sending out invitation email, you've got a bonus of %1$d %2$@!"],
                          prize, coinName];
        [SystemUtils showSNSAlert:title message:mesg];
    }
}

- (void) onLoginFinish:(NSNotification *)note
{
    
    int prizeStatus = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"fbConnectPrize"] intValue];
    if(prizeStatus==1) return;
    // FaceBook登陆成功后通知服务器
}

// 发送facebook Feed
- (void) sendFacebookInvitation
{
#ifdef SNS_ENABLE_WEIXIN
    // NSString *country = [SystemUtils getOriginalCountryCode];
    // if([country isEqualToString:@"CN"]) {
        [[WeixinHelper helper] publishNote];
        return;
    // }
#endif
    [[FacebookHelper helper] showFacebookPromotionHint];
}

// facebook登陆成功
- (void) facebooLoginSuccess
{
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:@"kUserDataFetchingNotification"
												  object:nil];
	[self sendFacebookInvitation];
}

// facebookFeed成功
- (void) facebooFeedSuccess
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:kSNSNotificationFacebookFeedSuccess 
												  object:nil];
    
    int today = [SystemUtils getCurrentTime]/86400;
    int lastday = [[SystemUtils getNSDefaultObject:@"kFacebookFeedDate"] intValue];
    if(lastday < today) {
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:today] forKey:@"kFacebookFeedDate"];
        // give prize
        // show notice
        int prize = 1500;
        [self addGameResource:prize ofType:1];
        NSString *coinName = nil;
        coinName = [SystemUtils getLocalizedString:@"CoinName1"];
        coinName = [StringUtils getPluralFormOfWord:coinName];
        
        NSString *title = [SystemUtils getLocalizedString:@"Feed Bonus"];
        NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Thanks for sharing Slots Casino to Facebook, you've got a bonus of %1$d %2$@!"],
                          prize, coinName];
        [SystemUtils showSNSAlert:title message:mesg];
    }
    
}

- (int) getIapItemType:(NSString *)itemName
{
    // if([itemName isEqualToString:@"beans"]) return kGameResourceTypeGold;
    if([itemName isEqualToString:@"gold"]) return kGameResourceTypeGold;
    return 0;
}

#pragma mark GameDataDelegate


// 获取当前等级的IAP金币数量
- (int) getIAPCoinCount:(int)val
{
    NSString *key = [NSString stringWithFormat:@"coin%i",val];
    int count = [self getIapItemQuantity:key];
	
    int promotionRate = [SystemUtils getPromotionRate];
	if(promotionRate > 0) {
		count = count * (10+promotionRate)/10;
	}
    return count;
}

// 获取IAP叶子数量
- (int) getIAPLeafCount:(int)val
{
	//      1 5   10  20 50  100
	// 钻石;10;61;127;280;710;1520
    int leaf = [self getIapItemQuantity:[NSString stringWithFormat:@"gem%i",val]];
    
	int promotionRate = [SystemUtils getPromotionRate];
	if(promotionRate > 0) {
		leaf = leaf * (10+promotionRate)/10;
	}
	return leaf;
}

- (BOOL) isGameDataValid:(NSString *)gameData
{
    if([gameData length]<50) return NO;
    NSDictionary *info = [StringUtils convertJSONStringToObject:gameData];
    if(info==nil || ![info isKindOfClass:[NSDictionary class]]) return NO;
    NSArray *arr = [info objectForKey:@"furthestlevel"];
    if(arr==nil) return NO;
    currentLevelID = [[arr objectAtIndex:0] intValue] * 1000 + [[arr objectAtIndex:1] intValue];
    return YES;
}

// 导出进度信息为字符串
- (NSString *) exportToString
{
    // NSDictionary *info = [NSDictionary dictionaryWithObject:m_gameData forKey:@"SAVEDATA"];
#define GAMEDATA_BUF_SIZE 128000
    char *buf = (char *)malloc(GAMEDATA_BUF_SIZE);
    buf = GameConfig::getGameData(buf,GAMEDATA_BUF_SIZE);
    // std::string stData = GameConfig::getGameData(); // stData.copy(str, strlen(str));
    NSString *gameData = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
    free(buf);
    SNSLog(@"savedata:\n%@",gameData);
    if(![self isGameDataValid:gameData]) return @"";
    // set UID
    if([m_extraInfo objectForKey:@"uid"]==nil) {
        NSString *curUID = [SystemUtils getCurrentUID];
        int val = [curUID integerValue];
        if(val>0) [m_extraInfo setObject:curUID forKey:@"uid"];
    }
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:m_extraInfo,@"extInfo", gameData, @"gameData", nil];
    NSString *text = [StringUtils convertObjectToJSONString:dict];
    if([text isEqualToString:@"{}"]) return @"";
    return [SystemUtils addHashToSaveData:text];
}

// 导入进度信息
- (BOOL) importFromString:(NSString *)str
{
    NSDictionary *dict = [SnsGameHelper parseSaveInfo:str];
    
    if(!dict || ![dict isKindOfClass:[NSDictionary class]]) 
    {
        return NO;
    }
    SNSLog(@"update savefile");
    // save to local file
    NSString *path = [SystemUtils getUserSaveFile];
    BOOL res = [str writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    if(!res) {
        SNSLog(@"failed to write savefile: %@", path);
    }
    return YES;
}

// 从Facebook导入进度
- (void) importFromFBString:(NSString *)str
{
    GameConfig::setGameDataFromFB([str UTF8String]);
}

// 获取本地通知列表
- (NSArray *) getNotificationList
{
	NSMutableArray *notifications = [NSMutableArray array];
	return notifications;
}

// 获取扩展字段
- (id) getExtraInfo:(id)key
{
	return [m_extraInfo objectForKey:key];
}

// 存储扩展字段
- (void) setExtraInfo:(id)val forKey:(id)key
{ 
	if(!m_extraInfo) return;
	[m_extraInfo setValue:val forKey:key];
	// [self saveGame];
}

// 添加游戏资源, type:1-金币，2－叶子，3－经验, 4-等级
- (void) addGameResource:(int)val ofType:(int) type
{
    // 添加游戏资源
    GameConfig::addGameResource(type, val);
	// [SystemUtils runCommand:@"updateUserInfo"];
}

// 获取游戏资源
- (int) getGameResourceOfType:(int) type
{
	// 获取游戏资源, type:1-金币，2－叶子，3－经验，4－等级
    return GameConfig::getGameResource(type);
}


// IAP购买充值, type:1-金币，2－叶子/钻石/糖果，3－活动奖励
- (void) onBuyIAP:(int)val ofType:(int) type
{
    NSString *itemName = nil; int count = val;
    NSString *iapID = nil;
    
    if(type==1) {
        itemName = [SystemUtils getSystemInfo:@"kIapCoinName"];
        // NSString *iapID1 = [NSString stringWithFormat:@"%@%i",itemName,val];
        iapID = [NSString stringWithFormat:@"%@%@%i", [SystemUtils getSystemInfo:@"kIapItemPrefix"], itemName, val];
        count = [self getIapItemQuantity:iapID];
        
        count += [SystemUtils getSpecialIapBonusAmount:iapID withCount:count];
        
        [self addGameResource:count ofType:1];
        [[SnsStatsHelper helper] logResource:kCoinType1 change:count channelType:kResChannelIAP];
    }
    if(type==2) {
        itemName = [SystemUtils getSystemInfo:@"kIapLeafName"];
        // NSString *iapID1 = [NSString stringWithFormat:@"%@%i",itemName,val];
        // count = [self getIapItemQuantity:iapID1];
        iapID = [NSString stringWithFormat:@"%@%@%i", [SystemUtils getSystemInfo:@"kIapItemPrefix"], itemName, val];
        count = [self getIapItemQuantity:iapID];
        
        count += [SystemUtils getSpecialIapBonusAmount:iapID withCount:count];
        
        [self addGameResource:count ofType:2];
        [[SnsStatsHelper helper] logResource:kCoinType2 change:count channelType:kResChannelIAP];
    }
    if(type==3) {
        itemName = [SystemUtils getSystemInfo:@"kIapPromotionName"];
        iapID = [NSString stringWithFormat:@"%@%@%i", [SystemUtils getSystemInfo:@"kIapItemPrefix"], itemName, val];
        GameConfig::purchaseSucceed([iapID UTF8String]);
    }
	// show notice
	NSString *coinName = nil;
	if(type == 1) coinName = [SystemUtils getLocalizedString:@"CoinName1"];
	else coinName  = [SystemUtils getLocalizedString:@"CoinName2"];
    coinName = [StringUtils getPluralFormOfWord:coinName];
    
    NSString * coinCount = [NSString stringWithFormat:@"%d", count];
    
//	NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"You just bought %1$@ %2$@ successfully!"],
//					  coinCount , coinName];
    NSString *mesg = [NSString stringWithFormat:@"You just bought %1$@ %2$@ successfully!",
					  coinCount , coinName];
	[SystemUtils showPaymentNotice:mesg];
}

// 通过IAP购买游戏道具, itemName是道具IAP ID中的道具名，count是数量,itemName+"count"就是IAP中的ID
// 比如 com.topgame.slots.coin10对应的itemName:coin, count:10
- (void) onBuyIAPItem:(NSString *)itemName withCount:(int) count
{
    NSString *iapID = [NSString stringWithFormat:@"%@%@%i", [SystemUtils getSystemInfo:@"kIapItemPrefix"], itemName, count];
    NSString *iapID1 = [NSString stringWithFormat:@"%@%i",itemName,count];
    
    // int count2 = GameConfig::getIapItemCoinNumber([iapID UTF8String]);
    int count2 = [self getIapItemQuantity:iapID];
    int type = [self getIapItemType:itemName];
    if(type>0) {
        
        // check if special offer
        count2 += [SystemUtils getSpecialIapBonusAmount:iapID withCount:count2];
        
        [self addGameResource:count2 ofType:type];
    }
    else {
        GameConfig::purchaseSucceed([iapID1 UTF8String]);
    }
    // NSString *iapID1 = [NSString stringWithFormat:@"%@%i",itemName,count];
    // int count2 = [self getIapItemQuantity:iapID1];
    
    // [[SnsStatsHelper helper] logResource:itemName change:count2 channelType:kResChannelIAP];
    
	// show notice
    NSString *name = [self getIapItemName:iapID];
	NSString *coinName = [SystemUtils getLocalizedString:name];
    if(count2>1)
        coinName = [StringUtils getPluralFormOfWord:coinName];
	
    // no need to show notice for restoring products
    if([InAppStore store].isRestoring) return;
    
	NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"You just bought %1$d %2$@ successfully!"],
					  count2, coinName];
    if([iapID1 isEqualToString:@"upgradelife30"] || [iapID1 isEqualToString:@"upgradelives30"]) {
        mesg = [SystemUtils getLocalizedString:@"You have successfully upgraded max lives to 8 with all lives remaining."]; 
    }
    if([iapID1 isEqualToString:@"superpower1"]) mesg = [SystemUtils getLocalizedString:@"Level unlocked. You have also received 3 QUEST levels."];
    if([itemName isEqualToString:@"gold"]) {
        NSString *fmt = [SystemUtils getLocalizedString:@"You have successfully purchased %d gold."];
        mesg = [NSString stringWithFormat:fmt, count2];
    }
    if([itemName isEqualToString:@"beans"]) {
        NSString *fmt = [SystemUtils getLocalizedString:@"You have successfully purchased %d magic beans."];
        mesg = [NSString stringWithFormat:fmt, count2];
    }
    if([iapID1 isEqualToString:@"move1"] ||
       [iapID1 isEqualToString:@"move2"] ||
       [iapID1 isEqualToString:@"move3"] ||
       [iapID1 isEqualToString:@"move4"] ) mesg = [SystemUtils getLocalizedString:@"Your purchase is successful!"];
    
	[SystemUtils showPaymentNotice:mesg];
}

- (void) onAddItem:(NSString *)itemID withCount:(int)count
{
    if(count==0) return;
    if([itemID isEqualToString:@"dollar"]) 
        GameConfig::addGameResource(1, count);
}

// 是否完成了新手引导
- (BOOL) isTutorialFinished
{
    return YES;
}
// 是否开始了新手教程
- (BOOL) isTutorialStart
{
    return YES;
}

- (void) backupSaveData:(NSString *)data
{
    NSString *path = [SystemUtils getDocumentRootPath];
    int lastBackupID = [[SystemUtils getNSDefaultObject:@"kBackupID"] intValue];
    if(lastBackupID>0) {
        if(lastBackupID>=currentLevelID) return;
    }
    NSString *file = [NSString stringWithFormat:@"%d_save.bak", currentLevelID];
    NSString *filePath = [path stringByAppendingPathComponent:file];
    BOOL res = [data writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    if(res) {
        [SystemUtils setNSDefaultObject:[NSString stringWithFormat:@"%d",currentLevelID] forKey:@"kBackupID"];
        // delete old backup file
        file = [NSString stringWithFormat:@"%d_save.bak", lastBackupID];
        filePath = [path stringByAppendingPathComponent:file];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
}

- (NSDictionary *) loadBackupSaveData
{
    NSString *path = [SystemUtils getDocumentRootPath];
    int levelID = 0; NSString *saveFile = nil;
    NSArray *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for(NSString *file in arr)
    {
        NSArray *arr2 = [file componentsSeparatedByString:@"."];
        if([arr2 count]<2) continue;
        NSString *ext = [arr2 objectAtIndex:1];
        if(![ext isEqualToString:@"bak"]) continue;
        NSString *name = [arr2 objectAtIndex:0];
        NSArray *arr3 = [name componentsSeparatedByString:@"_"];
        if([arr3 count]<2) continue;
        ext = [arr3 objectAtIndex:1];
        if(![ext isEqualToString:@"save"]) continue;
        name = [arr3 objectAtIndex:0];
        int level = [name intValue];
        if(level>levelID) {
            saveFile = file; levelID = level;
        }
    }
    
    NSString *filePath = [path stringByAppendingPathComponent:saveFile];
    NSString *text = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    NSDictionary *dict = [SnsGameHelper parseSaveInfo:text];
    if(dict==nil || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    // check if uid is the same
    if([dict objectForKey:@"extInfo"]) {
        NSDictionary *extInfo = [dict objectForKey:@"extInfo"];
        // 检查UID是否一致
        NSString *oldUID = [extInfo objectForKey:@"uid"];
        int uid = [oldUID intValue];
        NSString *curUID = [SystemUtils getCurrentUID];
        if(uid>0 && ![oldUID isEqualToString:curUID]) {
            // set default UID
            [SystemUtils setCurrentUID:oldUID];
            // show account switch alert
            [SystemUtils showSwitchAccountHint];
            [SystemUtils clearSessionKey];
            dict = nil;
        }
    }
    if(dict!=nil) {
        NSString *data = [dict objectForKey:@"gameData"];
        if(![self isGameDataValid:data]) dict = nil;
    }
    SNSLog(@"back data:%@",dict);
    return dict;

}

// 保存到本地
- (void) saveGame
{
    SNSLog(@"start save game");
    // save to file
    NSString *cont = [self exportToString];
    if(!cont || [cont length]==0) return;
    NSString *path = [SystemUtils getUserSaveFile];
    BOOL res = [cont writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
    if(!res) {
        SNSLog(@"failed to write savefile: %@", path);
    }
    else {
        // [SystemUtils updateSaveDataHash:cont];
        // 先把现有文件备份
        [self backupSaveData:cont];
    }
}


// 是否是当前玩家的进度
- (BOOL) isCurrentPlayer
{
    return YES;
}

// 获取本地通知音效是否开启
- (BOOL) getNotificationSoundOn
{
    return YES;
}


// 解析存档文件
+ (NSMutableDictionary *)parseSaveInfo:(NSString *)text
{
    if([SystemUtils verifySaveDataWithHash:text])
    {
        text = [SystemUtils stripHashFromSaveData:text];
    }
    else {
        text = nil;
    }
    
    NSDictionary *dict = nil;
    if(text) {
        dict = [text JSONValue];
        if(dict && ![dict isKindOfClass:[NSDictionary class]]) dict = nil;
    }
    if(dict && [dict objectForKey:@"gameData"]) {
        return [NSMutableDictionary dictionaryWithDictionary:dict];
    }
    return nil;
}

// 检查是否有未下载的远程道具
- (BOOL) hasUnloadedItems
{ 
    return NO;
}

- (void) onRemoteItemImageLoaded:(NSString *)itemID
{

}

// 更新远程文件的下载进度
- (void) onUpdateRemoteFileLoadingProgress:(NSNotification *)note
{
    if(note.userInfo==nil) return;
    NSString *fileID = [note.userInfo objectForKey:@"itemID"];
    int percent = [[note.userInfo objectForKey:@"percent"] intValue];
    if(fileID==nil) return;
    SNSLog(@"fileID:%@ percent:%d%%",fileID, percent);
    if([fileID rangeOfString:@"WorldMap8"].location==0) {
        // 设置背景图的加载进度,percent
    }
}

#pragma mark -

// 购买某个IAP道具
- (void) buyIapItem:(const char *)itemID
{
    // NSString *itemID2 = [NSString stringWithCString:itemID encoding:NSUTF8StringEncoding];
    NSString *itemID2 = [NSString stringWithFormat:@"%@%s",[SystemUtils getSystemInfo:@"kIapItemPrefix"], itemID];
    BOOL res = [[InAppStore store] buyAppStoreItem:itemID2 amount:1 withDelegate:self];
    if(res) {
        // show loading view
		[SystemUtils showInGameLoadingView];
    }
}

#pragma mark InAppStoreDelegate

// 交易完成通知，应该在这里关闭等候界面
// info中包含两个字段:
// itemId : NSString, 购买的产品ID
// amount : NSNumber, 购买数量
-(void) transactionFinished:(NSDictionary *)info
{
    // hide loading view
    [SystemUtils hideInGameLoadingView];
}
// 交易取消通知，应该在这里关闭等候界面
-(void) transactionCancelled
{
    // hide loading view
    [SystemUtils hideInGameLoadingView];
}


#pragma mark -

#pragma mark Memory Protection
- (void) hashGameData:(char *)hashBuffer
{
	// unsigned char digest[CC_MD5_DIGEST_LENGTH];
    char buffer[256];
    memset(buffer, 0, 256);
	// const char *src = [input bytes];
    int len = GameConfig::dumpProtectedData(buffer, 256);
    // int len = 100;
    const char *secret = "cdwsdf23424";
    memcpy(buffer+len,secret,strlen(secret));
    
	CC_MD5(buffer, len+strlen(secret), (unsigned char *)hashBuffer);
    
}


// 进入后台运行
- (void) onApplicationGoesToBackground
{
    [self hashGameData:data_hash];
}

// 从后台运行恢复
- (void) onApplicationResumeFromBackground
{
    char buffer[CC_MD5_DIGEST_LENGTH];
    [self hashGameData:buffer];
    if(memcmp(buffer, data_hash, CC_MD5_DIGEST_LENGTH)!=0)
    {
        NSLog(@"memery corrupt");
        exit(0);
    }
}

// 获取自己当前登陆的FaceBook帐号信息
+ (NSDictionary *) getFaceBookInfo
{
    return [FacebookHelper helper].fbUserInfo;
}

// 获取好友列表
- (void) onGetAllFacebookFriends:(NSArray *)friends withError:(NSError *)error
{
    if(error!=nil) {
        SNSLog(@"failed to get facebook friends:%@", error);
        return;
    }
#ifdef SNS_SYNCFACEBOOK
    if (![SystemUtils getNSDefaultObject:@"kFBUserToken"]) {
        [[FacebookHelper helper] getUserToken];
    }
#endif
    if(friends ==nil || ![friends isKindOfClass:[NSArray class]] || [friends count]==0) {
        SNSLog(@"no friends count");
        return;
    }
    // convert NSArray to CCArray
    for (NSDictionary *f in friends) {
//        SNSLog(@"I have a friend named %@ with id %@: installed=%@", [f objectForKey:@"name"], [f objectForKey:@"id"], [f objectForKey:@"installed"]);
        [[FacebookHelper helper] loadFacebookIcon:[f objectForKey:@"id"]];
    }
    NSDictionary * userInfo = [NSDictionary dictionaryWithObject:friends forKey:@"friends"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationGetFacebookFrds object:Nil userInfo:userInfo];
}

// 显示广告offer
- (void) showOfferWall:(NSString *)offerType
{
    /*
     if([offerType isEqualToString:@"flurry"]) {
     [[FlurryHelper2 helper] showOffer];
     }
     if([offerType isEqualToString:@"aarki"]) {
     [[AarkiHelper helper] showOfferWall];
     }
     if([offerType isEqualToString:@"sponsorpay"]) {
     // [[SponsorPayHelper helper] showOfferWall];
     }
     */
    [SystemUtils showPopupOfferOfType:offerType];
}


// 显示弹窗广告
- (void) showPopupOffer
{
    /*
    int mode = [[SystemUtils getGlobalSetting:@"kPopupOfferMode"] intValue];
    if(mode!=1 && mode!=2) return;
    if(mode==1) {
        // 一个session只弹一次
        if(m_popupShown>0) return;
    }
     */
    
#ifdef SNS_ENABLE_MINICLIP
    if([[MiniclipHelper helper] showUrgentBoard]) return;
    if([[MiniclipHelper helper] showPopup]) return;
    return;
#endif
    if(![SystemUtils isAdVisible]) return;
    if([SystemUtils shouldIgnoreAd]) return;
    NSString *venderStr = [SystemUtils getGlobalSetting:@"kPopupOfferList"];
    if(venderStr==nil) return;
    int skipCount = 0; NSString *vender = nil;
    NSArray *venderArr = [venderStr componentsSeparatedByString:@","];
    while (m_popupShown<[venderArr count]) {
        vender = [venderArr objectAtIndex:m_popupShown];
        m_popupShown++;
        if(m_popupShown>=[venderArr count]) m_popupShown = 0;
        if([SystemUtils showPopupOfferOfType:vender]) break;
        skipCount++;
        if(skipCount>=[venderArr count]) break;
    }
    SNSLog(@"show offer type: %@", vender);
    
}

#pragma mark -



@end
