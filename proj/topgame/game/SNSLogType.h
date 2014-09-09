/*
 *  SNSLogType.h
 *  TapCar
 *
 *  Created by LEON on 11-11-28.
 *  Copyright 2011 topgame.com. All rights reserved.
 *
 */

#ifndef _G_SNS_LOG_TYPE_H

#define _G_SNS_LOG_TYPE_H 1

#define SNS_DISABLE_CATCH_EXCEPTION 1

#define SNS_HAS_SNS_GAME_HELPER  1
#define SNS_DISABLE_FLURRY_V1 1
#ifdef BRANCH_CN
#define SNS_ENABLE_LIMEI2 1
#define SNS_ENABLE_WEIXIN 1
#define SNS_ENABLE_YOUMI  1
#define SNS_ENABLE_DOMOB  1
#define SNS_ENABLE_GUOHEAD 1
#define SNS_ENABLE_DIANRU  1
#define SNS_ENABLE_ADWO    1
#define SNS_ENABLE_MOBISAGE 1
#define SNS_ENABLE_WAPS 1
#define SNS_ENABLE_YIJIFEN 1
#define SNS_ENABLE_CHUKONG 1

#ifdef DEBUG
#define SNS_ENABLE_ADX       1
#endif

#endif
#ifdef BRANCH_WORLD
#define SNS_ENABLE_MINICLIP  1
#define SNS_ENABLE_ADX       1
#define SNS_ENABLE_FLURRY_V2 1
#endif
#define SNS_SHOW_NEW_NOTICE_VIEW  1
#define SNS_DISABLE_NETWORK_CHECK  1
#define SNS_SYNCFACEBOOK 1
#define SNS_AUTOLOAD_FB_ICON 1
// 对于宠物之家，力美的广告墙会以为是竖版，这个标志强制转换为横板
#define SNS_LIMEI_FORCE_LANDSCAPE 1
#define SNS_ENABLE_LAZY_LOAD_REMOTE_ITEM 1
#define SNS_DISABLE_DAILY_PRIZE  1
// #define SNS_ENABLE_TINYMOBI   1
// #define SNS_ENABLE_APPDRIVER  1
#define SNS_ENABLE_CHARTBOOST 1
#define SNS_DISABLE_ADCOLONY  1
// #define SNS_DISABLE_LOADING_VIEW 1
// #define SNS_DISABLE_REMOTECONFIG 1
// 在SnsServerHelper中不处理CCDirector的暂停
#define SNS_DISABLE_DIRECTOR_RESUME 1
#define SNS_DISABLE_GREYSTRIPE 1
#define MODE_COCOS2D_X 1
#define SNS_DISABLE_TINYMAIL 1
#ifdef DEBUG
// #define SNS_SIMULATE_BUY_IAP 1
#endif
#define SNS_DISABLE_SET_POPUP_POSITION 1
#define SNS_USE_NEW_STATS 1
#define SNS_ENABLE_IOS6      1
// #define SNS_ENABLE_KIIP  1
// #define SNS_ENABLE_AARKI    1
// #define SNS_ENABLE_SPONSORPAY 1
// #define SNS_ENABLE_APPLOVIN   1

// #define SNS_DISABLE_GAME_LOADSAVE 1
#define SNS_DISABLE_TAPJOY 1
#define SNS_DISABLE_BONUS_WINDOW 1
#define SNS_ENABLE_KOCHAVA  1
#define SNS_DISABLE_FLURRY_V2 1
// 使用列表通知系统，不自动弹窗
#define SNS_ENABLE_NOTICE_LIST   1

// 在启动时不检查丢失的资源文件，如果检查的话，要等资源文件下载完才能进入游戏，严重影响体验
#define SNS_DISABLE_CHECK_LOST_RESOURCE  1
//#define SNS_DISABLE_GAME_CENTER 1

// 使用游戏中自制的Loading启动界面
// #define SNS_USE_IN_GAME_LOADING 1

#define SNS_BUBBLE_SERVICE_DISABLE_LOAD_IMAGE 1

#define kCoinTypeTapjoy   kCoinType2

#define SNS_COIN_TYPE_GOLD    1
#define SNS_COIN_TYPE_GEM     2
#define SNS_COIN_TYPE_SOUL    3
#define DRAGON_BABY_NEST_ID   9999

