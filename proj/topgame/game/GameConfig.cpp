//
//  GameConfig.cpp
//  DragonSoul
//
//  Created by LEON on 12-10-12.
//
//

#include "GameConfig.h"
#include "FMDataManager.h"
#include "FMUINeedHeart.h"
#include "FMUIUnlockChapter.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "FMUIRedPanel.h"
#include "SNSFunction.h"
#include <string>

// #include "Game.h"

// 返回数据存档，每次进入后台保存数据时都会调用此方法
// buf_size是buf的长度，如果实际数据超过这个长度，就要用free(buf)把buf释放掉，然后用malloc()创建新的buf，并返回buf
char * GameConfig::getGameData(char *buf, int buf_size)
{
    // 获得游戏存档数据
    std::string data = FMDataManager::sharedManager()->getUserSaveString();
    if(data.length()==0) {
        CCLOG("%s: empty save data",__func__);
    }
    if(data.length()>=buf_size){
        free(buf);
        buf = (char *)malloc(data.length()+1);
    }
    strcpy(buf,data.c_str());
    data.clear();
    return buf;
}

// 初始化游戏存档，每次进入游戏时都会调用此方法设置最新的存档数据
void GameConfig::setGameData(const char *data)
{
    FMDataManager::sharedManager()->loadGame(data);
}
void GameConfig::setGameDataFromFB(const char *data)
{
    FMDataManager::sharedManager()->loadGameFromFB(data);
}
// 添加游戏资源, type:1-金币，2－钻石，3－经验, 101-Life
void GameConfig::addGameResource(int type, int val)
{
    if(type == 1)
    {
        int n = FMDataManager::sharedManager()->getGoldNum();
        FMDataManager::sharedManager()->setGoldNum(val+n);
        
#ifdef BRANCH_CN
        FMDataManager* manager = FMDataManager::sharedManager();
        if (manager->getIsGoldFromIap() && manager->whetherUnsealIapBouns()) {
            CCDictionary* dicData = (CCDictionary* )manager->getUserSave()->objectForKey(kGoldIapBonusDic);
            if (!dicData){
                manager->resetIapBounsSaveData();
                dicData = (CCDictionary* )manager->getUserSave()->objectForKey(kGoldIapBonusDic);
            }
            
            int curPurchased = ((CCNumber*)dicData->objectForKey("gold"))->getIntValue();
            dicData->setObject(CCNumber::create(curPurchased+val), "gold");
            manager->saveGame();
        }
        
        manager->setIsGoldFromIap(false);
#endif
        
    }
    else if(type == 2)
    {
        /*
        // User::sharedUser()->addStone(val);
        int n = FMDataManager::sharedManager()->getGoldNum();
        FMDataManager::sharedManager()->setGoldNum(val+n);
         */
    }
    else if(type == 3)
    {
        // User::sharedUser()->addExp(val);
        // int n = FMDataManager::sharedManager()->getStarNum();
        FMDataManager::sharedManager()->addSaveExp();
    }
    else if(type==4) {
        // 注意等级参数和其他参数不同，比如level＝25，表示设定玩家的等级为25，而不是当前等级＋25
        CCLOG("addGameResource: Set level:%d",val);
        FMDataManager::sharedManager()->setLevelTo(val);
    }
    else if(type == 101)
    {
        // TODO：增加生命
        CCLOG("add life:%d",val);
        int lifeNum = FMDataManager::sharedManager()->getLifeNum();
        lifeNum += val;
//        int maxlife = FMDataManager::sharedManager()->getMaxLife();
//        if (lifeNum > maxlife) {
//            lifeNum = maxlife;
//        }
        FMDataManager::sharedManager()->setLifeNum(lifeNum);
        FMDataManager::sharedManager()->updateStatusBar();
    }
    else if(type == 102)
    {
        // TODO：增加"+5步"道具
        int count = FMDataManager::sharedManager()->getBoosterAmount(kBooster_MovePlusFive);
        count += val;
        FMDataManager::sharedManager()->setBoosterAmount(kBooster_MovePlusFive, count);
    }
    // User::sharedUser()->updateVipLV();
}

