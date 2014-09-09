//
//  FMStatusbar.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-26.
//
//

#include "FMStatusbar.h"
#include "FMDataManager.h"
#include "FMUIInAppStore.h"
#include "FMUINeedHeart.h"
#include "GAMEUI_Scene.h"
#include "SNSFunction.h"
#include "FMUIFamilyTree.h"
#include "FMUIFreeGolds.h"
#include "FMUIMessage.h"
#include "FMUIFBConnect.h"
#include "FMUISendHeart.h"

FMStatusbar::FMStatusbar() :
    m_panel(NULL),
    m_panelNode(NULL),
//    m_adButtonParent(NULL),
    m_timeLabelParent(NULL),
    m_timeLabel(NULL),
    m_lifeLabel(NULL),
    m_goldLabel(NULL),
    m_unlimitTimeLabel(NULL),
    m_isShown(false),
    m_freeGemsBtn(NULL),
    m_rateBtn(NULL),
    m_hasNewQuest(false),
    m_unreadMsgLabel(NULL),
    m_msgButton(NULL),
    m_coinNode(NULL),
    m_lifeNode(NULL)
{
    m_mesgSourceType = 0;
    
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIStatus.ccbi", this);
    addChild(m_ccbNode);
    
    setVisible(false);
    
//    m_adButton = (CCControlButton *)m_adButtonParent->getChildByTag(1);
//    bool visible = SNSFunction_isAdVisible();
//    m_adButtonParent->setVisible(visible);
//    m_adButton->setVisible(visible);
    
    CCSprite * tbg = CCSprite::createWithSpriteFrameName("UnreadMessage.png");
    tbg->setAnchorPoint(ccp(0.5, 1));
    tbg->setPosition(ccp(m_msgButton->getContentSize().width-5.f, m_msgButton->getContentSize().height-13.f));
    m_msgButton->addChild(tbg);

    m_unreadMsgLabel = CCLabelBMFont::create("", "font_7.fnt", 50, kCCTextAlignmentCenter);
    tbg->addChild(m_unreadMsgLabel);
    m_unreadMsgLabel->setPosition(ccp(tbg->getContentSize().width/2 - 1.f, tbg->getContentSize().height/2));
    
    m_timeLabel->setAlignment(kCCTextAlignmentCenter);
}

FMStatusbar::~FMStatusbar()
{
    
}

#pragma mark - CCB Bindings
bool FMStatusbar::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_panelNode", CCNode *, m_panelNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_panel", CCSprite *, m_panel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_timeLabel", CCLabelBMFont *, m_timeLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_lifeLabel", CCLabelBMFont *, m_lifeLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_goldLabel", CCLabelBMFont *, m_goldLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_unlimitTimeLabel", CCLabelBMFont *, m_unlimitTimeLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_timeLabelParent", CCNode *, m_timeLabelParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_freeGemsBtn", CCControlButton *, m_freeGemsBtn);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_rateBtn", CCControlButton *, m_rateBtn);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_msgButton", CCAnimButton *, m_msgButton);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_coinNode", CCNode*, m_coinNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_lifeNode", CCNode*, m_lifeNode);
    
//    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_adButtonParent", CCNode *, m_adButtonParent);
    return true;
}

SEL_CCControlHandler FMStatusbar::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickIAP", FMStatusbar::clickIAP);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickBook", FMStatusbar::clickBook);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickAdvert", FMStatusbar::clickAdvert);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickFreeGems", FMStatusbar::clickFreeGems);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickRate", FMStatusbar::clickRate);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickMsg", FMStatusbar::clickMsg);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickHeart", FMStatusbar::clickHeart);
    return NULL;
}
void FMStatusbar::clickMsg(cocos2d::CCObject *object)
{
#ifndef SNS_ENABLE_MINICLIP
    if(m_mesgSourceType==1) {
        SNSFunction_showNoticePopup();
        return;
    }
#endif
    if (SNSFunction_isFacebookConnected()) {
        FMUIMessage * window = (FMUIMessage *)FMDataManager::sharedManager()->getUI(kUI_Message);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
    }else{
        FMUIFBConnect * window = (FMUIFBConnect *)FMDataManager::sharedManager()->getUI(kUI_FBConnect);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
    }
}

