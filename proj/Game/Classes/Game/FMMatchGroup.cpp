//
//  FMMatchGroup.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-13.
//
//

#include "FMMatchGroup.h"
#include "FMGameGrid.h"
#include "FMGameElement.h"

FMMatchGroup::FMMatchGroup() :
    m_grid(NULL),
    m_grids(NULL),
    m_phase(0),
    m_type(kMatch_None),
    m_matchEnd(false),
    m_color(-1),
    m_matchcolor(-1)
{
    m_grids = new std::set<FMGameGrid *>();
    
}

FMMatchGroup::~FMMatchGroup()
{
    delete m_grids;
    m_grids = NULL;
}

void FMMatchGroup::addAnimNode(neanim::NEAnimNode *node, const char * info)
{
    if (m_animCheckList.find(node) != m_animCheckList.end()) {
        m_animCheckList[node]++;
    }
    else {
        m_animCheckList[node] = 1;
        m_animInfo[node] = info;
    }
    node->setDelegate(this);
}
 

void FMMatchGroup::addCCNode(cocos2d::CCNode *node, cocos2d::CCActionInterval *action, const char * info)
{
    if (m_animCheckList.find(node) != m_animCheckList.end()) {
        m_animCheckList[node]++;
    }
    else {
        m_animCheckList[node] = 1;
        m_animInfo[node] = info;
    }
    CCCallFuncO * call = CCCallFuncO::create(this, callfuncO_selector(FMMatchGroup::actionDone), node);
    CCSequence * seq = CCSequence::create(action, call, NULL);
    node->runAction(seq);
}

void FMMatchGroup::addSyncAnimNode(NEAnimNode * node, const char * info)
{
    if (m_synchronizedAnimList.find(node) != m_synchronizedAnimList.end()) {
        m_synchronizedAnimList[node]++;
    }
    else {
        m_synchronizedAnimList[node] = 1;
        m_syncAnimInfo[node] = info;
    }
    node->setDelegate(this);

}

void FMMatchGroup::addSyncCCNode(CCNode * node, CCActionInterval * action, const char * info)
{
    if (m_synchronizedAnimList.find(node) != m_synchronizedAnimList.end()) {
        m_synchronizedAnimList[node]++;
    }
    else {
        m_synchronizedAnimList[node] = 1;
        m_syncAnimInfo[node] = info;
    }
    CCCallFuncO * call = CCCallFuncO::create(this, callfuncO_selector(FMMatchGroup::syncActionDone), node);
    CCSequence * seq = CCSequence::create(action, call, NULL);
    node->runAction(seq);

}

void FMMatchGroup::animationEnded(neanim::NEAnimNode *node, const char *animName)
{
    if (m_animCheckList.find(node) != m_animCheckList.end()) {
        m_animCheckList[node]--;
        if (m_animCheckList[node] <= 0) {
            m_animCheckList.erase(node);
#ifdef DEBUG
            const char * info = m_animInfo[node];
            CCLog("%s is finished", info);
            m_animInfo.erase(node);
            std::stringstream ss;
            for (std::map<CCNode *, const char *>::iterator it = m_animInfo.begin(); it != m_animInfo.end(); it++) {
                const char * info = it->second;
                ss << info << " is still running" << "\n";
            }
            CCLog("current animations: %s", ss.str().c_str());
#endif
        }
    }
    if (m_synchronizedAnimList.find(node) != m_synchronizedAnimList.end()) {
        m_synchronizedAnimList[node]--;
        if (m_synchronizedAnimList[node] <= 0) {
            m_synchronizedAnimList.erase(node);
        }
    }
    if (m_animCheckList.size() == 0) {
        //done
        nextPhase();
    }
}

void FMMatchGroup::animationCallback(neanim::NEAnimNode *node, const char *animName, const char *callback)
{
    if (m_animCheckList.find(node) != m_animCheckList.end()) {
        m_animCheckList[node]--;
        if (m_animCheckList[node] <= 0) {
            m_animCheckList.erase(node);
        }
    }
    if (m_synchronizedAnimList.find(node) != m_synchronizedAnimList.end()) {
        m_synchronizedAnimList[node]--;
        if (m_synchronizedAnimList[node] <= 0) {
            m_synchronizedAnimList.erase(node);
        }
    }
    if (m_animCheckList.size() == 0) {
        //done
        nextPhase();
    }
}

