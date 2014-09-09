//
//  FMInputNumberDialog.h
//  FarmMania
//
//  Created by  James Lee on 13-5-20.
//
//

#ifndef __FarmMania__FMInputNumberDialog__
#define __FarmMania__FMInputNumberDialog__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Dialog.h"

class FMInputNumberDialog : public GAMEUI_Dialog , public CCBSelectorResolver, public CCBMemberVariableAssigner  {
public:
    FMInputNumberDialog();
    ~FMInputNumberDialog();
private:
    CCNode * m_ui;
    CCNode * m_buttonParent;
    bool m_unmodified;
    int m_number;
public: 
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    void clickButton(CCObject * object, CCControlEvent event);
    int getNumber() { return m_number; }
    void setNumber(int number);
};

#endif /* defined(__FarmMania__FMInputNumberDialog__) */
