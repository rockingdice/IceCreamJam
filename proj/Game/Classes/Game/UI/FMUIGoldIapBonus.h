//
//  FMUIGoldIapBonus.h
//  JellyMania
//
//  Created by ywthahaha on 14-4-22.
//
//

#ifndef __JellyMania__FMUIGoldIapBonus__
#define __JellyMania__FMUIGoldIapBonus__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIGoldIapBonus : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIGoldIapBonus();
    ~FMUIGoldIapBonus();
private:
    bool m_instantMove;
    
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    CCLabelBMFont * m_titleLabel;
    CCLabelBMFont * m_purchasedLabel;
    CCLabelBMFont * m_timeLabel;
    
    
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    
    virtual void keyBackClicked();
public:
    virtual const char * classType() {return "FMUIGoldIapBonus";}
    virtual void onEnter();
    virtual void onExit();
    
    void clickButton(CCObject * object , CCControlEvent event);
    void getBonus(CCNode* sender , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void update(float time);
    void updateUI();
    
};

#endif /* defined(__JellyMania__FMUIGoldIapBonus__) */
