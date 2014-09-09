//
//  FMUIResult.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-28.
//
//

#include "FMUIResult.h"

#include "FMDataManager.h"
#include "FMMainScene.h"
#include "FMStatusbar.h"
#include "FMUILevelStart.h"
#include "FMGameNode.h"
#include "FMGameElement.h"
#include "FMWorldMapNode.h"
#include "GAMEUI_Scene.h" 
#include "BubbleServiceFunction.h"
#include "FMUIQuit.h"
#include "FMUIBranchLevel.h"
#include "SNSFunction.h"

extern BranchRewardData rewardData[2];

FMUIResult::FMUIResult() :
    m_parentNode(NULL),
    m_starParent(NULL),
    m_scoreLabel(NULL),
    m_levelLabel(NULL),
    m_highscoreLabel(NULL),
    m_highscoreMark(NULL),
    m_instantMove(false),
    m_rankList(NULL),
    m_connectTipLabel(NULL),
    m_tipPicture(NULL)
{
#ifdef BRANCH_CN
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIResult.ccbi", this);
#else
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIResultEN.ccbi", this);
#endif
    addChild(m_ccbNode);
    
    for (int i=0; i<3; i++) {
        CCString * name = CCString::createWithFormat("%d", i+1);
        m_star[i] = (NEAnimNode *)m_starParent->getNodeByName(name->getCString());
    }
    
    m_rankList = CCArray::create();
    m_rankList->retain();
    
    CCNode * ranknode = FMDataManager::sharedManager()->createNode("UI/FMUIRankList.ccbi", this);
    m_ccbNode->addChild(ranknode, 100, 100);
#ifdef BRANCH_CN
    ((CCBAnimationManager *)ranknode->getUserObject())->runAnimationsForSequenceNamed("Normal");
    CCLayer * frdsParent = (CCLayer *)ranknode->getChildByTag(1);
    CCSize sliderSize = frdsParent->getContentSize();
    GUIScrollSlider * tgSlider = new GUIScrollSlider(sliderSize, CCRect(-sliderSize.width * 0.5f, -sliderSize.height * 0.5f, sliderSize.width, sliderSize.height), 75.f, this, false, 2);
    tgSlider->autorelease();
    tgSlider->setPosition(ccp(sliderSize.width * 0.5f, sliderSize.height * 0.5f));
    tgSlider->setRevertDirection(true);
    frdsParent->addChild(tgSlider, 0, 2);
#else
    ((CCBAnimationManager *)ranknode->getUserObject())->runAnimationsForSequenceNamed("EN");
    CCLayer * frdsParent = (CCLayer *)ranknode->getChildByTag(2);
    CCSize sliderSize = frdsParent->getContentSize();
    sliderSize.height -= sliderSize.height * 0.2f;
    GUIScrollSlider * tgSlider = new GUIScrollSlider(sliderSize, CCRect(-sliderSize.width * 0.5f, -sliderSize.height * 0.5f, sliderSize.width, sliderSize.height), 75.f, this, false, 2);
    tgSlider->autorelease();
    tgSlider->setPosition(ccp(sliderSize.width * 0.5f, sliderSize.height * 0.5f ));
    tgSlider->setRevertDirection(true);
    frdsParent->addChild(tgSlider, 0, 2);
    
    m_connectTipLabel->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    m_connectTipLabel->setAlignment(kCCTextAlignmentCenter);
    m_connectTipLabel->setWidth(220);
#endif

}

FMUIResult::~FMUIResult()
{
    m_rankList->release();
}

#pragma mark - CCB Bindings
bool FMUIResult::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{

    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_starParent", NEAnimNode *, m_starParent);
    
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_levelLabel", CCLabelBMFont *, m_levelLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_scoreLabel", CCLabelBMFont *, m_scoreLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_highscoreLabel", CCLabelBMFont *, m_highscoreLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_connectTipLabel", CCLabelBMFont *, m_connectTipLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_highscoreMark", NEAnimNode *, m_highscoreMark);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_tipPicture", CCSprite *, m_tipPicture);
    return true;
}

SEL_CCControlHandler FMUIResult::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIResult::clickButton);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickMenuButton", FMUIResult::clickMenuButton);
    return NULL;
}

void FMUIResult::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        //close
        FMDataManager * manager = FMDataManager::sharedManager();
        FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
        scene->switchScene(kWorldMapNode);
        m_instantMove = true;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIResult::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    FMDataManager * manager = FMDataManager::sharedManager();
    switch (button->getTag()) {
        case 0:
        {
            //close
            FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
            scene->switchScene(kWorldMapNode);
            m_instantMove = true;
            GAMEUI_Scene::uiSystem()->prevWindow();
        }
            break;
        case 1:
        {
            //retry
            m_instantMove = false;
            GAMEUI_Scene::uiSystem()->prevWindow();
            FMUILevelStart * window = (FMUILevelStart *)manager->getUI(kUI_LevelStart);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
            break;
        case 2:
        {
            //next
            addNextPhase();
            FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
            m_instantMove = true;
            GAMEUI_Scene::uiSystem()->prevWindow();
            scene->switchScene(kWorldMapNode);
        }
            break;
        case 3:
        {
            //share
            CCString * levelstr ;
            if (manager->isQuest()) {
                levelstr = CCString::createWithFormat("%d-%d",manager->getWorldIndex()+1,manager->getLevelIndex()+1);
            }else{
                levelstr = CCString::createWithFormat("%d",manager->getGlobalIndex());
            }
            OBJCHelper::helper()->publicFBPassLevel(levelstr->getCString(), CCString::createWithFormat("%d",m_earnScore)->getCString());
        }
            break;
        case 4:
        {
            //connectFB
            OBJCHelper::helper()->connectToFacebook(this);
        }
            break;
        default:
            break;
    } 
}

