//
//  FMUIPrizeList.h
//  JellyMania
//
//  Created by lipeng on 14-4-23.
//
//

#ifndef __JellyMania__FMUIPrizeList__
#define __JellyMania__FMUIPrizeList__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "CCAnimButton.h"
#include "GUIScrollSlider.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIPrizeList : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner, public GUIScrollSliderDelegate {
public:
    FMUIPrizeList();
    ~FMUIPrizeList();
private:
    bool m_instantMove;
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    GUIScrollSlider * m_slider;
    CCArray * m_list;
    
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    
    virtual CCNode * createItemForSlider(GUIScrollSlider * slider);
    virtual int itemsCountForSlider(GUIScrollSlider * slider);
    virtual void sliderUpdate(GUIScrollSlider * slider, int rowIndex, CCNode * node);
    
public:
    virtual const char * classType() {return "FMUIPrizeList";}
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void onEnter();
    void updateUI();
    virtual void keyBackClicked();
};


#endif /* defined(__JellyMania__FMUIPrizeList__) */
