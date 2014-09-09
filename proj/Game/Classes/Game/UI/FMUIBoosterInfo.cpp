//
//  FMUIBoosterInfo.cpp
//  FarmMania
//
//  Created by  James Lee on 13-6-6.
//
//

#include "FMUIBoosterInfo.h"


#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "FMUIBooster.h"
extern boosterDataStruct boostersData[6];
FMUIBoosterInfo::FMUIBoosterInfo() :
    m_panel(NULL),
    m_parentNode(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIBoosterInfo.ccbi", this);
    addChild(m_ccbNode);
    
    CCSize winSize = CCSize(250, 280);
    CCSize cullingSize = CCSize(500, 280);
    GUIScrollSlider * slider = new GUIScrollSlider(winSize, CCRect(-cullingSize.width * 0.5f, -cullingSize.height * 0.5f, cullingSize.width, cullingSize.height), 80.f, this, true);
    slider->setPosition(ccp(0.f, -10.f));
    m_parentNode->addChild(slider);
}

FMUIBoosterInfo::~FMUIBoosterInfo()
{
    
}

#pragma mark - CCB Bindings
bool FMUIBoosterInfo::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_panel", CCNode *, m_panel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    return true;
}

SEL_CCControlHandler FMUIBoosterInfo::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIBoosterInfo::clickButton);
    return NULL;
}

void FMUIBoosterInfo::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    switch (button->getTag()) {
        case 0:
        {
            //close
            GAMEUI_Scene::uiSystem()->closeDialog();
        }
            break;
        default:
            break;
    }
}

 

void FMUIBoosterInfo::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    m_panel->setScale(0.5f);
    m_panel->setVisible(true);
    CCScaleTo * s = CCScaleTo::create(0.3f, 1.f);
    CCEaseBackOut * e = CCEaseBackOut::create(s);
    CCSequence * seq = CCSequence::create(e, finishAction, NULL);
    m_panel->runAction(seq);
}

void FMUIBoosterInfo::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    m_panel->setScale(1.f);
    CCScaleTo * s = CCScaleTo::create(0.15f, 0.5f);
    CCEaseBackIn * e = CCEaseBackIn::create(s);
    CCHide * h = CCHide::create();
    CCSequence * seq = CCSequence::create(e, h, finishAction, NULL);
    m_panel->runAction(seq);
}


#pragma mark - slider delegate
CCNode * FMUIBoosterInfo::createItemForSlider(GUIScrollSlider *slider)
{
    CCNode * node = FMDataManager::sharedManager()->createNode("UI/FMUIBoosterInfoItem.ccbi", this);    
    return node;
}

int FMUIBoosterInfo::itemsCountForSlider(GUIScrollSlider *slider)
{
    return 6;
}

void FMUIBoosterInfo::sliderUpdate(GUIScrollSlider *slider, int rowIndex, cocos2d::CCNode *node)
{
    CCNode * parent = node;
    kGameBooster boosterType = (kGameBooster)rowIndex;
    CCLabelBMFont * info = (CCLabelBMFont *)parent->getChildByTag(1);
    info->setWidth(135.f);
    info->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());

    
    const char * s = FMDataManager::sharedManager()->getLocalizedString(boostersData[boosterType].info);
    info->setString(s);
    
    NEAnimNode * booster = (NEAnimNode *)parent->getChildByTag(0);
    booster->playAnimation("Init");
    kGameBooster type = (kGameBooster)(rowIndex);
    booster->useSkin(FMGameNode::getBoosterSkin(type));
}

void FMUIBoosterInfo::keyBackClicked(void)
{
    //close
    GAMEUI_Scene::uiSystem()->closeDialog();
}
