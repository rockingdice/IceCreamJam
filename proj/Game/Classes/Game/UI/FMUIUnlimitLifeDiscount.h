//
//  FMUIUnlimitLifeDiscount.h
//  JellyMania
//
//  Created by ywthahaha on 14-4-21.
//
//

#ifndef __JellyMania__FMUIUnlimitLifeDiscount__
#define __JellyMania__FMUIUnlimitLifeDiscount__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIUnlimitLifeDiscount : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIUnlimitLifeDiscount();
    ~FMUIUnlimitLifeDiscount();
private:
    bool m_instantMove;
    CC_SYNTHESIZE(bool, m_freeUpgrade, FreeUpgread);
    
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    CCLabelBMFont * m_titleLabel;
    CCSprite * m_iconSpt;
    CCLabelBMFont * m_timeLabel;
    
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUIUnlimitLifeDiscount";}
    virtual void onEnter();
    virtual void onExit();

    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void keyBackClicked();
    void updateTimeLabel();

};


#endif /* defined(__JellyMania__FMUIUnlimitLifeDiscount__) */
