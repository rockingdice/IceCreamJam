//
//  FMUIBranchBonus.h
//  JellyMania
//
//  Created by lipeng on 14-2-11.
//
//

#ifndef __JellyMania__FMUIBranchBonus__
#define __JellyMania__FMUIBranchBonus__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIBranchBonus : public GAMEUI_Dialog , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIBranchBonus();
    ~FMUIBranchBonus();
private:
    CCNode * m_ccbNode;
    CCNode * m_panel;
    CCNode * m_parentNode;
    CCLabelBMFont * m_amountLabel;
    CCLabelBMFont * m_describeLabel;
    CCAnimButton * m_okButton;
    int m_level;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUIBranchBonus";}
    virtual void onEnter();
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    void setLevelIndex(int level);
};


#endif /* defined(__FarmMania__FMUIBoosterInfo__) */
