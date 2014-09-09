//
//  FMUIStarReward.h
//  JellyMania
//
//  Created by ywthahaha on 14-4-17.
//
//

#ifndef __JellyMania__FMUIStarReward__
#define __JellyMania__FMUIStarReward__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIStarReward : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIStarReward();
    ~FMUIStarReward();
private:
    CCNode * m_ccbNode;
    CCSprite * m_iconSprite;
    CCLabelBMFont * m_amountLabel;
    CCLabelBMFont * m_infoLabel;
    
    int m_boosterType;
    int m_boosterCount;
    
    
protected:
    virtual const char * classType() {return "FMUIStarReward";}
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual void onEnter();
    virtual void onExit();
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void transitionInDone();
    void updateUI(int index);
    void continueShowReward();
    
public:
    virtual void setClassState(int state);
    void clickButton(CCObject * object , CCControlEvent event);
};




#endif /* defined(__JellyMania__FMUIStarReward__) */
