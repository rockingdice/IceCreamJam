//
//  FMGameWall.h
//  JellyMania
//
//  Created by  James Lee on 14-1-4.
//
//

#ifndef __JellyMania__FMGameWall__
#define __JellyMania__FMGameWall__

#include <iostream>
#include "NEAnimNode.h"
#include "cocos2d.h"
using namespace cocos2d;
using namespace cocos2d::extension;
using namespace neanim;

typedef enum kWallType {
    kWallNone = -1,
    kWallNormal = 0,
    kWallBreak = 1
} kWallType;

class FMGameWall : public CCObject {
public:
    FMGameWall(bool vertical);
    ~FMGameWall();
private:
    NEAnimNode * m_animNode;
    kWallType m_wallType;
    bool m_isVertical;
    CCPoint m_coord;
public:
    NEAnimNode * getAnimNode() { return m_animNode; }
    void setWallType(kWallType type);
    kWallType getWallType() { return m_wallType; }
    void setCoord(int row, int col);
    bool breakWall();
};
#endif /* defined(__JellyMania__FMGameWall__) */
