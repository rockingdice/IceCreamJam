//
//  FMUIGoldIapBonus.cpp
//  JellyMania
//
//  Created by ywthahaha on 14-4-22.
//
//

#include "FMUIGoldIapBonus.h"

#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "OBJCHelper.h"
#include "FMUIInAppStore.h"
#include "FMEnergyManager.h"
#include "FMUIBooster.h"
#include "SNSFunction.h"
#include "FMUIRewardBoard.h"



FMUIGoldIapBonus::FMUIGoldIapBonus() :
m_parentNode(NULL),
m_titleLabel(NULL),
m_purchasedLabel(NULL),
m_timeLabel(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIGoldIapBonus.ccbi", this);
    addChild(m_ccbNode);
}

FMUIGoldIapBonus::~FMUIGoldIapBonus()
{
}

#pragma mark - CCB Bindings
bool FMUIGoldIapBonus::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_titleLabel", CCLabelBMFont *, m_titleLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_purchasedLabel", CCLabelBMFont * , m_purchasedLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_timeLabel", CCLabelBMFont *, m_timeLabel);
    return true;
}

SEL_CCControlHandler FMUIGoldIapBonus::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIGoldIapBonus::clickButton);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "getBonus", FMUIGoldIapBonus::getBonus);
    return NULL;
}

void FMUIGoldIapBonus::getBonus(CCNode *sender, CCControlEvent event)
{
    int tag = sender->getParent()->getTag();
    if (tag == -1) tag = sender->getParent()->getParent()->getTag();
    CCString* indexStr = CCString::createWithFormat("%d",tag+1);
    
    FMDataManager* manager = FMDataManager::sharedManager();
    CCDictionary* dicData = (CCDictionary* )manager->getUserSave()->objectForKey(kGoldIapBonusDic);
    int curPurchased = ((CCNumber*)dicData->objectForKey("gold"))->getIntValue();
    
    const char* str = SNSFunction_getRemoteConfigString(kGoldIapBouns);
    CCDictionary* remoteSetDic = OBJCHelper::helper()->converJsonStrToCCDic(str);
    if (!remoteSetDic) return;
    
    char phaseKey[16] = {0};
    sprintf(phaseKey, "IapPhase%d",tag +1);
    int phaseValue = remoteSetDic->valueForKey(phaseKey)->intValue();
    if (curPurchased < phaseValue) return;
    bool hasGetBonus = ((CCNumber* )dicData->objectForKey(indexStr->getCString()))->getIntValue();
    
    if (!hasGetBonus) {
        char bonusKey[16] = {0};
        sprintf(bonusKey, "Bonus%d",tag +1);
        int bonusValue = remoteSetDic->valueForKey(bonusKey)->intValue();
        //加金币
        int num = manager->getGoldNum();
        num += bonusValue;
        manager->setGoldNum(num);
        dicData->setObject(CCNumber::create(1), indexStr->getCString());
        manager->saveGame();

        FMUIRewardBoard * window = (FMUIRewardBoard *)manager->getUI(kUI_RewardBoard);
        window->setRewardType(kRwdTypeGold);
        window->setAmount(bonusValue);
        window->setRewardFrom(kRewardFromGoldIapBonus);
        window->setGoldIapIndex(indexStr->intValue());
        GAMEUI_Scene::uiSystem()->nextWindow(window);
    }
    
}

void FMUIGoldIapBonus::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIGoldIapBonus::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMDataManager* manager = FMDataManager::sharedManager();
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
            //show iap
            FMUIInAppStore * window = (FMUIInAppStore *)manager->getUI(kUI_IAPGold);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
            break;
            
            
        default:
            break;
    }
}



void FMUIGoldIapBonus::onExit()
{
    GAMEUI_Window::onExit();
}

void FMUIGoldIapBonus::onEnter()
{
    GAMEUI_Window::onEnter();
    unscheduleUpdate();
    scheduleUpdate();
}


void FMUIGoldIapBonus::update(float time)
{
    updateUI();
}

void FMUIGoldIapBonus::updateUI()
{
    FMDataManager* manager = FMDataManager::sharedManager();
    CCDictionary* dicData = (CCDictionary* )manager->getUserSave()->objectForKey(kGoldIapBonusDic);
    if (!dicData){
        manager->resetIapBounsSaveData();
        dicData = (CCDictionary* )manager->getUserSave()->objectForKey(kGoldIapBonusDic);
    }
    
    int curPurchased = ((CCNumber*)dicData->objectForKey("gold"))->getIntValue();
    m_purchasedLabel->setString(CCString::createWithFormat("%d",curPurchased)->getCString());
    const char* str = SNSFunction_getRemoteConfigString(kGoldIapBouns);
    CCDictionary* remoteSetDic = OBJCHelper::helper()->converJsonStrToCCDic(str);
    if (!remoteSetDic) return;
    
    for (int i = 1; i < 5; ++i) {
        CCNode* item = m_parentNode->getChildByTag(i -1);
        CCString* indexStr = CCString::createWithFormat("%d",i);
        char phaseKey[16] = {0};
        sprintf(phaseKey, "IapPhase%d",i);
        int phaseValue = remoteSetDic->valueForKey(phaseKey)->intValue();
        char bonusKey[16] = {0};
        sprintf(bonusKey, "Bonus%d",i);
        int bonusValue = remoteSetDic->valueForKey(bonusKey)->intValue();
        
        CCLabelBMFont* earnLabel = (CCLabelBMFont* )item->getChildByTag(0);
        earnLabel->setString(CCString::createWithFormat("x%d",bonusValue)->getCString());
        
        CCNode* coverSpt = item->getChildByTag(1);
        CCNode* greenCheck = item->getChildByTag(2);
        CCAnimButton* btn = (CCAnimButton* )item->getChildByTag(3);
        CCLabelBMFont* getLabel = (CCLabelBMFont*)item->getChildByTag(4);

        bool hasGetBonus = ((CCNumber* )dicData->objectForKey(indexStr->getCString()))->getIntValue();
        bool notReachTarget = curPurchased < phaseValue;
        
        if (hasGetBonus) {//已领取
            coverSpt->setVisible(true);
            greenCheck->setVisible(true);
            btn->setVisible(false);
            btn->setEnabled(false);
            getLabel->setString(manager->getLocalizedString("V140_HAS_GETED"));
        }else if (notReachTarget){//未满足领取条件
            coverSpt->setVisible(false);
            greenCheck->setVisible(false);
            btn->setVisible(false);
            btn->setEnabled(false);
            CCString* str = CCString::createWithFormat(manager->getLocalizedString("V140_NEED_NUM_TO_GET"),phaseValue - curPurchased);
            getLabel->setString(str->getCString());
        }else{//可领取
            coverSpt->setVisible(false);
            greenCheck->setVisible(false);
            btn->setVisible(true);
            btn->setEnabled(true);
            getLabel->setString(manager->getLocalizedString("V140_GET_NOW"));
        }
        
    }
    
    const char* partStr = manager->getLocalizedString("V140_BONUS_END");
    double endTime = manager->getDiscountTimeByKey(kGoldIapBouns,false);
    int remain = manager->getRemainTime(endTime);
    const char* timeStr = manager->getTimeString(remain)->getCString();
    CCString* lastStr = CCString::createWithFormat("%s%s",partStr,timeStr);
    m_timeLabel->setString(lastStr->getCString());
}



void FMUIGoldIapBonus::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIGoldIapBonus::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

