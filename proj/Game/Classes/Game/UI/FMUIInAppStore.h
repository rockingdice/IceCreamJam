//
//  FMUIInAppStore.h
//  FarmMania
//
//  Created by  James Lee on 13-6-5.
//
//

#ifndef __FarmMania__FMUIInAppStore__
#define __FarmMania__FMUIInAppStore__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "NEAnimNode.h"
#include "FMGameNode.h"
#include "GUIScrollSlider.h"
#include "OBJCHelper.h"
using namespace cocos2d;
using namespace cocos2d::extension;
using namespace neanim;


class FMUIInAppStore : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner, public GUIScrollSliderDelegate {
public:
    FMUIInAppStore();
    ~FMUIInAppStore();
private:
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    CCNode * m_parentButton;
    CCNode * m_moreButtonParent;
    CCAnimButton * m_closeButton;
    GUIScrollSlider * m_slider;
    CCLabelBMFont * m_titleLabel;
    bool m_instantMove; 
    iapItemGroup * m_boughtGroup;
    bool m_isClicked;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    
    virtual CCNode * createItemForSlider(GUIScrollSlider * slider);
    virtual int itemsCountForSlider(GUIScrollSlider * slider);
    virtual void sliderUpdate(GUIScrollSlider * slider, int rowIndex, CCNode * node);
    
    void buyIAPCallback(CCObject * object);
public:
    virtual const char * classType() {return "FMUIInAppStore";}
    virtual void setClassState(int state);
    void clickButton(CCObject * object , CCControlEvent event);
     
    
    virtual void onEnter();
    virtual void onExit();
    
    
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void keyBackClicked();
};
#endif /* defined(__FarmMania__FMUIInAppStore__) */
