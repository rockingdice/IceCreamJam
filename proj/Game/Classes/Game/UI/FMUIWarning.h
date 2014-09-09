//
//  FMUIWarning.h
//  FarmMania
//
//  Created by James Lee on 13-5-29.
//
//

#ifndef __FarmMania__FMUIWarning__
#define __FarmMania__FMUIWarning__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Dialog.h"
#include "GUIScrollSlider.h"
using namespace cocos2d;
using namespace cocos2d::extension;
 
class FMUIWarning : public GAMEUI_Dialog , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIWarning();
    ~FMUIWarning();
private:
    CCNode * m_ccbNode;
    CCNode * m_panel;
    CCNode * m_parentNode;  
    
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUIWarning";}
    virtual void setClassState(int state);
    void clickButton(CCObject * object , CCControlEvent event);
    void onEnter();
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
};


#endif /* defined(__FarmMania__FMUIWarning__) */
