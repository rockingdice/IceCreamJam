//
//  FMUIInputName.cpp
//  JellyMania
//
//  Created by lipeng on 14-4-14.
//
//

#include "FMUIInputName.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMDataManager.h"
#include "OBJCHelper.h"
#include "FMUIInvite.h"

FMUIInputName::FMUIInputName():
m_panel(NULL),
m_textfieldParent(NULL),
m_editBox(NULL),
m_isRename(false)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIInputName.ccbi", this);
    addChild(m_ccbNode);
    
}

FMUIInputName::~FMUIInputName()
{
    
}

#pragma mark - CCB Bindings
bool FMUIInputName::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_panel", CCNode *, m_panel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_textfieldParent", CCScale9Sprite *, m_textfieldParent);
    return true;
}

SEL_CCControlHandler FMUIInputName::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIInputName::clickButton);
    return NULL;
}

void FMUIInputName::onEnter()
{
    GAMEUI_Dialog::onEnter();
}

void FMUIInputName::transitionInDone()
{
    GAMEUI_Dialog::transitionInDone();
    FMDataManager *manager = FMDataManager::sharedManager();
    CCPoint p = m_textfieldParent->getPosition();
    
    m_editBox = CCEditBox::create(CCSize(160, 32), CCScale9Sprite::create("transparent.png"));
    nameLength();
    if (manager->getUserName()) {
        m_editBox->setText(manager->getUserName());
    }
    m_editBox->setFontColor(ccBLACK);
    m_editBox->setAnchorPoint(ccp(0.5, 0.5));
    p = m_textfieldParent->getParent()->convertToWorldSpace(p);
    m_editBox->setPosition(p);
    m_editBox->setMaxLength(8);
    m_editBox->setDelegate(this);
    m_editBox->setInputMode(kEditBoxInputModeEmailAddr);
    addChild(m_editBox);
    m_editBox->becomeFirstResponder();
}

void FMUIInputName::transitionIn(CCCallFunc* finishAction)
{
    m_panel->setScale(0.5f);
    m_panel->setVisible(true);
    CCScaleTo * s = CCScaleTo::create(0.3f, 1.f);
    CCEaseBackOut * e = CCEaseBackOut::create(s);
    CCSequence * seq = CCSequence::create(e, finishAction, NULL);
    m_panel->runAction(seq);
}
void FMUIInputName::transitionOut(CCCallFunc* finishAction)
{
    m_editBox->removeFromParent();

    m_panel->setScale(1.f);
    CCScaleTo * s = CCScaleTo::create(0.15f, 0.5f);
    CCEaseBackIn * e = CCEaseBackIn::create(s);
    CCHide * h = CCHide::create();
    CCSequence * seq = CCSequence::create(e, h, finishAction, NULL);
    m_panel->runAction(seq);
}

void FMUIInputName::clickButton(CCObject * object , CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * btn = (CCControlButton *)object;
    if (btn->getTag() == 2) {
        m_editBox->detachWithIME();
        const char* str = m_editBox->getText();
        int len = strlen(str);
        if (len == 0) {
            nameEmpty();
            return;
        }
        std::stringstream ss;
        for (int i = 0; i < len; i++) {
            ss << " ";
        }
        if (strcmp(str, ss.str().c_str()) == 0) {
            nameEmpty();
            return;
        }
        FMDataManager::sharedManager()->setUserName(str);
        OBJCHelper::helper()->postRequest(NULL, NULL, kPostType_SyncInfo);
        GAMEUI_Scene::uiSystem()->closeDialog();
        if (!m_isRename) {
            FMUIInvite * window = (FMUIInvite *)FMDataManager::sharedManager()->getUI(kUI_Invite);
            window->setClassState(1);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
    }
    else if (btn->getTag() == 0) {
        GAMEUI_Scene::uiSystem()->closeDialog();
    }
}

//bool FMUIInputName::onTextFieldInsertText(CCTextFieldTTF * sender, const char * text, int nLen)
//{
//    if (strcmp(text, "\n") == 0) {
//        m_textfield->detachWithIME();
//        return true;
//    }
//    int len = strlen(m_textfield->getString());
//    if (len + nLen > 12) {
//        return true;
//    }
//    return false;
//}

void FMUIInputName::editBoxReturn(CCEditBox* editBox)
{
    m_editBox->detachWithIME();
}

void FMUIInputName::nameEmpty()
{
    m_editBox->setText("");
    m_editBox->setPlaceHolder("昵称不能为空");
}
void FMUIInputName::nameLength()
{
    m_editBox->setPlaceHolder("1-8个字");
}
