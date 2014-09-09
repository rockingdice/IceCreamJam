//
//  FMEnergyManager.cpp
//  JellyMania
//
//  Created by JamesLee on 13-12-5.
//
//

#include "FMEnergyManager.h"
#include "FMDataManager.h"
static FMEnergyManager * m_sharedInstance = NULL;

FMEnergyManager::FMEnergyManager() :
    m_remainTime(-1)
{
    
}

FMEnergyManager::~FMEnergyManager()
{
    
}

FMEnergyManager * FMEnergyManager::manager()
{
    if (!m_sharedInstance) {
        m_sharedInstance = new FMEnergyManager;
    }
    return m_sharedInstance;
}


int FMEnergyManager::getCurrentLifeNum()
{
    return FMDataManager::sharedManager()->getLifeNum();
}

int FMEnergyManager::getRemainTime()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    int nextTime = manager->getNextLifeTime();
    if (nextTime == -1  || nextTime == 0) {
        return -1;
    }
    return manager->getRemainTime(nextTime);
}

void FMEnergyManager::update(float delta)
{
    //update energy
    FMDataManager * manager = FMDataManager::sharedManager();
    int nextTime = manager->getNextLifeTime();
    int maxEnergy = manager->getMaxLife();
    int curEnergy = manager->getLifeNum();
    if (nextTime == -1 || nextTime == 0) {
        //no counting, check life num
        if (curEnergy == maxEnergy) {
            //good
            return;
        }
        else {
//            CCAssert(0, "Check Energy Logic!");
        }
    }
    else {
        int currenttime = manager->getCurrentTime();
        int remainTime = manager->getRemainTime(nextTime);
        if (remainTime == 0) {
            //try add energy
            int off = currenttime - nextTime;
            int add = 0;
            int left = 0;
            while (off >= 0) {
                off -= kRecoverTime;
                add++;
            }
            left = abs(off);
            
            int life = manager->getLifeNum();
            int maxLife = manager->getMaxLife();
            
            if (life < maxLife) {
                if (add > 0) {
                    life += add;
                    if (life >= maxLife) {
                        life = maxLife;
                        manager->setNextLifeTime(-1);
                    }
                    else {
                        int nextTime = left + currenttime;
                        manager->setNextLifeTime(nextTime);
                    }
                    manager->setLifeNum(life);
                }
            }
            else {
                //life max, stop timer
                manager->setNextLifeTime(-1);
            }            
        }
    }
}