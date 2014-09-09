//
//  FMUIInAppStore.cpp
//  FarmMania
//
//  Created by  James Lee on 13-6-5.
//
//

#include "FMUIInAppStore.h"

#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMGameNode.h"
#include "FMMainScene.h"
#include "FMStatusbar.h"
#include "NEAnimNode.h"
#include "OBJCHelper.h"
#include "SNSFunction.h"
#include "CCBAnimationManager.h"
#include "FMUIFreeGolds.h"

#if CC_TARGET_PLATFORM==CC_PLATFORM_ANDROID
#include "SNSGameHelper.h"
#endif

using namespace neanim;

static iapItemGroup goldGroup[5] = {
    {4, "ui_gold1.png", "0.99", 10, 0, false, "com.naughtycat.jellymania.gold1", "$", "USD"},
    {3, "ui_gold2.png", "4.99", 52, 5, false, "com.naughtycat.jellymania.gold5", "$", "USD"},
    {2, "ui_gold3.png", "9.99", 110, 10, false, "com.naughtycat.jellymania.gold10", "$", "USD"},
    {1, "ui_gold4.png", "49.99", 560, 12, false, "com.naughtycat.jellymania.gold50", "$", "USD"},
    {0, "ui_gold5.png", "99.99", 1150, 15, true, "com.naughtycat.jellymania.gold100", "$", "USD"},
};

FMUIInAppStore::FMUIInAppStore() :
    m_parentNode(NULL),
    m_closeButton(NULL),
    m_moreButtonParent(NULL),
    m_titleLabel(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIIAP.ccbi", this);
    addChild(m_ccbNode);
    
    CCSize winSize = CCSize(250, 370);
    CCSize cullingSize = CCSize(500, 370);
    GUIScrollSlider * slider = new GUIScrollSlider(winSize, CCRect(-cullingSize.width * 0.5f, -cullingSize.height * 0.5f, cullingSize.width, cullingSize.height), 72.f, this, true);
    slider->setPosition(ccp(0.f, -25.f));
    m_slider = slider;
    m_parentNode->addChild(slider, 0);
    
}

FMUIInAppStore::~FMUIInAppStore()
{ 
}

#pragma mark - CCB Bindings
bool FMUIInAppStore::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_closeButton", CCAnimButton *, m_closeButton);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_titleLabel", CCLabelBMFont *, m_titleLabel);
//    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_moreButtonParent", CCNode *, m_moreButtonParent);
    return true;
}

SEL_CCControlHandler FMUIInAppStore::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIInAppStore::clickButton);
    return NULL;
}

void FMUIInAppStore::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        //close
        FMSound::playEffect("click.mp3", 0.1f, 0.1f);
        GAMEUI_Scene::uiSystem()->prevWindow();
        FMDataManager::sharedManager()->setIsGoldFromIap(false);
    }
}

void FMUIInAppStore::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{ 
        CCControlButton * button = (CCControlButton *)object;
        switch (button->getTag()) {
            case 0:
            {
                //close
                FMSound::playEffect("click.mp3", 0.1f, 0.1f);
                GAMEUI_Scene::uiSystem()->prevWindow();
                FMDataManager::sharedManager()->setIsGoldFromIap(false);
            }
                break;
            case 4:
            {
                //more
                if (event == CCControlEventTouchDown) {
                    m_isClicked = true;
                }
                
                if (event == CCControlEventTouchDragInside) {
                    m_isClicked = false;
                }
                
                if (event == CCControlEventTouchUpInside && m_isClicked) {
#ifdef BRANCH_CN
                    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
                        SNSFunction_showFreeGemsOffer();
#else
                        
                        FMUIFreeGolds * window = (FMUIFreeGolds *)FMDataManager::sharedManager()->getUI(kUI_FreeGolds);
                        GAMEUI_Scene::uiSystem()->nextWindow(window);
#endif
                    
                    //SNSFunction_showFreeGemsOffer();
#else
                    SNSFunction_showPopupAd();
#endif
                    // SNSFunction_showAdOffer("flurry");
                    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
                }
            }
                break;
            case 10:
            {
                if (event == CCControlEventTouchDown) {
                    m_isClicked = true;
                }
                
                if (event == CCControlEventTouchDragInside) {
                    m_isClicked = false;
                }
                
                
                if (event == CCControlEventTouchUpInside && m_isClicked) {
                    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
                    int tag = button->getParent()->getParent()->getParent()->getTag();
                    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#ifdef BRANCH_CN
                    if( tag == 0 ){
                        int platformType = SNSGameHelper_getPlatformType();
                        if(platformType == PLATFORM_MM || platformType == PLATFORM_MM_ALIPAY){
                            int skip_count = SNSFunction_getSkipIAPCount();
                            if(skip_count>0){
                                m_slider->refresh();
                                return;
                            }
                        }
                    }
#endif
#endif
                    iapItemGroup * group = goldGroup;
                    iapItemGroup &g = group[tag];
                    FMDataManager::sharedManager()->setIsGoldFromIap(true);
                    //iap
                    m_boughtGroup = &g;
                    OBJCHelper::helper()->updateIAPGroup(&g);
                    OBJCHelper::helper()->buyIAPItem(g.ID, 1, this, callfuncO_selector(FMUIInAppStore::buyIAPCallback));                
                }
            }
                break;
                
            default:
                break;
        } 
   
}

