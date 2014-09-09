//
//  FMUIPrizeList.cpp
//  JellyMania
//
//  Created by lipeng on 14-4-23.
//
//

#include "FMUIPrizeList.h"
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


FMUIPrizeList::FMUIPrizeList():
m_instantMove(false),
m_parentNode(NULL),
m_list(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIPrizeList.ccbi", this);
    addChild(m_ccbNode);
    
    m_list = FMDataManager::sharedManager()->getAllSpinPrizes();
    m_list->retain();
    
    CCSize winSize = CCSize(250, 265);
    CCSize cullingSize = CCSize(500, 275);
    GUIScrollSlider * slider = new GUIScrollSlider(winSize, CCRect(-cullingSize.width * 0.5f, -cullingSize.height * 0.5f + 5.f, cullingSize.width, cullingSize.height), 50.f, this, true);
    slider->setPosition(ccp(0.f, -10.f));
    m_slider = slider;
    m_parentNode->addChild(slider, 10);
}

FMUIPrizeList::~FMUIPrizeList()
{
    m_list->release();
}

#pragma mark - CCB Bindings
bool FMUIPrizeList::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    return true;
}

SEL_CCControlHandler FMUIPrizeList::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIPrizeList::clickButton);
    return NULL;
}

void FMUIPrizeList::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        //close
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIPrizeList::clickButton(cocos2d::CCObject *object, CCControlEvent event)
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
        default:
            break;
    }
}

void FMUIPrizeList::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIPrizeList::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUIPrizeList::onEnter()
{
    GAMEUI_Window::onEnter();
    updateUI();
}

void FMUIPrizeList::updateUI()
{
    m_slider->refresh();
}

#pragma mark - slider delegate
CCNode * FMUIPrizeList::createItemForSlider(GUIScrollSlider *slider)
{
    CCNode * node = FMDataManager::sharedManager()->createNode("UI/FMUIPrizeListItem.ccbi", this);
    return node;
}

int FMUIPrizeList::itemsCountForSlider(GUIScrollSlider *slider)
{
    return m_list->count();
}

void FMUIPrizeList::sliderUpdate(GUIScrollSlider *slider, int rowIndex, cocos2d::CCNode *node)
{
    FMDataManager * manager = FMDataManager::sharedManager();
    CCArray * t = (CCArray *)m_list->objectAtIndex(rowIndex);
    if (!t) {
        return;
    }
    int type = ((CCNumber *)t->objectAtIndex(0))->getIntValue();
    int amount = ((CCNumber *)t->objectAtIndex(1))->getIntValue();
    const char * name = manager->getLocalizedString(CCString::createWithFormat("V100_BOOSTER_%d",type)->getCString());
    CCNode * pNode = node->getChildByTag(0);
    CCNode * animNode = pNode->getChildByTag(0);
    CCSprite * picNode = (CCSprite *)pNode->getChildByTag(1);
    CCLabelBMFont * label = (CCLabelBMFont *)pNode->getChildByTag(2);
    label->setString(CCString::createWithFormat("%s x%d",name,amount)->getCString());
//    int index = manager->getGlobalIndex(manager->getFurthestWorld(), manager->getFurthestLevel());
//    if (spinData[rowIndex].unlock >= index) {
//        label->setString(CCString::createWithFormat(manager->getLocalizedString("V140_LEVEL(D)_UNLOCK"),spinData[rowIndex].unlock)->getCString());
//    }
    if (type == kBooster_FreeSpin) {
        animNode->setVisible(false);
        picNode->setScale(1.f);
        picNode->setVisible(true);
        
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("FreeSpin.png");
        picNode->setDisplayFrame(frame);
    }
    else if (type == kBooster_UnlimitLife){
        animNode->setVisible(false);
        picNode->setScale(1.f);
        picNode->setVisible(true);
        
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("unlimit_life_icon.png");
        picNode->setDisplayFrame(frame);
        label->setString(CCString::createWithFormat("%s %dh",FMDataManager::sharedManager()->getLocalizedString(name                                                                                                                                                                                                                                                                                                                             ),amount)->getCString());
        
    }
    else if (type == kBooster_Gold){
        animNode->setVisible(false);
        picNode->setScale(0.8f);
        picNode->setVisible(true);
        
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_gold1.png");
        picNode->setDisplayFrame(frame);
    }
    else if (type == kBooster_Life){
        animNode->setVisible(false);
        picNode->setScale(1.2f);
        picNode->setVisible(true);
        
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_life0.png");
        picNode->setDisplayFrame(frame);
    }
    else{
        const char * skin = FMGameNode::getBoosterSkin((kGameBooster)type);
        NEAnimNode * n = (NEAnimNode *)animNode;
        n->useSkin(skin);
        animNode->setVisible(true);
        picNode->setVisible(false);
        animNode->setScale(0.8f);
    }
}

