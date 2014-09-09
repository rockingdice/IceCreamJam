//
//  FMDataManager.cpp
//  NEAnimNodeCpp
//
//  Created by  James Lee on 13-5-2.
//
//

#include "FMDataManager.h"
#include "FMGameElement.h"
#include "CCNodeLoaderLibrary.h"
#include "CCJSONConverter.h"
#include "OBJCHelper.h"
#include "SNSFunction.h"
#include "GAMEUI_Scene.h"
#include "AppDelegate.h"

#include "FMMainScene.h"
#include "FMStatusbar.h"
#include "FMTutorial.h"
#include "FMUILevelStart.h"
#include "FMUIBranchLevel.h"
#include "FMUIWorldMap.h"
#include "FMUIConfig.h"
#include "FMUIGreenPanel.h"
#include "FMUIResult.h"
#include "FMUIQuit.h"
#include "FMUIRedPanel.h"
#include "FMUIBooster.h"
#include "FMUIInAppStore.h" 
#include "FMUINeedHeart.h"
#include "FMUINeedMoney.h"
#include "FMUIRestore.h"
#include "FMUIBoosterInfo.h"
#include "FMUIUnlockChapter.h"
#include "FMUIPause.h"
#include "FMUIFamilyTree.h"
#include "FMUIBranchBonus.h"
#include "FMUIFreeGolds.h"
#include "FMUIInvite.h"
#include "FMUIInviteList.h"
#include "FMUIUnlimitLife.h"
#include "FMUIInputName.h"
#include "FMUISpin.h"
#include "FMUIBuySpin.h"
#include "FMUIPrizeList.h"
#include "FMUISpinReward.h"
#include "FMUIMessage.h"
#include "FMUIFBConnect.h"

#include "FMUIStarReward.h"
#include "FMUIUnlimitLifeDiscount.h"
#include "FMUIGoldIapBonus.h"
#include "FMUIRewardBoard.h"
#include "FMUIFriendProfile.h"
#include "FMUISendHeart.h"
#include "FMUIDailyBoxPop.h"
#include "FMUIDailySign.h"
#include "FMUISignMakeUp.h"
#include "FMUISignReward.h"

#ifdef DEBUG
#include "FMUIWarning.h"
#endif
#include "BubbleServiceFunction.h"
#include "GameConfig.h"




static FMDataManager * m_sharedInstance = NULL;


FMDataManager::FMDataManager() :
    m_userSave(NULL),
    m_localConfig(NULL),
    m_frdDic(NULL),
    m_tutorials(NULL),
#ifdef DEBUG
    m_localMode(false),
#endif
    m_currentTutorial(NULL),
    m_currentTutorialPhaseIndex(0),
    m_worldIndex(0),
    m_levelIndex(0),
    m_isQuest(false),
    m_isBranch(false),
    m_isControlOpen(true),
    m_tutorialBooster(-1),
    m_worldInPhase(false),
    m_slider(NULL),
    m_isGoldFromIap(false),
    m_showPopupFlag(-2),
    m_totalStarNumber(0)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    m_fbSaveData = NULL;
#endif
    
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
    AppDelegate * app = (AppDelegate *)CCApplication::sharedApplication();
    app->initResPath();
#endif
    m_tutorials = CCArray::create();
    m_tutorials->retain();
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
    initTutorial();
#endif
    NEAnimManager::sharedManager()->setSoundDelegate(FMSound::manager());
    NEAnimManager::sharedManager()->setStringDelegate(this);
    
    extern BubbleLevelDelegate * gDelegate;
    gDelegate = this;
    reloadLevelData();
 
}

FMDataManager::~FMDataManager()
{
    m_tutorials->release();
    if (m_userSave) {
        m_userSave->release();
        m_userSave = NULL;
    }
    if (m_frdDic) {
        m_frdDic->release();
        m_frdDic = NULL;
    }
    if (m_localConfig) {
        m_localConfig->release();
        m_localConfig = NULL;
    }
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    delete gExceptionHandler;
#endif
}

FMDataManager * FMDataManager::sharedManager()
{
    if (m_sharedInstance == NULL) {
        m_sharedInstance = new FMDataManager();
    }
    return m_sharedInstance;
}

CCNode * FMDataManager::createNode(const char * ccbiFileName, CCObject * owner)
{
    CCNodeLoaderLibrary * ccNodeLoaderLibrary = CCNodeLoaderLibrary::newDefaultCCNodeLoaderLibrary();
    CCBReader * sharedReader = new CCBReader(ccNodeLoaderLibrary);
    CCNode * node = sharedReader->readNodeGraphFromFile(ccbiFileName, owner);
    delete sharedReader;
    return node;
}


std::vector<int> FMDataManager::getNextLevel(int worldIndex, int levelIndex)
{
    std::vector<int> retVal;
    BubbleLevelInfo * worldInfo = getLevelInfo(worldIndex);
    if (!worldInfo) {
        //no exist
        retVal.push_back(-1);
        retVal.push_back(-1);
        return retVal;
    }
    //check block
    bool checkNextWorld = false; 
    //check next level exist
    if (levelIndex == -1) {
        //next world
        checkNextWorld = true;
    }
    else {
        if (worldInfo->subLevelCount > levelIndex + 1) {
            retVal.push_back(worldIndex);
            retVal.push_back(levelIndex + 1);
        }
        else {
            //didn't exist in this world, check next world
            checkNextWorld = true;
        }
    }
    
    if (checkNextWorld) {
        //no exist, check next world
        if (BubbleServiceFunction_getLevelCount() <= worldIndex + 1) {
            //no next world
            retVal.push_back(-1);
            retVal.push_back(-1);
        }
        else {
            worldInfo = getLevelInfo(worldIndex + 1);
            if (worldInfo->subLevelCount > 0) {
                retVal.push_back(worldIndex+1);
                retVal.push_back(0);
            }
            else {
                retVal.push_back(-1);
                retVal.push_back(-1);
            }
        }

    }
    return retVal;
}



CCDictionary * FMDataManager::getLevelData(bool isLocal)
{
    if (BubbleServiceFunction_getLevelCount() == 0) {
        return NULL;
    }
    BubbleLevelInfo * worldInfo = getLevelInfo(m_worldIndex);
    CCDictionary * retVal = NULL;
    if (worldInfo) {
        BubbleSubLevelInfo * levelInfo = NULL;
        if (m_isQuest) {
            levelInfo = worldInfo->getUnlockLevel(m_levelIndex);
        }
        else {
            levelInfo = worldInfo->getSubLevel(m_levelIndex);
        }
        if (levelInfo) {
            if (isLocal) {
                //first find local file
                std::string filePath = getFilePathForID(levelInfo->ID);
                FILE * fp = fopen(filePath.c_str(), "r");
                if (!fp) {
                    //create one
                    CCString * initFileContent = CCString::createWithContentsOfFile("initLevel.dat");
                    fp = fopen(filePath.c_str(), "w");
                    fputs(initFileContent->getCString(), fp);
                }
                fclose(fp);
                CCString * fileContent = CCString::createWithContentsOfFile(filePath.c_str());
                retVal = CCJSONConverter::sharedConverter()->dictionaryFrom(fileContent->getCString());
            }
            else {
//                CCDictionary * data = CCJSONConverter::sharedConverter()->dictionaryFrom(levelInfo->content.c_str());
                if (m_cachedSubLevelData.find(levelInfo) == m_cachedSubLevelData.end()) {
                    CCString * initFileContent = CCString::createWithContentsOfFile("initLevel.dat");
                    retVal = CCJSONConverter::sharedConverter()->dictionaryFrom(initFileContent->getCString());
                }
                else {
                    CCDictionary * data = m_cachedSubLevelData[levelInfo];
                    retVal = data;
                }
            }
        }
        //delete worldInfo;
    }
    
    checkLevelVersion(retVal);

    return retVal;
}

void FMDataManager::checkLevelVersion(cocos2d::CCDictionary *levelData)
{
    CCNumber * version = (CCNumber *)levelData->objectForKey("version");
    if (!version) {
        //old data
        version = CCNumber::create(0);
        levelData->setObject(version, "version");
        
        //fix map size
        extern int kGridNum;
        CCArray * newmap = CCArray::createWithCapacity(kGridNum * kGridNum);
        CCArray * map = (CCArray *)levelData->objectForKey("map");
            
        for (int i=0; i<kGridNum; i++) {
            CCArray * rowData = CCArray::createWithCapacity(kGridNum);
            for (int j=0; j<kGridNum; j++) {
                CCArray * gridData = CCArray::createWithCapacity(kGridNum);
                gridData->addObject(CCNumber::create(-1));
                rowData->addObject(gridData);
            }
            newmap->addObject(rowData);
        }

        for (int i=0; i<8; i++) {
            CCArray * rowData = (CCArray *)map->objectAtIndex(i);
            CCArray * newrowData = (CCArray *)newmap->objectAtIndex(i);
            for (int j=7; j>=0; j--) {
                CCArray * gridData = (CCArray *)rowData->objectAtIndex(j);
                newrowData->replaceObjectAtIndex(j, gridData);
            }
        }
        levelData->setObject(newmap, "map");
    }
}

static std::map<std::string, int> fileCache;
bool FMDataManager::isFileExist(const char *filePath)
{
    std::string fullPath = CCFileUtils::sharedFileUtils()->fullPathForFilename(filePath);
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    std::string ccstr = std::string(filePath);
    std::map<std::string, int>::iterator iter = fileCache.find(ccstr);
    //CCLog("filePath=%s   %d", filePath, fileCache.size());
    if(iter != fileCache.end()) {CCLog("filePath=%s exist.", filePath);
        return true;
    }
    if(SNSFunction_isAssetsFileExist(fullPath.c_str())){
        fileCache.insert(std::map<std::string, int>::value_type(ccstr, 1));
        CCLog("filePath    exit");
        return true;
    }
    return false;
#else
    FILE *fp = fopen(fullPath.c_str(), "r");
    if (! fp)
    {
        return false;
    }
    else {
        fclose(fp);
        return true;
    }
#endif
}

std::string FMDataManager::getFilePathForID(int subLevelID)
{
    std::string path = CCFileUtils::sharedFileUtils()->getWriteablePath();
    std::stringstream ss;
    ss.str("");
    ss << path << subLevelID << ".dat";
    std::string filePath = ss.str();
    return filePath;
}

std::string FMDataManager::getUserFilePath(const char * filename)
{
    std::string path = CCFileUtils::sharedFileUtils()->getWriteablePath();
    std::stringstream ss;
    ss.str("");
    ss << path << filename;
    std::string filePath = ss.str();
    return filePath;
}

void FMDataManager::writeLocalLevelData(cocos2d::CCDictionary *data, int worldIndex, int levelIndex, bool isQuest)
{
    BubbleLevelInfo * worldInfo = getLevelInfo(worldIndex);
    CCAssert(worldInfo, "Cannot find world!");
    BubbleSubLevelInfo * levelInfo = NULL;
    if (isQuest) {
        levelInfo = worldInfo->getUnlockLevel(levelIndex);
    }
    else {
        levelInfo = worldInfo->getSubLevel(levelIndex);
    }
    CCAssert(levelInfo, "Cannot find level in world!");
    
    std::string filePath = getFilePathForID(levelInfo->ID);
    const char * json = CCJSONConverter::sharedConverter()->strFrom(data)->getCString();

	CCLOG("saveFile, path = %s", filePath.c_str());
	
	FILE *fp = fopen(filePath.c_str(), "w");
    
	if (! fp)
	{
		CCLOG("can not create file %s", filePath.c_str());
	}
    else {
        fputs(json, fp);
        fclose(fp);
    }
    //delete worldInfo;
}

void FMDataManager::uploadLevelData(CCDictionary * levelData)
{
    const char * content = CCJSONConverter::sharedConverter()->strFrom(levelData)->getCString();
    OBJCHelper::helper()->uploadLevelData(m_worldIndex, m_levelIndex, m_isQuest, content);
}

int FMDataManager::getGlobalIndex(int worldIndex, int levelIndex)
{
    int count = 0;
    for (int i=0; i<worldIndex; i++) {
        BubbleLevelInfo * worldInfo = getLevelInfo(i);
        if (!worldInfo) {
            return 0;
        }
        count+= worldInfo->subLevelCount;
        //delete worldInfo;
    }
    return count + levelIndex + 1;
}

CCPoint FMDataManager::getIndexFromGlobalIndex(int globalIndex)
{
    globalIndex--;
    int totalWorld = BubbleServiceFunction_getLevelCount();
    CCPoint ret = ccp(-1, -1);
    for (int i=0; i<totalWorld; i++) {
        BubbleLevelInfo * worldInfo = getLevelInfo(i);
        int subCount = worldInfo->subLevelCount;
        //delete worldInfo;
        if (subCount > globalIndex) {
            ret.x = i;  //world index
            ret.y = globalIndex;
            return ret;
        }
        globalIndex -= subCount;
    }
    return ret;
}
int FMDataManager::getCurrentScore()
{
    if (isInGame()) {
        FMMainScene * scene = (FMMainScene *)getUI(kUI_MainScene);
        FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);
        return game->getCurrentScore();
    }
    return 0;
}
int FMDataManager::getCurrentLeftMoves()
{
    if (isInGame()) {
        FMMainScene * scene = (FMMainScene *)getUI(kUI_MainScene);
        FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);
        return game->getLeftMoves();
    }
    return 0;
}
int FMDataManager::getCurrentUsedMoves()
{
    if (isInGame()) {
        FMMainScene * scene = (FMMainScene *)getUI(kUI_MainScene);
        FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);
        return game->getUsedMoves();
    }
    return 0;
}

