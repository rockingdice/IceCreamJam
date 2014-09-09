//
//  FMUIResult.h
//  FarmMania
//
//  Created by  James Lee on 13-5-28.
//
//

#ifndef __FarmMania__FMUIResult__
#define __FarmMania__FMUIResult__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "NEAnimNode.h"
#include "GUIScrollSlider.h"
#include "OBJCHelper.h"
using namespace cocos2d;
using namespace cocos2d::extension;
using namespace neanim;

enum kResultUIType {
    kResult_Win,
    kResult_Lose
//    kNormalQuit = 0,
//    kNormalComplete,
//    kNormalFailed,
//    kBossComplete,
//    kBossFailed,
//    kVegeComplete,
//    kVegeFailed,
//    kBoxComplete,
//    kBoxFailed
    };

class FMUIResult : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner, public GUIScrollSliderDelegate, public OBJCHelperDelegate {
public:
    FMUIResult();
    ~FMUIResult();
private:
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
    NEAnimNode * m_starParent;
    
    CCLabelBMFont * m_levelLabel;
    CCLabelBMFont * m_scoreLabel;
    CCLabelBMFont * m_highscoreLabel;
    CCLabelBMFont * m_connectTipLabel;
    NEAnimNode * m_star[3];
    NEAnimNode * m_highscoreMark;
    CCSprite * m_tipPicture;
    
    int m_earnStarNum;
    int m_earnScore;

    int m_oldStarNum;
    int m_oldHighscore;
    
    int m_showScore;
    int m_scoreGaps[3];
    int m_currentIndex;
    
    std::vector<int> m_remainItemTypes;
    std::map<int, int> m_remainItems;
//    bool m_enterMovesSummary;
    
    bool m_instantMove;
    
    CCArray * m_rankList;
private:
    void levelComplete();
    void addNextPhase();
    int getBonusNumber();
    static int less(const CCObject* obj0, const CCObject* obj1);
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual CCNode * createItemForSlider(GUIScrollSlider * slider);
    virtual int itemsCountForSlider(GUIScrollSlider * slider);
    virtual void sliderUpdate(GUIScrollSlider * slider, int rowIndex, CCNode * node);
    virtual void facebookLoginSuccess() ;
    virtual void facebookLoginFaild() {};
public:
    virtual const char * classType() {return "FMUIResult";}
    virtual void setClassState(int state);
    void clickButton(CCObject * object , CCControlEvent event);
    void clickMenuButton(CCObject * object);

    virtual void onEnter();
    virtual void onExit();
    virtual void update(float delta);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void transitionInDone();
    virtual void keyBackClicked();
    
    void updateFb();
    
    void refreshHighScore(int score);
    static void sortList(CCArray * list);
    void onSendLifeSuccess();
    void updateScrollView();
};

#endif /* defined(__FarmMania__FMUIResult__) */