void FMUIResult::clickMenuButton(CCObject * object)
{
    CCControlButton * btn = (CCControlButton *)object;
    CCNode * node = btn->getParent()->getParent();
    int index = node->getTag();
    if (index < m_rankList->count()) {
        CCDictionary * dic = (CCDictionary *)m_rankList->objectAtIndex(index);
        CCString * uid = (CCString *)dic->objectForKey("uid");
        if (uid == NULL) {
            return;
        }
        if (SNSFunction_getFacebookUid() != NULL && strcmp(uid->getCString(), SNSFunction_getFacebookUid()) == 0) {
            return;
        }
        OBJCHelper::helper()->sendLifeToFriend(uid->getCString(), this, callfuncO_selector(FMUIResult::onSendLifeSuccess));
    }
}

void FMUIResult::onEnter()
{
    GAMEUI_Window::onEnter();
    scheduleUpdate();
    updateFb();
//    m_enterMovesSummary = false;
    extern int gPlayOnTimes;
    gPlayOnTimes = 0;
    
    for (int i=0; i<3; i++) {
        CCString * name = CCString::createWithFormat("%d_Off", i+1);
        m_star[i]->playAnimation(name->getCString());
    }
    
    FMDataManager * manager = FMDataManager::sharedManager();
    int globalIndex = manager->getGlobalIndex();
    int worldIndex = manager->getWorldIndex();
    int levelIndex = manager->getLevelIndex();
    bool isQuest = manager->isQuest();
    FMGameNode * game = (FMGameNode *)((FMMainScene *)manager->getUI(kUI_MainScene))->getNode(kGameNode);
    int state = classState();
     
    CCString * levelStr;
    {
        int globalIndex = manager->getGlobalIndex();
        bool isQuest = manager->isQuest();
        if (isQuest) {
            int world = manager->getWorldIndex();
            int level = manager->getLevelIndex();
            const char * key = manager->getLocalizedString("V100_QUEST_(D)_(D)");
            levelStr = CCString::createWithFormat(key, world+1, level+1);
        }
        else {
            const char * key = manager->getLocalizedString("V100_LEVEL_(D)");
            levelStr = CCString::createWithFormat(key, globalIndex);
        }
        CCLabelBMFont * title = m_levelLabel;
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
        title->setAlignment(kCCTextAlignmentCenter);
#endif
        title->setString(levelStr->getCString());
    }
     
    m_showScore = 0;
    m_currentIndex = 0;
    
    m_earnStarNum = game->getCurrentStarNum();
    m_earnScore = game->getCurrentScore();
    m_oldHighscore = manager->getHighscore();
    m_oldStarNum = manager->getStarNum();
    m_highscoreMark->setVisible(false);
    
    
    int levelScore = m_earnScore;
    
    CCNode * rankNode = m_ccbNode->getChildByTag(100);
    if (state == kResult_Win) {
        rankNode->setVisible(true);
        m_earnStarNum = game->getCurrentStarNum(); 
        for (int i=0; i<3; i++) {
            m_scoreGaps[i] = game->getScoreGap(i);
        } 
        
        levelComplete();
        
        manager->resetFailCount();
    }
    else {
        rankNode->setVisible(false);
        ((CCBAnimationManager *)rankNode->getUserObject())->runAnimationsForSequenceNamed("Normal");
        CCString * score;
#ifdef BRANCH_CN
        score = CCString::createWithFormat("%d", m_earnScore);
#else
        score = CCString::createWithFormat("%s",FMDataManager::sharedManager()->getDollarString(m_earnScore).c_str());
#endif
        m_scoreLabel->setString(score->getCString());
        
        manager->addFailCount();
        if (manager->getUnlimitLifeTime() < manager->getCurrentTime()) {
            manager->checkNewTutorial("failed");
            manager->tutorialBegin();
        }
    }
    
    manager->saveGame();
    
    CCString * levelstr ;
    if (manager->isQuest()) {
        levelstr = CCString::createWithFormat("%d-%d",manager->getWorldIndex()+1,manager->getLevelIndex()+1);
    }else{
        levelstr = CCString::createWithFormat("%d",manager->getGlobalIndex());
    }
    OBJCHelper::helper()->trackLevelFinish(levelStr->getCString(), state == kResult_Win);

    //send analyst data
#ifdef DEBUG
    if (game->isCheated()) {
        return;
    }
#endif
    {
        BubbleLevelStatInfo * info = new BubbleLevelStatInfo;
         
        if (isQuest) {
            sprintf(info->levelIndex,"%d-%d", worldIndex+1, levelIndex+1);
        }
        else {
            sprintf(info->levelIndex,"%d", globalIndex);
        }
        int levelid = -1;
        {
            BubbleLevelInfo * lInfo = manager->getLevelInfo(worldIndex);
            BubbleSubLevelInfo * subInfo = isQuest ? lInfo->getUnlockLevel(levelIndex) : lInfo->getSubLevel(levelIndex);
            levelid = subInfo->ID;
            //delete lInfo;
        }
        info->levelID = levelid;
        info->success = state == kResult_Win ? 1 : 0;
        info->score = levelScore;
        info->star = m_earnStarNum;
        info->stepUsed = game->getUsedMoves();
        info->stepTotal = game->getDefaultMoves();
        info->failTimes = manager->getFailCount();
        info->buyFiveStep = game->hasPlus5Booster() ? 1 : 0;
        info->buySpade = -1;
        info->useSpadeCount = game->getBoosterUsed(kBooster_Harvest1Grid);
        info->useTractorCount = game->getBoosterUsed(kBooster_Harvest1Row);
        info->useAddPointCount = game->getBoosterUsed(kBooster_PlusOne);
        info->usePigCount = game->getBoosterUsed(kBooster_Harvest1Type);
        info->useRecoverCount = game->getBoosterUsed(kBooster_CureRot);
        info->buyFiveMoveCount = game->getContinueTimes();
        info->beatRatBonus = -1;    //no use anymore
        info->scoreBeforeMania = game->getScoreBeforeMania();
        std::map<int, elementTarget> targets = game->getTargets();
        for (std::map<int, elementTarget>::iterator it = targets.begin(); it != targets.end(); it++) {
            elementTarget & t = it->second;
            if (t.index < 4 && t.index >= 0) {
                info->targetCount[t.index] = t.target;
                info->collectCount[t.index] = t.harvested;
            }
        }
         
        BubbleServiceFunction_sendLevelStats(info); 
        delete info;
    }

    
    
}

