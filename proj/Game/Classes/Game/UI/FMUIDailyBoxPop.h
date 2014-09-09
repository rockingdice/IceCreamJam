//
//  FMUIDailyBoxPop.h
//  JellyMania
//
//  Created by lipeng on 14-8-15.
//
//

#ifndef __JellyMania__FMUIDailyBoxPop__
#define __JellyMania__FMUIDailyBoxPop__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "CCAnimButton.h"
#include "OBJCHelper.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIDailyBoxPop : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner, public OBJCHelperDelegate {
public:
    FMUIDailyBoxPop();
    ~FMUIDailyBoxPop();
private:
    bool m_instantMove;
    CCNode * m_ccbNode;
    CCAnimButton * m_sendButton;
    CCLabelBMFont * m_label;
    bool m_isShowTip;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    
public:
    virtual const char * classType() {return "FMUISendHeart";}
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void onEnter();
    void showTip(bool isTip = true);
};


#endif /* defined(__JellyMania__FMUIDailyBoxPop__) */