CCNode * FMDataManager::getUI(kGameUI uiType)
{
    if (m_cachedUI.find(uiType) != m_cachedUI.end()) {
        return m_cachedUI[uiType];
    }
    switch (uiType) {
        case kUI_MainScene:
        {
            FMMainScene * scene = FMMainScene::create();
            scene->retain();
            m_cachedUI[uiType] = scene;
        }
            break;
        case kUI_DailySign:
        {
            m_cachedUI[uiType] = new FMUIDailySign();
        }
            break;
        case kUI_DailySignBouns:
        {
            m_cachedUI[uiType] = new FMUISignReward();
        }
            break;
        case kUI_SignMakeUp:
        {
            m_cachedUI[uiType] = new FMUISignMakeUp();
        }
            break;
        case kUI_DailyBox:
        {
            m_cachedUI[uiType] = new FMUIDailyBoxPop();
        }
            break;
        case kUI_FriendProfile:
        {
            m_cachedUI[uiType] = new FMUIFriendProfile();
        }
            break;
        case kUI_SendHeart:
        {
            m_cachedUI[uiType] = new FMUISendHeart();
        }
            break;
        case kUI_FBConnect:
        {
            m_cachedUI[uiType] = new FMUIFBConnect();
        }
            break;
        case kUI_Message:
        {
            m_cachedUI[uiType] = new FMUIMessage();
        }
            break;
        case kUI_SpinReward:
        {
            m_cachedUI[uiType] = new FMUISpinReward();
        }
            break;
        case kUI_PrizeList:
        {
            m_cachedUI[uiType] = new FMUIPrizeList();
        }
            break;
        case kUI_BuySpin:
        {
            m_cachedUI[uiType] = new FMUIBuySpin();
        }
            break;
        case kUI_Spin:
        {
            m_cachedUI[uiType] = new FMUISpin();
        }
            break;
        case kUI_InputName:
        {
            m_cachedUI[uiType] = new FMUIInputName();
        }
            break;
        case kUI_UnlimitLife:
        {
            m_cachedUI[uiType] = new FMUIUnlimitLife();
        }
            break;
        case kUI_FamilyTree:
        {
            m_cachedUI[uiType] = new FMUIFamilyTree();
        }
            break;
        case kUI_Invite:
        {
            m_cachedUI[uiType] = new FMUIInvite();
        }
            break;
        case kUI_InviteList:
        {
            m_cachedUI[uiType] = new FMUIInviteList();
        }
            break;
        case kUI_FreeGolds:
        {
            m_cachedUI[uiType] = new FMUIFreeGolds();
        }
            break;
        case kUI_BranchBonus:
        {
            m_cachedUI[uiType] = new FMUIBranchBonus();
        }
            break;
        case kUI_BranchLevel:
        {
            m_cachedUI[uiType] = new FMUIBranchLevel();
        }
            break;
        case kUI_Statusbar:
        {
            m_cachedUI[uiType] = new FMStatusbar();
        }
            break;
        case kUI_LevelStart:
        {
            FMUILevelStart * window = new FMUILevelStart;
            m_cachedUI[uiType] = window;
        }
            break;
        case kUI_WorldMap:
        {
            m_cachedUI[uiType] = new FMUIWorldMap;
        }
            break;
        case kUI_Config:
        {
            m_cachedUI[uiType] = new FMUIConfig;
        }
            break;
        case kUI_GreenPanel:
        {
            m_cachedUI[uiType] = new FMUIGreenPanel;
        }
            break;
        case kUI_Result:
        {
            m_cachedUI[uiType] = new FMUIResult;
        }
            break;
        case kUI_Quit:
        {
            m_cachedUI[uiType] = new FMUIQuit;
        }
            break;
        case kUI_RedPanel:
        {
            m_cachedUI[uiType] = new FMUIRedPanel;
        }
            break;
        case kUI_Booster:
        {
            m_cachedUI[uiType] = new FMUIBooster;
        }
            break;
        case kUI_IAPGold:
        {
            m_cachedUI[uiType] = new FMUIInAppStore;
        }
            break;
//        case kUI_BossModifier:
//        {
//            m_cachedUI[uiType] = new FMUIBossModifier;
//        }
//            break;
        case kUI_BoosterInfo:
        {
            m_cachedUI[uiType] = new FMUIBoosterInfo;
        }
            break;
        case kUI_NeedHeart:
        {
            m_cachedUI[uiType] = new FMUINeedHeart;
        }
            break;
        case kUI_NeedMoney:
        {
            m_cachedUI[uiType] = new FMUINeedMoney;
        }
            break;
        case kUI_LevelEnd:
        {
            m_cachedUI[uiType] = new FMUIRestore;
        }
            break;
        case kUI_UnlockChapter:
        {
            m_cachedUI[uiType] = new FMUIUnlockChapter;
        }
            break;
        case kUI_Pause:
        {
            m_cachedUI[uiType] = new FMUIPause;
        }
            break;
            
        case kUI_StarReward:
        {
            m_cachedUI[uiType] = new FMUIStarReward;
        }
            break;
            
        case kUI_UnlimitLifeDiscount:
        {
            m_cachedUI[uiType] = new FMUIUnlimitLifeDiscount;
        }
            break;
            
        case kUI_GoldIapBonus:
        {
            m_cachedUI[uiType] = new FMUIGoldIapBonus;
        }
            break;
            
        case kUI_RewardBoard:
        {
            m_cachedUI[uiType] = new FMUIRewardBoard;
        }
            break;
            
            
#ifdef DEBUG
        case kUI_Warning:
        {
            m_cachedUI[uiType] = new FMUIWarning;
        }
            break;
#endif
        default:
            break;
    }
    if (m_cachedUI.find(uiType) != m_cachedUI.end()) {
        return m_cachedUI[uiType];
    }
    else {
        return NULL;
    }
}
 

#pragma mark - user save

void FMDataManager::loadGame(const char * userData)
{
    if (m_userSave) {
        m_userSave->release();
    }
    m_userSave = CCJSONConverter::sharedConverter()->dictionaryFrom(userData);
    if (!m_userSave) {
        m_userSave = getUserSave();
    }
    else {
        m_userSave->retain();
    }
    
    initTutorial();
}

void FMDataManager::loadGameFromFB(const char * userData)
{
    if (!m_userSave) {
        m_userSave = getUserSave();
    }
    CCDictionary * levelData = (CCDictionary *)m_userSave->objectForKey("leveldata");

    CCDictionary * tdic = CCJSONConverter::sharedConverter()->dictionaryFrom(userData);
    CCArray * tarry = tdic->allKeys();
    for (int i = 0; i < tarry->count(); i++) {
        const char * key = ((CCString *)tarry->objectAtIndex(i))->getCString();
        CCDictionary * tlevelData = (CCDictionary *)tdic->objectForKey(key);
        
        CCDictionary * currentlevelData = (CCDictionary *)levelData->objectForKey(key);
        if (!currentlevelData) {
            currentlevelData = CCDictionary::create();
            levelData->setObject(currentlevelData, key);
        }
        
        CCArray * ldkeys = tlevelData->allKeys();
        for (int j = 0; j < ldkeys->count(); j++) {
            
            if( ldkeys->objectAtIndex(j) == NULL )
                continue;
            
            const char * ldkey =  ((CCString *)ldkeys->objectAtIndex(j))->getCString();
            if( tlevelData->objectForKey(ldkey) == NULL )
                continue;
            
            if (strcmp(ldkey, "failtimes") == 0) {
                continue;
            }
            
            currentlevelData->setObject(tlevelData->objectForKey(ldkey), ldkey);
        }
    }
    addSaveExp();
    saveGame();
}

void FMDataManager::saveGame()
{
    OBJCHelper::helper()->saveGame();
}

CCDictionary * FMDataManager::getUserSave()
{
    if (!m_userSave) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
        CCString * str = CCString::createWithContentsOfFile("data/initSave.dat");
#else
        CCString * str = CCString::createWithContentsOfFile("initSave.dat");
#endif
        m_userSave = CCJSONConverter::sharedConverter()->dictionaryFrom(str->getCString());
        m_userSave->retain(); 
    }
    return m_userSave;
}

CCDictionary * FMDataManager::getLocalConfig()
{
    if (!m_localConfig) {
        std::string localConfigFilePath = getUserFilePath("localConfig.dat");
        if (isFileExist(localConfigFilePath.c_str())) {
            CCString * str = CCString::createWithContentsOfFile(localConfigFilePath.c_str());
            m_localConfig = CCJSONConverter::sharedConverter()->dictionaryFrom(str->getCString());
            m_localConfig->retain();
        }
        else {
            CCString * str = CCString::createWithContentsOfFile("initConfig.dat");
            m_localConfig = CCJSONConverter::sharedConverter()->dictionaryFrom(str->getCString());
            m_localConfig->retain();
            saveLocalConfig();
        }
    }
    return m_localConfig;
}

void FMDataManager::saveLocalConfig()
{
    CCDictionary * localConfig = getLocalConfig();
    const char * json = CCJSONConverter::sharedConverter()->strFrom(localConfig)->getCString();

    std::string filePath = getUserFilePath("localConfig.dat");
    
	CCLOG("saveFile, path = %s", filePath.c_str());
	
	FILE *fp = fopen(filePath.c_str(), "w");
    
	if (! fp)
	{
		CCLOG("can not create file %s", filePath.c_str());
	}
    else {
        fputs(json, fp);
        fclose(fp);
    }
}

void FMDataManager::resetUserSave()
{
    m_userSave->release();
    m_userSave = NULL;
    getUserSave();
    saveGame();
}

std::string FMDataManager::getUserSaveString()
{
    CCDictionary * userSave = getUserSave();
    const char * str = CCJSONConverter::sharedConverter()->strFrom(userSave)->getCString();
    
    if(str==NULL) str = "";
    
    return std::string(str);
}

CCDictionary * FMDataManager::getLevelUserData()
{
    return getLevelUserDataByIdx(m_worldIndex, m_levelIndex,m_isQuest);
}

CCDictionary* FMDataManager::getLevelUserDataByIdx(int worldIdx, int lvIdx,bool isQuest)
{
    CCDictionary * userSave = getUserSave();
    CCDictionary * levelData = (CCDictionary *)userSave->objectForKey("leveldata");
    std::stringstream ss;
    ss << worldIdx << "-" << lvIdx;
    if (isQuest) {
        ss << "Q";
    }
    
    CCDictionary * retVal = (CCDictionary *)levelData->objectForKey(ss.str());
    if (!retVal) {
        //create new level data
        retVal = CCDictionary::create();
        retVal->setObject(CCNumber::create(0), "highscore");
        retVal->setObject(CCNumber::create(0), "stars");
        retVal->setObject(CCNumber::create(0), "unlocked");
        levelData->setObject(retVal, ss.str());
        addSaveExp();
    }
    return retVal;
}


int FMDataManager::getHighscore()
{
    CCDictionary * levelData = getLevelUserData();
    CCNumber * num = (CCNumber *)levelData->objectForKey("highscore");
    return num->getIntValue();
}

void FMDataManager::setHighscore(int score)
{
    CCDictionary * levelData = getLevelUserData();
    levelData->setObject(CCNumber::create(score), "highscore");
    addSaveExp();
}

int FMDataManager::getStarNum(int world, int level, int quest)
{
    if (world == -1) {
        world = m_worldIndex;
    }
    if (level == -1) {
        level = m_levelIndex;
    }
    bool isq = false;
    if (quest == -1) {
        isq = m_isQuest;
    }else{
        isq = quest == 1;
    }
    
    CCDictionary * levelData = getLevelUserDataByIdx(world, level, isq);
    CCNumber * starNum = (CCNumber *)levelData->objectForKey("stars");
    return starNum->getIntValue();
}

void FMDataManager::setStarNum(int star)
{
    CCDictionary * levelData = getLevelUserData();
    levelData->setObject(CCNumber::create(star), "stars");
    addSaveExp();
}

int FMDataManager::getFailCount()
{
    CCDictionary * levelData = getLevelUserData();
    CCNumber * failTimes = (CCNumber *)levelData->objectForKey("failtimes");
    if (!failTimes) {
        failTimes = CCNumber::create(0);
        levelData->setObject(failTimes, "failtimes");
        addSaveExp();
    }
    return failTimes->getIntValue();
}

void FMDataManager::addFailCount()
{
    if (!m_needFailCount) {
        return;
    }
    int f = getFailCount();
    f++;
    CCDictionary * levelData = getLevelUserData();
    levelData->setObject(CCNumber::create(f), "failtimes");
    addSaveExp();
}

void FMDataManager::resetFailCount()
{
    CCDictionary * levelData = getLevelUserData();
    levelData->setObject(CCNumber::create(0), "failtimes");
    addSaveExp();
}

int FMDataManager::getbalanceCount()
{
    CCDictionary * levelData = getLevelUserData();
    CCNumber * balanceCount = (CCNumber *)levelData->objectForKey("balanceCount");
    if (!balanceCount) {
        balanceCount = CCNumber::create(0);
        levelData->setObject(balanceCount, "balanceCount");
        addSaveExp();
    }
    return balanceCount->getIntValue();
}
void FMDataManager::setbalanceCount(int count)
{
    int t_worldIndex = m_worldIndex;
    int t_levelIndex = m_levelIndex+1;
    bool t_isquest = m_isQuest;
    BubbleLevelInfo * info = getLevelInfo(t_worldIndex);
    if (m_isQuest) {
        if (t_levelIndex >= info->unlockLevelCount) {
            t_levelIndex = 0;
            t_worldIndex ++;
        }
    }else{
        if (t_levelIndex >= info->subLevelCount) {
            t_levelIndex = 0;
            t_isquest = true;
        }
    }
    
    
    CCDictionary * userSave = getUserSave();
    CCDictionary * levelData = (CCDictionary *)userSave->objectForKey("leveldata");
    std::stringstream ss;
    ss << t_worldIndex << "-" << t_levelIndex;
    if (t_isquest) {
        ss << "Q";
    }
    CCDictionary * retVal = (CCDictionary *)levelData->objectForKey(ss.str());
    if (!retVal) {
        //create new level data
        retVal = CCDictionary::create();
        retVal->setObject(CCNumber::create(0), "highscore");
        retVal->setObject(CCNumber::create(0), "stars");
        retVal->setObject(CCNumber::create(0), "unlocked");
        retVal->setObject(CCNumber::create(count), "balanceCount");
        levelData->setObject(retVal, ss.str());
        addSaveExp();
    }else{
        retVal->setObject(CCNumber::create(count), "balanceCount");
        levelData->setObject(retVal, ss.str());
        addSaveExp();
    }
}

