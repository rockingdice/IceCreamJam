//
//  FMStoryScene.cpp
//  JellyMania
//
//  Created by lipeng on 14-8-11.
//
//

#include "FMStoryScene.h"
#include "FMMainScene.h"
#include "FMDataManager.h"
#include "FMWorldMapNode.h"


CCScene* FMStoryScene::scene()
{
    FMStoryScene * storyLayer = FMStoryScene::create();
    CCSize size = CCDirector::sharedDirector()->getWinSize();
    storyLayer->setContentSize(size);
    
    CCScene* sc = CCScene::create();
    sc->addChild(storyLayer);
    
    return sc;
    
}

FMStoryScene::FMStoryScene()
:m_animNode(NULL),
m_skipButton(NULL)
{
    FMDataManager * manager = FMDataManager::sharedManager();
    
    CCNode * node = manager->createNode("UI/FMStoryScene.ccbi", this);
    addChild(node);
    
    m_animNode->setDelegate(this);
}


void FMStoryScene::clickSkip()
{
    m_animNode->setDelegate(NULL);
    
    m_skipButton->setVisible(false);
    m_skipButton->setEnabled(false);
    
    m_animNode->playAnimation("Animation1");
    
    stopAllActions();
    
    CCDelayTime * delay = CCDelayTime::create(2.6f);
    CCCallFunc * call = CCCallFunc::create(this, callfunc_selector(FMStoryScene::swithToGameScene));
    runAction(CCSequence::create(delay,call,NULL));
}

void FMStoryScene::swithToGameScene()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    FMMainScene *pScene = (FMMainScene *)manager->getUI(kUI_MainScene);
    
    manager->setLevel(0, 0, false);
    manager->useLife();
    pScene->switchScene(kGameNode);

    CCDirector::sharedDirector()->replaceScene(pScene);
}



#pragma mark - CCB Bindings
bool FMStoryScene::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_animNode", NEAnimNode *, m_animNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_skipButton", CCAnimButton *, m_skipButton);
    return true;
}

SEL_CCControlHandler FMStoryScene::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickSkip", FMStoryScene::clickSkip);
    return NULL;
}



#pragma mark - animation callback
void FMStoryScene::animationEnded(NEAnimNode * node, const char *animName)
{
    if (strcmp(animName, "Animation0") == 0) {
        clickSkip();
    }
}

void FMStoryScene::animationCallback(NEAnimNode * node, const char *animName, const char *callback)
{
    
}











