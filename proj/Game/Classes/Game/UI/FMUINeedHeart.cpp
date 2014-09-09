//
//  FMUINeedHeart.cpp
//  FarmMania
//
//  Created by  James Lee on 13-6-6.
//
//

#include "FMUINeedHeart.h"


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
#include "FMUIFBConnect.h"

static int refillPrice = 0;

//static iapItemGroup lifeGroup = {5, "", "29.99", 57500, 15, true, "com.naughtycat.jellymania.upgradelife30", "$", "USD"};
#ifdef BRANCH_CN
static int upgradePrice = 600;
#else
static int upgradePrice = 300;
#endif

FMUINeedHeart::FMUINeedHeart() :
    m_upgradePriceLabel(NULL),
    m_refillPriceLabel(NULL),
    m_timeLabel(NULL),
    m_lifeLabel(NULL),
    m_parentNode(NULL),
    m_discountNode(NULL)
{
#ifdef BRANCH_CN
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUINeedHeart.ccbi", this);
#else
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUINeedHeartEN.ccbi", this);
#endif
    addChild(m_ccbNode);
    
}

FMUINeedHeart::~FMUINeedHeart()
{ 
}

#pragma mark - CCB Bindings
bool FMUINeedHeart::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_upgradePriceLabel", CCLabelBMFont *, m_upgradePriceLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_refillPriceLabel", CCLabelBMFont *, m_refillPriceLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_timeLabel", CCLabelBMFont *, m_timeLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_lifeLabel", CCLabelBMFont *, m_lifeLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_discountNode", CCNode *, m_discountNode);
    
    return true;
}

SEL_CCControlHandler FMUINeedHeart::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUINeedHeart::clickButton);
    return NULL;
}

void FMUINeedHeart::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUINeedHeart::clickButton(cocos2d::CCObject *object, CCControlEvent event)
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
            FMDataManager * manager = FMDataManager::sharedManager();
            
#ifdef BRANCH_CN
            int price = upgradePrice;
            bool isDiscount = manager->whetherUnsealUnlimitLifeDiscount();
            isDiscount ? price = 300 : 1;
            
            if (manager->useMoney(price, "Unlimit Life")) {
                manager->getUserSave()->setObject(CCNumber::create(1), kPurchaseUnlimitLife);
                manager->saveGame();
                m_instantMove = true;
                GAMEUI_Scene::uiSystem()->closeAllWindows();
            }
            
            return;
#endif
            //upgrade
            if (manager->useMoney(upgradePrice, "Expand Life")) {
                manager->upgradeLife();
                int max = manager->getMaxLife();
                manager->setLifeNum(max);
                manager->updateStatusBar();
                m_instantMove = true;
                GAMEUI_Scene::uiSystem()->prevWindow();
                manager->saveGame();
            }
            //            OBJCHelper::helper()->buyIAPItem(lifeGroup.ID, 1, this, callfuncO_selector(FMUINeedHeart::buyIAPCallback));
        }
            break;
        case 2:
        {
            //refill
            int price = refillPrice;
            m_instantMove = false;
            FMDataManager * manager = FMDataManager::sharedManager();
            if (manager->useMoney(price, "Refill Life")) {
                int max = manager->getMaxLife();
                manager->setLifeNum(max);
                manager->updateStatusBar();
                m_instantMove = true;
                GAMEUI_Scene::uiSystem()->prevWindow();
            }
        }
            break;
        case 3:
        {
            if (SNSFunction_isFacebookConnected()) {
                OBJCHelper::helper()->askLifeFromFriend();
            }else{
                FMUIFBConnect * window = (FMUIFBConnect *)FMDataManager::sharedManager()->getUI(kUI_FBConnect);
                GAMEUI_Scene::uiSystem()->nextWindow(window);
            }
        }
            break;
        default:
            break;
    }
}

