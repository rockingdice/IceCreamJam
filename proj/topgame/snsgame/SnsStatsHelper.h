//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>

// 资源获取与消耗记录
@interface SnsResourceStats : NSObject
{
    int totalGet; // 累计获取
    int totalSpend; // 累计消耗
    NSMutableDictionary *levelsGet; // 每个等级下的累计获取
    NSMutableDictionary *levelsSpend; // 每个等级下的累计消耗
    NSMutableDictionary *channelGet;  // 每个渠道的累计获取
    NSMutableDictionary *channelSpend;  // 每个渠道的累计消耗
}

-(NSDictionary *)exportToDictionary;
-(void) importFromDictionary:(NSDictionary *)dict;

// 设置数据为初始状态
- (void) setDefaultStats;

// 变化记录，num－增加／减少数量，type－渠道类型，level－用户等级
- (void) logChange:(int)num channelType:(int)type atLevel:(int)level;

@end


@interface SnsTimeStats : NSObject
{
    /*
    int installTime; // 注册时间, int
    int lastPlayTime; // 最近一次启动时间, lpt
    int playTimes; // 累计启动次数, pts
    int playSeconds; // 累计玩的时间（秒钟）,pss
    int lastPlayDate; // 上次启动日期，int(lastPlayTime/86400), lpd
    int playDays; // 累计启动天数, pds
     */
}
@property(nonatomic, assign) int installTime; // 注册时间, int
@property(nonatomic, assign) int lastPlayTime; // 最近一次启动时间, lpt
@property(nonatomic, assign) int playTimes; // 累计启动次数, pts
@property(nonatomic, assign) int playSeconds; // 累计玩的时间（秒钟）,pss
@property(nonatomic, assign) int lastPlayDate; // 上次启动日期，int(lastPlayTime/86400), lpd
@property(nonatomic, assign) int playDays; // 累计启动天数, pds

-(NSDictionary *)exportToDictionary;
-(void) importFromDictionary:(NSDictionary *)dict;

// 设置数据为初始状态
- (void) setDefaultStats;

// 记录游戏开始时间
- (void) logStartTime;

// 记录游戏结束时间
- (void) logStopTime;

@end

@interface SnsDailyStats : NSObject
{
    int today;
    int playTimes,playSeconds;
    
    NSMutableDictionary *resInfo; // 资源统计记录, 每个对象都是一个 SnsResourceStats, res
    NSMutableDictionary *achievementInfo; // 成就统计
    NSMutableDictionary *buyItemInfo;  // 道具购买统计
    NSMutableDictionary *actionInfo;   // 行为统计
}

// @property(nonatomic,assign) int today;
@property(nonatomic,retain) NSMutableDictionary *resInfo;
@property(nonatomic,retain) NSMutableDictionary *achievementInfo; // 成就统计
@property(nonatomic,retain) NSMutableDictionary *buyItemInfo;  // 道具购买统计
@property(nonatomic,retain) NSMutableDictionary *actionInfo;   // 行为统计


-(NSDictionary *)exportToDictionary;
-(void) importFromDictionary:(NSDictionary *)dict;

-(void) setDefaultStats;

- (void) logResource:(int)resType change:(int)num channelType:(int)type;
// 道具购买统计
- (void) logBuyItem:(NSString *)itemID count:(int)count cost:(int)cost resType:(int)moneyType itemType:(int)itemType;
// 行为统计，记录累计次数和最后一次操作的时间
// - (void) logAction:(NSString *)actionName;
// 行为统计，记录累计次数和最后一次操作的时间
- (void) logAction:(NSString *)actionName withCount:(int)num;

// 记录本次玩游戏的时间
- (void) logPlayTime:(int)seconds;

@end


@interface SnsStatsHelper : NSObject
{
    BOOL isInitialized;
    
    int isTester; // 是否测试用户
    NSString *uid; // userID
    
    int payTotal; // 累计付费金额, pt
    NSMutableDictionary *payItemInfo; // 每种IAP道具的购买数量, pi
    NSMutableDictionary *resInfo; // 资源统计记录, 每个对象都是一个 SnsResourceStats, res
    NSMutableDictionary *achievementInfo; // 成就统计
    NSMutableDictionary *timeStatInfo; // 内置游戏时间统计
    NSMutableDictionary *buyItemInfo;  // 道具购买统计
    NSMutableDictionary *actionInfo;   // 行为统计
    
    SnsTimeStats *mainTimeStat; // 主游戏时间统计
    int weekHourPlayTime[168]; // 一周内每个小时的累计玩游戏时间(秒钟), whp
    
    SnsDailyStats *dailyStats;
}

+ (SnsStatsHelper *) helper;

- (void) initSession;

// 倒出为字符串
- (NSDictionary *) exportToDictionary;
// 从存档字符串中倒入数据
- (void) importFromDictionary:(NSDictionary *)dict;

// 设置数据为初始状态
- (void) setDefaultStats;

// 重置统计数据，在切换帐号时调用
- (void) resetStats;

// 付费统计, price-用户消费的价格（美分），itemID－道具ID
- (void) logPayment:(int)price withItem:(NSString *)itemID andTransactionID:(NSString *)tid;
// 货币／资源统计，resType－货币类型／资源类型，num－变化数量，正数增加，负数减少，type－渠道类型，消耗渠道和来源渠道
- (void) logResource:(int)resType change:(int)num channelType:(int)type;
// 成就统计，成就只统计一次，已经完成的成就重复调用会直接忽略
- (void) logAchievement:(NSString *)achieveName;
// 道具购买统计, itemID-道具ID，count－购买数量，cost－价格／消耗资源数量，resType－货币类型／消耗资源类型, place-发生此事件的位置
- (void) logBuyItem:(NSString *)itemID count:(int)count cost:(int)cost resType:(int)resType  itemType:(int)itemType placeName:(NSString *)place;
// 道具购买统计, itemID-道具ID，count－购买数量，cost－价格／消耗资源数量，resType－货币类型／消耗资源类型
- (void) logBuyItem:(NSString *)itemID count:(int)count cost:(int)cost resType:(int)resType  itemType:(int)itemType;
// 行为统计，记录累计次数和最后一次操作的时间
- (void) logAction:(NSString *)actionName;
// 行为统计，记录累计次数和最后一次操作的时间
- (void) logAction:(NSString *)actionName withCount:(int)num;

// 记录游戏开始时间
- (void) logStartTime:(NSString *)gameName;

// 记录游戏结束时间
- (void) logStopTime:(NSString *)gameName;

// 设置UID
- (void) setCurrentUID:(NSString *)userID;

// 检查tid是否已经存在
- (BOOL) isTransactionIDExisting:(NSString *)tid;

// 保存到文件
- (void) saveStats;

// 获得总的付费金额, 单位是美分
- (int) getTotalPay;

// 获得安装时间
- (int) getInstallTime;

@end
