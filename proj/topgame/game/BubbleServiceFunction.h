//
//  BubbleServiceFunction.h
//  CookieCrumble
//
//  Created by Leon Qiu on 5/6/13.
//
//

#ifndef __CookieCrumble__BubbleServiceFunction__
#define __CookieCrumble__BubbleServiceFunction__

#include <string>
#include <vector>

#ifdef __cplusplus
// extern "C" {
#endif

class BubbleLevelDelegate {
public:
    virtual void onLevelSyncFinished() {}
};

class BubbleSubLevelInfo {
public:
    BubbleSubLevelInfo();
    BubbleSubLevelInfo(int _ID, int _etime, const char *_content);
    ~BubbleSubLevelInfo();
    
    int ID;
    int etime;
    float x,y;
    std::string content;
};

class BubbleLevelInfo {
    
public:
    BubbleLevelInfo();
    ~BubbleLevelInfo();
    
    // 添加子关卡
    void addSubLevel(BubbleSubLevelInfo *p);
    // 获得子关卡
    BubbleSubLevelInfo *getSubLevel(int index);
    // 添加子关卡
    void addUnlockLevel(BubbleSubLevelInfo *p);
    // 获得解锁关卡
    BubbleSubLevelInfo *getUnlockLevel(int index);
    
    int ID;
    std::string name;
    int etime;
    int subLevelCount; // 子关卡数量
    int apiVer; // api version
    std::vector<BubbleSubLevelInfo *> subLevelList;
    int unlockLevelCount; // 解锁关卡数量
    // 解锁关卡列表
    std::vector<BubbleSubLevelInfo *> unlockLevelList;
};

class BubbleLevelStatInfo {
public:
    // 1）完成一个关卡：不管成功失败都要发送统计数据，statFinishLevel.php
    // 发送数据：关卡序号，关卡内部ID，是否过关(0-失败/1－成功)，得分，星级(0/1/2/3)，使用的步数（mania mode出现之前消耗的步数），关卡默认的步数，累计失败的次数（这个是客户端记录的，只要成功一次，失败次数就清零），进入关卡前是否选择＋5步，进入关卡前是否用豆子买铲子，消耗铲子数量，推土机数量，＋1道具数量，小猪道具数量，恢复腐烂水果道具，0.99＋5步的iap买了几个, 打地鼠的bonus值（0/1/2）, scoreBeforeMania, targetCount1/2/3/4,collectCount1/2/3/4
    // 数据格式：版本号|逗号分割的字符串
    // data=1|1,2,3,4,5,6,7,8,9,10...
    char levelIndex[50]; // 关卡序号(全局序号，如果是解锁关卡，就是"6-1", 如果是普通关卡，就是"123")
    int levelID;    // 关卡内部ID
    int success; // 是否过关，0-fail, 1-succeed
    int score;   // 得分总额
    int star;    // 得分星级，0/1/2/3
    int stepUsed;  // 使用的步数（mania mode出现之前消耗的步数）
    int stepTotal; // 关卡默认的总步数
    int failTimes; // 累计失败的次数（这个是客户端记录的，只要成功一次，失败次数就清零）
    int buyFiveStep; // 进入关卡前是否购买了＋5步，0-没买，1-买了
    int buySpade;    // 进入关卡前是否用豆子买铲子，0-没买，1-买了
    int useSpadeCount;    // 消耗的铲子数量
    int useTractorCount;  // 消耗的推土机数量
    int useAddPointCount; // 消耗的＋1道具数量
    int usePigCount;      // 消耗的小猪道具数量
    int useRecoverCount;  // 消耗的恢复腐烂水果道具数量
    int buyFiveMoveCount; // 购买加5步IAP的数量
    int beatRatBonus;     // 打地鼠的bonus，0/1/2
    
    int scoreBeforeMania; // mania模式之前的总分数
    int targetCount[4];      // 各元素的收集目标数量
    int collectCount[4];     // mania模式之前各元素的实际收集数量
    
    // 转换为字符串，调用的程序要负责free()掉返回的指针。
    char *getDataStr();

    BubbleLevelStatInfo();
    ~BubbleLevelStatInfo();
};

class BubbleUnlockEpisodeStatInfo {
    
public:
    // 2）大关解锁：如果玩家解锁大关(不管是花钱解锁还是完成quest解锁)，就发送这个统计数据，statUnlockEpisode.php
    // 发送的数据：大关序号，大关ID，解锁关卡已经完成了几个，总共消耗了几条命，是否付费，从可以玩第一个quest关卡开始到完成解锁的累计时间(秒数)。
    // 数据格式：版本号|逗号分割的字符串
    // data=1|1,2,3,4,5,6
    int episodeIndex; // 大关序号
    int episodeID;    // 大关ID
    int passUnlockLevelCount; // 解锁关卡已经完成了几个
    int useLifeCount; // 总共消耗了几条命
    int buyUnlockIAP; // 是否买IAP直接过关，0-不是，1-是
    int delayTime;    // 从可以玩第一个quest关卡开始到完成解锁的累计时间(单位是秒)
    
    // 转换为字符串，调用的程序要负责free()掉返回的指针。
    char *getDataStr();
    
    BubbleUnlockEpisodeStatInfo();
    ~BubbleUnlockEpisodeStatInfo();
};

// #include <iostream>
// 开始同步关卡数据
void BubbleServiceFunction_startLoadLevels();
// 关卡数据同步完成
void BubbleServiceFunction_onLoadLevelComplete();

// 获得关卡数量
int  BubbleServiceFunction_getLevelCount();

// 通过序号获得关卡信息, 调用者用完后要自行删除返回的指针
BubbleLevelInfo *BubbleServiceFunction_getLevelInfo(int index);

// 获得关卡文件存放的目录
const char *BubbleServiceFunction_getLevelImagePath(int levelID);

// 检查是否有不支持的新关卡
bool BubbleServiceFunction_hasUnsupportLevels();
// 检查是否可以更新
bool BubbleServiceFunction_isUpdateReady();


// 结束一局后发送统计数据
/* 
 用法：
 BubbleLevelStatInfo *info = new BubbleLevelStatInfo();
 sprintf(info->levelIndex,"%d",levelIndex);
 info->levelID = 1; info->success = 0; info->score = 123; ...
 BubbleServiceFunction_sendLevelStats(info);
 delete info;
 */
void BubbleServiceFunction_sendLevelStats(BubbleLevelStatInfo *info);
// 解锁一个章节后发送统计数据
/*
 用法：
 BubbleUnlockEpisodeStatInfo *info = new BubbleUnlockEpisodeStatInfo();
 info->episodeIndex = 1;
 info->episodeID = 1; info->passUnlockLevelCount = 3; info->useLifeCount = 5;
 info->buyUnlockIAP = 0; info->delayTime = 10234;
 BubbleServiceFunction_sendEpisodeStats(info);
 delete info;
 */
void BubbleServiceFunction_sendEpisodeStats(BubbleUnlockEpisodeStatInfo *info);

#ifdef __cplusplus
// }
#endif


#endif /* defined(__CookieCrumble__BubbleServiceFunction__) */
