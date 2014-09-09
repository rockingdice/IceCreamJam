//
//  FMUIPause.h
//  FarmMania
//
//  Created by  James Lee on 13-5-26.
//
//

#ifndef __FarmMania__FMUIPause__
#define __FarmMania__FMUIPause__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "CCAnimButton.h"
using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIPause : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIPause();
    ~FMUIPause();
private:
    bool m_instantMove;
    CCNode * m_ccbNode; 
    CCLabelBMFont * m_useridLabel;
    CCLabelBMFont * m_versionLabel; 
     
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUIPause";} 
    void clickButton(CCObject * object , CCControlEvent event); 
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void onEnter();
    void updateUI();
    virtual void keyBackClicked();
};


#endif /* defined(__FarmMania__FMUIPause__) */