void FMUIResult::addNextPhase()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    
    int worldIndex = manager->getWorldIndex();
    int levelIndex = manager->getLevelIndex();
    bool isQuest = manager->isQuest();
    bool isBranch = manager->isBranch();

    FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
    FMUIBranchLevel * branch = (FMUIBranchLevel *)manager->getUI(kUI_BranchLevel);
    FMWorldMapNode * worldMap = (FMWorldMapNode *)scene->getNode(kWorldMapNode);
    BubbleLevelInfo * info = manager->getLevelInfo(worldIndex);
    
    if (isBranch) {
        if (levelIndex < info->unlockLevelCount-1) {
            AnimPhaseStruct s = {kPhase_NextLevel, worldIndex, levelIndex+1, isQuest};
            branch->pushPhase(s);
        }
    }else{
        int wi = worldIndex;
        int li = levelIndex;
        bool Q = isQuest;
        if (isQuest) {
            wi ++;
            li = 0;
            Q = false;
            BubbleLevelInfo* i = manager->getLevelInfo(wi);
            if (!i) {
                return;
            }
        }else{
            li ++;
            if (li >= info->subLevelCount) {
                if (info->unlockLevelCount > 0) {
                    li = 0;
                    Q = true;
                }else{
                    wi++;
                    li = 0;
                    Q = false;
                    BubbleLevelInfo* i = manager->getLevelInfo(wi);
                    if (!i) {
                        return;
                    }
                }
            }
        }
        AnimPhaseStruct s = {kPhase_NextLevel, wi, li, Q};
        worldMap->pushPhase(s);
    }
}

int FMUIResult::getBonusNumber()
{
    FMDataManager* manager = FMDataManager::sharedManager();
    int li = manager->getLevelIndex();
    int num = 0;
    for (int i = 0; i < _BonusRewardCount_; i++) {
        if (li == rewardData[i].level) {
            num = rewardData[i].number;
            break;
        }
    }
    return num;
}

void FMUIResult::levelComplete()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    
    int worldIndex = manager->getWorldIndex();
    int levelIndex = manager->getLevelIndex();
    bool isQuest = manager->isQuest();
    bool isBranch = manager->isBranch();
    bool isBeaten = manager->isLevelBeaten();
    bool isRewardGetted = manager->isRewardGetted();
    if (!isBeaten) {
        manager->setLevelBeaten();
    }

    
    
    FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
    FMUIBranchLevel * branch = (FMUIBranchLevel *)manager->getUI(kUI_BranchLevel);
    FMWorldMapNode * worldMap = (FMWorldMapNode *)scene->getNode(kWorldMapNode);


    std::vector<int> rewardlevel = manager->getDailyRewardLevel();
    if (!isQuest) {
        if (rewardlevel[0] == worldIndex && rewardlevel[1] == levelIndex) {
            AnimPhaseStruct s = {kPhase_GetBonus, worldIndex, levelIndex, isQuest};
            worldMap->pushPhase(s);
            manager->setDailyLevelRewardTime(0);
        }
    }

    
    if (m_oldStarNum < m_earnStarNum) {
        AnimPhaseStruct s = {kPhase_PopStars, worldIndex, levelIndex, isQuest};
        if (isQuest) {
            branch->pushPhase(s);
        }else{
            worldMap->pushPhase(s);
        }
        manager->setStarNum(m_earnStarNum);
    }
     
    m_scoreLabel->setString("0");
#ifdef BRANCH_CN
    m_highscoreLabel->setString(CCString::createWithFormat("%d",m_oldHighscore)->getCString());
#else
    std::string highstring = FMDataManager::sharedManager()->getDollarString(m_oldHighscore);
    m_highscoreLabel->setString(highstring.c_str());
