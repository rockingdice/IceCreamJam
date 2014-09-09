//
//  FMUISpinReward.cpp
//  JellyMania
//
//  Created by lipeng on 14-4-23.
//
//

#include "FMUISpinReward.h"
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


FMUISpinReward::FMUISpinReward():
m_panel(NULL),
m_parentNode(NULL),
m_shareButton(NULL),
m_nameLabel(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUISpinReward.ccbi", this);
    addChild(m_ccbNode);
}

FMUISpinReward::~FMUISpinReward()
{
}

#pragma mark - CCB Bindings
bool FMUISpinReward::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_panel", CCNode *, m_panel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_nameLabel", CCLabelBMFont *, m_nameLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_shareButton", CCAnimButton *, m_shareButton);
    return true;
}

SEL_CCControlHandler FMUISpinReward::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUISpinReward::clickButton);
    return NULL;
}

void FMUISpinReward::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        //close
        GAMEUI_Scene::uiSystem()->closeDialog();
    }
}

void FMUISpinReward::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    int tag = button->getTag();
    switch (tag) {
        case 0:
        {
            //close
            GAMEUI_Scene::uiSystem()->closeDialog();
        }
            break;
        case 1:
        {
            //share
            CCArray * dic = (CCArray *)button->getUserObject();
            if (dic) {
                OBJCHelper::helper()->publicFBDailyBonus(dic);
            }
        }
            break;
        default:
            break;
    }
}

void FMUISpinReward::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    m_panel->setScale(0.5f);
    m_panel->setVisible(true);
    CCScaleTo * s = CCScaleTo::create(0.3f, 1.f);
    CCEaseBackOut * e = CCEaseBackOut::create(s);
    CCSequence * seq = CCSequence::create(e, finishAction, NULL);
    m_panel->runAction(seq);
}

void FMUISpinReward::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    m_panel->setScale(1.f);
    CCScaleTo * s = CCScaleTo::create(0.15f, 0.5f);
    CCEaseBackIn * e = CCEaseBackIn::create(s);
    CCHide * h = CCHide::create();
    CCSequence * seq = CCSequence::create(e, h, finishAction, NULL);
    m_panel->runAction(seq);
}
void FMUISpinReward::setReward(CCArray * dic)
{
    FMDataManager * manager = FMDataManager::sharedManager();
    m_shareButton->setUserObject(dic);
    int type = ((CCNumber *)dic->objectAtIndex(0))->getIntValue();
    int amount = ((CCNumber *)dic->objectAtIndex(1))->getIntValue();
    const char * name = manager->getLocalizedString(CCString::createWithFormat("V100_BOOSTER_%d",type)->getCString());
    CCString * amountStr = CCString::createWithFormat("x%d",amount);
    CCNode * animNode = m_parentNode->getChildByTag(11);
    CCSprite * picNode = (CCSprite *)m_parentNode->getChildByTag(10);
    if (type == kBooster_FreeSpin) {
        animNode->setVisible(false);
        picNode->setVisible(true);
        picNode->setScale(1.2f);
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("FreeSpin.png");
        picNode->setDisplayFrame(frame);
    }
    else if (type == kBooster_UnlimitLife){
        animNode->setVisible(false);
        picNode->setScale(1.f);
        picNode->setVisible(true);
        
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("unlimit_life_icon.png");
        picNode->setDisplayFrame(frame);
        amountStr = CCString::createWithFormat("%d h",amount);
    }
    else if (type == kBooster_Gold){
        animNode->setVisible(false);
        picNode->setVisible(true);
        picNode->setScale(1.f);
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_gold1.png");
        picNode->setDisplayFrame(frame);
    }
    else if (type == kBooster_Life){
        animNode->setVisible(false);
        picNode->setScale(1.4f);
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
    }
    CCString * nstring = CCString::createWithFormat("%s %s",name,amountStr->getCString());
    m_nameLabel->setString(nstring->getCString());
}
void FMUISpinReward::onEnter()
{
    GAMEUI_Dialog::onEnter();
}
