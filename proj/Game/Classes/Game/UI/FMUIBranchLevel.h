//
//  FMUIBranchLevel.h
//  JellyMania
//
//  Created by lipeng on 14-1-2.
//
//

#ifndef __JellyMania__FMUIBranchLevel__
#define __JellyMania__FMUIBranchLevel__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "NEAnimNode.h"
#include "FMWorldMapNode.h"
#define _BonusRewardCount_ 3

typedef struct BranchRewardData {
    int level;
    int number;
} BranchRewardData;

using namespace cocos2d;
using namespace cocos2d::extension;
using namespace neanim;

class FMUIBranchLevel : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner, public NEAnimCallback {
public:
    FMUIBranchLevel();
    ~FMUIBranchLevel();
private:
    bool m_instantMove;

    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    NEAnimNode * m_jellyrole;
    NEAnimNode * m_crown;
    CCLabelBMFont * m_titleLabel;
    bool m_isClicked;
    NEAnimNode * m_currentButton;
    CCSprite * m_giftBox;
    CCLabelBMFont * m_giftLabel;

    std::list<AnimPhaseStruct> m_phases;
    
    bool haveBonus(int lv);
protected:
    virtual void animationEnded(NEAnimNode * node, const char * animName);
    virtual void animationCallback(NEAnimNode * node, const char * animName, const char * callback) {};
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    
    virtual void keyBackClicked();
public:
    void setUpSubLevelBtn();
    void clickBackButton(CCObject * object , CCControlEvent event);
    void clickSubLevel(CCObject * object, CCControlEvent event);
    void updateButtonState(NEAnimNode * animNode, int flag, bool refresh = true);
    virtual void onEnter();
    virtual void onExit();
    virtual void update(float delta);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void transitionInDone();
    
    void clearCurrentButton();
    void pushPhase(AnimPhaseStruct phase);
    void pushPhase(int num, ...);
    void runPhase();
    void phaseDone();
    void cleanPhase();
    void updatePhases();
    void hideGiftBox();
};

#endif /* defined(__JellyMania__FMUIBranchLevel__) */
