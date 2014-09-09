//
//  FMUIRestore.cpp
//  FarmMania
//
//  Created by  James Lee on 13-6-6.
//
//

#include "FMUIRestore.h"


#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "FMStatusbar.h"
#include "OBJCHelper.h"

FMUIRestore::FMUIRestore():
m_parentNode(NULL),
m_infoLabel(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIRestore.ccbi", this);
    addChild(m_ccbNode);
    
    if (m_infoLabel) {
        m_infoLabel->setWidth(200);
        m_infoLabel->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    }
}

FMUIRestore::~FMUIRestore()
{
    
}

#pragma mark - CCB Bindings
bool FMUIRestore::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_infoLabel", CCLabelBMFont *, m_infoLabel);
    return true;
}

SEL_CCControlHandler FMUIRestore::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIRestore::clickButton);
    return NULL;
}

void FMUIRestore::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        //close
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIRestore::clickButton(cocos2d::CCObject *object, CCControlEvent event)
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
        case 2:
        {
            switch (classState()) {
                case kSRestore:
                { 
#if CC_TARGET_PLATFORM == CC_PLATFORM_IOS
                    OBJCHelper::helper()->restoreIAP(this, callfuncO_selector(FMUIRestore::restoreIAPCallback));
#endif
                }
                    break;
                    
                default:
                    break;
            }
        }
            break;
        default:
            break;
    }
}


void FMUIRestore::setClassState(int state)
{
    GAMEUI::setClassState(state);
}


void FMUIRestore::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIRestore::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}


void FMUIRestore::restoreIAPCallback(cocos2d::CCObject *object)
{
    CCNumber * n = (CCNumber *)object;
    if (n->getIntValue() == 1) {
        //succeed
        FMDataManager * manager = FMDataManager::sharedManager();
        if (!manager->isLifeUpgraded()) {
            manager->upgradeLife();
            int max = manager->getMaxLife();
            manager->setLifeNum(max);
            FMStatusbar * statusbar = (FMStatusbar *)manager->getUI(kUI_Statusbar);
            statusbar->updateUI();
        }
    }
}
