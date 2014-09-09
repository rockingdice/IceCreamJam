//
//  FMMainScene.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-3.
//
//

#include "FMMainScene.h"
#include "FMGameNode.h"
#include "FMWorldMapNode.h"
#include "FMDataManager.h"
#include "FMStatusbar.h"
#include "FMUIWorldMap.h"
#include "FMTutorial.h"
#include "FMEnergyManager.h"
#include "NEAnimNode.h"
#include "GAMEUI_Scene.h"

using namespace neanim;

FMMainScene::FMMainScene()
:m_currentScene(kLoadingNode)
{
    //load textures for test
    NEAnimManager::sharedManager()->loadSpriteframesFromFile(CCString::create("Elements.plist"));
    NEAnimManager::sharedManager()->loadSpriteframesFromFile(CCString::create("Map.plist"));
    CCTexture2D * tex = CCTextureCache::sharedTextureCache()->textureForKey("Map.pvr.ccz");
    tex->setAliasTexParameters();
    
    CC_PROFILER_START("GameNode Init");
    
    m_energyManager = FMEnergyManager::manager();
    schedule(schedule_selector(FMMainScene::update), 1.f);
    
    m_ui = GAMEUI_Scene::uiSystem(); 
    addChild(m_ui, 1000);
    
    m_worldMap = FMWorldMapNode::create();
    m_worldMap->retain();
    
    m_game = FMGameNode::create();
    m_game->retain();
    
    FMStatusbar * statusbar = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
    m_statusbar = statusbar;
    addChild(statusbar, 2000);
    
    //tutorial
    FMTutorial * tut = FMTutorial::tut();
    m_tutorial = tut;
    m_tutorial->setVisible(false);
    addChild(tut, 3000);
    
    
    CC_PROFILER_STOP("GameNode Init");
    CC_PROFILER_DISPLAY_TIMERS();  
}

FMMainScene::~FMMainScene()
{
    
} 

FMMainScene *FMMainScene::create()
{
    FMMainScene *pRet = new FMMainScene();
    if (pRet && pRet->init())
    {
        pRet->autorelease();
        return pRet;
    }
    else
    {
        CC_SAFE_DELETE(pRet);
        return NULL;
    }
}

void FMMainScene::switchScene(kMainNodeType scene)
{
    m_currentScene = scene;
    if (scene == kWorldMapNode) {
        FMSound::playMusic("main_bg.mp3");
        if (!m_worldMap->getParent()) {
            m_game->removeFromParentAndCleanup(false);
            addChild(m_worldMap);
        }

        FMUIWorldMap * bar = (FMUIWorldMap *)FMDataManager::sharedManager()->getUI(kUI_WorldMap);
        bar->show(true);
        
        m_statusbar->removeFromParentAndCleanup(false);
        addChild(m_statusbar, 50);
        FMStatusbar * statusbar = (FMStatusbar *)m_statusbar;
        statusbar->show(true);
        statusbar->updateUI();
    }
    else if (scene == kGameNode){
        if (!m_game->getParent()) {
            FMWorldMapNode * world = (FMWorldMapNode *)m_worldMap;
            world->updateToLatestState();
            m_worldMap->removeFromParentAndCleanup(false);
            addChild(m_game);
        }
        
        FMDataManager * manager = FMDataManager::sharedManager();
        FMGameNode * game = (FMGameNode *)m_game;
#ifdef DEBUG
        game->loadLevel(manager->getWorldIndex(), manager->getLevelIndex(), manager->getLocalMode(), manager->isQuest());
#else
        game->loadLevel(manager->getWorldIndex(), manager->getLevelIndex(), false, manager->isQuest());
#endif
        game->uiSlide(true);
        
        FMUIWorldMap * bar = (FMUIWorldMap *)FMDataManager::sharedManager()->getUI(kUI_WorldMap);
        bar->show(false);

        m_statusbar->removeFromParentAndCleanup(false);
        addChild(m_statusbar, 2000);
        
        FMStatusbar * statusbar = (FMStatusbar *)m_statusbar;
        statusbar->show(false, false);
    }
}

CCNode * FMMainScene::getNode(kMainNodeType node)
{
    if (node == kWorldMapNode) {
        return m_worldMap;
    }
    else if (node == kGameNode){
        return m_game;
    }
    return NULL;
}

kMainNodeType FMMainScene::getCurrentSceneType()
{
    return m_currentScene;
}

void FMMainScene::onEnter()
{
    CCScene::onEnter();
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
    m_ui->setKeypadEnabled(true);
#endif
}

void FMMainScene::update(float delta)
{
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
    if(FMDataManager::sharedManager()->getFBSaveData() != NULL )
    {
        char *fbData = FMDataManager::sharedManager()->getFBSaveData();
        if(fbData){
            FMDataManager::sharedManager()->loadGameFromFB(fbData);
            FMDataManager::sharedManager()->setFBSaveData(NULL);
        }
    }
#endif
    
    m_energyManager->update(delta);
}
