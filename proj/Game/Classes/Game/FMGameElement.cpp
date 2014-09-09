//
//  FMGameElement.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-3.
//
//

#include "FMGameElement.h"
#include "FMGameNode.h"
#include "FMSoundManager.h"
#include "FMGameGrid.h"

#define kTagSwapHand 1010

FMGameElement::FMGameElement() :
    m_elementType(kElement_None),
    m_isRot(false),
    m_isFrozen(false),
    m_color(-1),
    m_isMatchable(false),
    m_matchX(false),
    m_matchY(false),
    m_matchGroup(-1),
    m_initRandom(true),
    m_spawned(true),
    m_phase(0),
    m_combo(0),
    m_isTcross(false),
    m_velocity(CCPointZero),
    m_currentMovePhase(NULL),
    m_isDisabled(false),
    m_snailAnim(NULL),
    m_snailRecoverTurn(-1),
    m_countDown(0),
    m_isfirstRound(false)
{
    
    m_animNode = NEAnimNode::createNodeFromFile("FMElements.ani");
    m_animNode->retain();
    m_animNode->playAnimation("Init");
    m_animNode->setSmoothPlaying(true);
        
    m_selectedGrid = CCSprite::createWithSpriteFrameName("Map.plist|selected.png");
    m_selectedGrid->setVisible(false);
    m_animNode->addChild(m_selectedGrid, -1);
    
    setElementType(kElement_4Green); 
}

FMGameElement::~FMGameElement()
{
    if (m_animNode->getParent()) {
        m_animNode->removeFromParent();
    }
    m_animNode->release();
}

const char * FMGameElement::getElementSkin(kElementType type)
{
    if (type == kElement_Random || type == kElement_None) {
        return "Random";
    }
    else if (type <= kElement_6Pink) {
        static const char * skins[6] = {"Red", "Orange", "Yellow", "Green", "Blue", "Purple"};
        return skins[type-1];
    }
//    else if (type <= kElement_6PinkBad) {
//        static const char * badskins[6] = {"RedBad", "OrangeBad", "YellowBad", "GreenBad", "BlueBad", "PurpleBad"};
//        return badskins[type-7];
//    }
//    else if (type >= kElement_1RedJello && type <= kElement_6PinkJello){
//        static const char * jelloSkins[6] = {"JelloRed", "JelloOrange", "JelloYellow", "JelloGreen", "JelloBlue", "JelloPurple"};
//        return jelloSkins[type-kElement_1RedJello];
//    }
//    else if (type >= kElement_4Split1_Red && type <= kElement_4Split3_Pink) {
//        static const char * split4Skins[6] = {"Red", "Orange", "Yellow", "Green", "Blue", "Purple"};
//        int color = (type - kElement_4Split1_Red) % 6;
//        return split4Skins[color];
//    }
//    else if (type >= kElement_Ghost1Red && type <= kElement_GhostStun6Pink) {
//        static const char * ghostSkins[6] = {"Red", "Orange", "Yellow", "Green", "Blue", "Purple"};
//        int color = (type - kElement_Ghost1Red) % 6;
//        return ghostSkins[color];
//    }
//    else if (type <= kElement_SwitchPink && type >= kElement_SwitchRed) {
//        static const char * badskins[6] = {"RedHat", "OrangeHat", "YellowHat", "GreenHat", "BlueHat", "PurpleHat"};
//        return badskins[type-301];
//    }
//    else if (type <= kElement_BedRandom && type >= kElement_BedRed) {
//        static const char * badskins[7] = {"red", "orange", "yellow", "green", "blue", "purple","random"};
//        return badskins[type-401];
//    }
    else {
        return "Random";
    }
}

