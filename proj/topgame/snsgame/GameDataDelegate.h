//
//  GameDataDelegate.h
//  PetInn
//
//  Created by LEON on 11-8-3.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol GameDataDelegate

@required

// 获取本地通知音效是否开启
- (BOOL) getNotificationSoundOn;
// 获取本地通知列表
- (NSArray *) getNotificationList;

// 获取扩展字段
- (id) getExtraInfo:(id)key;

// 存储扩展字段
- (void) setExtraInfo:(id)val forKey:(id)key;

// 添加游戏资源, type:1-金币，2－叶子，3－经验
- (void) addGameResource:(int)val ofType:(int) type isIap:(BOOL)isIap;

// 获取游戏资源, type:1-金币，2－叶子，3－经验，4－等级
- (int) getGameResourceOfType:(int) type;

// 获取当前等级的IAP金币数量，传入参数1/5/10/20/50/100
- (int) getIAPCoinCount:(int)val;
// 获取IAP叶子数量
- (int) getIAPLeafCount:(int)val;

// IAP购买成功后充值, 需要在这个方法里显示充值成功通知
// val值和各IAP数量对应，一般有这几个取值：1/5/10/20/50/100
// 对于随等级变化的充值额度，要在这个方法里进行转换
// type:1-金币，2－叶子/钻石/糖果，3－活动奖励
- (void) onBuyIAP:(int)val ofType:(int) type;

// 是否完成了新手引导
- (BOOL) isTutorialFinished;
// 是否开始了新手教程
- (BOOL) isTutorialStart;

// 保存进度到文件
- (void) saveGame;

// 如果这个方法返回YES，将不会进入游戏，会提示用户需要下载远程道具，需要重新启动游戏
// 检查是否有未下载的远程道具，如果发现存档里有配置文件里没有的道具ID，就返回YES，否则返回NO
- (BOOL) hasUnloadedItems;

// 是否是当前玩家的进度
- (BOOL) isCurrentPlayer;

@optional
// 通过IAP购买游戏道具, itemName是道具IAP ID中的道具名，count是数量,itemName+"count"就是IAP中的ID
// 比如 com.topgame.slots.coin10对应的itemName:coin, count:10
- (void) onBuyIAPItem:(NSString *)itemName withCount:(int) count;

// 增加某个道具
- (void) onAddItem:(NSString *)itemID withCount:(int) count;

// 导出进度信息, 不建议使用，请转为使用 exportToString
- (NSDictionary *) exportToDictionary __attribute__ ((deprecated));
// 导出进度信息为字符串
- (NSString *) exportToString;
// 导入进度信息
- (BOOL) importFromString:(NSString *)str;
// 从Facebook导入进度
- (void) importFromFBString:(NSString *)str;
// 如果某个远程道具加载成功，就会调用此方法通知游戏
- (void) onRemoteItemImageLoaded:(NSString *)itemID;

// 检查配置文件里是否包含某个道具的定义，如果有就返回YES，没有就返回NO
- (BOOL) isRemoteItemLoaded:(NSString *)itemID;
// 游戏启动时运行的回调函数
- (void) onGameStarted;
// 进入后台时运行的函数
- (void) onGameGoesBackground;
// 从后台恢复前台时运行的函数
- (void) onGameResumeForground;


@end
