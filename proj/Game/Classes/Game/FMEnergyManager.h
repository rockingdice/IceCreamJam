//
//  FMEnergyManager.h
//  JellyMania
//
//  Created by JamesLee on 13-12-5.
//
//

#ifndef __JellyMania__FMEnergyManager__
#define __JellyMania__FMEnergyManager__

#include <iostream>

class FMEnergyManager
{
private:
    FMEnergyManager();
    ~FMEnergyManager();
public:
    static FMEnergyManager * manager();

    int getCurrentLifeNum();
    int getRemainTime();
    void update(float delta); 
private:
    int m_remainTime;
};
#endif /* defined(__JellyMania__FMEnergyManager__) */