void FMStatusbar::clickHeart(CCObject * object)
{
    if (SNSFunction_isFacebookConnected()) {
        FMUISendHeart * window = (FMUISendHeart *)FMDataManager::sharedManager()->getUI(kUI_SendHeart);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
    }else{
        FMUIFBConnect * window = (FMUIFBConnect *)FMDataManager::sharedManager()->getUI(kUI_FBConnect);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
    }
}

void FMStatusbar::clickAdvert(cocos2d::CCObject *object, CCControlEvent event)
{
    if (!isVisible()) {
        return;
    }
    // SNSFunction_showAdOffer("flurry");
    SNSFunction_showPopupAd();
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
//    m_adButtonParent->setPosition(ccp(5, -20));
//    CCMoveTo * m = CCMoveTo::create(0.15f, ccp(5, -26));
//    CCMoveTo * m2 = CCMoveTo::create(0.15f, ccp(5, -20));
//    CCSequence * seq = CCSequence::create(m, m2, NULL);
//    m_adButtonParent->runAction(seq);
}

void FMStatusbar::clickIAP(cocos2d::CCObject *object, CCControlEvent event)
{
    if (!isVisible()) {
        return;
    }

    CCControlButton * button = (CCControlButton *)object;
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    
    FMDataManager * manager = FMDataManager::sharedManager();
    switch (button->getTag()) {
        case 0:
        {
            //life
            bool full = manager->isLifeFull();
            //temp fix for iap issue
            bool upgraded = manager->isLifeUpgraded();
            if ((full && upgraded) || manager->getUnlimitLifeTime() > manager->getCurrentTime()) {
                //do nothing
            }
            else {
                FMUINeedHeart * window = (FMUINeedHeart *) manager->getUI(kUI_NeedHeart);
                GAMEUI_Scene::uiSystem()->nextWindow(window);
            }
        }
            break;
        case 2:
        {
            //gold
            FMUIInAppStore * window = (FMUIInAppStore *)manager->getUI(kUI_IAPGold);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
            break;
        default:
            break;
    } 
    
}

void FMStatusbar::show(bool isShown, bool transition)
{ 
    bool visible = !FMDataManager::sharedManager()->isInGame() && SNSFunction_isAdVisible();
//    m_adButtonParent->setVisible(visible);
//    m_adButton->setVisible(visible);
    
    if (m_isShown == isShown) {
        //do nothing
        return;
    }
    m_isShown = isShown;
    
    m_panelNode->stopAllActions();
    if (m_isShown) {
        setVisible(true);
        m_panelNode->setPosition(ccp(0, 100));
        CCMoveTo * m = CCMoveTo::create(0.3f, CCPointZero);
        CCEaseOut * ease = CCEaseOut::create(m, 2.f);
        m_panelNode->runAction(ease);
    }
    else {
        setVisible(transition);
        m_panelNode->setPosition(ccp(0, 0));
        CCMoveTo * m = CCMoveTo::create(0.3f, ccp(0, 100));
        CCEaseOut * ease = CCEaseOut::create(m, 2.f);
        m_panelNode->runAction(ease);
    }
}

void FMStatusbar::clickBook(CCObject * object , CCControlEvent event)
{
//    FMUIFamilyTree * window = (FMUIFamilyTree* )FMDataManager::sharedManager()->getUI(kUI_FamilyTree);
//    GAMEUI_Scene::uiSystem()->nextWindow(window);
}

void FMStatusbar::clickFreeGems(CCObject * object , CCControlEvent event)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    SNSFunction_showFreeGemsOffer();
#else
    if (!isVisible()) {
        return;
    }

    FMUIFreeGolds * window = (FMUIFreeGolds *)FMDataManager::sharedManager()->getUI(kUI_FreeGolds);
    GAMEUI_Scene::uiSystem()->nextWindow(window);
#endif
}

