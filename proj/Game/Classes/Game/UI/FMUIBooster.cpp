//
//  FMUIBooster.cpp
//  FarmMania
//
//  Created by  James Lee on 13-6-4.
//
//

#include "FMUIBooster.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMGameNode.h"
#include "FMMainScene.h"
#include "FMStatusbar.h"
#include "NEAnimNode.h"
#include "SNSFunction.h"
using namespace neanim;

#ifdef BRANCH_CN
boosterDataStruct boostersData[10] = {
    {kBooster_Harvest1Grid, 36, 36, 3, "V100_BOOSTER_0", "V100_BOOSTER_HARVEST1GRID_INFO"},
    {kBooster_Harvest1Row, 59, 59, 3, "V100_BOOSTER_1", "V100_BOOSTER_HARVEST1ROW_INFO"},
    {kBooster_PlusOne, 59, 59, 3, "V100_BOOSTER_2", "V100_BOOSTER_+1_INFO"},
    {kBooster_Harvest1Type, 59, 59, 3, "V100_BOOSTER_3", "V100_BOOSTER_HARVEST1TYPE_INFO"},
    {kBooster_Shuffle, 59, 59, 3, "V100_BOOSTER_4", "V100_BOOSTER_SHUFFLE_INFO"},
    {kBooster_CureRot, 59, 59, 3, "V100_BOOSTER_5", "V100_BOOSTER_CUREROT_INFO"},
    {kBooster_MovePlusFive, 18, 18, 1, "V100_BOOSTER_6", "V100_BOOSTER_MOVE+5_INFO"},
    {kBooster_TCross, 15, 15, 1, "V100_BOOSTER_7", "V100_BOOSTER_TCROSS_INFO"},
    {kBooster_4Match, 12, 12, 1, "V100_BOOSTER_8", "V100_BOOSTER_4MATCH_INFO"},
    {kBooster_5Line, 18, 18, 1, "V100_BOOSTER_9", "V100_BOOSTER_5LINE_INFO"},
};
#else
boosterDataStruct boostersData[10] = {
    {kBooster_Harvest1Grid, 18, 18, 3, "V100_BOOSTER_0", "V100_BOOSTER_HARVEST1GRID_INFO"},
    {kBooster_Harvest1Row, 27, 27, 3, "V100_BOOSTER_1", "V100_BOOSTER_HARVEST1ROW_INFO"},
    {kBooster_PlusOne, 27, 27, 3, "V100_BOOSTER_2", "V100_BOOSTER_+1_INFO"},
    {kBooster_Harvest1Type, 27, 27, 3, "V100_BOOSTER_3", "V100_BOOSTER_HARVEST1TYPE_INFO"},
    {kBooster_Shuffle, 27, 27, 3, "V100_BOOSTER_4", "V100_BOOSTER_SHUFFLE_INFO"},
    {kBooster_CureRot, 27, 27, 3, "V100_BOOSTER_5", "V100_BOOSTER_CUREROT_INFO"},
    {kBooster_MovePlusFive, 9, 9, 1, "V100_BOOSTER_6", "V100_BOOSTER_MOVE+5_INFO"},
    {kBooster_TCross, 7, 7, 1, "V100_BOOSTER_7", "V100_BOOSTER_TCROSS_INFO"},
    {kBooster_4Match, 6, 6, 1, "V100_BOOSTER_8", "V100_BOOSTER_4MATCH_INFO"},
    {kBooster_5Line, 8, 8, 1, "V100_BOOSTER_9", "V100_BOOSTER_5LINE_INFO"},
};
#endif

FMUIBooster::FMUIBooster() :
    m_parentNode(NULL),
    m_amountLabel(NULL),
    m_boosterIcon(NULL),
    m_boosterCount(NULL),
    m_willClose(false),
    m_recharging(false),
    m_unlockLabel(NULL),
    m_newBoostLabel(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIBooster.ccbi", this);
    addChild(m_ccbNode);
    
    CCLabelBMFont * title = (CCLabelBMFont *)m_parentNode->getChildByTag(3);
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
    title->setAlignment(kCCTextAlignmentCenter);
#endif
    
    NEAnimNode * booster = (NEAnimNode *)m_parentNode->getChildByTag(1);
    booster->releaseControl("Clock");
    booster->releaseControl("Booster");
    
    NEAnimNode * boosterIcon = (NEAnimNode *)booster->getNodeByName("Booster");
    m_boosterIcon = boosterIcon;
    
    NEAnimNode * boosterClock = (NEAnimNode *)booster->getNodeByName("Clock");
    boosterClock->setVisible(false);
    
    NEAnimNode * boosterCount = (NEAnimNode *)booster->getNodeByName("Count");
    boosterCount->releaseControl("Label", kProperty_StringValue);
    m_boosterCount = boosterCount;
    m_amountLabel = (CCLabelBMFont *)boosterCount->getNodeByName("Label");
    
    CCAnimButton * priceButton = (CCAnimButton *)m_parentNode->getChildByTag(15);
    priceButton->getAnimNode()->releaseControl("Label", kProperty_StringValue);

}

