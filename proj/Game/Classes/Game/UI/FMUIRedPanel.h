//
//  FMUIRedPanel.h
//  FarmMania
//
//  Created by James Lee on 13-5-29.
//
//

#ifndef __FarmMania__FMUIRedPanel__
#define __FarmMania__FMUIRedPanel__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "OBJCHelper.h"
using namespace cocos2d;
using namespace cocos2d::extension;

enum kPlayOnItems {
    kPlayOnItem_None = -1,
    kPlayOnItem_Booster1 = 0,
    kPlayOnItem_Booster2,
    kPlayOnItem_Booster3,
    kPlayOnItem_Booster4,
    kPlayOnItem_Booster5,
    kPlayOnItem_Booster6,
    kPlayOnItem_5Moves
};

typedef struct kPlayOnData {
    int price;
    kPlayOnItems item[3];
}kPlayOnData;

class FMUIRedPanel : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIRedPanel();
    ~FMUIRedPanel();
private:
    CCNode * m_ccbNode;
    CCNode * m_levelTargetParent;
    CCSprite * m_panel;
    CCLabelBMFont * m_priceLabel;
    CCLabelBMFont * m_targetInfoLabel;
    CCNode * m_rewardCCB;
    CCAnimButton * m_playOnButton;
    CCSprite * m_coin;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMUIRedPanel";}
    virtual void setClassState(int state);
    void clickButton(CCObject * object , CCControlEvent event);
    void buyIAPCallback(CCObject *object);

    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction); 
    virtual void onEnter();
    void givePlayerPlayOnReward();
    CCPoint getTutorialPosition();
    CCSize getTutorialSize();
    virtual void keyBackClicked();
};



#endif /* defined(__FarmMania__FMUIRedPanel__) */