#ifdef BRANCH_WORLD
#define SNS_DISABLE_DAILYCHECKIN 1
#endif
/*
 完成任务：
 SNSFunction_logResource(kGameResourceTypeGold, 100, kResChannelTaskReward);
 SNSFunction_logResource(kGameResourceTypeGem,  100, kResChannelTaskReward);
 SNSFunction_logResource(kGameResourceTypeExpr, 100, kResChannelTaskReward);
 SNSFunction_logResource(kGameResourceTypeDragonSoul, 100, kResChannelTaskReward);
 
 购买房间：
 SNSFunction_logResource(kGameResourceTypeGold, -100, kResChannelBuyRoom);
 SNSFunction_logResource(kGameResourceTypeGem, -100, kResChannelBuyRoom);
 SNSFunction_logResource(kGameResourceTypeExpr, 100, kResChannelBuyRoom);
 SNSFunction_logBuyItem("roomID",1,1000,kGameResourceTypeGold, kItemTypeRoom);
 
 升级房间：
 SNSFunction_logResource(kGameResourceTypeGold, -100, kResChannelUpgradeRoom);
 SNSFunction_logResource(kGameResourceTypeGem, -100, kResChannelUpgradeRoom);
 SNSFunction_logResource(kGameResourceTypeExpr, 100, kResChannelUpgradeRoom);


 用户升级统计：
 SNSFunction_logAchievement("10");
 
 买龙：
 SNSFunction_logResource(kGameResourceTypeGold, -100, kResChannelBuyDragon);
 SNSFunction_logResource(kGameResourceTypeGem, -100, kResChannelBuyDragon);
 SNSFunction_logResource(kGameResourceTypeExpr, 100, kResChannelBuyDragon);
 SNSFunction_logBuyItem("dragonID",1,1000,kGameResourceTypeGold, kItemTypeDragon);
 
 喂龙魂：
 SNSFunction_logResource(kGameResourceTypeDragonSoul, -100, kResChannelFeedDragon);
 生产龙魂：
 SNSFunction_logResource(kGameResourceTypeDragonSoul, 100, kResChannelOrbProduct);
 加速魂器：
 SNSFunction_logAction("speedOrb");
 SNSFunction_logResource(kGameResourceTypeGem, -100, kResChannelSpeedOrb);
 买魂器：
 SNSFunction_logResource(kGameResourceTypeGem, -100, kResChannelBuyOrb);
 SNSFunction_logBuyItem("orbID",1,1000,kGameResourceTypeGem, kItemTypeOrb);
 魂器升级：
 SNSFunction_logResource(kGameResourceTypeGem, -100, kResChannelUpgradeOrb);
 
 交配产蛋：
 SNSFunction_logAction("breed");
 
 加速交配：
 SNSFunction_logAction("speedBreed");
 SNSFunction_logResource(kGameResourceTypeGem, -100, kResChannelSpeedBreed);
 
 加速孵化：
 SNSFunction_logAction("speedNest");
 SNSFunction_logResource(kGameResourceTypeGem, -100, kResChannelSpeedNest);
 
 加速房间建设：
 SNSFunction_logAction("speedRoom");
 SNSFunction_logResource(kGameResourceTypeGem, -100, kResChannelSpeedRoom);
 
 买孵化窝：
 SNSFunction_logResource(kGameResourceTypeGem, -100, kResChannelBuyNest);
 SNSFunction_logBuyItem("nestID",1,1000,kGameResourceTypeGem, kItemTypeNest);
 
 收获金币：
 房间收获
 SNSFunction_logResource(kGameResourceTypeGold, 100, kResChannelRoomProduct);
 
 卖龙蛋
 卖龙
 卖房间
 
 */

// 资源获取与消耗渠道定义
enum {
    kResChannelBuyRoom     = 101,  // 买房间
    kResChannelUpgradeRoom = 102,  // 升级房间
    kResChannelBuyDragon   = 103,  // 买龙
    kResChannelBuyNest     = 104,  // 买龙窝
    kResChannelBuyOrb      = 105,  // 买魂器
    kResChannelUpgradeOrb  = 106,  // 魂器升级
    
    kResChannelTaskReward  = 111,  // 任务奖励
    kResChannelOrbProduct  = 112,  // 魂器生产龙魂
    kResChannelFeedDragon  = 113,  // 给龙喂食
    kResChannelRoomProduct = 114,  // 房间产金币
    
    
    kResChannelSpeedRoom   = 121,  // 加速房间建设
    kResChannelSpeedNest   = 122,  // 加速孵蛋
    kResChannelSpeedBreed  = 123,  // 加速交配
    kResChannelSpeedOrb    = 124,  // 加速魂器
};

// 道具类型定义
enum {
	kItemTypeNone = 0,
	kItemTypeRoom, // 1-房间
	kItemTypeDragon, // 2-龙
	kItemTypeOrb,   // 3-魂器
	kItemTypeNest, // 4-龙窝
};

// 增加新的资源类型
enum {
    kGameResourceTypeGold  = 1,
    kGameResourceTypeGem   = 2,
    kGameResourceTypeExpr  = 3,
    kGameResourceTypeDragonSoul = 101, //
};


// image name
#define kFlurryPrizeLeafIcon40x40  @"wqRunLoginLeafage.png"
#define kFlurryPrizeCoinIcon40x40  @"wqRunLoginYB.png"

// loadingView indicator position
#define kLoadingViewIndicatorSubPosition CGPointMake(15, 80)
#define kLoadingViewIndicatorSubPositionPad CGPointMake(30, 230)

#define kDESKey @"zj[P]cz6"
/*

 
 
 // types of pet hotel
enum {
	kLogMethodTypePetRoomHarvest = 101,
	kLogMethodTypePetRoomBuild,
	kLogMethodTypePetRoomSpeed,
	kLogMethodTypeFunRoomHarvest,
	kLogMethodTypeFunRoomBuild,
	kLogMethodTypeFunRoomSpeed,
	kLogMethodTypePetMood,
	kLogMethodTypeStaff,
	kLogMethodTypeExpand,
	kLogMethodTypeExpandSpeed,
	kLogMethodTypePlayMiniGame,
};

*/

/*
 // 道具类型定义
 enum {
 kItemTypeNone = 0,
 kItemTypeIAP, // 在线商品ID，Coin50／Leaf50
 kItemTypePetRoom, // 宠物房间
 kItemTypeConnector, // 连接器
 kItemTypeExpansion, // 扩容
 kItemTypeBackground,// 背景
 kItemTypeDecoration,// 装饰
 kItemTypeFunRoom, // 功能房间
 kItemTypeStaff, // 雇员
 kItemTypeSpeedBuild, // 加速建造
 kItemTypeSpeedExpansion, // 加速扩容
 kItemTypeBuildPetRoom, // 开始建造宠物房间
 kItemTypeBuildFunRoom, // 开始建造功能房间
 kItemTypeStartExpansion, // 开始扩容
 };
 */

#endif

