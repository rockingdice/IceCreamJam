//
//  FMUINeedHeart.h
//  FarmMania
//
//  Created by  James Lee on 13-6-6.
//
//

#ifndef __FarmMania__FMUINeedHeart__
#define __FarmMania__FMUINeedHeart__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
using namespace cocos2d;
using namespace cocos2d::extension;

class FMUINeedHeart : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUINeedHeart();
    ~FMUINeedHeart();
private:
    bool m_instantMove;
    CCNode * m_ccbNode;
    CCNode * m_parentNode;

    CCLabelBMFont * m_timeLabel;
    CCLabelBMFont * m_lifeLabel;
    CCLabelBMFont * m_refillPriceLabel;
    CCLabelBMFont * m_upgradePriceLabel;
    CCNode * m_discountNode;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUINeedHeart";}
    virtual void onEnter();
    virtual void onExit();
    virtual void update(float time);
    void buyIAPCallback(CCObject * object);
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    void updateUI();
    virtual void keyBackClicked();
};


#endif /* defined(__FarmMania__FMUINeedHeart__) */