void FMGameElement::changeAnimNode(neanim::NEAnimNode *anim, kElementType type)
{
    if (type < 100) {
        //color element
        anim->changeFile("FMElements.ani");
        anim->playAnimation("Init");
        if (type == kElement_Random) {
            anim->useSkin("Random");
        }
        else if (type == kElement_None) {
            anim->useSkin("None");
        }
        else if (type < 7) {
            //normal element
            const char * skinName = getElementSkin(type);
            anim->useSkin(skinName);
        }
        else if (type < 13) {
            const char * skinName = getElementSkin(type);
            anim->useSkin(skinName);
        }
    }
//    else if (type >= kElement_1RedJello && type <= kElement_6PinkJello) {
//        anim->changeFile("FMElements.ani");
//        anim->playAnimation("Init");
//        const char * skinName = getElementSkin(type);
//        anim->useSkin(skinName);
//    }
//    else if (type >= kElement_4Split1_Red && type <= kElement_4Split3_Pink) {
//        int state = 1 + (type - kElement_4Split1_Red) / 6;
//        const char * skinName = getElementSkin(type);
//        anim->changeFile("FMElements_Split4.ani");
//        anim->playAnimation(CCString::createWithFormat("Splitfour%dIdle", state)->getCString());
//        anim->useSkin(skinName);
//    }
//    else if (type >= kElement_Ghost1Red && type <= kElement_GhostStun6Pink) {
//        const char * skinName = getElementSkin(type);
//        anim->changeFile("FMElements_Ghost.ani");
//        anim->useSkin(skinName);
//        if (type <= kElement_Ghost6Pink) {
//            anim->playAnimation("NormalIdle");
//        }
//        else {
//            anim->playAnimation("GiddyIdle");
//        }
//    }
//    else if (type >= kElement_SwitchRed && type <= kElement_SwitchPink){
//        anim->changeFile("FMElements.ani");
//        const char * skinName = getElementSkin(type);
//        anim->useSkin(skinName);
//        anim->playAnimation("Init");
//    }
//    else if (type >= kElement_BedRed && type <= kElement_BedRandom){
//        anim->changeFile("Bounce.ani");
//        const char * skinName = getElementSkin(type);
//        anim->useSkin(skinName);
//        anim->playAnimation("jump");
//    }
    else
    {
//        switch (type) {
//            case kElement_Grow1:
//            {
//                anim->changeFile("FMElements_Grow.ani");
//                anim->playAnimation("Grow1Idle");
//            }
//                break;
//            case kElement_Grow2:
//            {
//                anim->changeFile("FMElements_Grow.ani");
//                anim->playAnimation("Grow2Idle");
//            }
//                break;
//            case kElement_Grow3:
//            {
//                anim->changeFile("FMElements_Grow.ani");
//                anim->playAnimation("Grow3Idle");
//            }
//                break;
//            case kElement_3Split1:
//            {
//                anim->changeFile("FMElements_Split3.ani");
//                anim->playAnimation("SplitThree1Idle");
//            }
//                break;
//            case kElement_3Split2:
//            {
//                anim->changeFile("FMElements_Split3.ani");
//                anim->playAnimation("SplitThree2Idle");
//            }
//                break;
//            case kElement_3Split3:
//            {
//                anim->changeFile("FMElements_Split3.ani");
//                anim->playAnimation("SplitThree3Idle");
//            }
//                break;
//
//            case kElement_Egg1:
//            {
//                anim->changeFile("FMElements_Combine.ani");
//                anim->playAnimation("Combine1Idle");
//            }
//                break;
//            case kElement_Egg2:
//            {
//                anim->changeFile("FMElements_Combine.ani");
//                anim->playAnimation("Combine2Idle");
//            }
//                break;
//            case kElement_Egg3:
//            {
//                anim->changeFile("FMElements_Combine.ani");
//                anim->playAnimation("Combine3Idle");
//            }
//                break;
//            case kElement_Cannon1:
//            {
//                anim->changeFile("FMElements_Cannon.ani");
//                anim->playAnimation("Init");
//                anim->useSkin("Up");
//            }
//                break;
//            case kElement_Cannon2:
//            {
//                anim->changeFile("FMElements_Cannon.ani");
//                anim->playAnimation("Init");
//                anim->useSkin("Down");
//            }
//                break;
//            case kElement_Cannon3:
//            {
//                anim->changeFile("FMElements_Cannon.ani");
//                anim->playAnimation("Init");
//                anim->useSkin("Left");
//            }
//                break;
//            case kElement_Cannon4:
//            {
//                anim->changeFile("FMElements_Cannon.ani");
//                anim->playAnimation("Init");
//                anim->useSkin("Right");
//            }
//                break;
//            case kElement_ChangeColor:
//            {
//                anim->changeFile("FMElements.ani");
//                anim->playAnimation("Init");
//                anim->useSkin("Candy");
//            }
//                break;
//            case kElement_Drop:
//            {
//                anim->changeFile("FMElements_Queen.ani");
//                anim->playAnimation("Init");
//            }
//                break;
//            case kElement_TargetIce:
//            {
//                anim->changeFile("FMElements.ani");
//                anim->useSkin("Tice");
//                anim->playAnimation("TargetIdle");
//            }
//                break;
//            case kElement_TargetWall:
//            {
//                anim->changeFile("FMElements.ani");
//                anim->useSkin("Twall");
//                anim->playAnimation("TargetIdle");
//            }
//                break;
//            case kElement_Target4Match:
//            {
//                anim->changeFile("FMElements.ani");
//                anim->useSkin("T4");
//                anim->playAnimation("TargetIdle");
//            }
//                break;
//            case kElement_TargetTMatch:
//            {
//                anim->changeFile("FMElements.ani");
//                anim->useSkin("TT");
//                anim->playAnimation("TargetIdle");
//            }
//                break;
//            case kElement_Target5Line:
//            {
//                anim->changeFile("FMElements.ani");
//                anim->useSkin("T5");
//                anim->playAnimation("TargetIdle");
//            }
//                break;
//                
//            case kElement_TargetBed:
//            {   
//                anim->changeFile("Bounce.ani");
//                anim->useSkin("random");
//                anim->playAnimation("target");
//            }
//                break;
//                
//            default:
//                break;
//        }
    }

}

