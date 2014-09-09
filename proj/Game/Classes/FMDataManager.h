//
//  FMDataManager.h
//  NEAnimNodeCpp
//
//  Created by  James Lee on 13-5-2.
//
//

#ifndef __NEAnimNodeCpp__FMDataManager__
#define __NEAnimNodeCpp__FMDataManager__

#include <iostream>
#include "CCBReader.h" 
#include "CCJSONConverter.h"
#include "FMSoundManager.h"
#include "BubbleServiceFunction.h"
#include "GUIScrollSlider.h"
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include "client/linux/handler/exception_handler.h"
#endif

using namespace cocos2d;
using namespace cocos2d::extension;

#define kRecoverTime 1800
#ifdef NDEBUG
#define kQuestCoolDown 86400
#else
#define kQuestCoolDown 60
#endif

#define kLevelStartDiscount "kLevelStartDiscount"       //关卡开始界面的道具打折50%活动时间的key
#define kNextStarRwdIdx "kNextStarRwdIdx"
#define kUnlimitLifeDiscount "kUnlimitLifeDiscount"     //升级无限生命的打折活动
#define kPurchaseUnlimitLife "kPurchaseUnlimitLife"     //是否已购买了无限体力 1 已购买 0 未购买
#define kNewPlayerUnlimitLifeDiscountTime "kNewPlayerUnlimitLifeDiscountTime"   //新玩家所给予的3天无限生命促销时间的结束时间
#define kGoldIapBouns "kGoldIapBouns"                           //金币的促销活动

/**
 key gold 活动期间已购买了多少金币  valueType CCNumber
 key 1    是否已领取了第一阶段的奖励  valueType  CCNumber  1/已领取 0/未领取
 key 2 key3 key4 同key1
 
 **/
#define kGoldIapBonusDic "kGoldIapBonusDic"                     //金币促销活动数据保存的key

typedef enum kGameUI
{
    kUI_MainScene,
    kUI_BranchLevel,
    kUI_Statusbar,
    kUI_WorldMap,
    kUI_LevelStart,
    kUI_Config,
    kUI_Result,
    kUI_GreenPanel,
    kUI_Quit,
    kUI_RedPanel,
    kUI_Booster,
    kUI_IAPGold,
    kUI_Pause,
//    kUI_BossModifier,
    kUI_NeedHeart,
    kUI_NeedMoney,
    kUI_BoosterInfo,
    kUI_LevelEnd,
    kUI_UnlockChapter,
    kUI_FamilyTree,
    kUI_BranchBonus,
    kUI_FreeGolds,
    kUI_Invite,
    kUI_InviteList,
    kUI_UnlimitLife,
    kUI_InputName,
    kUI_Spin,
    kUI_BuySpin,
    kUI_PrizeList,
    kUI_SpinReward,
    kUI_Message,
    kUI_FBConnect,
    kUI_StarReward,
    kUI_UnlimitLifeDiscount,
    kUI_GoldIapBonus,
    kUI_RewardBoard,
    kUI_AskLife,
    kUI_KakaoInvite,
    kUI_KakaoPolice,
    kUI_FriendProfile,
    kUI_SendHeart,
    kUI_DailyBox,
    kUI_DailySign,
    kUI_SignMakeUp,
    kUI_DailySignBouns,
#ifdef DEBUG
    kUI_Warning,
#endif
    kUI_Num
} kGameUI;


typedef enum {
    kRwdTypeGold = 0,
    kHarvest1Type = 3,          //吸管
    kShuffle = 4,               //排序
    kTurnGood = 5,              //变好
    kAdd5Move = 6,              //+5步
    kTCross = 7,                //十字消
    k5Line = 9,                 //5消
    
    kUnlimitLifeOneHour,        //一小时无限生命
    
}kRewardType;



//达到多少星星获取多少奖励
//星星数,奖励道具类型,道具数量,frameName

#ifdef DEBUG

static int s_starReward[10][3] = {
    {1,kUnlimitLifeOneHour,1},
    {2,kHarvest1Type,1},
    {3,kAdd5Move,3},
    {4,kUnlimitLifeOneHour,3},
    {5,kTCross,3},
    {6,kUnlimitLifeOneHour,6},
    {7,kHarvest1Type,2},
    {8,kUnlimitLifeOneHour,12},
    {9,kTurnGood,3},
    {10,kUnlimitLifeOneHour,24}
};