void FMDataManager::resetbalanceCount(){
    CCDictionary * levelData = getLevelUserData();
    levelData->setObject(CCNumber::create(0), "balanceCount");
    addSaveExp();
}
bool FMDataManager::isRewardGetted()
{
    CCDictionary * levelData = getLevelUserData();
    CCNumber * num = (CCNumber*)levelData->objectForKey("reward");
    if (!num) {
        num = CCNumber::create(0);
        levelData->setObject(num, "reward");
    }
    bool getted = ((CCNumber *)levelData->objectForKey("reward"))->getIntValue() == 1;
    return getted;
}
void FMDataManager::getReward()
{
    CCDictionary * levelData = getLevelUserData();
    levelData->setObject(CCNumber::create(1), "reward");
    addSaveExp();
}

void FMDataManager::addGameResources(int itemType, int numModify)
{
    if (numModify == 0) {
        return;
    }
    bool modify = true;
    switch (itemType) {
        case kItemType_Gem:
        {
            int num = getGoldNum();
            num += numModify;
            setGoldNum(num);
        }
            break;
        case kItemType_Mushroom:
        {
            int num = getMushroomNum();
            num += numModify;
            setMushroomNum(num);
        }
            break;
        case kItemType_Booster1:
        case kItemType_Booster2:
        case kItemType_Booster3:
        case kItemType_Booster4:
        case kItemType_Booster5:
        case kItemType_Booster6:
        {
            int boosterType = itemType - kItemType_Booster1;
            int num = getBoosterAmount(boosterType);
            num += numModify;
            setBoosterAmount(boosterType, num);
        }
            break; 
        default:
        {
            modify = false;
        }
            break;
    }
    if (modify) {
        addSaveExp();
    }
}
 
void FMDataManager::setBoosterAmount(int booster, int num)
{
    //amount: >=0 locked:-1 none:other
    CCArray * boosters = (CCArray *)getUserSave()->objectForKey("boosters");
    while (booster >= boosters->count()) {
        boosters->addObject(CCNumber::create(0));
    }
    if (booster < boosters->count()) {
        boosters->replaceObjectAtIndex(booster, CCNumber::create(num));
        addSaveExp();
    }
}

void FMDataManager::resetBoosterTimer(int booster)
{
    int time = getBoosterDefaultTime(booster);
    if (time == -1) {
        return;
    }
    int t = getBoosterTime(booster);
    if (t != -1) {
        //still updating
        return;
    }
    
    time += getCurrentTime();
    CCArray * boosters = (CCArray *)getUserSave()->objectForKey("boostertime");
    boosters->replaceObjectAtIndex(booster, CCNumber::create(time));
    addSaveExp();
}

int FMDataManager::getBoosterDefaultTime(int booster)
{
    bool timing = isBoosterTiming(booster);
    if (!timing) {
        return -1;
    }
    static int defaultTimer[3] = {3600 * 6, 3600 * 12, 3600 * 18};
    int time = defaultTimer[booster];
    return time;
}

int FMDataManager::getBoosterTime(int booster)
{
    if (!isBoosterTiming(booster)) {
        return -1;
    }
    CCArray * boosters = (CCArray *)getUserSave()->objectForKey("boostertime");
    CCNumber * n = (CCNumber *)boosters->objectAtIndex(booster);
    return n->getIntValue();
}

void FMDataManager::stopBoosterTimer(int booster)
{
    if (getBoosterDefaultTime(booster) == -1) {
        return;
    }
    CCArray * boosters = (CCArray *)getUserSave()->objectForKey("boostertime");
    boosters->replaceObjectAtIndex(booster, CCNumber::create(-1)); 
}

bool FMDataManager::isBoosterUsable(int type)
{
    if (isBoosterLocked(type)) {
        return false;
    }
    
    int amount = getBoosterAmount(type);
    if (amount > 0) {
        return true;
    }
    return false;
}

bool FMDataManager::isBoosterTiming(int booster)
{
    if (booster == kBooster_MovePlusFive ||
        booster == kBooster_Locked ||
        booster == kBooster_CureRot ||
        booster == kBooster_Harvest1Type ||
        booster == kBooster_Shuffle ||
        booster == kBooster_None) {
        return false;
    }
    if (booster > 2) {
        return false;
    }
    return true;
}

bool FMDataManager::isBoosterLocked(int booster)
{
    if (booster == kBooster_MovePlusFive || booster == kBooster_TCross || booster == kBooster_5Line || booster == kBooster_4Match) {
        return false;
    }
    if (booster == kBooster_Locked) {
        return true;
    }
    int amount = getBoosterAmount(booster);
    if (amount < 0) {
        return true;
    }
    return false;
}

int FMDataManager::getBoosterAmount(int booster)
{
    //amount: >=0 locked:-1 none:other
    CCArray * boosters = (CCArray *)getUserSave()->objectForKey("boosters");
    if (booster < boosters->count()) {
        int amount = ((CCNumber *)boosters->objectAtIndex(booster))->getIntValue();
        return amount;
    }
    return -2;
}

void FMDataManager::getInviteReward(int index)
{
    if (!isInviteRewardUseable(index)) {
        return;
    }
    CCDictionary * usersave = getUserSave();
    CCArray * inviteRewards = (CCArray *)usersave->objectForKey("invitereward");
    inviteRewards->replaceObjectAtIndex(index, CCNumber::create(1));
    
    int currentTime = SNSFunction_getCurrentTime();
    setUnlimitLifeTime(MAX(currentTime, getUnlimitLifeTime()) + getInviteRewardTime(index));
}
bool FMDataManager::isInviteRewardUseable(int index)
{
    CCDictionary * usersave = getUserSave();
    CCArray * inviteRewards = (CCArray *)usersave->objectForKey("invitereward");
    if (!inviteRewards) {
        inviteRewards = CCArray::create();
        usersave->setObject(inviteRewards, "invitereward");
    }
    while (inviteRewards->count() <= index) {
        inviteRewards->addObject(CCNumber::create(0));
    }
    CCNumber * num = (CCNumber *)inviteRewards->objectAtIndex(index);
    return num->getIntValue() == 0;
}
int FMDataManager::getUnlimitLifeTime()
{
    CCDictionary * usersave = getUserSave();
    CCNumber * time = (CCNumber *)usersave->objectForKey("unlimitlifetime");
    if (time) {
        return time->getIntValue();
    }
    return -1;
}
void FMDataManager::setUnlimitLifeTime(int time)
{
    CCDictionary * usersave = getUserSave();
    usersave->setObject(CCNumber::create(time), "unlimitlifetime");
    saveGame();
}
int FMDataManager::getInviteRewardNeedCount(int index)
{
    int rcount = 1000;
#ifdef DEBUG
    switch (index) {
        case 0:
            rcount = 1;
            break;
        case 1:
            rcount = 2;
            break;
        case 2:
            rcount = 3;
            break;
        default:
            break;
    }
#else
    switch (index) {
        case 0:
            rcount = 10;
            break;
        case 1:
            rcount = 20;
            break;
        case 2:
            rcount = 40;
            break;
        default:
            break;
    }
#endif
    return rcount;
}

int FMDataManager::getInviteRewardTime(int index)
{
    int rtime = 0;
    switch (index) {
        case 0:
            rtime = 3600 * 3;
            break;
        case 1:
            rtime = 3600 * 6;
            break;
        case 2:
            rtime = 3600 * 24;
            break;
        default:
            break;
    }
    return rtime;
}

void FMDataManager::setFid(int fid, int type)
{
    getUserSave()->setObject(CCString::createWithFormat("%d",fid), "tempfid");
    getUserSave()->setObject(CCNumber::create(type), "tempftype");
}

CCArray * FMDataManager::getFid()
{
    CCDictionary * usersave = getUserSave();
    CCString * fid = (CCString *)usersave->objectForKey("tempfid");
    CCNumber * ftype = (CCNumber *)usersave->objectForKey("tempftype");
    
    CCArray * array = CCArray::create();
    if (!fid) {
        fid = CCString::create("0");
    }
    array->addObject(fid);
    if (!ftype) {
        ftype = CCNumber::create(4);
    }
    array->addObject(ftype);
    return array;
}

int FMDataManager::getFurthestWorld()
{
    CCArray * f = (CCArray *) getUserSave()->objectForKey("furthestlevel");
    int worldIndex = ((CCNumber *)f->objectAtIndex(0))->getIntValue();
    return worldIndex;
}

int FMDataManager::getFurthestLevel()
{
    CCArray * f = (CCArray *) getUserSave()->objectForKey("furthestlevel");
    int levelIndex = ((CCNumber *)f->objectAtIndex(1))->getIntValue();
    return levelIndex;
}

void FMDataManager::setFurthestLevel(int world, int level, int quest)
{
    if (world == -1) {
        world = m_worldIndex;
    }
    if (level == -1) {
        level = m_levelIndex;
    }
    bool isq;
    if (quest == -1) {
        isq = m_isQuest;
    }else{
        isq = quest == 1;
    }

    CCArray * f = (CCArray *) getUserSave()->objectForKey("furthestlevel");
    int oldWorldIndex = ((CCNumber *)f->objectAtIndex(0))->getIntValue();
    int oldLevelIndex = ((CCNumber *)f->objectAtIndex(1))->getIntValue();
    bool overwrite = false;
    if (world > oldWorldIndex) {
        overwrite = true;
    }
    else if (world == oldWorldIndex && (level > oldLevelIndex || level == -1) ){
        overwrite = true;
    }
    if (overwrite) {
        f->removeAllObjects();
        f->addObject(CCNumber::create(world));
        f->addObject(CCNumber::create(level));
        addSaveExp();
    }
}

bool FMDataManager::isFurthestLevel()
{
    CCArray * f = (CCArray *) getUserSave()->objectForKey("furthestlevel");
    int oldWorldIndex = ((CCNumber *)f->objectAtIndex(0))->getIntValue();
    int oldLevelIndex = ((CCNumber *)f->objectAtIndex(1))->getIntValue();
    if (m_worldIndex == oldWorldIndex && m_levelIndex == oldLevelIndex && !m_isQuest) {
       return true;
    }
    return false;
}

bool FMDataManager::isLevelUnlocked(int world, int level, int quest)
{
    if (world == -1) {
        world = m_worldIndex;
    }
    if (level == -1) {
        level = m_levelIndex;
    }
    bool isq;
    if (quest == -1) {
        isq = m_isQuest;
    }else{
        isq = quest == 1;
    }
    
    CCDictionary * levelData = getLevelUserDataByIdx(world, level, isq);
    CCNumber * unlocked = (CCNumber *)levelData->objectForKey("unlocked");
    if (!unlocked) {
        unlocked = CCNumber::create(0);
    }
    return unlocked->getIntValue() == 1;
}

void FMDataManager::unlockLevel()
{
    CCDictionary * levelData = getLevelUserData();
    levelData->setObject(CCNumber::create(1), "unlocked");
    addSaveExp();
}

bool FMDataManager::isWorldUnlocked()
{
    CCDictionary * userSave = getUserSave();
    CCDictionary * worldUnlocked = (CCDictionary *)userSave->objectForKey("worldUnlocked");
    if (!worldUnlocked) {
        worldUnlocked = CCDictionary::create();
        userSave->setObject(worldUnlocked, "worldUnlocked");
        addSaveExp();
    }
    
    CCString * s = CCString::createWithFormat("%d", m_worldIndex); 
    CCNumber * unlocked = (CCNumber *)worldUnlocked->objectForKey(s->getCString());
    if (unlocked) {
        int u = unlocked->getIntValue();
        if (u == 1) {
            return true;
        }
    }
    else {
        int u = 0;
//        if (m_worldIndex == 0 || m_worldIndex == 1) {
//            u = 1;
//        }
        worldUnlocked->setObject(CCNumber::create(u), s->getCString());
        return u == 1;
    }
    return false;
}

void FMDataManager::unlockWorld(bool iapBuy)
{
    if (isWorldUnlocked()) {
        return;
    }
    CCDictionary * userSave = getUserSave();
    CCDictionary * worldUnlocked = (CCDictionary *)userSave->objectForKey("worldUnlocked");
    CCString * s = CCString::createWithFormat("%d", m_worldIndex);
    worldUnlocked->setObject(CCNumber::create(1), s->getCString());
    addSaveExp();
    
    if (!m_isQuest) {
        return;
    }
    
    BubbleUnlockEpisodeStatInfo *info = new BubbleUnlockEpisodeStatInfo();
    info->episodeIndex = m_worldIndex;
    {
        BubbleLevelInfo * lInfo = getLevelInfo(m_worldIndex);
        BubbleSubLevelInfo * subInfo = lInfo->getUnlockLevel(m_levelIndex);
        info->episodeID = subInfo->ID;
        //delete lInfo;
    }
    {
        int worldIndex = m_worldIndex;
        int levelIndex=  m_levelIndex;
        int count = 0;
        for (int i=0; i<3; i++) {
            setLevel(worldIndex, i, true);
            if (isLevelBeaten()) {
                count++;
            }
        }
        setLevel(worldIndex, levelIndex, true);
        info->passUnlockLevelCount = count;
    }
    info->useLifeCount = getWorldLifeUsed();
    
    info->buyUnlockIAP = iapBuy ? 1 : 0;
    
    int currentTime = getCurrentTime();
    int questBeginTime = getWorldQuestBeginTime();
    info->delayTime = currentTime - questBeginTime;
    
    BubbleServiceFunction_sendEpisodeStats(info);
    delete info;
}

int FMDataManager::getWorldQuestBeginTime()
{
    CCDictionary * userSave = getUserSave();
    CCDictionary * data = (CCDictionary *)userSave->objectForKey("unlockWorldTime");
    if (!data) {
        data = CCDictionary::create();
        userSave->setObject(data, "unlockWorldTime");
        addSaveExp();
    }
    CCString * str = CCString::createWithFormat("%d", m_worldIndex);
    CCNumber * n = (CCNumber *)data->objectForKey(str->getCString());
    if (!n) {
        n = CCNumber::create(-1);
        data->setObject(n, str->getCString());
        addSaveExp();
    }
    return n->getIntValue();
}

