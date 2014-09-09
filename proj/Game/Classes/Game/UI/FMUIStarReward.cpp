//
//  FMUIStarReward.cpp
//  JellyMania
//
//  Created by ywthahaha on 14-4-17.
//
//

#include "FMUIStarReward.h"

#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMGameElement.h"
#include "SNSFunction.h"
#include "FMUIRewardBoard.h"

FMUIStarReward::FMUIStarReward():
m_iconSprite(NULL),
m_amountLabel(NULL),
m_infoLabel(NULL)
{
    m_boosterType = 0;
    m_boosterCount = -1;
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIStarReward.ccbi", this);
    addChild(m_ccbNode);
}

FMUIStarReward::~FMUIStarReward()
{
    
}



bool FMUIStarReward::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_iconSprite", CCSprite *, m_iconSprite);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_amountLabel", CCLabelBMFont *, m_amountLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_infoLabel", CCLabelBMFont * , m_infoLabel);
    return true;
}

SEL_CCControlHandler FMUIStarReward::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIStarReward::clickButton);
    return NULL;
}

void FMUIStarReward::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    CCControlButton * button = (CCControlButton *)object;
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    FMDataManager* manager = FMDataManager::sharedManager();
    
    switch (button->getTag()) {
        case 0:
        {
            GAMEUI_Scene::uiSystem()->closeAllWindows();
            return;
        }
            break;
        case 1:
        {
            if (!manager->whetherCanGetStarReward()) {
                return;
            }
            
            int idx = manager->getNextStarRewardIndex();
            int maxIdx = sizeof(s_starReward) / (sizeof(int)*3) -1;
            if (idx > maxIdx) return;
            
            //int boosterType = s_starReward[idx][1];
            //int boosterCount = s_starReward[idx][2];
            
            if (m_boosterType == kUnlimitLifeOneHour) {
                //增加无限时间
                int currentTime = SNSFunction_getCurrentTime();
                manager->setUnlimitLifeTime(MAX(currentTime, manager->getUnlimitLifeTime()) + 3600*m_boosterCount);
                
            }else if(m_boosterType == kRwdTypeGold){
                //加金币
                int num = manager->getGoldNum();
                num += m_boosterCount;
                manager->setGoldNum(num);
            }else{
                int haveAmount = manager->getBoosterAmount(m_boosterType);
                haveAmount == -1 ? haveAmount = 0 : 0;
                manager->setBoosterAmount(m_boosterType, haveAmount+m_boosterCount);
                manager->stopBoosterTimer(m_boosterType);
            }
            
            FMUIRewardBoard * window = (FMUIRewardBoard *)manager->getUI(kUI_RewardBoard);
            window->setRewardType(m_boosterType);
            window->setAmount(m_boosterCount);
            window->setRewardFrom(kRewardFromStarBonus);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
            break;
            
        default:
            break;
    }
    
    bool hasNewReward = manager->whetherCanGetStarReward();
    if (hasNewReward) {
        updateUI(manager->getNextStarRewardIndex());
    }else{
        //close
        GAMEUI_Scene::uiSystem()->closeAllWindows();
    }

}

void FMUIStarReward::continueShowReward()
{
    FMDataManager::sharedManager()->showStarReward();
}

void FMUIStarReward::setClassState(int state)
{
    GAMEUI::setClassState(state);
}

void FMUIStarReward::onEnter()
{
    GAMEUI_Window::onEnter();
    updateUI(FMDataManager::sharedManager()->getNextStarRewardIndex());
 
}

void FMUIStarReward::onExit()
{
    GAMEUI_Window::onExit();
}



void FMUIStarReward::updateUI(int index)
{
    FMDataManager* manager = FMDataManager::sharedManager();
    int boosterType = s_starReward[index][1];
    int boosterCount = s_starReward[index][2];
    
    //是否购买了无限体力
    bool hasPurchased = manager->hasPurchasedUnlimitLife();
    if (hasPurchased && boosterType == kUnlimitLifeOneHour) {
        switch (boosterCount) {
            case 1:boosterType = kHarvest1Type;break;
            case 3:boosterType = k5Line;break;
            case 6:
            {
                boosterCount = 3;
                boosterType = kShuffle;
            }
                break;
            case 12:
            {
                boosterCount = 5;
                boosterType = kTCross;
            }
                break;
            case 24:
            {
                boosterCount = 5;
                boosterType = k5Line;
            }
                break;
                
            default:
                break;
        }

    }
    
    m_boosterCount = boosterCount;
    m_boosterType = boosterType;
    
    CCSpriteFrame* frame = FMUIRewardBoard::getIconFrameByType(boosterType);
    if (frame) m_iconSprite->setDisplayFrame(frame);
    char amountStr[32] = {0};
    if (boosterType == kUnlimitLifeOneHour)
        sprintf(amountStr, "%d小时",boosterCount);
    else
        sprintf(amountStr, "x%d",boosterCount);
    m_amountLabel->setString(amountStr);
    
    int curStar = manager->getAllStarsFromSave();
    int nextRwdIdx = manager->getNextStarRewardIndex();
    int nextStar = s_starReward[nextRwdIdx][0];
    int needStar = nextStar - curStar;
    CCAnimButton* getBtn = (CCAnimButton*)m_iconSprite->getParent()->getChildByTag(1);
    if (needStar > 0)
        getBtn->useSkin("GrayGetReward");
    else
        getBtn->useSkin("GetReward");
    
    CCString* needStr = CCString::createWithFormat(manager->getLocalizedString("V140_GETSTAR_CANEARN"),nextStar);
    m_infoLabel->setString(needStr->getCString());

}



void FMUIStarReward::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIStarReward::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionOut(finishAction);
}
void FMUIStarReward::transitionInDone()
{
    GAMEUI_Window::transitionInDone();
}