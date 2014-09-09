//
//  FMUIDailySign.h
//  JellyMania
//
//  Created by lipeng on 14-8-16.
//
//

#ifndef __JellyMania__FMUIDailySign__
#define __JellyMania__FMUIDailySign__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "CCAnimButton.h"
#include "OBJCHelper.h"
#include "NEAnimNode.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIDailySign : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner, public OBJCHelperDelegate, public NEAnimCallback {
public:
    FMUIDailySign();
    ~FMUIDailySign();
private:
    bool m_instantMove;
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    CCNode * m_rewardNode;
    CCLabelBMFont * m_botLabel;
    bool m_isChecked;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual void animationEnded(NEAnimNode * node, const char * animName);
    virtual void animationCallback(NEAnimNode * node, const char * animName, const char * callback){};
public:
    virtual const char * classType() {return "FMUIDailySign";}
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void onEnter();
    void updateUI();
    void delayCheckIn();
    void checkIn();
    void checkInSuccess();
};


#endif /* defined(__JellyMania__FMUIDailySign__) */
