//
//  FMUIBoosterInfo.h
//  FarmMania
//
//  Created by  James Lee on 13-6-6.
//
//

#ifndef __FarmMania__FMUIBoosterInfo__
#define __FarmMania__FMUIBoosterInfo__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "GUIScrollSlider.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIBoosterInfo : public GAMEUI_Dialog , public CCBSelectorResolver, public CCBMemberVariableAssigner, public GUIScrollSliderDelegate {
public:
    FMUIBoosterInfo();
    ~FMUIBoosterInfo();
private:
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    CCNode * m_panel; 
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual CCNode * createItemForSlider(GUIScrollSlider * slider);
    virtual int itemsCountForSlider(GUIScrollSlider * slider);
    virtual void sliderUpdate(GUIScrollSlider * slider, int rowIndex, CCNode * node);
public:
    virtual const char * classType() {return "FMUIBoosterInfo";}
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void keyBackClicked(void);
};


#endif /* defined(__FarmMania__FMUIBoosterInfo__) */
