//
//  FMUINeedMoney.cpp
//  FarmMania
//
//  Created by  James Lee on 13-6-6.
//
//

#include "FMUINeedMoney.h"


#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "FMStatusbar.h"
#include "OBJCHelper.h"
#include "SNSFunction.h"

//static iapItemGroup goldGroup[] = {
//    {3, "iap_gold2.png", "4.99", 52, 5, false, "com.naughtycat.jellymania.gold5", "$", "USD"},
//};
static iapItemGroup goldGroup[5] = {
    {4, "ui_gold1.png", "0.99", 10, 0, false, "com.naughtycat.jellymania.gold1", "$", "USD"},
    {3, "ui_gold2.png", "4.99", 52, 5, false, "com.naughtycat.jellymania.gold5", "$", "USD"},
    {2, "ui_gold3.png", "9.99", 110, 10, false, "com.naughtycat.jellymania.gold10", "$", "USD"},
    {1, "ui_gold4.png", "49.99", 560, 12, false, "com.naughtycat.jellymania.gold50", "$", "USD"},
    {0, "ui_gold5.png", "99.99", 1150, 15, true, "com.naughtycat.jellymania.gold100", "$", "USD"},
};

FMUINeedMoney::FMUINeedMoney() :
    m_parentNode(NULL),
    m_amountLabel(NULL),
    m_priceButton(NULL),
    m_goldLabel1(NULL),
    m_goldLabel2(NULL),
    m_index(4)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUINeedMoney.ccbi", this);
    addChild(m_ccbNode);

    m_priceButton->getAnimNode()->releaseControl("Label", kProperty_StringValue);
    
    //#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
//    CCLabelBMFont * title = (CCLabelBMFont *)m_parentNode->getChildByTag(3);
//    title->setAlignment(kCCTextAlignmentCenter);
//#endif
//    
//    for (int i=0; i<2; i++) {
//        CCNode * item = FMDataManager::sharedManager()->createNode("UI/FMUIIAPItem.ccbi", this);
//        m_parentNode->addChild(item, 1 + i, i);
//        item->setPosition(ccp(0, -39.f - i * 70));
//    }
}

FMUINeedMoney::~FMUINeedMoney()
{
    
}

#pragma mark - CCB Bindings
bool FMUINeedMoney::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_amountLabel", CCLabelBMFont *, m_amountLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_priceButton", CCAnimButton *, m_priceButton);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_goldLabel1", CCLabelBMFont *, m_goldLabel1);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_goldLabel2", CCLabelBMFont *, m_goldLabel2);
    return true;
}

SEL_CCControlHandler FMUINeedMoney::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUINeedMoney::clickButton);
    return NULL;
}

void FMUINeedMoney::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
        FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    }
}

void FMUINeedMoney::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    CCControlButton * button = (CCControlButton *)object; 
    switch (button->getTag()) {  
        case 0:
        {
            //resume
            m_instantMove = false;
            GAMEUI_Scene::uiSystem()->prevWindow();
            FMSound::playEffect("click.mp3", 0.1f, 0.1f);
        }
            break;
        case 10:
        {
            FMSound::playEffect("click.mp3", 0.1f, 0.1f); 
            iapItemGroup & g = goldGroup[m_index];
            OBJCHelper::helper()->updateIAPGroup(&g);
            m_boughtGroup = &g;
            OBJCHelper::helper()->buyIAPItem(g.ID, 1, this, callfuncO_selector(FMUINeedMoney::buyIAPCallback));
        }
            break;
        case 11:
        {
            SNSFunction_showFreeGemsOffer();
        }
            break;
        default:
            break;
    }
}


void FMUINeedMoney::buyIAPCallback(cocos2d::CCObject *object)
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
        //FMDataManager * manager = FMDataManager::sharedManager();
        //int gold = manager->getGoldNum();
        //gold += m_boughtGroup->amount;
        //manager->setGoldNum(gold);
        m_boughtGroup = NULL;
        //manager->saveGame();
        GAMEUI_Scene::uiSystem()->prevWindow();
    }

    CCLOG("iap buy : %d" , succeed);
}


void FMUINeedMoney::setClassState(int state)
{
    GAMEUI::setClassState(state);
}

void FMUINeedMoney::setNeedNumber(int number)
{
    for (int i = 0; i < 5; i++) {
        if (goldGroup[i].amount >= number) {
            m_index = i;
            break;
        }
    }
}

void FMUINeedMoney::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
//    FMDataManager * manager = FMDataManager::sharedManager();
//    if (manager->isInGame()) {
//        //move in slider
//        FMStatusbar * statusbar = (FMStatusbar *)manager->getUI(kUI_Statusbar);
//        statusbar->show(true);
//    }
}

void FMUINeedMoney::transitionOut(cocos2d::CCCallFunc *finishAction)
{ 
    GAMEUI_Window::transitionOut(finishAction);
//    FMDataManager * manager = FMDataManager::sharedManager();
//    if (manager->isInGame()) {
//        //move out slider
//        FMStatusbar * statusbar = (FMStatusbar *)manager->getUI(kUI_Statusbar);
//        statusbar->show(false);
//    }
}

void FMUINeedMoney::onEnter()
{
    GAMEUI_Window::onEnter();
    
#ifdef BRANCH_CN
    CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
    anim->runAnimationsForSequenceNamed("CN");
#endif
    FMDataManager * manager = FMDataManager::sharedManager();

    //update gold info
    for (int i=0; i<5; i++) {
        iapItemGroup &g = goldGroup[i];
        OBJCHelper::helper()->updateIAPGroup(&g);
    } 
    
    CCString * num = CCString::createWithFormat("x %d", goldGroup[m_index].amount);
    m_amountLabel->setString(num->getCString());
    
    CCLabelBMFont * amountLabel = (CCLabelBMFont *)m_priceButton->getAnimNode()->getNodeByName("Label");
    amountLabel->setFntFile("font_2.fnt");
    num = CCString::createWithFormat(manager->getLocalizedString("V100_BUY_FOR_(S)_(S)"), goldGroup[m_index].symbol, goldGroup[m_index].price);
    amountLabel->setString(num->getCString());
    
#ifdef BRANCH_TH
    m_goldLabel1->setPosition(ccp(0, 10));
    m_goldLabel2->setPosition(ccp(0, -24));
#endif
    
    
}
