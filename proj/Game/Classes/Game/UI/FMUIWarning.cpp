//
//  FMUIWarning.cpp
//  FarmMania
//
//  Created by James Lee on 13-5-29.
//
//

#include "FMUIWarning.h"

#include "FMDataManager.h"
#include "FMMainScene.h"
#include "FMStatusbar.h"
#include "GAMEUI_Scene.h"

FMUIWarning::FMUIWarning() :
    m_panel(NULL),
    m_parentNode(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIWarning.ccbi", this);
    addChild(m_ccbNode);
}

FMUIWarning::~FMUIWarning()
{
    
}

#pragma mark - CCB Bindings
bool FMUIWarning::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_panel", CCNode *, m_panel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode); 
    return true;
}

SEL_CCControlHandler FMUIWarning::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIWarning::clickButton);
    return NULL;
}

void FMUIWarning::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    switch (button->getTag()) {
        case 0:
        case 1:
        {
            //close, cancel
            setHandleResult(DIALOG_CANCELED);
            GAMEUI_Scene::uiSystem()->closeDialog();
        }
            break;
        case 2:
        {
            //quit
            setHandleResult(DIALOG_OK);
            GAMEUI_Scene::uiSystem()->closeDialog();
        }
            break;
        default:
            break;
    }
}

void FMUIWarning::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    m_panel->setScale(0.5f);
    m_panel->setVisible(true);
    CCScaleTo * s = CCScaleTo::create(0.3f, 1.f);
    CCEaseBackOut * e = CCEaseBackOut::create(s);
    CCSequence * seq = CCSequence::create(e, finishAction, NULL);
    m_panel->runAction(seq);
}

void FMUIWarning::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    m_panel->setScale(1.f);
    CCScaleTo * s = CCScaleTo::create(0.15f, 0.5f);
    CCEaseBackIn * e = CCEaseBackIn::create(s);
    CCHide * h = CCHide::create();
    CCSequence * seq = CCSequence::create(e, h, finishAction, NULL);
    m_panel->runAction(seq);
}

void FMUIWarning::setClassState(int state)
{
    GAMEUI::setClassState(state);
}

void FMUIWarning::onEnter()
{
    GAMEUI_Dialog::onEnter();
}