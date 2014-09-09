//
//  FMUISpinReward.h
//  JellyMania
//
//  Created by lipeng on 14-4-23.
//
//

#ifndef __JellyMania__FMUISpinReward__
#define __JellyMania__FMUISpinReward__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "CCAnimButton.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMUISpinReward : public GAMEUI_Dialog , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUISpinReward();
    ~FMUISpinReward();
private:
    CCNode * m_panel;
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    CCLabelBMFont * m_nameLabel;
    CCAnimButton * m_shareButton;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUISpinReward";}
    void setReward(CCArray * dic);
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void keyBackClicked();
    virtual void onEnter();
};




#endif /* defined(__JellyMania__FMUISpinReward__) */
