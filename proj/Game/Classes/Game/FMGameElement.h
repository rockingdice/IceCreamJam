//
//  FMGameElement.h
//  FarmMania
//
//  Created by  James Lee on 13-5-3.
//
//

#ifndef __FarmMania__FMGameElement__
#define __FarmMania__FMGameElement__

#include <iostream>
#include "cocos2d.h"
#include "NEAnimNode.h"

using namespace cocos2d;
using namespace neanim;
#define initDropSpeed ccp(0.f , -600.f)
#define initSlideSpeed ccp(412.f, 0.f)
typedef enum kElementType
{
    kElement_None = -1,
    kElement_Random = 0,
    kElement_1Red = 1,
    kElement_2Orange = 2,
    kElement_3Yellow = 3,
    kElement_4Green = 4,
    kElement_5Blue = 5,
    kElement_6Pink = 6,
} kElementType;

typedef enum kElementBombType
{
    kBomb_Horizon,
    kBomb_Vertical,
    kBomb_Cross,
    kBomb_Star
} kElementBombType;

#define kTag_Disabled 1001
#define kTag_Straw 1002

typedef struct ElementFile
{
    kElementType type;
    const char * file;
}ElementFile;

typedef enum kItemType
{
    kItemType_Gem = 2,
    kItemType_Booster1 = 4,
    kItemType_Booster2 = 5,
    kItemType_Booster3 = 6,
    kItemType_Booster4 = 7,
    kItemType_Booster5 = 8,
    kItemType_Booster6 = 9
}kItemType;

struct ElementMovePhase {
    int moveType;
    CCPoint targetPos;
    CCPoint speed;
};

typedef enum kElementStatus {
    kStatus_Disabled,
    kStatus_Frozen,
}kElementStatus;

typedef enum kControlFlag {
    kFlag_None = 0,
    kFlag_InitRandom = 1 << 0,
    kFlag_Spawned = 1 << 1,
    kFlag_MatchX = 1 << 2,
    kFlag_MatchY = 1 << 3,
    kFlag_MatchEnd = 1 << 4,
    kFlag_Movable = 1 << 5,
    kFlag_Swappable = 1 << 6,
    kFlag_ShuffleAble = 1 << 7,
    kFlag_Matchable = 1 << 8
}kControlFlag;


class FMGameElement : public CCObject {
public:
    FMGameElement();
    ~FMGameElement();
    
private:
    kElementType m_elementType;
    kElementBombType m_bombType;
public:
    void setElementType(kElementType type); //directly change the type
    kElementType getElementType() { return m_elementType;}
    kElementType getElementPrototype(); //can be expressed a type of element
    void setBombType(kElementBombType bombType);
    kElementBombType getBombType() { return m_bombType; }
    //status
private:
    std::set<kElementStatus> m_status; //frozen, disabled
public:
    bool hasStatus(kElementStatus status) { return m_status.find(status) != m_status.end(); }
    void addStatus(kElementStatus status);
    bool canAddStatus(kElementStatus status);
    void removeStatus(kElementStatus status);
    void cleanStatus();
    
    //cached for later use
    int m_color;
    bool m_isMatchable;

    //used for calculate moving
private:
    CCPoint m_velocity;
    std::vector<ElementMovePhase> m_movePhases;
    ElementMovePhase * m_currentMovePhase;
public:
    int updateMoving(float delta);
    void DelayMove(float time);
    void DropMove(CCPoint p, CCPoint speed);
    void SlideMove(CCPoint p, CCPoint speed);
    void cleanMoveQueue() { m_movePhases.clear(); }
    bool isMoveDone() { return m_movePhases.size() == 0;}

    
public:
    int m_elementFlag;  //initrandom, spawned, match flags, etc
    int m_matchGroup;
    int m_countDown;    //element has round countdown property
    int m_endurance;    //element has hp property
private:
    NEAnimNode * m_animNode;
    CCSprite * m_selectedGrid;
public:
    NEAnimNode * getAnimNode() { return m_animNode; }
    void playAnimation(const char * animName);
    void updateFlags();
    int getMatchColor();
    static int getMatchColor(int type);
    int getElementColor(){return m_color;}
    bool isMatched() { return m_matchGroup != -1; }
    void setZOrder(int zOrder);
    void makeSurprise();
    void makeNormal();
    void restoreState();
    static bool isBaseElement(kElementType type) { return type >= kElement_1Red && type <= kElement_6Pink;}
    static const char * getElementSkin(kElementType type);
    static void changeAnimNode(NEAnimNode * anim, kElementType type);

//use item
    void showSelected(bool shown);
    bool isSelected() { return m_selectedGrid->isVisible(); }
    bool acceptBooster(int booster);
     
//disable

////snail
//    NEAnimNode * generateSnailAnim();
//    void destroySnailAnim();
//    void setSnailOn(NEAnimNode * snailAnim);
//    bool isSnailOn() { return m_snailAnim != NULL; }
//    NEAnimNode * getSnailAnim() { return m_snailAnim; }
//    int getSnailStatus() { return m_snailRecoverTurn; }
//    bool hitSnail(int combo);
//    void snailCountDown();
//    bool isCombineType();
    static int getColorIndex(kElementType type);

//control
    int getElementControlType();
    
//type convert
    void convertToElementType(CCInteger * type);
    
//ghost
    void countDown();
    void setCountDown(int count);
    int getCountDown();
//    bool isGhostType() { return isGhostType(m_elementType); }
//    static bool isGhostType(kElementType type) { return type >= kElement_Ghost1Red && type <= kElement_Ghost6Pink; }
//    bool isGhostFirstRound() {return m_isfirstRound;}
//    void setGhostFirstRound(bool flag) {m_isfirstRound = flag;}
//    void ghostEaten();
//    void ghostEatenCallback();
    
//changecolor candy
//    void changeColor(kElementType type);
    
//    static bool isJelloType(kElementType type) { return type >= kElement_1RedJello && type <= kElement_6PinkJello; }
    
    //switch element
//    kElementType m_resultType;
//    static bool isSwitchElementType(kElementType type) { return type >= kElement_SwitchRed && type <= kElement_SwitchPink; }
//    kElementType getSwitchType();
//    void switchType();
//    CCString* getSkinBeforeSwithType();
//    bool m_originalType;
    
    
//    //bed
//    static bool isBedType(kElementType type) { return type >= kElement_BedRed && type <= kElement_BedRandom; }
//    bool m_notChangedColor; //是否没改变过颜色
    
    
};

#endif /* defined(__FarmMania__FMGameElement__) */