#endif
    int highscore = m_earnScore;
    if (m_oldHighscore < highscore) {
        manager->setHighscore(highscore);
    }
    refreshHighScore(MAX(highscore, m_oldHighscore));

    
    //add 1 life for winning
    int life = manager->getLifeNum();
    int maxlife = manager->getMaxLife();
    if (manager->getUnlimitLifeTime() < manager->getCurrentTime()) {
        life++;
        manager->setLifeNum(life);
        if (isQuest) {
            manager->addWorldLifeUsed(-1);
        }
    }
    if (worldIndex == 0 && levelIndex == 0 && !isQuest && !isBeaten) {
        manager->setWorldInPhase(true);
        AnimPhaseStruct s = {kPhase_TutorialUnlock, worldIndex, levelIndex, isQuest};
        AnimPhaseStruct s1 = {kPhase_Tutorial, worldIndex, levelIndex, isQuest};
        worldMap->pushPhase(2, s, s1);
    }

    if (isQuest) {
        //check if unlock world?
        if (!manager->isWorldUnlocked() && !isBranch) {
            //not unlocked, check last quest is already beaten?
            if (!isBeaten) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
                SNSFunction_unlockAchievement(worldIndex);
#endif
                manager->unlockWorld();
                manager->setNewJelly(worldIndex, true);
                std::vector<int> nextIndices = manager->getNextLevel(worldIndex, -1);
                if (nextIndices[0] == -1) {
                    manager->setLevel(worldIndex, levelIndex+1, true);
                    manager->unlockLevel();
                    
                    manager->setLevel(worldIndex + 1, 0, false);
                    manager->openWorld();
                    manager->unlockLevel();
                    //                        manager->cleanQuestCD();
                    manager->setFurthestLevel();
                    manager->setWorldInPhase(true);
                    AnimPhaseStruct s2 = {kPhase_QuestComplete, worldIndex, -1, false};
                    AnimPhaseStruct s3 = {kPhase_Tutorial, worldIndex, -1, false};
                    worldMap->pushPhase(2, s2, s3);
                    manager->setLevel(worldIndex, levelIndex, isQuest);
                    
                    AnimPhaseStruct s5 = {kPhase_LevelUnlock, worldIndex, levelIndex+1, true};
                    branch->pushPhase(s5);
                }else{
                    manager->setLevel(worldIndex, levelIndex+1, true);
                    manager->unlockLevel();
                    
                    manager->setLevel(nextIndices[0], nextIndices[1], false);
                    manager->openWorld();
                    manager->unlockLevel();
                    //                        manager->cleanQuestCD();
                    manager->setFurthestLevel();
                    manager->setWorldInPhase(true);
                    AnimPhaseStruct s2 = {kPhase_QuestComplete, worldIndex, -1, false};
                    AnimPhaseStruct s3 = {kPhase_Tutorial, worldIndex, -1, false};
                    AnimPhaseStruct s4 = {kPhase_WorldUnlock, nextIndices[0], -1, false};
                    worldMap->pushPhase(3, s2, s3, s4);
                    manager->setLevel(worldIndex, levelIndex, isQuest);
                    
                    AnimPhaseStruct s5 = {kPhase_LevelUnlock, worldIndex, levelIndex+1, true};
                    branch->pushPhase(s5);
                }
            }
        }else{
            if (!isRewardGetted) {
                manager->setLevel(worldIndex, levelIndex, isQuest, true);
                int bonus = getBonusNumber();
                if (bonus > 0) {
                    int num = manager->getGoldNum();
                    num += bonus;
                    manager->setGoldNum(num);
                    manager->getReward();
                    
                    AnimPhaseStruct s4 = {kPhase_GetBonus, worldIndex, levelIndex, true};
                    branch->pushPhase(s4);
                }
            }
            if (!isBeaten) {
                BubbleLevelInfo * info = manager->getLevelInfo(worldIndex);
                
                //next quest
                manager->setLevel(worldIndex, levelIndex+1, true, true);
                manager->unlockLevel();
                //                    manager->resetQuestCD();
                AnimPhaseStruct s2 = {kPhase_LevelUnlock, worldIndex, levelIndex+1, true};
                branch->pushPhase(s2);
                
                if (levelIndex+1 >= info->unlockLevelCount) {
                    AnimPhaseStruct s3 = {kPhase_QuestComplete, worldIndex, levelIndex, true};
                    branch->pushPhase(s3);
                }
            }
        }
    }
    else {
        //check can unlock?
        std::vector<int> nextIndices = manager->getNextLevel(worldIndex, levelIndex);
        bool isLastNormalLevel = worldIndex != nextIndices[0];
        if (nextIndices[0] == -1) {
            //no next world
//            AnimPhaseStruct s = {kPhase_ComingSoon, -1, -1, false};
//            worldMap->pushPhase(s);
            
//            if (isLastNormalLevel) {
//                manager->setLevel(worldIndex, levelIndex+1, false);
//                manager->unlockLevel();
//                
//                manager->setLevel(worldIndex, 0, true);
//                manager->unlockLevel();
//                
//                manager->setLevel(worldIndex, levelIndex, isQuest);
//            }
            manager->setLevel(worldIndex, 0, true);
            manager->unlockLevel();
            manager->resetWorldQuestBeginTime();
            AnimPhaseStruct s3 = {kPhase_LevelUnlock, worldIndex, 0, true};
            AnimPhaseStruct s2 = {kPhase_MoveAvatar, worldIndex, levelIndex, false};
            
            worldMap->pushPhase(2, s3, s2);

        }
        else {
            if (isLastNormalLevel) {
                //check the world is beaten(last quest is beaten)
                bool worldCleared = manager->isWorldBeaten(true);
                manager->setLevel(nextIndices[0], nextIndices[1], false);
                if (worldCleared) {
                    //no quests or quests cleared
                    if (!manager->isWorldOpened()) {
                        manager->openWorld();
                        manager->unlockLevel();
                        AnimPhaseStruct s1 = {kPhase_WorldUnlock, nextIndices[0], -1, false};
                        worldMap->pushPhase(s1);
                    }
                }
                else {
                    //have quests not cleared, begin quest
                    manager->setLevel(worldIndex, 0, true);
                    manager->unlockLevel();
                    manager->resetWorldQuestBeginTime();
                    AnimPhaseStruct s3 = {kPhase_LevelUnlock, worldIndex, 0, true};
                    AnimPhaseStruct s2 = {kPhase_MoveAvatar, worldIndex, levelIndex, false};

                    worldMap->pushPhase(2, s3, s2);
                }
            }
            else {
                //just normal level
                manager->setLevel(nextIndices[0], nextIndices[1], false);
                bool isUnlocked = manager->isLevelUnlocked();
                if (!isUnlocked) { 
                    manager->unlockLevel();
                    manager->setFurthestLevel();
                    AnimPhaseStruct s2 = {kPhase_MoveAvatar, worldIndex, levelIndex, false};
                    AnimPhaseStruct s3 = {kPhase_LevelUnlock, nextIndices[0], nextIndices[1], false};
                    worldMap->pushPhase(2, s2, s3);
                }
            }
        }
        if (!isBeaten) {
            OBJCHelper::helper()->trackLevelUp(manager->getGlobalIndex());
        }
    }
