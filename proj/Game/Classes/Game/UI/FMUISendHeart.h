//
//  FMUISendHeart.h
//  JellyMania
//
//  Created by lipeng on 14-8-7.
//
//

#ifndef __JellyMania__FMUISendHeart__
#define __JellyMania__FMUISendHeart__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "CCAnimButton.h"
#include "GUIScrollSlider.h"
#include "OBJCHelper.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMUISendHeart : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner, public GUIScrollSliderDelegate, public OBJCHelperDelegate {
public:
    FMUISendHeart();
    ~FMUISendHeart();
private:
    bool m_instantMove;
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    GUIScrollSlider * m_slider;
    CCLabelBMFont * m_topLabel;
    CCLabelBMFont * m_botLabel;
    CCAnimButton * m_sendButton;
    CCArray * m_friends;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    
    virtual CCNode * createItemForSlider(GUIScrollSlider * slider);
    virtual int itemsCountForSlider(GUIScrollSlider * slider);
    virtual void sliderUpdate(GUIScrollSlider * slider, int rowIndex, CCNode * node);
public:
    virtual const char * classType() {return "FMUISendHeart";}
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void onEnter();
    void updateUI(bool loading = true);
};

#endif /* defined(__JellyMania__FMUISendHeart__) */
