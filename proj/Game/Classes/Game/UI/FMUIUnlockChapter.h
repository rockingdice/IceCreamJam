    //
//  FMUIUnlockChapter.h
//  FarmMania
//
//  Created by James Lee on 13-6-8.
//
//

#ifndef __FarmMania__FMUIUnlockChapter__
#define __FarmMania__FMUIUnlockChapter__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "NEAnimNode.h"
using namespace cocos2d;
using namespace cocos2d::extension;
using namespace neanim;

class FMUIUnlockChapter : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIUnlockChapter();
    ~FMUIUnlockChapter();
private:
    bool m_instantMove;
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    CCNode * m_panel1Node;
    CCNode * m_panel2Node;
    NEAnimNode * m_uiAnim;
    NEAnimNode * m_button[3]; 
    int m_current;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUIUnlockChapter";}
    virtual void onEnter();
    virtual void onExit();
    virtual void update(float delta);
    void clickButton(CCObject * object , CCControlEvent event);
    void clickQuest(CCObject * object , CCControlEvent event);
    void updateUI();
    void buyIAPCallback(CCObject *object);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void transitionInDone();
    virtual void keyBackClicked();
    CCPoint getTutorialPosition(int index);
};


#endif /* defined(__FarmMania__FMUIUnlockChapter__) */
