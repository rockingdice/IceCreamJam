//
//  FMLoopGroup.cpp
//  FarmMania
//
//  Created by James Lee on 13-5-29.
//
//

#include "FMLoopGroup.h"
#include "FMGameGrid.h"
#include "FMGameNode.h"

FMLoopGroup::FMLoopGroup()
{
    
}

FMLoopGroup::~FMLoopGroup()
{
    
}

void FMLoopGroup::animationCallback(neanim::NEAnimNode *node, const char *animName, const char *callback)
{
    if (strcmp(callback, "nextMarquee") == 0) {
        //next
        int i = (int)node->getUserData();
//        for (; i<m_borderNodes.size(); i++) {
//            if (node == m_borderNodes[i].node) {
//                break;
//            }
//        }
        i++;
        if (i >= m_borderNodes.size()) {
            i = 0;
        }
        
        MarqueeData & d = m_borderNodes.at(i);
        NEAnimNode * n = d.node;
        if (n) {
            n->playAnimation(d.fileName.c_str());
            n->setDelegate(this);
            n->setUserData((void *)i);
        }
    }
}

void FMLoopGroup::playMarquee()
{
    int currentIndex = 0;
    while (currentIndex < m_borderNodes.size()) {
        MarqueeData & d = m_borderNodes.at(currentIndex);
        NEAnimNode * n = d.node;
        if (n) {
            n->playAnimation(d.fileName.c_str());
            n->setDelegate(this);
            n->setUserData((void *)currentIndex);
        }
        currentIndex += 3;
    }
}

void FMLoopGroup::stopMarquee()
{
    for (std::vector<MarqueeData>::iterator it = m_borderNodes.begin(); it != m_borderNodes.end(); it++) {
        MarqueeData & data = *it;
        std::string file = data.normalFileName;
        data.node->playAnimation(file.c_str());
    }
}