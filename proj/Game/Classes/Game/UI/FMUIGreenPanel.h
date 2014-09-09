//
//  FMUIGreenPanel.h
//  FarmMania
//
//  Created by James Lee on 13-5-27.
//
//

#ifndef __FarmMania__FMUIGreenPanel__
#define __FarmMania__FMUIGreenPanel__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI.h"
using namespace cocos2d;
using namespace cocos2d::extension;
enum kGreenPanelType {
    kPanelGoal = 0,
    kPanelManiaMode,
    kPanelComplete,
    kPanelBoss,
    kPanelVege, 
    kPanelShuffle,
    kPanel5MovesLeft,
    kPanelGood,
    kPanelFail
    };

class FMUIGreenPanel : public GAMEUI , public CCBSelectorResolver, public CCBMemberVariableAssigner, public NEAnimCallback, public CCBAnimationManagerDelegate {
public:
    FMUIGreenPanel();
    ~FMUIGreenPanel();
private:
    CCNode * m_ccbNode; 
    CCNode * m_harvestMode;
    NEAnimNode * m_animNode; 
    CCLabelBMFont * m_targetInfoLabel;
    CCLabelBMFont * m_goalLabel;
    CCNode * m_levelTargetParent;
    int m_gameMode;
public:
    void setGameMode(int gameMode);
    virtual const char * classType() {return "FMUIGreenPanel";}
    virtual void setClassState(int state);
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual void animationEnded(NEAnimNode * node, const char * animName);
    virtual void animationCallback(NEAnimNode * node, const char * animName, const char * callback);
    virtual void completedAnimationSequenceNamed(const char *name); 
    virtual void onEnter();
    void setHarvestNumber(int number);
};


#endif /* defined(__FarmMania__FMUIGreenPanel__) */
