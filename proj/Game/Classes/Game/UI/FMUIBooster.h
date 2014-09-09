//
//  FMUIBooster.h
//  FarmMania
//
//  Created by  James Lee on 13-6-4.
//
//

#ifndef __FarmMania__FMUIBooster__
#define __FarmMania__FMUIBooster__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
using namespace cocos2d;
using namespace cocos2d::extension;

enum kUIBoosterType {
    kUIBooster_Buy,
    kUIBooster_Unlock
};

typedef struct boosterDataStruct
{
    int type;
    int inGamePrice;
    int outGamePrice;
    int amount;
    const char * name;
    const char * info;
}boosterDataStruct;

class FMUIBooster : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMUIBooster();
    ~FMUIBooster();
private:
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    NEAnimNode * m_boosterIcon;
    NEAnimNode * m_boosterCount;
    CCLabelBMFont * m_amountLabel;
    CCLabelBMFont * m_newBoostLabel;
    CCLabelBMFont * m_unlockLabel;
    
    bool m_willClose;
    int m_type;
    bool m_recharging;
protected:
    virtual const char * classType() {return "FMUIBooster";}
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual void onEnter();
    virtual void onExit();
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void transitionInDone();
    virtual void update(float delta);
    void updateUI();
public:
    virtual void setClassState(int state);
    void setBoosterType(int type) { m_type = type; }
    void clickButton(CCObject * object , CCControlEvent event);
    
    virtual void keyBackClicked();
};


#endif /* defined(__FarmMania__FMUIBooster__) */
