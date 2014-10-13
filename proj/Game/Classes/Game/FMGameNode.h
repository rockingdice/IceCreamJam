//
//  FMGameNode.h
//  FarmMania
//
//  Created by  James Lee on 13-5-3.
//
//

#ifndef __FarmMania__FMGameNode__
#define __FarmMania__FMGameNode__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "NEAnimNode.h"
#include "GUIScrollSlider.h"
#include "GAMEUI.h"
#include "GAMEUI_Dialog.h"
#include "FMGameElement.h"


typedef enum kGameDirection
{
    kDirection_None = -1,
    kDirection_Center = 0,
    kDirection_C = 0,
    kDirection_U = 1,
    kDirection_B = 8,
    kDirection_L = 2,
    kDirection_R = 7,
    kDirection_LU = 3,
    kDirection_RB = 6,
    kDirection_RU = 5,
    kDirection_LB = 4,
}kGameDirection;

typedef enum kGameMode
{
    kGameMode_Classic,
    kGameMode_Harvest,
//    kGameMode_Boss,
    kGameMode_Max
}kGameMode;

typedef enum kGameBooster
{
    kBooster_None = -1,
    kBooster_Harvest1Grid,
    kBooster_Harvest1Row,
    kBooster_PlusOne,
    kBooster_Harvest1Type,
    kBooster_Shuffle,
    kBooster_CureRot,
    kBooster_MovePlusFive,
    kBooster_TCross,
    kBooster_4Match,
    kBooster_5Line,
    kBooster_Locked = 100,
    kBooster_Gold,
    kBooster_FreeSpin,
    kBooster_UnlimitLife,
    kBooster_Life,
    KBooster_MaxLifeUnlock
}kGameBooster;

typedef enum kGamePhase
{
    kPhase_NoInput,
    kPhase_WaitInput,
    kPhase_BeforeMatch,
    kPhase_CheckTriggers,
    kPhase_Harvest,
    kPhase_Falling,
    kPhase_ItemSelecting,
    kPhase_ItemUsing,
    kPhase_HeroFlying,
    kPhase_AI,
    kPhase_BeforeNewTurn,
    kPhase_Shuffling,
    kPhase_GameEnd
} kGamePhase;

typedef enum kGameControl
{
    kControl_None,
    kControl_Win,
    kControl_CloseTo,
    kControl_Lose
} kGameControl;

typedef enum kSpecialNeighbor
{
    kSpecial_Ice,
    kSpecial_Others
}kSpecialNeighbor;

#ifdef DEBUG
typedef enum EditorItemType {
    kEditorItem_None = -1,
    kEditorItem_Grid,
    kEditorItem_Status, 
    kEditorItem_Element,
//    kEditorItem_Wall,
} EditorItemType;

typedef struct EditorItemData {
    EditorItemType type;
    int value;
    const char * name;
    const char * file;
    const char * animName;
    const char * skinName;
} EditorItemData;
#endif

using namespace cocos2d;
using namespace cocos2d::extension;
using namespace neanim;

class FMGameGrid;
class FMGameElement;
class FMGameWall;
class FMMatchGroup;
class FMLoopGroup;
class FMManiaHero;

typedef struct ElementAmountPair {
    int type;
    int weight;
    ElementAmountPair(int t, int w) {
        type = t;
        weight = w;
    }
    ElementAmountPair() {
        type = weight = 0;
    }
}ElementAmountPair;

typedef struct elementTarget {
    int index;
    int harvested;
    int target;
    int count;
} elementTarget;

typedef struct elementType {
    int type;
    int number;
} elementType;