void FMUIInAppStore::buyIAPCallback(cocos2d::CCObject *object)
{
    CCDictionary * dic = (CCDictionary *)object;
    if (!dic) {
        return;
    }
    CCNumber * num = (CCNumber *)dic->objectForKey("success");
    bool succeed = num->getIntValue() == 1;
    if (succeed) {
        OBJCHelper::helper()->trackPurchase(m_boughtGroup->ID, atof(m_boughtGroup->price), m_boughtGroup->code);
        
        CCString * tid = (CCString *)dic->objectForKey("tid");
        if (tid) {
            OBJCHelper::helper()->trackBIPurchase(m_boughtGroup->price, m_boughtGroup->ID, m_boughtGroup->amount, tid->getCString(), m_boughtGroup->code);
        }
        // 不用在这里加宝石/金币，而是在公共代码里统一加SnsGameHelper.mm
        // FMDataManager * manager = FMDataManager::sharedManager();
        // int gold = manager->getGoldNum();
        // gold += m_boughtGroup->amount;
        // manager->setGoldNum(gold);
        m_boughtGroup = NULL;
        // manager->saveGame();
    }
}

void FMUIInAppStore::setClassState(int state)
{
    GAMEUI::setClassState(state);
}

void FMUIInAppStore::onExit()
{
    GAMEUI_Window::onExit();
    FMDataManager::sharedManager()->setIsGoldFromIap(false);
}

void FMUIInAppStore::onEnter()
{
    GAMEUI_Window::onEnter();
    
//    bool showAdvert = SNSFunction_isAdVisible();
//    m_moreButtonParent->setVisible(showAdvert); 
    
    m_closeButton->setDefaultTouchPriority(-getZOrder() -1);
    m_closeButton->setTouchPriority(-getZOrder()-1);
    
//    CCControlButton * moreButton = (CCControlButton *)m_moreButtonParent->getChildByTag(4);
//    moreButton->setDefaultTouchPriority(-getZOrder() -1);
//    moreButton->setTouchPriority(-getZOrder()-1);
//    moreButton->setEnabled(showAdvert);
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
//    static const char* s_icons[3] = {
//        "ui_a_gold1.png","ui_a_gold2.png","ui_a_gold3.png",
//    };
//    static int s_sale[] = {
//        66,25,0,
//    };
    if( SNSFunction_getPackageType() == PT_MM_CN_WEIXIN_MM ||
       SNSFunction_getPackageType() == PT_MM_CN_WEIXIN_MM_ALIPAY )
    {
        for (int i=0; i<5; i++) {
            //goldGroup[i].icon = s_icons[i];
            goldGroup[i].sale = 0;
            goldGroup[i].bestValue = false;
        }
        goldGroup[0].bestValue = true;
    }
    
    SNSGameHelper_onAppstoreEnter();
#endif
    
    for (int i=0; i<5; i++) {
        OBJCHelper::helper()->updateIAPGroup(&goldGroup[i]);
    }
    
    m_slider->refresh();
    
#ifdef BRANCH_TH
    m_titleLabel->setScale(0.8f);
#endif
    
}

