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
//    kElement_1RedBad = 7,
//    kElement_2OrangeBad = 8,
//    kElement_3YellowBad = 9,
//    kElement_4GreenBad = 10,
//    kElement_5BlueBad = 11,
//    kElement_6PinkBad = 12,
//    kElement_Grow1 = 101,
//    kElement_Grow2 = 113,
//    kElement_Grow3 = 114,
//    kElement_Egg1 = 102,
//    kElement_Egg2 = 103,
//    kElement_Egg3 = 104,
//    kElement_4Split1 = 105,
//    kElement_4Split2 = 109,
//    kElement_4Split3 = 110,
//    kElement_3Split1 = 106,
//    kElement_3Split2 = 111,
//    kElement_3Split3 = 112,
//    kElement_Snail = 108,
//    kElement_1RedJello = 120,
//    kElement_2OrangeJello = 121,
//    kElement_3YellowJello = 122,
//    kElement_4GreenJello = 123,
//    kElement_5BlueJello = 124,
//    kElement_6PinkJello = 125,
//    kElement_Cannon1 = 130,
//    kElement_Cannon2 = 131,
//    kElement_Cannon3 = 132,
//    kElement_Cannon4 = 133,
//    kElement_Ghost1Red = 140,
//    kElement_Ghost2Orange = 141,
//    kElement_Ghost3Yellow = 142,
//    kElement_Ghost4Green = 143,
//    kElement_Ghost5Blue = 144,
//    kElement_Ghost6Pink = 145,
//    kElement_GhostStun1Red = 146,
//    kElement_GhostStun2Orange = 147,
//    kElement_GhostStun3Yellow = 148,
//    kElement_GhostStun4Green = 149,
//    kElement_GhostStun5Blue = 150,
//    kElement_GhostStun6Pink = 151,
//    kElement_4Split1_Red = 160,
//    kElement_4Split1_Orange = 161,
//    kElement_4Split1_Yellow = 162,
//    kElement_4Split1_Green = 163,
//    kElement_4Split1_Blue = 164,
//    kElement_4Split1_Pink = 165,
//    kElement_4Split2_Red = 166,
//    kElement_4Split2_Orange = 167,
//    kElement_4Split2_Yellow = 168,
//    kElement_4Split2_Green = 169,
//    kElement_4Split2_Blue = 170,
//    kElement_4Split2_Pink = 171,
//    kElement_4Split3_Red = 172,
//    kElement_4Split3_Orange = 173,
//    kElement_4Split3_Yellow = 174,
//    kElement_4Split3_Green = 175,
//    kElement_4Split3_Blue = 176,
//    kElement_4Split3_Pink = 177,
//    kElement_ChangeColor = 180,
//    kElement_Drop = 190,
//    kElement_TargetIce = 200,
//    kElement_TargetWall = 201,
//    kElement_Target4Match = 202,
//    kElement_TargetTMatch = 203,
//    kElement_Target5Line = 204,
//    
//    kElement_SwitchRed = 301,
//    kElement_SwitchOrange = 302,
//    kElement_SwitchYellow = 303,
//    kElement_SwitchGreen = 304,
//    kElement_SwitchBlue = 305,
//    kElement_SwitchPink = 306,
//    
//    kElement_BedRed = 401,
//    kElement_BedOrange = 402,
//    kElement_BedYellow = 403,
//    kElement_BedGreen = 404,
//    kElement_BedBlue = 405,
//    kElement_BedPink = 406,
//    kElement_BedRandom = 407,
//    kElement_TargetBed = 408,
//    kElement_PlaceHold = 409,
    
    
} kElementType;

typedef enum kElementAnimTag
{
    kTag_Disabled = 1117,
    kTag_Snail = 1118,
    kTag_Straw = 1119,
} kElementAnimTag;

typedef enum kElementControlType
{
    kElementCT_Match,
    kElementCT_Beside,
    kElementCT_Other,
} kElementControlType;


typedef struct ElementFile
{
    kElementType type;
    const char * file;
}ElementFile;

typedef enum kItemType
{
    kItemType_Gem = 2,
    kItemType_Mushroom = 3,
    kItemType_Booster1 = 4,
    kItemType_Booster2 = 5,
    kItemType_Booster3 = 6,
    kItemType_Booster4 = 7,
    kItemType_Booster5 = 8,
    kItemType_Booster6 = 9
}kItemType;