void FMDataManager::resetWorldQuestBeginTime()
{
    if (getWorldQuestBeginTime() == -1) {
        CCDictionary * userSave = getUserSave();
        CCDictionary * data = (CCDictionary *)userSave->objectForKey("unlockWorldTime");
        CCString * str = CCString::createWithFormat("%d", m_worldIndex);
        data->setObject(CCNumber::create(getCurrentTime()), str->getCString());
        addSaveExp();
    }
}

bool FMDataManager::isGameCleared()
{
    int world = m_worldIndex;
    int level = m_levelIndex;
    bool quest = m_isQuest;
    bool branch = m_isBranch;
    int count = BubbleServiceFunction_getLevelCount();
    BubbleLevelInfo * info = getLevelInfo(count-1);
    int subcount = info->subLevelCount;
    setLevel(count-1, subcount-1, false);
    bool isCleared = isLevelBeaten();
    setLevel(world, level, quest, branch);
    return isCleared;
}
bool FMDataManager::isChallengeCleared(int idx)
{
    int wi = getWorldIndex();
    int li = getLevelIndex();
    bool quest = isQuest();
    bool branch = isBranch();
    BubbleLevelInfo * info = getLevelInfo(idx);
    bool alldone = true;
    if (info && info->unlockLevelCount > 0) {
        for (int i = 0; i < info->unlockLevelCount; i++) {
            setLevel(idx, i, true);
            if (!isLevelBeaten()) {
                alldone = false;
                break;
            }
        }
    }else{
        alldone = false;
    }
    setLevel(wi, li, quest, branch);
    return alldone;
}

bool FMDataManager::isWorldOpened()
{
    CCDictionary * userSave = getUserSave();
    CCDictionary * data = (CCDictionary *)userSave->objectForKey("worldOpened");
    if (!data) {
        data = CCDictionary::create();
        data->setObject(CCNumber::create(1), "0");
//        data->setObject(CCNumber::create(1), "1");
        userSave->setObject(data, "worldOpened");
        addSaveExp();
    } 
    CCString * s = CCString::createWithFormat("%d", m_worldIndex);
    CCNumber * worldOpened = (CCNumber *)data->objectForKey(s->getCString());
    if (!worldOpened) {
        worldOpened = CCNumber::create(0);
        data->setObject(worldOpened, s->getCString());
        addSaveExp();
    }
    int n = worldOpened->getIntValue();
    return n == 1;
}

void FMDataManager::openWorld()
{
    if (isWorldOpened()) {
        return;
    }
    CCDictionary * userSave = getUserSave();
    CCDictionary * data = (CCDictionary *)userSave->objectForKey("worldOpened");
    CCString * s = CCString::createWithFormat("%d", m_worldIndex);
    data->setObject(CCNumber::create(1), s->getCString());
    addSaveExp();
}

int FMDataManager::getWorldLifeUsed()
{
    CCDictionary * userSave = getUserSave();
    CCDictionary * data = (CCDictionary *)userSave->objectForKey("unlockWorldLife");
    if (!data) {
        data = CCDictionary::create();
        userSave->setObject(data, "unlockWorldLife");
        addSaveExp();
    }
    CCString * str = CCString::createWithFormat("%d", m_worldIndex);
    CCNumber * n = (CCNumber *)data->objectForKey(str->getCString());
    if (!n) {
        n = CCNumber::create(0);
        data->setObject(n, str->getCString());
        addSaveExp();
    }
    return n->getIntValue();
}

void FMDataManager::addWorldLifeUsed(int delta)
{
    if (!m_isQuest || isWorldUnlocked()) {
        return;
    }
    
    int lifeUsed = getWorldLifeUsed();
    lifeUsed += delta;
    
    CCDictionary * userSave = getUserSave();
    CCDictionary * data = (CCDictionary *)userSave->objectForKey("unlockWorldLife");
    CCString * str = CCString::createWithFormat("%d", m_worldIndex);
    data->setObject(CCNumber::create(lifeUsed), str->getCString());
    addSaveExp();
}

bool FMDataManager::isWorldBeaten(bool checkQuest)
{
    BubbleLevelInfo * worldInfo = getLevelInfo(m_worldIndex);
    bool n = false;
    int oldLevelIndex = m_levelIndex;
    bool isQuest = m_isQuest;
    bool isBranch = m_isBranch;
    if (worldInfo) {
        int subCount = worldInfo->subLevelCount;
        int levelIndex = subCount - 1;
        setLevel(m_worldIndex, levelIndex, false);
        n = isLevelBeaten();
        setLevel(m_worldIndex, oldLevelIndex, isQuest);
    }
    if (n && checkQuest) {
        if (worldInfo->unlockLevelCount > 0) {
            //check the last quest level is beaten
            setLevel(m_worldIndex, 0, true);
            n = isLevelBeaten();
            setLevel(m_worldIndex, oldLevelIndex, isQuest);
        }
    }
    
    int oldWorldIndex = m_worldIndex;
    setLevel(m_worldIndex+1, 0, false);
    if (isLevelUnlocked()) {
        n = true;
    }
    setLevel(oldWorldIndex, oldLevelIndex, isQuest, isBranch);
    //delete worldInfo;
    return n;
}

bool FMDataManager::isLevelBeaten(int world, int level, int quest)
{
    if (world == -1) {
        world = m_worldIndex;
    }
    if (level == -1) {
        level = m_levelIndex;
    }
    bool isq = false;
    if (quest == -1) {
        isq = m_isQuest;
    }else{
        isq = quest == 1;
    }

    CCDictionary * levelData = getLevelUserDataByIdx(world, level, isq);
    CCNumber * num = (CCNumber *)levelData->objectForKey("beaten");
    if (!num) {
        num = CCNumber::create(0);
    }
    bool beaten = num->getIntValue() == 1;
    return beaten;
//    if (m_isQuest) {
//        if (isWorldUnlocked()) {
//            return true;
//        }
//        else {
//            return getStarNum() > 0;
//        }
//    }
//    else {
//        return getStarNum() > 0;
//    }
}

void FMDataManager::setLevelBeaten(int t)
{
    CCDictionary * levelData = getLevelUserData();
    levelData->setObject(CCNumber::create(t), "beaten");
}

bool FMDataManager::isPreLevelBeaten(int world, int level, int quest)
{
    if (world == -1) {
        world = m_worldIndex;
    }
    if (level == -1) {
        level = m_levelIndex;
    }
    bool isq = false;
    if (quest == -1) {
        isq = m_isQuest;
    }else{
        isq = quest == 1;
    }
    
    BubbleLevelInfo * info = getLevelInfo(world);
    if (level > 0) {
        level--;
    }else{
        if (isq) {
            level = info->subLevelCount-1;
            isq = false;
        }else{
            world--;
            level = 0;
            isq = true;
            if (world < 0) {
                return true;
            }
        }
    }
    bool flag = isLevelBeaten(world, level, quest)||getStarNum(world, level, quest)>0;
    return flag;
}

void FMDataManager::resetQuestCD()
{
    CCDictionary * save = getUserSave();
    save->setObject(CCNumber::create( GameConfig::getQuestWaitingTime() + getCurrentTime()), "questcooldown");
    addSaveExp();
}

void FMDataManager::cleanQuestCD()
{
    CCDictionary * save = getUserSave();
    save->setObject(CCNumber::create(-1), "questcooldown");
}

int FMDataManager::getQuestCD()
{
    CCDictionary * save = getUserSave();
    CCNumber * time = (CCNumber *)save->objectForKey("questcooldown");
    if (!time) {
        cleanQuestCD();
        time = (CCNumber *)save->objectForKey("questcooldown");
    }
    return time->getIntValue();
}
int FMDataManager::getSpinTimes()
{
    CCDictionary * save = getUserSave();
    CCNumber * times = (CCNumber *)save->objectForKey("spintimes");
    if (!times) {
        times = CCNumber::create(0);
        save->setObject(times, "spintimes");
    }
    return times->getIntValue();
}
void FMDataManager::setSpinTimes(int t)
{
    CCDictionary * save = getUserSave();
    CCNumber * times = CCNumber::create(t);
    save->setObject(times, "spintimes");
}

void FMDataManager::addSpinTimes()
{
    CCDictionary * save = getUserSave();
    CCNumber * times = (CCNumber *)save->objectForKey("spintimes");
    if (!times) {
        times = CCNumber::create(0);
    }
    int t = times->getIntValue();
    if (t < 0) {
        t = 0;
    }
    t += 1;
    save->setObject(CCNumber::create(t), "spintimes");
}
void FMDataManager::useSpinTimes()
{
    CCDictionary * save = getUserSave();
    CCNumber * times = (CCNumber *)save->objectForKey("spintimes");
    if (!times) {
        times = CCNumber::create(0);
    }
    int t = times->getIntValue();
    t -= 1;
    if (t < 0) {
        t = 0;
    }
    CCNumber * count = (CCNumber *)save->objectForKey("spincount");
    if (!count) {
        count = CCNumber::create(0);
    }
    int c = count->getIntValue();
    c += 1;
    save->setObject(CCNumber::create(c), "spincount");
    save->setObject(CCNumber::create(t), "spintimes");
}
int FMDataManager::getSpinCount()
{
    CCDictionary * save = getUserSave();
    CCNumber * count = (CCNumber *)save->objectForKey("spincount");
    if (!count) {
        count = CCNumber::create(0);
    }
    return count->getIntValue();
}
void FMDataManager::setSpinCount(int t)
{
    CCDictionary * save = getUserSave();
    save->setObject(CCNumber::create(t), "spincount");
}
bool FMDataManager::isNewJelly(int idx)
{
    CCDictionary * save = getUserSave();
    CCDictionary* newdic = (CCDictionary*)save->objectForKey("newjelly");
    if (!newdic) {
        newdic = CCDictionary::create();
    }
    CCNumber* n = (CCNumber*)newdic->objectForKey(CCString::createWithFormat("%d",idx)->m_sString);
    if (!n) {
        n = CCNumber::create(0);
    }
    bool flag = n->getIntValue() != 0;
    return flag;
}
void FMDataManager::setNewJelly(int idx, bool isNew)
{
    CCDictionary * save = getUserSave();
    CCDictionary* newdic = (CCDictionary*)save->objectForKey("newjelly");
    if (!newdic) {
        newdic = CCDictionary::create();
    }
    newdic->setObject(CCNumber::create(isNew), CCString::createWithFormat("%d",idx)->m_sString);
    save->setObject(newdic, "newjelly");
}
bool FMDataManager::haveNewJelly()
{
    CCDictionary * save = getUserSave();
    CCDictionary* newdic = (CCDictionary*)save->objectForKey("newjelly");
    if (!newdic) {
        return false;
    }
    for (int i = 0; i < newdic->allKeys()->count(); i++) {
        CCString* key = (CCString*)newdic->allKeys()->objectAtIndex(i);
        CCNumber* n = (CCNumber*)newdic->objectForKey(key->m_sString);
        if (n->getIntValue() != 0) {
            return true;
        }
    }
    return false;
}
bool FMDataManager::haveNewBranchLevel()
{
    bool flag = false;
    CCDictionary * save = getUserSave();
    CCDictionary* newdic = (CCDictionary*)save->objectForKey("branchlevelcount");
    if (!newdic) {
        newdic = CCDictionary::create();
    }
    for (int i = 0; i < getFurthestWorld()+1; i++) {
        BubbleLevelInfo* info = getLevelInfo(i);
        if (!info) {
            continue;
        }
        int c = info->unlockLevelCount;
        CCNumber* n = (CCNumber*)newdic->objectForKey(CCString::createWithFormat("%d",i)->getCString());
        if (!n) {
            n = CCNumber::create(c);
        }else{
            if (c > n->getIntValue()) {
                int wi = getWorldIndex();
                int li = getLevelIndex();
                bool quest = isQuest();
                bool branch = isBranch();
                setLevel(i, 0, true);
                bool beaten = isLevelBeaten();
                setNewJelly(i, beaten);
                if (beaten) {
                    flag = true;
                }
                setLevel(wi, li, quest, branch);
            }
            n->setValue(c);
        }
        newdic->setObject(n, CCString::createWithFormat("%d",i)->getCString());
    }
    save->setObject(newdic, "branchlevelcount");
    return flag;
}

CCDictionary* FMDataManager::getFrdDic()
{
    if (m_frdDic == NULL) {
        m_frdDic = CCDictionary::create();
        m_frdDic->retain();
    }
    return m_frdDic;
}

void FMDataManager::setFrdMapDic(CCDictionary * dic)
{
    if (!dic) {
        return;
    }
    CCDictionary * frdDic = getFrdDic();
    frdDic->setObject(dic, "mapdata");
}

void FMDataManager::insertFrdMapDic(CCDictionary * dic)
{
    if (!dic) {
        return;
    }
    CCDictionary * mapdata = getFrdMapDic();
    if (!mapdata) {
        return;
    }
    CCArray * list = (CCArray *)mapdata->objectForKey("list");
    if (!list) {
        list = CCArray::create(dic,NULL);
    }else{
        list->addObject(dic);
    }
    mapdata->setObject(list, "list");
}

CCDictionary * FMDataManager::getFrdMapDic()
{
    CCDictionary * frdDic = getFrdDic();
    CCDictionary * mapdata = (CCDictionary*)frdDic->objectForKey("mapdata");
    return mapdata;
}
void FMDataManager::setFrdLevelDic(CCDictionary * dic)
{
    CCDictionary * frdDic = getFrdDic();
    CCArray * list = (CCArray *)dic->objectForKey("list");
    CCDictionary * levelDic = (CCDictionary *)dic->objectForKey("userobject");
    if (levelDic && list) {
        CCNumber * world = (CCNumber *)levelDic->objectForKey("world");
        CCNumber * level = (CCNumber *)levelDic->objectForKey("level");
        CCNumber * q = (CCNumber *)levelDic->objectForKey("quest");
        if (world && level && q) {
            int wi = world->getIntValue();
            int li = level->getIntValue();
            bool quest = q->getIntValue() == 1;
            
            std::stringstream ss;
            ss << wi << "-" << li;
            if (quest) {
                ss << "Q";
            }
            frdDic->setObject(list, ss.str());
        }
    }
}
CCArray * FMDataManager::getFrdLevelDic()
{
    CCDictionary * frdDic = getFrdDic();
    std::stringstream ss;
    ss << m_worldIndex << "-" << m_levelIndex;
    if (m_isQuest) {
        ss << "Q";
    }
    
    return (CCArray *)frdDic->objectForKey(ss.str());
}