#pragma mark - slider delegate
CCNode * FMUIInAppStore::createItemForSlider(GUIScrollSlider *slider)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    CCNode * node = NULL;
    if( SNSFunction_getPackageType() == PT_MM_CN_WEIXIN_MM ||
       SNSFunction_getPackageType() == PT_MM_CN_WEIXIN_MM_ALIPAY ) {
        node = FMDataManager::sharedManager()->createNode("UI/FMUIIAPItem_MM.ccbi", this);
    }else {
        node = FMDataManager::sharedManager()->createNode("UI/FMUIIAPItem.ccbi", this);
    }
#else
    CCNode * node = FMDataManager::sharedManager()->createNode("UI/FMUIIAPItem.ccbi", this);
#endif
    
    CCNode * parent = node->getChildByTag(0)->getChildByTag(0);
    
    CCAnimButton * button = (CCAnimButton *)parent->getChildByTag(10);
    button->getAnimNode()->releaseControl("Label", kProperty_StringValue);
    return node;
}

int FMUIInAppStore::itemsCountForSlider(GUIScrollSlider *slider)
{
    if (SNSFunction_isAdVisible()) {
#ifdef BRANCH_CN
        return 7;
#else
        return 5;
#endif
    }
    else {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#ifdef BRANCH_CN
        int platformType = SNSGameHelper_getPlatformType();
        if(platformType == PLATFORM_MM || platformType == PLATFORM_MM_ALIPAY){
            int skip_count = SNSFunction_getSkipIAPCount();
            static int s_skip_count = skip_count;
            if(s_skip_count != skip_count){
                s_skip_count = skip_count;
                m_slider->refresh();
            }
            return 5 - skip_count;
        }
#endif
#else
        return 5;
#endif //CC_PLATFORM_ANDROID
        return 5;
    }
}