#ifdef SNS_ENABLE_MINICLIP
    if (OBJCHelper::helper()->canShowMiniclipPopup()) {
        AnimPhaseStruct ss = {kPhase_ShowAdv, worldIndex, levelIndex, false};
        worldMap->pushPhase(ss);
    }
#else
    AnimPhaseStruct ss = {kPhase_ShowAdv, worldIndex, levelIndex, false};
    worldMap->pushPhase(ss);
#endif
    
    manager->setLevel(worldIndex, levelIndex, isQuest, isBranch);
    OBJCHelper::helper()->postRequest(NULL, NULL, kPostType_SyncData);
}

void FMUIResult::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIResult::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUIResult::transitionInDone()
{

}

void FMUIResult::setClassState(int state)
{
    GAMEUI::setClassState(state);
    CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
    if (state == kResult_Win) {
        anim->runAnimationsForSequenceNamed("Win");
    }
    else {
        anim->runAnimationsForSequenceNamed("Lose");
    }
    
}

void FMUIResult::onExit()
{
    GAMEUI_Window::onExit();
    OBJCHelper::helper()->releaseDelegate(this);
    unscheduleUpdate();
}

void FMUIResult::updateFb()
{
#ifndef BRANCH_CN
    CCNode * rankNode = m_ccbNode->getChildByTag(100);
    CCLayer * frdsParent = (CCLayer *)rankNode->getChildByTag(2);

    if (SNSFunction_isFacebookConnected()) {
        ((CCBAnimationManager *)rankNode->getUserObject())->runAnimationsForSequenceNamed("EN");
        frdsParent->getChildByTag(2)->setVisible(true);
    }else{
        ((CCBAnimationManager *)rankNode->getUserObject())->runAnimationsForSequenceNamed("Unconnect");
        frdsParent->getChildByTag(2)->setVisible(false);
    }
#endif
}
void FMUIResult::facebookLoginSuccess()
{
    updateFb();
}

