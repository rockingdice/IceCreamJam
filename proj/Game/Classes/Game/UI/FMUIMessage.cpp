//
//  FMUIMessage.cpp
//  JellyMania
//
//  Created by lipeng on 14-4-26.
//
//

#include "FMUIMessage.h"
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


FMUIMessage::FMUIMessage():
m_instantMove(false),
m_parentNode(NULL),
m_checkNode(NULL),
m_tipLabel(NULL),
m_acceptButton(NULL),
m_loading(NULL),
m_isloading(false)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIMessageBox.ccbi", this);
    addChild(m_ccbNode);
    
    CCSize winSize = CCSize(265, 220);
    CCSize cullingSize = CCSize(500, 220);
    GUIScrollSlider * slider = new GUIScrollSlider(winSize, CCRect(-cullingSize.width * 0.5f, -cullingSize.height * 0.5f + 5.f, cullingSize.width, cullingSize.height), 45.f, this, true);
    slider->setPosition(ccp(0, -10));
    m_slider = slider;
    m_parentNode->addChild(slider, 10);
    
    m_tipLabel->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    m_tipLabel->setWidth(220);
    m_tipLabel->setAlignment(kCCTextAlignmentCenter);
    
    NEAnimNode * anode = m_acceptButton->getAnimNode();
    anode->releaseControl("Label", kProperty_FNTFile);
    CCLabelBMFont * label = (CCLabelBMFont *)anode->getNodeByName("Label");
    label->setFntFile("font_2.fnt");
}

FMUIMessage::~FMUIMessage()
{
}

#pragma mark - CCB Bindings
bool FMUIMessage::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_checkNode", CCSprite *, m_checkNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_tipLabel", CCLabelBMFont *, m_tipLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_acceptButton", CCAnimButton *, m_acceptButton);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_loading", NEAnimNode *, m_loading);
    return true;
}

SEL_CCControlHandler FMUIMessage::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIMessage::clickButton);
    return NULL;
}

void FMUIMessage::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIMessage::clickButton(cocos2d::CCObject *object, CCControlEvent event)
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
            bool allselected = true;
            for (int i = 0; i < OBJCHelper::helper()->getAllFBMessage()->count(); i++) {
                CCDictionary * dic = (CCDictionary *)OBJCHelper::helper()->getAllFBMessage()->objectAtIndex(i);
                CCNumber * isSelect = (CCNumber *)dic->objectForKey("select");
                if (!isSelect || isSelect->getIntValue() == 0) {
                    allselected = false;
                    break;
                }
            }
            
            for (int i = 0; i < OBJCHelper::helper()->getAllFBMessage()->count(); i++) {
                CCDictionary * dic = (CCDictionary *)OBJCHelper::helper()->getAllFBMessage()->objectAtIndex(i);
                if (allselected) {
                    dic->setObject(CCNumber::create(0), "select");
                }else{
                    dic->setObject(CCNumber::create(1), "select");
                }
            }
            updateUI();
        }
            break;
        case 2:
        {
            OBJCHelper::helper()->acceptFBRequest();
            updateUI();
        }
            break;
        case 3:
        {
            int rowIndex = button->getParent()->getParent()->getParent()->getTag();
            CCDictionary * dic = (CCDictionary *)OBJCHelper::helper()->getAllFBMessage()->objectAtIndex(rowIndex);
            CCNumber * select = (CCNumber *)dic->objectForKey("select");
            if (!select) {
                select = CCNumber::create(0);
            }
            if (select->getIntValue() == 0) {
                select->setValue(1);
            }else{
                select->setValue(0);
            }
            dic->setObject(select, "select");
            
            CCSprite * selectSpr = (CCSprite *)button->getParent()->getChildByTag(1);
            selectSpr->setVisible(select->getIntValue() != 0);
            
            if (select->getIntValue() == 0) {
                m_checkNode->setVisible(false);
            }
        }
            break;
        default:
            break;
    }
}

