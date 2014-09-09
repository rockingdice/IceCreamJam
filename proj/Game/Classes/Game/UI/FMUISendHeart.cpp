//
//  FMUISendHeart.cpp
//  JellyMania
//
//  Created by lipeng on 14-8-7.
//
//

#include "FMUISendHeart.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "SNSFunction.h"
#include "FMUIWorldMap.h"
#include "FMUIRestore.h"
#include "FMUIConfig.h"
#include "FMStatusbar.h"
#include "FMUISpin.h"


FMUISendHeart::FMUISendHeart():
m_instantMove(false),
m_parentNode(NULL),
m_topLabel(NULL),
m_botLabel(NULL),
m_sendButton(NULL),
m_friends(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIKakaoSendHeart.ccbi", this);
    addChild(m_ccbNode);
    
    CCSize winSize = CCSize(265, 210);
    CCSize cullingSize = CCSize(500, 210);
    GUIScrollSlider * slider = new GUIScrollSlider(winSize, CCRect(-cullingSize.width * 0.5f, -cullingSize.height * 0.5f + 5.f, cullingSize.width, cullingSize.height), 72.f, this, true);
    slider->setPosition(ccp(0, -30));
    m_slider = slider;
    m_parentNode->addChild(slider, 10);
    
    m_topLabel->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    m_topLabel->setWidth(160);
    m_topLabel->setAlignment(kCCTextAlignmentCenter);
    
    m_botLabel->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    m_botLabel->setWidth(120);
    m_botLabel->setAlignment(kCCTextAlignmentCenter);

//    NEAnimNode * closeNode = m_sendButton->getAnimNode();
//    closeNode->releaseControl("Label", kProperty_FNTFile);
//    closeNode->releaseControl("Label", kProperty_Position);
//    CCLabelBMFont * closelabel = (CCLabelBMFont *)closeNode->getNodeByName("Label");
//    closelabel->setFntFile("font_2.fnt");
//    closelabel->setPosition(ccp(10, closelabel->getPosition().y));

    m_friends = CCArray::create();
    m_friends->retain();
}

FMUISendHeart::~FMUISendHeart()
{
    CC_SAFE_RELEASE(m_friends);
}

#pragma mark - CCB Bindings
bool FMUISendHeart::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_topLabel", CCLabelBMFont *, m_topLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_botLabel", CCLabelBMFont *, m_botLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_sendButton", CCAnimButton *, m_sendButton);
    return true;
}

SEL_CCControlHandler FMUISendHeart::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUISendHeart::clickButton);
    return NULL;
}

void FMUISendHeart::clickButton(cocos2d::CCObject *object, CCControlEvent event)
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
        case 3:
        {
            int ptag = button->getParent()->getParent()->getTag();
            int row = button->getParent()->getParent()->getParent()->getParent()->getParent()->getTag();
            int index = row*3+ptag;
            
            CCDictionary * dic = (CCDictionary *)m_friends->objectAtIndex(index);
            CCNumber * select = (CCNumber *)dic->objectForKey("select");
            CCNode * check = button->getParent()->getChildByTag(2);
            if (select->getIntValue() == 0) {
                select->setValue(1);
                check->setVisible(true);
            }else{
                select->setValue(0);
                check->setVisible(false);
            }
        }
            break;
        case 5:
        {
            std::stringstream ss;
            for (int i = 0; i < m_friends->count(); i++) {
                CCDictionary * dic = (CCDictionary *)m_friends->objectAtIndex(i);
                CCNumber * isSelect = (CCNumber *)dic->objectForKey("select");
                if (isSelect && isSelect->getIntValue() == 1) {
                    CCString * fid = (CCString *)dic->objectForKey("fid");
                    if (ss.str().length() == 0) {
                        ss<<fid->getCString();
                    }else{
                        ss<<","<<fid->getCString();
                    }
                    m_friends->removeObjectAtIndex(i);
                    i--;
                }
            }
            if (ss.str().length() > 0) {
                OBJCHelper::helper()->sendLifeToFriend(ss.str().c_str());
            }
            m_instantMove = false;
            GAMEUI_Scene::uiSystem()->prevWindow();
        }
            break;
        default:
            break;
    }
}

void FMUISendHeart::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUISendHeart::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUISendHeart::onEnter()
{
    GAMEUI_Window::onEnter();
    
    m_friends->removeAllObjects();
    for (int i = 0; i < OBJCHelper::helper()->getAllFBFriends()->count(); i++) {
        CCDictionary * dic = (CCDictionary *)OBJCHelper::helper()->getAllFBFriends()->objectAtIndex(i);
        CCNumber * installed = (CCNumber *)dic->objectForKey("installed");
        if (installed && installed->getIntValue() == 1) {
            CCString * fid = (CCString *)dic->objectForKey("fid");
            
            if (OBJCHelper::helper()->isFrdMsgEnable(fid->getCString(), 1)) {
                dic->setObject(CCNumber::create(1), "select");
                m_friends->addObject(dic);
            }
        }
    }

    updateUI();
}

void FMUISendHeart::updateUI(bool loading)
{
    m_slider->refresh();
}

#pragma mark - slider delegate
CCNode * FMUISendHeart::createItemForSlider(GUIScrollSlider *slider)
{
    CCNode * node = FMDataManager::sharedManager()->createNode("UI/FMUIKakaoSendHeartItem.ccbi", this);
    return node;
}

int FMUISendHeart::itemsCountForSlider(GUIScrollSlider *slider)
{
    int n = m_friends->count()/3;
    if (m_friends->count()%3>0) {
        n++;
    }
    return n;
}

void FMUISendHeart::sliderUpdate(GUIScrollSlider *slider, int rowIndex, cocos2d::CCNode *node)
{
    node->setTag(rowIndex);
    for (int i = 0; i < 3; i++) {
        CCNode * n = node->getChildByTag(0)->getChildByTag(0)->getChildByTag(i);
        int index = rowIndex*3+i;
        if (index >= m_friends->count()) {
            n->setVisible(false);
            continue;
        }
        
        n->setVisible(true);
        
        CCDictionary * dic = (CCDictionary*)m_friends->objectAtIndex(index);
        CCString * uid = (CCString *)dic->objectForKey("fid");
        CCString * name = (CCString *)dic->objectForKey("name");
        
        CCNode * avatar = n->getChildByTag(0)->getChildByTag(1)->getChildByTag(1);
        avatar->removeChildByTag(10);
        
        const char * icon = SNSFunction_getFacebookIcon(uid->getCString());
        if (icon && FMDataManager::sharedManager()->isFileExist(icon)){
            CCSprite * spr = CCSprite::create(icon);
            float size = 52.f;
            spr->setScale(size / MAX(spr->getContentSize().width, size));
            avatar->addChild(spr, 0, 10);
            spr->setPosition(ccp(avatar->getContentSize().width/2, avatar->getContentSize().height/2));
        }
        
        CCLabelTTF * namelabel = (CCLabelTTF *)n->getChildByTag(0)->getChildByTag(0);
        namelabel->setString(name->getCString());
        
        CCNumber * select = (CCNumber *)dic->objectForKey("select");
        if (select->getIntValue() == 0) {
            n->getChildByTag(0)->getChildByTag(2)->setVisible(false);
        }else{
            n->getChildByTag(0)->getChildByTag(2)->setVisible(true);
        }
    }
}