void FMDataManager::addSaveExp()
{
    CCDictionary * save = getUserSave();
    int exp = getSaveExp();
    exp++;
    save->setObject(CCNumber::create(exp), "cnt");
}

int FMDataManager::getSaveExp()
{ 
    CCDictionary * save = getUserSave();
    CCNumber * exp = (CCNumber *)save->objectForKey("cnt");
    if (!exp) {
        exp = CCNumber::create(0);
        //新玩家
#ifdef DEBUG
    save->setObject(CCNumber::create(60 *10 + getCurrentTime()), kNewPlayerUnlimitLifeDiscountTime);
#else
    save->setObject(CCNumber::create(86400 *3 + getCurrentTime()), kNewPlayerUnlimitLifeDiscountTime);
#endif
        saveGame();
    }
    return exp->getIntValue();
}

void FMDataManager::setLevelTo(int level)
{ 
    int globalIndex = level;
    int currentworld = m_worldIndex;
    int currentlevel = m_levelIndex;
    bool isquest = m_isQuest;
    
    int totalWorld = BubbleServiceFunction_getLevelCount();
    for (int i=0; i<totalWorld; i++) {
        BubbleLevelInfo * worldInfo = getLevelInfo(i);
        int subCount = worldInfo->subLevelCount;
        //delete worldInfo;
        if (globalIndex < 0) {
            break;
        }
        setLevel(i, 0, false);
        openWorld();
        bool willbreak = false;
        if (subCount > globalIndex) {
            subCount = globalIndex;
            willbreak = true;
        }
        else {
            unlockWorld();
        }
        globalIndex -= subCount;

        for (int j=0; j<subCount; j++) {
            //make the level beaten
            setLevel(i, j, false);
            if (getStarNum() < 1) {
                setStarNum(1);
                unlockLevel();
            }
        }
        if (willbreak) {
            break;
        }
    }
    setLevel(currentworld, currentlevel, isquest);
}

#pragma mark - config
bool FMDataManager::isMusicOn()
{
    CCDictionary * userSave = getLocalConfig();
    CCNumber * music = (CCNumber *)userSave->objectForKey("music");
    if (!music) {
        music = CCNumber::create(1);
        userSave->setObject(music, "music"); 
    }
    return music->getIntValue() == 1;
}

bool FMDataManager::isSFXOn()
{
    CCDictionary * userSave = getLocalConfig();
    CCNumber * music = (CCNumber *)userSave->objectForKey("sfx");
    if (!music) {
        music = CCNumber::create(1);
        userSave->setObject(music, "sfx"); 
    }
    return music->getIntValue() == 1;
}

void FMDataManager::setMusicOn(bool on)
{
    CCDictionary * userSave = getLocalConfig();
    int n = on ? 1 : 0;
    userSave->setObject(CCNumber::create(n), "music");
    saveLocalConfig();
}

void FMDataManager::setSFXOn(bool on)
{
    CCDictionary * userSave = getLocalConfig();
    int n = on ? 1 : 0;
    userSave->setObject(CCNumber::create(n), "sfx"); 
    saveLocalConfig();
}

#pragma mark - status

int FMDataManager::getLifeNum()
{
    CCDictionary * saveData = getUserSave();
    CCNumber * num = (CCNumber *)saveData->objectForKey("life");
    int value = num->getIntValue();
    return value;
}

int FMDataManager::getGoldNum()
{
    CCDictionary * saveData = getUserSave();
    CCNumber * num = (CCNumber *)saveData->objectForKey("goldbar");
    int value = num->getIntValue();
    return value;
}

int FMDataManager::getMushroomNum()
{
    CCDictionary * saveData = getUserSave();
    CCNumber * num = (CCNumber *)saveData->objectForKey("mushroom");
    if (!num) {
        num = CCNumber::create(10);
        saveData->setObject(num, "mushroom");
        addSaveExp();
    }
    int value = num->getIntValue();
    return value;
}

void FMDataManager::setMushroomNum(int n)
{
    CCDictionary * saveData = getUserSave();
    saveData->setObject(CCNumber::create(n), "mushroom");
    addSaveExp();
}

void FMDataManager::setLifeNum(int n)
{
    CCDictionary * saveData = getUserSave();
    saveData->setObject(CCNumber::create(n), "life");
    addSaveExp();
}

void FMDataManager::setBeanNum(int n)
{
    CCDictionary * saveData = getUserSave();
    saveData->setObject(CCNumber::create(n), "magicbean");
    addSaveExp();
    updateStatusBar();
}

void FMDataManager::setGoldNum(int n)
{
    CCDictionary * saveData = getUserSave();
    saveData->setObject(CCNumber::create(n), "goldbar");
    addSaveExp();
    updateStatusBar();
}

bool FMDataManager::useMoney(int n, const char * booster)
{
    bool result = false;
    int price = abs(n);
    int gold = getGoldNum();
    if (gold >= price) {
        OBJCHelper::helper()->trackBuyBooster(booster, abs(n));
        //ok
        gold -= price;
        setGoldNum(gold);
        result = true;
    }
    else {
        //not enough
#ifdef BRANCH_CN
        FMUIInAppStore * window = (FMUIInAppStore *)getUI(kUI_IAPGold);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
#else
        FMUINeedMoney * window = (FMUINeedMoney *)getUI(kUI_NeedMoney);
        window->setNeedNumber(price - gold);
        window->setClassState(0);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
#endif
    }
    return result;
}

int FMDataManager::getNextLifeTime()
{
    CCDictionary * saveData = getUserSave();
    CCNumber * num = (CCNumber *)saveData->objectForKey("time");
    int value = num->getIntValue();
    return value;
}

void FMDataManager::setNextLifeTime(int time)
{
    CCDictionary * saveData = getUserSave();
    saveData->setObject(CCNumber::create(time), "time");
    addSaveExp();
}

void FMDataManager::resetNextLifeTime()
{  
    setNextLifeTime(kRecoverTime+getCurrentTime());
    updateStatusBar();
}

bool FMDataManager::isLifeUpgraded()
{
    CCDictionary * saveData = getUserSave();
    CCNumber * num = (CCNumber *)saveData->objectForKey("maxlifeunlock");
    int value = num->getIntValue();
    return value == 1;
}

void FMDataManager::upgradeLife()
{
    CCDictionary * saveData = getUserSave();
    saveData->setObject(CCNumber::create(1), "maxlifeunlock");
    addSaveExp();
}

bool FMDataManager::isLifeFull()
{
    int life = getLifeNum();
    int maxlife = getMaxLife();
    return life >= maxlife;
}

int FMDataManager::getMaxLife()
{
    if (isLifeUpgraded()) {
        return 8;
    }
    return 5;
}

bool FMDataManager::useLife()
{
    bool purchased = hasPurchasedUnlimitLife();
    if (getUnlimitLifeTime() > getCurrentTime() || purchased) {
        return true;
    }
    int life = getLifeNum();
    if (life > 0) {
        life--;
        setLifeNum(life);
        int nextTime = getNextLifeTime();
        if (nextTime == -1) {
            resetNextLifeTime();
        }
        return true;
    }
    else {
        FMUINeedHeart * window = (FMUINeedHeart *)getUI(kUI_NeedHeart);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
    }
    return false;
}

#pragma mark - tutorial
void FMDataManager::initTutorial()
{
    m_tutorials->removeAllObjects();
    //create instances
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    CCString * str = CCString::createWithContentsOfFile("data/tutorial_android.dat");
#else
    CCString * str = CCString::createWithContentsOfFile("tutorial.dat");
#endif
    CCDictionary * tuts = CCJSONConverter::sharedConverter()->dictionaryFrom(str->getCString());
    CCArray * array = (CCArray *)tuts->objectForKey("tutorials");
    if (array) {
        for (int i=0; i<array->count(); i++) {
            CCDictionary * tut = (CCDictionary *)array->objectAtIndex(i);
            int tid = ((CCNumber *)tut->objectForKey("tid"))->getIntValue();
            CCNumber* r = (CCNumber*)tut->objectForKey("repeat");
            bool repeat = r!=NULL && r->getIntValue() == 1;
            if (!isTutorialDone(tid) || repeat) {
                m_tutorials->addObject(tut);
            }
        }
    }
}

void FMDataManager::checkNewTutorial(const char * event)
{
    if (m_currentTutorial) {
        CCLOG("TUTORIAL IS NOT FINISHED YET!");
        int tid = ((CCNumber *)m_currentTutorial->objectForKey("tid"))->getIntValue();
        finishTutorial(tid);
        m_tutorials->removeObject(m_currentTutorial);
        m_currentTutorial = NULL;
        m_currentTutorialPhaseIndex = 0;
//        FMTutorial::tut()->updateTutorial(NULL);
//        FMTutorial::tut()->setVisible(false);
    }
    
    for (int i=0; i<m_tutorials->count(); i++) {
        CCDictionary * tut = (CCDictionary *)m_tutorials->objectAtIndex(i);
        CCNumber * tid = (CCNumber *)tut->objectForKey("tid");
        CCNumber * basetid = (CCNumber *)tut->objectForKey("basetid");
        if (basetid) {
            //check base tutorial is done?
            if (!isTutorialDone(basetid->getIntValue())) {
                continue;
            }
        }
        
        CCString * uiStr = (CCString *)tut->objectForKey("ui");
        bool checkLevelBeaten = false;
        if (uiStr) {
            const char * uis = uiStr->getCString();
            FMMainScene * mainScene = (FMMainScene *)getUI(kUI_MainScene);
            if (strcmp(uis, "world") == 0) {
                checkLevelBeaten = true;
                if (mainScene->getCurrentSceneType() != kWorldMapNode) {
                    continue;
                }else if(m_worldInPhase){
                    continue;
                }

            }
            else if (strcmp(uis, "game") == 0) {
                if (mainScene->getCurrentSceneType() != kGameNode) {
                    continue;
                }
            }
            else {
                //check current ui
                GAMEUI * ui = GAMEUI_Scene::uiSystem()->getCurrentUI();
                if (!ui) {
                    continue;
                }
                const char * classType = ui->classType();
                if (strcmp(classType, uis) != 0) {
                    continue;
                }
                else {
                    CCNumber * uiState = (CCNumber *)tut->objectForKey("uiState");
                    if (uiState) {
                        //check ui state
                        if (uiState->getIntValue() != ui->classState()) {
                            continue;
                        }
                    } 
                }
            }
        }
        
        CCString * checkLevel = (CCString *)tut->objectForKey("checkLevel");
        if (checkLevel && strcmp(checkLevel->getCString(), "pass") == 0) {
            int wi = m_worldIndex;
            int li = m_levelIndex;
            bool q = m_isQuest;
            bool b = m_isBranch;
            CCNumber * world = (CCNumber *)tut->objectForKey("world");
            CCNumber * level = (CCNumber *)tut->objectForKey("level");
            CCNumber * isQuest = (CCNumber *)tut->objectForKey("quest");
            if (world) {
                m_worldIndex = world->getIntValue();
            }
            if (level) {
                m_levelIndex = level->getIntValue();
            }
            if (isQuest) {
                m_isQuest = isQuest->getIntValue() == 1;
            }
            if (strcmp(checkLevel->getCString(), "pass") == 0) {
                setLevel(m_worldIndex, m_levelIndex, m_isQuest);
                bool isBeaten = isLevelBeaten();
                setLevel(wi, li, q, b);
                if (!isBeaten) {
                    continue;
                }
            }
        }else{
            CCNumber * world = (CCNumber *)tut->objectForKey("world");
            if (world) {
                //check world
                if (m_worldIndex != world->getIntValue()) {
                    continue;
                }
            }
            
            CCNumber * level = (CCNumber *)tut->objectForKey("level");
            if (level) {
                if (m_levelIndex != level->getIntValue()) {
                    continue;
                }
                
                if (checkLevelBeaten && !isLevelBeaten()) {
                    continue;
                }
            }
            
            CCNumber * isQuest = (CCNumber *)tut->objectForKey("quest");
            if (isQuest) {
                if (m_isQuest != (isQuest->getIntValue() == 1)) {
                    continue;
                }
            }
            
            if (checkLevel && strcmp(checkLevel->getCString(), "next") == 0) {
                int wi = m_worldIndex;
                int li = m_levelIndex;
                bool q = m_isQuest;
                bool b = m_isBranch;
                CCNumber * world = (CCNumber *)tut->objectForKey("world");
                CCNumber * level = (CCNumber *)tut->objectForKey("level");
                CCNumber * isQuest = (CCNumber *)tut->objectForKey("quest");
                if (world) {
                    m_worldIndex = world->getIntValue();
                }
                if (level) {
                    m_levelIndex = level->getIntValue();
                }
                if (isQuest) {
                    m_isQuest = isQuest->getIntValue() == 1;
                }

                BubbleLevelInfo* info = getLevelInfo(m_worldIndex);
                if (info) {
                    if (isQuest) {
                        setLevel(m_worldIndex+1, 0, false);
                    }else{
                        if (m_levelIndex + 1 < info->subLevelCount - 1) {
                            setLevel(m_worldIndex, m_levelIndex+1, false);
                        }else{
                            setLevel(m_worldIndex, 0, true);
                        }
                    }
                }
                bool isBeaten = isLevelBeaten();
                setLevel(wi, li, q, b);
                if (isBeaten) {
                    continue;
                }
            }
        }
        
        CCString * triggerevent = (CCString *)tut->objectForKey("event");
        if (event) {
            if (!triggerevent) {
                continue;
            }
            else {
                if (strcmp(triggerevent->getCString(), event) != 0) {
                    continue;
                }
            }
        }
        else {
            if (triggerevent) {
                continue;
            }
        }
        
        CCArray * phases = (CCArray *)tut->objectForKey("phase");
        if (phases->count() > 0) {
            CCNumber* r = (CCNumber*)tut->objectForKey("repeat");
            CCNumber * seed = (CCNumber *)tut->objectForKey("seed");
            if (seed) {
                int gameSeed = seed->getIntValue();
#ifdef DEBUG
                CCDictionary * levelData = getLevelData(m_localMode);
#else
                CCDictionary * levelData = getLevelData(false);
#endif
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
                CCArray * seeds = (CCArray *)levelData->objectForKey("seeds");
                if (seeds && seeds->count() > 0) {
                    int r = FMDataManager::getRandom() % seeds->count();
                    CCNumber * n = (CCNumber *)seeds->objectAtIndex(r);
                    gameSeed = n->getIntValue();
   
                }
#endif
                FMDataManager::sharedManager()->setRandomSeed(gameSeed);
                setControlflag(false);
            }
            CCDictionary * p = (CCDictionary *)phases->objectAtIndex(0);
            CCNumber * booster = (CCNumber *)p->objectForKey("booster");
            if (booster) {
                if (getBoosterAmount(booster->getIntValue()) < 0) {
                    setBoosterAmount(booster->getIntValue(), 0);
                }
            }else{
                m_currentTutorial = tut;
                m_currentTutorialPhaseIndex = 0;
                return;
            }
//            tutorialBegin();
        }
    }
}

