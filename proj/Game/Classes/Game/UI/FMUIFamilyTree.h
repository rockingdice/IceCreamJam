//
//  FMUIFamilyTree.h
//  JellyMania
//
//  Created by lipeng on 14-2-20.
//
//

#ifndef __JellyMania__FMUIFamilyTree__
#define __JellyMania__FMUIFamilyTree__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "NEAnimNode.h"
#include "GUIScrollSlider.h"
using namespace cocos2d;
using namespace cocos2d::extension;
using namespace neanim;


class FMUIFamilyTree : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner, public GUIScrollSliderDelegate {
public:
    FMUIFamilyTree();
    ~FMUIFamilyTree();
private:
    CCNode * m_ccbNode;
    CCNode * m_parentNode;

    GUIScrollSlider * m_slider;
    bool m_instantMove;
    bool m_isClicked;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    
    virtual CCNode * createItemForSlider(GUIScrollSlider * slider);
    virtual int itemsCountForSlider(GUIScrollSlider * slider);
    virtual void sliderUpdate(GUIScrollSlider * slider, int rowIndex, CCNode * node);
public:
    virtual const char * classType() {return "FMUIFamilyTree";}
    virtual void setClassState(int state);
    void clickButton(CCObject * object , CCControlEvent event);
    void clickJelly(CCObject * object, CCControlEvent event);

    
    virtual void onEnter();
    //    virtual void onExit();
    virtual void keyBackClicked();
    
    
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void transitionInDone();
    
    CCPoint getTutorialPosition(int idx);
    void updateButtonState(NEAnimNode * animNode, int flag, bool refresh = true);
};

#endif /* defined(__JellyMania__FMUIFamilyTree__) */