void FMUIResult::update(float delta)
{
    int state = classState();
    if (state == kResult_Win) {
        if (m_showScore < m_earnScore) {
//            int add = delta * 1000.f * 3.f;
            int add = delta * m_earnScore * 0.1f * 6.f;
            m_showScore += add;
            if (m_showScore >= m_earnScore) {
                m_showScore = m_earnScore;
            }
            
            while (m_currentIndex < 3) {
                //stars
                if (m_scoreGaps[m_currentIndex] <= m_showScore) {
                    //get star
                    CCString * animName = CCString::createWithFormat("%d_Get", m_currentIndex+1);
                    m_star[m_currentIndex]->playAnimation(animName->getCString());
                    CCString * effect = CCString::createWithFormat("star_%02d.mp3", m_currentIndex+1);
                    FMSound::playEffect(effect->getCString());
                    m_currentIndex++;
                }
                else {
                    break;
                }
            }
            
//            
//            if (m_currentIndex < 3) {
//                //stars
//                if (m_scoreGaps[m_currentIndex] < m_showScore) {
//                    //get star
//                    CCString * animName = CCString::createWithFormat("%d_Get", m_currentIndex+1);
//                    m_star[m_currentIndex]->playAnimation(animName->getCString());
//                    m_currentIndex++;
//                }
//            }
#ifdef BRANCH_CN
            m_scoreLabel->setString(CCString::createWithFormat("%d", m_showScore)->getCString());
#else
            m_scoreLabel->setString(CCString::createWithFormat("%s", FMDataManager::sharedManager()->getDollarString(m_showScore).c_str())->getCString());
#endif
            
            if (m_showScore >= m_oldHighscore) {
#ifdef BRANCH_CN
                m_highscoreLabel->setString(CCString::createWithFormat("%d", m_showScore)->getCString());
#else
                m_highscoreLabel->setString(CCString::createWithFormat("%s", FMDataManager::sharedManager()->getDollarString(m_showScore).c_str())->getCString());
#endif
                if (!m_highscoreMark->isVisible()) {
                    m_highscoreMark->setVisible(true);
                    m_highscoreMark->playAnimation("Init");
                }
            }
        }
    }
//        if (m_earnStarNum < m_starIndex) {
//            return;
//        }
//        if (m_earnStarNum == m_starIndex) {
//            if (m_currentPercent >= m_scoreGaps[4] || m_currentPercent >= m_percentage) {
//                //reset to data status
//                return;
//            }
//        }
//        CCRect r = m_water->getTextureRect();
//        float width = r.size.width;
//        width += movespeed;
//        //calc percentage
//        
//        if (width >= flowerPos[m_starIndex+1]) {
//            //next
//            //play anim
//            int starNum = m_oldStarNum;
//            if (m_starIndex < starNum) {
//                m_star[m_starIndex]->stopAllActions();
//                m_star[m_starIndex]->playAnimation("2To3");
//            }
//            else if(m_starIndex < 3){
//                m_star[m_starIndex]->stopAllActions();
//                m_star[m_starIndex]->playAnimation("1To3");
//                //TODO: GIVE MAGIC BEANS
//                CCPoint startPoint = m_star[m_starIndex]->convertToWorldSpace(CCPointZero);
//                startPoint = m_rewardParent->convertToNodeSpace(startPoint);
//                NEAnimNode * beanAnim = (NEAnimNode *)m_rewardParent->getChildByTag(2);
//                float delay = 1.0f;
//                FMDataManager * manager = FMDataManager::sharedManager();
//                int rewardNum = manager->getRewardBean(m_starIndex+1);
//                CCNode * beanParent = m_rewardParent->getChildByTag(3);
//                for (int i=0; i<10; i++) {
//                    CCSprite * bean = CCSprite::createWithSpriteFrameName("monet_bean.png");
//                    bean->setVisible(false);
//                    CCDelayTime * d = CCDelayTime::create(delay);
//                    CCShow * show = CCShow::create();
//                    bean->setPosition(startPoint);
//                    bean->setRotation(FMDataManager::getRandom() % 720 - 360);
//                    bean->setScale(0.3f);
//                    CCJumpTo * jump = CCJumpTo::create(0.5f, beanAnim->getPosition(), 75.f, 1);
//                    CCRotateBy * rot = CCRotateBy::create(0.5f, FMDataManager::getRandom() % 720 - 360);
//                    CCScaleTo* scale = CCScaleTo::create(0.5f, 1.f);
//                    CCSpawn* spawn = CCSpawn::create(jump, rot, scale, NULL);
//                    CCCallFuncO * c = CCCallFuncO::create(this, callfuncO_selector(FMUIResult::beanRewardCallback), bean);
//                    CCSequence * seq = CCSequence::create(d, show, spawn, c, NULL);
//                    bean->runAction(seq);
//                    beanParent->addChild(bean, 100 - i);
//                    delay += 0.2f;
//                    bean->setUserData((void *)rewardNum);
//                }
//            }
//            m_starIndex++;
//            CCString * s = CCString::createWithFormat("star_%02d.mp3", m_starIndex);
//            FMSound::playEffect(s->getCString());
//
//        }
//        if (width > flowerPos[4]) {
//            width = flowerPos[4];
//        }
//        float off = width - flowerPos[m_starIndex];
//        float t = (flowerPos[m_starIndex+1] - flowerPos[m_starIndex]) / (m_scoreGaps[m_starIndex+1] - m_scoreGaps[m_starIndex]);
//        int addPercentage = ceil(off / t);
//
//        m_currentPercent = m_scoreGaps[m_starIndex] + addPercentage;
//        
//        if (m_currentPercent > m_percentage) {
//            m_currentPercent = m_percentage;
//        }
//        m_water->setTextureRect(CCRect(r.origin.x, r.origin.y, width, r.size.height));
//        
//        CCLabelBMFont * percentLabel = (CCLabelBMFont *)m_panelWin->getChildByTag(0);
//
//        CCString * s = CCString::createWithFormat("%d%%", m_currentPercent);
//        percentLabel->setString(s->getCString());
//        
//        int score = m_currentPercent * 100;
//        CCString * cstr = CCString::createWithFormat("%d", score);
//        m_scoreLabel->setString(cstr->getCString());
//        
//        if (score > m_oldHighscore) {
//            m_highscoreLabel->setString(cstr->getCString());
//        }
//    }
//    else if (state == kBoxComplete) {
//        if (m_currentPercent >= m_percentage) {
//            return;
//        }
//        m_currentPercent += 1;
//        int score = m_currentPercent * 100;
//        CCString * cstr = CCString::createWithFormat("%d", score);
//        m_scoreLabel->setString(cstr->getCString());
//    }
//    else if (state == kBossComplete || state == kVegeComplete) {
//        if (m_leftMoves >= 0.f) {
//            FMDataManager * manager = FMDataManager::sharedManager();
//            if (!m_enterMovesSummary) {
//                m_currentPercent++;
//                if (m_currentPercent > 100) {
//                    m_currentPercent = 100;
//                    if (m_leftMoves > 0.f) {
//                        m_enterMovesSummary = true;
//                    }
//                }
//                CCString * cstr = CCString::createWithFormat("%d%%", m_currentPercent);
//                m_percentBossLabel->setString(cstr->getCString());
//                 
//                int score = m_currentPercent * 100;
//                cstr = CCString::createWithFormat("%d", score);
//                m_scoreLabel->setString(cstr->getCString());
//                
//                if (score > m_oldHighscore) {
//                    m_highscoreLabel->setString(cstr->getCString());
//                }
//            }
//            else {
//                m_leftMoves -= 0.2f;
//                int leftMoves = m_leftMoves;
//                const char * leftMovesString = manager->getLocalizedString("V108_D_MOVES_LEFT");
//                CCString * cstr = CCString::createWithFormat(leftMovesString, leftMoves);
//                m_leftMovesLabel->setString(cstr->getCString());
//                
//                m_currentPercent++;
//                cstr = CCString::createWithFormat("%d%%", m_currentPercent);
//                m_percentBossLabel->setString(cstr->getCString());
//                
//                if (m_starIndex < 3) {
//                    if (m_currentPercent > m_scoreGaps[m_starIndex+1]) {
//                        //pop star
//                        m_starIndex++;
//                    }
//                }
//                
//                int score = m_currentPercent * 100;
//                cstr = CCString::createWithFormat("%d", score);
//                m_scoreLabel->setString(cstr->getCString());
//                
//                if (score > m_oldHighscore) {
//                    m_highscoreLabel->setString(cstr->getCString());
//                }
//            }
//        }
//    }
}

