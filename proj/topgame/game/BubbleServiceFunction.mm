//
//  BubbleServiceFunction.cpp
//  CookieCrumble
//
//  Created by Leon Qiu on 5/6/13.
//
//

#import "BubbleServiceFunction.h"
#import "BubbleServiceHelper.h"

bool gLevelSyncDone = false;
BubbleLevelDelegate * gDelegate = NULL;

BubbleSubLevelInfo::BubbleSubLevelInfo()
{
    ID = 0; etime = 0; content = ""; x=0; y=0;
}
BubbleSubLevelInfo::BubbleSubLevelInfo(int _ID, int _etime, const char *_content)
{
    ID = _ID; etime = _etime; content = _content; x=0; y=0;
}

BubbleSubLevelInfo::~BubbleSubLevelInfo()
{
    
}

BubbleLevelInfo::BubbleLevelInfo()
{
    ID = 0; etime = 0; name = ""; subLevelCount = 0; unlockLevelCount = 0; apiVer = 0;
}

BubbleLevelInfo::~BubbleLevelInfo()
{
    // release sub levels
    for (int i=0; i<subLevelList.size(); i++) {
        delete subLevelList[i];
    }
    subLevelList.clear();
    for (int i=0; i<unlockLevelList.size(); i++) {
        delete unlockLevelList[i];
    }
    unlockLevelList.clear();
}
// 添加子关卡
void BubbleLevelInfo::addSubLevel(BubbleSubLevelInfo *p)
{
    subLevelList.push_back(p);
}
// 获得子关卡
BubbleSubLevelInfo *BubbleLevelInfo::getSubLevel(int index)
{
    if(index>=subLevelList.size()) return NULL;
    return subLevelList[index];
}
// 添加子关卡
void BubbleLevelInfo::addUnlockLevel(BubbleSubLevelInfo *p)
{
    unlockLevelList.push_back(p);
}

// 获得解锁关卡
BubbleSubLevelInfo *BubbleLevelInfo::getUnlockLevel(int index)
{
    if(index>=unlockLevelList.size()) return NULL;
    return unlockLevelList[index];
}


BubbleLevelStatInfo::BubbleLevelStatInfo()
{
    // strcpy(levelIndex, "");
    levelIndex[0] = '\0';
    levelID = 0;
    success = 0;
    score   = 0;
    star    = 0;
    stepUsed  = 0;
    stepTotal = 0;
    failTimes = 0;
    buyFiveStep = 0;
    buySpade    = 0;
    useSpadeCount = 0;
    useTractorCount  = 0;
    useAddPointCount = 0;
    usePigCount = 0;
    useRecoverCount  = 0;
    buyFiveMoveCount = 0;
    beatRatBonus = 0;
    scoreBeforeMania = 0;
    collectCount[0] = 0;
    collectCount[1] = 0;
    collectCount[2] = 0;
    collectCount[3] = 0;
    targetCount[0] = 0;
    targetCount[1] = 0;
    targetCount[2] = 0;
    targetCount[3] = 0;
    
}
BubbleLevelStatInfo::~BubbleLevelStatInfo()
{
    
}

// 转换为字符串，调用的程序要负责free掉返回的指针。
char *BubbleLevelStatInfo::getDataStr()
{
    // 发送数据：关卡序号，关卡内部ID，是否过关(0-失败/1－成功)，得分，星级(0/1/2/3)，使用的步数（mania mode出现之前消耗的步数），关卡默认的步数，累计失败的次数（这个是客户端记录的，只要成功一次，失败次数就清零），进入关卡前是否选择＋5步，进入关卡前是否用豆子买铲子，消耗铲子数量，推土机数量，＋1道具数量，小猪道具数量，恢复腐烂水果道具，0.99＋5步的iap买了几个, 打地鼠的bonus值（0/1/2）, scoreBeforeMania, targetCount1/2/3/4,collectCount1/2/3/4
    char buf[512];
    sprintf(buf,"1|%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", levelIndex, levelID, success, score, star, stepUsed, stepTotal, failTimes, buyFiveStep, buySpade, useSpadeCount, useTractorCount, useAddPointCount, usePigCount, useRecoverCount, buyFiveMoveCount, beatRatBonus, scoreBeforeMania, targetCount[0],targetCount[1],targetCount[2],targetCount[3], collectCount[0], collectCount[1], collectCount[2], collectCount[3]);
    int len = strlen(buf)+1;
    char *p = (char *) malloc(len);
    memcpy(p, buf, len);
    return p;
}

BubbleUnlockEpisodeStatInfo::BubbleUnlockEpisodeStatInfo()
{
    episodeID = 0;
    episodeIndex = 0;
    passUnlockLevelCount = 0;
    useLifeCount = 0;
    buyUnlockIAP = 0;
    delayTime = 0;
}

BubbleUnlockEpisodeStatInfo::~BubbleUnlockEpisodeStatInfo()
{
    
}
// 转换为字符串，调用的程序要负责free()掉返回的指针。
char *BubbleUnlockEpisodeStatInfo::getDataStr()
{
    // 发送的数据：大关序号，大关ID，解锁关卡已经完成了几个，总共消耗了几条命，是否付费，从可以玩第一个quest关卡开始到完成解锁的累计时间(秒数)。
    char buf[255];
    sprintf(buf,"1|%d,%d,%d,%d,%d,%d", episodeIndex, episodeID, passUnlockLevelCount, useLifeCount, buyUnlockIAP, delayTime);
    int len = strlen(buf)+1;
    char *p = (char *) malloc(len);
    memcpy(p, buf, len);
    return p;
}

