//
//  FMUIBuySpin.cpp
//  JellyMania
//
//  Created by lipeng on 14-4-23.
//
//

#include "FMUIBuySpin.h"
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
#include "FMUISpin.h"

#ifdef BRANCH_CN
static int kBuyMoreSpin = 12;
#else
static int kBuyMoreSpin = 6;
#endif

FMUIBuySpin::FMUIBuySpin():
m_instantMove(false),
m_moreSpinBtn(NULL),
m_tipLabel(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIPopBuySpin.ccbi", this);
    addChild(m_ccbNode);
    
    m_tipLabel->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    m_tipLabel->setWidth(220);
    m_tipLabel->setAlignment(kCCTextAlignmentCenter);
}

FMUIBuySpin::~FMUIBuySpin()
{
}

#pragma mark - CCB Bindings
bool FMUIBuySpin::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_tipLabel", CCLabelBMFont *, m_tipLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_moreSpinBtn", CCAnimButton *, m_moreSpinBtn);
    return true;
}

SEL_CCControlHandler FMUIBuySpin::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIBuySpin::clickButton);
    return NULL;
}

void FMUIBuySpin::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIBuySpin::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    int tag = button->getTag();
    FMDataManager * manager = FMDataManager::sharedManager();
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
            //morespin
            if (manager->useMoney(kBuyMoreSpin, "Spin")) {
                manager->addSpinTimes();
                m_instantMove = false;
                GAMEUI_Scene::uiSystem()->prevWindow();
            }
        }
            break;
        default:
            break;
    }
}

void FMUIBuySpin::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIBuySpin::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUIBuySpin::onEnter()
{
    GAMEUI_Window::onEnter();
    FMDataManager * manager = FMDataManager::sharedManager();
    
    NEAnimNode * node = m_moreSpinBtn->getAnimNode();
    node->releaseControl("Label", kProperty_StringValue);
    CCLabelBMFont * label = (CCLabelBMFont *)node->getNodeByName("Label");
    label->setString(CCString::createWithFormat(manager->getLocalizedString("V140_MORESPIN_(D)"), kBuyMoreSpin)->getCString());

    m_tipLabel->setAlignment(kCCTextAlignmentCenter);
    m_tipLabel->setWidth(180);
    m_tipLabel->setLineBreakWithoutSpace(manager->isCharacterType());

}