FMUIBooster::~FMUIBooster()
{
    
}

#pragma mark - CCB Bindings
bool FMUIBooster::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_newBoostLabel", CCLabelBMFont *, m_newBoostLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_unlockLabel", CCLabelBMFont *, m_unlockLabel);
    return true;
}

SEL_CCControlHandler FMUIBooster::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIBooster::clickButton);
    return NULL;
}

void FMUIBooster::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        m_willClose = true;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIBooster::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    CCControlButton * button = (CCControlButton *)object;
    int state = classState();
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    switch (button->getTag()) {
        case 0:
        {
            //close
            m_willClose = true;
            GAMEUI_Scene::uiSystem()->prevWindow(); 
        }
            break;
        case 16:
        {
            if (state == kUIBooster_Unlock) {
                GAMEUI_Scene::uiSystem()->prevWindow();
            }
        }
            break;
        case 15:
        {
            //buy
            FMDataManager* manager = FMDataManager::sharedManager();
            bool inGame = manager->isInGame();
            int price = inGame ? boostersData[m_type].inGamePrice : boostersData[m_type].outGamePrice;

            //discount
            if (!inGame && manager->whetherUnsealLevelStartDiscount()) {
                price /= 2;
            }
            
            if (manager->useMoney(price, manager->getLocalizedString(boostersData[m_type].name))) {
                int num = boostersData[m_type].amount;
                manager->setBoosterAmount(m_type, num);
                manager->stopBoosterTimer(m_type);
                {
                    
                    const char * key;
                    if (manager->isQuest()) {
                        int world = manager->getWorldIndex();
                        int level = manager->getLevelIndex();
                        key = CCString::createWithFormat("%d-%d", world+1, level+1)->getCString();
                    }
                    else {
                        key = CCString::createWithFormat("%d", manager->getGlobalIndex())->getCString();
                    }
                    
                    std::stringstream ss;
                    ss << "level[" << key << "]";
                    if (inGame) {
                        FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
                        FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);
                        if (game->isGameOver()) {
                            ss << "retry";
                        }
                        else {
                            ss << "playing";
                        }
                    }
                    else {
                        ss << "before";
                    }
                    SNSFunction_logBuyItem(boostersData[m_type].name, num, abs(price), price < 0 ? 2 : 1, 0, ss.str().c_str());
                }
                m_willClose = true;
                m_recharging = false;
                GAMEUI_Scene::uiSystem()->prevWindow();
                
                //update gameui
                if (inGame) {
                    FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
                    FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);
                    if (!game->isGameOver()) {
                        game->updateBoosters();
                        game->enterUseItemMode(m_type);
                    }
                }
            }
        }
            break;
            
        default:
            break;
    }
}
 
void FMUIBooster::setClassState(int state)
{
    GAMEUI::setClassState(state);
    CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
    switch (state) {
        case kUIBooster_Buy:
        {
            anim->runAnimationsForSequenceNamed("Buy");
        }
            break;
        case kUIBooster_Unlock:
        {
            anim->runAnimationsForSequenceNamed("Unlock");
        }
            break;
        default:
            break;
    }
}

