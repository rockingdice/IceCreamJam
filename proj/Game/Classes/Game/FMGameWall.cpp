//
//  FMGameWall.cpp
//  JellyMania
//
//  Created by  James Lee on 14-1-4.
//
//

#include "FMGameWall.h"
extern float kGridWidth;
extern float kGridHeight;

FMGameWall::FMGameWall(bool vertical)
{
    m_animNode = NEAnimNode::createNodeFromFile("FMElements_CandyWall.ani");
    m_animNode->retain();
    m_isVertical = vertical;
    m_animNode->useSkin(m_isVertical ? "Horizon" : "Vertical");
}

FMGameWall::~FMGameWall()
{
    m_animNode->release();
    m_animNode = NULL;
}

void FMGameWall::setWallType(kWallType type)
{
    m_animNode->setVisible(true);
    switch (type) {
        case kWallNone:
        {
            m_animNode->setVisible(false);
        }
            break;
        case kWallNormal:
        {
            m_animNode->playAnimation("1Idle");
        }
            break;
        case kWallBreak:
        {
            m_animNode->playAnimation("2Idle");
        }
            break;
        default:
            break;
    }
    m_wallType = type;
}

void FMGameWall::setCoord(int row, int col)
{
    m_coord = CCPoint(row, col);
    CCPoint p;
    if (!m_isVertical) {
        p.x = (row + 0.5f) * kGridWidth;
        p.y = -col * kGridHeight;
    }
    else {
        p.y = -(row + 0.5f) * kGridHeight;
        p.x = col * kGridWidth;
    }
    m_animNode->setPosition(p);
}

bool FMGameWall::breakWall()
{
    switch (m_wallType) {
        case kWallNone:
            return false;
        case kWallNormal:
        {
            m_animNode->playAnimation("1-2");
            m_wallType = kWallBreak;
        }
            break;
        case kWallBreak:
        {
            m_animNode->playAnimation("2-0");
            m_wallType = kWallNone;
            return true;
        }
            break;
        default:
            break;
    }
    return false;
}