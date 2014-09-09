//
//  FMMatchGroup.h
//  FarmMania
//
//  Created by  James Lee on 13-5-13.
//
//

#ifndef __FarmMania__FMMatchGroup__
#define __FarmMania__FMMatchGroup__

#include <iostream>
#include "cocos2d.h"
#include "NEAnimNode.h"

using namespace neanim;
typedef enum {
    kMatch_None = -1,
    kMatch_3,
    kMatch_4,
    kMatch_5Cross,
    kMatch_5Line,
    kMatch_Jump,
} kMatchType;


class FMGameGrid;
class FMMatchGroup : public CCObject,  public NEAnimCallback{
public:
    FMMatchGroup();
    FMMatchGroup(std::set<FMGameGrid *> * grids, kMatchType type) { m_grids = grids; m_type = type; m_phase = 0;}
    ~FMMatchGroup();
    
private:
    std::map<CCNode *, int> m_animCheckList;
    std::map<CCNode *, int> m_synchronizedAnimList;
    std::map<CCNode *, const char *> m_animInfo;
    std::map<CCNode *, const char *> m_syncAnimInfo;
public:
    std::set<FMGameGrid *> * m_grids;
    FMGameGrid * m_grid;
protected:
    int m_phase;
    bool m_matchEnd;
    kMatchType m_type;
    int m_matchcolor;
    int m_color;
public:
    void addAnimNode(NEAnimNode * node, const char * info = NULL);
    void addCCNode(CCNode * node, CCActionInterval * action, const char * info = NULL);
    void addSyncAnimNode(NEAnimNode * node, const char * info = NULL);
    void addSyncCCNode(CCNode * node, CCActionInterval * action, const char * info = NULL);
    bool isAnimationDone(bool checkSync = true);
    int getPhase() { return m_phase; }
    void updateMatchType();
    void setMatchType(kMatchType type) { m_type = type; }
    bool isGridInGroup(FMGameGrid * grid);
    void cleanGrids();
    bool isMatchEnd() { return m_matchEnd; }
    void setMatchEnd(bool matchEnd) { m_matchEnd = matchEnd; }
    kMatchType getMatchType() { return m_type; }
    void resetPhase() { m_phase = 0; }
    virtual void nextPhase() { m_phase++; }
    virtual void animationEnded(NEAnimNode * node, const char * animName);
    virtual void animationCallback(NEAnimNode * node, const char * animName, const char * callback);
    void actionDone(CCNode * node);
    void syncActionDone(CCNode * node);
    void cleanCheckingAnims();
    void resetCheckingAnims();

    int getMatchColor() {return m_matchcolor; }
    int getElementColor() {return m_color; }
};

#endif /* defined(__FarmMania__FMMatchGroup__) */
