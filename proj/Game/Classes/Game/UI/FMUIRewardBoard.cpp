//
//  FMUIRewardBoard.cpp
//  JellyMania
//
//  Created by ywthahaha on 14-4-23.
//
//

#include "FMUIRewardBoard.h"

#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMGameElement.h"
#include "SNSFunction.h"


FMUIRewardBoard::FMUIRewardBoard():
m_iconSprite(NULL),
m_amountLabel(NULL),
m_titleLabel(NULL),
m_boosterNameLabel(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIRewardBoard.ccbi", this);
    addChild(m_ccbNode);
    m_rwdType = 0;
    m_amount = 0;
    m_rwdFrom = kRewardFromNone;
    m_goldIapIndex = 0;
}

FMUIRewardBoard::~FMUIRewardBoard()
{
    
}



bool FMUIRewardBoard::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_iconSprite", CCSprite *, m_iconSprite);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_amountLabel", CCLabelBMFont *, m_amountLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_titleLabel", CCLabelBMFont *, m_titleLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_boosterNameLabel", CCLabelBMFont *, m_boosterNameLabel);
    return true;
}

SEL_CCControlHandler FMUIRewardBoard::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIRewardBoard::clickButton);
    return NULL;
}

CCString* FMUIRewardBoard::getBoosterNameByType(int type)
{
    CCString* name = NULL;
    FMDataManager* manager = FMDataManager::sharedManager();
    
    switch (type) {
        case kRwdTypeGold:name = CCString::create(manager->getLocalizedString("V100_BOOSTER_101"));break;
        case kHarvest1Type:name = CCString::create(manager->getLocalizedString("V100_BOOSTER_3"));break;
        case kTurnGood:name = CCString::create(manager->getLocalizedString("V100_BOOSTER_5"));break;
        case kAdd5Move:name = CCString::create(manager->getLocalizedString("V100_BOOSTER_6"));break;
        case kTCross:name = CCString::create(manager->getLocalizedString("V100_BOOSTER_7"));break;
        case kUnlimitLifeOneHour:name = CCString::create(manager->getLocalizedString("V100_BOOSTER_103"));break;
        case k5Line:name = CCString::create(manager->getLocalizedString("V100_BOOSTER_9"));break;
        case kShuffle:name = CCString::create(manager->getLocalizedString("V100_BOOSTER_4"));break;
        default:name = CCString::create(""); break;
    }
    
    CCLOG("%s",name->getCString());
    return name;
}


void FMUIRewardBoard::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        clickButton(NULL,0);
    }
}

void FMUIRewardBoard::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    FMDataManager* manager = FMDataManager::sharedManager();
    
    if (m_rwdFrom == kRewardFromStarBonus) {
        if (!manager->updateNextStarRewardIndex()) {
            GAMEUI_Scene::uiSystem()->closeAllWindows();
            return;
        }
    }
    
    GAMEUI_Scene::uiSystem()->prevWindow();
}




void FMUIRewardBoard::onEnter()
{
    GAMEUI_Window::onEnter();
    updateUI();
}

void FMUIRewardBoard::onExit()
{
    GAMEUI_Window::onExit();
}



void FMUIRewardBoard::updateUI()
{
    CCSpriteFrame* frame = FMUIRewardBoard::getIconFrameByType(m_rwdType);
    if (frame) m_iconSprite->setDisplayFrame(frame);
    if (m_rwdType == kUnlimitLifeOneHour)
        m_amountLabel->setString(CCString::createWithFormat("%d小时",m_amount)->getCString());
    else
        m_amountLabel->setString(CCString::createWithFormat("x%d",m_amount)->getCString());
    m_titleLabel->setString(getTitleByType(m_rwdType)->getCString());
    m_boosterNameLabel->setString(getBoosterNameByType(m_rwdType)->getCString());
}

CCSpriteFrame* FMUIRewardBoard::getIconFrameByType(int type)
{
    CCSpriteFrameCache* cache = CCSpriteFrameCache::sharedSpriteFrameCache();
    cache->addSpriteFramesWithFile("Boosters.plist");
    switch (type) {
        case kRwdTypeGold:return cache->spriteFrameByName("ui_gold2.png");
        case kHarvest1Type:return cache->spriteFrameByName("boost4.png");break;
        case kTurnGood:return cache->spriteFrameByName("boost5.png");break;
        case kAdd5Move:return cache->spriteFrameByName("boost6.png");break;
        case kTCross:return cache->spriteFrameByName("boost_t.png");break;
        case kUnlimitLifeOneHour:return cache->spriteFrameByName("heart_enable.png");break;
        case k5Line:return cache->spriteFrameByName("boost_5.png");break;
        case kShuffle:return cache->spriteFrameByName("boost9.png");break;
        default:break;
    }
    
    return NULL;
}

CCString* FMUIRewardBoard::getTitleByType(int type)
{
    FMDataManager* manager = FMDataManager::sharedManager();
    CCString* rwdName = NULL;
    switch (type) {
        case kRwdTypeGold:
        {
            rwdName = CCString::create(manager->getLocalizedString("V100_NOT_ENOUGH_GOLD_2"));
            return CCString::createWithFormat("%s%s",manager->getLocalizedString("V140_CONGRATULATION_GET"),rwdName->getCString());
        }
            
        break;
            
        default:
        {
            return CCString::create(manager->getLocalizedString("V140_GETREWARD"));
        }
            
        break;
    }
    
    return CCString::create("");
}


void FMUIRewardBoard::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIRewardBoard::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionOut(finishAction);
}
void FMUIRewardBoard::transitionInDone()
{
    GAMEUI_Window::transitionInDone();
}
