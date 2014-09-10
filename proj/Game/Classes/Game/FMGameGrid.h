//
//  FMGameGrid.h
//  FarmMania
//
//  Created by  James Lee on 13-5-3.
//
//

#ifndef __FarmMania__FMGameGrid__
#define __FarmMania__FMGameGrid__

#include <iostream>
#include "NEAnimNode.h"
#include "cocos2d.h"
#include "FMGameElement.h"


using namespace cocos2d;
typedef enum kGridType {
    kGridNone = -1,
    kGridNormal = 0,
    kGridGrass = 1
} kGridType;

typedef enum kGridStatus {
    kGridStatus_NoStatus = 0,
    kGridStatus_Spawner = 1,
    kGridStatus_Ice = 2,
//    kStatus_Ice = 2,
//    kStatus_Snail = 3,
//    kStatus_4Bonus = 4,
//    kStatus_5Bonus = 5,
//    kStatus_TBonus = 6,
//    kStatus_JumpSeat = 10,
    kStatus_Max
} kGridStatus;

//typedef enum kGridBonus {
//    kBonus_None,
////    kBonus_4Match = kStatus_4Bonus,
////    kBonus_5Line = kStatus_5Bonus,
////    kBonus_Cross = kStatus_TBonus,
//    kBonus_Other = 999
//} kGridBonus;

class FMGameElement;
class FMGameGrid : public CCObject {
public:
    FMGameGrid();
    ~FMGameGrid();
private:
    CCPoint m_coord;
    FMGameElement * m_elementPtr;

    kGridType m_gridType;
    kElementType m_elementType;
//status:
    std::set<int> m_status;
//spawner
    std::vector<FMGameElement *> m_spawnQueue;
public:
//slide
    bool m_acceptSlide;
public:
    //test
    NEAnimNode * m_gridNode;
    NEAnimNode * m_seatNode;
    void cleanSpawnQueue();
public:
    void setGridType(kGridType gridType);
    void setGridCoord(int row, int col);
    NEAnimNode * getAnimNode() { return m_gridNode; }
    CCPoint getCoord() {return m_coord;}
    kGridType getGridType(){ return m_gridType; }
    void addGridStatus(kGridStatus status);
    void removeGridStatus(kGridStatus status);
    bool hasGridStatus(kGridStatus status);
    int getGridStatusCount() { return m_status.size(); }
    void showGridStatus(bool show);
    void cleanGridStatus(); 
    FMGameElement * getElement() {return m_elementPtr;}
    void update(float delta);
    void spawnNextElement();
    void queueSpawnElement(FMGameElement * element); 
    bool isEmpty(){ return m_elementPtr == NULL;}
    bool isNone(){ return m_gridType == kGridNone;}
    bool isMovable();
    bool isSwappable();
    bool isExistMovableElement();
    bool isExistImmovableElement();
    void setOccupyElement(FMGameElement * element);
    CCPoint getPosition();
    
    //用于判断是否能添加关前购买的4，5，T消
    bool canAddSellingBonus(bool isSelf);
    
//element type
    void setElementType(kElementType type) {m_elementType = type;}
    kElementType getElementType() {return m_elementType;}
};

#endif /* defined(__FarmMania__FMGameGrid__) */
