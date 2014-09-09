//
//  FMInputNumberDialog.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-20.
//
//

#include "FMInputNumberDialog.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"

FMInputNumberDialog::FMInputNumberDialog() :
    m_buttonParent(NULL),
    m_number(0),
    m_unmodified(true)
{
    m_ui = FMDataManager::sharedManager()->createNode("Editor/FMInputNumberDialog.ccbi", this);
    addChild(m_ui);
}

FMInputNumberDialog::~FMInputNumberDialog()
{
    
}


bool FMInputNumberDialog::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_buttonParent", CCNode *, m_buttonParent);
    return true;
}

SEL_CCControlHandler FMInputNumberDialog::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMInputNumberDialog::clickButton); 
    return NULL;
}


void FMInputNumberDialog::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    CCControlButton * button = (CCControlButton *)object;
    int tag = button->getTag();
    switch (tag) {
        case 10:
            //del
            setNumber(m_number / 10.f);
            break;
        case 11:
            //c
            setNumber(0);
            break;
        case 12:
            //cancel
            setHandleResult(DIALOG_CANCELED);
            GAMEUI_Scene::uiSystem()->closeDialog();
            break;
        case 13:
            //ok
            setHandleResult(DIALOG_OK);
            GAMEUI_Scene::uiSystem()->closeDialog();
            break;
            
        default:
            int num = tag;
            if (m_unmodified) {
                m_unmodified = false;
                setNumber(num);
            }
            else {
                setNumber(m_number * 10 + num);
            }
            break;
    }
}

void FMInputNumberDialog::setNumber(int number)
{
    m_number = number;
    if (m_number >= 10000000000) {
        m_number = 9999999999;
    }
    if (m_number < 0) {
        m_number = 0;
    }
    CCLabelTTF * numberLabel = (CCLabelTTF *)m_buttonParent->getChildByTag(99);
    std::stringstream ss;
    ss << m_number;
    numberLabel->setString(ss.str().c_str());
}