//
//  FMUIInvite.h
//  JellyMania
//
//  Created by lipeng on 14-4-3.
//
//

#ifndef __JellyMania__FMUIInvite__
#define __JellyMania__FMUIInvite__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "CCAnimButton.h"
using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIInvite : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIInvite();
    ~FMUIInvite();
private:
    bool m_instantMove;
    CCNode * m_ccbNode;
    CCLabelBMFont * m_inviteLabel;
    CCArray * m_list;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUIInvite";}
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void onEnter();
    void updateUI();
    void onRequstFinished(CCDictionary * dic);
    virtual void keyBackClicked();
};

#endif /* defined(__JellyMania__FMUIInvite__) */