void FMGameElement::setElementType(kElementType type)
{
#ifdef DEBUG
    if (m_animNode->getChildByTag(12334) != NULL) {
        m_animNode->removeChildByTag(12334);
    }
#endif
//    CCLOG("PREVIOUS TYPE %d", m_elementType);
    m_isRot = false;
    m_isFrozen = false;
    m_phase = 0;
    m_countDown = 0;

    changeAnimNode(m_animNode, type);
    m_color = (type-kElement_1Red) % 6;
    m_elementType = type;
    
    m_isMatchable = true;
    if (0) {
        m_isMatchable = false;
    }
    
}

kElementType FMGameElement::getElementPrototype()
{
    return m_elementType;
//    //return the original type for data editing
//    if (m_elementType == kElement_Grow1) {
//        switch (m_phase) {
//            case 0:
//                return kElement_Grow1;
//            case 1:
//                return kElement_Grow2;
//            case 2:
//                return kElement_Grow3;
//            default:
//                return kElement_Grow1;
//        }
//    }
//    else if (m_elementType == kElement_4Split1){
//        kElementType type = (kElementType)(kElement_4Split1_Red + m_phase * 6 + m_color);
//        return type;
//    }
//    else if (m_elementType >= kElement_Ghost1Red && m_elementType <= kElement_Ghost6Pink) {
//        kElementType type = (kElementType)(kElement_Ghost1Red + m_phase * 6 + m_color);
//        return type;
//    }
//    else if (m_elementType == kElement_3Split1){
//        switch (m_phase) {
//            case 0:
//                return kElement_3Split1;
//            case 1:
//                return kElement_3Split2;
//            case 2:
//                return kElement_3Split3;
//            default:
//                return kElement_3Split1;
//        }
//    }
//    else if (m_elementType == kElement_Cannon1) {
//        switch (m_phase) {
//            case kDirection_U:
//                return kElement_Cannon1;
//            case kDirection_B:
//                return kElement_Cannon2;
//            case kDirection_L:
//                return kElement_Cannon3;
//            case kDirection_R:
//                return kElement_Cannon4;
//            default:
//                return kElement_Cannon1;
//        }
//    }
//    else {
//        return m_elementType;
//    }
}

