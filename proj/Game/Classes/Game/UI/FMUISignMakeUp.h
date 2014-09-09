//
//  FMUISignMakeUp.h
//  JellyMania
//
//  Created by lipeng on 14-8-16.
//
//

#ifndef __JellyMania__FMUISignMakeUp__
#define __JellyMania__FMUISignMakeUp__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "CCAnimButton.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMUISignMakeUp : public GAMEUI_Dialog , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUISignMakeUp();
    ~FMUISignMakeUp();
private:
    CCNode * m_ccbNode;
    CCNode * m_panel;
    CCLabelBMFont * m_title;
    CCLabelBMFont * m_label;
    CCLabelBMFont * m_dayLabel;
    CCLabelBMFont * m_priceLabel;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUISignMakeUp";}
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void onEnter();
};

#endif /* defined(__JellyMania__FMUISignMakeUp__) */
