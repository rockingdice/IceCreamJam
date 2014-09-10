//
//  FMGameGrid.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-3.
//
//

#include "FMGameGrid.h"

float kGridWidth = 34.5f;
float kGridHeight = 35.f;
int kGridNum = 9;

FMGameGrid::FMGameGrid() :
    m_coord(CCPointMake(-1, -1)),
    m_elementPtr(NULL),
    m_seatNode(NULL),
    m_acceptSlide(true),
    m_gridType(kGridNone),
    m_elementType(kElement_None)
{
    m_gridNode = NEAnimNode::createNodeFromFile("FMGridBG.ani");
    m_gridNode->retain();
}

FMGameGrid::~FMGameGrid()
{
    m_gridNode->release();
    m_gridNode = NULL;
}

void FMGameGrid::setGridCoord(int row, int col)
{ 
    //test
    m_coord = ccp(row, col);
    m_gridNode->setPosition(ccp(col * kGridWidth, - row * kGridHeight));
} 

void FMGameGrid::setGridType(kGridType gridType)
{
    if (m_gridType == kGridGrass) {
        if (getAnimNode()->getChildByTag(2) != NULL) {
            getAnimNode()->removeChildByTag(2);
        }
        
        if (getAnimNode()->getChildByTag(1) != NULL) {
            getAnimNode()->removeChildByTag(1);
        }
    }
    m_gridType = gridType;
    
    if (isNone()) {
        m_gridNode->setVisible(false);
    }
    else {
        m_gridNode->setVisible(true);
        if (m_gridType == kGridNormal || m_gridType == kGridGrass) {
            int odd = (int)(m_coord.x + m_coord.y) % 2 == 1; 
            if (odd) {
                m_gridNode->playAnimation("GridLight");
            }
            else{
                m_gridNode->playAnimation("GridDark");
            } 
        }
        else {
            CCLOG("type unknown!!!");
        }
        if (m_gridType == kGridGrass) {
            NEAnimNode * grassGrid = NEAnimNode::createNodeFromFile("FMGridGrass.ani");
            grassGrid->playAnimation("GrassIdle");
            getAnimNode()->addChild(grassGrid, 1, 1);
            
            NEAnimNode * grassEffect = NEAnimNode::createNodeFromFile("FMGridBonusEffect.ani");
            getAnimNode()->addChild(grassEffect, 2, 2);
            grassEffect->playAnimation("+1");
        }
    }
}

void FMGameGrid::addGridStatus(kGridStatus status)
{
    if (m_status.find(status) != m_status.end()) {
        return;
    }
    m_status.insert(status);
    
    switch (status) {
//        case kStatus_JumpSeat:
//        {
//            if (!m_seatNode) {
//                m_seatNode = NEAnimNode::createNodeFromFile("FMGridSeat.ani");
//                m_seatNode->playAnimation("Init");
//                getAnimNode()->getParent()->addChild(m_seatNode, getAnimNode()->getZOrder()+1);
//                m_seatNode->setPosition(getPosition());
//            }
//        }
//            break;
        default:
            break;
    }
}

void FMGameGrid::removeGridStatus(kGridStatus status)
{
    std::set<int>::iterator it = m_status.find(status);
    if (it != m_status.end()) {
        m_status.erase(it);
    }
//    switch (status) {
//        case kStatus_JumpSeat:
//        {
//            if (m_seatNode) {
//                m_seatNode->removeFromParent();
//            }
//            m_seatNode = NULL;
//        }
//            break;
//            
//        default:
//            break;
//    }
}

bool FMGameGrid::hasGridStatus(kGridStatus status)
{
    std::set<int>::iterator it = m_status.find(status);
    if (it != m_status.end()) {
        return true;
    }
    return false;
}

void FMGameGrid::cleanGridStatus()
{
    std::set<int> status = m_status;
    for (std::set<int>::iterator it = status.begin(); it != status.end(); it++) {
        int s = *it;
        removeGridStatus((kGridStatus)s);
    }
}

bool FMGameGrid::isMovable()
{
    return !isNone() && isEmpty();
}

bool FMGameGrid::isSwappable()
{
    if (isNone()) {
        return false;
    }
    if (m_elementPtr) {
        return m_elementPtr->m_elementFlag & kFlag_Swappable;
    }
    return false;
}

bool FMGameGrid::isExistMovableElement()
{
    bool exist = false;
    if (m_elementPtr && m_elementPtr->m_elementFlag & kFlag_Movable) {
        exist = true;
    }
    return exist;
}

bool FMGameGrid::isExistImmovableElement()
{
    bool exist = false;
    if (m_elementPtr && !m_elementPtr->m_elementFlag & kFlag_Movable) {
        exist = true;
    }
    return exist;
}

void FMGameGrid::setOccupyElement(FMGameElement *element)
{ 
    m_elementPtr = element;
    if (m_elementPtr) {
        m_elementPtr->getAnimNode()->getParent()->reorderChild(m_elementPtr->getAnimNode(), (m_coord.x+1) * 5);
    }
}

void FMGameGrid::queueSpawnElement(FMGameElement *element)
{
    element->m_elementFlag &= ~kFlag_Spawned;
    element->getAnimNode()->setVisible(false);
    m_spawnQueue.push_back(element);
    if (m_spawnQueue.size() == 1) {
        //begin spawning
        spawnNextElement();
    }
}

void FMGameGrid::update(float delta)
{
    if (m_spawnQueue.size() != 0) {
        FMGameElement * currentElement = m_spawnQueue.front();
        CCPoint p = currentElement->getAnimNode()->getPosition();
        if (p.y <= m_gridNode->getPosition().y) {
            //next element
            m_spawnQueue.erase(m_spawnQueue.begin());
            if (m_spawnQueue.size() != 0) {
                spawnNextElement();
            }
        }
    }
}

void FMGameGrid::spawnNextElement()
{
    FMGameElement * element = m_spawnQueue.front();
    element->getAnimNode()->setPosition(ccp(m_coord.y * kGridWidth, - (m_coord.x-1) * kGridHeight));
    element->getAnimNode()->setVisible(true);
    element->m_elementFlag |= kFlag_Spawned;
}

void FMGameGrid::cleanSpawnQueue()
{ 
    m_spawnQueue.clear();
}

CCPoint FMGameGrid::getPosition()
{
    return m_gridNode->getPosition();
}

bool FMGameGrid::canAddSellingBonus(bool isSelf)
{
    if (m_gridType == kGridNone) {
        return false;
    }
//    FMGameElement * e = getElement();
//    if (isSelf) {
//        if (m_gridBonus != kBonus_None) {
//            return false;
//        }
//        if (e) {
//            kElementType type = e->getElementType();
//            if (type > 100 && !e->isCombineType()) {
//                return false;
//            }
//            if (e->isFrozen()) {
//                return false;
//            }
//        }
//    }
    
    return true;
}