void FMUIBooster::onEnter()
{
    GAMEUI_Window::onEnter();
    m_willClose = false;
//    scheduleUpdate();
    FMDataManager * manager = FMDataManager::sharedManager();

    CCLabelBMFont * title = (CCLabelBMFont *)m_parentNode->getChildByTag(3);
    CCLabelBMFont * info  = (CCLabelBMFont *)m_parentNode->getChildByTag(11);
    info->setWidth(200.f);
    info->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());

    int state = classState();
    switch (state) {
        case kUIBooster_Buy:
        {
            //title
            CCString * cstr = NULL;
            const char * s = manager->getLocalizedString(boostersData[m_type].name);
            cstr = CCString::createWithFormat(manager->getLocalizedString("%s"), s);
            title->setString(cstr->getCString());

            //info
            s = manager->getLocalizedString(boostersData[m_type].info);
            info->setString(s);
            
            //time
            int boosterTime = manager->getBoosterTime(m_type);
            m_recharging = boosterTime != -1;
            
            int remainTime = manager->getRemainTime(boosterTime);
            s = manager->getTimeString(remainTime)->getCString();
            CCLabelBMFont * timeLabel = (CCLabelBMFont *)m_parentNode->getChildByTag(4);
            const char * ss = manager->getLocalizedString("V100_+1_IN_(S)");
            cstr = CCString::createWithFormat(ss, s);
            timeLabel->setString(cstr->getCString());
            timeLabel->setVisible(remainTime != 0);

            //booster
            kGameBooster type = (kGameBooster)m_type;
            m_boosterIcon->useSkin(FMGameNode::getBoosterSkin(type));
            
            //num
            int num = boostersData[m_type].amount;
            cstr = CCString::createWithFormat("%d", num);
            s = cstr->getCString();
            m_amountLabel->setString(s);
            m_boosterCount->setVisible(true);
            
            //price
            CCAnimButton * priceButton = (CCAnimButton *)m_parentNode->getChildByTag(15);
            CCLabelBMFont * priceLabel = (CCLabelBMFont *)priceButton->getAnimNode()->getNodeByName("Label");
            bool inGame = manager->isInGame();
            int price = inGame ? boostersData[m_type].outGamePrice : boostersData[m_type].inGamePrice;
            
            //discount
            if (!inGame && manager->whetherUnsealLevelStartDiscount()) {
                price /= 2;
            }

            s = manager->getLocalizedString("V100_BUY_FOR_(D)");
            cstr = CCString::createWithFormat(s, price);
            priceLabel->setString(cstr->getCString());
        }
            break;
        case kUIBooster_Unlock:
        {
            //title
            CCString * cstr = NULL;
            const char * s = manager->getLocalizedString(boostersData[m_type].name);
            cstr = CCString::createWithFormat(manager->getLocalizedString("%s"), s);
            title->setString(cstr->getCString());
            
            //info
            s = manager->getLocalizedString(boostersData[m_type].info);
            info->setString(s);
            
            //booster
            kGameBooster type = (kGameBooster)m_type;
            m_boosterIcon->useSkin(FMGameNode::getBoosterSkin(type));
            
            m_boosterCount->setVisible(false);
        }
            break;
        default:
            break;
    }
    
#ifdef BRANCH_TH
    m_newBoostLabel->setPosition(ccp(0, 183));
    m_unlockLabel->setPosition(ccp(0, 149));
#endif
    
}

void FMUIBooster::onExit()
{
    GAMEUI_Window::onExit();
    unscheduleUpdate();
}

void FMUIBooster::update(float delta)
{
    if (classState() == kUIBooster_Buy) {
        FMDataManager * manager = FMDataManager::sharedManager();
        bool isTiming = manager->isBoosterTiming(m_type);
        if (!isTiming) {
            return;
        }
        int boosterTime = manager->getBoosterTime(m_type);
        bool updateui = true;
        if (boosterTime == -1) {
            if (m_recharging) {
                m_recharging = false;
                m_willClose = true;
                GAMEUI_Scene::uiSystem()->prevWindow();
            }
            else {
                updateui = false;
            }
        }
        if (!updateui) {
            return;
        }
        int remainTime = manager->getRemainTime(boosterTime);
        if (remainTime == 0 && boosterTime != -1) {
            manager->stopBoosterTimer(m_type);
            int amount = manager->getBoosterAmount(m_type);
            amount++;
            manager->setBoosterAmount(m_type, amount); 
        }
        const char * s = manager->getTimeString(remainTime)->getCString();
        CCLabelBMFont * timeLabel = (CCLabelBMFont *)m_parentNode->getChildByTag(4);
        timeLabel->setString(s);

        //time
        const char * ss = manager->getLocalizedString("V100_+1_IN_(S)");
        CCString * cstr = CCString::createWithFormat(ss, s);
        timeLabel->setString(cstr->getCString());
        timeLabel->setVisible(remainTime != 0);
    }
}

void FMUIBooster::updateUI()
{
    
}


void FMUIBooster::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
    int state = classState();
    if (state == kUIBooster_Buy) {
        FMDataManager * manager = FMDataManager::sharedManager();
        if (manager->isInGame()) {
            //move in slider
            FMStatusbar * statusbar = (FMStatusbar *)manager->getUI(kUI_Statusbar);
            statusbar->show(true);
        }
    }
}

void FMUIBooster::transitionOut(cocos2d::CCCallFunc *finishAction)
{ 
    GAMEUI_Window::transitionOut(finishAction);
    int state = classState();
    if (state == kUIBooster_Buy && m_willClose) {
        FMDataManager * manager = FMDataManager::sharedManager();
        if (manager->isInGame()) {
            FMGameNode * game = (FMGameNode *)((FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene))->getNode(kGameNode);
            if (!game->isGameOver()) {
                //move out slider
                FMStatusbar * statusbar = (FMStatusbar *)manager->getUI(kUI_Statusbar);
                statusbar->show(false);
            }
        }
    }
}
void FMUIBooster::transitionInDone()
{
    GAMEUI_Window::transitionInDone();
    scheduleUpdate();
    //    FMDataManager::sharedManager()->checkNewTutorial();
    //    FMDataManager::sharedManager()->tutorialBegin();
}