bool FMGameElement::isMovable()
{
    bool movable = true;
    if (0) {
        movable = false;
    }
    if (m_isFrozen || m_isDisabled) {
        movable = false;
    }
    return movable;
}

bool FMGameElement::isSwappable()
{
    bool swappable = true;
    if (!isMovable()) {
        swappable = false;
    }
    return swappable;
}

static CCPoint dropSpd = ccp(0.f, -50.f);
static CCPoint dropAcc = ccp(0.f, -1980.f);
//static float slideSpeed = 200.f;
static float maxSpeed = 800.f;

int FMGameElement::updateMoving(float delta)
{  
    int moveResult = -1;    //-1=移动中 >=0 某种移动完毕
    if (m_movePhases.size() > 0) {
        ElementMovePhase phase = m_movePhases.front();
        if (phase.moveType == 0) {
            //drop
            CCPoint deltaV = ccpMult(dropAcc, delta);
            m_velocity = ccpAdd(m_velocity, deltaV);
            if (m_velocity.y < -maxSpeed) {
                m_velocity.y = -maxSpeed;
            }
            if (m_spawned) {
                CCPoint p = m_animNode->getPosition();
                p = ccpAdd(p, ccpMult(m_velocity, delta));
                if (p.y <= phase.targetPos.y) {
                    p.y = phase.targetPos.y;
                    moveResult = 0;
                }
                m_animNode->setPosition(p);
            }
        }
        else if (phase.moveType == 1){
            //slide
            CCAssert(!m_velocity.equals(CCPointZero), "sliding speed is zero!!");
            CCPoint p = m_animNode->getPosition();
            CCPoint p2 = ccpAdd(p, ccpMult(m_velocity, delta));
            float distance = ccpDistance(p, phase.targetPos);
            float movedistance = ccpDistance(p, p2);
            if (movedistance >= distance) {
                p2 = phase.targetPos;
                moveResult = 1;
            }
            m_animNode->setPosition(p2);
        }
        else if (phase.moveType == 2) {
            m_velocity.x += delta;
            if (m_velocity.x >= phase.targetPos.x) {
                moveResult = 2;
            }
        }
        if (moveResult != -1) {
            m_movePhases.erase(m_movePhases.begin());
//            m_velocity = CCPointZero;
            
            if (m_movePhases.size() != 0) {
                ElementMovePhase p = m_movePhases.front();
                m_currentMovePhase = &p;
                if (p.moveType == 1) {
                    playAnimation("Init");
                    CCAssert(!p.targetPos.equals(m_animNode->getPosition()), "sliding target cannot be the same!");
                    CCPoint vec = ccpSub(p.targetPos, m_animNode->getPosition());
                    vec = ccpNormalize(vec);
                    m_velocity = ccpMult(vec, p.speed.x / fabsf(vec.y));
                }
                else if (p.moveType == 0) {
                    playAnimation("Dropping"); 
                    m_velocity.x = 0;
                }
            }
            else {
                m_currentMovePhase = NULL;
            }
        }
    }

    if (m_movePhases.size() == 0) {
        m_velocity = ccp(0, 0);
    }
    return moveResult;
}

void FMGameElement::DelayMove(float time)
{ 
    m_movePhases.push_back((ElementMovePhase){2, ccp(time, 0)});
    if (!m_currentMovePhase) {
        m_currentMovePhase = &(m_movePhases.front());
    }
}

