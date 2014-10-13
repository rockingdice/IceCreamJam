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
    m_color(-1),
    m_objIndex(-1),
    m_isMatchable(false),
    m_matchGroup(-1),
    m_velocity(CCPointZero),
    m_currentMovePhase(NULL),
    m_countDown(0),
    m_endurance(0),
    m_elementFlag(0)
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
    else
    {

    }

}

void FMGameElement::setElementType(kElementType type)
{
#ifdef DEBUG
    if (m_animNode->getChildByTag(12334) != NULL) {
        m_animNode->removeChildByTag(12334);
    }
#endif
    m_endurance = 0;
    m_countDown = 0;

    changeAnimNode(m_animNode, type);
    m_color = (type-kElement_1Red) % 6;
    m_elementType = type;
    updateFlags();
}

kElementType FMGameElement::getElementPrototype()
{
    return m_elementType;
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
            if (m_elementFlag & kFlag_Spawned) {
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

void FMGameElement::showSelected(bool shown)
{
    m_selectedGrid->setVisible(shown);
}

bool FMGameElement::acceptBooster(int booster)
{
    return true;
}

void FMGameElement::makeSurprise()
{
}

void FMGameElement::makeNormal()
{
    if (m_elementFlag & kFlag_Movable) {
        getAnimNode()->playAnimation("Bounce");
    }
}

void FMGameElement::restoreState()
{
    if (!canAddStatus(kStatus_Frozen)) {
        return;
    }
    if (hasStatus(kStatus_Frozen)) {
        getAnimNode()->playAnimation("Frozen");
    }
    else {
        getAnimNode()->playAnimation("Init");
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
    if (hasStatus(kStatus_Disabled) || !m_isMatchable)
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


 
void FMGameElement::addStatus(kElementStatus status)
{
    if (!hasStatus(status)) {
        m_status.insert(status);
        //do status related logic here
    }
}

void FMGameElement::removeStatus(kElementStatus status)
{
    if (hasStatus(status)) {
        m_status.erase(status);
        //do status related logic here
    }
}

void FMGameElement::cleanStatus()
{
    std::set<kElementStatus> status;
    status.insert(m_status.begin(), m_status.end());
    for (std::set<kElementStatus>::iterator it = status.begin(); it != status.end(); it++) {
        kElementStatus s = *it;
        removeStatus(s);
    }
}

bool FMGameElement::canAddStatus(kElementStatus status)
{
    //do status related logic here
    
}

void FMGameElement::updateFlags()
{
    m_elementFlag = 0;
    
    m_elementFlag |= kFlag_Movable;
    m_elementFlag |= kFlag_Swappable;
    m_elementFlag |= kFlag_ShuffleAble;
    m_elementFlag |= kFlag_Matchable;
}