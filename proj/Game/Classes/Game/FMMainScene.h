//
//  FMMainScene.h
//  FarmMania
//
//  Created by  James Lee on 13-5-3.
//
//

#ifndef __FarmMania__FMMainScene__
#define __FarmMania__FMMainScene__

#include <iostream>
#include "cocos2d.h"
using namespace cocos2d;

enum kMainNodeType {
    kWorldMapNode = 0,
    kGameNode = 1,
    kLoadingNode
    };

class GAMEUI_Scene;
class FMEnergyManager;
class FMMainScene : public CCScene {
public:
    FMMainScene();
    ~FMMainScene();
    
private:
    //world map node
    CCNode * m_worldMap;
    
    //game play node
    CCNode * m_game;
    
    //ui
    GAMEUI_Scene * m_ui;
    
    //status bar
    CCNode * m_statusbar;
    
    //tutorial
    CCNode * m_tutorial;
    
    //energy manager
    FMEnergyManager * m_energyManager;
    
    kMainNodeType m_currentScene;
public:
    static FMMainScene * create();
    void switchScene(kMainNodeType scene);
    CCNode * getNode(kMainNodeType node);
    kMainNodeType getCurrentSceneType();
    virtual void onEnter();
    void update(float delta);
};

#endif /* defined(__FarmMania__FMMainScene__) */
