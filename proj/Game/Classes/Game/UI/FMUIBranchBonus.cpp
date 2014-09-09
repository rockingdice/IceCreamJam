//
//  FMUIBranchBonus.cpp
//  JellyMania
//
//  Created by lipeng on 14-2-11.
//
//

#include "FMUIBranchBonus.h"

#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "FMUIBranchLevel.h"
extern BranchRewardData rewardData[2];

FMUIBranchBonus::FMUIBranchBonus() :
//m_parentNode(NULL),
m_panel(NULL),
m_amountLabel(NULL),
m_describeLabel(NULL),
m_level(0),
m_okButton(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIBranchBonus.ccbi", this);
    addChild(m_ccbNode);
    
    m_okButton->getAnimNode()->releaseControl("Label", kProperty_StringValue);
}

FMUIBranchBonus::~FMUIBranchBonus()
{
    
}

#pragma mark - CCB Bindings
bool FMUIBranchBonus::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
//    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_panel", CCNode *, m_panel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_describeLabel", CCLabelBMFont *, m_describeLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_amountLabel", CCLabelBMFont *, m_amountLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_okButton", CCAnimButton *, m_okButton);
    return true;
}

SEL_CCControlHandler FMUIBranchBonus::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIBranchBonus::clickButton);
    return NULL;
}

void FMUIBranchBonus::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    switch (button->getTag()) {
        case 0:
        {
            //close
            FMUIBranchLevel * window = (FMUIBranchLevel *)FMDataManager::sharedManager()->getUI(kUI_BranchLevel);
            window->phaseDone();
            GAMEUI_Scene::uiSystem()->closeDialog();
        }
            break;
        default:
            break;
    }
}

void FMUIBranchBonus::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    m_panel->setScale(0.5f);
    m_panel->setVisible(true);
    CCScaleTo * s = CCScaleTo::create(0.3f, 1.f);
    CCEaseBackOut * e = CCEaseBackOut::create(s);
    CCSequence * seq = CCSequence::create(e, finishAction, NULL);
    m_panel->runAction(seq);
}

void FMUIBranchBonus::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    m_panel->setScale(1.f);
    CCScaleTo * s = CCScaleTo::create(0.15f, 0.5f);
    CCEaseBackIn * e = CCEaseBackIn::create(s);
    CCHide * h = CCHide::create();
    CCSequence * seq = CCSequence::create(e, h, finishAction, NULL);
    m_panel->runAction(seq);
}

void FMUIBranchBonus::onEnter()
{
    GAMEUI_Dialog::onEnter();
    
    FMDataManager * manager = FMDataManager::sharedManager();
    
    CCLabelBMFont * btnLabel = (CCLabelBMFont *)m_okButton->getAnimNode()->getNodeByName("Label");
    btnLabel->setFntFile("font_1.fnt");
    btnLabel->setString(manager->getLocalizedString("V120_BUTTON_OK"));
    
    //update gold info
    for (int i = 0; i < _BonusRewardCount_; i++) {
        if (rewardData[i].level == m_level) {
            CCString * num = CCString::createWithFormat("x %d", rewardData[i].number);
            m_amountLabel->setString(num->getCString());
            break;
        }
    }
}

void FMUIBranchBonus::setLevelIndex(int level)
{
    m_level = level;
}
