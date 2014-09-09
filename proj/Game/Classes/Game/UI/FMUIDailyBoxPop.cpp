//
//  FMUIDailyBoxPop.cpp
//  JellyMania
//
//  Created by lipeng on 14-8-15.
//
//

#include "FMUIDailyBoxPop.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "SNSFunction.h"
#include "FMMainScene.h"
#include "FMWorldMapNode.h"


FMUIDailyBoxPop::FMUIDailyBoxPop():
m_instantMove(false),
m_sendButton(NULL),
m_label(NULL),
m_isShowTip(true)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIDailyBoxPop.ccbi", this);
    addChild(m_ccbNode);
    
    
    m_label->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    m_label->setWidth(200);
    m_label->setAlignment(kCCTextAlignmentCenter);
    
//    NEAnimNode * closeNode = m_sendButton->getAnimNode();
//    closeNode->releaseControl("Label", kProperty_FNTFile);
//    CCLabelBMFont * closelabel = (CCLabelBMFont *)closeNode->getNodeByName("Label");
//    closelabel->setFntFile("font_2.fnt");
}

FMUIDailyBoxPop::~FMUIDailyBoxPop()
{
}

#pragma mark - CCB Bindings
bool FMUIDailyBoxPop::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_label", CCLabelBMFont *, m_label);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_sendButton", CCAnimButton *, m_sendButton);
    return true;
}

SEL_CCControlHandler FMUIDailyBoxPop::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIDailyBoxPop::clickButton);
    return NULL;
}

void FMUIDailyBoxPop::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    if (!m_isShowTip) {
        FMDataManager * manager = FMDataManager::sharedManager();
        manager->setGoldNum(manager->getGoldNum()+3);
        
        FMMainScene * mainScene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMWorldMapNode* wd = (FMWorldMapNode*)mainScene->getNode(kWorldMapNode);
        wd->phaseDone();
    }
    GAMEUI_Scene::uiSystem()->prevWindow();
}

void FMUIDailyBoxPop::onEnter()
{
    GAMEUI_Window::onEnter();
}

void FMUIDailyBoxPop::showTip(bool isTip)
{
    m_isShowTip = isTip;
    FMDataManager * manager = FMDataManager::sharedManager();
    if (isTip) {
        m_label->setString(manager->getLocalizedString("V170_DAILYBOX_TIP"));
    }else{
        m_label->setString(manager->getLocalizedString("V170_DAILYBOX_REWARD"));
    }
}