void FMDataManager::tutorialBegin()
{
    if (m_currentTutorial) {
        //update tutorials
        FMTutorial::tut()->updateTutorial(m_currentTutorial);
    }
}

void FMDataManager::tutorialNextPhase()
{
    if (!m_currentTutorial) {
        checkNewTutorial();
        tutorialBegin();
    }
    else {
        CCArray * phases = (CCArray *)m_currentTutorial->objectForKey("phase");
        if (phases->count() > m_currentTutorialPhaseIndex) {
            //update tutorials
            FMTutorial::tut()->updateTutorial(m_currentTutorial,m_currentTutorialPhaseIndex);
        } 
    }
}

bool FMDataManager::isTutorialDone(int tid)
{
    CCDictionary * save = getUserSave();
    CCArray * tuts = (CCArray *)save->objectForKey("tutorials");
    if (!tuts) {
        tuts = CCArray::create();
        save->setObject(tuts, "tutorials");
    }
    bool done = false;
    for (int i=0; i<tuts->count(); i++) {
        CCNumber * n = (CCNumber *)tuts->objectAtIndex(i);
        if (n->getIntValue() == tid) {
            done = true;
        }
    }
    return done;
}

void FMDataManager::checkStableTrigger()
{
    if (m_currentTutorial) {
        CCArray * phases = (CCArray *)m_currentTutorial->objectForKey("phase");
        if (phases->count() > m_currentTutorialPhaseIndex) {
            CCDictionary * phaseData = (CCDictionary *)phases->objectAtIndex(m_currentTutorialPhaseIndex);
            CCNumber * stable = (CCNumber *)phaseData->objectForKey("stable");
            if (stable != NULL && stable->getIntValue() == 1) {
                tutorialNextPhase();
            }
        }
    }
}

void FMDataManager::clearAllTutorial()
{
    CCDictionary * save = getUserSave();
    CCArray * tuts = (CCArray *)save->objectForKey("tutorials");
    if (!tuts) {
        return;
    }
    tuts->removeAllObjects();
    m_tutorials->removeAllObjects();
    m_currentTutorial = NULL;
}

void FMDataManager::finishTutorial(int tid)
{
    setControlflag(true);
    if (!isTutorialDone(tid)) {
        CCDictionary * save = getUserSave();
        CCArray * tuts = (CCArray *)save->objectForKey("tutorials");
        tuts->addObject(CCNumber::create(tid));
    }
    FMMainScene * mainScene = (FMMainScene *)getUI(kUI_MainScene);
    if (mainScene->getCurrentSceneType() == kWorldMapNode) {
        FMWorldMapNode* wd = (FMWorldMapNode*)mainScene->getNode(kWorldMapNode);
        if (wd->getCurrentPhaseType() == kPhase_Tutorial) {
            wd->phaseDone();
        }
    }
}
void FMDataManager::tutorialSkip()
{
    if (m_currentTutorial) {
        FMTutorial * tut = FMTutorial::tut();
        tut->fade(false);
        
        CCNumber* r = (CCNumber*)m_currentTutorial->objectForKey("repeat");
        bool repeat = r!=NULL && r->getIntValue() == 1;
        CCArray * phases = (CCArray *)m_currentTutorial->objectForKey("phase");
        if (repeat) {
            m_currentTutorialPhaseIndex = phases->count();
            CCNumber * tid = (CCNumber *)m_currentTutorial->objectForKey("tid");
            finishTutorial(tid->getIntValue());
            FMTutorial::tut()->tutorialEnd(m_currentTutorial);
            m_currentTutorial = NULL;
        }else{
            phases->removeAllObjects();
            CCNumber * tid = (CCNumber *)m_currentTutorial->objectForKey("tid");
            finishTutorial(tid->getIntValue());
            FMTutorial::tut()->tutorialEnd(m_currentTutorial);
            m_tutorials->removeObject(m_currentTutorial);
            m_currentTutorial = NULL;
            }
    }
}

void FMDataManager::tutorialPhaseDone()
{
    if (m_currentTutorial) {
        FMTutorial * tut = FMTutorial::tut();
        tut->fade(false);
        
        CCNumber* r = (CCNumber*)m_currentTutorial->objectForKey("repeat");
        bool repeat = r!=NULL && r->getIntValue() == 1;
        CCArray * phases = (CCArray *)m_currentTutorial->objectForKey("phase");
        if (repeat) {
            CCDictionary * tp = (CCDictionary *)phases->objectAtIndex(m_currentTutorialPhaseIndex);
            CCNumber * step = (CCNumber *)tp->objectForKey("step");
            if (step && step->getIntValue() > 0) {
                OBJCHelper::helper()->trackTutorial(step->getIntValue());
            }
            m_currentTutorialPhaseIndex ++;
            if (phases->count() <= m_currentTutorialPhaseIndex) {
                //tutorial done
                CCNumber * tid = (CCNumber *)m_currentTutorial->objectForKey("tid");
                finishTutorial(tid->getIntValue());
                FMTutorial::tut()->tutorialEnd(m_currentTutorial);
                m_currentTutorial = NULL;
            }
            else {
                CCDictionary * phaseData = (CCDictionary *)phases->objectAtIndex(m_currentTutorialPhaseIndex);
                CCNumber * shownow = (CCNumber*)phaseData->objectForKey("shownow");
                if (shownow && shownow->getIntValue()==1) {
                    tutorialNextPhase();
                }
            }
        }else{
            CCDictionary * tp = (CCDictionary *)phases->objectAtIndex(0);
            CCNumber * step = (CCNumber *)tp->objectForKey("step");
            if (step && step->getIntValue() > 0) {
                OBJCHelper::helper()->trackTutorial(step->getIntValue());
            }

            phases->removeObjectAtIndex(0);
            if (phases->count() == 0) {
                //tutorial done
                CCNumber * tid = (CCNumber *)m_currentTutorial->objectForKey("tid");
                finishTutorial(tid->getIntValue());
                FMTutorial::tut()->tutorialEnd(m_currentTutorial);
                m_tutorials->removeObject(m_currentTutorial);
                m_currentTutorial = NULL;
            }
            else {
                CCDictionary * phaseData = (CCDictionary *)phases->objectAtIndex(0);
                CCNumber * shownow = (CCNumber*)phaseData->objectForKey("shownow");
                if (shownow && shownow->getIntValue()==1) {
                    tutorialNextPhase();
                }
            }
        }
    }
}

#pragma mark - level data
void FMDataManager::reloadLevelData()
{
    for (std::map<BubbleSubLevelInfo *, CCDictionary *>::iterator it = m_cachedSubLevelData.begin(); it != m_cachedSubLevelData.end(); it++) {
        CCDictionary * dict = it->second;
        dict->release();
    }
    m_cachedSubLevelData.clear();
    
    for (std::map<int, BubbleLevelInfo *>::iterator it = m_cachedLevelData.begin(); it != m_cachedLevelData.end(); it++) {
        BubbleLevelInfo * l = it->second;
        delete l;
    }
    m_cachedLevelData.clear();
    
    int count = BubbleServiceFunction_getLevelCount();
    for (int i=0; i<count; i++) {
        BubbleLevelInfo * l = BubbleServiceFunction_getLevelInfo(i);
        m_cachedLevelData[i] = l;
        
        for (int j=0; j<l->subLevelCount; j++) {
            BubbleSubLevelInfo * sl = l->getSubLevel(j);
            CCDictionary * dict = CCJSONConverter::sharedConverter()->dictionaryFrom(sl->content.c_str());
            if (dict) {
                dict->retain();
                m_cachedSubLevelData[sl] = dict;
            }
        }
        
        for (int j=0; j<l->unlockLevelCount; j++) {
            BubbleSubLevelInfo * sl = l->getUnlockLevel(j);
            CCDictionary * dict = CCJSONConverter::sharedConverter()->dictionaryFrom(sl->content.c_str());
            if (dict) {
                dict->retain();
                m_cachedSubLevelData[sl] = dict;
            }
        }
    }
}

BubbleLevelInfo * FMDataManager::getLevelInfo(int world)
{
    if (m_cachedLevelData.size() == 0) {
        //not init
        reloadLevelData();
    }
    if (m_cachedLevelData.find(world) != m_cachedLevelData.end()) {
        return m_cachedLevelData[world];
    }
    
    return NULL;
}

int FMDataManager::getGameMode()
{
#ifdef DEBUG
    CCDictionary * levelData = getLevelData(m_localMode);
#else
    CCDictionary * levelData = getLevelData(false);
#endif
    return ((CCNumber *)levelData->objectForKey("gameMode"))->getIntValue();
}

CCArray* FMDataManager::getSellingBooster()
{
#ifdef DEBUG
    CCDictionary * levelData = getLevelData(m_localMode);
#else
    CCDictionary * levelData = getLevelData(false);
#endif
    CCArray * array = (CCArray*)levelData->objectForKey("sellingItems");
    if (!array) {
        array = CCArray::create();
        array->addObject(CCNumber::create(6));
        array->addObject(CCNumber::create(0));
        array->addObject(CCNumber::create(7));
    }
    return array;
}

int FMDataManager::getBossBean(int multiplier)
{
#ifdef DEBUG
    CCArray * beans = (CCArray *)getLevelData(m_localMode)->objectForKey("gameModeData");
#else
    CCArray * beans = (CCArray *)getLevelData(false)->objectForKey("gameModeData");
#endif
    int bean = ((CCNumber *)beans->objectAtIndex(multiplier))->getIntValue();
    return bean;
}

bool FMDataManager::isInGame()
{
    FMMainScene * scene = (FMMainScene *)getUI(kUI_MainScene);
    return scene->getCurrentSceneType() == kGameNode;
}

int FMDataManager::getLevelID()
{
    BubbleLevelInfo * worldInfo = getLevelInfo(m_worldIndex);
    int id = -1;
    if (worldInfo) {
        BubbleSubLevelInfo * info = m_isQuest ? worldInfo->getUnlockLevel(m_levelIndex) : worldInfo->getSubLevel(m_levelIndex);
        id = info->ID;
    }
    //delete worldInfo;
    return id;
}

#pragma mark - helper
static int currentSeed = -1;
static int randomIterateSeed = -1;
static int randomIterator = 0;
void FMDataManager::setRandomSeed(int seed, bool reset)
{
    if (reset) {
        currentSeed = seed;
        randomIterateSeed = seed;
        randomIterator = 0;
        srand(randomIterateSeed);
    }
    else {
        if (seed == randomIterateSeed) {
            //get queue random
            if (currentSeed == randomIterateSeed) {
                //do nothing
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
                currentSeed = randomIterateSeed;
                //do iterating
                srand(randomIterateSeed);
                int it = 0;
                while (it < randomIterator) {
                    rand();
                    it++;
                }
#endif
            }
            else {
                currentSeed = randomIterateSeed;
                //do iterating
                srand(randomIterateSeed);
                int it = 0;
                while (it < randomIterator) {
                    rand();
                    it++;
                }
            }
        }
        else {
            currentSeed = seed;
            srand(seed);
        }
    }
//        if (currentSeed != randomIterateSeed) {
//            srand(currentSeed);
//        }
//        else {
//            
//        }
//        
//        
//        
//        if (currentSeed == randomIterateSeed) {
//            //if last current seed is equal to random seed
//            
//            
//        }
//        else {
//            //switch to seed
//        }
//        
//        if (randomIterateSeed == seed) {
//        }
//        else {
//            
//        }
//    }
//    if (randomIterateSeed != currentSeed) {
//        
//    }
//    
//    if (currentSeed == seed && !reset) {
//        //do nothing
//    }
//    else {
//        if (seed == 0) {
//            //time seed
//            struct cc_timeval now;
//            CCTime::gettimeofdayCocos2d(&now, NULL);
//            if (currentSeed == now.tv_usec) {
//                currentSeed = now.tv_usec+1;
//            }
//            currentSeed = now.tv_usec;
//            srand(currentSeed);
//        }
//        else {
//            currentSeed = seed;
//            srand(currentSeed);
//        }
//    }
}

int FMDataManager::getCurrentRandomSeed()
{
    return currentSeed;
}

int FMDataManager::getRandomIteratorSeed()
{
    return randomIterateSeed;
}

int FMDataManager::getRandom()
{
    //time based random seed
    struct cc_timeval now;
    CCTime::gettimeofdayCocos2d(&now, NULL);
    int seed = now.tv_usec;
    if (randomIterateSeed == seed) {
        seed++;
    }
    setRandomSeed(seed);
    return rand();
}

int FMDataManager::getRandom(int seed)
{
    int useSeed = seed;
    if (seed == -1) {
        //use current seed
        CCAssert(randomIterateSeed != -1, "cannot get random by seed -1!"); 
        useSeed = randomIterateSeed;
    }
    
    setRandomSeed(useSeed);
    randomIterator++;
    return rand();
}

const char * FMDataManager::getLocalizedString(const char *string)
{ 
    OBJCHelper * helper = OBJCHelper::helper();
    return helper->getLocalizedString(string);
}

void FMDataManager::reloadLocalizedString()
{
    OBJCHelper * helper = OBJCHelper::helper();
    helper->loadLocalizedStrings();
}