void FMMatchGroup::actionDone(cocos2d::CCNode *node)
{
    if (m_animCheckList.find(node) != m_animCheckList.end()) {
        m_animCheckList[node]--;
        if (m_animCheckList[node] <= 0) {
            m_animCheckList.erase(node);
#ifdef DEBUG
            const char * info = m_animInfo[node];
            CCLog("%s is finished", info);
            m_animInfo.erase(node);
            std::stringstream ss;
            for (std::map<CCNode *, const char *>::iterator it = m_animInfo.begin(); it != m_animInfo.end(); it++) {
                const char * info = it->second;
                ss << info << " is still running" << "\n";
            }
            CCLog("current animations: %s", ss.str().c_str());
#endif
        }
    }
    
    if (m_animCheckList.size() == 0) {
        //done
        nextPhase();
    }
}
void FMMatchGroup::syncActionDone(CCNode * node)
{
    if (m_synchronizedAnimList.find(node) != m_synchronizedAnimList.end()) {
        m_synchronizedAnimList[node]--;
        if (m_synchronizedAnimList[node] <= 0) {
            m_synchronizedAnimList.erase(node);
#ifdef DEBUG
            const char * info = m_syncAnimInfo[node];
            CCLog("%s is finished", info);
            m_syncAnimInfo.erase(node);
            std::stringstream ss;
            for (std::map<CCNode *, const char *>::iterator it = m_syncAnimInfo.begin(); it != m_syncAnimInfo.end(); it++) {
                const char * info = it->second;
                ss << info << " is still running" << "\n";
            }
            CCLog("current animations: %s", ss.str().c_str());
#endif
        }
    }
}

void FMMatchGroup::updateMatchType()
{
    if (m_grids->size() == 1) {
        m_type = kMatch_Jump;
    }
    else if (m_grids->size() == 3) {
        m_type = kMatch_3;
    }
    else if (m_grids->size() == 4) {
        m_type = kMatch_4;
    }
    else {
        FMGameGrid * crossGrid = NULL;
        
        for (std::set<FMGameGrid *>::iterator it = m_grids->begin(); it != m_grids->end(); it++) {
            FMGameGrid * g = *it;
            FMGameElement * e = g->getElement();
            if (e) {
                if (e->m_elementFlag & kFlag_MatchX &&
                    e->m_elementFlag & kFlag_MatchY) {
                    //cross pattern
                    crossGrid = g;
                    break;
                }
            }
        }
        if (crossGrid) {
            m_type = kMatch_5Cross;
        }
        else {
            m_type = kMatch_5Line;
        }
    }
    
    if (m_grids->size() != 0) {
        FMGameGrid * grid = *m_grids->begin();
        m_matchcolor = grid->getElement()->getMatchColor();
        m_color = grid->getElement()->getElementColor();
    }
    else {
        m_matchcolor = -1;
        m_color = -1;
    }
    
   }

bool FMMatchGroup::isGridInGroup(FMGameGrid *grid)
{
    return m_grids->find(grid) != m_grids->end();
}

void FMMatchGroup::cleanGrids()
{
    m_grids->clear();
}

void FMMatchGroup::cleanCheckingAnims()
{
    for (std::map<CCNode *, int>::iterator it = m_animCheckList.begin(); it != m_animCheckList.end(); it ++) {
        CCNode * n = it->first;
        n->removeFromParent();
    }
    m_animCheckList.clear();
//    for (std::map<CCNode *, int>::iterator it = m_synchronizedAnimList.begin(); it != m_synchronizedAnimList.end(); it ++) {
//        CCNode * n = it->first;
//        n->removeFromParent();
//    }
    m_synchronizedAnimList.clear();
}

void FMMatchGroup::resetCheckingAnims()
{
    m_animCheckList.clear();
    m_synchronizedAnimList.clear();
}

bool FMMatchGroup::isAnimationDone(bool checkSync)
{
    if (checkSync) {
        return m_animCheckList.size() == 0 && m_synchronizedAnimList.size() == 0;
    }else{
        return m_animCheckList.size() == 0;
    }
}