void FMGameElement::DropMove(cocos2d::CCPoint p, CCPoint dropSpeed)
{ 
    m_movePhases.push_back((ElementMovePhase){0, p, dropSpeed});
    if (!m_currentMovePhase) {
        m_currentMovePhase = &(m_movePhases.front());
        playAnimation("Dropping");
        m_velocity = m_currentMovePhase->speed;
    }
}

void FMGameElement::SlideMove(cocos2d::CCPoint p, CCPoint slideSpeed)
{
    ElementMovePhase phase;
    phase.targetPos = p;
    phase.moveType = 1;
    phase.speed = slideSpeed;
    m_movePhases.push_back(phase);
    if (!m_currentMovePhase) {
        m_currentMovePhase = &(m_movePhases.front());
        playAnimation("Init");
        CCPoint vec = ccpSub(m_currentMovePhase->targetPos, m_animNode->getPosition());
        vec = ccpNormalize(vec);
        m_velocity = ccpMult(vec, slideSpeed.x / fabsf(vec.y));
       
    }
}

void FMGameElement::playAnimation(const char *animName)
{
    if (m_animNode == NULL) {
        return;
    }
    m_animNode->playAnimation(animName);
}

void FMGameElement::setZOrder(int zOrder)
{ 
    m_animNode->getParent()->reorderChild(m_animNode, zOrder);
}

//bool FMGameElement::addPhase(int combo, bool isTcross)
//{
//    if (isBesideType(isTcross) || combo > m_combo) {
//        m_phase++;
//        m_combo = combo;
//        return true;
//    }
//    return false;
//}
//bool FMGameElement::isBesideType(bool isTcross)
//{
//    if (m_isTcross == isTcross && isTcross == true) {
//        return false;
//    }
//    if (isTcross) {
//        m_isTcross = isTcross;
//    }
//    bool flag = false;
//    switch (m_elementType) {
//        case kElement_Grow1:
//        case kElement_Grow2:
//        case kElement_Grow3:
//        case kElement_4Split1:
//        case kElement_4Split2:
//        case kElement_4Split3:
//        case kElement_3Split1:
//        case kElement_3Split2:
//        case kElement_3Split3:
//        case kElement_Snail:
//        case kElement_Ghost1Red:
//        case kElement_Ghost2Orange:
//        case kElement_Ghost3Yellow:
//        case kElement_Ghost4Green:
//        case kElement_Ghost5Blue:
//        case kElement_Ghost6Pink:
//        case kElement_GhostStun1Red:
//        case kElement_GhostStun2Orange:
//        case kElement_GhostStun3Yellow:
//        case kElement_GhostStun4Green:
//        case kElement_GhostStun5Blue:
//        case kElement_GhostStun6Pink:
//        case kElement_4Split1_Red:
//        case kElement_4Split1_Orange:
//        case kElement_4Split1_Yellow:
//        case kElement_4Split1_Green:
//        case kElement_4Split1_Blue:
//        case kElement_4Split1_Pink:
//        case kElement_4Split2_Red:
//        case kElement_4Split2_Orange:
//        case kElement_4Split2_Yellow:
//        case kElement_4Split2_Green:
//        case kElement_4Split2_Blue:
//        case kElement_4Split2_Pink:
//        case kElement_4Split3_Red:
//        case kElement_4Split3_Orange:
//        case kElement_4Split3_Yellow:
//        case kElement_4Split3_Green:
//        case kElement_4Split3_Blue:
//        case kElement_4Split3_Pink:
//        case kElement_ChangeColor:
//            flag = true;
//            break;
//            
//        default:
//            break;
//    }
//    return flag;
//}
//void FMGameElement::switchxid(bool makeRot)
//{
//    kElementType t = (kElementType)(makeRot ? m_color + kElement_1RedBad : m_color + kElement_1Red);
//    if (FMGameElement::isSwitchElementType(m_elementType)) {
//        t = (kElementType)(m_color + kElement_1RedBad -1);
//    }
//    
//    setElementType(t);
//    if (makeRot) {
//        const char * effect = FMSound::getRandomEffect("sad_01.mp3", "sad_02.mp3", "sad_03.mp3", NULL);
//        FMSound::playEffect(effect);
//        m_animNode->playAnimation("turnBad");
//    }
//    else {
//        FMSound::playEffect("switch.mp3");
//        m_animNode->playAnimation("turnGood");
//    }
//}
//
void FMGameElement::showSelected(bool shown)
{
    m_selectedGrid->setVisible(shown);
}

