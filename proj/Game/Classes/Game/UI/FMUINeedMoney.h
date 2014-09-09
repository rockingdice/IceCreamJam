//
//  FMUINeedMoney.h
//  FarmMania
//
//  Created by  James Lee on 13-6-6.
//
//

#ifndef __FarmMania__FMUINeedMoney__
#define __FarmMania__FMUINeedMoney__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "FMUIInAppStore.h"
#include "OBJCHelper.h"
using namespace cocos2d;
using namespace cocos2d::extension;

class FMUINeedMoney : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUINeedMoney();
    ~FMUINeedMoney();
private:
    bool m_instantMove;
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    iapItemGroup * m_boughtGroup;
    bool m_isClicked;
    CCLabelBMFont * m_amountLabel;
    CCAnimButton * m_priceButton;
    CCLabelBMFont * m_goldLabel1;
    CCLabelBMFont * m_goldLabel2;
    int m_index;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUINeedMoney";}
    virtual void setClassState(int state);
    virtual void onEnter();
    void buyIAPCallback(CCObject *object);
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    void setNeedNumber(int number);
    virtual void keyBackClicked();
};


#endif /* defined(__FarmMania__FMUINeedMoney__) */
