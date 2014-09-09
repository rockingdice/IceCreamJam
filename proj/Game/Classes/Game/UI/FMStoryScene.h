//
//  FMStoryScene.h
//  JellyMania
//
//  Created by lipeng on 14-8-11.
//
//

#ifndef __JellyMania__FMStoryScene__
#define __JellyMania__FMStoryScene__

#include <iostream>
#include "cocos2d.h"
#include "NEAnimNode.h"
#include "CCAnimButton.h"

USING_NS_CC;
using namespace neanim;

class FMStoryScene : public CCLayer, public NEAnimCallback, public CCBSelectorResolver, public CCBMemberVariableAssigner 
{
private:
    NEAnimNode * m_animNode;
    CCAnimButton * m_skipButton;
public:
    FMStoryScene();
    ~FMStoryScene(){;}
    CREATE_FUNC(FMStoryScene);
    
    void swithToGameScene();
    void clickSkip();
    
    static CCScene* scene();
    
private:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);

    
protected:
    virtual void animationEnded(NEAnimNode * node, const char * animName) ;
    virtual void animationCallback(NEAnimNode * node, const char * animName, const char * callback) ;

};





#endif /* defined(__JellyMania__FMStoryScene__) */
