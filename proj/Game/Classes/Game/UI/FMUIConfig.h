//
//  FMUIConfig.h
//  FarmMania
//
//  Created by  James Lee on 13-5-26.
//
//

#ifndef __FarmMania__FMUIConfig__
#define __FarmMania__FMUIConfig__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "CCAnimButton.h"
using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIConfig : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIConfig();
    ~FMUIConfig();
private:
    bool m_instantMove;
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    CCLabelBMFont * m_titleLabel;
    CCLabelBMFont * m_button1Label;
    CCLabelBMFont * m_useridLabel;
    CCLabelBMFont * m_versionLabel;
    CCNode * m_buttonParent;
    CCNode * m_centerNode;
//    CCNode * m_buttonsCN;
//    CCNode * m_buttonsEN;
    bool m_isConnectedToFacebook;
    
    CCAnimButton * m_facebookButton;
    CCLabelBMFont * m_facebookInfo;
    CCSprite * m_facebookIcon;
    CCLabelTTF * m_facebookName;
    CCNode * m_connectNode;
     
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUIConfig";}
    virtual void setClassState(int state);
    void clickButton(CCObject * object , CCControlEvent event); 
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void onEnter();
    void updateUI();
    
    virtual void keyBackClicked();
};


#endif /* defined(__FarmMania__FMUIConfig__) */
