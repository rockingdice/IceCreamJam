//
//  FMUIPause.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-26.
//
//

#include "FMUIPause.h"
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

FMUIPause::FMUIPause() :
    m_useridLabel(NULL),
    m_versionLabel(NULL),
    m_instantMove(false)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIPause.ccbi", this);
    addChild(m_ccbNode);
}

FMUIPause::~FMUIPause()
{
    
}

#pragma mark - CCB Bindings
bool FMUIPause::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_useridLabel", CCLabelBMFont *, m_useridLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_versionLabel", CCLabelBMFont *, m_versionLabel);
    return true;
}

SEL_CCControlHandler FMUIPause::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIPause::clickButton);
    return NULL;
}

void FMUIPause::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIPause::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    switch (button->getTag()) {
        case 0:
        case 4:
        {
            //close
            m_instantMove = false;
            GAMEUI_Scene::uiSystem()->prevWindow();
        }
            break;
        case 1:
        {
            //retry
            FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
            FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);
           
            m_instantMove = true;
            GAMEUI_Scene::uiSystem()->prevWindow();

            FMDataManager * manager = FMDataManager::sharedManager();
            if (!manager->isNeedFailCount()) {
                game->userRetryAddLife();
                return;
            }
            
            FMUIQuit * dialog = (FMUIQuit *)FMDataManager::sharedManager()->getUI(kUI_Quit);
            dialog->setClassState(kQuit_To_Retry);
            dialog->setHandleCallback(CCCallFuncN::create(game, callfuncN_selector(FMGameNode::handleDialogQuit)));
            GAMEUI_Scene::uiSystem()->addDialog(dialog);
        }
            break;
        case 2:
        {
            //exit
            FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
            FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);

            m_instantMove = true;
            GAMEUI_Scene::uiSystem()->prevWindow();
            
            FMDataManager * manager = FMDataManager::sharedManager();
            if (!manager->isNeedFailCount()) {
                game->userQuiteAddLife();
                return;
            }

            FMUIQuit * dialog = (FMUIQuit *)FMDataManager::sharedManager()->getUI(kUI_Quit);
            dialog->setClassState(kQuit_To_WorldMap);
            dialog->setHandleCallback(CCCallFuncN::create(game, callfuncN_selector(FMGameNode::handleDialogQuit)));
            GAMEUI_Scene::uiSystem()->addDialog(dialog);
        }
            break;
        case 3:
        { 
            FMUIConfig * window = (FMUIConfig *)FMDataManager::sharedManager()->getUI(kUI_Config);
            window->setClassState(1);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
            break;
        default:
            break;
    }
} 




void FMUIPause::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIPause::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUIPause::onEnter()
{
    GAMEUI_Window::onEnter();

    updateUI();
}

void FMUIPause::updateUI()
{
    FMDataManager * manager = FMDataManager::sharedManager();

    CCString * cstr = CCString::createWithFormat("V %s", manager->getVersion());
    m_versionLabel->setString(cstr->getCString());
    
    cstr = CCString::createWithFormat(manager->getLocalizedString("V100_SUPPORT_ID"), manager->getUID());
    m_useridLabel->setString(cstr->getCString());
}
