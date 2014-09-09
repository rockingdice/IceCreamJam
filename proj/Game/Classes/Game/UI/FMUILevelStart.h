//
//  FMUILevelStart.h
//  FarmMania
//
//  Created by  James Lee on 13-5-26.
//
//

#ifndef __FarmMania__FMUILevelStart__
#define __FarmMania__FMUILevelStart__

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

class FMUILevelStart : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner, public GUIScrollSliderDelegate, public OBJCHelperDelegate {
public:
    FMUILevelStart();
    ~FMUILevelStart();
private:
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    NEAnimNode * m_starParent;
    CCNode * m_levelTargetParent;
    CCLabelBMFont * m_levelLabel; 
    CCLabelBMFont * m_targetInfoLabel;
    CCLabelBMFont * m_connectTipLabel;
    CCSprite * m_tipPicture;
    NEAnimNode * m_star[3];
    bool m_recharging[3];
    bool m_instantMove;
    bool m_isBranchLevel;
    bool m_isLoading;
    bool m_playClicked;
    NEAnimNode * m_loading;
//    CCNode * m_harvestMode;
    CCNode * m_boosterParent;
    CCArray * m_rankList;
    CCNode * m_boosterSelectParent;
    static int less(const CCObject* obj0, const CCObject* obj1);
    static void sortList(CCArray * list);
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual void facebookLoginSuccess();
    virtual void facebookLoginFaild(){};
public:
    virtual const char * classType() {return "FMUILevelStart";}
    virtual void setClassState(int state);
    virtual CCNode * createItemForSlider(GUIScrollSlider * slider);
    virtual int itemsCountForSlider(GUIScrollSlider * slider);
    virtual void sliderUpdate(GUIScrollSlider * slider, int rowIndex, CCNode * node);
    void clickButton(CCObject * object , CCControlEvent event);
    void clickBooster(CCObject * object , CCControlEvent event);
    void clickAddFrds(CCObject * object);
    void clickMenuButton(CCObject * object);
    void updateBoosters();
    void setBranchLevel();
    void updateFrdList();
    void updateFb();

    virtual void onEnter();
    virtual void onExit();
    virtual void update(float delta);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void transitionInDone();
    virtual void keyBackClicked();
    CCPoint getTutorialPosition(int index);
    void onRequstFinished(CCDictionary * dic);
    void onSendLifeSuccess();
    void updateScrollView();
};

#endif /* defined(__FarmMania__FMUILevelStart__) */
