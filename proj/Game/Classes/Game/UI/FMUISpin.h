//
//  FMUISpin.h
//  JellyMania
//
//  Created by lipeng on 14-4-20.
//
//

#ifndef __JellyMania__FMUISpin__
#define __JellyMania__FMUISpin__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "CCAnimButton.h"
#include "GUISpinView.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMUISpin : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner, public GUISpinViewDelegate {
public:
    FMUISpin();
    ~FMUISpin();
private:
    bool m_instantMove;
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    CCArray * m_list;
    CCArray * m_tiers;
    GUISpinView * m_spinView;
    CCLabelBMFont * m_timesLabel;
    CCLabelBMFont * m_titleLabel;
    CCAnimButton * m_moreSpinBtn;
    CCSprite * m_lever;
    CCSprite * m_leverBar;
    CCSprite * m_leverBall;
    NEAnimNode * m_spinGuide;
    bool m_isSpin;
    bool m_isLeverTouch;
    float m_touchStartY;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    
    virtual CCNode * createItemForSpinView(GUISpinView * slider, int index);
    virtual int itemsCountForSpinView(GUISpinView * slider);
    virtual void spinFinished(int index);
    virtual bool ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchMoved(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchCancelled(CCTouch *pTouch, CCEvent *pEvent);
    void leverCallBack();
public:
    virtual const char * classType() {return "FMUISpin";}
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void keyBackClicked();
    virtual void onEnter();
    void updateUI();
    int getSpinResult();
};


#endif /* defined(__JellyMania__FMUISpin__) */