void FMStatusbar::clickRate(CCObject * object , CCControlEvent event)
{
    if (!isVisible()) {
        return;
    }

    SNSFunction_toRateIt();
    SNSFunction_setLastRateTime();
    resetRateBtn(true);
}

bool FMStatusbar::ccTouchBegan(cocos2d::CCTouch *pTouch, cocos2d::CCEvent *pEvent)
{
//    if (!isVisible()) {
//        return false;
//    }
//    CCSprite * bg = (CCSprite *)m_parentNode->getParent();
//    CCSize size = bg->getContentSize();
//    CCPoint p = pTouch->getLocation();
//    p = bg->convertToNodeSpace(p);
//    if (p.x >=0.f && p.y >= 0.f && p.x <= size.width && p.y <= size.height) {
//        return true;
//    }
//    return false;
    return false;
}

void FMStatusbar::updateUI()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    m_unlimitLifeTime = manager->getUnlimitLifeTime();
    m_nextEnergyTime = manager->getNextLifeTime();
    m_maxEnergy = manager->getMaxLife();
    m_energy = manager->getLifeNum();
//    if (m_energy > m_maxEnergy) {
//        m_energy = m_maxEnergy;
//        manager->setLifeNum(m_energy);
//    }
    if (m_energy < 0) {
        m_energy = 0;
        manager->setLifeNum(m_energy);
    }
    
    if (m_energy >= m_maxEnergy) {
        m_nextEnergyTime = -1;
        manager->setNextLifeTime(m_nextEnergyTime);
    }
    
    if (m_nextEnergyTime != -1) {
        addEnergy();
        m_nextEnergyTime = manager->getNextLifeTime();
        m_maxEnergy = manager->getMaxLife();
        m_energy = manager->getLifeNum();
    }
    else {
//        m_energy = m_maxEnergy;
//        manager->setLifeNum(m_energy);
    }
    
    
    CCLabelBMFont * lifeLabel = m_lifeLabel;
    CCString * cstr = CCString::createWithFormat("%d", m_energy);
    lifeLabel->setString(cstr->getCString());
    
    CCLabelBMFont * timeLabel = m_timeLabel;
    if (m_nextEnergyTime == -1) {
        m_timeLabelParent->setVisible(false);
    }
    else {
        if (m_unlimitLifeTime == -1) {
            m_timeLabelParent->setVisible(true);
        }
        int remain = manager->getRemainTime(m_nextEnergyTime);
        const char * s = manager->getTimeString(remain)->getCString();
        CCString * str = CCString::createWithFormat(manager->getLocalizedString("V100_+1_IN"),s);
        timeLabel->setString(str->getCString());
    }
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
    CCLabelBMFont * goldLabel = m_goldLabel;
    int gold = manager->getGoldNum();
    goldLabel->setString(manager->getDollarString(gold).c_str());
#else
    CCLabelBMFont * goldLabel = m_goldLabel;
    int gold = manager->getGoldNum();
    std::stringstream ss2;
    ss2 << gold;
    goldLabel->setString(ss2.str().c_str());
#endif
}

void FMStatusbar::onEnter()
{
    GAMEUI::onEnter();
    updateUI();
    scheduleUpdate();
    FMDataManager* manager = FMDataManager::sharedManager();
#ifdef BRANCH_CN
    m_freeGemsBtn->setVisible(SNSFunction_isAdVisible());
    m_freeGemsBtn->setEnabled(SNSFunction_isAdVisible());
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
    const char *language  = OBJCHelper::helper()->getLanguageCode();
    if( 0 == strcmp(language, "zh-Hans") )
    {
        CCSpriteFrame * spriteFrame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("loc_x52.png");
        m_freeGemsBtn->setBackgroundSpriteFrameForState(spriteFrame, CCControlStateNormal);
        m_freeGemsBtn->setBackgroundSpriteFrameForState(spriteFrame, CCControlStateHighlighted);
    }
#endif
#endif
    makeReadOnly(manager->isInGame());
    
//    resetBookBtn();
}

