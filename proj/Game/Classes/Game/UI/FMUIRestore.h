//
//  FMUIRestore.h
//  FarmMania
//
//  Created by  James Lee on 13-6-6.
//
//

#ifndef __FarmMania__FMUIRestore__
#define __FarmMania__FMUIRestore__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
using namespace cocos2d;
using namespace cocos2d::extension;

enum kSmallUIType {
    kSLevelEnd,
    kSComingSoon,
    kSRestore,
    kSChapterEnd
};

class FMUIRestore : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIRestore();
    ~FMUIRestore();
private:
    bool m_instantMove;
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    
    CCLabelBMFont * m_titleLabel;
    CCLabelBMFont * m_infoLabel;
    CCLabelBMFont * m_button2Label;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUIRestore";}
    virtual void setClassState(int state);
    void clickButton(CCObject * object , CCControlEvent event); 
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    void restoreIAPCallback(CCObject * object);
    virtual void keyBackClicked();
};


#endif /* defined(__FarmMania__FMUIRestore__) */
