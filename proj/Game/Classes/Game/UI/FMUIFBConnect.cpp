//
//  FMUIFBConnect.cpp
//  JellyMania
//
//  Created by lipeng on 14-4-27.
//
//

#include "FMUIFBConnect.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "OBJCHelper.h"
#include "SNSFunction.h"

FMUIFBConnect::FMUIFBConnect():
m_instantMove(false),
m_tipLabel(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIConnectFB.ccbi", this);
    addChild(m_ccbNode);
}

FMUIFBConnect::~FMUIFBConnect()
{
}

#pragma mark - CCB Bindings
bool FMUIFBConnect::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_tipLabel", CCLabelBMFont *, m_tipLabel);
    return true;
}

SEL_CCControlHandler FMUIFBConnect::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIFBConnect::clickButton);
    return NULL;
}

void FMUIFBConnect::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIFBConnect::clickButton(cocos2d::CCObject *object, CCControlEvent event)
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
        {
            //connect
            m_instantMove = false;
            GAMEUI_Scene::uiSystem()->prevWindow();

            OBJCHelper::helper()->connectToFacebook(NULL);
        }
            break;
        default:
            break;
    }
}

void FMUIFBConnect::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIFBConnect::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUIFBConnect::onEnter()
{
    GAMEUI_Window::onEnter();
    FMDataManager * manager = FMDataManager::sharedManager();
    
    m_tipLabel->setAlignment(kCCTextAlignmentCenter);
    m_tipLabel->setWidth(180);
    m_tipLabel->setLineBreakWithoutSpace(manager->isCharacterType());
}
