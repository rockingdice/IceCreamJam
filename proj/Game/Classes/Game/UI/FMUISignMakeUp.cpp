//
//  FMUISignMakeUp.cpp
//  JellyMania
//
//  Created by lipeng on 14-8-16.
//
//

#include "FMUISignMakeUp.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "OBJCHelper.h"
#include "SNSFunction.h"


FMUISignMakeUp::FMUISignMakeUp():
m_panel(NULL),
m_dayLabel(NULL),
m_priceLabel(NULL),
m_label(NULL),
m_title(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIMakeUpSign.ccbi", this);
    addChild(m_ccbNode);
    
    CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
#ifdef BRANCH_CN
    anim->runAnimationsForSequenceNamed("CN");
#else
    anim->runAnimationsForSequenceNamed("tip");
#endif
    
    m_title->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    m_title->setWidth(160);
    m_title->setAlignment(kCCTextAlignmentCenter);
    
    m_label->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    m_label->setWidth(185);
    m_label->setAlignment(kCCTextAlignmentCenter);
}

FMUISignMakeUp::~FMUISignMakeUp()
{
}

#pragma mark - CCB Bindings
bool FMUISignMakeUp::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_panel", CCNode *, m_panel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_label", CCLabelBMFont *, m_label);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_dayLabel", CCLabelBMFont *, m_dayLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_priceLabel", CCLabelBMFont *, m_priceLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_title", CCLabelBMFont *, m_title);
    return true;
}

SEL_CCControlHandler FMUISignMakeUp::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUISignMakeUp::clickButton);
    return NULL;
}

void FMUISignMakeUp::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    FMDataManager * manager = FMDataManager::sharedManager();
    int tag = button->getTag();
    switch (tag) {
        case 0:
        {
            //close
        }
            break;
        case 1:
        {
            manager->setLoginRewardStatus(false, true);
        }
            break;
        case 2:
        {
            manager->setLoginRewardStatus(true, true);
        }
            break;
        default:
            break;
    }
    GAMEUI_Scene::uiSystem()->closeDialog();
}

void FMUISignMakeUp::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    m_panel->setScale(0.5f);
    m_panel->setVisible(true);
    CCScaleTo * s = CCScaleTo::create(0.3f, 1.f);
    CCEaseBackOut * e = CCEaseBackOut::create(s);
    CCSequence * seq = CCSequence::create(e, finishAction, NULL);
    m_panel->runAction(seq);
}

void FMUISignMakeUp::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    m_panel->setScale(1.f);
    CCScaleTo * s = CCScaleTo::create(0.15f, 0.5f);
    CCEaseBackIn * e = CCEaseBackIn::create(s);
    CCHide * h = CCHide::create();
    CCSequence * seq = CCSequence::create(e, h, finishAction, NULL);
    m_panel->runAction(seq);
}

void FMUISignMakeUp::onEnter()
{
    GAMEUI_Dialog::onEnter();
    FMDataManager * manager = FMDataManager::sharedManager();
    
    int index = manager->getTodaysLoginIndex();
    CCArray * list = manager->getLoginRewardStatus();
    int d = index-list->count();
    m_title->setString(CCString::createWithFormat(manager->getLocalizedString("V170_MAKEUP_TITLE_(D)"),d)->getCString());
    
    m_label->setString(manager->getLocalizedString("V170_MAKEUP_TIP_(D)"));
    
    m_dayLabel->setString(CCString::createWithFormat(manager->getLocalizedString("V170_MAKEUP_(D)"),index+1)->getCString());
    
    m_priceLabel->setString(CCString::createWithFormat("%d",manager->getSignSkipGold(index))->getCString());
}
