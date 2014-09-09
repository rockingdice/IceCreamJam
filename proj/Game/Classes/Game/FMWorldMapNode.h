//
//  FMWorldMapNode.h
//  FarmMania
//
//  Created by  James Lee on 13-5-12.
//
//

#ifndef __FarmMania__FMWorldMapNode__
#define __FarmMania__FMWorldMapNode__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "NEAnimNode.h"
#include "GUIScrollSlider.h"
#include "DailyBox.h"
#define kTreeTrunkOffsetX 35.f
#define kAvatarOffsetY 42.f
#define kMaxSameLevelShow 5
using namespace cocos2d;
using namespace cocos2d::extension;
using namespace neanim;

enum kWorldButtonState {
    kButton_Passed = 1 << 0,
    kButton_Pressed = 1 << 1,
    kButton_Highlighted = 1 << 2,
    kButton_Locked = 1 << 3,
    kButton_Finished = 1 << 4,
    kButton_Released = 1 << 5,
};

enum kAnimPhaseType {
    kPhase_NULL = -1,
    kPhase_MoveAvatar = 0,
    kPhase_PopStars,
    kPhase_LevelUnlock,
    kPhase_QuestPassed,
    kPhase_QuestComplete,
    kPhase_WorldUnlock,
    kPhase_Tutorial,
    kPhase_TutorialUnlock,
    kPhase_NextLevel,
    kPhase_GetBonus,
    kPhase_ShowAdv,
//    kPhase_KeyFlying,
//    kPhase_TreeOpenLock,
//    kPhase_TreeRemove,
//    kPhase_CloudsFade,
    kPhase_ComingSoon
};

enum kGameAdvance {
    kAdvance_Normal,
    kAdvance_MasterComplete,
    kAdvance_AllComplete
};

struct AnimPhaseStruct {
    kAnimPhaseType type;
    int worldIndex;
    int levelIndex;
    bool isQuest;
};

class FMWorldMapNode : public CCLayer, public CCBSelectorResolver, public CCBMemberVariableAssigner, public NEAnimCallback, public GUIScrollSliderDelegate {
public:
    FMWorldMapNode();
    ~FMWorldMapNode();
    static FMWorldMapNode * create();
private:
    CCNode * m_ccbNode;
    GUIScrollSlider * m_slider;
    CCNode * m_avatar;
    NEAnimNode * m_mapNameNode;
    CCPoint m_lastPosition;
    CCNode * m_newVersionNode;
    NEAnimNode * m_leftButton;
    NEAnimNode * m_rightButton;
    DailyBox * m_dailyBox;
    
    std::map<int, NEAnimNode *> m_cachedMaps;
    
    bool m_isClicked;
    kGameAdvance m_gameAdvance;
    bool m_isPhaseRunning;
    void clickSubLevel(CCObject * object, CCControlEvent event);
    void clickUpdate(CCObject * object, CCControlEvent event);
    void clickPlayBranch(CCObject * object, CCControlEvent event);
    void clickButton(CCObject * object, CCControlEvent event);
    void clickAvatarBtn(CCObject * object, CCControlEvent event);
    bool m_initAvatar;
    int  m_willUnlockBooster;
    bool m_willUpdateStar;
    int  m_willUpdateUnlock;
    bool m_hideSublevel;
    NEAnimNode * m_currentButton;
    CCLabelBMFont * m_info;
    CCSprite * m_dialog;
    
    //helper
//    NEAnimNode * getWorldNode(int index);
//    void showButton(NEAnimNode * animNode, CCControlEvent state, bool isPassed);
    void updateButtonState(NEAnimNode * animNode, int flag, bool refresh = true);

    std::list<AnimPhaseStruct> m_phases;
    //phase
    CCPoint getScrollPosition(int worldIndex, int levelIndex, bool isQuest);
    CCPoint getMapPosition(int worldIndex, int levelIndex, bool isQuest);
    
//CCB Bindings:
    CCNode * m_centerNode;
protected:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual void animationEnded(NEAnimNode * node, const char * animName);
    virtual void animationCallback(NEAnimNode * node, const char * animName, const char * callback) {};
    virtual CCNode * createItemForSlider(GUIScrollSlider * slider);
    virtual int itemsCountForSlider(GUIScrollSlider * slider);
    virtual void sliderUpdate(GUIScrollSlider * slider, int rowIndex, CCNode * node);
    virtual void sliderEnterPage(GUIScrollSlider * slider, int rowIndex, CCNode * node);
    virtual void sliderStopInPage(GUIScrollSlider * slider, int rowIndex, CCNode * node);
    virtual void sliderLeavePage(GUIScrollSlider * slider, int rowIndex, CCNode * node);

    virtual void onEnter();
    virtual void onExit();
    void updateWorld(NEAnimNode * node, int world);    
public:
    void hideSublevel(int idx = -1);
    void showSublevel();
    void slideDone();
    void updateUnlockBooster(int booster);
    void noUiCallback();
    
    void clearCurrentButton();
    void pushPhase(AnimPhaseStruct phase);
    void pushPhase(int num, ...);
    void runPhase();
    void phaseDone();
    void cleanPhase();
    void updateToLatestState();
    void updatePhases();
    kAnimPhaseType getCurrentPhaseType();
    void initMapPosition();
    bool m_worldUnlockFlag;
    void worldUnlockCallback();
    
    NEAnimNode * getLevelNode(int world, int level, bool isQuest); 
    CCPoint getTutorialPosition(int index); 
    bool isWorldExist(int rowIndex);
    void onFileDownloaded(CCString * fileName);
    CCSpriteFrame * getCurrentWorldBGFrame();
    void onRequestFinished(CCDictionary * dic);
    
    void checkGameCleared();
    void showFamilyTree(bool scroll = false);
    void showBranchLevel();
    void requestFriendsData();
    void setAvatarEnable(bool flag);
};
#endif /* defined(__FarmMania__FMWorldMapNode__) */
