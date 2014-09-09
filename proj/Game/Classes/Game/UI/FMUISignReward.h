//
//  FMUISignReward.h
//  JellyMania
//
//  Created by lipeng on 14-8-16.
//
//

#ifndef __JellyMania__FMUISignReward__
#define __JellyMania__FMUISignReward__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "CCAnimButton.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMUISignReward : public GAMEUI_Dialog , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUISignReward();
    ~FMUISignReward();
private:
    bool m_instantMove;
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    CCLabelBMFont * m_nameLabel;
    CCAnimButton * m_shareButton;
    CCNode * m_rewardNode;
    CCNode * m_panel;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUISignReward";}
    void setReward(std::vector<int> vector);
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void onEnter();
};

#endif /* defined(__JellyMania__FMUISignReward__) */