bool FMGameElement::acceptBooster(int booster)
{
//    switch (booster) {
//        case kBooster_Harvest1Grid:
//        {
//            if (m_elementType == kElement_Drop) {
//                return false;
//            }
//            if (isSnailOn()) {
//                if (getSnailStatus() == 0) {
//                    return true;
//                }
//                else
//                    return false;
//            }
//            if (m_elementType == kElement_Egg2 ||
//                m_elementType == kElement_Egg3) {
//                return false;
//            }
//            
//            if (FMGameElement::isBedType(m_elementType) ||
//                m_elementType == kElement_PlaceHold) {
//                return false;
//            }
//            
//            
//            //default is true
//            return true;
//        }
//            break;
//        case kBooster_Harvest1Row:
//        {
//            if (isSnailOn()) {
//                if (getSnailStatus() == 0) {
//                    return true;
//                }
//                else
//                    return false;
//            }
//            if (m_elementType <= kElement_6PinkBad ||
//                isGhostType(m_elementType) ||
//                isSwitchElementType(m_elementType)) {
//                return true;
//            }
//            else {
//                return false;
//            }
//        }
//            break;
//        case kBooster_Harvest1Type:
//        {
//            if (isFrozen()) {
//                return false;
//            }
//            if (isSnailOn()) {
//                return false;
//            }
//            if (m_elementType <= kElement_6PinkBad ||
//                FMGameElement::isSwitchElementType(m_elementType)) {
//                return true;
//            }
//            else {
//                return false;
//            }
//        }
//            break;
//        case kBooster_Shuffle:
//        {
//            return isSwappable();
//        }
//            break;
//        default:
//            break;
//    }
    return true;
}
void FMGameElement::addSwapHand()
{
    NEAnimNode * hand = NEAnimNode::createNodeFromFile("FMElements.ani");
    hand->playAnimation("SwapHand");
    getAnimNode()->addChild(hand,1000,kTagSwapHand);
}
void FMGameElement::removeSwapHand()
{
    getAnimNode()->removeChildByTag(kTagSwapHand);
    makeNormal();
}

void FMGameElement::makeSurprise()
{
//    if (m_elementType <= kElement_6Pink) {
//        getAnimNode()->playAnimation("Surprise"); 
////        CCString * effectString = CCString::createWithFormat("surprised_0%d.mp3", m_color);
////        FMSound::playEffect(effectString->getCString(), "surprise",  0.01f, 0.5f);
//        FMSound::playEffect("tap.mp3", 0.01f, 0.5f);
//    }
//    else if (m_elementType == kElement_Egg1) {
//        FMSound::playEffect("cloudsleep.mp3");
//    }
//    else if (m_elementType == kElement_Egg2) {
//        FMSound::playEffect("cloudwakeup.mp3");
//    }
}

void FMGameElement::makeNormal()
{
    if (isMovable()) {
        getAnimNode()->playAnimation("Bounce");
    }
}

void FMGameElement::restoreState()
{
    if (!canBeFrozen(m_elementType)) {
        return;
    }
    if (isFrozen()) {
        getAnimNode()->playAnimation("Frozen");
    }
    else {
        getAnimNode()->playAnimation("Init");
    }
}