// 获取游戏资源, type:1-金币，2－叶子，3－经验，4－等级, 101-龙魂, 5 - 当前游戏分数， 6 - 当前游戏剩余步数， 7 - 当前游戏已使用步数
int GameConfig::getGameResource(int type)
{
    if(type == 1)
    {
        // return Game::getGameInstance()->myUser->money;
        return -1;
    }
    else if(type == 2)
    {
        // return User::sharedUser()->nCurStone ;
        return FMDataManager::sharedManager()->getGoldNum();
    }
    else if(type == 3)
    {
        // return User::sharedUser()->nAllExp;
        // return Game::getGameInstance()->myUser->exp;
        return FMDataManager::sharedManager()->getSaveExp();
    }
    else if(type == 4)
    {
        // return User::sharedUser()->nCurLevel;
        // return Game::getGameInstance()->myUser->level;
        FMDataManager * manager = FMDataManager::sharedManager();
        int furWorld = manager->getFurthestWorld();
        int furLevel = manager->getFurthestLevel();
        int globalIndex = manager->getGlobalIndex(furWorld, furLevel);
        return globalIndex;
    }
    else if (type == 5)
    {
        return FMDataManager::sharedManager()->getCurrentScore();
    }
    else if (type == 6)
    {
        return FMDataManager::sharedManager()->getCurrentLeftMoves();
    }
    else if (type == 7)
    {
        return FMDataManager::sharedManager()->getCurrentUsedMoves();
    }
    else if(type == 101)
    {
        // return User::sharedUser()->nCurDragonExp;
    }
    return 0;
}

// IAP道具购买成功,发放金币和道具
void GameConfig::purchaseSucceed(const char *iapID)
{
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
    FMDataManager * manager = FMDataManager::sharedManager();
    if(strcmp(iapID, "upgradelives30")==0 || strcmp(iapID, "upgradelife30")==0 || strcmp(iapID, "升级到8个体力")==0) {
        // 执行增加3条命的操作
        FMUINeedHeart * window = (FMUINeedHeart *)manager->getUI(kUI_NeedHeart);
        CCNumber *num = new CCNumber(1);
        window->buyIAPCallback(num);
    } else if(strcmp(iapID, "superpower1")==0 || strcmp(iapID, "钥匙1")==0) {
        FMUIUnlockChapter * window = (FMUIUnlockChapter *)manager->getUI(kUI_UnlockChapter);
        CCNumber *num = new CCNumber(1);
        window->buyIAPCallback(num);
    } else if(strcmp(iapID, "move1")==0 || strcmp(iapID, "move2")==0 || strcmp(iapID, "move3")==0 || strcmp(iapID, "move4")==0 || strcmp(iapID, "额外的移动步数1")==0 || strcmp(iapID, "额外的移动步数2")==0 || strcmp(iapID, "额外的移动步数3")==0 || strcmp(iapID, "额外的移动步数4")==0) {
        FMUIRedPanel * window = (FMUIRedPanel *)FMDataManager::sharedManager()->getUI(kUI_RedPanel);
        CCNumber *num = new CCNumber(1);
        window->buyIAPCallback(num);
    }
#endif
}

// 设置IAP道具的奖励数量
void GameConfig::setGoldsAmount()
{
    // gold_1 = SNSFunction_getIAPItemCount("coin2");
}

// 获取IAP道具对应的金币数量,coin2,coin5, gem2,gem5
int GameConfig::getIapItemCoinNumber(const char *iapID)
{
    // return User::sharedUser()->getIapNum(iapID);
    return 0;
}



// 显示系统通知
void GameConfig::onGetSystemNotice(const char *noticeMesg)
{
}
extern bool isLoadingDone;
void GameConfig::setIsLoadingDone()
{
    isLoadingDone = true;
    CCLOG("GameConfig::setIsLoadingDone()=%d", isLoadingDone ? 1 : 0);
}



// 导出关键的数值，进行保护
int  GameConfig::dumpProtectedData(char *buf, int len)
{
    char *p = buf;
    int len2 = 0; int val; int blen = sizeof(int);
    val = getGameResource(1);
    memcpy(p, &val, blen); p += blen; len2 += blen;
    val = getGameResource(2);
    memcpy(p, &val, blen); p += blen; len2 += blen;
    // val = getGameResource(3);
    // memcpy(p, &val, blen); p += blen; len2 += blen;
    val = getGameResource(4);
    memcpy(p, &val, blen); p += blen; len2 += blen;
    val = getGameResource(5);
    memcpy(p, &val, blen); p += blen; len2 += blen;
    val = getGameResource(6);
    memcpy(p, &val, blen); p += blen; len2 += blen;
    val = getGameResource(7);
    memcpy(p, &val, blen); p += blen; len2 += blen;
    return len2;
}

// 获得关卡等候时间, 单位是秒
int  GameConfig::getQuestWaitingTime()
{
#ifdef DEBUG
    return 60;
#endif
    static int waitingTime = 0;
    static int loadTime = 0;
    int now = SNSFunction_getCurrentTime();
    if(loadTime>now-3600) return waitingTime;
    int hours = SNSFunction_getRemoteConfigInt("kQuestWaitHours");
    if(hours==0) hours = 8; // 默认8小时
    waitingTime = hours * 3600;
    loadTime = now;
    return waitingTime;
}

