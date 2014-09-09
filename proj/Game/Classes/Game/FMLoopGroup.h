//
//  FMLoopGroup.h
//  FarmMania
//
//  Created by James Lee on 13-5-29.
//
//

#ifndef __FarmMania__FMLoopGroup__
#define __FarmMania__FMLoopGroup__

#include <iostream>
#include "cocos2d.h"
#include "NEAnimNode.h"
using namespace cocos2d;
using namespace neanim;
class FMGameGrid;

struct MarqueeData { 
    NEAnimNode * node;
    std::string fileName;
    std::string normalFileName;
};
class FMLoopGroup : public CCObject, public NEAnimCallback
{
public:
    FMLoopGroup();
    ~FMLoopGroup();
    std::vector<MarqueeData> m_borderNodes;
    
    virtual void animationEnded(NEAnimNode * node, const char * animName) {}
    virtual void animationCallback(NEAnimNode * node, const char * animName, const char * callback);
    void playMarquee();
    void stopMarquee();
};

#endif /* defined(__FarmMania__FMLoopGroup__) */
