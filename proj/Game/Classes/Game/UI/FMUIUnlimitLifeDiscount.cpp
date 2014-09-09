//
//  FMUIUnlimitLifeDiscount.cpp
//  JellyMania
//
//  Created by ywthahaha on 14-4-21.
//
//

#include "FMUIUnlimitLifeDiscount.h"

#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "OBJCHelper.h"
#include "FMUIInAppStore.h"
#include "FMEnergyManager.h"
#include "FMUIBooster.h"


FMUIUnlimitLifeDiscount::FMUIUnlimitLifeDiscount() :
m_parentNode(NULL),
m_titleLabel(NULL),
m_iconSpt(NULL),
m_timeLabel(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIUnlimitLifeDiscount.ccbi", this);
    addChild(m_ccbNode);
    m_freeUpgrade = false;
}

FMUIUnlimitLifeDiscount::~FMUIUnlimitLifeDiscount()
{
}

#pragma mark - CCB Bindings
bool FMUIUnlimitLifeDiscount::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{

    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_titleLabel", CCLabelBMFont *, m_titleLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_iconSpt", CCSprite *, m_iconSpt);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_timeLabel", CCLabelBMFont *, m_timeLabel);
    return true;
}

SEL_CCControlHandler FMUIUnlimitLifeDiscount::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIUnlimitLifeDiscount::clickButton);
    return NULL;
}

void FMUIUnlimitLifeDiscount::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        //close
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIUnlimitLifeDiscount::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMDataManager * manager = FMDataManager::sharedManager();
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
            //free upgrade
            if (manager->getMaxLife() != 8) return;
            manager->getUserSave()->setObject(CCNumber::create(1), kPurchaseUnlimitLife);
            manager->saveGame();
            m_instantMove = true;
            GAMEUI_Scene::uiSystem()->closeAllWindows();
            
        }
            break;
            
        case 3:
        {
            int price = 600;
            bool isDiscount = manager->whetherUnsealUnlimitLifeDiscount();
            isDiscount ? price = 300 : 1;
            
            //折扣购买
            if (manager->useMoney(price, "Unlimit Life")) {
                manager->getUserSave()->setObject(CCNumber::create(1), kPurchaseUnlimitLife);
                manager->saveGame();
                m_instantMove = true;
                GAMEUI_Scene::uiSystem()->closeAllWindows();
            }

        }
            break;

        default:
            break;
    }
}



void FMUIUnlimitLifeDiscount::onExit()
{
    GAMEUI_Window::onExit();
}

void FMUIUnlimitLifeDiscount::onEnter()
{
    GAMEUI_Window::onEnter();
    FMDataManager* manager = FMDataManager::sharedManager();
    CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
    if (m_freeUpgrade) {
        anim->runAnimationsForSequenceNamed("FreeUpgrade");
        m_titleLabel->setString(manager->getLocalizedString("V140_THANKS_FOR_UNLIMITLIFE"));
        m_iconSpt->setDisplayFrame(CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("unlimitLife_upgrade_icon.png"));
        
        
    }else {
        anim->runAnimationsForSequenceNamed("PayUpgrade");
        m_titleLabel->setString(manager->getLocalizedString("V140_UNLIMIT_LIFE_DISCOUNT"));
        m_iconSpt->setDisplayFrame(CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("unlimit_heart.png"));
        
        updateTimeLabel();
    }
    
    unscheduleAllSelectors();
    schedule(schedule_selector(FMUIUnlimitLifeDiscount::updateTimeLabel), 0.5f);
}

void FMUIUnlimitLifeDiscount::updateTimeLabel()
{
    FMDataManager* manager = FMDataManager::sharedManager();
    const char* partStr = manager->getLocalizedString("V140_BONUS_END");
    const char* timeStr = manager->getUnlimitLifeDiscountRestTimeStr()->getCString();
    CCString* lastStr = CCString::createWithFormat("%s%s",partStr,timeStr);
    m_timeLabel->setString(lastStr->getCString());
    m_timeLabel->setVisible( !(strcmp(timeStr, "")==0) );
}



void FMUIUnlimitLifeDiscount::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIUnlimitLifeDiscount::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