#else
static int s_starReward[10][3] = {
    {25,kUnlimitLifeOneHour,1},
    {50,kHarvest1Type,1},
    {75,kAdd5Move,3},
    {100,kUnlimitLifeOneHour,3},
    {125,kTCross,3},
    {150,kUnlimitLifeOneHour,6},
    {175,kHarvest1Type,2},
    {200,kUnlimitLifeOneHour,12},
    {250,kTurnGood,3},
    {300,kUnlimitLifeOneHour,24}
};

#endif

class BubbleLevelInfo;
class FMDataManager : public BubbleLevelDelegate, public NEAnimStringDelegate
{
private:
    FMDataManager();
    ~FMDataManager();
    
private:
    int m_worldIndex;
    int m_levelIndex;
    bool m_isQuest;
    bool m_isBranch;
    bool m_worldInPhase;
    bool m_isControlOpen;
    int m_tutorialBooster;
    bool m_needFailCount;
    std::map<kGameUI, CCNode *> m_cachedUI;
    CCDictionary * m_userSave;
    CCDictionary * m_localConfig;
    CCDictionary * m_frdDic;
    CCArray * m_tutorials;
    CCDictionary * m_currentTutorial;
    int  m_currentTutorialPhaseIndex;
    std::map<int, BubbleLevelInfo *> m_cachedLevelData;
    std::map<BubbleSubLevelInfo *, CCDictionary *> m_cachedSubLevelData;
    GUIScrollSlider * m_slider;
    int m_totalStarNumber;

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    char *m_fbSaveData;
#endif


    CC_SYNTHESIZE(bool, m_isGoldFromIap, IsGoldFromIap);
#ifdef DEBUG
    bool m_localMode;
public:
    bool getLocalMode() { return m_localMode; }
    void setLocalMode(bool local) { m_localMode = local; }
#endif
protected:
    virtual void onLevelSyncFinished() { reloadLevelData(); }
    virtual const char * animationGetLocalizedString(const char * string) {return getLocalizedString(string);}
public:
    static FMDataManager * sharedManager();
    void destroy();
    void init();
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    char* getFBSaveData();
    void  setFBSaveData(const char* data );
#endif
    
    CCBReader * m_sharedReader;
    static CCNode * createNode(const char * ccbiFileName, CCObject * owner);
    void setLevel(int worldIndex, int levelIndex, bool isQuest, bool isBranch = false) { m_worldIndex = worldIndex; m_levelIndex = levelIndex; m_isQuest = isQuest; m_isBranch = isBranch;}
    void setBranch(bool isBranch){m_isBranch = isBranch;}
    bool nextLevel();
    int getWorldIndex() { return m_worldIndex; }
    int getLevelIndex() { return m_levelIndex; }
    bool isQuest() { return m_isQuest; }
    bool isBranch() { return m_isBranch; }
    void setNeedFailCount(bool flag = true) { m_needFailCount = flag; }
    bool isNeedFailCount() { return m_needFailCount; }
    void setWorldInPhase(bool flag) {m_worldInPhase = flag;}
    int getGlobalIndex() { return getGlobalIndex(m_worldIndex, m_levelIndex); }
    CCDictionary * getLevelData(bool isLocal);
    void checkLevelVersion(CCDictionary * levelData);
    void writeLocalLevelData(CCDictionary * data, int worldIndex, int levelIndex, bool isQuest);
    void uploadLevelData(CCDictionary * levelData);
    int getCurrentScore();
    int getCurrentLeftMoves();
    int getCurrentUsedMoves();
    