void FMGameElement::breakIce()
{
    //play break ice animation
    setFrozen(false);
    FMSound::playEffect("ice.mp3");
}

bool FMGameElement::canBeFrozen(kElementType type)
{
//    if ((type >= kElement_Random && type <= kElement_6PinkBad) || type == kElement_Egg1 || type == kElement_Egg2) {
//        return true;
//    }
//    if (type >= kElement_1RedJello && type <= kElement_6PinkJello) {
//        return true;
//    }
    return false;
}

void FMGameElement::setFrozen(bool frozen)
{
    if (!canBeFrozen(m_elementType)) {
        return;
    }
    m_isFrozen = frozen;
//    if (m_isFrozen) {
//        if (m_elementType == kElement_Egg1) {
//            getAnimNode()->playAnimation("Combine1Frozen");
//        }
//        else if (m_elementType == kElement_Egg2) {
//            getAnimNode()->playAnimation("Combine2Frozen");
//        }
//        else {
//            getAnimNode()->playAnimation("Frozen");
//        }
//    }
//    else {
//        if (m_elementType == kElement_Egg1) {
//            getAnimNode()->playAnimation("Combine1Idle");
//        }
//        else if (m_elementType == kElement_Egg2) {
//            getAnimNode()->playAnimation("Combine2Idle");
//        }
//        else {
//            getAnimNode()->playAnimation("Init");
//        }
//    }

    
}

bool FMGameElement::canBeDisabled()
{
    if (isFrozen()) {
        return false;
    }
    kElementType type = m_elementType;
//    if ((type >= kElement_Random && type <= kElement_6PinkBad) ||
//        type == kElement_4Split1 ||
//        type == kElement_3Split1 ||
//        type == kElement_Grow1) {
//        return true;
//    }
    return false;
}

void FMGameElement::setDisabled(bool disabled)
{
    if (!canBeDisabled()) {
        return;
    }
    if (m_isDisabled == disabled) {
        return;
    }
    m_isDisabled = disabled;
    NEAnimNode * disableAnim = (NEAnimNode *)getAnimNode()->getChildByTag(kTag_Disabled);
    if (disableAnim == NULL) {
        disableAnim = NEAnimNode::createNodeFromFile("FMEffectDisabled.ani");
        getAnimNode()->addChild(disableAnim, 100, kTag_Disabled);
    }

    if (disabled) {
        disableAnim->setAutoRemove(false);
        disableAnim->playAnimation("appear");
    }
    else {
        disableAnim->setAutoRemove(true);
        disableAnim->playAnimation("disappear");
    }
}


int FMGameElement::getColorIndex(kElementType type)
{
    if (type >= kElement_1Red && type <= kElement_6Pink) {
        return type - kElement_1Red;
    }
    return -1;
}

void FMGameElement::convertToElementType(cocos2d::CCInteger *type)
{
    kElementType t = (kElementType)type->getValue();
    setElementType(t);
    getAnimNode()->setDelegate(NULL);
    playAnimation("Bounce");
}

int FMGameElement::getMatchColor()
{
    if (m_isDisabled || !m_isMatchable)
         return -1;
    if (m_elementType >= kElement_1Red && m_elementType <= kElement_6Pink) {
        return m_color + kElement_1Red;
    }
    return -1;
}
int FMGameElement::getMatchColor(int type)
{
    int tcolor = -1;
    if (type < 100) {
        //color element
        tcolor = (type-kElement_1Red) % 6;
    }
    
    if (type >= kElement_1Red && type <= kElement_6Pink) {
        return tcolor + kElement_1Red;
    }
    return -1;
}

void FMGameElement::countDown()
{
    m_countDown--;
}

int FMGameElement::getCountDown()
{
    return m_countDown;
}

void FMGameElement::setCountDown(int count)
{
    m_countDown = count;
}


bool FMGameElement::isShuffleAble()
{
    if (isMovable()) {
        return true;
    }
    return false;
}
