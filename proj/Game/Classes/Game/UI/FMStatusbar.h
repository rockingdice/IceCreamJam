//
//  FMStatusbar.h
//  FarmMania
//
//  Created by  James Lee on 13-5-26.
//
//

#ifndef __FarmMania__FMStatusbar__
#define __FarmMania__FMStatusbar__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI.h"
using namespace cocos2d;
using namespace cocos2d::extension;

class FMStatusbar : public GAMEUI , public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMStatusbar();
    ~FMStatusbar();
private:
    CCNode * m_ccbNode; 
    CCNode * m_panelNode;
    CCSprite * m_panel;
//    CCNode * m_adButtonParent;
//    CCControlButton * m_adButton;
    
    CCAnimButton  * m_msgButton;
    CCLabelBMFont * m_lifeLabel;
    CCLabelBMFont * m_goldLabel;
    CCLabelBMFont * m_timeLabel;
    CCLabelBMFont * m_unlimitTimeLabel;
    CCLabelBMFont * m_unreadMsgLabel;
    CCNode * m_timeLabelParent;
    CCControlButton * m_freeGemsBtn;
    CCControlButton * m_rateBtn;
    CCNode * m_coinNode;
    CCNode * m_lifeNode;
    bool m_isShown;
    int m_nextEnergyTime;
    int m_maxEnergy;
    int m_energy;
    int m_unlimitLifeTime;
    bool m_hasNewQuest;
    int m_mesgSourceType; // 0-facebook, 1-topgame notice
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
public:
    virtual const char * classType() {return "FMStatusbar";}
    void show(bool isShown, bool transition = true);
    void makeReadOnly(bool readonly);
    bool isHaveNewQuest() {return m_hasNewQuest;}
    void resetHaveNewQuest() {m_hasNewQuest = false;}
    void clickIAP(CCObject * object , CCControlEvent event);
    void clickAdvert(CCObject * object , CCControlEvent event);
    void clickBook(CCObject * object , CCControlEvent event);
    void clickFreeGems(CCObject * object , CCControlEvent event);
    void clickRate(CCObject * object , CCControlEvent event);
    void clickMsg(CCObject * object);
    void clickHeart(CCObject * object);
    virtual bool ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent);
    void updateUI();
    void addEnergy();
    virtual void onEnter();
    virtual void onExit();
    virtual void update(float delta);
    
    CCPoint getTutorialPosition(int index);
    void resetBookBtn();
    void resetRateBtn(bool hidden);
};

#endif /* defined(__FarmMania__FMStatusbar__) */