    //user save
    void loadGame(const char * userData);
    void saveGame();
    void loadGameFromFB(const char * userData);
    CCDictionary * getUserSave();
    void resetUserSave();
    std::string getUserSaveString();
    CCDictionary * getLevelUserData();
    CCDictionary * getLevelUserDataByIdx(int worldIdx,int lvIdx,bool isQuest = false);
    CCDictionary * getLocalConfig();
    void saveLocalConfig();
    
    
    int getStarNum(int world = -1, int level = -1, int quest = -1);
    void setStarNum(int star);
    int getFailCount();
    void addFailCount();
    void resetFailCount();
    int getbalanceCount();
    void setbalanceCount(int count);
    void resetbalanceCount();
    bool isRewardGetted();
    void getReward();
    int getFurthestLevel();
    int getFurthestWorld();
    void setFurthestLevel(int world = -1, int level = -1, int quest = -1);
    bool isFurthestLevel();
    bool isLevelUnlocked(int world = -1, int level = -1, int quest = -1);
    void unlockLevel();
    bool isGameCleared();
    bool isChallengeCleared(int idx);
    bool isWorldUnlocked();
    void unlockWorld(bool iapBuy = false);
    bool isWorldOpened();
    void openWorld();
    int getWorldLifeUsed();
    void addWorldLifeUsed(int delta);
    void resetWorldQuestBeginTime();
    int getWorldQuestBeginTime();
    bool isLevelBeaten(int world = -1, int level = -1, int quest = -1);
    void setLevelBeaten(int t = 1);
    bool isPreLevelBeaten(int world = -1, int level = -1, int quest = -1);
    bool isWorldBeaten(bool checkQuest = false);
    bool isBoosterLocked(int booster);
    bool isBoosterTiming(int booster);
    bool isBoosterUsable(int type);
    void setBoosterAmount(int booster, int num);
    int getBoosterAmount(int booster);
    int getBoosterTime(int booster);
    int getBoosterDefaultTime(int booster);
    void resetBoosterTimer(int booster);
    void stopBoosterTimer(int booster);
    int getHighscore();
    void setHighscore(int score);
    
    void getInviteReward(int index);
    bool isInviteRewardUseable(int index);
    int getUnlimitLifeTime();
    void setUnlimitLifeTime(int time);
    int getInviteRewardNeedCount(int index);
    int getInviteRewardTime(int index);
    
    void setFid(int fid, int type);
    CCArray* getFid();
    
    void addGameResources(int itemType, int numModify);
    
    void addSaveExp();
    int getSaveExp();
    void setLevelTo(int level);

    
    int getLifeNum();
    int getGoldNum();
    int getMushroomNum();
    void setLifeNum(int n);
    void setBeanNum(int n);
    void setGoldNum(int n);
    void setMushroomNum(int n);
    bool useMoney(int n, const char * booster);
    int getNextLifeTime();
    void setNextLifeTime(int time);
    void resetNextLifeTime();
    bool isLifeUpgraded();
    void upgradeLife();
    bool isLifeFull();
    int getMaxLife();
    bool useLife();
    bool isMusicOn();
    bool isSFXOn();
    void setMusicOn(bool on);
    void setSFXOn(bool on);
    void resetQuestCD();
    void cleanQuestCD();
    int getQuestCD();
    int getSpinTimes();
    void setSpinTimes(int t);
    void addSpinTimes();
    void useSpinTimes();
    int getSpinCount();
    void setSpinCount(int t);
 
    bool isNewJelly(int idx);
    void setNewJelly(int idx, bool isNew);
    bool haveNewJelly();
    bool haveNewBranchLevel();

    CCDictionary* getFrdDic();
    void setFrdMapDic(CCDictionary * dic);
    void insertFrdMapDic(CCDictionary * dic);
    CCDictionary * getFrdMapDic();
    void setFrdLevelDic(CCDictionary * dic);
    CCArray * getFrdLevelDic();
    
    //tutorial
    bool isTutorialDone(int tid);
    void finishTutorial(int tid);
    void initTutorial();
    void checkNewTutorial(const char * event = NULL);
    void tutorialBegin();
    void tutorialNextPhase();
    void tutorialPhaseDone();
    void tutorialSkip();
    bool isTutorialRunning() { return m_currentTutorial != NULL; }
    void checkStableTrigger();
    void clearAllTutorial();
    