const char * FMDataManager::getHMAC()
{
    OBJCHelper * helper = OBJCHelper::helper();
    return helper->getHMAC();
}

const char * FMDataManager::getVersion()
{
    return OBJCHelper::helper()->getVersion();
}

const char * FMDataManager::getUID()
{
    return OBJCHelper::helper()->getUID();
}

const char * FMDataManager::getUserName()
{
    CCDictionary * usersave = getUserSave();
    CCString * name = (CCString*)usersave->objectForKey("username");
    if (name) {
        return name->getCString();
    }
    return NULL;
}

void FMDataManager::setUserName(const char * name)
{
    CCDictionary * usersave = getUserSave();
    CCString * str = CCString::create(name);
    usersave->setObject(str, "username");
    saveGame();
}
int FMDataManager::getUserIcon()
{
    CCDictionary * usersave = getUserSave();
    CCNumber * icon = (CCNumber*)usersave->objectForKey("usericon");
    if (!icon || icon->getIntValue() < 1 || icon->getIntValue() > 6) {
        icon = CCNumber::create((getRandom()%6) + 1);
        usersave->setObject(icon, "usericon");
    }
    return icon->getIntValue();
}
void FMDataManager::setUserIcon(int iconId)
{
    if (iconId < 1 || iconId > 6) {
        return;
    }
    CCDictionary * usersave = getUserSave();
    CCNumber * icon = CCNumber::create(iconId);
    usersave->setObject(icon, "usericon");
}

int FMDataManager::getCurrentTime()
{
    return OBJCHelper::helper()->getCurrentTime();
}

int FMDataManager::getRemainTime(int time)
{
    int currentTime = getCurrentTime();
    int off = time - currentTime;
    if (off < 0) {
        off = 0;
    }
    return off;
}

CCString * FMDataManager::getTimeString(int time, bool cut)
{
    CCString * timeStr = NULL;
    
    if (time > 86400) {
        int day = time / 86400;
        int hour = (time % 86400) / 3600;
        timeStr = CCString::createWithFormat(getLocalizedString("V140_(D)DAY_(D)HOUR"),day,hour);
        //CCLOG("%s",timeStr->getCString());
    }else{
        int hour = time / 3600;
        int minute = (time % 3600) / 60;
        int second = (int)time % 60;
        if (cut) {
            if (hour == 0) {
                if (minute == 0) {
                    timeStr = CCString::createWithFormat("%02d:%02d", minute, second);
                }
                else {
                    timeStr = CCString::createWithFormat("%02d:%02d", minute ,second);
                }
            }
            else {
                timeStr = CCString::createWithFormat("%02d:%02d:%02d", hour, minute, second);
            }
        }
        else {
            timeStr = CCString::createWithFormat("%02d:%02d:%02d", hour, minute, second);
        }
        
    }
    
    return timeStr;
}

std::string FMDataManager::getDollarString(int dollar)
{
    int d = dollar;
    std::stringstream ss;
    std::list<int> digits;
    while (d != 0) {
        int s = d % 10;
        digits.push_front(s);
        d = d / 10;
    }
    if (digits.size() == 0) {
        digits.push_back(0);
    }
    
    while (digits.size() > 0) {
        int d = digits.front();
        ss << d;
        digits.pop_front();
        if (digits.size() % 3 == 0 && digits.size() != 0) {
            ss << ",";
        }
    }

    return std::string(ss.str());
}

void FMDataManager::updateStatusBar()
{
    FMStatusbar * bar = (FMStatusbar *)getUI(kUI_Statusbar);
    bar->updateUI();
}


bool FMDataManager::isCharacterType()
{
    const char * langCode = OBJCHelper::helper()->getLanguageCode();
    if (strcmp(langCode, "zh-Hans") == 0 ||
        strcmp(langCode, "zh-Hant") == 0 ||
        strcmp(langCode, "ja") == 0 ||
        strcmp(langCode, "ko") == 0
        ) {
        return true;
    }
    return false;
}

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
char* FMDataManager::getFBSaveData()
{
    return m_fbSaveData;
}

void FMDataManager::setFBSaveData(const char* data )
{
    if( data == NULL ){
        if( m_fbSaveData ) free(m_fbSaveData);
        m_fbSaveData = NULL;
        return;
    }
    int len = strlen(data);
    char *fbsave = (char*)malloc(len+1);
    memset(fbsave, 0, len+1);
    memcpy(fbsave,data,len);
    m_fbSaveData = fbsave;
}
#endif

double FMDataManager::getDiscountTimeByKey(const char* key,bool startTime)
{
    const char* valueStr = SNSFunction_getRemoteConfigString(key);
    if (!valueStr) return -1;
    CCDictionary* timeDic = OBJCHelper::helper()->converJsonStrToCCDic(valueStr);
    if (!timeDic) return -1;
    
    CCString* timeStr = NULL;
    
    //开始时间
    if (startTime)
        timeStr =(CCString* )timeDic->objectForKey("start");
    else
        timeStr = (CCString* )timeDic->objectForKey("end");

    double time = OBJCHelper::helper()->convertStringDateTo1970Sec(timeStr->getCString());
    return time;
}

bool FMDataManager::whetherUnsealDiscountFromServerByKey(const char* key)
{
    const char* valueStr = SNSFunction_getRemoteConfigString(key);
    if (!valueStr) return false;
    CCDictionary* timeDic = OBJCHelper::helper()->converJsonStrToCCDic(valueStr);
    if (!timeDic) return false;
    
    double curTime = SNSFunction_getCurrentTime();
    CCString* startTimeStr =(CCString* )timeDic->objectForKey("start");
    double startTime = OBJCHelper::helper()->convertStringDateTo1970Sec(startTimeStr->getCString());
    if (startTime > curTime) return false;
    
    CCString* endTimeStr = (CCString* )timeDic->objectForKey("end");
    double endTime = OBJCHelper::helper()->convertStringDateTo1970Sec(endTimeStr->getCString());
    return endTime >= curTime;
}


bool FMDataManager::whetherUnsealLevelStartDiscount()
{
#ifndef BRANCH_CN
    return false;
#endif
    
    return whetherUnsealDiscountFromServerByKey(kLevelStartDiscount);
}

bool FMDataManager::whetherUnsealUnlimitLifeDiscount()
{
#ifndef BRANCH_CN
    return false;
#endif
    
    bool purchased = hasPurchasedUnlimitLife();
    if (purchased) return false;
    int maxLife = getMaxLife();
    
    //已升级了8体力的玩家永远显示
    if (maxLife == 8) return true;
    
    //新手玩家显示3天
    CCNumber* newPlayerFlag = (CCNumber* )getUserSave()->objectForKey(kNewPlayerUnlimitLifeDiscountTime);
    if (!newPlayerFlag) newPlayerFlag = CCNumber::create(-1);
    int flagValue = newPlayerFlag->getDoubleValue();
    
    //new Player
    if (flagValue != -1) {
        int remain = getRemainTime(flagValue);
        if (remain == 0) {
            getUserSave()->setObject(CCNumber::create(-1), kNewPlayerUnlimitLifeDiscountTime);
            saveGame();
            return false;
        }
        return true;
    }
    
    //普通玩家的折扣时间从服务器获得
    return whetherUnsealDiscountFromServerByKey(kUnlimitLifeDiscount);
}


CCString* FMDataManager::getUnlimitLifeDiscountRestTimeStr()
{
#ifndef BRANCH_CN
    return CCString::create("");
#endif

    //新手玩家显示3天
    CCNumber* newPlayerFlag = (CCNumber* )getUserSave()->objectForKey(kNewPlayerUnlimitLifeDiscountTime);
    if (!newPlayerFlag) newPlayerFlag = CCNumber::create(-1);
    int flagValue = newPlayerFlag->getDoubleValue();
    
    //new Player
    if (flagValue != -1) {
        int remain = getRemainTime(flagValue);
        if (remain == 0) {
            getUserSave()->setObject(CCNumber::create(-1), kNewPlayerUnlimitLifeDiscountTime);
            saveGame();
        }else{
            CCString* timeStr = getTimeString(remain);
            return timeStr;
        }
    }
    
    double endTime = getDiscountTimeByKey(kUnlimitLifeDiscount,false);
    int remain = getRemainTime(endTime);
    CCString* timeStr = NULL;
    remain==0 ? timeStr=CCString::create("") : timeStr=getTimeString(remain);
    return timeStr;
}

bool FMDataManager::hasPurchasedUnlimitLife()
{
    CCNumber* purNum = (CCNumber* )m_userSave->objectForKey(kPurchaseUnlimitLife);
    if (!purNum) {
        purNum = CCNumber::create(0);
        m_userSave->setObject(purNum, kPurchaseUnlimitLife);
        saveGame();
    }
    
   return purNum->getIntValue();
}

bool FMDataManager::whetherUnsealIapBouns()
{
#ifndef BRANCH_CN
    return false;
#endif
    
    bool isServiceUnseal = whetherUnsealDiscountFromServerByKey(kGoldIapBouns);
    if (!isServiceUnseal) resetIapBounsSaveData();
    
    //是否已领取完了所有奖励
    CCDictionary* dicData = (CCDictionary* )getUserSave()->objectForKey(kGoldIapBonusDic);
    if (!dicData){
        resetIapBounsSaveData();
        dicData = (CCDictionary* )getUserSave()->objectForKey(kGoldIapBonusDic);
    }
    bool hasGetAllRwd = true;
    CCDictElement* dicEle = NULL;
    CCDICT_FOREACH(dicData, dicEle){
        CCNumber* valueNum = (CCNumber*)dicEle->getObject();
        if (valueNum->getIntValue() == 0) {
            hasGetAllRwd = false;
            break;
        }
    }
    
    return isServiceUnseal && !hasGetAllRwd;
}

void FMDataManager::resetIapBounsSaveData()
{
    CCDictionary* dicData = CCDictionary::create();
    dicData->setObject(CCNumber::create(0), "gold");
    
    for (int i = 1; i < 5; ++i) {
        dicData->setObject(CCNumber::create(0), CCString::createWithFormat("%d",i)->getCString());
    }
    getUserSave()->setObject(dicData, kGoldIapBonusDic);
}



int FMDataManager::getAllStarsFromSave()
{
    int allStars = 0;
    int furWorldIdx = getFurthestWorld();
    for (int i = 0; i < furWorldIdx+1; ++i) {
        BubbleLevelInfo * info = getLevelInfo(i);
        
        //subLv
        for (int j = 0; j < 15; ++j) {
            bool isInWorld = j < info->subLevelCount;
            if (isInWorld) {
                CCDictionary* data = getLevelUserDataByIdx(i, j);
                int star = ((CCNumber* )data->objectForKey("stars"))->getIntValue();
                allStars += MIN(star, 3);
            }

        }
        
        //quest
        for (int k = 0; k < 16; ++k) {
            bool isInWorld = k < info->unlockLevelCount;
            if (isInWorld) {
                CCDictionary* data = getLevelUserDataByIdx(i, k,true);
                int star = ((CCNumber* )data->objectForKey("stars"))->getIntValue();
                allStars += MIN(star, 3);
            }
        }
    }
    
    //CCLOG("%d",allStars);
    return allStars;

}

void FMDataManager::showStarReward()
{
    FMUIStarReward* window = (FMUIStarReward* )getUI(kUI_StarReward);
    GAMEUI_Scene::uiSystem()->nextWindow(window);
}

int FMDataManager::getNextStarRewardIndex()
{
    CCNumber* idx = (CCNumber* )m_userSave->objectForKey(kNextStarRwdIdx);
    if (!idx) {
        idx = CCNumber::create(0);
        m_userSave->setObject(idx, kNextStarRwdIdx);
        saveGame();
    }
    
    return idx->getIntValue();
}

bool FMDataManager::updateNextStarRewardIndex()
{
    int idx = getNextStarRewardIndex();
    m_userSave->setObject(CCNumber::create(idx+1), kNextStarRwdIdx);
    saveGame();
    int maxIdx = sizeof(s_starReward) / (sizeof(int)*3) -1;
    return maxIdx >= (idx+1);
}

bool FMDataManager::whetherUnsealStarBonus()
{
#ifndef BRANCH_CN
    return false;
#endif
    int maxIdx = sizeof(s_starReward) / (sizeof(int)*3) -1;
    int nextIdx = getNextStarRewardIndex();
    return nextIdx <= maxIdx;
}



bool FMDataManager::whetherCanGetStarReward()
{
#ifndef BRANCH_CN
    return false;
#endif
    int curStar = getAllStarsFromSave();
    int nextRwdIdx = getNextStarRewardIndex();
    int maxIdx = sizeof(s_starReward) / (sizeof(int)*3) -1;
    int needStar = s_starReward[nextRwdIdx][0];
    
    if (nextRwdIdx <= maxIdx && needStar <= curStar) {
        return true;
    }
    
    return false;
}


CCObject* FMDataManager::getObjectForUserSave(const char * key)
{
    return getUserSave()->objectForKey(key);
}
void FMDataManager::setObjectForUserSave(CCObject * obj, const char * key)
{
    getUserSave()->setObject(obj, key);
}

int FMDataManager::getTotalStarsNumber()
{
    if (m_totalStarNumber == 0) {
        int count = BubbleServiceFunction_getLevelCount();
        for (int i=0; i<count; i++) {
            BubbleLevelInfo * l = BubbleServiceFunction_getLevelInfo(i);
            m_totalStarNumber += (l->subLevelCount+l->unlockLevelCount)*3;
        }
    }
    return m_totalStarNumber;
}



