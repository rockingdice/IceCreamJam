//
//  FMUIQuit.h
//  FarmMania
//
//  Created by James Lee on 13-5-29.
//
//

#ifndef __FarmMania__FMUIQuit__
#define __FarmMania__FMUIQuit__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Dialog.h"
#include "GUIScrollSlider.h"
using namespace cocos2d;
using namespace cocos2d::extension;

enum kTinyUIType {
    kQuit_To_Retry,
    kQuit_To_WorldMap
};

class FMUIQuit : public GAMEUI_Dialog , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIQuit();
    ~FMUIQuit();
private:
    CCNode * m_ccbNode;
    CCNode * m_panel;
    CCNode * m_parentNode;
    CCLabelBMFont * m_titleLabel;
    
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUIQuit";}
    virtual void setClassState(int state);
    void clickButton(CCObject * object , CCControlEvent event);
    void onEnter();
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void keyBackClicked(void);
};


#endif /* defined(__FarmMania__FMUIQuit__) */
