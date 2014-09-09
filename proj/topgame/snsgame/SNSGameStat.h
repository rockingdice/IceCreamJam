//
//  SNSGameStat.h
//  TapCar
//
//  Created by XU LE on 12-2-13.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SNSGameStat : NSObject
{
    NSString *userID; 
    int updateDate; // 更新日期，110216
    int userExp; // 用户当前经验值
    
    int installTime; // 安装时间
    int timeSinceInstall;// 到现在的安装天数
    int sessionStartTime; // 启动游戏的时间
    
    int playCount;// 玩游戏次数
    int playTime;// 玩游戏累计时间
    
    int payTotal;// 累计支付金额，美分
    int payCount;// 累计支付次数
    int payLastTime; // 最后一次支付时间
    
    NSMutableDictionary *levelUpInfo; // 升级信息
    NSMutableDictionary *buyItems; // 道具购买信息
    NSMutableDictionary *resourceLog; // 资源变化记录
    NSMutableArray *paymentInfo;  // 支付信息
    NSMutableDictionary *miniGameInfo; // 玩小游戏信息
    
    /*
    NSMutableDictionary *gainGold; // 获取金币信息
    NSMutableDictionary *gainLeaf; // 获取叶子信息
    NSMutableDictionary *gainExp; // 获取经验信息
    NSMutableDictionary *spendGold; // 花费金币信息
    NSMutableDictionary *spendLeaf; // 花费叶子信息
     */
    
}

@property(nonatomic, retain) NSString *userID;
@property(nonatomic, assign) int updateDate;
@property(nonatomic, assign) int userExp;
@property(nonatomic, assign) int installTime;
@property(nonatomic, assign) int timeSinceInstall;
@property(nonatomic, assign) int playCount;
@property(nonatomic, assign) int playTime;
@property(nonatomic, assign) int payTotal;
@property(nonatomic, assign) int payCount;
@property(nonatomic, assign) int payLastTime;

@property(nonatomic, retain) NSMutableDictionary * resourceLog;
@property(nonatomic, retain) NSMutableArray * paymentInfo;
@property(nonatomic, retain) NSMutableDictionary * levelUpInfo;
@property(nonatomic, retain) NSMutableDictionary * buyItems;
@property(nonatomic, retain) NSMutableDictionary * miniGameInfo;

/*
@property(nonatomic, retain) NSMutableDictionary * gainGold;
@property(nonatomic, retain) NSMutableDictionary * gainLeaf;
@property(nonatomic, retain) NSMutableDictionary * gainExp;
@property(nonatomic, retain) NSMutableDictionary * spendGold;
@property(nonatomic, retain) NSMutableDictionary * spendLeaf;
 */

- (NSString *) exportToString;
- (BOOL) importFromString:(NSString *)info;

- (void) logPayment:(int)cost withItem:(NSString *)itemID;

- (void) startPlaySession;
- (void) endPlaySession;

- (void) addUpResource:(int)type method:(int)method count:(int) count;
- (void)logResourceChange:(int)type method:(int)method itemID:(NSString *)itemID count:(int) count;

- (void)logItemBuy:(int)type withID:(NSString *)ID;
- (void)logLevelUp:(int)level;
- (void)logPlayMiniGame:(int)gameID forTime:(int)seconds;

@end
