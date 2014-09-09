//
//  FMUIUnlockChapter.cpp
//  FarmMania
//
//  Created by James Lee on 13-6-8.
//
//

#include "FMUIUnlockChapter.h"

#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "FMUILevelStart.h"
#include "FMUINeedHeart.h"
#include "FMUIInAppStore.h"
#include "FMWorldMapNode.h"
#include "OBJCHelper.h"
#include "GameConfig.h"

static iapItemGroup unlockGroup = {6, "", "", 0, 0, true, "com.naughtycat.jellymania.superpower1", "$", "USD"};

FMUIUnlockChapter::FMUIUnlockChapter() :
    m_parentNode(NULL),
    m_panel1Node(NULL),
    m_panel2Node(NULL),
    m_uiAnim(NULL),
    m_instantMove(false)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIUnlockChapter.ccbi", this);
    addChild(m_ccbNode);
    
    for (int i = 0; i<3; i++) {
        m_button[i] = (NEAnimNode *)m_panel1Node->getChildByTag(20 + i);
    }
    NEAnimNode * priceButton = ((CCAnimButton *)m_panel2Node->getChildByTag(1))->getAnimNode();
    priceButton->releaseControl("Label", kProperty_StringValue);
    
//    CCNode * parent = m_panel1Node->getChildByTag(4);
//    NEAnimNode * key = NEAnimNode::createNodeFromFile("FMKey.ani");
//    parent->addChild(key, 10);
//    key->setSmoothPlaying(true);
//    key->playAnimation("Shine");
//#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
//    CCLabelBMFont * title = (CCLabelBMFont *)m_parentNode->getChildByTag(2);
//    title->setAlignment(kCCTextAlignmentCenter);
//#endif
}

FMUIUnlockChapter::~FMUIUnlockChapter()
{
    
}

#pragma mark - CCB Bindings
bool FMUIUnlockChapter::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_panel1Node", CCNode *, m_panel1Node);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_panel2Node", CCNode *, m_panel2Node);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_uiAnim", NEAnimNode *, m_uiAnim);
    return true;
}

SEL_CCControlHandler FMUIUnlockChapter::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIUnlockChapter::clickButton);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickQuest", FMUIUnlockChapter::clickQuest);
    return NULL;
}

void FMUIUnlockChapter::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIUnlockChapter::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    switch (button->getTag()) {
        case 0:
        {
            //close
            m_instantMove = false;
            GAMEUI_Scene::uiSystem()->prevWindow();
        }
            break;
        case 1:
        {
            //buy keys to unlock
//            buyIAPCallback(CCNumber::create(1));
            OBJCHelper::helper()->buyIAPItem(unlockGroup.ID, 1, this, callfuncO_selector(FMUIUnlockChapter::buyIAPCallback));
        }
            break;
        default:
            break;
    }
}


void FMUIUnlockChapter::buyIAPCallback(cocos2d::CCObject *object)
{
    CCNumber * num = (CCNumber *)object;
    bool succeed = num->getIntValue() == 1;
    if (succeed) {
        GAMEUI_Scene::uiSystem()->prevWindow();

        FMDataManager * manager = FMDataManager::sharedManager();
        int world = manager->getWorldIndex();
        int level = manager->getLevelIndex();
        bool isQuest = manager->isQuest();
        FMWorldMapNode * worldmap = (FMWorldMapNode *)((FMMainScene *)manager->getUI(kUI_MainScene))->getNode(kWorldMapNode);
        
        for (int i =0; i<3; i++) {
            manager->setLevel(world, i, true);
            bool isBeaten = manager->isLevelBeaten();
            if (!isBeaten) {
                //play anim
                AnimPhaseStruct s = {kPhase_QuestPassed, world, i, true};
                worldmap->pushPhase(s);
                manager->setLevelBeaten();
                manager->unlockLevel();
            }
        }
        manager->unlockWorld(true);
        std::vector<int> nextIndices = manager->getNextLevel(world, -1);
        manager->setLevel(nextIndices[0], nextIndices[1], false);
        manager->unlockLevel();
        manager->openWorld();
        manager->cleanQuestCD();
        manager->setFurthestLevel();
         
        AnimPhaseStruct s1 = {kPhase_QuestComplete, world, -1, false};
        AnimPhaseStruct s2 = {kPhase_WorldUnlock, nextIndices[0], -1, false};
       
        worldmap->pushPhase(2, s1, s2);
        manager->setLevel(world, level, isQuest);
        worldmap->updatePhases();
        worldmap->runPhase();
        manager->saveGame();        
    }
    CCLOG("iap buy : %d" , succeed);
}