void FMUIInAppStore::sliderUpdate(GUIScrollSlider *slider, int rowIndex, cocos2d::CCNode *node)
{
#ifdef BRANCH_CN
    if (SNSFunction_isAdVisible()) {
        if (rowIndex == 0 || rowIndex == 6) {
            CCBAnimationManager * manager = (CCBAnimationManager *)node->getUserObject();
            manager->runAnimationsForSequenceNamed("ButtonCN");
            CCNode* pnode = node->getChildByTag(1);
            if (pnode) {
                CCAnimButton* btn = (CCAnimButton*)pnode->getChildByTag(4);
                if (btn) {
                    NEAnimNode* anim = btn->getAnimNode();
                    if (anim) {
                        anim->useSkin("FreeGemIAP");
                    }
                }
            }
            return;
        }else{
            rowIndex -= 1;
            CCBAnimationManager * manager = (CCBAnimationManager *)node->getUserObject();
            manager->runAnimationsForSequenceNamed("Init");
        }
    }
    else{
        CCBAnimationManager * manager = (CCBAnimationManager *)node->getUserObject();
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
        if( rowIndex == 0 && SNSFunction_getSkipIAPCount() == 0 )
            manager->runAnimationsForSequenceNamed("ButtonBuyLimit");
        else manager->runAnimationsForSequenceNamed("Init");
#else
        manager->runAnimationsForSequenceNamed("Init");
#endif
    }
    
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
    int skip_count = SNSFunction_getSkipIAPCount();
    if( skip_count > 0 )
    {
        for( int i = 0; i < 5; i++ ){
            goldGroup[i].bestValue = false;
        }
        goldGroup[4].bestValue = true;
        
        rowIndex += skip_count;
    }
#endif
    
#else
    if (rowIndex == 5) {
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
        if (SNSFunction_isAdVisible()) {
            CCBAnimationManager * manager = (CCBAnimationManager *)node->getUserObject();
            manager->runAnimationsForSequenceNamed("Button");
        }
#else
        CCBAnimationManager * manager = (CCBAnimationManager *)node->getUserObject();
        manager->runAnimationsForSequenceNamed("Button");
#endif
        return;
    }
    else{
        CCBAnimationManager * manager = (CCBAnimationManager *)node->getUserObject();
        manager->runAnimationsForSequenceNamed("Init");
    }
#endif
    
    
    FMDataManager * manager = FMDataManager::sharedManager();
    node->setZOrder(10 + rowIndex);
    node->setTag(rowIndex);
    CCNode * parent = node->getChildByTag(0)->getChildByTag(0);
    CCSprite * icon = (CCSprite *)parent->getChildByTag(0);
    iapItemGroup * group = goldGroup;
    OBJCHelper::helper()->updateIAPGroup(&goldGroup[rowIndex]);
    iapItemGroup &g = group[rowIndex];
    CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(g.icon);
    icon->setDisplayFrame(frame);
    
    bool isSale = g.sale != 0;
    CCSprite * redLabel = (CCSprite *)parent->getChildByTag(1);
    redLabel->setVisible(isSale);
    
    CCSprite * redLine = (CCSprite *)parent->getChildByTag(6);
    redLine->setVisible(isSale);
    
    
    CCLabelBMFont * more = (CCLabelBMFont *)parent->getChildByTag(1)->getChildByTag(1);
    const char * s = manager->getLocalizedString("V100_(D)_MORE");
    CCString * cstr = CCString::createWithFormat(s, g.sale);
    more->setString(cstr->getCString());
#ifdef BRANCH_TH
    more->setScale(0.85f);
#endif
    
    
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    if( SNSFunction_getPackageType() == PT_MM_CN_WEIXIN_MM ||
       SNSFunction_getPackageType() == PT_MM_CN_WEIXIN_MM_ALIPAY )
    {
//        CCLabelBMFont * prize = (CCLabelBMFont *)parent->getChildByTag(100);
//        const char * s = manager->getLocalizedString("V100_PRIZE_PACKAGE");
//        CCString * cstr = CCString::createWithFormat(s, g.amount);
//        prize->setString(cstr->getCString());
//        prize->setColor(ccc3(107, 71, 0));
//        
//        static int s_prize_count[5] = {50,25,10,0,0};
//        CCLabelBMFont * prizeDes = (CCLabelBMFont *)parent->getChildByTag(101);
//        s = manager->getLocalizedString("V100_GOLD_DES");
//        cstr = CCString::createWithFormat(s,s_prize_count[rowIndex]);
//        prizeDes->setString(cstr->getCString());
//        prizeDes->setColor(ccc3(107, 71, 0));
    }
#endif
    
    CCLabelBMFont * amount = (CCLabelBMFont *)parent->getChildByTag(2);
    cstr = CCString::createWithFormat("%d", g.amount);
    amount->setString(cstr->getCString());
    
    CCLabelBMFont * oldamount = (CCLabelBMFont *)parent->getChildByTag(3);
    int old = ceil(g.amount /((100 + g.sale) / 100.f));
    cstr = CCString::createWithFormat("%d", old);
    oldamount->setString(cstr->getCString());
    oldamount->setVisible(isSale);
    
    CCAnimButton * button = (CCAnimButton *)parent->getChildByTag(10);
    CCLabelBMFont * buttonLabel = (CCLabelBMFont *)button->getAnimNode()->getNodeByName("Label");
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    if( SNSFunction_getPackageType() == PT_CY_EN_FACEBOOK_CY )
    {
        cstr = CCString::createWithFormat("%s%s", g.symbol, g.price);
        buttonLabel->setString(cstr->getCString());
    }else{
        cstr = CCString::createWithFormat("%s %s", g.symbol, g.price);
        buttonLabel->setString(cstr->getCString());
    }
#else
    cstr = CCString::createWithFormat("%s %s", g.symbol, g.price);
    buttonLabel->setString(cstr->getCString());
#endif

    CCSprite * bestValue = (CCSprite *)parent->getChildByTag(5);
    bestValue->setVisible(g.bestValue);
    
}


void FMUIInAppStore::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction); 
//    FMDataManager * manager = FMDataManager::sharedManager();
//    if (manager->isInGame()) {
//        //move in slider
//        FMStatusbar * statusbar = (FMStatusbar *)manager->getUI(kUI_Statusbar);
//        statusbar->show(true);
//    } 
}

void FMUIInAppStore::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionOut(finishAction); 
//    FMDataManager * manager = FMDataManager::sharedManager();
//    if (manager->isInGame()) {
//        //move out slider
//        FMStatusbar * statusbar = (FMStatusbar *)manager->getUI(kUI_Statusbar);
//        statusbar->show(false);
//    }
}
