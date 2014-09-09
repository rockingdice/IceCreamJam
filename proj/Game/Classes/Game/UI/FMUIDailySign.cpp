//
//  FMUIDailySign.cpp
//  JellyMania
//
//  Created by lipeng on 14-8-16.
//
//

#include "FMUIDailySign.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMGameNode.h"
#include "SNSFunction.h"


FMUIDailySign::FMUIDailySign():
m_instantMove(false),
m_parentNode(NULL),
m_botLabel(NULL),
m_rewardNode(NULL),
m_isChecked(false)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUILoginSign.ccbi", this);
    addChild(m_ccbNode);
    
    m_botLabel->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    m_botLabel->setWidth(240);
}

FMUIDailySign::~FMUIDailySign()
{
}

#pragma mark - CCB Bindings
bool FMUIDailySign::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_botLabel", CCLabelBMFont *, m_botLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_rewardNode", CCNode *, m_rewardNode);
    return true;
}

SEL_CCControlHandler FMUIDailySign::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIDailySign::clickButton);
    return NULL;
}

void FMUIDailySign::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    if (m_isChecked) {
        return;
    }
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    m_isChecked = true;
    FMDataManager * manager = FMDataManager::sharedManager();
    if (manager->getLoginReward()) {
        checkIn();
    }
}

void FMUIDailySign::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIDailySign::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUIDailySign::onEnter()
{
    GAMEUI_Window::onEnter();
    m_isChecked = false;
    updateUI();
}

void FMUIDailySign::updateUI()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    CCArray * list = manager->getLoginRewardStatus();
    int index = manager->getTodaysLoginIndex();
    for (int i = 0; i < 25; i++) {
        CCNode * node = m_rewardNode->getChildByTag(i);
        CCBAnimationManager * rewardAnim = (CCBAnimationManager *)node->getUserObject();
        if (i > index) {
            rewardAnim->runAnimationsForSequenceNamed("future");
        }else if (i == index){
            rewardAnim->runAnimationsForSequenceNamed("today");
        }else if (i >= list->count()){
            rewardAnim->runAnimationsForSequenceNamed("unsigned");
        }else{
            CCNumber * n = (CCNumber *)list->objectAtIndex(i);
            if (n->getIntValue() == 0) {
                rewardAnim->runAnimationsForSequenceNamed("unsigned");
            }else{
                rewardAnim->runAnimationsForSequenceNamed("signed");
            }
        }
        CCLabelBMFont * label = (CCLabelBMFont *)node->getChildByTag(2);
        label->setString(CCString::createWithFormat("%d",i+1)->getCString());
        
        std::vector<int> reward = manager->getRewardInfoForIndex(i);
        int type = reward[0];
        int amount = reward[1];
        if (type == -1 || amount == -1) {
            continue;
        }
        
        CCNode * n = node->getChildByTag(0);
        CCBAnimationManager * anim = (CCBAnimationManager *)n->getUserObject();
        anim->runAnimationsForSequenceNamed(CCString::createWithFormat("%d",type)->getCString());
        
        label = (CCLabelBMFont *)node->getChildByTag(1);
        if (type == kBooster_UnlimitLife) {
            label->setString(CCString::createWithFormat(manager->getLocalizedString("V170_MINUTES_(D)"),amount)->getCString());
        }else{
            label->setString(CCString::createWithFormat("x%d",amount)->getCString());
        }
    }
}
void FMUIDailySign::delayCheckIn()
{
    CCDelayTime * delay = CCDelayTime::create(0.3f);
    CCCallFunc * call = CCCallFunc::create(this, callfunc_selector(FMUIDailySign::checkIn));
    runAction(CCSequence::create(delay,call,NULL));
}

void FMUIDailySign::checkIn()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    int index = manager->getTodaysLoginIndex();
    CCNode * node = m_rewardNode->getChildByTag(index);
    NEAnimNode * ani = (NEAnimNode *)node->getChildByTag(3);
    ani->setVisible(true);
//    CCBAnimationManager * rewardAnim = (CCBAnimationManager *)node->getUserObject();
    ani->setDelegate(this);
    ani->playAnimation("Stamp");
}

void FMUIDailySign::animationEnded(neanim::NEAnimNode *node, const char *animName)
{
//    FMDataManager * manager = FMDataManager::sharedManager();
//    int index = manager->getTodaysLoginIndex();
    CCNode * pnode = node->getParent();
    CCBAnimationManager * rewardAnim = (CCBAnimationManager *)pnode->getUserObject();
    rewardAnim->runAnimationsForSequenceNamed("signed");
    
    CCDelayTime * delay = CCDelayTime::create(0.1f);
    CCCallFunc * call = CCCallFunc::create(this, callfunc_selector(FMUIDailySign::checkInSuccess));
    runAction(CCSequence::create(delay,call,NULL));
}

void FMUIDailySign::checkInSuccess()
{
    FMDataManager::sharedManager()->getLoginRewardSuccess();
}