class FMGameNode : public GAMEUI, public CCBSelectorResolver, public CCBMemberVariableAssigner, public NEAnimCallback, public CCBAnimationManagerDelegate
#ifdef DEBUG
, public GUIScrollSliderDelegate
#endif
{
public:
    FMGameNode();
    ~FMGameNode();
private:
    CCNode * m_ccbNode;
    
    CCSprite * m_background;
    
    CCNode * m_gridParent;
//ui
    bool m_uiSlideDone;
    CCNode * m_gameUI;
    CCSprite * m_gameBG;
    CCNode * m_greenPanel;
    CCControlButton * m_closeButton;
    CCControlButton * m_buttons[7];
    CCNode * m_modeParent;
    CCNode * m_modeNode[3];

    NEAnimNode * m_harvestCrowds;
    
    NEAnimNode * m_targetAnimNode[4];
    CCLabelBMFont * m_targetLabel[4];

    CCScale9Sprite * m_scorebar;
    CCLabelBMFont * m_scoreLabel;;
    CCNode * m_levelStatus;
    NEAnimNode * m_star[3];
    
    FMGameGrid *** m_grids;
    FMGameWall **** m_walls;
    
    
//level data
    CCDictionary * m_levelData;
    std::vector<ElementAmountPair> m_spawnData;
    int m_totalWeight;
    
    std::map<int, elementTarget> m_targets;
    
    std::map<int, elementTarget> m_levelLimits;
    
    std::map<int, int> m_currentLimits;
    
    std::vector<FMGameElement *> m_elementsCache;
    int m_elementsCount;
    
    
    kGameMode m_gameMode;
    kGameBooster m_suggestedBooster;
    int m_leftMoves;
    int m_usedMoves;
    int m_totalMoves;
    bool m_hasPlus5BeforeLevel;
    int m_boosterUsed[5];
    int m_continueTimes;
    int m_scoreCaps[3];
    int m_gameModeData[3];
    
    int m_starNum;
    int m_starNumCurrent;
    int m_score;
    int m_showScore;
    int m_scoreBeforeMania;
    
    
    bool m_enableManiaMode;
    bool m_isLevelFirstIn;
    
    float m_thinkingTime;
    float m_idleTime;
    
//game phase
    kGamePhase m_phase;
    bool m_targetsCompleted;
    bool m_maniaMode;
    bool m_maniaModeBegin;
    int m_usingItem;
    bool m_movePlus;
    bool m_gameEnd;
    bool m_userQuit;

    int m_harvestedInMove;
//combo
    int m_combo;
    int m_soundEffectCombo;
    
    NEAnimNode * m_indicator[4]; 
    
    CCSpriteBatchNode * m_borderGridParent;
    
    std::set<FMGameElement*> m_movingElements;
    
    std::map<int, FMMatchGroup * > m_matchedGroups;
//    int m_matchedGroupsIndex;
    //int: groupID
    //CCArray*: matched Elements
    
    std::vector<FMGameGrid *> m_spawner;
    
    std::vector<FMGameGrid *> m_matchableGrids;
    
    FMMatchGroup * m_animChecker;
    
    FMGameGrid * m_currentSelection;
    
    std::vector<elementType> m_spawnElements;
//temp
    CCDictionary * m_data;
    std::vector<int> m_usedBonus;
protected:
    virtual void onEnter();
    virtual void onExit();
public:
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    void setGameBG();
#endif
    void loadLevel(int world, int index, bool localMode, bool isQuest, int seed = 0);
    void makeInit();
    void gameStart();
    void updateUI();
    bool checkGridsStable();
    bool checkFalling();
    void beginSpawn();
    bool checkMatch();
    void beginMatch();
    void beginHarvest();
    void beginFalling();
    void beforeMatch();
    void checkTriggers(); 
    void cleanMatchFlag();
    bool checkMatchable();
    void checkAI();
    void beforeNewTurn();
    bool checkGridMatchable(FMGameGrid * grid);
    int getGridMatchPriority(FMGameGrid * grid, int priority);
    int getGridsPriority(std::vector<FMGameGrid *> grids, int color);
    std::vector<FMGameGrid *> getMatchPriorityGrids(FMGameGrid * grid, int elementColor, kGameDirection dismissDirection);
    bool checkGridMatch(FMGameGrid * grid);
    void shuffle();
    bool checkMapPlayable();
    void mapDataRemake();
    void markMatchable();
    void makeGridStable(FMGameGrid * grid);
    int getHarvestTypeInMap(int elementType);
    int getTypeInMap(int elementType);
    void playJellyAnim(bool isAnim = true);
    void playIdleAnim();
    void addSellingBonus(int type);

    //game functions
    void addCombo();

    //scores
    int getCurrentStarNum() { return m_starNum; }
    std::map<int, elementTarget> getTargets() { return m_targets; }
    int getCurrentScore();
    int getScoreGap(int gap);
    int getUsedMoves() {return m_usedMoves;}
    int getDefaultMoves();
    int getLeftMoves();
    int getBoosterUsed(int boosterType) { return m_boosterUsed[boosterType]; }
    int getContinueTimes() { return m_continueTimes; }

    int getGameMode() { return m_gameMode; }
    bool hasPlus5Booster() { return m_hasPlus5BeforeLevel; } 
    bool isGameOver() { return m_gameEnd; }
    int getScoreBeforeMania() { return  m_scoreBeforeMania; }
    void addLeftMoves(int mod) { m_leftMoves += mod; }
        
    //helper
    CCPoint getNeighborCoord(int row, int col, int direction);
    FMGameGrid * getNeighbor(int row, int col, int direction);
    FMGameGrid * getNeighbor(FMGameGrid * grid, int direction);
    FMGameWall * getWall(int row, int col, int direction);
    FMGameWall * getWall(FMGameGrid * grid, int direction);

    //only check walls
    bool isDirectionBlocked(int row, int col, int direction);
    bool isDirectionBlocked(FMGameGrid * grid, int direction);

    //check walls and grids
    bool hasRouteToDirection(FMGameGrid * grid, int direction);
    bool isGridsSwappable(FMGameGrid * grid, kGameDirection direction);
    bool isCoordExist(int row, int col);
    bool isCoordTouchable(int row, int col);

    CCPoint getPositionForCoord(float row, float col);
    CCPoint getPositionForGrid(FMGameGrid * grid);
    CCPoint getWorldPositionForCoord(float row, float col);
    int getNewElementType();
    FMGameElement * createNewElement(int type);
    void removeElement(FMGameElement * element);
    int createNewMatchGroup();
    void addMovingElement(FMGameElement * element);
    bool isGridMatchColor(FMGameGrid * grid, int color);
    void showIndicator(bool show, int row = 0, int col = 0, int row2 = -1, int col2 = -1);
    void breakWall(std::set<FMGameGrid *> * checkQueue, FMGameGrid * grid);
    void triggerAddValueToTarget(FMGameElement * element);
    void triggerAddValueToSpecailTarget(kElementType type);
    void triggerHitDone(FMGameElement * element);

    void resetZOrder(FMGameGrid * grid);

    void removeBadSeed(int seed);
    bool canPlayerInput() { return m_phase == kPhase_WaitInput && !m_swapBegin && m_touchBegin && !m_gameEnd; }
    kGamePhase getGamePhase() { return m_phase; }
    void setGamePhase(kGamePhase phase) { m_phase = phase; /*CCLOG("game switching to:%d", phase);*/}
    std::set<FMGameGrid*> getGridsAroundMatchGroup(FMMatchGroup * mg);
    void creatElementType(FMGameGrid * grid);
//marquee groups
    std::vector<FMLoopGroup *> m_marquees;
    static std::string getBorderFileName(int flag);
    kGameDirection getDirection(kGameDirection dir, bool inserse = false);
    kGameDirection getOutputDirection(int flag, kGameDirection inputDirection = kDirection_None);
    void updateMarquee();
    void playMarquee(bool play);
    
    //ui
    void updateHarvestTargets();
    void updateMoves();
    void updateBackGrids();

    //mania mode
    void maniaMode();
    void maniaPlusOne();
    void maniaHeroRush(); 
    void maniaHarvestGrid(int row, int col);
    void maniaHarvestCallback(FMGameGrid * grid);
    bool maniaUseMove();
//    void maniaFireworkCallback(FMGameGrid * grid);
    
    //item
    bool isSellingBooster(int type);
    bool isBoosterUsable(kGameBooster type);
    void useItem(kGameBooster type);
    void useItemMode(bool useItem);
    void showSelectedGrids(bool show, int row = -1, int col = -1);
    void triggerItem(int row, int col);
    void enterUseItemMode(int booster);
    void gridNextPhase(FMMatchGroup * mg, FMGameGrid * grid, float harvestDelay = 0.f);
    void tractorCallback(FMGameGrid * grid);
    void pigCallback();
    void elementStrawHarvest(FMGameElement * element);
    void updateBoosters();
    static const char * getBoosterSkin(kGameBooster type);
    void updateBoostersTimer(float delta);
    
    static int getBaseScore(kElementType type);
    int getHarvestScore(kElementType type);
    void addScore(int score);
    void updateScorebar(float delta);
    void resetScorebar();
    void setScoreBar(float percentage);
    void uiSlide(bool movein);
    void checkTargetComplete();
    bool checkWinner();
    void levelComplete();
    void levelFailed();
    void mapSlideInDone();
    void mapSlideOutDone();
    void goalSlideDone();
    void completeSlideDone();
    void handleDialogFailed(int t);
    void userRetryAddLife();
    void userQuiteAddLife();
    void addLifeAndBooster();
    void handleDialogQuit(GAMEUI_Dialog * dialog);
    
    //tutorials
private:
    std::set<int> m_tutCoords;
public:
    void setMapLimit(std::set<int> coords);
    void resetMapLimit();
    void setButtonLimit(std::set<int> indices);
    void resetButtonLimit();
    CCPoint getTutorialPosition(int index);
private:
    //swap
    FMGameGrid * m_swapGrid1;
    FMGameGrid * m_swapGrid2;
    bool m_swapBegin;
    bool m_touchBegin;
    void swapElements(FMGameGrid * g1, FMGameGrid * g2);
    void callbackSwapDone();
    void callbackSwapBack();
            
//    //jump seat
//    std::vector<FMGameGrid *> m_jumpGrids;
    
//    //snails
    bool m_aiChecked;
//    std::set<FMGameGrid *> m_snailGrids;
//    void callbackSnailMoveDone(FMGameElement * element);
//    void callbackSnailDropDone(FMGameElement * element);
    
//    //ghost
//    void callbackGhostMoveDone(FMGameElement * element);
public:
    static FMGameNode * create();
    virtual void update(float delta);
private:
//CCB Bindings:
    CCNode * m_centerNode;
    CCNode * m_moveNode;
    CCLayerColor * m_colorLayer;
    CCNode * m_boosterParent;
    CCNode * m_boosterUseParent;
//    CCLabelBMFont * m_levelLabel;
    void clickUIButton(CCObject * object, CCControlEvent event);
    void clickBooster(CCObject * object, CCControlEvent event);
    void clickCancelBooster(CCObject * object, CCControlEvent event);
//animation callback
    void completedAnimationSequenceNamed(const char *name);
#ifdef DEBUG
    CCNode * m_debugMenu;
    CCNode * m_editor;
    CCSprite * m_debugCheatIcon;
    CCLayer * m_sliderParent;
    CCSprite * m_toolIcon;
    CCLabelTTF * m_toolInfo;
    CCNode * m_debugButtonsParent;
    CCLayer * m_childSliderParent;
    std::vector<int> m_boxids;
    int m_selectBoxid;
    int m_childMode;
    bool m_cheatMode; 
    bool m_isEditorMode;
    bool m_isStatusOn;
    bool m_isCheated;
    CCPoint m_currentCoord;
    
    //debug menu
    void clickDebugEditLevel(); 
    void clickDebugSwitchLevel();
    void clickDebugCheatMode();
    void clickDebugPassLevel();
    void clickDebugAddSeed();
    void switchLevelHandle(CCNode * node);
    
    //editor
    void clickDebugPlayLevel();
    void clickDebugSaveData();
    void clickDebugConfig();
    void clickDebugUpload();
    void clickDebugClearTutorial();
    void clickEditorGetGrid();
    void handleUploadDialog(GAMEUI_Dialog * dialog);
    void clickItem(CCObject * object, CCControlEvent event);
    void clickSubItem(CCObject * object, CCControlEvent event);
    void showElements(bool show);
    void showSpawner(bool show);
    void changeGridData(int row, int col);
    void setToolIconWithGrid(FMGameGrid * grid);
    void updateLevelData();
    void setCheated(bool cheated);
public:
    bool isCheated() { return m_isCheated; }
    void testLevel();
private:
    
    virtual CCNode * createItemForSlider(GUIScrollSlider * slider);
    virtual int itemsCountForSlider(GUIScrollSlider * slider);
    virtual void sliderUpdate(GUIScrollSlider * slider, int rowIndex, CCNode * node);
#endif
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual void animationEnded(NEAnimNode * node, const char * animName);
    virtual void animationCallback(NEAnimNode * node, const char * animName, const char * callback);
    
    
//    void clickTest();
//    void clickTest2(); 
    bool m_test;
    //touch:
private:
    CCPoint m_touchBeginPoint;
protected:
    virtual bool ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchMoved(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchCancelled(CCTouch *pTouch, CCEvent *pEvent);
    virtual void pause(){ GAMEUI::pause();}
    virtual void resume(){GAMEUI::resume();}

};
#endif /* defined(__FarmMania__FMGameNode__) */