void FMStatusbar::resetRateBtn(bool hidden)
{
#ifndef BRANCH_CN
    m_rateBtn->setVisible(false); return;
#endif
    int lastTime = SNSFunction_getLastRateTime();
    int currentTime = SNSFunction_getCurrentTime();
    int hour = (currentTime - lastTime)/3600;

    bool visible = !hidden && hour > 23 && !FMDataManager::sharedManager()->isInGame();
    m_rateBtn->setVisible(visible);
}

void FMStatusbar::resetBookBtn()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    bool haveNew = manager->haveNewBranchLevel();
    CCAnimButton* bookBtn = (CCAnimButton*)m_panelNode->getChildByTag(2);
    if (!bookBtn) {
        return;
    }
    NEAnimNode* bn = bookBtn->getAnimNode();
    bn->releaseControl("New", kProperty_Visible);
    NEAnimNode* n = (NEAnimNode*)bn->getNodeByName("New");
    if (manager->haveNewJelly()) {
        n->setVisible(true);
    }else{
        n->setVisible(false);
    }
    
    int wi = manager->getWorldIndex();
    int li = manager->getLevelIndex();
    bool q = manager->isQuest();
    bool b = manager->isBranch();
    manager->setLevel(0, 0, true);
    bool beaten = manager->isWorldBeaten(true);
    bool visible = beaten && !manager->isInGame();
    bookBtn->setVisible(visible);
    bookBtn->setEnabled(visible);
    manager->setLevel(wi, li, q, b);
    
    if (haveNew && beaten) {
        m_hasNewQuest = true;
    }
}

void FMStatusbar::onExit()
{
    GAMEUI::onExit();
    unscheduleUpdate();
}

void FMStatusbar::update(float delta)
{
    FMDataManager * manager = FMDataManager::sharedManager();
    
    bool purchaseUnlimit = manager->hasPurchasedUnlimitLife();
    if (purchaseUnlimit) {
        m_lifeLabel->setVisible(false);
        m_timeLabel->setVisible(false);
        CCNode * lifenode = m_panelNode->getChildByTag(0);
        CCBAnimationManager * lifeAnim = (CCBAnimationManager *)lifenode->getUserObject();
        lifeAnim->runAnimationsForSequenceNamed("unlimit");
        lifenode->setPosition(ccp(-90, -16));
        m_unlimitTimeLabel->setVisible(false);
        m_coinNode->setPosition(ccp(-100, -18));
        m_lifeNode->setPosition(ccp(9999, 9999));
        return;
    }
    
    if (m_unlimitLifeTime != -1) {
        m_unlimitLifeTime = manager->getUnlimitLifeTime();
        int remaintime = m_unlimitLifeTime - manager->getCurrentTime();
        // 解决等待时间太长的问题
//        if(remaintime>18000) remaintime = 0;
        if (remaintime <= 0) {
            manager->setUnlimitLifeTime(-1);
            CCNode * lifenode = m_panelNode->getChildByTag(0);
            CCBAnimationManager * lifeAnim = (CCBAnimationManager *)lifenode->getUserObject();
            if (manager->isInGame()) {
                lifeAnim->runAnimationsForSequenceNamed("Off");
            }else{
                lifeAnim->runAnimationsForSequenceNamed("On");
            }
            lifenode->setPosition(ccp(-113, -16));
            updateUI();
            
        }else{
            const char * s = manager->getTimeString(remaintime, false)->getCString();
            m_unlimitTimeLabel->setString(s);
        }
    }else{
        m_unlimitLifeTime = manager->getUnlimitLifeTime();
        if (m_unlimitLifeTime != -1) {
            CCNode * lifenode = m_panelNode->getChildByTag(0);
            CCBAnimationManager * lifeAnim = (CCBAnimationManager *)lifenode->getUserObject();
            lifeAnim->runAnimationsForSequenceNamed("unlimit");
            lifenode->setPosition(ccp(-90, -16));
            updateUI();
        }
    }
    if (m_nextEnergyTime != -1) {
        addEnergy();
        
        CCLabelBMFont * timeLabel = m_timeLabel;
        if (m_nextEnergyTime == -1) {
            m_timeLabelParent->setVisible(false); 
        }
        else {
            if (m_unlimitLifeTime == -1) {
                m_timeLabelParent->setVisible(true);
            }
            int remain = manager->getRemainTime(m_nextEnergyTime);
            const char * s = manager->getTimeString(remain, true)->getCString();
            CCString * str = CCString::createWithFormat(manager->getLocalizedString("V100_+1_IN"),s);
            timeLabel->setString(str->getCString());
        }
    }else{
        m_timeLabelParent->setVisible(false);
    }

    int t = OBJCHelper::helper()->getAllFBMessage()->count();
    m_mesgSourceType = 0;
#ifndef SNS_ENABLE_MINICLIP
    if(t == 0) {
        // check topgame source type
        t = SNSFunction_getNewNoticeCount();
        if(t>0) m_mesgSourceType = 1;
    }
#endif
    if (t == 0) {
        m_unreadMsgLabel->getParent()->setVisible(false);
        m_unreadMsgLabel->setString("0");
    }else{
        m_unreadMsgLabel->getParent()->setVisible(true);
        m_unreadMsgLabel->setString(CCString::createWithFormat("%d",t)->getCString());
    }
}