// 结束一局后发送统计数据
void BubbleServiceFunction_sendLevelStats(BubbleLevelStatInfo *info)
{
    char *buf = info->getDataStr();
    NSString *data = [NSString stringWithUTF8String:buf];
    [[BubbleServiceHelper helper] performSelectorInBackground:@selector(reportToStatLevel:) withObject:data];
    free(buf);
}
// 解锁一个章节后发送统计数据
void BubbleServiceFunction_sendEpisodeStats(BubbleUnlockEpisodeStatInfo *info)
{
    char *buf = info->getDataStr();
    NSString *data = [NSString stringWithUTF8String:buf];
    [[BubbleServiceHelper helper] performSelectorInBackground:@selector(reportToStatUnlockEpisode:) withObject:data];
    free(buf);
}

// 开始同步关卡数据
void BubbleServiceFunction_startLoadLevels()
{
    [[BubbleServiceHelper helper] startSyncWithServer];
}
// 关卡数据同步完成
void BubbleServiceFunction_onLoadLevelComplete()
{
    // TODO: 在这里添加回调函数
    gLevelSyncDone = true;
    if (gDelegate) {
        gDelegate->onLevelSyncFinished();
    }
}

// 获得关卡数量
int  BubbleServiceFunction_getLevelCount()
{
    return [[BubbleServiceHelper helper] getLevelCount:1];
}
// 检查是否有不支持的新关卡
bool BubbleServiceFunction_hasUnsupportLevels()
{
    if([[BubbleServiceHelper helper] hasUnsupportLevels]) return true;
    return false;
}
// 检查是否可以更新
bool BubbleServiceFunction_isUpdateReady()
{
    if([[BubbleServiceHelper helper] isUpdateVersionReady]) return true;
    return false;
}

// 通过序号获得关卡信息
BubbleLevelInfo *BubbleServiceFunction_getLevelInfo(int index)
{
    NSDictionary *info = [[BubbleServiceHelper helper] getLevelAtIndex:index];
    
    BubbleLevelInfo *levelInfo = new BubbleLevelInfo();
    levelInfo->ID = [[info objectForKey:@"id"] intValue];
    NSString *name = [info objectForKey:@"name"];
    if(name==nil) levelInfo->name = "";
    else levelInfo->name = [name UTF8String];
    levelInfo->etime = [[info objectForKey:@"etime"] intValue];
    levelInfo->subLevelCount = [[info objectForKey:@"subLevelCount"] intValue];
    levelInfo->unlockLevelCount = [[info objectForKey:@"unlockLevelCount"] intValue];
    //added by james
#ifndef JELLYMANIA
    if (BubbleServiceFunction_getLevelCount()-1 == index) {
        //final world, quest levels are not allowed
        levelInfo->unlockLevelCount = 0;
    }
#endif
    levelInfo->apiVer = [[info objectForKey:@"apiVer"] intValue];
    NSArray *posList = nil; NSString *posStr = [info objectForKey:@"subLevelPosList"];
    if(posStr!=nil && [posStr length]>0) posList = [posStr componentsSeparatedByString:@"|"];
    // add sub levels
    for(int i=1;i<=levelInfo->subLevelCount;i++) {
        NSString *content = [info objectForKey:[NSString stringWithFormat:@"subLevel%d", i]];
        NSString *etime   = [info objectForKey:[NSString stringWithFormat:@"subTime%d", i]];
        NSString *ID      = [info objectForKey:[NSString stringWithFormat:@"subID%d", i]];
        if(content==nil) continue;
        BubbleSubLevelInfo *p = new BubbleSubLevelInfo([ID intValue], [etime intValue], [content UTF8String]);
        if(posList!=nil && [posList count]>=i) {
            // set position of subLevel
            posStr = [posList objectAtIndex:i-1];
            NSArray *arr = [posStr componentsSeparatedByString:@","];
            if(arr!=nil && [arr count]>=2) {
                posStr = [arr objectAtIndex:0]; p->x = [posStr floatValue];
                posStr = [arr objectAtIndex:1]; p->y = [posStr floatValue];
            }
        }
        levelInfo->addSubLevel(p);
    }
    
    // add unlock levels
    for(int i=1;i<=levelInfo->unlockLevelCount;i++) {
        NSString *content = [info objectForKey:[NSString stringWithFormat:@"unlockLevel%d", i]];
        NSString *etime   = [info objectForKey:[NSString stringWithFormat:@"unlockTime%d", i]];
        NSString *ID      = [info objectForKey:[NSString stringWithFormat:@"unlockID%d", i]];
        if(content==nil) continue;
        BubbleSubLevelInfo *p = new BubbleSubLevelInfo([ID intValue], [etime intValue], [content UTF8String]);
        levelInfo->addUnlockLevel(p);
    }
    return levelInfo;
}

// 获得关卡文件存放的目录
const char *BubbleServiceFunction_getLevelImagePath(int levelID)
{
    NSString *ID = [NSString stringWithFormat:@"%d",levelID];
    NSString *path = [[BubbleServiceHelper helper] getLevelImagePath:ID];
    return [path UTF8String];
}