void FMUIResult::refreshHighScore(int score)
{
    m_rankList->removeAllObjects();
    FMDataManager * manager = FMDataManager::sharedManager();
    CCArray * list = (CCArray *)manager->getFrdLevelDic();
    if (list) {
        m_rankList->addObjectsFromArray(list);
    }
    bool haveSelf = false;
    
#ifdef BRANCH_CN
    for (int i = 0; i < m_rankList->count(); i++) {
        CCDictionary * dic = (CCDictionary *)m_rankList->objectAtIndex(i);
        CCNumber * uid = (CCNumber *)dic->objectForKey("uid");
        if (atoi(manager->getUID()) == uid->getIntValue()) {
            haveSelf = true;
            dic->setObject(CCNumber::create(score), "highscore");
            break;
        }
    }
    if (!haveSelf) {
        CCDictionary * dic = CCDictionary::create();
        dic->setObject(CCNumber::create(atoi(manager->getUID())), "uid");
        dic->setObject(CCNumber::create(score), "highscore");
        dic->setObject(CCString::create("me"), "name");
        dic->setObject(CCNumber::create(manager->getUserIcon()), "icon");
        m_rankList->addObject(dic);
    }
    
    sortList(m_rankList);
    
    
#else
    for (int i = 0; i < m_rankList->count(); i++) {
        CCDictionary * dic = (CCDictionary *)m_rankList->objectAtIndex(i);
        CCString * uid = (CCString *)dic->objectForKey("uid");
        if (SNSFunction_getFacebookUid() != NULL && strcmp(uid->getCString(), SNSFunction_getFacebookUid()) == 0) {
            haveSelf = true;
            dic->setObject(CCNumber::create(score), "highscore");
            break;
        }
    }
    if (!haveSelf) {
        CCDictionary * dic = CCDictionary::create();
        dic->setObject(CCString::createWithFormat("%s",SNSFunction_getFacebookUid()), "uid");
        dic->setObject(CCNumber::create(score), "highscore");
        dic->setObject(CCString::create("me"), "name");
        m_rankList->addObject(dic);
    }
    
    sortList(m_rankList);
    
#endif
    
    updateScrollView();
}

void FMUIResult::updateScrollView()
{
#ifdef BRANCH_CN
    CCLayer * frdsParent = (CCLayer *)m_ccbNode->getChildByTag(100)->getChildByTag(1);
    GUIScrollSlider * slider = (GUIScrollSlider *)frdsParent->getChildByTag(2);
    slider->setMainNodePosition(CCPointZero);
    slider->refresh();
#else
    CCLayer * frdsParent = (CCLayer *)m_ccbNode->getChildByTag(100)->getChildByTag(2);
    GUIScrollSlider * slider = (GUIScrollSlider *)frdsParent->getChildByTag(2);
    slider->setMainNodePosition(CCPointZero);
    slider->refresh();
    
    m_tipPicture->setVisible(m_rankList->count() == 0 && SNSFunction_isFacebookConnected());
#endif
}


int FMUIResult::less(const CCObject* in_pCcObj0, const CCObject* in_pCcObj1) {
    return ((CCNumber *)((CCDictionary *)in_pCcObj0)->objectForKey("highscore"))->getIntValue() > ((CCNumber *)((CCDictionary *)in_pCcObj1)->objectForKey("highscore"))->getIntValue();
}

void FMUIResult::sortList(CCArray* list) {
    std::sort(list->data->arr, list->data->arr + list->data->num, FMUIResult::less);
}

#pragma mark - GUIScrollSliderDelegate

