//
//  DailyBox.cpp
//  JellyMania
//
//  Created by lipeng on 14-8-15.
//
//

#include "DailyBox.h"
#include "FMDataManager.h"
#include "SNSFunction.h"
#include "GAMEUI_Scene.h"


DailyBox * DailyBox::creat()
{
    DailyBox * node = new DailyBox();
    if (node) {
        node->autorelease();
        return node;
    }
    CC_SAFE_DELETE(node);
    return NULL;
}

DailyBox::DailyBox()
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIDailyBox.ccbi", NULL);
    addChild(m_ccbNode);
    
    scheduleUpdate();
}

DailyBox::~DailyBox()
{
}

void DailyBox::update(float delta)
{
    FMDataManager * manager = FMDataManager::sharedManager();
    int time = manager->getDailyLevelRewardTime();
    if (time > 0) {
        setVisible(true);
        CCLabelBMFont * label = (CCLabelBMFont *)m_ccbNode->getChildByTag(1);
        int remainTime = manager->getRemainTime(time);
        label->setString(CCString::createWithFormat("%02d:%02d",remainTime/60,remainTime%60)->getCString());
    }else{
        setVisible(false);
    }
}

bool DailyBox::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    return true;
}

SEL_CCControlHandler DailyBox::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    return NULL;
}
