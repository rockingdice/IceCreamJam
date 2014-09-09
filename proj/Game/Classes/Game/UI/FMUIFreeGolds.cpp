//
//  FMUIFreeGolds.cpp
//  JellyMania
//
//  Created by lipeng on 14-3-5.
//
//

#include "FMUIFreeGolds.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "OBJCHelper.h"
#include "SNSFunction.h"
#include "FMUIWorldMap.h"
#include "FMUIRestore.h"
#include "FMUIConfig.h"
#include "FMStatusbar.h"

FMUIFreeGolds::FMUIFreeGolds():
m_instantMove(false)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIFreeGolds.ccbi", this);
    addChild(m_ccbNode);
}

FMUIFreeGolds::~FMUIFreeGolds()
{
    
}

#pragma mark - CCB Bindings
bool FMUIFreeGolds::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    return true;
}

SEL_CCControlHandler FMUIFreeGolds::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIFreeGolds::clickButton);
    return NULL;
}

void FMUIFreeGolds::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIFreeGolds::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    int tag = button->getTag();
    switch (tag) {
        case 0:
        {
            //close
            m_instantMove = false;
            GAMEUI_Scene::uiSystem()->prevWindow();
        }
            break;
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        {
            SNSFunction_showFreeGemsOfferOfType(tag);
        }
            break;
        case 6:
        {
            //SNSFunction_showFreeGemsOfferOfType(1);
        }
            break;
        default:
            break;
    }
}




void FMUIFreeGolds::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIFreeGolds::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUIFreeGolds::onEnter()
{
    GAMEUI_Window::onEnter();
}