void FMUIUnlockChapter::clickQuest(cocos2d::CCObject *object, CCControlEvent event)
{
    CCControlButton * button = (CCControlButton *)object;
    int tag = button->getTag();
    int index = tag - 10;
    bool current = (int)m_button[index]->getUserData() == 1;
    FMDataManager * manager = FMDataManager::sharedManager();
    bool cooldown = manager->getQuestCD() == -1;
    if (current && cooldown) {
        //play this level

        int life = manager->getLifeNum();
        if (life > 0) {
            //close this window
            GAMEUI_Scene::uiSystem()->prevWindow();
            int world = manager->getWorldIndex();
            manager->setLevel(world, index, true);
            FMUILevelStart * window = (FMUILevelStart *)manager->getUI(kUI_LevelStart);
            window->setClassState(0);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
        else {
            FMUINeedHeart * window = (FMUINeedHeart *)manager->getUI(kUI_NeedHeart);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
    }
}

 
void FMUIUnlockChapter::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIUnlockChapter::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUIUnlockChapter::onEnter()
{
    GAMEUI_Window::onEnter();
    scheduleUpdate();
    updateUI();
    NEAnimationDoneAction * anim1 = NEAnimationDoneAction::create(m_uiAnim, "UITrapped");
    NEAnimationDoneAction * anim2 = NEAnimationDoneAction::create(m_uiAnim, "UITrapIdle");
    CCSequence * seq = CCSequence::create(anim1, anim2, NULL);
    m_uiAnim->stopAnimation();
    m_uiAnim->runAction(seq);
}

void FMUIUnlockChapter::onExit()
{
    GAMEUI_Window::onExit();
    unscheduleUpdate();
}

void FMUIUnlockChapter::updateUI()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    int worldIndex = manager->getWorldIndex();
    int levelIndex = manager->getLevelIndex();
    bool quest = manager->isQuest();
    m_current = -1; 

    bool isCoolDown = manager->getQuestCD() == -1;
    for (int i=0; i<3; i++) {
        manager->setLevel(worldIndex, i, true);
        bool beaten = manager->isLevelBeaten();
 
        m_button[i]->setUserData((void*)false);
        if (beaten) {
            m_button[i]->playAnimation("UIQuestComplete",0 ,false, true);
        }
        else if (m_current == -1){
            m_current = i;
            if (isCoolDown) {
                m_button[i]->playAnimation("UIQuestCurrent");
            }
            else {
                m_button[i]->playAnimation("UIQuestInCD");
            }
            
            m_button[i]->setUserData((void*)1);
        }
        else {
            m_button[i]->playAnimation("UIQuestLocked");
        } 
    }
    
    OBJCHelper::helper()->updateIAPGroup(&unlockGroup);
    NEAnimNode * priceButton = ((CCAnimButton *)m_panel2Node->getChildByTag(1))->getAnimNode();
    CCLabelBMFont * priceLabel = (CCLabelBMFont *)priceButton->getNodeByName("Label");
    const char * s = manager->getLocalizedString("V100_BUY_FOR_(S)_(S)");
    CCString * cstr = CCString::createWithFormat(s, unlockGroup.symbol, unlockGroup.price);
    priceLabel->setString(cstr->getCString());
    
    CCLabelBMFont * questCDLabel = (CCLabelBMFont *)m_panel1Node->getChildByTag(55);
    int questcooldown = manager->getQuestCD();
    if (questcooldown == -1) {
        questCDLabel->setString("");
        questCDLabel->setVisible(false);
    }
    else {
        const char * s = manager->getLocalizedString("V100_PLAY_QUEST_(D)_IN_(S)");
        int remain = manager->getRemainTime(questcooldown);
        CCString * cstr = CCString::createWithFormat(s, m_current + 1, manager->getTimeString(remain)->getCString());
        questCDLabel->setString(cstr->getCString());
        questCDLabel->setVisible(true);
    }
    
    manager->setLevel(worldIndex, levelIndex, quest);
}

void FMUIUnlockChapter::update(float delta)
{
    CCLabelBMFont * questCDLabel = (CCLabelBMFont *)m_panel1Node->getChildByTag(55);
    FMDataManager * manager = FMDataManager::sharedManager();
    int questcooldown = manager->getQuestCD();

    if (questcooldown == -1) {
        if (!questCDLabel->isVisible()) {
            return;
        }
        questCDLabel->setVisible(false);
    }
    else {
        const char * s = manager->getLocalizedString("V100_PLAY_QUEST_(D)_IN_(S)");
        int remain = manager->getRemainTime(questcooldown);
        CCString * cstr = CCString::createWithFormat(s, m_current + 1, manager->getTimeString(remain)->getCString());
        questCDLabel->setString(cstr->getCString());
        if (remain == 0) {
            manager->cleanQuestCD();
            updateUI();
        } 
    }
}

CCPoint FMUIUnlockChapter::getTutorialPosition(int index)
{
    switch (index) {
        case 0:
        {
            CCPoint wp = m_panel1Node->convertToWorldSpace(CCPointZero);
            return wp;
        }
            break;
        case 1:
        {
            CCPoint wp = m_panel2Node->convertToWorldSpace(CCPointZero);
            return wp;
        }
            break;
        default:
            break;
    }
    return CCPointZero;
}

void FMUIUnlockChapter::transitionInDone()
{
    GAMEUI_Window::transitionInDone(); 
    FMDataManager::sharedManager()->checkNewTutorial();
    FMDataManager::sharedManager()->tutorialBegin();
}