void FMStatusbar::addEnergy()
{
    
    FMDataManager* manager = FMDataManager::sharedManager();
    int remain = manager->getRemainTime(m_nextEnergyTime);
    
    int maxLife = manager->getMaxLife();
    // 解决等待时间太长的问题
    if(remain>kRecoverTime*maxLife) remain = 0;
    if (remain == 0) {
        //try add energy
        int currenttime = manager->getCurrentTime();
        int off = currenttime - m_nextEnergyTime;
        
        if(off<0) off = kRecoverTime * maxLife;
        
        int add = 0;
        int left = 0;
        while (off >= 0) {
            off -= kRecoverTime;
            add++;
        }
        left = abs(off);
    
        int life = manager->getLifeNum();
        
        if (life < maxLife) {
            if (add > 0) {
                life += add;
                if (life >= maxLife) {
                    life = maxLife;
                    manager->setNextLifeTime(-1);
                }
                else {
                    int nextTime = left + currenttime;
                    manager->setNextLifeTime(nextTime);
                }
                manager->setLifeNum(life);
                updateUI();
            }
        }
        else {
            //life max, stop timer
            manager->setNextLifeTime(-1);
            updateUI();
        }
    }
}

void FMStatusbar::makeReadOnly(bool readonly)
{
    CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
#ifdef BRANCH_CN
    if (readonly) {
        anim->runAnimationsForSequenceNamed("OffCN");
    }
    else {
        anim->runAnimationsForSequenceNamed("OnCN");
    }
#else
    if (readonly) {
        anim->runAnimationsForSequenceNamed("Off");
    }
    else {
        anim->runAnimationsForSequenceNamed("On");
    }
#endif
    FMDataManager * manager = FMDataManager::sharedManager();
    CCNode * lifenode = m_panelNode->getChildByTag(0);
    CCBAnimationManager * lifeAnim = (CCBAnimationManager *)lifenode->getUserObject();
    if (manager->getUnlimitLifeTime() > manager->getCurrentTime()) {
        lifeAnim->runAnimationsForSequenceNamed("unlimit");
        lifenode->setPosition(ccp(-90, -16));
    }
    else if (readonly){
        lifeAnim->runAnimationsForSequenceNamed("Off");
        lifenode->setPosition(ccp(-113, -16));
    }
    else{
        lifeAnim->runAnimationsForSequenceNamed("On");
        lifenode->setPosition(ccp(-113, -16));
    }
    
    resetRateBtn(readonly);
}

CCPoint FMStatusbar::getTutorialPosition(int index)
{
    CCNode * node = m_panelNode->getChildByTag(index);
    CCPoint p = node->getPosition();
    CCSize s = CCDirector::sharedDirector()->getWinSize();
    p.x += s.width * 0.5f;
    p.y += s.height;
    return p;
}