void FMUIMessage::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIMessage::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUIMessage::onEnter()
{
    GAMEUI_Window::onEnter();
    
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
    if( SNSFunction_isFacebookConnected() ){
        m_isloading = OBJCHelper::helper()->getFacebookMessages();
        updateUI();
    } else updateUI(false);
#else
    m_isloading = OBJCHelper::helper()->getFacebookMessages();
    updateUI();
#endif
}

void FMUIMessage::updateUI(bool loading)
{
    m_isloading = loading;
    bool allselected = true;
    for (int i = 0; i < OBJCHelper::helper()->getAllFBMessage()->count(); i++) {
        CCDictionary * dic = (CCDictionary *)OBJCHelper::helper()->getAllFBMessage()->objectAtIndex(i);
        CCNumber * isSelect = (CCNumber *)dic->objectForKey("select");
        if (!isSelect || isSelect->getIntValue() == 0) {
            allselected = false;
            break;
        }
    }
    if (allselected) {
        m_checkNode->setVisible(true);
    }else{
        m_checkNode->setVisible(false);
    }

    m_slider->refresh();
    CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
    if (OBJCHelper::helper()->getAllFBMessage()->count() == 0) {
        anim->runAnimationsForSequenceNamed("NoMsg");
    }else{
        anim->runAnimationsForSequenceNamed("Init");
    }
    
    m_loading->setVisible(m_isloading && OBJCHelper::helper()->getAllFBMessage()->count() == 0);
    m_tipLabel->setVisible(!m_isloading && OBJCHelper::helper()->getAllFBMessage()->count() == 0);
}

#pragma mark - slider delegate
CCNode * FMUIMessage::createItemForSlider(GUIScrollSlider *slider)
{
    CCNode * node = FMDataManager::sharedManager()->createNode("UI/FMUIMessageItem.ccbi", this);
    return node;
}

int FMUIMessage::itemsCountForSlider(GUIScrollSlider *slider)
{
    return OBJCHelper::helper()->getAllFBMessage()->count();
}

void FMUIMessage::sliderUpdate(GUIScrollSlider *slider, int rowIndex, cocos2d::CCNode *node)
{
    node->setTag(rowIndex);
    CCDictionary * dic = (CCDictionary*)OBJCHelper::helper()->getAllFBMessage()->objectAtIndex(rowIndex);
    CCString * uid = (CCString *)dic->objectForKey("uid");
    CCString * data = (CCString *)dic->objectForKey("data");
    CCString * name = (CCString *)dic->objectForKey("name");
    CCNumber * select = (CCNumber *)dic->objectForKey("select");
    if (!select) {
        select = CCNumber::create(0);
    }
    CCNode * parentNode = node->getChildByTag(0)->getChildByTag(0);
    
    CCSprite * selectSpr = (CCSprite *)parentNode->getChildByTag(1);
    selectSpr->setVisible(select->getIntValue() != 0);
    
    CCNode * avatar = parentNode->getChildByTag(0);
    avatar->removeChildByTag(10);
    
    const char * icon = SNSFunction_getFacebookIcon(uid->getCString());
    avatar->removeChildByTag(10);
    if (icon && FMDataManager::sharedManager()->isFileExist(icon)){
        CCSprite * spr = CCSprite::create(icon);
        float size = 52.f;
        spr->setScale(size / MAX(spr->getContentSize().width, size));
        avatar->addChild(spr, 0, 10);
        spr->setPosition(ccp(avatar->getContentSize().width/2, avatar->getContentSize().height/2));
    }

    CCLabelTTF * namelabel = (CCLabelTTF *)parentNode->getChildByTag(2);
    namelabel->setString(name->getCString());
    
    CCLabelBMFont * msglabel = (CCLabelBMFont *)parentNode->getChildByTag(3);
    if (strcmp(data->getCString(), "need") == 0) {
        msglabel->setString(FMDataManager::sharedManager()->getLocalizedString("V140_FB_NEED"));
    }else if (strcmp(data->getCString(), "gift") == 0){
        msglabel->setString(FMDataManager::sharedManager()->getLocalizedString("V140_FB_GIFT"));
    }else{
        msglabel->setString("");
    }
}