    //stage data
    int getGameMode();
    CCArray* getSellingBooster();
    int getBossBean(int multiplier);
    bool isInGame();
    int getLevelID();
    void reloadLevelData();
    BubbleLevelInfo * getLevelInfo(int world);
    
    
    //helper
    static bool isCharacterType();
    static void setRandomSeed(int seed, bool reset = false);
    static int getCurrentRandomSeed();
    static int getRandomIteratorSeed();
    static int getRandom();
    static int getRandom(int seed);
    void updateStatusBar();
    bool isFileExist(const char * filePath);
    std::string getFilePathForID(int subLevelID);
    std::string getUserFilePath(const char * filename);
    int getGlobalIndex(int worldIndex, int levelIndex);
    std::vector<int> getNextLevel(int worldIndex, int levelIndex);
    CCPoint getIndexFromGlobalIndex(int globalIndex);
    CCNode * getUI(kGameUI uiType);
    void reloadLocalizedString();
    const char * getLocalizedString(const char * string);
    int getCurrentTime();
    CCString * getTimeString(int time, bool cut = false);
    std::string getDollarString(int dollar);
    int getRemainTime(int time);
    const char * getHMAC();
    const char * getVersion();
    const char * getUID();
    const char * getUserName();
    int getUserIcon();
    void setUserIcon(int iconId);
    void setUserName(const char * name);
    void setControlflag(bool flag){m_isControlOpen = flag;};
    bool isControlOpen(){return m_isControlOpen;};
    void settutorialBooster(int booster){m_tutorialBooster = booster;};
    int getTutorialBooster(){return m_tutorialBooster;};
    
    GUIScrollSlider * getCurrentSlider() {return m_slider;};
    void setCurrentSlider(GUIScrollSlider * slider) {m_slider = slider;};
    
    //获取促销的开始结束时间 true/开始时间 false/结束时间
    double getDiscountTimeByKey(const char* key,bool startTime = true);
    
    //根据key来判断是否开启某折扣活动(仅从服务器获取的时间判断) //true 开启 /false 关闭
    bool whetherUnsealDiscountFromServerByKey(const char* key);

    //根据后台设置的数据及玩家是否已购买 来判断是否开启关卡开始界面的道具打折
    bool whetherUnsealLevelStartDiscount();
    
    //是否开启iap买金币的促销活动
    bool whetherUnsealIapBouns();
    void resetIapBounsSaveData();

    //根据后台设置的数据判断是否开启升级无限生命的打折活动
    bool whetherUnsealUnlimitLifeDiscount();
    //获取无限生命打折的剩余时间的字符串
    CCString* getUnlimitLifeDiscountRestTimeStr();
    
    //是否购买了无限体力
    bool hasPurchasedUnlimitLife();

    //获取用户已得到的所有星星(包括quest关卡)
    int getAllStarsFromSave();
    
    //弹出收集星星的奖励窗口
    void showStarReward();
    
    //获取下一次收集星星奖励的Index
    int getNextStarRewardIndex();
    //true/下一个index可用 false/不可用
    bool updateNextStarRewardIndex();
    
    //是否开启收星星活动 true/开启 false/关闭
    bool whetherUnsealStarBonus();
    
    //检查收集的星星是否已能获取奖励 true 能 / false 不能
    bool whetherCanGetStarReward();
    
    CCObject* getObjectForUserSave(const char * key);
    void setObjectForUserSave(CCObject * obj, const char * key);
    
    //因为插屏存在加载延迟的问题,当flag == 0时show插屏
    CC_SYNTHESIZE(int, m_showPopupFlag, ShowPopupFlag);
    
    CCArray * getSpinPrizes();
    CCArray * getAllSpinPrizes();
    CCArray * getPrizeFromTier(int tier, int number);
    CCArray * creatPrize(int booster, int number);
    
    int getTotalStarsNumber();
    void resetTotalStarsNumber() {m_totalStarNumber = 0;}
    
    int getDailyLevelRewardDate();
    int getDailyLevelRewardTime();
    void setDailyLevelRewardTime(int time);
    std::vector<int> getDailyRewardLevel();
    
    bool showDailySign();
    int getTodaysLoginIndex();
    CCArray * getLoginRewardStatus();
    bool getLoginReward();
    void getLoginRewardSuccess();
    void setLoginRewardStatus(bool continuous, bool update = false);
    std::vector<int> getRewardInfoForIndex(int index);
    int getSignSkipGold(int index);
};
#endif /* defined(__NEAnimNodeCpp__FMDataManager__) */