enum ELEMENTXID {
    XID_None = -1,
    //these for change xid
    XID_Element_Body = 1000,
    XID_Element_Eye = 1001,
    XID_Element_Mouth = 1002,
    XID_Element_Eye_Shock = 1003,
    XID_Element_Mouth_Shock = 1004,
    XID_Element_Eye_Shut = 1005,
    //end
    //these are reference only
    XID_Element_Body_Normal_Start = 1,
    XID_Element_Eye_Normal_Start = 7,
    XID_Element_Mouth_Normal_Start = 13,
    XID_Element_Eye_Shock_Start = 19,
    XID_Element_Mouth_Shock_Start = 25,
    XID_Element_Eye_Shut_Start = 31,
    XID_Element_Eye_Bad_Start = 37,
    XID_Element_Body_Bad_Start = 43,
    XID_Element_Mouth_Bad_Start = 49,
    XID_Element_WhiteAura_Start = 55,
    XID_Element_Body_Random = 9999
};

struct ElementMovePhase {
    int moveType;
    CCPoint targetPos;
    CCPoint speed;
};

class FMGameElement : public CCObject {
public:
    FMGameElement();
    ~FMGameElement();
    
private:
    kElementType m_elementType;
    bool m_isRot;
    bool m_isFrozen;
//used for matching
    int m_color;
    bool m_isMatchable;
public:
    bool m_matchX;  //matched in x axis
    bool m_matchY;  //matched in y axis
    int m_matchGroup;
    //4 match count, when 0 then check harvest
//    int m_4matchCount;
//    int m_harvestType;
    //used for match shoot
    int m_matchCount;
//used for init
    bool m_initRandom;
//used for spawning
    bool m_spawned; 
private:
//used for flower, bucket
    int m_phase;
    int m_combo;
    bool m_isTcross;
//used for moving
    CCPoint m_velocity;
    std::vector<ElementMovePhase> m_movePhases;
    ElementMovePhase * m_currentMovePhase;
//snail
    bool m_isDisabled;
    NEAnimNode * m_snailAnim;
    int m_snailRecoverTurn;
//ghost
    int m_countDown;
    bool m_isfirstRound;
private:
    NEAnimNode * m_animNode;
    CCSprite * m_selectedGrid;
public:
    NEAnimNode * getAnimNode() { return m_animNode; }
    void setElementType(kElementType type); //directly change the type 
    void breakIce();
    bool isFrozen() { return m_isFrozen; }
    void setFrozen(bool frozen);
    static bool canBeFrozen(kElementType type);
    kElementType getElementType(){return m_elementType;}
    kElementType getElementPrototype();
    bool isMovable();
    bool isSwappable();
    bool isShuffleAble();
    bool isMatchable() { return m_isMatchable; }
    int getMatchColor();
    static int getMatchColor(int type);
    int getElementColor(){return m_color;}
    bool isMatched() { return m_matchGroup != -1; }
    int updateMoving(float delta);
    void DelayMove(float time);
    void DropMove(CCPoint p, CCPoint speed);
    void SlideMove(CCPoint p, CCPoint speed);
    void cleanMoveQueue() { m_movePhases.clear(); }
    bool isMoveDone() { return m_movePhases.size() == 0;}
    void playAnimation(const char * animName);
    void setZOrder(int zOrder);
    void makeSurprise();
    void makeNormal();
    void restoreState();
    static bool isBaseElement(kElementType type) { return type >= kElement_1Red && type <= kElement_6Pink;}
    static const char * getElementSkin(kElementType type);
    static void changeAnimNode(NEAnimNode * anim, kElementType type);

////rot elements
//    bool isRotten() { return m_isRot; }
//    void switchxid(bool makeRot);
////flower bucket
//    bool addPhase(int combo, bool isTcross = false);
//    int getPhase() { return m_phase; }
//    void resetPhase() { m_phase = 0; }
//    void resetCombo() { m_combo = 0; m_isTcross = false;}
//    bool isBesideType(bool isTcross);
//use item
    void showSelected(bool shown);
    bool isSelected() { return m_selectedGrid->isVisible(); }
    bool acceptBooster(int booster);
    
    void addSwapHand();
    void removeSwapHand();
//disable
    bool isDisabled() { return m_isDisabled; }
    void setDisabled(bool disabled);
    bool canBeDisabled();
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
