//
//  FMUISignReward.cpp
//  JellyMania
//
//  Created by lipeng on 14-8-16.
//
//

#include "FMUISignReward.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "OBJCHelper.h"
#include "SNSFunction.h"
#include "FMGameNode.h"

FMUISignReward::FMUISignReward():
m_panel(NULL),
m_parentNode(NULL),
m_shareButton(NULL),
m_nameLabel(NULL),
m_rewardNode(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUISignReward.ccbi", this);
    addChild(m_ccbNode);
    
    
}

FMUISignReward::~FMUISignReward()
{
}

#pragma mark - CCB Bindings
bool FMUISignReward::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_panel", CCNode *, m_panel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_nameLabel", CCLabelBMFont *, m_nameLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_shareButton", CCAnimButton *, m_shareButton);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_rewardNode", CCNode *, m_rewardNode);
    return true;
}

SEL_CCControlHandler FMUISignReward::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUISignReward::clickButton);
    return NULL;
}

void FMUISignReward::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    GAMEUI_Scene::uiSystem()->closeDialog();
    GAMEUI_Scene::uiSystem()->closeAllWindows();
}

void FMUISignReward::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    m_panel->setScale(0.5f);
    m_panel->setVisible(true);
    CCScaleTo * s = CCScaleTo::create(0.3f, 1.f);
    CCEaseBackOut * e = CCEaseBackOut::create(s);
    CCSequence * seq = CCSequence::create(e, finishAction, NULL);
    m_panel->runAction(seq);
}

void FMUISignReward::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    m_panel->setScale(1.f);
    CCScaleTo * s = CCScaleTo::create(0.15f, 0.5f);
    CCEaseBackIn * e = CCEaseBackIn::create(s);
    CCHide * h = CCHide::create();
    CCSequence * seq = CCSequence::create(e, h, finishAction, NULL);
    m_panel->runAction(seq);
}
void FMUISignReward::setReward(std::vector<int> vector)
{
    int type = vector[0];
    int amount = vector[1];
    
    CCString * amountStr = CCString::createWithFormat("x%d",amount);
    CCBAnimationManager * rewardAnim = (CCBAnimationManager *)m_rewardNode->getUserObject();
    rewardAnim->runAnimationsForSequenceNamed(CCString::createWithFormat("%d",type)->getCString());
    
    if (type == kBooster_UnlimitLife){
        amountStr = CCString::createWithFormat(FMDataManager::sharedManager()->getLocalizedString("V170_MINUTES_(D)"),amount);
    }
    m_nameLabel->setString(amountStr->getCString());
}
void FMUISignReward::onEnter()
{
    GAMEUI_Dialog::onEnter();
}