void FMUIResult::sliderUpdate(GUIScrollSlider *slider, int rowIndex, cocos2d::CCNode *node)
{
    node->setTag(rowIndex);
    FMDataManager * manager = FMDataManager::sharedManager();
    CCDictionary * dic = (CCDictionary *)m_rankList->objectAtIndex(rowIndex);
#ifdef BRANCH_CN
    CCNumber * uid = (CCNumber *)dic->objectForKey("uid");
    CCString * name = (CCString *)dic->objectForKey("name");
    CCNumber * icon = (CCNumber *)dic->objectForKey("icon");
    CCNumber * highscore = (CCNumber *)dic->objectForKey("highscore");
    CCSprite * bg = (CCSprite *)node->getChildByTag(1);
    CCSprite * avatar = (CCSprite *)node->getChildByTag(2);
    CCSprite * up = (CCSprite *)node->getChildByTag(3);
    CCLabelTTF * namelabel = (CCLabelTTF *)node->getChildByTag(4);
    CCLabelTTF * scorelabel = (CCLabelTTF *)node->getChildByTag(5);
    CCSprite * crown = (CCSprite *)node->getChildByTag(10);
    crown->setVisible(true);
    CCLabelBMFont * ranklabel = (CCLabelBMFont *)crown->getChildByTag(1);
    CCSpriteFrame * bgframe;
    CCSpriteFrame * upframe;
    
    if (rowIndex == 0) {
        bgframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_b_1.png");
        upframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_u_1.png");
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_rank_1.png");
        crown->setDisplayFrame(frame);
        ranklabel->setString("1.");
    }
    else if (rowIndex < 3){
        bgframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_b_2.png");
        upframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_u_2.png");
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(CCString::createWithFormat("ui_icon_rank_%d.png",rowIndex+1)->getCString());
        crown->setDisplayFrame(frame);
        ranklabel->setString(CCString::createWithFormat("%d.",rowIndex+1)->getCString());
    }
    else if (uid->getIntValue() == atoi(manager->getUID())){
        bgframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_b_4.png");
        upframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_u_4.png");
        crown->setVisible(false);
    }
    else{
        bgframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_b_3.png");
        upframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_u_3.png");
        crown->setVisible(false);
    }
    if (name) {
        namelabel->setString(name->getCString());
    }else{
        namelabel->setString(CCString::createWithFormat("%d",uid->getIntValue())->getCString());
    }
    bg->setDisplayFrame(bgframe);
    up->setDisplayFrame(upframe);

    scorelabel->setString(CCString::createWithFormat("%d",highscore->getIntValue())->getCString());
    
    int iconint = icon->getIntValue() - 1;
    if (iconint < 0 || iconint > 5) {
        iconint = 0;
    }
    CCSpriteFrame * iconframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(CCString::createWithFormat("usericon%d.png",iconint)->getCString());
    avatar->setDisplayFrame(iconframe);
    
    
    if (uid->getIntValue() == atoi(manager->getUID())) {
        const char* me = manager->getLocalizedString("V110_ME_NAME");
        namelabel->setString(me);
    }
#else
    CCString * uid = (CCString *)dic->objectForKey("uid");
    CCString * name = (CCString *)dic->objectForKey("name");
    CCNumber * highscore = (CCNumber *)dic->objectForKey("highscore");
    CCNode * parentNode = node->getChildByTag(1);
    CCSprite * avatar = (CCSprite *)parentNode->getChildByTag(1);
    CCLabelTTF * namelabel = (CCLabelTTF *)parentNode->getChildByTag(3);
    CCLabelTTF * scorelabel = (CCLabelTTF *)parentNode->getChildByTag(4);
    CCSprite * crown = (CCSprite *)parentNode->getChildByTag(10);
    crown->setVisible(true);
    CCLabelBMFont * ranklabel = (CCLabelBMFont *)crown->getChildByTag(1);
    if (rowIndex == 0) {
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_rank_1.png");
        crown->setDisplayFrame(frame);
        ranklabel->setString("1");
    }
    else if (rowIndex < 3){
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(CCString::createWithFormat("ui_icon_rank_%d.png",rowIndex+1)->getCString());
        crown->setDisplayFrame(frame);
        ranklabel->setString(CCString::createWithFormat("%d",rowIndex+1)->getCString());
    }
    else if (SNSFunction_getFacebookUid() != NULL && strcmp(uid->getCString(), SNSFunction_getFacebookUid()) == 0){
        crown->setVisible(false);
    }
    else{
        crown->setVisible(false);
    }
    if (name) {
        namelabel->setString(name->getCString());
    }else{
        namelabel->setString("");
    }
    scorelabel->setString(CCString::createWithFormat("%s",FMDataManager::sharedManager()->getDollarString(highscore->getIntValue()).c_str())->getCString());
    
    const char * icon = SNSFunction_getFacebookIcon(uid->getCString());
    avatar->removeChildByTag(10);
    if (icon && FMDataManager::sharedManager()->isFileExist(icon)){
        CCSprite * spr = CCSprite::create(icon);
        float size = 52.f;
        spr->setScale(size / MAX(spr->getContentSize().width, size));
        avatar->addChild(spr, 0, 10);
        spr->setPosition(ccp(avatar->getContentSize().width/2, avatar->getContentSize().height/2));
    }else{
        
    }
    
    
    CCNode * sendlifeBtn = parentNode->getChildByTag(2);
    if (uid != NULL && SNSFunction_getFacebookUid() != NULL && strcmp(uid->getCString(), SNSFunction_getFacebookUid()) == 0) {
        const char* me = manager->getLocalizedString("V110_ME_NAME");
        namelabel->setString(me);
        sendlifeBtn->setVisible(false);
    }else{
        sendlifeBtn->setVisible(OBJCHelper::helper()->isFrdMsgEnable(uid->getCString(), 1));
    }
#endif
}

CCNode * FMUIResult::createItemForSlider(GUIScrollSlider *slider)
{
#ifdef BRANCH_CN
    CCNode * node = FMDataManager::sharedManager()->createNode("UI/FMUIRankAvatar.ccbi", this);
#else
    CCNode * node = FMDataManager::sharedManager()->createNode("UI/FMUIRankAvatarFB.ccbi", this);
#endif
    
    return node;
}

int FMUIResult::itemsCountForSlider(GUIScrollSlider *slider)
{
    return m_rankList->count();
}

void FMUIResult::onSendLifeSuccess()
{
    updateScrollView();
}