int FMDataManager::getDailyLevelRewardDate()
{
    CCDictionary * save = getUserSave();
    CCNumber * n = (CCNumber *)save->objectForKey("levelrewarddate");
    if (!n) {
        n = CCNumber::create(0);
        save->setObject(n, "levelrewarddate");
    }
    return n->getIntValue();
}
int FMDataManager::getDailyLevelRewardTime()
{
#ifdef SNS_DISABLE_DAILYCHECKIN
    return 0;
#endif

    CCDictionary * save = getUserSave();
    CCNumber * n = (CCNumber *)save->objectForKey("levelrewarddate");
    if (!n) {
        n = CCNumber::create(0);
    }
    
    if (SNSFunction_getTodayDate() != n->getIntValue() || save->objectForKey("levelrewardinfo") == NULL) {
        n->setValue(SNSFunction_getTodayDate());
        save->setObject(n, "levelrewarddate");
        
        int world = getFurthestWorld();
        int level = getFurthestLevel();
        
        BubbleLevelInfo * info = getLevelInfo(world);
        if (!info) {
            return 0;
        }
        
        level += 5;
        if (level >= info->subLevelCount) {
            level -= info->subLevelCount;
            world += 1;
        }

        if (world >= BubbleServiceFunction_getLevelCount()) {
            return 0;
        }
        
        CCDictionary * dic = CCDictionary::create();
        dic->setObject(CCNumber::create(world), "world");
        dic->setObject(CCNumber::create(level), "level");
        dic->setObject(CCNumber::create(SNSFunction_getCurrentTime()+3600), "time");
        
        save->setObject(dic, "levelrewardinfo");
    }
    
    CCDictionary * dic = (CCDictionary *)save->objectForKey("levelrewardinfo");
    CCNumber * time = (CCNumber *)dic->objectForKey("time");
    return time->getIntValue();
}
void FMDataManager::setDailyLevelRewardTime(int time)
{
    CCDictionary * save = getUserSave();
    CCDictionary * dic = (CCDictionary *)save->objectForKey("levelrewardinfo");
    if (!dic) {
        dic = CCDictionary::create();
    }
    dic->setObject(CCNumber::create(time), "time");
    save->setObject(dic, "levelrewardinfo");
}
std::vector<int> FMDataManager::getDailyRewardLevel()
{
    CCDictionary * save = getUserSave();
    int time = getDailyLevelRewardTime();
    std::vector<int> retVal;
    if (time > SNSFunction_getCurrentTime()) {
        CCDictionary * dic = (CCDictionary *)save->objectForKey("levelrewardinfo");
        CCNumber * w = (CCNumber *)dic->objectForKey("world");
        CCNumber * l = (CCNumber *)dic->objectForKey("level");
        retVal.push_back(w->getIntValue());
        retVal.push_back(l->getIntValue());
    }else{
        retVal.push_back(-1);
        retVal.push_back(-1);
    }
    return retVal;
}

int FMDataManager::getTodaysLoginIndex()
{
    CCDictionary * save = getUserSave();
    CCNumber * firstLoginStamp = (CCNumber *)save->objectForKey("firstloginstamp");
    if (!firstLoginStamp) {
        int h = SNSFunction_getCurrentHour();
        int m = SNSFunction_getCurrentMinute();
        int s = SNSFunction_getCurrentSecond();
        int time = SNSFunction_getCurrentTime();
        
        int stamp = time - h * 3600 - m * 60 - s;
        
        firstLoginStamp = CCNumber::create(stamp);
        save->setObject(firstLoginStamp, "firstloginstamp");
        return 0;
    }
    int h = SNSFunction_getCurrentHour();
    int m = SNSFunction_getCurrentMinute();
    int s = SNSFunction_getCurrentSecond();
    int time = SNSFunction_getCurrentTime();
    
    int stamp = time - h * 3600 - m * 60 - s;
    
    int index = (stamp - firstLoginStamp->getIntValue())/(3600*24);
    if (index > 24 || index < 0) {
        setLoginRewardStatus(false);
        index = 0;
    }
    return index;
}
CCArray * FMDataManager::getLoginRewardStatus()
{
    CCDictionary * save = getUserSave();
    CCArray * ls = (CCArray *)save->objectForKey("loginrewardstatus");
    if (!ls) {
        ls = CCArray::create();
    }
    return ls;
}
bool FMDataManager::getLoginReward()
{
    CCArray * list = getLoginRewardStatus();
    int index = getTodaysLoginIndex();
    if (index>list->count()) {
        FMUISignMakeUp * dialog = (FMUISignMakeUp *)getUI(kUI_SignMakeUp);
        GAMEUI_Scene::uiSystem()->addDialog(dialog);
        return false;
    }
    return true;
}
void FMDataManager::getLoginRewardSuccess()
{
    CCDictionary * save = getUserSave();
    CCArray * list = getLoginRewardStatus();
    list->addObject(CCNumber::create(1));
    save->setObject(list, "loginrewardstatus");
    int index = getTodaysLoginIndex();

    std::vector<int> vector = getRewardInfoForIndex(index);
    FMUISignReward * dialog = (FMUISignReward *)getUI(kUI_DailySignBouns);
    GAMEUI_Scene::uiSystem()->addDialog(dialog);
    dialog->setReward(vector);
    
    int t = vector[0];
    int n = vector[1];
    if (t == kBooster_Gold) {
        int current = getGoldNum();
        setGoldNum(MAX(current + n, 0));
    }else if(t == kBooster_FreeSpin){
        int current = getSpinTimes();
        setSpinTimes(MAX(current + n, 0));
    }else if (t == kBooster_UnlimitLife){
        setUnlimitLifeTime(MAX(getUnlimitLifeTime(), getCurrentTime()) + n * 60);
    }else if (t == kBooster_Life){
        int current = getLifeNum();
        setLifeNum(MAX(current + n, 0));
    }else{
        int current = getBoosterAmount(t);
        setBoosterAmount(t, MAX(current + n, 1));
    }
    
    saveGame();
}

void FMDataManager::setLoginRewardStatus(bool continuous, bool update)
{
    CCDictionary * save = getUserSave();
    if (continuous) {
        int index = getTodaysLoginIndex();
        if (useMoney(getSignSkipGold(index), "skip_sign")) {
            CCArray * list = getLoginRewardStatus();
            while (index > list->count()) {
                list->addObject(CCNumber::create(0));
            }
            save->setObject(list, "loginrewardstatus");
        }
    }else{
        int h = SNSFunction_getCurrentHour();
        int m = SNSFunction_getCurrentMinute();
        int s = SNSFunction_getCurrentSecond();
        int time = SNSFunction_getCurrentTime();
        
        int stamp = time - h * 3600 - m * 60 - s;
        CCNumber * firstLoginStamp = CCNumber::create(stamp);
        save->setObject(firstLoginStamp, "firstloginstamp");

        save->removeObjectForKey("loginrewardstatus");
    }
    
    if (update) {
        FMUIDailySign * sign = (FMUIDailySign *)getUI(kUI_DailySign);
        if (sign) {
            sign->updateUI();
            sign->delayCheckIn();
        }
    }
}

std::vector<int> FMDataManager::getRewardInfoForIndex(int index)
{
    std::vector<int> rev;
    switch (index) {
        case 0:
        case 5:
        case 10:
        case 15:
        case 20:
        {
            rev.push_back(kBooster_FreeSpin);
            rev.push_back(1);
        }
            break;
        case 2:
        case 7:
        case 12:
        case 17:
        case 22:
        {
            rev.push_back(kBooster_UnlimitLife);
            rev.push_back(30);
        }
            break;
        case 1:
        {
            rev.push_back(kBooster_Harvest1Grid);
            rev.push_back(1);
        }
            break;
        case 3:
        {
            rev.push_back(kBooster_4Match);
            rev.push_back(1);
        }
            break;
        case 4:
        {
            rev.push_back(kBooster_Gold);
            rev.push_back(1);
        }
            break;
        case 6:
        {
            rev.push_back(kBooster_5Line);
            rev.push_back(1);
        }
            break;
        case 8:
        {
            rev.push_back(kBooster_MovePlusFive);
            rev.push_back(1);
        }
            break;
        case 9:
        {
            rev.push_back(kBooster_Gold);
            rev.push_back(3);
        }
            break;
        case 11:
        {
            rev.push_back(kBooster_TCross);
            rev.push_back(1);
        }
            break;
        case 13:
        {
            rev.push_back(kBooster_Harvest1Row);
            rev.push_back(1);
        }
            break;
        case 14:
        {
            rev.push_back(kBooster_Gold);
            rev.push_back(5);
        }
            break;
        case 16:
        {
            rev.push_back(kBooster_Harvest1Type);
            rev.push_back(1);
        }
            break;
        case 18:
        {
            rev.push_back(kBooster_PlusOne);
            rev.push_back(1);
        }
            break;
        case 19:
        {
            rev.push_back(kBooster_Gold);
            rev.push_back(7);
        }
            break;
        case 21:
        {
            rev.push_back(kBooster_Shuffle);
            rev.push_back(1);
        }
            break;
        case 23:
        {
            rev.push_back(kBooster_CureRot);
            rev.push_back(1);
        }
            break;
        case 24:
        {
            rev.push_back(kBooster_Gold);
            rev.push_back(10);
        }
            break;
        default:
        {
            rev.push_back(-1);
            rev.push_back(-1);
        }
            break;
    }
    return rev;
}

int FMDataManager::getSignSkipGold(int index)
{
    switch (index) {
        case 2:
        case 3:
        case 4:
        case 5:
            return 1;
        case 6:
        case 7:
        case 8:
        case 9:
        case 10:
            return 3;
        case 11:
        case 12:
        case 13:
        case 14:
        case 15:
            return 5;
        case 16:
        case 17:
        case 18:
        case 19:
        case 20:
            return 7;
        case 21:
        case 22:
        case 23:
        case 24:
        case 25:
            return 8;
        default:
            break;
    }
    return 0;
}

bool FMDataManager::showDailySign()
{
#ifdef SNS_DISABLE_DAILYCHECKIN
    return false;
#endif
    if (getGlobalIndex(getFurthestWorld(), getFurthestLevel()) < 7) {
        return false;
    }

    int index = getTodaysLoginIndex();
    CCArray * list = getLoginRewardStatus();
    if (index >= list->count()) {
        FMUIDailySign * window = (FMUIDailySign *)getUI(kUI_DailySign);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
        return true;
    }
    return false;
}

CCArray * FMDataManager::getSpinPrizes()
{
    CCDictionary * save = getUserSave();
    CCNumber * date = (CCNumber *)save->objectForKey("dailyspindate");
    if (date && date->getIntValue() == SNSFunction_getTodayDate()) {
        CCArray * list = (CCArray *)save->objectForKey("dailyspinprize");
        if (list && list->count() == 4) {
            return list;
        }
    }
    
    save->setObject(CCNumber::create(SNSFunction_getTodayDate()), "dailyspindate");
    
    CCArray * rlist = CCArray::create();
    rlist->addObject(getPrizeFromTier(1, 4));
    rlist->addObject(getPrizeFromTier(2, 3));
    rlist->addObject(getPrizeFromTier(3, 2));
    rlist->addObject(getPrizeFromTier(4, 1));
    
    save->setObject(rlist, "dailyspinprize");
    
    return rlist;
}

CCArray * FMDataManager::getAllSpinPrizes()
{
    CCArray * rlist = CCArray::create();
    rlist->addObjectsFromArray(getPrizeFromTier(1, 100));
    rlist->addObjectsFromArray(getPrizeFromTier(2, 100));
    rlist->addObjectsFromArray(getPrizeFromTier(3, 100));
    rlist->addObjectsFromArray(getPrizeFromTier(4, 100));
    return rlist;
}
CCArray * FMDataManager::getPrizeFromTier(int tier, int number)
{
    CCArray * plist = CCArray::create();
    switch (tier) {
        case 1:
        {
            plist->addObject(creatPrize(kBooster_Life, 1));
            plist->addObject(creatPrize(kBooster_Life, 2));
            plist->addObject(creatPrize(kBooster_Gold, 1));
            plist->addObject(creatPrize(kBooster_Gold, 2));
            plist->addObject(creatPrize(kBooster_Harvest1Type, 1));
            plist->addObject(creatPrize(kBooster_Shuffle, 1));
            plist->addObject(creatPrize(kBooster_CureRot, 1));
        }
            break;
        case 2:
        {
            plist->addObject(creatPrize(kBooster_4Match, 1));
            plist->addObject(creatPrize(kBooster_TCross, 1));
            plist->addObject(creatPrize(kBooster_5Line, 1));
            plist->addObject(creatPrize(kBooster_MovePlusFive, 1));
            plist->addObject(creatPrize(kBooster_Harvest1Type, 2));
            plist->addObject(creatPrize(kBooster_Shuffle, 2));
            plist->addObject(creatPrize(kBooster_CureRot, 2));
            plist->addObject(creatPrize(kBooster_4Match, 2));
            plist->addObject(creatPrize(kBooster_TCross, 2));
            plist->addObject(creatPrize(kBooster_5Line, 2));
            plist->addObject(creatPrize(kBooster_Gold, 10));
        }
            break;
        case 3:
        {
            plist->addObject(creatPrize(kBooster_Harvest1Type, 5));
            plist->addObject(creatPrize(kBooster_Shuffle, 5));
            plist->addObject(creatPrize(kBooster_CureRot, 5));
            plist->addObject(creatPrize(kBooster_4Match, 5));
            plist->addObject(creatPrize(kBooster_TCross, 5));
            plist->addObject(creatPrize(kBooster_5Line, 5));
            plist->addObject(creatPrize(kBooster_UnlimitLife, 1));
            plist->addObject(creatPrize(kBooster_Gold, 20));
            plist->addObject(creatPrize(kBooster_FreeSpin, 3));
        }
            break;
        case 4:
        {
            plist->addObject(creatPrize(kBooster_MovePlusFive, 5));
            plist->addObject(creatPrize(kBooster_UnlimitLife, 6));
            plist->addObject(creatPrize(kBooster_UnlimitLife, 24));
            plist->addObject(creatPrize(kBooster_FreeSpin, 5));
        }
            break;
        default:
            break;
    }
    
    if (number >= plist->count()) {
        return plist;
    }
    
    CCArray * relist = CCArray::create();
    
    while (number > 0) {
        number--;
        if (plist->count() <= 0) break;
        int rand = getRandom()%plist->count();
        relist->addObject(plist->objectAtIndex(rand));
        plist->removeObjectAtIndex(rand);
    }
    
    return relist;
}

CCArray * FMDataManager::creatPrize(int booster, int number)
{
    CCArray * a = CCArray::create();
    a->addObject(CCNumber::create(booster));
    a->addObject(CCNumber::create(number));
    return a;
}



