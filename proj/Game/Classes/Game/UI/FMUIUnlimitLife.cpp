//
//  FMUIUnlimitLife.cpp
//  JellyMania
//
//  Created by lipeng on 14-4-11.
//
//

#include "FMUIUnlimitLife.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMDataManager.h"

FMUIUnlimitLife::FMUIUnlimitLife():
m_panel(NULL),
m_closeNode(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIUnlimitLife.ccbi", this);
    addChild(m_ccbNode);
}

FMUIUnlimitLife::~FMUIUnlimitLife()
{
    
}


void FMUIUnlimitLife::showWithFile(const char* fileName , const char* animName)
{
    m_panel->removeChildByTag(100);
    NEAnimNode * node = NEAnimNode::createNodeFromFile(fileName);
//    CCSize winsize = CCDirector::sharedDirector()->getWinSize();
    m_panel->addChild(node,100,100);
//    node->setPosition(ccp(winsize.width/2, winsize.height/2));
    node->playAnimation(animName);
    
    m_closeNode = node->getNodeByName("close");
}

#pragma mark - CCB Bindings
bool FMUIUnlimitLife::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_panel", CCNode *, m_panel);
    return true;
}

SEL_CCControlHandler FMUIUnlimitLife::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    return NULL;
}

void FMUIUnlimitLife::transitionIn(CCCallFunc* finishAction)
{
    m_panel->setScale(0.5f);
    m_panel->setVisible(true);
    CCScaleTo * s = CCScaleTo::create(0.3f, 1.f);
    CCEaseBackOut * e = CCEaseBackOut::create(s);
    CCSequence * seq = CCSequence::create(e, finishAction, NULL);
    m_panel->runAction(seq);
}
void FMUIUnlimitLife::transitionOut(CCCallFunc* finishAction)
{
    m_panel->setScale(1.f);
    CCScaleTo * s = CCScaleTo::create(0.15f, 0.5f);
    CCEaseBackIn * e = CCEaseBackIn::create(s);
    CCHide * h = CCHide::create();
    CCSequence * seq = CCSequence::create(e, h, finishAction, NULL);
    m_panel->runAction(seq);
}
bool FMUIUnlimitLife::ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent)
{
    return true;
}
void FMUIUnlimitLife::ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent)
{
    if (m_closeNode) {
        CCPoint p = pTouch->getLocation();
        p = m_closeNode->convertToNodeSpace(p);
        if (abs(p.x) < 50 && abs(p.y) < 30) {
            FMSound::playEffect("click.mp3", 0.1f, 0.1f);
            GAMEUI_Scene::uiSystem()->closeDialog();
        }
    }
}
