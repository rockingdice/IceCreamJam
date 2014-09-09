//
//  FMUIUnlimitLife.h
//  JellyMania
//
//  Created by lipeng on 14-4-11.
//
//

#ifndef __JellyMania__FMUIUnlimitLife__
#define __JellyMania__FMUIUnlimitLife__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIUnlimitLife : public GAMEUI_Dialog , public CCBSelectorResolver, public CCBMemberVariableAssigner{
private:
    CCNode * m_ccbNode;
    CCNode * m_panel;
    CCNode * m_closeNode;
public:
    FMUIUnlimitLife();
    ~FMUIUnlimitLife();
    
private:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}

public:
    virtual const char * classType() {return "FMUIUnlimitLife";}
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    void showWithFile(const char* fileName , const char* animName);
    virtual bool ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent);
};

#endif /* defined(__JellyMania__FMUIUnlimitLife__) */
