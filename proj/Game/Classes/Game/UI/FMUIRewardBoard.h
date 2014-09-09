//
//  FMUIRewardBoard.h
//  JellyMania
//
//  Created by ywthahaha on 14-4-23.
//
//

#ifndef __JellyMania__FMUIRewardBoard__
#define __JellyMania__FMUIRewardBoard__

#include <iostream>

#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
using namespace cocos2d;
using namespace cocos2d::extension;

typedef enum {
    kRewardFromNone = -1,
    kRewardFromStarBonus = 0,
    kRewardFromGoldIapBonus,
    
}kRewardFrom;



class FMUIRewardBoard : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIRewardBoard();
    ~FMUIRewardBoard();
private:
    CCNode * m_ccbNode;
    CCSprite * m_iconSprite;
    CCLabelBMFont * m_amountLabel;
    CCLabelBMFont * m_titleLabel;
    CC_SYNTHESIZE(int, m_rwdType, RewardType);
    CC_SYNTHESIZE(int, m_amount, Amount);
    CC_SYNTHESIZE(kRewardFrom, m_rwdFrom, RewardFrom);
    CC_SYNTHESIZE(int, m_goldIapIndex, GoldIapIndex);
    CC_SYNTHESIZE(CCLabelBMFont*, m_boosterNameLabel, BoosterNameLabel);
    
    
protected:
    virtual const char * classType() {return "FMUIRewardBoard";}
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual void onEnter();
    virtual void onExit();
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void transitionInDone();
    virtual void keyBackClicked();
    
public:
    void clickButton(CCObject * object , CCControlEvent event);
    void updateUI();
    static CCSpriteFrame* getIconFrameByType(int type);
    CCString* getTitleByType(int type);
    CCString* getBoosterNameByType(int type);
};




#endif /* defined(__JellyMania__FMUIRewardBoard__) */