void FMUINeedHeart::buyIAPCallback(cocos2d::CCObject *object)
{
    CCNumber * num = (CCNumber *)object;
    bool succeed = num->getIntValue() == 1;
    if (succeed) {
        FMDataManager * manager = FMDataManager::sharedManager();
        manager->upgradeLife();
        int max = manager->getMaxLife();
        manager->setLifeNum(max);
        manager->updateStatusBar();
        m_instantMove = true;
        GAMEUI_Scene::uiSystem()->prevWindow();
        manager->saveGame();
    }
    CCLOG("iap buy : %d" , succeed);
}

void FMUINeedHeart::onExit()
{
    unscheduleUpdate();
    GAMEUI_Window::onExit();
}

void FMUINeedHeart::onEnter()
{
    GAMEUI_Window::onEnter();
    scheduleUpdate();
    
    FMDataManager * manager = FMDataManager::sharedManager();
    bool boughtUpgrade = manager->isLifeUpgraded();
    bool isFull = manager->isLifeFull();
    CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
    if (boughtUpgrade) {
        anim->runAnimationsForSequenceNamed("Refill");
#ifdef BRANCH_TH
        m_refillPriceLabel->setPosition(ccp(26.5, -182));
#endif
    }
    else if (isFull) {
        
#ifdef BRANCH_TH
    anim->runAnimationsForSequenceNamed("UpgradeTH");
#else
    anim->runAnimationsForSequenceNamed("Upgrade");
#endif
    }
    else {
        
#ifdef BRANCH_TH
    anim->runAnimationsForSequenceNamed("RefillUpgradeTH");
#else
    anim->runAnimationsForSequenceNamed("RefillUpgrade");
#endif
    
    }

//    OBJCHelper::helper()->updateIAPGroup(&lifeGroup);
    
#ifdef BRANCH_CN
    if (manager->whetherUnsealUnlimitLifeDiscount()) {
        upgradePrice = 300;
        ccColor3B c3 = {33,153,0};
        m_upgradePriceLabel->setColor(c3);
        m_discountNode->setVisible(true);
        
    }else{
        upgradePrice = 600;
        ccColor3B c3 = {127,87,35};
        m_upgradePriceLabel->setColor(c3);
        m_discountNode->setVisible(false);
    }
#endif
    
    CCString * cstr = CCString::createWithFormat(manager->getLocalizedString("V100_BUY_FOR_(D)"), upgradePrice);
    m_upgradePriceLabel->setString(cstr->getCString());
    
    cstr = CCString::createWithFormat(manager->getLocalizedString("V140_REFILL_LIFE_(D)"), refillPrice);
    m_refillPriceLabel->setString(cstr->getCString());

}

void FMUINeedHeart::update(float time)
{
    updateUI();
}

 
void FMUINeedHeart::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUINeedHeart::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUINeedHeart::updateUI()
{
    FMEnergyManager * em = FMEnergyManager::manager();
    FMDataManager * manager = FMDataManager::sharedManager();
    int lifeNum = em->getCurrentLifeNum();
    CCString * str = NULL;
#ifdef BRANCH_CN
    if (lifeNum != 1) {
        const char * lifeStr = manager->getLocalizedString("V100_YOU_HAVE_X_LIVES");
//        lifeStr = "you have %d lives";
        str = CCString::createWithFormat(lifeStr, lifeNum);
    }
    else {
        const char * lifeStr = manager->getLocalizedString("V100_YOU_HAVE_1_LIFE");
//        lifeStr = "you have 1 life";
        str = CCString::createWithFormat(lifeStr);
    }
    m_lifeLabel->setString(str->getCString());
#endif

    int time = em->getRemainTime();
    if (time != -1) {
        const char * timeStr = manager->getLocalizedString("V100_+1_IN_(S)");
        CCString * t = manager->getTimeString(time, true);
        str = CCString::createWithFormat(timeStr, t->getCString());
        m_timeLabel->setString(str->getCString());
        m_timeLabel->setVisible(true);
    }
    else {
        m_timeLabel->setVisible(false); 
    }
    
}
