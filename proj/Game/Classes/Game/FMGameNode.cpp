//
//  FMGameNode.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-3.
//
//

#include "FMGameNode.h"
#include "FMDataManager.h"
#include "FMGameGrid.h"
#include "FMGameElement.h"
#include "FMGameWall.h"
#include "FMMatchGroup.h"
#include "FMLoopGroup.h"

#include "FMUIConfig.h"
#include "FMUIGreenPanel.h"
#include "FMUIRedPanel.h"
#include "FMUIResult.h"
#include "FMUIBooster.h"
#include "FMUIBoosterInfo.h"
#include "FMUIQuit.h"
#include "FMUIPause.h"
#include "FMMainScene.h"
#include "FMWorldMapNode.h"
#include "FMUILevelStart.h"

#ifdef DEBUG
#include "FMUIWarning.h"
#endif
#include "FMTutorial.h"

#include "CCJSONConverter.h"
#include "BubbleServiceFunction.h"
#include "SNSFunction.h"
#include "GAMEUI_Scene.h"
#include "BlurSprite.h"
#include <algorithm>

#ifdef DEBUG
#include "FMLevelSelectDialog.h"
#include "FMLevelConfig.h"
#endif

#define tipTimePeriod 6.f
#define idleTimePeriod 1.f
#define MaxComboCount 3
#define MaxRespawnTimes 10
#define kTagTcrossBG 10086
extern float kGridWidth;
extern float kGridHeight;
extern int kGridNum;

#pragma mark - Allocations 

static int shuffleTimes = 0;
FMGameNode::FMGameNode() :
#ifdef DEBUG
    m_cheatMode(false),
    m_isEditorMode(false),
    m_isStatusOn(false),
    m_debugCheatIcon(NULL),
    m_debugMenu(NULL),
    m_editor(NULL),
    m_sliderParent(NULL),
    m_childSliderParent(NULL),
    m_toolIcon(NULL),
    m_toolInfo(NULL),
    m_debugButtonsParent(NULL),
    m_childMode(0),
    m_selectBoxid(-1),
#endif
    m_centerNode(NULL),
    m_gameBG(NULL),
    m_closeButton(NULL),
    m_moveNode(NULL),
    m_swapGrid1(NULL),
    m_swapGrid2(NULL),
    m_swapBegin(false),
    m_gameUI(NULL),
    m_modeParent(NULL),
    m_scorebar(NULL),
//    m_scorebarParent(NULL),
//    m_percentageLabel(NULL),
    m_colorLayer(NULL),
    m_borderGridParent(NULL),
    m_boosterParent(NULL),
    m_boosterUseParent(NULL),
    m_currentSelection(NULL),
    m_scoreLabel(NULL),
    m_levelStatus(NULL),

    m_targetsCompleted(false),
    m_enableManiaMode(true),
    m_maniaModeBegin(false),
    m_bossHurtTurn(false), 
    m_isLevelFirstIn(true),
    m_phase(kPhase_NoInput),
    m_usingItem(-1),
    m_leftMoves(0),
    m_usedMoves(0),
    m_userQuit(false),
    m_maniaMode(false),
    m_movePlus(false),
    m_gameEnd(false),
    m_starNum(0),
    m_starNumCurrent(0),
    m_totalWeight(0),
    m_thinkingTime(0.f),
    m_idleTime(idleTimePeriod),
    m_score(0),
    m_showScore(0),
    m_harvestedInMove(0)
{
    
    setTouchMode(kCCTouchesOneByOne);
    setTouchEnabled(true);
    setTouchPriority(0);
    
    m_ccbNode = FMDataManager::sharedManager()->createNode("FMGameNode.ccbi", this);
    addChild(m_ccbNode);
    
    m_gameUI = FMDataManager::sharedManager()->createNode("UI/FMUIGame.ccbi", this);
    ((CCBAnimationManager*)m_gameUI->getUserObject())->setDelegate(this);
    addChild(m_gameUI, 2);
    
    m_greenPanel = FMDataManager::sharedManager()->getUI(kUI_GreenPanel);
    m_greenPanel->setVisible(false);
    addChild(m_greenPanel, 3);
    
    
#ifdef DEBUG

    m_debugMenu = FMDataManager::sharedManager()->createNode("Editor/FMDebugMenu.ccbi", this);
    m_debugMenu->retain();
    addChild(m_debugMenu, 4);
    
    m_editor = FMDataManager::sharedManager()->createNode("Editor/FMLevelEditor.ccbi", this);
    m_editor->retain();
    
    CCSize sliderSize = m_sliderParent->getContentSize(); 
    GUIScrollSlider * slider = new GUIScrollSlider(sliderSize, CCRect(-sliderSize.width * 0.5f, -sliderSize.height * 0.5f, sliderSize.width, sliderSize.height), 40.f, this, false, 1);
    slider->setPosition(ccp(sliderSize.width * 0.5f, sliderSize.height * 0.5f));
    slider->setRevertDirection(true);
    m_sliderParent->addChild(slider);
    
    {
        sliderSize = m_childSliderParent->getContentSize();
        GUIScrollSlider * slider = new GUIScrollSlider(sliderSize, CCRect(-sliderSize.width * 0.5f, -sliderSize.height * 0.5f, sliderSize.width, sliderSize.height), 40.f, this, false, 2);
        slider->setPosition(ccp(sliderSize.width * 0.5f, sliderSize.height * 0.5f));
        slider->setRevertDirection(true);
        m_childSliderParent->addChild(slider);
    }
    m_toolIcon->setTag(6);
#endif
    
    m_gridParent = CCNode::create();
    m_centerNode->addChild(m_gridParent, 0);
    
    m_movingElements.clear();
    
    m_levelData = NULL;
    m_animChecker = new FMMatchGroup;
    
    //init cached nodes
    //init 64 grid instances
    CCNode * offsetNode = CCNode::create();  
    offsetNode->setPosition(ccp(kGridWidth * 0.5f - (kGridWidth * kGridNum) * 0.5f, - kGridHeight * 0.5f + (kGridHeight * kGridNum) * 0.5f));
    m_gridParent->addChild(offsetNode, 0, 1);
//    offsetNode->setVisible(false);
    
    NEAnimManager::sharedManager()->preloadTextureForAnimFile("FMGrid.ani", "0000");
    CCSpriteFrame * gridFrame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("Map.plist|0000.png");
    m_borderGridParent = CCSpriteBatchNode::createWithTexture(gridFrame->getTexture());
    offsetNode->addChild(m_borderGridParent, -1);
    
    m_grids = new FMGameGrid**[kGridNum];
    for (int i=0; i<kGridNum; i++) {
        m_grids[i] = new FMGameGrid*[kGridNum];
        for (int j=0; j<kGridNum; j++) {
            m_grids[i][j] = new FMGameGrid();
            FMGameGrid * grid = m_grids[i][j];
            grid->setGridCoord(i, j);
            offsetNode->addChild(grid->getAnimNode());
        }
    }
    
    m_walls = new FMGameWall***[kGridNum];
    for (int i=0; i<2; i++) {
        bool vertical = i != 0;
        m_walls[i] = new FMGameWall**[kGridNum];
        for (int j=0; j<kGridNum-1; j++) {
            m_walls[i][j] = new FMGameWall*[kGridNum];
            for (int k=0; k<kGridNum; k++) {
                FMGameWall * wall = new FMGameWall(vertical);
                m_walls[i][j][k] = wall;
                wall->setCoord(j, k);
                wall->setWallType(kWallNone);
                offsetNode->addChild(wall->getAnimNode(), 200);
            }
        }
    }
    
    for (int i=0; i<4; i++) {
        CCString * skinName = CCString::createWithFormat("%d", i+1);
        m_indicator[i] = NEAnimNode::createNodeFromFile("FMIndicator.ani");
        m_indicator[i]->useSkin(skinName->getCString()); 
        m_indicator[i]->playAnimation("Init");
        m_indicator[i]->pauseAnimation();
        m_indicator[i]->setVisible(false);
        m_indicator[i]->setPosition(CCPointZero);
        offsetNode->addChild(m_indicator[i], 100);
    }
    
    //ui initialize
    
    {
        //mode parent
        for (int i=0; i<3; i++) {
            m_modeNode[i] = m_modeParent->getChildByTag(i);
        }
    }

    
    {
        //harvest mode
        CCNode * modeNode = m_modeNode[kGameMode_Harvest];
        
        for (int i=0; i<6; i++) {
            NEAnimNode * animTarget = (NEAnimNode *)(modeNode->getChildByTag(i));
            NEAnimNode * icon = (NEAnimNode *)(animTarget->getNodeByName("Element"));
            FMGameElement::changeAnimNode(icon, (kElementType)(i+1));
            icon->playAnimation("TargetIdle");
        }
        
        //score
        NEAnimNode * scorebar = (NEAnimNode *)modeNode->getChildByTag(15);
        CCNode * parent = scorebar->getParent();
        scorebar->removeFromParent();
        CCClippingNode * clip = CCClippingNode::create();
        clip->addChild(scorebar);
        parent->addChild(clip);
        clip->setPosition(scorebar->getPosition());
        scorebar->setPosition(CCPointZero);
        CCScale9Sprite * mask = CCScale9Sprite::createWithSpriteFrameName("ui_collectbar_cover.png");
        m_scorebar = mask;
        clip->setStencil(mask);
        CCSize size = mask->getOriginalSize();
        mask->setPosition(ccp(-size.width, 0));
        clip->setAlphaThreshold(0.2f);
    }
    
    {
        //target animation nodes
        for (int i=0; i<4; i++) {
            CCNode * parent = m_modeNode[kGameMode_Classic]->getChildByTag(i);
            m_targetAnimNode[i] = (NEAnimNode *)parent->getChildByTag(0);
            m_targetAnimNode[i]->releaseControl("Label");
            m_targetLabel[i] = (CCLabelBMFont *)(m_targetAnimNode[i]->getNodeByName("Label"));
//            m_targetBossElement[i] = (CCSprite *)m_bossMode->getChildByTag(3)->getChildByTag(i);
        }

        //BOSS
//        for (int i=0; i<4; i++) {
//            NEAnimNode * target = NEAnimNode::createNodeFromFile("FMElementUI.ani");
//            CCNode * parent = m_bossMode->getChildByTag(3);
//            
//            target->setScale(0.5f);
//            float x = i % 2 == 0 ? -1 : 1;
//            float y = i / 2 == 0 ? 1 : -1;
//            target->setPosition(ccp(x * 9.f, y * 9.f));
//            parent->addChild(target, 1, i);
//        }
    }
    
    //boosters
    for (int i=0; i<6; i++) {
        CCAnimButton * boosterButton = (CCAnimButton *)m_boosterParent->getChildByTag(i)->getChildByTag(1);
        boosterButton->getAnimNode()->releaseControl("Booster");
        boosterButton->getAnimNode()->releaseControl("Count");
        boosterButton->getAnimNode()->releaseControl("Clock");
    }
//    for (int i=0; i<5; i++) {
//        NEAnimNode * booster = NEAnimNode::createNodeFromFile("FMBooster.ani");
//        booster->setSmoothPlaying(true);
//        booster->xidChange(1, i+1);
//        booster->playAnimation("Init");
//        m_boosterParent->getChildByTag(i)->addChild(booster, 0, 1);
//        
//        NEAnimNode * boosterBoard = NEAnimNode::createNodeFromFile("FMBoosterBoard.ani");
//        boosterBoard->playAnimation("Red");
//        boosterBoard->setPosition(ccp(25.f, 21.f));
//        m_boosterParent->getChildByTag(i)->addChild(boosterBoard, 2, 2);
//        
//        CCLabelBMFont * boosterCount = CCLabelBMFont::create("", "font_booster_count.fnt");
//        boosterBoard->replaceNode("1", boosterCount);
//#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
//        boosterCount->setAlignment(kCCTextAlignmentCenter);
//#endif 
//        
////        CCSprite * shadow = CCSprite::createWithSpriteFrameName("Boosters.plist|booster_bg1.png");
////        shadow->setColor(ccc3(0, 0, 0));
////        shadow->setOpacity(128);
////        CCProgressTimer * timer = CCProgressTimer::create(shadow);
////        timer->setPercentage(0.f);
////        timer->setReverseDirection(true);
////        m_boosterParent->getChildByTag(i)->addChild(timer, 1, 3);
//    }
     

    //stars
    for (int i=0; i<3; i++) {
        m_star[i] = (NEAnimNode *)m_levelStatus->getChildByTag(i);
    }
    
    
//    //boss
//    for (int i=0; i<3; i++) {
//        NEAnimNode * ground = NEAnimNode::createNodeFromFile("FMBossGround.ani");
//        m_bossGround[i] = ground;
//        ground->setSmoothPlaying(true);
//        NEAnimNode * boss = NEAnimNode::createNodeFromFile("FMBoss.ani");
//        boss->setSmoothPlaying(true);
//        boss->playAnimation("Boss1Idle");
//        boss->pauseAnimation();
//        ground->replaceNode("1", boss);
//        ground->playAnimation("Pop");
//        CCNode * node = m_bossMode->getChildByTag(i);
//        node->addChild(ground);
//    }
    
    //vege mode
//    {
//        m_harvestCrowds = NEAnimNode::createNodeFromFile("FMHarvestCrowds.ani");
//        m_harvestCrowds->playAnimation("Init");
//        CCNode * node1 = m_vegeMode->getChildByTag(1);
//        node1->addChild(m_harvestCrowds);
//        
//        CCNode * node3 = m_vegeMode->getChildByTag(3);
//        NEAnimNode * checkedAnim =  NEAnimNode::createNodeFromFile("FMCheckBox.ani");
//        checkedAnim->playAnimation("Empty");
//        node3->addChild(checkedAnim, 111, 1);
//    }
    
    //tutorial buttons ref
    m_buttons[0] = m_closeButton;
    for (int i=0; i<6; i++) {
        m_buttons[1 + i] = (CCControlButton *)m_boosterParent->getChildByTag(i)->getChildByTag(1);
    }
    
    
    
//    m_data = loadFromJsonFile();
//    m_data->retain();
//    loadFromJsonFile();
//    loadLevel(0, 0, false);
    
    
}

FMGameNode::~FMGameNode()
{
    m_data->release();
#ifdef DEBUG
    m_debugMenu->release();
    m_editor->release();
    m_debugMenu = NULL;
    m_editor = NULL;
#endif
}


FMGameNode *FMGameNode::create()
{
    FMGameNode *pRet = new FMGameNode();
    if (pRet)
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

#pragma mark - Game Functions
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
extern bool forground;
void FMGameNode::setGameBG(){
    FMMainScene *pScene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
    FMWorldMapNode * worldmap = (FMWorldMapNode *)pScene->getNode(kWorldMapNode);
    CCSpriteFrame * frame = worldmap->getCurrentWorldBGFrame();
    SpriteBlur * m_pBlurSprite = SpriteBlur::createWithSpriteFrame(frame);
    CCSize size = CCDirector::sharedDirector()->getWinSize();
    m_pBlurSprite->setPosition(ccp(size.width * 0.5f, size.height * 0.5f));
    m_pBlurSprite->setBlurSize(2.f);
    m_pBlurSprite->setScaleY(-1);
    CCRenderTexture * r = CCRenderTexture::create(size.width, size.height);
    r->addChild(m_pBlurSprite);
    r->beginWithClear(0, 0, 0, 0);
    m_pBlurSprite->visit();
    r->end();
    m_gameBG->setDisplayFrame(r->getSprite()->displayFrame());
    m_gameBG->setScale(2.f);
}
#endif
void FMGameNode::loadLevel(int world, int index, bool localMode, bool isQuest, int seed)
{
    if (m_levelData) {
        m_levelData->release();
        m_levelData = NULL;
    }
    FMDataManager * manager = FMDataManager::sharedManager();
    manager->setLevel(world, index, isQuest,manager->isBranch());
    m_levelData = manager->getLevelData(localMode);
    if (seed == 0) {
        seed = manager->getRandom();
    }
    resetMapLimit();
    resetButtonLimit();
    manager->setRandomSeed(seed);
    manager->settutorialBooster(-1);
    manager->checkNewTutorial(); //may update the seed for tutorials
    
    if (!m_levelData) {
        return;
    }
    m_levelData->retain();
    makeInit();
    if (m_leftMoves > 999) {
        m_enableManiaMode = false;
        NEAnimNode * node = (NEAnimNode *)m_moveNode->getChildByTag(0);
        node->playAnimation("unlimit");
    }
    else {
        m_enableManiaMode = true;
    }
    
    //background
    FMMainScene *pScene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
    
    FMWorldMapNode * worldmap = (FMWorldMapNode *)pScene->getNode(kWorldMapNode);
    
    CCSpriteFrame * frame = worldmap->getCurrentWorldBGFrame();
    if (frame == NULL || frame->getTexture() == NULL) {
        frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("WorldBG1.plist|WorldBG1.png");
    }
    SpriteBlur * m_pBlurSprite = SpriteBlur::createWithSpriteFrame(frame);
    CCSize size = CCDirector::sharedDirector()->getWinSize();
    m_pBlurSprite->setPosition(ccp(size.width * 0.5f, size.height * 0.5f));
    m_pBlurSprite->setBlurSize(2.f);
    m_pBlurSprite->setScaleY(-1);
    CCRenderTexture * r = CCRenderTexture::create(size.width, size.height);
    r->addChild(m_pBlurSprite);
    r->beginWithClear(0, 0, 0, 0);
    m_pBlurSprite->visit();
    r->end();
    m_gameBG->setDisplayFrame(r->getSprite()->displayFrame());
    m_gameBG->setScale(2.f);
    
    
//    const char * worldTextureFilename = CCString::createWithFormat("WorldBG%02d.plist", world + 1)->getCString();
//    const char * path = SNSFunction_getDownloadSubFolderFilePath("1x", worldTextureFilename);
//    if (!manager->isFileExist(path)) {
//        //check local file
//        std::string filepath = CCFileUtils::sharedFileUtils()->fullPathForFilename(worldTextureFilename);
//        if (!manager->isFileExist(filepath.c_str())) {
//            //use default
//            
//            m_gameBG->setDisplayFrame(<#cocos2d::CCSpriteFrame *pNewFrame#>)
//        }
//        else {
//            
//        }
//    }
//    else {
//        
//    }
}

void FMGameNode::makeInit()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    manager->setNeedFailCount(false);
    CCAssert(m_levelData != 0, "level data is null, need init!");
    //clear all matches
    for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it!= m_matchedGroups.end(); it++) {
        FMMatchGroup * mg = it->second;
        mg->cleanCheckingAnims();
        std::set<FMGameGrid *>* eles = mg->m_grids;
        for (std::set<FMGameGrid*>::iterator it = eles->begin(); it!= eles->end(); it++) {
            FMGameGrid * g = *it;
            FMGameElement * e = g->getElement();
            if (e) {
                removeElement(e);
            }
            
            g->setOccupyElement(NULL);
        }
        delete mg; 
    }
    m_animChecker->cleanCheckingAnims();
    m_matchedGroups.clear();

    //reset elements
    for (int i=0; i<kGridNum; i++) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
            if (grid->hasGridStatus(kGridStatus_Spawner)) {
                grid->cleanSpawnQueue();
            }
            FMGameElement * e = grid->getElement();
            if (e) {
                removeElement(e);
            }
            grid->setOccupyElement(NULL);

        }
    }
    for (int i=0; i<2; i++) {
        for (int j=0; j<kGridNum-1; j++) {
            for (int k=0; k<kGridNum; k++) {
                FMGameWall * wall = m_walls[i][j][k];
                wall->setWallType(kWallNone);
            }
        }
    }
    m_movingElements.clear();
    m_spawner.clear();
    m_usedBonus.clear();
    
    //load spawn data
    m_spawnData.clear();
    m_totalWeight = 0;
    CCArray * spawn = (CCArray *)m_levelData->objectForKey("spawnables");
    for (int i=0; i<spawn->count(); i++) {
        CCArray * spawnPair = (CCArray *)spawn->objectAtIndex(i);
        kElementType spawnType = (kElementType)((CCNumber *)spawnPair->objectAtIndex(0))->getIntValue();
        int spawnWeight = ((CCNumber *)spawnPair->objectAtIndex(1))->getIntValue();
        ElementAmountPair data(spawnType, spawnWeight);
        m_spawnData.push_back(data);
        m_totalWeight += spawnWeight;
    }
    
    //load target data
    m_targets.clear();
    CCArray * targets = (CCArray *)m_levelData->objectForKey("targets");
    for (int i=0; i<targets->count(); i++) {
        CCArray * targetData = (CCArray *)targets->objectAtIndex(i);
        int targetType = ((CCNumber *)targetData->objectAtIndex(0))->getIntValue();
        int targetAmount = ((CCNumber *)targetData->objectAtIndex(1))->getIntValue();
        elementTarget et;
        et.target = targetAmount;
        et.harvested = 0;
        et.index = i;
        m_targets[targetType] = et;
    }
    
    //load limits data
    m_currentLimits.clear();
    CCArray * climits = (CCArray *)m_levelData->objectForKey("currentlimit");
    if (climits) {
        for (int i=0; i<climits->count(); i++) {
            CCArray * targetData = (CCArray *)climits->objectAtIndex(i);
            int targetType = ((CCNumber *)targetData->objectAtIndex(0))->getIntValue();
            int targetAmount = ((CCNumber *)targetData->objectAtIndex(1))->getIntValue();
            m_currentLimits[targetType] = targetAmount;
        }
    }
    
    m_levelLimits.clear();
    CCArray * lLimits = (CCArray *)m_levelData->objectForKey("levellimit");
    if (lLimits) {
        for (int i=0; i<lLimits->count(); i++) {
            CCArray * targetData = (CCArray *)lLimits->objectAtIndex(i);
            int targetType = ((CCNumber *)targetData->objectAtIndex(0))->getIntValue();
            int targetAmount = ((CCNumber *)targetData->objectAtIndex(1))->getIntValue();
            elementTarget et;
            et.index = 0;
            et.target = targetAmount;
            et.harvested = 0;
            et.count = 0;
            m_levelLimits[targetType] = et;
        }
    }
    
    
    m_gameMode = (kGameMode)((CCNumber *)m_levelData->objectForKey("gameMode"))->getIntValue();
    m_suggestedBooster = (kGameBooster)((CCNumber *)m_levelData->objectForKey("suggestedItem"))->getIntValue();
    m_leftMoves = ((CCNumber *)m_levelData->objectForKey("moves"))->getIntValue();;
    //temp fix
    if (m_gameMode >= kGameMode_Max) {
        m_gameMode = kGameMode_Classic;
    }
    
    //3 stars score
    CCArray * scores = (CCArray *)m_levelData->objectForKey("percentage");
    for (int i=0; i<3; i++) {
        m_scoreCaps[i] = ((CCNumber *)scores->objectAtIndex(i))->getIntValue();
    }
    
    //game mode data
    CCArray * gameModeData = (CCArray *)m_levelData->objectForKey("gameModeData");
    for (int i=0; i<3; i++) {
        m_gameModeData[i] = ((CCNumber *)gameModeData->objectAtIndex(i))->getIntValue();
    }
    
    //bg music data
    CCNumber * bgMusicData = (CCNumber *)m_levelData->objectForKey("bgmusic");
    if (!bgMusicData) {
        bgMusicData = CCNumber::create(1);
        m_levelData->setObject(bgMusicData, "bgmusic");
    }
    CCString * bgMusicFile = CCString::createWithFormat("game_bg_%02d.mp3", bgMusicData->getIntValue());
    FMSound::playMusic(bgMusicFile->getCString(), true);
    
    //snails data
//    CCArray * snails = (CCArray *)m_levelData->objectForKey("snails");
//    if (!snails) {
//        snails = CCArray::create();
//        snails->addObject(CCNumber::create(0));
//        snails->addObject(CCNumber::create(0));
//        m_levelData->setObject(snails, "snails");
//    }
//    m_snailSameTime = ((CCNumber *)snails->objectAtIndex(0))->getIntValue();
//    m_snailMax = ((CCNumber *)snails->objectAtIndex(1))->getIntValue();
    
    //wall data
    CCArray * wall = (CCArray *)m_levelData->objectForKey("wall");
    if (wall) {
        for (int i=0; i<2; i++) {
            CCArray * data1 = (CCArray *)wall->objectAtIndex(i);
            for (int j=0; j<kGridNum-1; j++) {
                CCArray * data2 = (CCArray *)data1->objectAtIndex(j);
                for (int k=0; k<kGridNum; k++) {
                    CCArray * data3 = (CCArray *)data2->objectAtIndex(k);
                    kWallType type = (kWallType)((CCNumber *)data3->objectAtIndex(0))->getIntValue();
                    m_walls[i][j][k]->setWallType(type);
                }
            }
        }
    }
    
    CCArray * map = (CCArray *)m_levelData->objectForKey("map");
    for (int i=0; i<kGridNum; i++) {
        CCArray * rowData = (CCArray *)map->objectAtIndex(i);
        for (int j=kGridNum-1; j>=0; j--) {
            FMGameGrid * grid = m_grids[i][j];
            CCArray * gridData = (CCArray *)rowData->objectAtIndex(j);
            int dataCount = gridData->count();
            kGridType gridType = kGridNormal;
            kGridStatus status = kGridStatus_NoStatus;
            kElementType elementType = kElement_Random;
            int param1 = -1;
            grid->cleanGridStatus();
            std::vector<int> initStatus; 
            int index = 0;
            while (index < dataCount) {
                index++;
                switch (index) {
                    case 1:
                    {
                        gridType = (kGridType)((CCNumber *)gridData->objectAtIndex(0))->getIntValue();
                    }
                        break;
                    case 2:
                    {
                        elementType = (kElementType)((CCNumber *)gridData->objectAtIndex(1))->getIntValue();
                    }
                        break;
                    default:
                    {
                        for (int i=2; i<dataCount; i++) {
                            status = (kGridStatus)((CCNumber *)gridData->objectAtIndex(i))->getIntValue();
                            if (status != kGridStatus_NoStatus) {
                                initStatus.push_back(status);
                            }
                        }

                    }
                        break; 
                }
            }
             
            grid->setGridType(gridType); 
//            if (grid->hasGridStatus(kStatus_JumpSeat)) {
//                m_jumpGrids.push_back(grid);
//            }
#ifdef DEBUG
            if (m_isEditorMode) {
                FMGameElement * e = createNewElement(elementType);
                e->setElementType(elementType);
                grid->setOccupyElement(e);
                e->getAnimNode()->setPosition(grid->getPosition());
                if (grid->isNone()) {
                    e->getAnimNode()->setVisible(false);
                }
            }
            else
#endif
            {
                if (!grid->isNone() && elementType != kElement_None) {
                    FMGameElement * e = createNewElement(kElement_None);
                    if (elementType == kElement_Random) {
                        e->m_elementFlag |= kFlag_InitRandom;
                    }
                    grid->setOccupyElement(e);
                    e->getAnimNode()->setPosition(grid->getPosition());
                }
            }
            
            
            for (std::vector<int>::iterator it = initStatus.begin(); it != initStatus.end(); it++) {
                kGridStatus status = (kGridStatus)*it;
                switch (status) {
                    case kGridStatus_Spawner:
                    {
                        if (!grid->isNone()) {
                            grid->addGridStatus(kGridStatus_Spawner);
                            m_spawner.push_back(grid);
                        }
                    }
                        break;
//                    case kStatus_Ice:
//                    {
//                        FMGameElement * e = grid->getElement();
//                        grid->addGridStatus(kStatus_Ice);
//                        if (e) {
//                            e->addStatus(kStatus_Ice);
//                            (grid->hasGridStatus(kStatus_Ice));
//                        }
//
//                    }
//                        break;

                    default:
                        break;
                }
            }
        }
    }

    
    shuffleTimes = 0;
#ifdef DEBUG
    if (!m_isEditorMode)
#endif
    {
        int seed = FMDataManager::getCurrentRandomSeed();
        FMDataManager::setRandomSeed(seed, true);
        mapDataRemake();
    }

    

#ifdef DEBUG
    setCheated(false);
    m_selectBoxid = -1;
#endif
    //box
    
//    std::map<int, int> items = manager->getBoxRemainItems();
//    m_remainItems.clear();
//    m_remainItems.insert(items.begin(), items.end());
//    CCLog("items %d" , m_remainItems.size());
    
    //ui init
    m_targetsCompleted = false;
    m_usingItem = -1;
    for (int i=0; i<5; i++) {
        m_boosterUsed[i] = 0;
    }
    m_continueTimes = 0;
    m_score = 0;
    m_showScore = 0;
    m_scoreBeforeMania = 0;
    m_userQuit = false;
    m_gameEnd = false;
    m_maniaMode = false;
    m_maniaModeBegin = false;
    m_movePlus = false;
    m_aiChecked = false;
    m_bossHurtTurn = false;
    m_swapGrid1 = NULL;
    m_swapGrid2 = NULL;
    m_currentSelection = NULL;
    m_usedMoves = 0;
    m_thinkingTime = 0.f;
    m_idleTime = idleTimePeriod;
    m_combo = 0;
    m_soundEffectCombo = 0;
    m_harvestedInMove = 0;
    m_hasPlus5BeforeLevel = false;
    m_bossIndex = FMDataManager::getRandom() % 3;
    updateBackGrids();
//    m_mysticBox->setVisible(false);
    //check plus move booster 

    if (manager->isBoosterUsable(kBooster_MovePlusFive) && isSellingBooster(kBooster_MovePlusFive)) {
        int num = manager->getBoosterAmount(kBooster_MovePlusFive);
        num--;
        manager->setBoosterAmount(kBooster_MovePlusFive, num);
        m_leftMoves += 5;
        m_hasPlus5BeforeLevel = true;
        m_usedBonus.push_back(kBooster_MovePlusFive);
    }
    for (int i = 0; i < 3; i++) {
        kGameBooster btype = (kGameBooster)(kBooster_TCross+i);
        if (manager->isBoosterUsable(btype) && isSellingBooster(btype)) {
            addSellingBonus(btype);
            m_usedBonus.push_back(btype);
            int num = manager->getBoosterAmount(btype);
            num--;
            manager->setBoosterAmount(btype, num);
        }
    }

    for (int i=0; i<kGameMode_Max; i++) {
        m_modeNode[i]->setVisible(i == m_gameMode);
    }
    CCNode * modeNode = m_modeNode[m_gameMode];
    if (m_gameMode == kGameMode_Boss) {
//        m_harvestMode->setVisible(false);
//        m_vegeMode->setVisible(false);
//        m_bossMode->setVisible(true);
//        
//        
//        for (int i=0; i<3; i++) {
//            NEAnimNode * boss = (NEAnimNode *)m_bossGround[i]->getNodeByName("1");
//            boss->playAnimation("Hide");
//            m_bossGround[i]->playAnimation("Hide");
//        }
//        
//        std::map<int, elementTarget>::iterator it = m_targets.begin();
//        std::stringstream ss;
//        CCNode * parent = m_bossMode->getChildByTag(3);
//        for (; it != m_targets.end(); it++) {
//            ss.str("");
//            kElementType type = (kElementType)it->first;
//            elementTarget target = it->second;
//            int index = target.index;
//
//            if (index < 4) {
//                NEAnimNode * target = (NEAnimNode *)parent->getChildByTag(index);
//                target->xidChange(1, type);
//                target->playAnimation("Init");
//                target->setVisible(true);
//            }
//        }
//        for (int i = m_targets.size(); i < 4; i++) {
//            NEAnimNode * target = (NEAnimNode *)parent->getChildByTag(i);
//            target->setVisible(false);
//        }
    }
    else if (m_gameMode == kGameMode_Harvest) {
        NEAnimNode * checkedAnim = (NEAnimNode *)modeNode->getChildByTag(20);
        checkedAnim->playAnimation("Init");

        CCNode * jellyParent = m_modeNode[kGameMode_Harvest]->getChildByTag(25);
        NEAnimNode * jelly = (NEAnimNode *)jellyParent->getChildByTag(0);
        jellyParent->setScale(0.75f);
        jelly->playAnimation("GrowingjellyIdle2", 0 , false, true);
    }
    else {
        std::map<int, elementTarget>::iterator it = m_targets.begin();
        std::stringstream ss;
        for (; it != m_targets.end(); it++) {
            ss.str("");
            kElementType type = (kElementType)it->first;
            elementTarget target = it->second;
            int index = target.index;
            if (index < 4) {
                NEAnimNode * icon = (NEAnimNode *)m_targetAnimNode[index]->getNodeByName("Element");
                FMGameElement::changeAnimNode(icon, type);
                icon->playAnimation("TargetHarvest", 0 ,true);
                m_targetAnimNode[index]->getParent()->setVisible(true);
                CCNode * parent = modeNode->getChildByTag(index);
                NEAnimNode * checkedAnim = (NEAnimNode *)parent->getChildByTag(3);
                checkedAnim->playAnimation("Init");
            }
        }
        for (int i = m_targets.size(); i < 4; i++) {
            m_targetAnimNode[i]->getParent()->setVisible(false);
        }
        
        updateHarvestTargets();
    }
    
    NEAnimNode * fiveMoveNode = (NEAnimNode *)m_moveNode->getChildByTag(0);
    fiveMoveNode->playAnimation("Init");
    fiveMoveNode->releaseControl("label", kProperty_StringValue);

    m_colorLayer->setColor(ccc3(255, 255, 255));
    m_colorLayer->setOpacity(0);
    
    updateMoves();
    
    resetScorebar();
    updateHarvestTargets();
    updateBoosters();
    showIndicator(false);
    gameStart();
}

void FMGameNode::playIdleAnim()
{
    std::vector<FMGameElement*> eles;
    for (int i=0; i<kGridNum; i++) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * g = getNeighbor(i, j, kDirection_C);
            FMGameElement * e = g->getElement();
            if (e &&!e->hasStatus(kStatus_Frozen)) {
                eles.push_back(e);
            }
        }
    }
    if (eles.size() == 0)return;
    
    FMDataManager * manager = FMDataManager::sharedManager();
    int count = manager->getRandom()%2;
    
}
void FMGameNode::addSellingBonus(int type)
{
//    std::set<FMGameGrid *> freeGrids;
//    for (int i=0; i<kGridNum; i++) {
//        for (int j=0; j<kGridNum; j++) {
//            FMGameGrid * g = getNeighbor(i, j, kDirection_C);
//            if (g && !g->canAddSellingBonus(true)) {
//                continue;
//            }
//            
//            //监测x轴方向是否可以放置
//            FMGameGrid * xg = g;
//            int xnumber1 = 0;
//            while (xg && xg->canAddSellingBonus(false) && xnumber1 < 3) {
//                xnumber1++;
//                xg = getNeighbor(xg, kDirection_L);
//            }
//            xg = g;
//            int xnumber2 = 0;
//            while (xg && xg->canAddSellingBonus(false) && xnumber2 < 3) {
//                xnumber2++;
//                xg = getNeighbor(xg, kDirection_R);
//            }
//            if (xnumber1 + xnumber2 > 3) {
//                freeGrids.insert(g);
//                continue;
//            }
//            
//            //监测y轴方向是否可以放置
//            FMGameGrid * yg = g;
//            int ynumber1 = 0;
//            while (yg && yg->canAddSellingBonus(false) && ynumber1 < 3) {
//                ynumber1++;
//                yg = getNeighbor(yg, kDirection_U);
//            }
//            yg = g;
//            int ynumber2 = 0;
//            while (yg && yg->canAddSellingBonus(false) && ynumber2 < 3) {
//                ynumber2++;
//                yg = getNeighbor(yg, kDirection_B);
//            }
//            if (ynumber1 + ynumber2 > 3) {
//                freeGrids.insert(g);
//                continue;
//            }
//        }
//    }
//    if (freeGrids.size() == 0) {
//        return;
//    }
//    int count = 4;
//    switch (type) {
//        case kBooster_4Match:
//            count = 4;
//            break;
//        case kBooster_5Line:
//            count = 2;
//            break;
//        case kBooster_TCross:
//            count = 3;
//            break;
//        default:
//            break;
//    }
//    FMDataManager * manager = FMDataManager::sharedManager();
//    for (int i = 0; i < count; i++) {
//        int r = manager->getRandom()%freeGrids.size();
//        std::set<FMGameGrid *>::iterator it = freeGrids.begin();
//        std::advance(it, r);
//        FMGameGrid * g = *it;
//        switch (type) {
//            case kBooster_4Match:
//                g->setGridBonus(kBonus_4Match);
//                break;
//            case kBooster_5Line:
//                g->setGridBonus(kBonus_5Line);
//                break;
//            case kBooster_TCross:
//                g->setGridBonus(kBonus_Cross);
//                break;
//            default:
//                break;
//        }
//        freeGrids.erase(it);
//        if (freeGrids.size() == 0) {
//            return;
//        }
//    }
}

void FMGameNode::mapDataRemake()
{
    //load level data
    m_spawner.clear();
//    m_jumpGrids.clear();
//    m_snailGrids.clear();
// 
    
    for (std::map<int, elementTarget>::iterator it = m_levelLimits.begin(); it != m_levelLimits.end(); it++) {
        elementTarget & et = it->second;
        et.count = 0;
    }

    std::vector<FMGameGrid*> emptyGrids;
    CCArray * map = (CCArray *)m_levelData->objectForKey("map");
    for (int i=0; i<kGridNum; i++) {
        CCArray * rowData = (CCArray *)map->objectAtIndex(i);
        for (int j=kGridNum-1; j>=0; j--) {
            FMGameGrid * grid = m_grids[i][j];
            CCArray * gridData = (CCArray *)rowData->objectAtIndex(j);
            int dataCount = gridData->count();
            kGridType gridType = kGridNormal;
            kGridStatus status = kGridStatus_NoStatus;
            kElementType elementType = kElement_Random;
            grid->cleanGridStatus();
            switch (dataCount) {
                case 0:
                {
                    //default grid and element, no status
                }
                    break;
                case 1:
                {
                    gridType = (kGridType)((CCNumber *)gridData->objectAtIndex(0))->getIntValue();
                }
                    break;
                case 2:
                {
                    gridType = (kGridType)((CCNumber *)gridData->objectAtIndex(0))->getIntValue();
                    elementType = (kElementType)((CCNumber *)gridData->objectAtIndex(1))->getIntValue();
                }
                    break;
                default:
                {
                    gridType = (kGridType)((CCNumber *)gridData->objectAtIndex(0))->getIntValue();
                    elementType = (kElementType)((CCNumber *)gridData->objectAtIndex(1))->getIntValue();
                    for (int i=2; i<dataCount; i++) {
                        status = (kGridStatus)((CCNumber *)gridData->objectAtIndex(i))->getIntValue();
                        if (status != kGridStatus_NoStatus) {
                            grid->addGridStatus(status);
                        }
                    }
                }
                    break;
            }
            grid->setGridType(gridType);
            if (grid->hasGridStatus(kGridStatus_Spawner) && !grid->isNone()) {
                m_spawner.push_back(grid);
            }
//            if (grid->hasGridStatus(kStatus_JumpSeat)) {
//                m_jumpGrids.push_back(grid);
//            }
#ifdef DEBUG
            if (m_isEditorMode) {
                FMGameElement * e = grid->getElement();
                e->cleanStatus();
                e->setElementType(elementType);
                e->getAnimNode()->setVisible(elementType != kElement_None);
                e->getAnimNode()->setPosition(grid->getPosition());
                if (grid->isNone()) {
                    e->getAnimNode()->setVisible(false);
                }
            }
            else
#endif
            {
                if (!grid->isNone() && grid->getElement()) {
                    if (elementType != kElement_Random) {
                        FMGameElement * e = grid->getElement();
                        e->cleanStatus();
                        kElementType type = elementType;
                        e->setElementType(type);
                        if (elementType == kElement_Random) {
                            e->m_elementFlag |= kFlag_InitRandom;
                        }
                        e->getAnimNode()->setPosition(grid->getPosition());
                        if (grid->hasGridStatus(kGridStatus_Ice)) {
                            e->addStatus(kStatus_Frozen);
                        }
                        
                        kElementType ttype = elementType;
                        if (m_levelLimits.find(ttype) != m_levelLimits.end()) {
                            elementTarget &et = m_levelLimits[ttype];
                            et.count++;
                        }
                        
                    }else{
                        emptyGrids.push_back(grid);
                    }
                }
            }
            
        }
    }
    for (int i = 0; i < emptyGrids.size(); i++) {
        FMGameGrid * g = emptyGrids.at(i);
        FMGameElement * e = g->getElement();
        e->cleanStatus();
        int type = getNewElementType();
        e->setElementType((kElementType)type);
        e->m_elementFlag |= kFlag_InitRandom;
        e->getAnimNode()->setPosition(g->getPosition());
        if(g->hasGridStatus(kGridStatus_Ice)) {
            e->addStatus(kStatus_Frozen);
        }
    }
    
    //check if snails is not enough
//    if (m_snailGrids.size() < m_snailSameTime) {
//        int num = m_snailSameTime - m_snailGrids.size();
//        
//        std::vector<FMGameGrid *> freeGrids;
//        for (int i=0; i<kGridNum; i++) {
//            for (int j=0; j<kGridNum; j++) {
//                FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
//                if (grid && grid->getElement()) {
//                    if (grid->hasGridStatus(kStatus_Spawner)) {
//                        continue;
//                    }
//                    FMGameElement * element = grid->getElement();
//                    if (element->canBeDisabled() && !element->isDisabled()) {
//                        freeGrids.push_back(grid);
//                    }
//                }
//            }
//        }
//        
//        int free = freeGrids.size();
//        free -= 10;
//        int max = m_snailMax;
//        while (free > 0 && num > 0 && max > 0) {
//            int r = FMDataManager::getRandom(-1) % free;
//            std::vector<FMGameGrid *>::iterator it = freeGrids.begin() + r;
//            FMGameGrid * g = *it;
//            g->getElement()->setDisabled(true);
//            m_snailGrids.insert(g);
//            freeGrids.erase(it);
//            free--;
//            num--;
//            max--;
//        }
//    }
    
#ifdef DEBUG
    if (!m_isEditorMode)
#endif
    {
        if (checkMapPlayable()) {
            //succeed
//            m_snailMax -= m_snailGrids.size();
            CCLog("succeed seed: %d", FMDataManager::getRandomIteratorSeed());
        }
        else {
            removeBadSeed(FMDataManager::getRandomIteratorSeed());
            //check
            if (shuffleTimes > 100) {
                //use default seed
                CCArray * seeds = (CCArray *)m_levelData->objectForKey("seeds");
                if (!seeds || seeds->count() == 0) {
                    //don't have default seed
                    //sorry for the bad luck..
                    CCLOG("cannot generate a map! last seed:%d", FMDataManager::getRandomIteratorSeed());
                }
                else {
                    int r = FMDataManager::getRandom() % seeds->count();
                    CCNumber * n = (CCNumber *)seeds->objectAtIndex(r);
                    FMDataManager::setRandomSeed(n->getIntValue(), true);
                    mapDataRemake();
                    return;
                }
            }
            else {
                //make map again,using different seed
                //take random seed
                int levelSeed = FMDataManager::getRandom();
                FMDataManager::setRandomSeed(levelSeed, true);
                mapDataRemake();
                return;
            }
        }
#ifdef DEBUG
        if (shuffleTimes > 100) {
            //no proper seed
            CCLOG("no proper seed!, last seed: %d", FMDataManager::getRandomIteratorSeed());
            CCControlButton * button = (CCControlButton *)m_debugButtonsParent->getChildByTag(4);
            button->setVisible(false);
        }
        else {
            CCLOG("level seed: %d", FMDataManager::getRandomIteratorSeed());
            CCControlButton * button = (CCControlButton *)m_debugButtonsParent->getChildByTag(4);
            button->setVisible(true);
        }
        CCLOG("shuffled times: %d", shuffleTimes);
#endif
        for (int i=0; i<kGridNum; i++) {
            for (int j=0; j<kGridNum; j++) {
                FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
                if (grid->getElement()) {
                    grid->getElement()->m_elementFlag |= kFlag_InitRandom;
                }
            }
        }
    }
}

int FMGameNode::getNewElementType()
{
    int r = FMDataManager::getRandom(-1) % m_totalWeight;
    kElementType newtype = kElement_None;
    for (int i=0; i<m_spawnData.size(); i++) {
        //check amount limit
        const ElementAmountPair &s = m_spawnData[i];
        int weight = s.weight;

        if (r <= weight) {
            newtype = (kElementType)s.type;
            break;
        }
        r -= s.weight;
    }
    
    //check limit
    bool exceedLimit = false;
    if (newtype == kElement_None) {
        exceedLimit = true;
    }
    kElementType ttype = newtype;
    
//    if (!exceedLimit && m_currentLimits.find(ttype) != m_currentLimits.end()) {
//        int amount = 0;
//        for (int i=0; i<kGridNum; i++) {
//            for (int j=0; j<kGridNum; j++) {
//                FMGameGrid * g = getNeighbor(i, j, kDirection_C);
//                FMGameElement * e = g->getElement();
//                if (newisGhost) {
//                    if (e && e->isGhostType()) {
//                        amount++;
//                    }
//                }else{
//                    if (e && e->getElementType() == ttype) {
//                        amount++;
//                    }
//                }
//            }
//        }
//        if (amount >= m_currentLimits[ttype]) {
//            //exceed limit
//            exceedLimit = true;
//        }
//    }
//    
//    if (!exceedLimit && m_levelLimits.find(ttype) != m_levelLimits.end()) {
//        elementTarget &et = m_levelLimits[ttype];
//        if (et.count >= et.target) {
//            //exceed limit
//            exceedLimit = true;
//        }
//        else {
//            et.count++;
//            return newtype;
//        }
//    }
//    
//    if (!exceedLimit) {
//        return newtype;
//    }
//    else {
//        //find a element without limit
//        std::vector<int> types;
//        for (int i=0; i<m_spawnData.size(); i++) {
//            //check amount limit
//            const ElementAmountPair &s = m_spawnData[i];
//            if (m_levelLimits.find(s.type) == m_levelLimits.end() &&
//                m_currentLimits.find(s.type) == m_currentLimits.end()) {
//                if (newisGhost) {
//                    kElementType t = (kElementType)s.type;
//                    if (!FMGameElement::isGhostType(t)) {
//                        types.push_back(s.type);
//                    }
//                }else{
//                    types.push_back(s.type);
//                }
//            }
//        }
//        if (types.size() != 0) {
//            int typeIndex = FMDataManager::getRandom(-1) % types.size();
//            kElementType retType = (kElementType)types.at(typeIndex);
//            return retType;
//        }
//    }
    
    return (kElementType)(kElement_1Red + FMDataManager::getRandom(-1) % 6);
}

FMGameElement * FMGameNode::createNewElement(int type)
{
    CCNode * offsetNode = m_gridParent->getChildByTag(1);
    FMGameElement * e = new FMGameElement;
    e->autorelease();
    e->retain();
    CCAssert(e != NULL, "new error");
    offsetNode->addChild(e->getAnimNode());

    kElementType t = (kElementType)type;
    if (t == kElement_Random) {
        t = (kElementType)getNewElementType();
        CCAssert(t != kElement_Random, "random algorithm error!");
    }
    e->setElementType(t);
    return e;
}

void FMGameNode::removeElement(FMGameElement *element)
{
    element->getAnimNode()->removeFromParentAndCleanup(true);
    element->release();
}

bool FMGameNode::checkGridMatch(FMGameGrid *grid)
{
    FMGameElement * element = grid->getElement();
    if (element && element->m_elementFlag & kFlag_Matchable) {
        int basecolor = element->getMatchColor();
        //check x axis
        {
            int count = 0;
            FMGameGrid * xgrid = grid;   
            while (xgrid) {
                FMGameElement * e = xgrid->getElement();
                bool matched = false;
                if (e && e->m_elementFlag & kFlag_Matchable) {
                    int color = e->getMatchColor();
                    if (color == basecolor) {
                        matched = true;
                        count++; 
                    }
                }
                if (matched) {
                    //continue
                    CCPoint coord = xgrid->getCoord();
                    xgrid = getNeighbor(coord.x, coord.y, kDirection_R);
                }
                else {
                    break;
                }
            }
            if (count >= 3) {
                return true;
            }  
        }
        
        //check y axis
        {
            int count = 0;
            FMGameGrid * xgrid = grid; 
            while (xgrid) {
                FMGameElement * e = xgrid->getElement();
                bool matched = false;
                if (e && e->m_elementFlag & kFlag_Matchable) {
                    int color = e->getMatchColor();
                    if (color == basecolor) {
                        matched = true;
                        count++; 
                    }
                }
                if (matched) {
                    //continue
                    CCPoint coord = xgrid->getCoord();
                    xgrid = getNeighbor(coord.x, coord.y, kDirection_B);
                }
                else {
                    break;
                }
            }
            if (count >= 3) {
                return true;
            } 
        }
    }
    return false;
}

bool FMGameNode::checkGridsStable()
{
    //check jump jelly grids
    bool stable = true;
//    for (std::vector<FMGameGrid *>::iterator it = m_jumpGrids.begin() ; it != m_jumpGrids.end(); it++) {
//        FMGameGrid * g = *it;
//        FMGameElement * e = g->getElement();
////        if (e && e->getElementType() == kElement_Drop) {
////            //make a new match group
////            stable = false;
////            FMMatchGroup * mg = new FMMatchGroup();
////            std::set<FMGameGrid *> * elements = mg->m_grids;
////            int gid = createNewMatchGroup();
////            m_matchedGroups[gid] = mg;
////            
////            elements->insert(g);
////            mg->m_grid = g;
////            e->m_matchGroup = gid;
////        }
//    }
    
    
    for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it!= m_matchedGroups.end(); it++) {
        FMMatchGroup * mg = it->second;
        mg->updateMatchType();
    }
    
    return stable;
}

bool FMGameNode::checkMatch()
{
    bool needStableCheck = false;
    CCAssert(m_matchedGroups.size() == 0, "match group is not cleared!");
    m_matchedGroups.clear();
    for (int i=0; i<kGridNum; i++) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
            FMGameElement * element = grid->getElement();
            if (element && element->m_elementFlag & kFlag_Matchable) {
                int basecolor = element->getMatchColor();
                //check x axis
                if (!element->m_elementFlag & kFlag_MatchX) {
                    int count = 0;
                    FMGameGrid * xgrid = grid;
                    FMMatchGroup * mg = new FMMatchGroup();
                    CCAssert(mg != NULL, "new error");
                    std::set<FMGameGrid *> * elements = mg->m_grids;
                    while (xgrid) {
                        FMGameElement * e = xgrid->getElement();
                        bool matched = false;
                        if (e && e->m_elementFlag & kFlag_Matchable) {
                            int color = e->getMatchColor();
                            if (color == basecolor && color != -1) {
                                matched = true;
                                count++;
                                elements->insert(xgrid);
                            }
                        }
                        if (matched) {
                            //continue
                            CCPoint coord = xgrid->getCoord();
                            xgrid = getNeighbor(coord.x, coord.y, kDirection_R);
                        }
                        else {
                            break;
                        }
                    }
                    if (count >= 3) {
                        //make a new match group
                        int gid = createNewMatchGroup();
                        m_matchedGroups[gid] = mg; 
                        std::vector<FMGameGrid*> willAddedToGroup;
                        for (std::set<FMGameGrid*>::iterator it = elements->begin(); it != elements->end(); it++) {
                            FMGameGrid * grid = *it;
                            CCAssert(grid, "grid cannot be NULL");
                            FMGameElement * e = grid->getElement();
                            int matchGroup = e->m_matchGroup;
                            if (matchGroup != -1 && matchGroup != gid && matchGroup != 100) {
                                //combine groupe
                                std::set<FMGameGrid *> * eles = m_matchedGroups[matchGroup]->m_grids;
                                for (std::set<FMGameGrid*>::iterator it = eles->begin(); it!= eles->end(); it++) {
                                    FMGameGrid * g = *it;
                                    FMGameElement * gEle = g->getElement();
                                    gEle->m_matchGroup = gid;
                                    gEle->m_elementFlag |= kFlag_Matchable;
                                    willAddedToGroup.push_back(g);
                                }
                                delete m_matchedGroups[matchGroup];
                                m_matchedGroups.erase(matchGroup);
                            }
                            e->m_matchGroup = gid; 
                            e->m_elementFlag |= kFlag_MatchX;
                        }
                        for (int i=0; i<willAddedToGroup.size(); i++) {
                            FMGameGrid * g = willAddedToGroup[i];
                            elements->insert(g);
                        }
                        willAddedToGroup.clear();
                    }
                    else {
                        delete mg;
                    }

                }
                                
                //check y axis
                if (!(element->m_elementFlag & kFlag_MatchY)) {
                    int count = 0;
                    FMGameGrid * xgrid = grid;
                    FMMatchGroup * mg = new FMMatchGroup;
                    CCAssert(mg != NULL, "new error");
                    std::set<FMGameGrid *> * elements = mg->m_grids;
                    while (xgrid) {
                        FMGameElement * e = xgrid->getElement();
                        bool matched = false;
                        if (e && e->m_elementFlag & kFlag_Matchable) {
                            int color = e->getMatchColor();
                            if (color == basecolor && color != -1) {
                                matched = true;
                                count++;
                                elements->insert(xgrid);
                            }
                        }
                        if (matched) {
                            //continue
                            CCPoint coord = xgrid->getCoord();
                            xgrid = getNeighbor(coord.x, coord.y, kDirection_B);
                        }
                        else {
                            break;
                        }
                    }
                    if (count >= 3) {
                        //make a new match group
                        int gid = createNewMatchGroup();
                        m_matchedGroups[gid] = mg;
                        std::vector<FMGameGrid*> willAddedToGroup;
                        for (std::set<FMGameGrid*>::iterator it = elements->begin(); it!= elements->end(); it++) {
                            FMGameGrid * grid = *it;
                            FMGameElement * e = grid->getElement();
                            int matchGroup = e->m_matchGroup;
                            if (matchGroup != -1 && matchGroup != gid && matchGroup != 100) {
                                //combine group
                                std::set<FMGameGrid *> * eles = m_matchedGroups[matchGroup]->m_grids;
                                for (std::set<FMGameGrid*>::iterator it = eles->begin(); it!= eles->end(); it++) {
                                    FMGameGrid * g = *it;
                                    FMGameElement * gEle = g->getElement();
                                    gEle->m_matchGroup = gid;
                                    gEle->m_elementFlag |= kFlag_MatchY;
                                    willAddedToGroup.push_back(g);
                                }
                                delete m_matchedGroups[matchGroup];
                                m_matchedGroups.erase(matchGroup);
                            }
                            e->m_matchGroup = gid;
                            e->m_elementFlag |= kFlag_MatchY;
                        }
                        for (int i=0; i<willAddedToGroup.size(); i++) {
                            FMGameGrid * g = willAddedToGroup[i];
                            elements->insert(g);
                        }
                        willAddedToGroup.clear();
                    }
                    else {
                        delete mg;
                    }
                }
            }
        }
    }
    
    if (m_matchedGroups.size() != 0) {
        needStableCheck = true;
    }
    
    
    for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it!= m_matchedGroups.end(); it++) {
        FMMatchGroup * mg = it->second;
        mg->updateMatchType();
    }
    
    for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it!= m_matchedGroups.end(); it++) {
        int gid = it->first;
        FMMatchGroup * mg = it->second;
        std::set<FMGameGrid *>* eles = mg->m_grids;
        char data[1000];
        sprintf(data, "");
        for (std::set<FMGameGrid*>::iterator it = eles->begin(); it!= eles->end(); it++) {
            FMGameGrid * g = *it;
            CCPoint p = g->getCoord();
            sprintf(data, "%s (%f, %f)", data, p.x, p.y );
        }
    }
    if (needStableCheck) {
        return true;
//        beginMatch();
    }
    return false;
}

bool FMGameNode::checkGridMatchable(FMGameGrid *grid)
{
    if (!grid->getElement()) {
        return false;
    }
    int color = grid->getElement()->getMatchColor();
    //first check x axis
    {
        FMGameGrid * right = getNeighbor(grid, kDirection_R);
        FMGameGrid * right2 = getNeighbor(right, kDirection_R);
        
        if (isGridMatchColor(right, color)) {
            //check neighbors
            FMGameGrid * gridLeft = getNeighbor(grid, kDirection_L);
            if (gridLeft) {
                FMGameGrid * gridLeftNeighbor = getNeighbor(gridLeft, kDirection_U);
                if (isGridMatchColor(gridLeftNeighbor, color) && isGridsSwappable(gridLeft, kDirection_U)) {
                    return true;
                }
                
                gridLeftNeighbor = getNeighbor(gridLeft, kDirection_L);
                if (isGridMatchColor(gridLeftNeighbor, color) && isGridsSwappable(gridLeft, kDirection_L)) {
                    return true;
                }
                
                gridLeftNeighbor = getNeighbor(gridLeft, kDirection_B);
                if (isGridMatchColor(gridLeftNeighbor, color) && isGridsSwappable(gridLeft, kDirection_B)) {
                    return true;
                }
            }
            
            if (right2) {
                FMGameGrid * right2neighbor = getNeighbor(right2, kDirection_U);
                if (isGridMatchColor(right2neighbor, color) && isGridsSwappable(right2, kDirection_U)) {
                    return true;
                }
                
                right2neighbor = getNeighbor(right2, kDirection_R);
                if (isGridMatchColor(right2neighbor, color) && isGridsSwappable(right2, kDirection_R)) {
                    return true;
                }
                
                right2neighbor = getNeighbor(right2, kDirection_B);
                if (isGridMatchColor(right2neighbor, color) && isGridsSwappable(right2, kDirection_B)) {
                    return true;
                }
                
            }
        }
        
        if (isGridMatchColor(right2, color)) {
            if (right) {
                FMGameGrid * rightneighbor = getNeighbor(right, kDirection_U);
                if (isGridMatchColor(rightneighbor, color) && isGridsSwappable(right, kDirection_U)) {
                    return true;
                }
                
                rightneighbor = getNeighbor(right, kDirection_B);
                if (isGridMatchColor(rightneighbor, color) && isGridsSwappable(right, kDirection_B)) {
                    return true;
                }
            }
            
        }
    }
    
    //check y axis
    {
        FMGameGrid * right = getNeighbor(grid, kDirection_U);
        FMGameGrid * right2 = getNeighbor(right, kDirection_U);
        
        if (isGridMatchColor(right, color)) {
            //check neighbors
            FMGameGrid * gridLeft = getNeighbor(grid, kDirection_B);
            if (gridLeft) {
                FMGameGrid * gridLeftNeighbor = getNeighbor(gridLeft, kDirection_L);
                if (isGridMatchColor(gridLeftNeighbor, color) && isGridsSwappable(gridLeft, kDirection_L)) {
                    return true;
                }
                
                gridLeftNeighbor = getNeighbor(gridLeft, kDirection_B);
                if (isGridMatchColor(gridLeftNeighbor, color) && isGridsSwappable(gridLeft, kDirection_B)) {
                    return true;
                }
                
                gridLeftNeighbor = getNeighbor(gridLeft, kDirection_R);
                if (isGridMatchColor(gridLeftNeighbor, color) && isGridsSwappable(gridLeft, kDirection_R)) {
                    return true;
                }
                
            }
            
            if (right2) {
                FMGameGrid * right2neighbor = getNeighbor(right2, kDirection_L);
                if (isGridMatchColor(right2neighbor, color) && isGridsSwappable(right2, kDirection_L)) {
                    return true;
                }
                
                right2neighbor = getNeighbor(right2, kDirection_U);
                if (isGridMatchColor(right2neighbor, color) && isGridsSwappable(right2, kDirection_U)) {
                    return true;
                }
                
                right2neighbor = getNeighbor(right2, kDirection_R);
                if (isGridMatchColor(right2neighbor, color) && isGridsSwappable(right2, kDirection_R)) {
                    return true;
                }
                
            }
        }
        
        if (isGridMatchColor(right2, color)) {
            if (right) {
                FMGameGrid * rightneighbor = getNeighbor(right, kDirection_L);
                if (isGridMatchColor(rightneighbor, color) && isGridsSwappable(right, kDirection_L)) {
                    return true;
                }
                
                rightneighbor = getNeighbor(right, kDirection_R);
                if (isGridMatchColor(rightneighbor, color) && isGridsSwappable(right, kDirection_R)) {
                    return true;
                }
            }
            
        }
    }
    return false;
}

//int FMGameNode::getGridMatchPriority(FMGameGrid * grid, int priority)
//{
//    if (!grid->getElement()) {
//        return priority;
//    }
//    int color = grid->getElement()->getMatchColor();
//    kGameDirection direction[4] = {kDirection_L, kDirection_B, kDirection_R, kDirection_U};
//    
//    for (int i = 0; i < 4; i++) {
//        kGameDirection dir = direction[i];
//        FMGameGrid * tg = getNeighbor(grid, dir);
//        if (!isGridMatchColor(tg, color) && isGridsSwappable(grid, dir)) {
//            std::vector<FMGameGrid *> tmpGrids = getMatchPriorityGrids(tg, color, dir);
//            tmpGrids.push_back(grid);
//            int tp = getGridsPriority(tmpGrids, color);
//            if (tp > priority) {
//                priority = tp;
//                m_matchableGrids.clear();
//                for (int j = 0; j < tmpGrids.size(); j++) {
//                    m_matchableGrids.push_back(tmpGrids.at(j));
//                }
//            }
//        }
//    }
//    return priority;
//}
//
//std::vector<FMGameGrid *> FMGameNode::getMatchPriorityGrids(FMGameGrid * grid, int elementColor, kGameDirection dismissDirection)
//{
//    std::vector<FMGameGrid *> reGrids;
//    if (!grid->getElement()) {
//        return reGrids;
//    }
//    
//    //check x
//    std::vector<FMGameGrid *> xGrids;
//    int xNumber = 1;
//    if (dismissDirection != kDirection_R) {
//        FMGameGrid * leftGrid = getNeighbor(grid, kDirection_L);
//        while (leftGrid && leftGrid->getElement()) {
//            if (leftGrid->getElement()->getMatchColor() == elementColor) {
//                xNumber++;
//                xGrids.push_back(leftGrid);
//                leftGrid = getNeighbor(leftGrid, kDirection_L);
//            }else{
//                break;
//            }
//        }
//    }
//    if (dismissDirection != kDirection_L) {
//        FMGameGrid * rightGrid = getNeighbor(grid, kDirection_R);
//        while (rightGrid && rightGrid->getElement()) {
//            if (rightGrid->getElement()->getMatchColor() == elementColor) {
//                xNumber++;
//                xGrids.push_back(rightGrid);
//                rightGrid = getNeighbor(rightGrid, kDirection_R);
//            }else{
//                break;
//            }
//        }
//    }
//    if (xNumber < 3) {
//        xGrids.clear();
//    }
//    //check y
//    std::vector<FMGameGrid *> yGrids;
//    int yNumber = 1;
//    if (dismissDirection != kDirection_B) {
//        FMGameGrid * upGrid = getNeighbor(grid, kDirection_U);
//        while (upGrid && upGrid->getElement()) {
//            if (upGrid->getElement()->getMatchColor() == elementColor) {
//                yNumber++;
//                yGrids.push_back(upGrid);
//                upGrid = getNeighbor(upGrid, kDirection_U);
//            }else{
//                break;
//            }
//        }
//    }
//    if (dismissDirection != kDirection_U) {
//        FMGameGrid * bGrid = getNeighbor(grid, kDirection_B);
//        while (bGrid && bGrid->getElement()) {
//            if (bGrid->getElement()->getMatchColor() == elementColor) {
//                yNumber++;
//                yGrids.push_back(bGrid);
//                bGrid = getNeighbor(bGrid, kDirection_B);
//            }else{
//                break;
//            }
//        }
//    }
//    if (yNumber < 3) {
//        yGrids.clear();
//    }
//    for (int i = 0; i < xGrids.size(); i++) {
//        FMGameGrid * g = xGrids.at(i);
//        reGrids.push_back(g);
//    }
//    for (int j = 0; j < yGrids.size(); j++) {
//        FMGameGrid * g = yGrids.at(j);
//        reGrids.push_back(g);
//    }
//    return reGrids;
//}
//
//int FMGameNode::getGridsPriority(std::vector<FMGameGrid *> grids, int color)
//{
//    if (grids.size() < 3) {
//        return 0;
//    }
//    int reValue = 0;
//    int p = 1;
//    if (isTypeLack(color)) {
//        p = 2;
//    }
//    if (grids.size() > 4) {
//        reValue += 20;
//    }
//    for (int i = 0; i < grids.size(); i++) {
//        FMGameGrid * grid = grids.at(i);
//        int value = grid->getElement()->getValue()+1;
//        reValue += value*p;
//    }
//    return reValue;
//}

bool FMGameNode::checkMatchable()
{
    m_matchableGrids.clear();
    for (int i=kGridNum-1; i>=0; i--) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
            bool gridMatchable = checkGridMatchable(grid);
            if (gridMatchable) {
                return true;
            }
        }
    }
    return false;
}

void FMGameNode::shuffle()
{
    shuffleTimes++;
    m_movingElements.clear();
    m_animChecker->resetCheckingAnims();
    std::vector<FMGameGrid *> freeGrids;
    std::vector<FMGameElement *> freeElements;
    for (int i=0; i<kGridNum; i++) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
            FMGameElement * e = grid->getElement();
            if (e && e->m_elementFlag & kFlag_ShuffleAble) {
                freeGrids.push_back(grid);
                freeElements.push_back(e);
                e->cleanMoveQueue();
            }
        }
    }
    
    for (int i=0; i<freeGrids.size(); i++) {
        FMGameGrid * grid = freeGrids.at(i);
        int index = FMDataManager::getRandom(-1) % freeElements.size();
        FMGameElement * randElement = freeElements.at(index);
        grid->setOccupyElement(randElement);
        std::vector<FMGameElement *>::iterator it = freeElements.begin() + index;
        freeElements.erase(it);
        CCPoint coord = grid->getCoord();
        CCPoint target = getPositionForCoord(coord.x, coord.y);
        CCPoint offset = ccpSub(randElement->getAnimNode()->getPosition(), target);
        float distance = ccpLength(offset);
        int moves = floor(distance / 30.f);
        randElement->setZOrder(moves*10+100);
        float time = moves * 0.075f;
        randElement->playAnimation("Move");
        float scale = MIN(moves, 10) * 0.1f + 1.f;
        CCCallFunc * makeNormal = CCCallFunc::create(randElement, callfunc_selector(FMGameElement::makeNormal));
//        CCJumpTo * j = CCJumpTo::create(time, target, 10.f, moves);
        CCMoveTo * j = CCMoveTo::create(time, target);
        float angle = index%2==0? 360.f:-360.f;
        CCRotateBy * rot = CCRotateBy::create(time, angle*moves);
        CCScaleTo * s1 = CCScaleTo::create(time * 0.5f, scale);
        CCScaleTo * s2 = CCScaleTo::create(time * 0.5f, 1.f);
        CCSequence * seq1 = CCSequence::create(s1,s2,NULL);
        CCSpawn * spawn = CCSpawn::create(j,seq1, rot,NULL);
        CCCallFuncO * reorder = CCCallFuncO::create(this, callfuncO_selector(FMGameNode::resetZOrder), grid);
        CCSequence* seq = CCSequence::create(spawn, reorder, makeNormal, NULL);
        
//        bool isRevert = false;
//        if (offset.x < 0.f) isRevert = !isRevert;
//        if (randElement->getElementType() == kElement_3Yellow || randElement->getElementType() == kElement_3YellowBad) {
//            isRevert = !isRevert;
//        }
//        if (isRevert) {
//            randElement->getAnimNode()->setScaleX(-1.f);
//            seq = CCSequence::create(seq, CCScaleTo::create(0.0f, 1.f, 1.f), NULL);
//        }
//        else {
//            randElement->getAnimNode()->setScaleX(1.f);
//        }
        
        //CCMoveTo * act1 = CCMoveTo::create(1.f, getPositionForCoord(coord.x, coord.y));
        randElement->getAnimNode()->stopAllActions();
//        randElement->getAnimNode()->runAction(act1);
        m_animChecker->addCCNode(randElement->getAnimNode(), seq, "cc flag 1");
    }
    
    bool needShuffle = false;
    needShuffle = checkMatch();
    cleanMatchFlag();
    if (needShuffle) {
        shuffle();
    }
    
    needShuffle = !checkGridsStable();
    cleanMatchFlag();
    if (needShuffle) {
        shuffle();
    }
    
    needShuffle = !checkMatchable();
    if (needShuffle) {
        shuffle();
    }
    else {
//        markMatchable();
    }
}
void FMGameNode::resetZOrder(FMGameGrid * grid)
{
    grid->getElement()->setZOrder((grid->getCoord().x+1) * 5);
}

bool FMGameNode::checkMapPlayable()
{
    shuffleTimes++;
    
    bool needShuffle = false;
    needShuffle = checkMatch();
    cleanMatchFlag();
    if (needShuffle) { 
        return false;
    }
    
    needShuffle = !checkGridsStable();
    cleanMatchFlag();
    if (needShuffle) {
        return false;
    }
    
    needShuffle = !checkMatchable();
    if (needShuffle) {
        return false;
    }
    return true;
}

void FMGameNode::beforeMatch()
{
    setGamePhase(kPhase_BeforeMatch);
}

void FMGameNode::breakWall(std::set<FMGameGrid *> * checkQueue, FMGameGrid *grid)
{
    static kGameDirection checkDirs[4] = {kDirection_U, kDirection_B, kDirection_L, kDirection_R};
    checkQueue->erase(grid);
    for (int i=0; i<4; i++) {
        FMGameGrid * neighbor = getNeighbor(grid, checkDirs[i]);
        if (neighbor && checkQueue->find(neighbor) != checkQueue->end()) {
            FMGameWall * wall = getWall(grid, checkDirs[i]);
            if (wall->getWallType() == kWallBreak) {
                //消除墙时加分
                addScore(200);
            }
            if (wall->breakWall()) {
//                triggerAddValueToSpecailTarget(kElement_TargetWall);
            }

            breakWall(checkQueue, neighbor);
        }
    }
}

void FMGameNode::gridNextPhase(FMMatchGroup *mg, FMGameGrid *grid, float harvestDelay)
{
    FMGameElement * e = grid->getElement();
    if (!e) {
        return;
    }
    //    int phase = e->getPhase();
    kElementType type = e->getElementType();
    switch (type) {
        case kElement_1Red:
        case kElement_2Orange:
        case kElement_3Yellow:
        case kElement_4Green:
        case kElement_5Blue:
        case kElement_6Pink:
            
        {
            kElementType t = type;
            float delay = harvestDelay;
            e->showSelected(false);

            if (m_targets.find(t) != m_targets.end()) {
                //普通元素收集时加分
                addScore(getHarvestScore(type) * (1));
                //harvest
                //move to ui
                elementTarget et = m_targets[t];
                CCPoint posInUi = e->getAnimNode()->convertToWorldSpace(CCPointZero);
                posInUi = m_gameUI->convertToNodeSpace(posInUi);
                e->getAnimNode()->removeFromParentAndCleanup(false);
                m_gameUI->addChild(e->getAnimNode(), 200);
                e->getAnimNode()->setPosition(posInUi);
                CCPoint posInUiTarget = CCPointZero;
                if (m_gameMode == kGameMode_Boss) {
                    //posInUiTarget = m_bossGround[m_bossIndex]->convertToWorldSpace(CCPointZero);
                }
                else if (m_gameMode == kGameMode_Harvest) {
                    NEAnimNode * animTarget = (NEAnimNode *)m_modeNode[kGameMode_Harvest]->getChildByTag(type-1);
                    posInUiTarget = animTarget->convertToWorldSpace(CCPointZero);
                }
                else {
                    posInUiTarget = m_targetAnimNode[et.index]->convertToWorldSpace(CCPointZero);
                }
                posInUiTarget = m_gameUI->convertToNodeSpace(posInUiTarget);
                if (m_gameMode == kGameMode_Boss) {
                    posInUiTarget.x += FMDataManager::getRandom() % 10 - 5;
                    posInUiTarget.y += FMDataManager::getRandom() % 10 + 5;
                }
                else if (m_gameMode == kGameMode_Harvest) {
//                    posInUiTarget.x += FMDataManager::getRandom() % 80 - 40;
//                    posInUiTarget.y += FMDataManager::getRandom() % 20 - 10;
                }
                
                CCDelayTime * del = CCDelayTime::create(delay); 
                CCScaleTo * s1 = CCScaleTo::create(0.3f, 1.3f);
                CCScaleTo * s2 = CCScaleTo::create(0.3f, 0.65f);
                CCSequence * seq1 = CCSequence::create(s1, s2, NULL);
                ccBezierConfig config;
                config.controlPoint_1 = posInUi;
                config.controlPoint_2 = ccp(posInUiTarget.x, posInUi.y);
                config.endPosition = posInUiTarget;
                CCCallFunc * makenormal = CCCallFunc::create(e, callfunc_selector(FMGameElement::makeNormal));
                CCBezierTo * m1 = CCBezierTo::create(0.6f, config);
                CCEaseOut * ease = CCEaseOut::create(m1, 2.f); 
                CCSpawn * spa = CCSpawn::create(seq1, ease, NULL);
                CCCallFuncO * remove = NULL; 
                remove = CCCallFuncO::create(this, callfuncO_selector(FMGameNode::triggerAddValueToTarget), e);
                
//                if (m_gameMode == kGameMode_Boss) {
////                    remove = CCCallFuncO::create(this, callfuncO_selector(FMGameNode::triggerHitBoss), e);
//                }
//                else if (m_gameMode == kGameMode_Harvest) {
//                    remove = CCCallFuncO::create(this, callfuncO_selector(FMGameNode::triggerHarvest), e);
//                }
//                else {
//                    remove = CCCallFuncO::create(this, callfuncO_selector(FMGameNode::triggerAddValueToTarget), e);
//                }
                
                
                CCSequence * seq2 = NULL;
                if (m_gameMode == kGameMode_Boss) {
                    static float flyDistance = 30.f;
                    float x = (FMDataManager::getRandom() % 2 - 0.5) * 2.f * flyDistance + posInUiTarget.x + FMDataManager::getRandom() % 10 - 5.f;
                    float y = posInUiTarget.y + FMDataManager::getRandom() % 20 - 10.f;
                    float angle = FMDataManager::getRandom() % 1080 - 540.f;
                    float height = FMDataManager::getRandom() % (int)flyDistance + flyDistance * 0.5f;
                    CCJumpTo * fly = CCJumpTo::create(0.7f, ccp(x, y), height, 1);
                    CCRotateBy * rot = CCRotateBy::create(0.7f, angle);
                    CCSpawn * spawn = CCSpawn::create(fly, rot, NULL);
                    CCCallFuncO * removedone = CCCallFuncO::create(this, callfuncO_selector(FMGameNode::triggerHitDone), e);
                    seq2 = CCSequence::create(del, makenormal, spa, remove, spawn, removedone, NULL);
                }
                else if (m_gameMode == kGameMode_Harvest) {
//                    NEAnimNode * hiteffect = NEAnimNode::createNodeFromFile("FMEffectHitStar.ani");
//                    m_gameUI->addChild(hiteffect, 2011);
//                    hiteffect->setPosition(posInUiTarget);
//                    hiteffect->setAutoRemove(true);
//                    CCString * animName = CCString::createWithFormat("Star%d", FMDataManager::getRandom() % 2 + 1);
//                    CCCallFuncO * call = CCCallFuncO::create(hiteffect, callfuncO_selector(NEAnimNode::playAnimationCallback), animName);
//                    seq2 = CCSequence::create(del, makenormal, spa, remove, call, NULL);
                    seq2 = CCSequence::create(del, makenormal, spa, remove, NULL);
                }
                else {
                    seq2 = CCSequence::create(del, makenormal, spa, remove, NULL);
                }
//                e->getAnimNode()->runAction(seq2);
//                mg->addSyncCCNode(e->getAnimNode(), seq2, "sync cc flag 1");
                e->getAnimNode()->runAction(seq2);
                CCDelayTime * delay = CCDelayTime::create(0.15f);
                mg->addCCNode(e->getAnimNode(), delay, "cc flag 4");
//                    e->getAnimNode()->runAction(seq2);
                e->getAnimNode()->getParent()->reorderChild(e->getAnimNode(), 100);
                grid->setOccupyElement(NULL);
                
            }
            else {
                //普通元素消除时加分
                addScore(getBaseScore(type));
                //throw away
//                if (m_usingItem == kBooster_Harvest1Row) {
                    FMGameElement * e = grid->getElement();
                    CCDelayTime * del = CCDelayTime::create(delay);
                    NEAnimationAction * anim = NEAnimationAction::create("Disappear");
                    CCDelayTime * disappeartime = CCDelayTime::create(0.5f);
                    CCCallFuncO * remove = CCCallFuncO::create(this, callfuncO_selector(FMGameNode::removeElement), e);
                    CCSequence * seq = CCSequence::create(del, anim, disappeartime, remove, NULL);
                    e->getAnimNode()->runAction(seq);
//                    mg->addSyncCCNode(e->getAnimNode(), seq, "sync cc flag 2");
                    CCDelayTime * delay = CCDelayTime::create(0.15f);
                    mg->addCCNode(e->getAnimNode(), delay, "cc flag 5");
                    grid->setOccupyElement(NULL);
//                }
//                else {
//                    FMGameElement * e = grid->getElement();
//                    e->playAnimation("Disappear");
//                    mg->addAnimNode(e->getAnimNode());
//                }
            }
        }
            break;
      
        default:
            break;
    }
}

void FMGameNode::checkTriggers()
{
    for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it != m_matchedGroups.end(); it++) {
//    if (m_matchedGroups.size() > m_matchedGroupsIndex) {
//        std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin();
//        std::advance(it, m_matchedGroupsIndex);
        FMMatchGroup * mg = it->second;
        std::set<FMGameGrid *>* eles = mg->m_grids;
        for (std::set<FMGameGrid*>::iterator it = eles->begin(); it!= eles->end(); it++) {
            FMGameGrid * g = *it;
            FMGameElement * e = g->getElement();
            if (e) {
                e->getAnimNode()->playAnimation("Match");
            }
        }

        
        //break walls
        std::set<FMGameGrid *> grids;
        grids.insert(mg->m_grids->begin(), mg->m_grids->end());
        
        if (grids.size() != 0) {
            FMGameGrid * firstGrid = *(grids.begin());
            breakWall(&grids, firstGrid);
        }
        
        
        //ice
        std::set<FMGameGrid *> deleted;
        for (std::set<FMGameGrid*>::iterator it = mg->m_grids->begin(); it != mg->m_grids->end(); it++) {
            FMGameGrid * grid = *it;
            FMGameElement * e = grid->getElement();
            if (e && e->hasStatus(kStatus_Frozen)) {
                CCAssert(e, "matching element cannot be NULL!");
                deleted.insert(grid);
                e->removeStatus(kStatus_Frozen);
//                triggerAddValueToSpecailTarget(kElement_TargetIce);
                CCDelayTime * delay = CCDelayTime::create(0.4f);
                mg->addCCNode(e->getAnimNode(), delay, "cc flag 10");
            }
        }
         
        for (std::set<FMGameGrid*>::iterator it = deleted.begin(); it!=deleted.end(); it++) {
            FMGameGrid * grid = *it;
            grid->getElement()->m_matchGroup = -1;
            grid->getElement()->m_elementFlag &= ~kFlag_MatchX;
            grid->getElement()->m_elementFlag &= ~kFlag_MatchY;
            mg->m_grids->erase(*it);
        }

        std::set<FMGameGrid*> aroundGrids = getGridsAroundMatchGroup(mg);
        for (std::set<FMGameGrid*>::iterator it = aroundGrids.begin(); it != aroundGrids.end(); it++) {
            FMGameGrid * g = *it;
            FMGameElement * e = g->getElement();
        }
    }
}

void FMGameNode::beginMatch()
{
    setGamePhase(kPhase_CheckTriggers);
    checkTriggers();
}

void FMGameNode::beginHarvest()
{
    setGamePhase(kPhase_Harvest);
    
    //trigger grid bonus
    for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it != m_matchedGroups.end(); it++) {
//    if (m_matchedGroups.size() > m_matchedGroupsIndex) {
//        std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin();
//        std::advance(it, m_matchedGroupsIndex);
        FMMatchGroup * mg = it->second;
//        if (mg->getMatchType() == kMatch_4 || mg->getMatchType() == kMatch_5Cross || mg->getMatchType() == kMatch_5Line) {
//            //set the trigger grid
//            if (mg->isGridInGroup(m_swapGrid1)) {
//                mg->m_grid = m_swapGrid1;
//            }
//            else if (mg->isGridInGroup(m_swapGrid2)) {
//                mg->m_grid = m_swapGrid2;
//            }else{
//                
//            }
//        }
        
    }
    m_swapGrid1 = NULL;
    m_swapGrid2 = NULL;
    
    //play harvest animation
    for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it!= m_matchedGroups.end(); it++) {
        //    if (m_matchedGroups.size() > m_matchedGroupsIndex) {
        //        std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin();
        //        std::advance(it, m_matchedGroupsIndex);
        FMMatchGroup * mg = it->second;
        if (mg->m_grids->size() > 0) {
            m_soundEffectCombo++;
            int v = m_soundEffectCombo - 1;
            if (v > 6) {
                v = 6;
            }
            CCString * str = CCString::createWithFormat("combo_%02d.mp3", v);
            FMSound::playEffect(str->getCString());
            
            FMGameGrid * firstGrid = *(mg->m_grids->begin());
            mg->setMatchEnd(false);
            mg->resetPhase();
            
            
            int color = -1;
            if (mg->m_grids->size() > 0) {
                FMGameGrid * grid = *mg->m_grids->begin();
                if (grid->getElement()) {
                    color = grid->getElement()->getMatchColor();
                }
            }
            
            int addValueTotal = 0;
            for (std::set<FMGameGrid*>::iterator it = mg->m_grids->begin(); it != mg->m_grids->end(); it++) {
                FMGameGrid * grid = *it;
                FMGameElement * e = grid->getElement();
                if (e) {
                    kElementType type = e->getElementType();
                    if (m_targets.find(type) != m_targets.end()) {
                        int v = 0;
                        addValueTotal += v + 1;
                    }
                }
            }
            
            if (addValueTotal > 0) {
                //show add value
                CCString* str = CCString::createWithFormat("+%d", addValueTotal);
                //CCLabelAtlas * valueLabel = CCLabelAtlas::create(str->getCString(), "+0123456789", 21, 21, '+');
                CCLabelBMFont * valueLabel = CCLabelBMFont::create(str->getCString(), "font_add_value.fnt");
                FMGameGrid * shooter = mg->m_grid;
                if (!shooter) {
                    int r = mg->m_grids->size() * 0.5f;
                    std::set<FMGameGrid*>::iterator it = mg->m_grids->begin();
                    std::advance(it, r);
                    shooter = *it;
                }
                valueLabel->setPosition(shooter->getPosition());
                m_gameUI->addChild(valueLabel, 201);
                CCPoint posInUi = shooter->getElement()->getAnimNode()->convertToWorldSpace(CCPointZero);
                posInUi = m_gameUI->convertToNodeSpace(posInUi);
                valueLabel->setPosition(posInUi);
                
                CCFadeOut * f = CCFadeOut::create(0.6f);
                CCEaseIn * ef = CCEaseIn::create(f, 5.f);
                CCScaleTo * s = CCScaleTo::create(0.6f, 1.5f);
                CCSpawn * spawn = CCSpawn::create(ef, s, NULL);
                CCEaseOut * ease = CCEaseOut::create(spawn, 2.f);
                CCCallFunc * remove = CCCallFunc::create(valueLabel, callfunc_selector(CCNode::removeFromParent));
                CCSequence * seq = CCSequence::create(ease, remove, NULL);
                valueLabel->runAction(seq);
            }
            
            
            float delay = 0.f;
            for (std::set<FMGameGrid*>::iterator it = mg->m_grids->begin(); it != mg->m_grids->end(); it++) {
                
                FMGameGrid * grid = *it;
                delay = grid->getCoord().y * 0.05f;
                gridNextPhase(mg, grid, delay);
            }
        }
    }
    
    
    //trigger bonus generate
//    for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it != m_matchedGroups.end(); it++) {
//    if (m_matchedGroups.size() > m_matchedGroupsIndex) {
//        std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin();
//        std::advance(it, m_matchedGroupsIndex);
//        FMMatchGroup * mg = it->second;
//        triggerGenerateGridBonus(mg);
//    }
}

void FMGameNode::beginFalling()
{      
    setGamePhase(kPhase_Falling);
    //clear all matches
    for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it!= m_matchedGroups.end(); it++) {
        FMMatchGroup * mg = it->second;
        std::set<FMGameGrid *>* eles = mg->m_grids;
        for (std::set<FMGameGrid*>::iterator it = eles->begin(); it!= eles->end(); it++) {
            FMGameGrid * g = *it;
            FMGameElement * e = g->getElement();
            if (e) {
                removeElement(e);
            }
            
            g->setOccupyElement(NULL);
        }
//        delete mg;
    }
//    m_matchedGroups.clear();
//    m_matchedGroupsIndex = 0;
    checkFalling();
}

void FMGameNode::cleanMatchFlag()
{
    //clear all matches
    for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it!= m_matchedGroups.end(); it++) {
        FMMatchGroup * mg = it->second;
        std::set<FMGameGrid *>* eles = mg->m_grids;
        for (std::set<FMGameGrid*>::iterator it = eles->begin(); it!= eles->end(); it++) {
            FMGameGrid * g = *it;
            FMGameElement * e = g->getElement();
            e->m_matchGroup = -1;
            e->m_elementFlag &= ~kFlag_MatchX;
            e->m_elementFlag &= ~kFlag_MatchY;
        }
        delete mg;
    }
    m_matchedGroups.clear();
}


bool FMGameNode::checkFalling()
{
    bool needFalling = false;
    for (int i=kGridNum-1; i>=0; i--) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * grid = getNeighbor(i, j, kDirection_Center); 
            makeGridStable(grid);
        }
    }
    for (int i=kGridNum-1; i>=0; i--) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
            grid->m_acceptSlide = true;
        }
    }

    beginSpawn();

    
    return needFalling;
}

void FMGameNode::beginSpawn()
{
    if (m_spawner.size() == 0) {
        return;
    }
    bool hasEmpty = true;
    while (hasEmpty) {
        hasEmpty = false;
        for (int i=0; i<m_spawner.size(); i++) {
            FMGameGrid * grid = m_spawner[i];
            if (grid->hasGridStatus(kGridStatus_Spawner) && grid->isEmpty()) {
                //generate an element

                FMGameElement * e = createNewElement(kElement_Random);
                grid->queueSpawnElement(e);
                grid->setOccupyElement(e);
                addMovingElement(e); 
                e->DropMove(grid->getPosition(), CCPointZero);
                makeGridStable(grid);
            }
            if (grid->isEmpty()) {
                hasEmpty = true;
            }
            else {
                
            }
        }
    }
}

void FMGameNode::checkAI()
{ 
    setGamePhase(kPhase_AI);
    m_animChecker->setMatchEnd(false);
    m_aiChecked = true;
    
        
//    //check snails falling
//    {
//        int currentNum = m_snailGrids.size();
//        int need = m_snailSameTime - currentNum;
//        if (need > 0) {
//            //drop snails
//            
//            std::vector<FMGameGrid *> freeGrids;
//            for (int i=0; i<kGridNum; i++) {
//                for (int j=0; j<kGridNum; j++) {
//                    FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
//                    if (grid && grid->getElement()) {
//                        if (grid->hasGridStatus(kStatus_Spawner)) {
//                            continue;
//                        }
//                        FMGameElement * element = grid->getElement();
//                        if (element->canBeDisabled() && !element->isDisabled()) {
//                            freeGrids.push_back(grid);
//                        }
//                    }
//                }
//            }
//            
//            int free = freeGrids.size();
//            free -= 10;
//            while (free > 0 && need > 0 && m_snailMax > 0) {
//                int r = FMDataManager::getRandom(-1) % free;
//                std::vector<FMGameGrid *>::iterator it = freeGrids.begin() + r;
//                FMGameGrid * g = *it;
//                FMGameElement * e = g->getElement();
//                g->getElement()->setDisabled(true);
//               
//                NEAnimNode * snailAnim = g->getElement()->getSnailAnim();
//                snailAnim->removeFromParent();
//                CCNode * offsetNode = m_gridParent->getChildByTag(1);
//                offsetNode->addChild(snailAnim, 250);
//                snailAnim->playAnimation("snailmove", 0, true, false);
//                CCPoint finalPos = g->getPosition();
//                CCPoint initPos = finalPos;
//                initPos.y = 500;
//                snailAnim->setPosition(initPos);
//                float time = (FMDataManager::getRandom() % 10) * 0.025f + 0.5f;
//                FMSound::playEffect("snail_fall.mp3");
//                CCMoveTo * act1 = CCMoveTo::create(time, finalPos);
//                CCCallFuncO * act2 = CCCallFuncO::create(this, callfuncO_selector(FMGameNode::callbackSnailDropDone), e);
//                CCSequence  * seq = CCSequence::create(act1, act2, NULL);
//                m_animChecker->addCCNode(snailAnim, seq, "cc flag 12");
//                
//                
//                
//                m_snailGrids.insert(g);
//                freeGrids.erase(it);
//                free--;
//                need--;
//                m_snailMax--;
//            }
//        }
//    }
    
}

void FMGameNode::beforeNewTurn()
{
    //can match
    m_aiChecked = false;
    m_swapGrid1 = NULL;
    m_swapGrid2 = NULL;
    setGamePhase(kPhase_BeforeNewTurn);
    m_thinkingTime = 0.f;
    m_idleTime = idleTimePeriod;
    m_combo = 0;
//    m_soundEffectCombo = 0;
    //clean all combos
    for (int i=0; i<kGridNum; i++) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * g = getNeighbor(i, j, kDirection_C);
            FMGameElement * e = g->getElement();
//            if (e) {
//                e->resetCombo();
//            }
        }
    }
    
    m_animChecker->cleanCheckingAnims();
    m_animChecker->cleanGrids();
    if (m_maniaModeBegin) {
        if (m_leftMoves > 0) {
            return;
        }
    }
    checkWinner();
}

void FMGameNode::makeGridStable(FMGameGrid *grid)
{
    CCPoint coord = grid->getCoord();
    int row = coord.x;
    int col = coord.y;
    if (grid->isNone()) {
        return;
    }
    if (grid->isEmpty()) {
        FMGameGrid * upGrid = grid;//getNeighbor(row, col, kDirection_U);
        while (upGrid && !upGrid->isNone()) {
            if (upGrid->isEmpty()) {
                if (isDirectionBlocked(row, col, kDirection_U)) {
                    //this grid is stable since up direction is blocked
                    return;
                }
                row--;
                upGrid = getNeighbor(row, col, kDirection_Center);
            }
            else if (!upGrid->isExistMovableElement()) {
                return;
            }
            else {
                addMovingElement(upGrid->getElement());
                upGrid->getElement()->setZOrder((grid->getCoord().x+1) * 5);
                upGrid->getElement()->DropMove(grid->getPosition(), initDropSpeed);
                grid->setOccupyElement(upGrid->getElement());
                upGrid->setOccupyElement(NULL);
                makeGridStable(grid);
                //make falling grids not accept sliding
                FMGameGrid * downGrid = getNeighbor(upGrid, kDirection_B);
                while (downGrid && downGrid->isMovable()) {
                    downGrid->m_acceptSlide = false;
                    downGrid = getNeighbor(downGrid, kDirection_B);
                }
                break;
            }
        } 
    }
    else
    {
        if (!grid->isExistMovableElement()) {
            return;
        }
        else {
            //see if can drop down
            FMGameGrid * bottomGrid = getNeighbor(row, col, kDirection_B);
            FMGameGrid * lastMovableGrid = NULL;
            while (bottomGrid) {
                if (bottomGrid->isMovable() && !isDirectionBlocked(bottomGrid, kDirection_U)) {
                    lastMovableGrid = bottomGrid;
                    CCPoint co = bottomGrid->getCoord();
                    bottomGrid = getNeighbor(co.x, co.y, kDirection_B);
                }
                else {
                    break;
                }
            }
            if (lastMovableGrid) {
                addMovingElement(grid->getElement());
                grid->getElement()->setZOrder((lastMovableGrid->getCoord().x+1) * 5);
                grid->getElement()->DropMove(lastMovableGrid->getPosition(), initDropSpeed);

                lastMovableGrid->setOccupyElement(grid->getElement());
                grid->setOccupyElement(NULL);
                makeGridStable(lastMovableGrid);
                makeGridStable(grid);
                return;
            }
            else {
            }
            
            //see slide if able, left
            FMGameGrid * slideGrid = getNeighbor(row, col, kDirection_LB);
            
            //see this column has spawner? if so, don't slide
            if (slideGrid && slideGrid->isMovable() && slideGrid->m_acceptSlide &&
                hasRouteToDirection(grid, kDirection_LB)) {
                //check up grid
                FMGameGrid * upGrid = getNeighbor(slideGrid, kDirection_U);
                if (upGrid) {
                    bool canSlide = false;
                    if (upGrid->isNone() || isDirectionBlocked(upGrid, kDirection_B)) {
                        canSlide = true;
                    }
                    else {
                        if (upGrid->isEmpty()) {
                            if (upGrid->hasGridStatus(kGridStatus_Spawner)) {
                                canSlide = false;
                            }
                            else {
                                //check 3 upgrids
                                while (!upGrid->isNone() && upGrid->isEmpty() && !isDirectionBlocked(upGrid, kDirection_B)) {
                                    bool exist = false;
                                    FMGameGrid * u1 = getNeighbor(upGrid, kDirection_LU);
                                    if (u1 && u1->isExistMovableElement() && hasRouteToDirection(upGrid, kDirection_LU)) {
                                        exist = true;
                                    }
                                    
                                    FMGameGrid * u2 = getNeighbor(upGrid, kDirection_U);
                                    if (u2 && u2->isExistMovableElement() && hasRouteToDirection(upGrid, kDirection_U)) {
                                        exist = true;
                                    }
                                    
                                    FMGameGrid * u3 = getNeighbor(upGrid, kDirection_RU);
                                    if (u3 && u3->isExistMovableElement() && hasRouteToDirection(upGrid, kDirection_RU)) {
                                        exist = true;
                                    }
                                    
                                    if (exist) {
                                        canSlide = false;
                                        break;
                                    }
                                    else {
                                        if (u2 && u2->isMovable() && !isDirectionBlocked(u2, kDirection_B)) {
                                            if (u2->hasGridStatus(kGridStatus_Spawner)) {
                                                canSlide = false;
                                                break;
                                            }
                                            else {
                                                upGrid = u2;
                                            }
                                        }
                                        else {
                                            canSlide = true;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                        else {
                            if (upGrid->isExistImmovableElement()) {
                                canSlide = true;
                            }
                        }
                    }
                    
                    if (canSlide) {
                        addMovingElement(grid->getElement());
                        grid->getElement()->setZOrder((slideGrid->getCoord().x+1) * 5);
                        grid->getElement()->SlideMove(slideGrid->getPosition(), initSlideSpeed);
                        slideGrid->setOccupyElement(grid->getElement());
                        grid->setOccupyElement(NULL);
                        
                        makeGridStable(slideGrid);
                        makeGridStable(grid);

                        return;
                    }
                }
                
            }
            
            
            //then check right side
            slideGrid = getNeighbor(row, col, kDirection_RB);
            
            if (slideGrid && slideGrid->isMovable() && slideGrid->m_acceptSlide &&
                hasRouteToDirection(grid, kDirection_RB)) {
                //check up grid
                FMGameGrid * upGrid = getNeighbor(slideGrid, kDirection_U);
                if (upGrid) {
                    bool canSlide = false;
                    if (upGrid->isNone() || isDirectionBlocked(upGrid, kDirection_B)) {
                        canSlide = true;
                    }
                    else {
                        if (upGrid->isEmpty()) {
                            if (upGrid->hasGridStatus(kGridStatus_Spawner)) {
                                canSlide = false; 
                            }
                            else {
                                //check 3 upgrids
                                while (!upGrid->isNone() && upGrid->isEmpty() && !isDirectionBlocked(upGrid, kDirection_B)) {
                                    bool exist = false;
                                    FMGameGrid * u1 = getNeighbor(upGrid, kDirection_LU);
                                    if (u1 && u1->isExistMovableElement() && hasRouteToDirection(upGrid, kDirection_LU)) {
                                        exist = true;
                                    }
                                    
                                    FMGameGrid * u2 = getNeighbor(upGrid, kDirection_U);
                                    if (u2 && u2->isExistMovableElement() && hasRouteToDirection(upGrid, kDirection_U)) {
                                        exist = true;
                                    }
                                    
                                    FMGameGrid * u3 = getNeighbor(upGrid, kDirection_RU);
                                    if (u3 && u3->isExistMovableElement() && hasRouteToDirection(upGrid, kDirection_RU)) {
                                        exist = true;
                                    }
                                    
                                    if (exist) {
                                        canSlide = false;
                                        break;
                                    }
                                    else {
                                        if (u2 && u2->isMovable() && !isDirectionBlocked(u2, kDirection_B)) {
                                            if (u2->hasGridStatus(kGridStatus_Spawner)) {
                                                canSlide = false;
                                                break;
                                            }
                                            else {
                                                upGrid = u2;
                                            }
                                        }
                                        else {
                                            canSlide = true;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                        else {
                            if (upGrid->isExistImmovableElement()) {
                                canSlide = true;
                            }
                        }
                    }
                    
                    if (canSlide) {
                        addMovingElement(grid->getElement());
                        grid->getElement()->setZOrder((slideGrid->getCoord().x+1) * 5);
                        grid->getElement()->SlideMove(slideGrid->getPosition(), initSlideSpeed);
                        slideGrid->setOccupyElement(grid->getElement());
                        grid->setOccupyElement(NULL);
                        
                        makeGridStable(slideGrid);
                        makeGridStable(grid);

                        return;
                    }
                }
            }
        }
    }
}

CCPoint FMGameNode::getNeighborCoord(int row, int col, int direction)
{
    switch (direction) {
        case kDirection_LU:
            row--;col--;
            break;
        case kDirection_U:
            row--;
            break;
        case kDirection_RU:
            row--;col++;
            break;
        case kDirection_L:
            col--;
            break;
        case kDirection_Center:
            break;
        case kDirection_R:
            col++;
            break;
        case kDirection_LB:
            row++;col--;
            break;
        case kDirection_B:
            row++;
            break;
        case kDirection_RB:
            row++;col++;
            break;
        default:
            row=col=-1;
            break;
    }
    return ccp(row, col);
}

FMGameGrid * FMGameNode::getNeighbor(FMGameGrid *grid, int direction)
{
    if (!grid) {
        return NULL;
    }
    CCPoint coord = grid->getCoord();
    return getNeighbor(coord.x, coord.y, direction);
}

FMGameGrid * FMGameNode::getNeighbor(int row, int col, int direction)
{
    CCPoint coord = getNeighborCoord(row, col, direction);
    int r = coord.x;
    int c = coord.y;
    if (isCoordExist(r, c)) {
        return m_grids[r][c];
    } 
    return NULL;
}

FMGameWall * FMGameNode::getWall(FMGameGrid * grid, int direction)
{
    CCPoint coord = grid->getCoord();
    return getWall(coord.x, coord.y, direction);
}

FMGameWall * FMGameNode::getWall(int row, int col, int direction)
{
    if (direction == kDirection_L ||
        direction == kDirection_R ||
        direction == kDirection_U ||
        direction == kDirection_B ) {
        
    }
    else {
        return NULL;
    }
    
    int mod = (direction == kDirection_L || direction == kDirection_U) ? -1 : 0;
    bool horizon = direction == kDirection_L || direction == kDirection_R;
    int id1, id2, id3;
    if (horizon) {
        id1 = 0;
        id2 = col + mod;
        id3 = row;
    }
    else {
        id1 = 1;
        id2 = row + mod;
        id3 = col;
    }
    if (id2 < 0 || id2 >= kGridNum-1 || id3 < 0 || id3 >= kGridNum) {
        return NULL;
    }
    return m_walls[id1][id2][id3];
}

bool FMGameNode::isDirectionBlocked(int row, int col, int direction)
{
    FMGameGrid * grid = getNeighbor(row, col, direction);
    if (!grid) {
        return true;
    }
    FMGameWall * wall = getWall(row, col, direction);
    if (!wall || wall->getWallType() == kWallNone) {
        return false;
    }
    return true;
}

bool FMGameNode::isDirectionBlocked(FMGameGrid *grid, int direction)
{
    CCPoint coord = grid->getCoord();
    return isDirectionBlocked(coord.x, coord.y, direction);
}

bool FMGameNode::hasRouteToDirection(FMGameGrid *grid, int direction)
{
    bool hasRoute = false;
    if (!grid) {
        return false;
    }
    if (direction == kDirection_C) {
        return true;
    }
    CCPoint coord = grid->getCoord();
    int row = coord.x;
    int col = coord.y;
    switch (direction) {
        case kDirection_B:
        case kDirection_L:
        case kDirection_U:
        case kDirection_R:
        {
            hasRoute |= !isDirectionBlocked(row, col, direction);
        }
            break;
        case kDirection_LB:
        {
            kGameDirection dir1 = kDirection_L;
            kGameDirection dir2 = kDirection_B;
            
            hasRoute |= !(isDirectionBlocked(row, col, dir1) || isDirectionBlocked(getNeighbor(grid, dir1), dir2));
            hasRoute |= !(isDirectionBlocked(row, col, dir2) || isDirectionBlocked(getNeighbor(grid, dir2), dir1));
        }
            break;
        case kDirection_LU:
        {
            kGameDirection dir1 = kDirection_L;
            kGameDirection dir2 = kDirection_U;
            
            hasRoute |= !(isDirectionBlocked(row, col, dir1) || isDirectionBlocked(getNeighbor(grid, dir1), dir2));
            hasRoute |= !(isDirectionBlocked(row, col, dir2) || isDirectionBlocked(getNeighbor(grid, dir2), dir1));
        }
            break;
        case kDirection_RB:
        {
            kGameDirection dir1 = kDirection_R;
            kGameDirection dir2 = kDirection_B;
            
            hasRoute |= !(isDirectionBlocked(row, col, dir1) || isDirectionBlocked(getNeighbor(grid, dir1), dir2));
            hasRoute |= !(isDirectionBlocked(row, col, dir2) || isDirectionBlocked(getNeighbor(grid, dir2), dir1));
        }
            break;
        case kDirection_RU:
        {
            kGameDirection dir1 = kDirection_R;
            kGameDirection dir2 = kDirection_U;
            
            hasRoute |= !(isDirectionBlocked(row, col, dir1) || isDirectionBlocked(getNeighbor(grid, dir1), dir2));
            hasRoute |= !(isDirectionBlocked(row, col, dir2) || isDirectionBlocked(getNeighbor(grid, dir2), dir1));
        }
            break;
        default:
            break;
    }
    return hasRoute;
}

bool FMGameNode::isGridsSwappable(FMGameGrid *grid, kGameDirection direction)
{
    FMGameGrid * targetGrid = getNeighbor(grid, direction);
    if (grid && targetGrid && grid->isSwappable() && targetGrid->isSwappable() && !isDirectionBlocked(grid, direction)) {
        return true;
    }
    return false;
}

bool FMGameNode::isCoordExist(int row, int col)
{
    if (row <0 || col <0 || row>kGridNum-1 || col>kGridNum-1) {
        return false;
    }
    return true;
}

bool FMGameNode::isCoordTouchable(int row, int col)
{
    //tutorials
    int index = row * kGridNum + col;
    if (m_tutCoords.size() != 0) {
        //limit
        if (m_tutCoords.find(index) != m_tutCoords.end()) {
            return true;
        }
        else {
            return false;
        }
    }
    return true;
}

void FMGameNode::markMatchable()
{
    if (FMDataManager::sharedManager()->isTutorialRunning()) {
        return;
    }
    m_matchableGrids.clear();
//    int priority = 2;
//    for (int i=kGridNum-1; i>=0; i--) {
//        for (int j=0; j<kGridNum; j++) {
//            FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
//            priority = getGridMatchPriority(grid, priority);
//        }
//    }

    for (int i=0; i<m_matchableGrids.size(); i++) {
        FMGameGrid * grid = m_matchableGrids.at(i);
        FMGameElement* e = grid->getElement();
        if (e->hasStatus(kStatus_Frozen)) {
            e->playAnimation("FrozenShake");
        }
        else {
            e->playAnimation("Jump");
        }
    }
}

int FMGameNode::getHarvestTypeInMap(int elementType)
{
    bool random = m_targets.find(elementType) == m_targets.end();
    
    if (elementType > kElement_6Pink) {
        random = true;
    }
    
    std::map<int, int> types;
    for (int i=0; i<kGridNum; i++) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * g = getNeighbor(i, j, kDirection_C);
            if (g && !g->isNone()) {
                FMGameElement * e = g->getElement();
                if (e && (e->m_elementFlag & kFlag_Movable) && !e->isMatched()) {
                    kElementType type = e->getElementType();
                    if (m_targets.find(type) != m_targets.end() && type >= kElement_1Red && type <= kElement_6Pink) {
                        if (types.find(type) != types.end()) {
                            types[type]++;
                        }
                        else {
                            types[type] = 1;
                        }
                    }
                }
            }
        }
    }
    
    if (types.find(elementType) == types.end()) {
        //not exist
        random = true;
    }
    
    if (random) { 
        int s = types.size();
        if (s == 0) {
            return kElement_None;
        }
        std::map<int, int>::iterator it = types.begin();
        int r = FMDataManager::getRandom() % s;
        std::advance(it, r);
        int type = it->first;
        return type;
    }
    else {
        return elementType;
    }
}

int FMGameNode::getTypeInMap(int elementType)
{
    //get one element type in the map, target element type is prefered.
    std::map<int, int> types;
    std::set<int> targetTypes;
    kElementType targetType = kElement_None;
    if (elementType >= kElement_1Red && elementType <= kElement_6Pink) {
        targetType = (kElementType)elementType;
    }

    for (int i=0; i<kGridNum; i++) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * g = getNeighbor(i, j, kDirection_C);
            if (g && !g->isNone()) {
                FMGameElement * e = g->getElement();
                if (e && (e->m_elementFlag & kFlag_Movable) && !e->isMatched()) {
                    kElementType type = e->getElementType();
                    if (type == targetType) {
                        return targetType;
                    }
//                    if (type >= kElement_1Red && type <= kElement_6PinkBad) {
//                        if (types.find(type) != types.end()) {
//                            types[type]++;
//                        }
//                        else {
//                            types[type] = 1;
//                        }
//                    }
                }
            }
        }
    }
    
    return kElement_None;
    
    if (types.find(elementType) != types.end()) {
        //exist
        return elementType;
    }
    else {
        return kElement_None;
//        //pick random type from exists 
//        int s = types.size();
//        if (s == 0) {
//            return kElement_None;
//        }
//        std::map<int, int>::iterator it = types.begin();
//        int r = FMDataManager::getRandom() % s;
//        std::advance(it, r);
//        int type = it->first;
//        return type;
    }
    
//    if (targetTypes.size() != 0) {
//        //use target types
//        int s = targetTypes.size();
//        std::set<int>::iterator it = targetTypes.begin();
//        int r = FMDataManager::getRandom() % s;
//        std::advance(it, r);
//        int type = *it;
//        return type;
//    }
//    else {
//        //use random type
//        int s = types.size();
//        std::map<int, int>::iterator it = types.begin();
//        int r = FMDataManager::getRandom() % s;
//        std::advance(it, r);
//        int type = it->first;
//        return type;
//    }
    
}

#pragma mark - swap
static float swapTime = 0.125f;
void FMGameNode::swapElements(FMGameGrid *g1, FMGameGrid *g2)
{
    FMSound::playEffect("change.mp3");
    m_swapBegin = true;
    showIndicator(false);
    FMGameElement * e1 = g1->getElement();
    FMGameElement * e2 = g2->getElement();
    if (e1 == NULL || e2 == NULL) {
        return;
    }
    m_swapGrid1 = g1;
    m_swapGrid2 = g2;
    m_swapGrid1->setOccupyElement(e2);
    m_swapGrid2->setOccupyElement(e1);
    {
        e1->getAnimNode()->setZOrder(50);
        CCMoveTo * m = CCMoveTo::create(swapTime * 2.f, g2->getPosition());
        CCEaseOut * ease = CCEaseOut::create(m, 1.2f);
        CCScaleTo * s1 = CCScaleTo::create(swapTime, 1.3f);
        CCScaleTo * s2 = CCScaleTo::create(swapTime, 1.f);
        CCSequence * seq1 = CCSequence::create(s1,s2,NULL);
        CCSpawn * spawn = CCSpawn::create(ease, seq1, NULL);
        CCCallFunc * c = CCCallFunc::create(this, callfunc_selector(FMGameNode::callbackSwapDone));
        CCSequence * s = CCSequence::create(spawn, c, NULL);
        e1->getAnimNode()->runAction(s);
    }
    
    {
        e2->getAnimNode()->setZOrder(49);
        CCMoveTo * m = CCMoveTo::create(swapTime * 2.f, g1->getPosition());
        CCEaseOut * ease = CCEaseOut::create(m, 1.2f);
        CCScaleTo * s1 = CCScaleTo::create(swapTime, 0.7f);
        CCScaleTo * s2 = CCScaleTo::create(swapTime, 1.f);
        CCSequence * seq1 = CCSequence::create(s1,s2,NULL);
        CCSpawn * spawn = CCSpawn::create(ease, seq1, NULL);
        e2->getAnimNode()->runAction(spawn);
    } 

}

void FMGameNode::callbackSwapDone()
{
    if (m_swapGrid1 == NULL || m_swapGrid2 == NULL) {
        m_swapGrid1 = NULL;
        m_swapGrid2 = NULL;
        
        m_swapBegin = false;
        m_touchBegin = false;
        
        return;
    }
    
    bool willSwap = false;
    bool matched = checkMatch();
    willSwap = matched;
#ifdef DEBUG
    if (!matched && m_cheatMode) {
        willSwap = true;
        setCheated(true);
    }
#endif
    if (willSwap) {
        FMDataManager * manager = FMDataManager::sharedManager();
        if (manager->isTutorialRunning()) {
            manager->tutorialPhaseDone();
        }
        pause();
        if (!manager->isNeedFailCount()) {
            if (manager->getUnlimitLifeTime() < manager->getCurrentTime()) {
                manager->setNeedFailCount();
            }
        }
        m_harvestedInMove = 0;
        m_leftMoves--;
        m_usedMoves++;

        updateMoves(); 
        
        FMGameElement * e1 = m_swapGrid1->getElement();
        FMGameElement * e2 = m_swapGrid2->getElement();

        e1->setZOrder((m_swapGrid1->getCoord().x+1) * 5);
        e2->setZOrder((m_swapGrid2->getCoord().x+1) * 5);
        
        
        m_swapBegin = false;
        m_touchBegin = false;
        cleanMatchFlag();
        beforeMatch();
//        beginMatch();
        
    }
    else {
        //swap back
        FMSound::playEffect("wrongmove.mp3");
        FMGameElement * e1 = m_swapGrid1->getElement();
        FMGameElement * e2 = m_swapGrid2->getElement(); 
        m_swapGrid1->setOccupyElement(e2);
        m_swapGrid2->setOccupyElement(e1);
        {
            e1->setZOrder(49);
            CCMoveTo * m = CCMoveTo::create(swapTime * 2.f, m_swapGrid2->getPosition());
            CCEaseOut * ease = CCEaseOut::create(m, 1.2f);
            CCScaleTo * s1 = CCScaleTo::create(swapTime, 0.7f);
            CCScaleTo * s2 = CCScaleTo::create(swapTime, 1.f);
            CCSequence * seq1 = CCSequence::create(s1,s2,NULL);
            CCSpawn * spawn = CCSpawn::create(ease, seq1, NULL);
            CCCallFunc * c = CCCallFunc::create(this, callfunc_selector(FMGameNode::callbackSwapBack));
            CCSequence * s = CCSequence::create(spawn, c, NULL);
            e1->getAnimNode()->runAction(s);
        }
        
        {
            e2->setZOrder(50);
            CCMoveTo * m = CCMoveTo::create(swapTime * 2.f, m_swapGrid1->getPosition());
            CCEaseOut * ease = CCEaseOut::create(m, 1.2f);
            CCScaleTo * s1 = CCScaleTo::create(swapTime, 1.3f);
            CCScaleTo * s2 = CCScaleTo::create(swapTime, 1.f);
            CCSequence * seq1 = CCSequence::create(s1,s2,NULL);
            CCSpawn * spawn = CCSpawn::create(ease, seq1, NULL);
            e2->getAnimNode()->runAction(spawn);
        }
    }
}

void FMGameNode::callbackSwapBack()
{
    if (m_swapGrid1 && m_swapGrid2) {
        FMGameElement * e1 = m_swapGrid1->getElement();
        FMGameElement * e2 = m_swapGrid2->getElement();
        
        e1->setZOrder((m_swapGrid1->getCoord().x+1) * 5);
        e2->setZOrder((m_swapGrid2->getCoord().x+1) * 5);
    }
    
    m_swapGrid1 = NULL;
    m_swapGrid2 = NULL;
    
    m_swapBegin = false;
    m_touchBegin = false;
}

#pragma mark - combo
void FMGameNode::addCombo()
{
    m_combo++;
//    int v = m_combo - 1;
//    if (v > 6) {
//        v = 6;
//    }
//    CCString * str = CCString::createWithFormat("combo_%02d.mp3", v);
//    FMSound::playEffect(str->getCString());
}

#pragma mark - helper
CCPoint FMGameNode::getPositionForCoord(float row, float col)
{
    return ccp(col * kGridWidth, - row * kGridHeight);
}

CCPoint FMGameNode::getWorldPositionForCoord(float row, float col)
{
    CCNode * offsetNode = m_gridParent->getChildByTag(1);
    CCPoint wp = offsetNode->convertToWorldSpace(getPositionForCoord(row, col));
    return wp;
}

CCPoint FMGameNode::getPositionForGrid(FMGameGrid *grid)
{
    CCPoint coord=  grid->getCoord();
    return getPositionForCoord(coord.x, coord.y);
}

int FMGameNode::createNewMatchGroup()
{
    int gid = 0;
    std::map<int, FMMatchGroup * >::iterator it = m_matchedGroups.find(gid);
    while (it != m_matchedGroups.end()) {
        gid++;
        it = m_matchedGroups.find(gid);
    }
    return gid;
}

void FMGameNode::addMovingElement(FMGameElement *element)
{
    if (m_movingElements.find(element) == m_movingElements.end()) {
//        element->DelayMove(m_movingElements.size() * 0.018f);
        m_movingElements.insert(element);
    }
}

bool FMGameNode::isGridMatchColor(FMGameGrid *grid, int color)
{
    if (grid && !grid->isEmpty() && grid->getElement()->getMatchColor() == color && color != -1) {
        return true;
    }
    return false;
}

void FMGameNode::showIndicator(bool show, int row, int col, int row2, int col2)
{
    row2 = row2 == -1 ? row : row2;
    col2 = col2 == -1 ? col : col2;
    row2 = abs(row2 - row);
    col2 = abs(col2 - col);
    for (int i=0; i<4; i++) {
        int r = i / 2 == 1 ? 1 : 0;
        int c = i % 2 == 1 ? 1 : 0;
        r = row2 * r;
        c = col2 * c;
        m_indicator[i]->setVisible(show);
        m_indicator[i]->pauseAnimation(!show);
        m_indicator[i]->setPosition(getPositionForCoord(row + r, col + c));
    }
    


}

//void FMGameNode::makeGridSurprise(bool s, int row, int col)
//{
//    if (row ==-1 || col ==-1) {
//        if (m_currentSelection) {
//            FMGameElement * e = m_currentSelection->getElement();
//            if (e) {
//                e->makeNormal();
//            }
//        }
//        m_currentSelection = NULL;
//        return;
//    }
//    
//    FMGameGrid * oldGrid = m_currentSelection;
//    FMGameGrid * newGrid = getNeighbor(row, col, kDirection_C);
//    if (oldGrid && oldGrid == newGrid) {
//        return;
//    }
//    
//    if (s) {
//        if (m_currentSelection) {
//            FMGameElement * e = m_currentSelection->getElement();
//            if (e) {
//                e->makeNormal();
//            }
//        }
//        m_currentSelection = newGrid;
//        if (m_currentSelection) {
//            FMGameElement * e = m_currentSelection->getElement();
//            if (e) {
//                e->makeSurprise();
//            }
//        }
//    }
//    else {
//        if (m_currentSelection) {
//            FMGameElement * e = m_currentSelection->getElement();
//            if (e) {
//                e->makeNormal();
//            }
//        }
//        m_currentSelection = NULL;
//    }
//}


void FMGameNode::triggerAddValueToSpecailTarget(kElementType type)
{
    if (m_targets.find(type) != m_targets.end()) {
        elementTarget & et = m_targets[type];
        
        switch (m_gameMode) {
            case kGameMode_Classic:
            {
                bool check = false;
                if (et.harvested < et.target) {
                    check = true;
                }
                et.harvested += 1;
                if (check && et.harvested >= et.target) {
                    //satisfied this target
                    
                    CCNode * parent = m_modeNode[m_gameMode]->getChildByTag(et.index);
                    NEAnimNode * checkedAnim = (NEAnimNode *)parent->getChildByTag(3);
                    checkedAnim->playAnimation("Checked");
                    
                    FMSound::playEffect("gainsdone.mp3");
                }
//                NEAnimNode * anim = (NEAnimNode *)m_targetAnimNode[et.index]->getNodeByName("Element");
//                anim->playAnimation("TargetHarvest");
                
            }
                break;
            case kGameMode_Harvest:
            {
                int totalHarvested = 0;
                int totalTarget = 0;
                for (std::map<int, elementTarget>::iterator it = m_targets.begin(); it != m_targets.end(); it++) {
                    elementTarget & t = it->second;
                    totalHarvested += t.harvested;
                    totalTarget += t.target;
                }
                
                et.harvested += 1;
                CCNode * modeNode = m_modeNode[kGameMode_Harvest];
                NEAnimNode * animTarget = (NEAnimNode *)modeNode->getChildByTag(type-1);
//                NEAnimNode * anim = (NEAnimNode *)animTarget->getNodeByName("Element");
//                anim->playAnimation("TargetHarvest");
                
                if (totalHarvested < totalTarget) {
                    //check
                    if (totalHarvested + 1 >= totalTarget) {
                        NEAnimNode * checkedAnim = (NEAnimNode *)m_modeNode[kGameMode_Harvest]->getChildByTag(20);
                        checkedAnim->playAnimation("Checked");
                        
                        FMSound::playEffect("gainsdone.mp3");
                    }
                }
                
            }
                break;
            default:
                break;
        }
        
        
        //update ui
        updateHarvestTargets();
        FMSound::playEffect("gains.mp3");
    }
    
    checkTargetComplete();
}

void FMGameNode::triggerAddValueToTarget(FMGameElement * element)
{
    kElementType type = element->getElementType();
    
    if (m_targets.find(type) != m_targets.end()) {
        int value = 1;
        elementTarget & et = m_targets[type];
        
        switch (m_gameMode) {
            case kGameMode_Classic:
            {
                bool check = false;
                if (et.harvested < et.target) {
                    check = true;
                }
                et.harvested += value + 1;
                if (check && et.harvested >= et.target) {
                    //satisfied this target
                    
                    CCNode * parent = m_modeNode[m_gameMode]->getChildByTag(et.index);
                    NEAnimNode * checkedAnim = (NEAnimNode *)parent->getChildByTag(3);
                    checkedAnim->playAnimation("Checked");
                    
                    FMSound::playEffect("gainsdone.mp3");
                }
                NEAnimNode * anim = (NEAnimNode *)m_targetAnimNode[et.index]->getNodeByName("Element");
                anim->playAnimation("TargetHarvest");
                
            }
                break;
            case kGameMode_Harvest:
            {
                int totalHarvested = 0;
                int totalTarget = 0;
                for (std::map<int, elementTarget>::iterator it = m_targets.begin(); it != m_targets.end(); it++) {
                    elementTarget & t = it->second;
                    totalHarvested += t.harvested;
                    totalTarget += t.target;
                }
                
                et.harvested += value + 1;
                CCNode * modeNode = m_modeNode[kGameMode_Harvest];
                NEAnimNode * animTarget = (NEAnimNode *)modeNode->getChildByTag(type-1);
                NEAnimNode * anim = (NEAnimNode *)animTarget->getNodeByName("Element");
                anim->playAnimation("TargetHarvest");
                
                if (totalHarvested < totalTarget) {
                    //check
                    if (totalHarvested + value + 1 >= totalTarget) {
                        NEAnimNode * checkedAnim = (NEAnimNode *)m_modeNode[kGameMode_Harvest]->getChildByTag(20);
                        checkedAnim->playAnimation("Checked");
                        
                        FMSound::playEffect("gainsdone.mp3");
                    }
                }
                
            }
                break;
            default:
                break;
        }

        
        //update ui
        updateHarvestTargets();
        FMSound::playEffect("gains.mp3");
    }
    
    removeElement(element);
    
    checkTargetComplete();
}
//
//void FMGameNode::triggerHarvest(FMGameElement * element)
//{
//    kElementType type = element->getElementType();
//    if (m_targets.find(type) != m_targets.end()) {
//        m_harvestCrowds->playAnimation("Grow");
//        
//        int totalHarvested = 0;
//        int totalTarget = 0;
//        for (std::map<int, elementTarget>::iterator it = m_targets.begin(); it != m_targets.end(); it++) {
//            elementTarget & t = it->second;
//            totalHarvested += t.harvested;
//            totalTarget += t.target;
//        }
//        
//        bool check = totalHarvested < totalTarget;
//        int value = element->getValue();
//        elementTarget & et = m_targets[type];
//        et.harvested += value + 1;
//        
//        if (check) {
//            if (totalHarvested + value + 1 >= totalTarget) {
//                //bingo
//                NEAnimNode * checkedAnim = (NEAnimNode *)m_vegeMode->getChildByTag(3)->getChildByTag(1);
//                checkedAnim->playAnimation("Checked");
//                FMSound::playEffect("gainsdone.mp3");
//            }
//        }
//
//        //update ui
//        updateHarvestTargets();
//        FMSound::playEffect("gains.mp3");
//    }
//    
//    removeElement(element);
//}
//
//void FMGameNode::triggerHitBoss(FMGameElement *element)
//{
//    kElementType type = element->getElementType();
//    m_bossHurtTurn = true;
//    if (m_targets.find(type) != m_targets.end()) {
//        int value = element->getValue();
//        elementTarget & et = m_targets[type]; 
//        et.harvested += value + 1;
//        NEAnimNode * boss = (NEAnimNode *)m_bossGround[m_bossIndex]->getNodeByName("1");
//        boss->setDelegate(this);
//        boss->playAnimation("Hit");
//        NEAnimNode * anim = (NEAnimNode *)m_targetAnimNode[et.index]->getNodeByName("Element");
//        anim->playAnimation("TargetHarvest");
//        
//        //update ui
//        updateHarvestTargets();
//        FMSound::playEffect("hitboss.mp3", 0.5f, 0.05f);
//    }
//}

void FMGameNode::triggerHitDone(FMGameElement *element)
{ 
    removeElement(element);
}

//void FMGameNode::triggerGetSnail(FMGameElement *element)
//{
//    kElementType type = kElement_Snail;
//    if (m_targets.find(type) != m_targets.end()) {
//        int value = element->getValue();
//        elementTarget & et = m_targets[type];
//        bool check = false;
//        if (et.harvested < et.target) {
//            check = true;
//        }
//        et.harvested += value + 1;
//        if (m_gameMode == kGameMode_Classic && check && et.harvested >= et.target) {
//            //satisfied this target
//            
//            CCNode * parent = m_modeNode[kGameMode_Classic]->getChildByTag(et.index);
//            NEAnimNode * checkedAnim = (NEAnimNode *)parent->getChildByTag(3);
//            checkedAnim->playAnimation("Checked");
//            
//            FMSound::playEffect("gainsdone.mp3");
//        }
//        NEAnimNode * anim = (NEAnimNode *)m_targetAnimNode[et.index]->getNodeByName("Element");
//        anim->playAnimation("TargetHarvest");
//        
//        //update ui
//        updateHarvestTargets();
//        FMSound::playEffect("gains.mp3");
//    }
//
//    if (element && element->isSnailOn()) {
//        element->destroySnailAnim();
//        element->setDisabled(false);
//    }
//}

std::set<FMGameGrid*> FMGameNode::getGridsAroundMatchGroup(FMMatchGroup *mg)
{
    std::set<FMGameGrid *> addValueGrids;
    for (std::set<FMGameGrid*>::iterator it = mg->m_grids->begin(); it!= mg->m_grids->end(); it++) {
        FMGameGrid * g = *it;
        FMGameGrid * neighbor = getNeighbor(g, kDirection_U);
        if (neighbor && neighbor->getElement() && neighbor->getElement()->m_matchGroup == -1) {
            if (addValueGrids.find(neighbor) == addValueGrids.end()) {
                addValueGrids.insert(neighbor);
            }
        }
        neighbor = getNeighbor(g, kDirection_B);
        if (neighbor && neighbor->getElement() && neighbor->getElement()->m_matchGroup == -1) {
            if (addValueGrids.find(neighbor) == addValueGrids.end()) {
                addValueGrids.insert(neighbor);
            }
        }
        neighbor = getNeighbor(g, kDirection_L);
        if (neighbor  && neighbor->getElement() && neighbor->getElement()->m_matchGroup == -1) {
            if (addValueGrids.find(neighbor) == addValueGrids.end()) {
                addValueGrids.insert(neighbor);
            }
        }
        neighbor = getNeighbor(g, kDirection_R);
        if (neighbor && neighbor->getElement() && neighbor->getElement()->m_matchGroup == -1) {
            if (addValueGrids.find(neighbor) == addValueGrids.end()) {
                addValueGrids.insert(neighbor);
            }
        }
    }
    return addValueGrids;
}

void FMGameNode::creatElementType(FMGameGrid * grid)
{
    kElementType type = grid->getElementType();
    if (type == kElement_None) {
        return;
    }
    if (grid->isEmpty()) {
        FMGameElement * ele = createNewElement(type);
        ele->getAnimNode()->setPosition(grid->getPosition());
        grid->setOccupyElement(ele);
    }else{
        FMGameElement * element = grid->getElement();
        element->setElementType(type);
        element->getAnimNode()->setDelegate(NULL);
        element->playAnimation("Bounce");
    }
    grid->setElementType(kElement_None);
}

void FMGameNode::removeBadSeed(int seed)
{
    CCArray * seeds = (CCArray *)m_levelData->objectForKey("seeds");
    if (seeds) {
        int count = seeds->count();
        for (int i=0; i<count; i++) {
            CCNumber * n = (CCNumber *)seeds->objectAtIndex(i);
            if (n->getIntValue() == seed) {
                seeds->removeObjectAtIndex(i);
                return;
            }
        }
    }
}

void FMGameNode::onEnter()
{
    SNSFunction_setPopupStatus(false);
    GAMEUI::onEnter();
    scheduleUpdate();
}

void FMGameNode::onExit()
{
    GAMEUI::onExit();
    unscheduleUpdate();
}

#pragma mark - function per frame

void FMGameNode::update(float delta)
{
#ifdef DEBUG
    if (m_isEditorMode) {
        return;
    }
#endif
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    if(forground){
        setGameBG();
        forground = false;
    }
#endif
    if (m_gameEnd) {
        return;
    }
    updateScorebar(delta);
    updateBoostersTimer(delta);
    switch (m_phase) {
        case kPhase_WaitInput:
        {
            m_thinkingTime += delta;
            if (m_thinkingTime > tipTimePeriod) {
                markMatchable();
                m_thinkingTime = 0.f;
            }
            
            m_idleTime += delta;
            if (m_idleTime > idleTimePeriod) {
                playIdleAnim();
                m_idleTime = 0.f;
            }
        }
            break;
        case kPhase_Falling:
        {
            for (int i=0; i<m_spawner.size(); i++) {
                FMGameGrid * grid = m_spawner[i];
                grid->update(delta);
            }
            bool needCheckFalling = false;
            if (m_movingElements.size() > 0) {
                std::vector<FMGameElement *> deleted;
                for (std::set<FMGameElement *>::iterator it = m_movingElements.begin(); it!=m_movingElements.end(); it++) {
                    FMGameElement * e = *it;
                    int moveResult = e->updateMoving(delta);
                    if (e->isMoveDone()) {
                        e->playAnimation("Bounce");
                        FMSound::playEffect("step.mp3", 0.1f, 0.1f);
                        deleted.push_back(e);
                    }
                    if (moveResult == 1){
                        needCheckFalling = true;
                    }
                }
                
                for (int i=0; i<deleted.size(); i++) {
                    FMGameElement * e = deleted[i];
                    std::set<FMGameElement *>::iterator it = m_movingElements.find(e);
                    m_movingElements.erase(it);
                }
                
            }
            
            if (needCheckFalling) {
//                checkFalling();
            }
            
            
            if (m_movingElements.size() == 0) {
                //move done, clean all spawner grids queue (bug 1)
                for (int i=0; i<m_spawner.size(); i++) {
                    FMGameGrid * grid = m_spawner[i];
                    grid->cleanSpawnQueue();
                }
                beforeMatch();
            }

        }
            break;
        case kPhase_AI:
        {
            if (m_animChecker->isAnimationDone()) { 
                if (!m_animChecker->isMatchEnd()) {}
                else {
                    beginFalling();
                } 
            }
        }
            break;
        case kPhase_BeforeMatch:
        {
            int matchEnded = 0;
            for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it != m_matchedGroups.end(); it++ ) {
                FMMatchGroup * mg = it->second;
                if (mg->isAnimationDone()) {
                    matchEnded++;
                }
            }
            if (matchEnded == m_matchedGroups.size() && m_animChecker->isAnimationDone()) {
                for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it!= m_matchedGroups.end(); it++) {
                    FMMatchGroup * mg = it->second;
                    delete mg;
                }
                m_matchedGroups.clear();

                bool haveMatch = checkMatch();
                bool gridsStable = checkGridsStable();
                if (haveMatch || !gridsStable)
                {
                    addCombo();
                    beginMatch();
                }
                else {
                    
//                    //check ai
//                    if (!m_aiChecked) {
//                        checkAI();
//                        break;
//                    }
                    checkTargetComplete();
                    
                    if (m_maniaMode) {
                        beforeNewTurn();
                        break;
                    }
    
                    
                    if (m_targetsCompleted || checkMatchable()) {
                        if (m_gameMode == kGameMode_Boss) {
                            //switch a new hole
                            if (m_bossHurtTurn) {
                                m_bossHurtTurn = false;
                                m_bossGround[m_bossIndex]->setDelegate(this);
                                m_bossGround[m_bossIndex]->playAnimation("Run");
                            }
                        }
                        beforeNewTurn();
                    }
                    else {
                        CCLOG("No Match");
                        setGamePhase(kPhase_NoInput);
                        FMUIGreenPanel * panel = (FMUIGreenPanel *)m_greenPanel;
                        panel->setClassState(kPanelShuffle);
                        panel->setVisible(true); 
                        
                        //make surprise
                        for (int i=0; i<kGridNum; i++) {
                            for (int j=0; j<kGridNum; j++) {
                                FMGameGrid * g = getNeighbor(i, j, kDirection_C);
                                if (g->isExistMovableElement()) {
                                    FMGameElement * e = g->getElement();
                                    e->makeSurprise();
                                }
                            }
                        }
                    }
                }

            }
        }
            break;
        case kPhase_BeforeNewTurn:
        {
            if (m_animChecker->isAnimationDone()) {
                if (m_maniaModeBegin) {
                    if (m_maniaMode) {
                        maniaPlusOne();
                    }
                }
                else {
//                    if (m_harvestedInMove >= 8) {
//                        setGamePhase(kPhase_NoInput);
//                        FMUIGreenPanel * panel = (FMUIGreenPanel *)m_greenPanel;
//                        panel->setHarvestNumber(m_harvestedInMove);
//                        panel->setVisible(true);
//                        
//                        m_harvestedInMove = -1;
//                        return;
//                    }else{
//                        m_harvestedInMove = -1;
//                    }
                    if (m_soundEffectCombo >= 3) {
                        FMUIGreenPanel * panel = (FMUIGreenPanel *)m_greenPanel;
                        panel->setHarvestNumber(m_soundEffectCombo);
                        panel->setVisible(true);
                    }
                    m_soundEffectCombo = 0;
                    
                    if (m_leftMoves == 5) {
                        setGamePhase(kPhase_NoInput);
                        FMUIGreenPanel * panel = (FMUIGreenPanel *)m_greenPanel;
                        panel->setClassState(kPanel5MovesLeft);
                        panel->setVisible(true);

                        NEAnimNode * fiveMoveNode = (NEAnimNode *)m_moveNode->getChildByTag(0);
                        fiveMoveNode->playAnimation("Animation0");

//                        return;
                    }
                    setGamePhase(kPhase_WaitInput);
                    if (!m_gameEnd) {
                        resume();
                        FMDataManager * manager = FMDataManager::sharedManager();
                        manager->checkStableTrigger();
                    }
                }
            }
        }
            break;
        case kPhase_CheckTriggers:
        {
            int matchEnded = 0;
            for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it != m_matchedGroups.end(); it++ ) {
                FMMatchGroup * mg = it->second;
                if (mg->isAnimationDone(false)) {
                    matchEnded++;
                }
            }
            if (m_matchedGroups.size() == matchEnded) {
                //all match effects are done, move to harvest
                beginHarvest();
            }
        }
            break;
        case kPhase_Harvest:
        { 
            bool matchEnded = false;
            
            
            for (std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin(); it != m_matchedGroups.end(); it++ ) {
//            if (m_matchedGroups.size() > m_matchedGroupsIndex) {
//                std::map<int, FMMatchGroup *>::iterator it = m_matchedGroups.begin();
//                std::advance(it, m_matchedGroupsIndex);
                FMMatchGroup * mg = it->second;
                if (mg->isAnimationDone(false)) {
                    if (!mg->isMatchEnd()) {

                        mg->setMatchEnd(true);

                    }
                }
                if (mg->isMatchEnd()) {
                    matchEnded = true;
                }
            }
            if (m_matchedGroups.size() == 0){
                matchEnded = true;
            }
            
            
            
            if (matchEnded && m_animChecker->isAnimationDone(false)) {
                //all match effects are done, move to harvest
//                m_matchedGroupsIndex++;
//                if (m_matchedGroups.size() > m_matchedGroupsIndex) {
//                    beginMatch();
//                }else{
                    beginFalling();
//                }
            }
        }
            break;
        case kPhase_ItemUsing:
        {
            if (m_animChecker->isAnimationDone()) {
                switch (m_usingItem) {
                    case kBooster_PlusOne:
                    case kBooster_CureRot:
                    {
                        setGamePhase(kPhase_WaitInput);
                        m_usingItem = kBooster_None;
                    }
                        break;
                    case kBooster_Shuffle:
                    {
                        m_animChecker->setMatchEnd(true);
                        m_animChecker->cleanGrids();
                        //end
                        useItemMode(false);
                        useItem((kGameBooster)m_usingItem);
                        m_usingItem = kBooster_None;

                        beforeMatch();
                    }
                        break;
                    case kBooster_Harvest1Grid:
                    {
                        if (!m_animChecker->isMatchEnd()) {
                            FMGameGrid * g = m_animChecker->m_grid;
                            FMGameElement * e = g->getElement();
                            kElementType t = e->getElementType();
           
                            if (e->hasStatus(kStatus_Frozen)) {
                                //remove the ice
                                
                                e->removeStatus(kStatus_Frozen);
//                                triggerAddValueToSpecailTarget(kElement_TargetIce);
                                m_animChecker->setMatchEnd(true);
                                m_animChecker->resetPhase();
                            }
                            else {
                                m_animChecker->setMatchEnd(true);
                                m_animChecker->resetPhase();
                            
                                gridNextPhase(m_animChecker, m_animChecker->m_grid);
                            }
                        }
                        
                        if (m_animChecker->isMatchEnd()) {
                            m_animChecker->resetPhase();
                            m_animChecker->cleanGrids();
                            FMMatchGroup * mg = m_animChecker;
                            if (mg->isAnimationDone()) {
                                //end
                                useItemMode(false);

                                useItem((kGameBooster)m_usingItem);
                                m_usingItem = kBooster_None;
                                
                                for (int i=0; i<6; i++) {
                                    CCAnimButton * boosterButton = (CCAnimButton *)m_boosterParent->getChildByTag(i)->getChildByTag(1);
                                    NEAnimNode * boosterIcon = (NEAnimNode *)boosterButton->getAnimNode()->getNodeByName("Booster");
                                    boosterIcon->playAnimation("Init");
                                }
                                
                                beginFalling();
                                break;
                            }
                        }

                    }
                        break;
                    case kBooster_Harvest1Type:
                    {
                        if (m_animChecker->isAnimationDone()) { 
                            m_animChecker->setMatchEnd(true);
                            m_animChecker->cleanGrids();
                            //end
                            useItemMode(false);
                            useItem((kGameBooster)m_usingItem);
                            m_usingItem = kBooster_None;
                            
                            
                            for (int i=0; i<6; i++) {
                                CCAnimButton * boosterButton = (CCAnimButton *)m_boosterParent->getChildByTag(i)->getChildByTag(1);
                                NEAnimNode * boosterIcon = (NEAnimNode *)boosterButton->getAnimNode()->getNodeByName("Booster");
                                boosterIcon->playAnimation("Init");
                            }
                            
                            
                            beginFalling();
                        }
                        
                    }
                        break;
                    case kBooster_Harvest1Row:
                    {
                        m_animChecker->setMatchEnd(true);
                        m_animChecker->cleanGrids();
                        //end
                        useItemMode(false);
                        useItem((kGameBooster)m_usingItem);
                        m_usingItem = kBooster_None;
                        
                        
                        for (int i=0; i<6; i++) {
                            CCAnimButton * boosterButton = (CCAnimButton *)m_boosterParent->getChildByTag(i)->getChildByTag(1);
                            NEAnimNode * boosterIcon = (NEAnimNode *)boosterButton->getAnimNode()->getNodeByName("Booster");
                            boosterIcon->playAnimation("Init");
                        }
                        
                        beginFalling();
                    }
                        break;
                    default:
                        break;
                }
                
            }
        }
            break;
//        case kPhase_HeroFlying:
//        {
//            
//            int phase = m_animChecker->getPhase();
//            if (m_animChecker->isAnimationDone()) {
//                int count = 5;
//                //get available columns
//                std::map<int, std::set<int> > coords;
//                std::set<int> cols;
//                for (int i=0; i<kGridNum; i++) {
//                    for (int j=0; j<kGridNum; j++) {
//                        FMGameGrid * g = getNeighbor(j, i, kDirection_C);
//                        if (!g->isNone()) {
//                            CCPoint p = g->getCoord();
//                            if (cols.find((int)p.y) == cols.end()) {
//                                cols.insert((int)p.y);
//                            }
//
//                            std::set<int> & sets = coords[(int)p.y];
//                            sets.insert((int)p.x);
//                        }
//                    }
//                }
//                std::set<int> usedCols = cols;
//                while (1) {
//                    bool useMove = maniaUseMove();
//                    if (!useMove) {
//                        m_animChecker->resetPhase();
//                        m_animChecker->cleanGrids();
//                        m_animChecker->setMatchEnd(true);
////                        cleanValueAdd();
//                        beginFalling();
//                        break;
//                    }
//                    count--;
//                    if (usedCols.size() == 0) {
//                        usedCols = cols;
//                    }
//                    int r = FMDataManager::getRandom() % usedCols.size();
//                    std::set<int>::iterator it = usedCols.begin();
//                    std::advance(it, r);
//                    int col = *it;
//                    usedCols.erase(it);
//                    std::set<int> &rows = coords[col];
//                    r = FMDataManager::getRandom() % rows.size();
//                    it = rows.begin();
//                    std::advance(it, r);
//                    int row = *it;
//                    
//                    FMGameGrid * g = getNeighbor(row, col, kDirection_C);
//                    if (g->isNone()) {
//                        CCAssert(0, "error to get a grid");
//                    }
//                    
//                   
//                    CCParticleSystemQuad * particleTrail = CCParticleSystemQuad::create("particle_fireworktrail.plist");
//                    
//                    int randomfirework = FMDataManager::getRandom() % 4;
//                    CCString * file = CCString::createWithFormat("particle_firework%d.plist", randomfirework + 1);
//                    CCParticleSystemQuad * particleFirework = CCParticleSystemQuad::create(file->getCString());
//      
//                    particleTrail->resetSystem();
//                    particleFirework->stopSystem();
//                    particleFirework->setAutoRemoveOnFinish(true);
//                    
//                    CCNode * offsetNode = m_gridParent->getChildByTag(1);
//                    offsetNode->addChild(particleTrail, 100);
//                    offsetNode->addChild(particleFirework, 100);
//                    
//                    CCPoint from = getPositionForCoord(8.5f, col);
//                    CCPoint to = g->getPosition();
//                    
//                    particleTrail->setPosition(from);
//                    particleTrail->setSourcePosition(CCPointZero);
//                    particleFirework->setPosition(to);
//                    particleFirework->setSourcePosition(CCPointZero);
//                    
//                    float distance = ccpDistance(to, from);
//                    float flyTime = distance * 0.0025f + (FMDataManager::getRandom() % 3) * 0.05f;
//                    
//                    //trail
//                    CCMoveTo * a1 = CCMoveTo::create(flyTime, to);
//                    CCCallFuncO * a2 = CCCallFuncO::create(this, callfuncO_selector(FMGameNode::triggerGridBonus), g);
//                    CCCallFunc * a3 = CCCallFunc::create(particleTrail, callfunc_selector(CCNode::removeFromParent));
//                    CCSequence * a4 = CCSequence::create(a1, a2, a3, NULL); 
//                    m_animChecker->addCCNode(particleTrail, a4, "cc flag 19");
//                    const char * effect = FMSound::getRandomEffect("fireworksfly_01.mp3", "fireworksfly_02.mp3", NULL);
//                    FMSound::playEffect(effect, 0.1f, 0.05f);
//                    
//                    //firework
//                    effect = FMSound::getRandomEffect("fireworksboom_01.mp3", "fireworksboom_02.mp3", "fireworksboom_03.mp3", NULL);
//                    CCString * str = CCString::create(effect);
//                    CCDelayTime * b1 = CCDelayTime::create(flyTime);
//                    CCCallFunc * b2 = CCCallFunc::create(particleFirework, callfunc_selector(CCParticleSystemQuad::resetSystem));
//                    CCCallFuncO * b3 = CCCallFuncO::create(FMSound::manager(), callfuncO_selector(FMSound::playEffectC), str);
//                    CCSequence * b4 = CCSequence::create(b1, b2, b3, NULL);
//                    particleFirework->runAction(b4);                    
//                    
//                    if (count == 0) {
//                        m_animChecker->resetPhase();
//                        m_animChecker->cleanGrids();
//                        m_animChecker->setMatchEnd(true);
////                        cleanValueAdd();
//                        beginFalling();
//                        break;
//                    }
//                }
//            }
//            
//        }
//            break;
        case kPhase_Shuffling:
        {
            if (m_animChecker->isAnimationDone()) {
                //shuffle done
//                setGamePhase(kPhase_WaitInput);
//                resume();
//                beforeNewTurn();
                beforeMatch();
            }
        }
            break;
        default:
            break;
    }
}



#pragma mark - CCB Bindings
bool FMGameNode::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_colorLayer", CCLayerColor *, m_colorLayer);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_gameBG", CCSprite *, m_gameBG);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_centerNode", CCNode *, m_centerNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_modeParent", CCNode *, m_modeParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_levelStatus", CCNode *, m_levelStatus);
//    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_scorebarParent", CCNode *, m_scorebarParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_scoreLabel", CCLabelBMFont *, m_scoreLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_boosterParent", CCNode *, m_boosterParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_boosterUseParent", CCNode *, m_boosterUseParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_closeButton", CCControlButton *, m_closeButton);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_moveNode", CCNode *, m_moveNode);
//    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_mysticBox", CCSprite *, m_mysticBox);
#ifdef DEBUG
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_debugCheatIcon", CCSprite *, m_debugCheatIcon);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_sliderParent", CCLayer *, m_sliderParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_childSliderParent", CCLayer *, m_childSliderParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_toolIcon", CCSprite *, m_toolIcon);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_toolInfo", CCLabelTTF *, m_toolInfo);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_debugButtonsParent", CCNode *, m_debugButtonsParent);
#endif
    return true;
}

SEL_CCControlHandler FMGameNode::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
//    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clicktest", FMGameNode::clickTest);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickUIButton", FMGameNode::clickUIButton);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickBooster", FMGameNode::clickBooster);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickCancelBooster", FMGameNode::clickCancelBooster);
#ifdef DEBUG
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickDebugEditLevel", FMGameNode::clickDebugEditLevel);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickDebugSwitchLevel", FMGameNode::clickDebugSwitchLevel);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickDebugCheatMode", FMGameNode::clickDebugCheatMode);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickDebugPlayLevel", FMGameNode::clickDebugPlayLevel);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickDebugClearTutorial", FMGameNode::clickDebugClearTutorial);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickDebugConfig", FMGameNode::clickDebugConfig);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickDebugSaveData", FMGameNode::clickDebugSaveData);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickDebugUpload", FMGameNode::clickDebugUpload);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickDebugPassLevel", FMGameNode::clickDebugPassLevel);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickDebugAddSeed", FMGameNode::clickDebugAddSeed);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickEditorGetGrid", FMGameNode::clickEditorGetGrid);
#endif
    return NULL;
}

void FMGameNode::clickUIButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    switch (button->getTag()) {
        case 0:
        {
            useItemMode(false);
            FMUIPause * window = (FMUIPause *)FMDataManager::sharedManager()->getUI(kUI_Pause);
            window->setClassState(0);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
            break;
//        case 5:
//        {
//            //info button 
//            FMDataManager * manager = FMDataManager::sharedManager();
//            FMUIBoosterInfo * dialog = (FMUIBoosterInfo *)manager->getUI(kUI_BoosterInfo);
//            GAMEUI_Scene::uiSystem()->addDialog(dialog);
//        }
//            break;
        default:
            break;
    }
}
void FMGameNode::clickCancelBooster(CCObject * object, CCControlEvent event)
{
    if (getGamePhase() != kPhase_ItemSelecting || FMDataManager::sharedManager()->isTutorialRunning()) {
        return;
    }

    CCBAnimationManager * anim = (CCBAnimationManager *)m_gameUI->getUserObject();
    anim->runAnimationsForSequenceNamed("BoosterSlideOut");
    
    m_usingItem = -1;
    //cancel selection
    
    useItemMode(false);
    setGamePhase(kPhase_WaitInput);
}

void FMGameNode::clickBooster(cocos2d::CCObject *object, CCControlEvent event)
{
    if (getGamePhase() != kPhase_WaitInput || m_usingItem != -1) {
        return;
    }
    m_swapGrid1 = NULL;
    m_swapGrid2 = NULL;

    CCControlButton * button = (CCControlButton *)object;
    int tag = button->getParent()->getTag();
    
    switch (event) {
        case CCControlEventTouchDown:
        {
//            boosterBoard->playAnimation("")
        }
            break;
        case CCControlEventTouchUpInside:
        {
            FMSound::playEffect("click.mp3", 0.1f, 0.1f);
            showIndicator(false);
            FMDataManager * manager = FMDataManager::sharedManager();
            if (manager->isTutorialRunning()) {
                manager->tutorialPhaseDone();
            }
            if (m_usingItem == tag) {
                m_usingItem = -1;
                //cancel selection
                
                for (int i=0; i<6; i++) {
                    CCAnimButton * boosterButton = (CCAnimButton *)m_boosterParent->getChildByTag(i)->getChildByTag(1);
                    NEAnimNode * boosterIcon = (NEAnimNode *)boosterButton->getAnimNode()->getNodeByName("Booster");
                    boosterIcon->playAnimation("Init");
                }
                useItemMode(false);
                setGamePhase(kPhase_WaitInput);
            }
            else {
                if (m_usingItem != -1) {
                    //already in using item mode
                    //do nothing
                }
                else {
                    //check num
                    if (0) {
                        //show buy booster window
                    }
                    else {
                        m_usingItem = tag;
                        if (tag == kBooster_PlusOne) {
                            if (!isBoosterUsable((kGameBooster)m_usingItem))
                            {
                                m_usingItem = -1;
                                return;
                            }
                            for (int i=0; i<kGridNum; i++) {
                                for (int j=0; j<kGridNum; j++) {
                                    FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
                                    if (grid->getElement()) {
                                        kElementType type = grid->getElement()->getElementType();
//                                        if (!grid->getElement()->isValueAddable()) {
//                                            continue;
//                                        }
                                        if (m_targets.find(type) != m_targets.end()) {
                                            m_animChecker->addAnimNode(grid->getElement()->getAnimNode(), "anim flag 18");
                                            setGamePhase(kPhase_ItemUsing);
                                            
                                            NEAnimNode * sugar = NEAnimNode::createNodeFromFile("FMBoostSugar.ani");
                                            sugar->playAnimation("Init");
                                            sugar->setAutoRemove(true);
                                            grid->getElement()->getAnimNode()->addChild(sugar, 100);
                                        }
                                    }
                                }
                            }
                            if (!m_animChecker->isAnimationDone()) {
                                setGamePhase(kPhase_ItemUsing);
                                m_usingItem = tag;
                                useItem((kGameBooster)m_usingItem);
                            }
                            else {
                                FMSound::playEffect("error.mp3", 0.01f, 0.5f);
                                m_usingItem = -1;
                            }

                            updateBoosters();
                        }
                        else if (tag == kBooster_CureRot) {
                            if (!isBoosterUsable((kGameBooster)m_usingItem))
                            {
                                m_usingItem = -1;
                                return;
                            }
                          
                            if (!m_animChecker->isAnimationDone()) {
                                setGamePhase(kPhase_ItemUsing);
                                m_usingItem = tag;
                                useItem((kGameBooster)m_usingItem);
                            }
                            else {
                                FMSound::playEffect("error.mp3", 0.01f, 0.5f);
                                m_usingItem = -1;
                            }
                            updateBoosters();
                        }
//                        else if (tag == kBooster_Shuffle) {
//                            if (!isBoosterUsable((kGameBooster)m_usingItem))
//                            {
//                                m_usingItem = -1;
//                                return;
//                            }
//                            useItem((kGameBooster)m_usingItem);
//                            setGamePhase(kPhase_NoInput);
////                            FMUIGreenPanel * panel = (FMUIGreenPanel *)m_greenPanel;
////                            panel->setClassState(kPanelShuffle);
////                            panel->setVisible(true);
//                            setGamePhase(kPhase_Shuffling);
//                            shuffle();
//                            m_combo = 0;
//                            FMSound::playEffect("shuffle.mp3");
//                            
//                            //make surprise
////                            for (int i=0; i<8; i++) {
////                                for (int j=0; j<8; j++) {
////                                    FMGameGrid * g = getNeighbor(i, j, kDirection_C);
////                                    if (g->isExistMovableElement()) {
////                                        FMGameElement * e = g->getElement();
////                                        e->makeSurprise();
////                                    }
////                                }
////                            }
//                            m_usingItem = kBooster_None;
//                            updateBoosters();
//                        }
                        else {
                            if (!isBoosterUsable((kGameBooster)m_usingItem))
                            {
                                m_usingItem = -1;
                                return;
                            }
                            enterUseItemMode(m_usingItem);

                        }
                    }
                }
            }
        }
            break;
        case CCControlEventTouchDragExit:
        {
            
        }
            break;
        case CCControlEventTouchDragInside:
        {
            
        }
            break;
        default:
            break;
    }
    
}

#pragma mark - DEBUG

#ifdef DEBUG
void FMGameNode::clickDebugEditLevel()
{
    setGamePhase(kPhase_WaitInput);
    m_isEditorMode = true;
    CCBAnimationManager * anim = (CCBAnimationManager *) m_gameUI->getUserObject();
    anim->runAnimationsForSequenceNamed("SlideOut");
    
    m_debugMenu->removeFromParent();
    
    addChild(m_editor, 2);
    
    makeInit();
    showIndicator(false);
    showSpawner(true);
}

void FMGameNode::clickDebugSwitchLevel()
{
    FMLevelSelectDialog * dialog = new FMLevelSelectDialog();
    dialog->autorelease();
    dialog->setHandleCallback(CCCallFuncN::create(this, callfuncN_selector(FMGameNode::switchLevelHandle)));
    GAMEUI_Scene::uiSystem()->addDialog(dialog);
}

void FMGameNode::switchLevelHandle(cocos2d::CCNode *node)
{
    FMLevelSelectDialog * dialog = (FMLevelSelectDialog *)node;
    if (dialog->getHandleResult() == DIALOG_OK) {
        int worldIndex = dialog->getWorldIndex();
        int levelIndex = dialog->getLevelIndex();
        bool isLocal = dialog->isLocalMode();
        bool isQuest = dialog->isQuest();
        loadLevel(worldIndex, levelIndex, isLocal, isQuest);
        if (m_isEditorMode) {
            showSpawner(true);
        }
    }
}

void FMGameNode::clickDebugCheatMode()
{
    m_cheatMode = !m_cheatMode;
    m_debugCheatIcon->setVisible(m_cheatMode);
    updateBoosters();
}

void FMGameNode::clickDebugPassLevel()
{
    //modify targets
//    FMDataManager * manager = FMDataManager::sharedManager();
//    int worldIndex = manager->getWorldIndex();
//    int levelIndex = manager->getLevelIndex();
//    bool isQuest = manager->isQuest();
//    bool isLocalMode = manager->getLocalMode();
//    saveBoxData();
//    std::map<int, int> items = m_remainItems;
//    loadLevel(worldIndex, levelIndex, isLocalMode, isQuest);
//    m_remainItems = items;
    setCheated(true);
    for (std::map<int, elementTarget>::iterator it = m_targets.begin(); it != m_targets.end(); it++) {
        elementTarget & t = it->second;
        t.harvested = t.target;
    }
    m_score = 10000;
    m_leftMoves = 0;
    checkTargetComplete();
    checkWinner();
}

void FMGameNode::clickDebugAddSeed()
{
    int seed = FMDataManager::getRandomIteratorSeed();
    CCArray * seeds = (CCArray *)m_levelData->objectForKey("seeds");
    if (!seeds) {
        seeds = CCArray::create();
        m_levelData->setObject(seeds, "seeds");
    }
    else {
        //check exist
        for (int i=0; i<seeds->count(); i++) {
            CCNumber * n = (CCNumber*)seeds->objectAtIndex(i);
            if (n->getIntValue() == seed) {
                return;
            }
        }
    }
    seeds->addObject(CCNumber::create(seed));

    clickDebugEditLevel();
    clickDebugConfig();
}

void FMGameNode::clickDebugPlayLevel()
{
    int levelseed = FMDataManager::getRandom();
    FMDataManager::setRandomSeed(levelseed, true);
    testLevel();
}
void FMGameNode::clickDebugClearTutorial()
{
    FMDataManager::sharedManager()->clearAllTutorial();
}
void FMGameNode::clickEditorGetGrid()
{
//    m_toolIcon->setDisplayFrame(NULL);
    m_toolInfo->setString("提取格子");
    m_toolIcon->setTag(-1);
}

void FMGameNode::testLevel()
{
    m_isEditorMode = false;
    setCheated(false);
    CCBAnimationManager * anim = (CCBAnimationManager *) m_gameUI->getUserObject();
    anim->runAnimationsForSequenceNamed("SlideIn");
    
    m_editor->removeFromParent();
    
    addChild(m_debugMenu, 2);
    showSpawner(false);
    updateLevelData();
    makeInit();
}

void FMGameNode::setCheated(bool cheated)
{
    m_isCheated = cheated;
    CCLabelTTF * l = (CCLabelTTF *)m_debugButtonsParent->getChildByTag(5);
    l->setVisible(cheated);
}

void FMGameNode::clickDebugSaveData()
{
    //warning dialog
    updateLevelData();
    FMDataManager * manager = FMDataManager::sharedManager();
    int worldIndex = manager->getWorldIndex();
    int levelIndex = manager->getLevelIndex();
    bool isQuest = manager->isQuest();
    manager->writeLocalLevelData(m_levelData, worldIndex, levelIndex, isQuest);
}

void FMGameNode::clickDebugConfig()
{
    FMLevelConfig * window = new FMLevelConfig();
    window->autorelease();
    window->loadLevelData(m_levelData);
    GAMEUI_Scene::uiSystem()->nextWindow(window);
}

void FMGameNode::clickDebugUpload()
{
    FMUIWarning * dialog = (FMUIWarning *)FMDataManager::sharedManager()->getUI(kUI_Warning);
    dialog->setHandleCallback(CCCallFuncN::create(this, callfuncN_selector(FMGameNode::handleUploadDialog)));
    GAMEUI_Scene::uiSystem()->addDialog(dialog);
}

void FMGameNode::handleUploadDialog(GAMEUI_Dialog *dialog)
{
    if (dialog->getHandleResult() == DIALOG_OK) {
        FMDataManager::sharedManager()->uploadLevelData(m_levelData);
    }
}


#pragma mark - editor items data
EditorItemData gEditorItemsData[] = {
    {kEditorItem_Grid, kGridNone, "去掉格子", "Map.plist|gznull.png"},
    {kEditorItem_Grid, kGridNormal, "普通格子", "Map.plist|gezi.png"},
    {kEditorItem_Grid, kGridGrass, "果冻格子", "Map.plist|grass.png"},
//    {kEditorItem_Wall, kWallNone, "墙-去掉", "FMElements_CandyWall.ani", "No", "Vertical"},
//    {kEditorItem_Wall, kWallNormal, "墙-1", "FMElements_CandyWall.ani", "1Idle", "Vertical"},
//    {kEditorItem_Wall, kWallBreak, "墙-2", "FMElements_CandyWall.ani", "2Idle", "Vertical"},
    {kEditorItem_Status, kGridStatus_NoStatus, "清除状态", "Map.plist|gzclean.png"},
    {kEditorItem_Status, kGridStatus_Ice, "状态-冰", "Map.plist|ice.png"},
    {kEditorItem_Status, kGridStatus_Spawner, "状态-生成", "Map.plist|gzspawner.png"},
//    {kEditorItem_Status, kStatus_Snail, "状态-蜗牛", "FMElementSnail.ani", "snailmove"},
//    {kEditorItem_Status, kStatus_4Bonus, "4消格子", "FMGridBonus.ani", "4"},
//    {kEditorItem_Status, kStatus_5Bonus, "5消格子", "FMGridBonus.ani", "5"},
//    {kEditorItem_Status, kStatus_TBonus, "T消格子", "FMGridBonus.ani", "T"},
    {kEditorItem_Element, kElement_Random, "随机元素", "Elements.plist|random.png"},
    {kEditorItem_Element, kElement_None, "无元素", "Elements.plist|none.png"},
    {kEditorItem_Element, kElement_1Red, "红", "FMElements.ani", "TargetIdle", "Red"},
    {kEditorItem_Element, kElement_2Orange, "橙","FMElements.ani", "TargetIdle", "Orange"},
    {kEditorItem_Element, kElement_3Yellow, "黄", "FMElements.ani", "TargetIdle", "Yellow"},
    {kEditorItem_Element, kElement_4Green, "绿", "FMElements.ani", "TargetIdle", "Green"},
    {kEditorItem_Element, kElement_5Blue, "蓝", "FMElements.ani", "TargetIdle", "Blue"},
    {kEditorItem_Element, kElement_6Pink, "粉", "FMElements.ani", "TargetIdle", "Purple"},
//    {kEditorItem_Element, kElement_1RedJello, "红[杯]", "FMElements.ani", "TargetIdle", "JelloRed"},
//    {kEditorItem_Element, kElement_2OrangeJello, "橙[杯]","FMElements.ani", "TargetIdle", "JelloOrange"},
//    {kEditorItem_Element, kElement_3YellowJello, "黄[杯]", "FMElements.ani", "TargetIdle", "JelloYellow"},
//    {kEditorItem_Element, kElement_4GreenJello, "绿[杯]", "FMElements.ani", "TargetIdle", "JelloGreen"},
//    {kEditorItem_Element, kElement_5BlueJello, "蓝[杯]", "FMElements.ani", "TargetIdle", "JelloBlue"},
//    {kEditorItem_Element, kElement_6PinkJello, "粉[杯]", "FMElements.ani", "TargetIdle", "JelloPurple"},
//    {kEditorItem_Element, kElement_1RedBad, "红[坏]", "FMElements.ani", "TargetIdle", "RedBad"},
//    {kEditorItem_Element, kElement_2OrangeBad, "橙[坏]", "FMElements.ani", "TargetIdle", "OrangeBad"},
//    {kEditorItem_Element, kElement_3YellowBad, "黄[坏]", "FMElements.ani", "TargetIdle", "YellowBad"},
//    {kEditorItem_Element, kElement_4GreenBad, "绿[坏]", "FMElements.ani", "TargetIdle", "GreenBad"},
//    {kEditorItem_Element, kElement_5BlueBad, "蓝[坏]", "FMElements.ani", "TargetIdle", "BlueBad"},
//    {kEditorItem_Element, kElement_6PinkBad, "紫[坏]", "FMElements.ani", "TargetIdle", "PurpleBad"},
//    {kEditorItem_Element, kElement_Grow1, "成长-1", "FMElements_Grow.ani", "Grow1Idle"},
//    {kEditorItem_Element, kElement_Grow2, "成长-2", "FMElements_Grow.ani", "Grow2Idle"},
//    {kEditorItem_Element, kElement_Grow3, "成长-3", "FMElements_Grow.ani", "Grow3Idle"},
//    {kEditorItem_Element, kElement_Egg1, "合成1", "FMElements_Combine.ani", "Combine1Idle"},
//    {kEditorItem_Element, kElement_Egg2, "合成2", "FMElements_Combine.ani", "Combine2Idle"},
//    {kEditorItem_Element, kElement_4Split1_Red, "4分-红1", "FMElements_Split4.ani", "Splitfour1Idle", "Red"},
//    {kEditorItem_Element, kElement_4Split2_Red, "4分-红2", "FMElements_Split4.ani", "Splitfour2Idle", "Red"},
//    {kEditorItem_Element, kElement_4Split3_Red, "4分-红3", "FMElements_Split4.ani", "Splitfour3Idle", "Red"},
//    {kEditorItem_Element, kElement_4Split1_Orange, "4分-橙1", "FMElements_Split4.ani", "Splitfour1Idle", "Orange"},
//    {kEditorItem_Element, kElement_4Split2_Orange, "4分-橙2", "FMElements_Split4.ani", "Splitfour2Idle", "Orange"},
//    {kEditorItem_Element, kElement_4Split3_Orange, "4分-橙3", "FMElements_Split4.ani", "Splitfour3Idle", "Orange"},
//    {kEditorItem_Element, kElement_4Split1_Yellow, "4分-黄1", "FMElements_Split4.ani", "Splitfour1Idle", "Yellow"},
//    {kEditorItem_Element, kElement_4Split2_Yellow, "4分-黄2", "FMElements_Split4.ani", "Splitfour2Idle", "Yellow"},
//    {kEditorItem_Element, kElement_4Split3_Yellow, "4分-黄3", "FMElements_Split4.ani", "Splitfour3Idle", "Yellow"},
//    {kEditorItem_Element, kElement_4Split1_Green, "4分-绿1", "FMElements_Split4.ani", "Splitfour1Idle", "Green"},
//    {kEditorItem_Element, kElement_4Split2_Green, "4分-绿2", "FMElements_Split4.ani", "Splitfour2Idle", "Green"},
//    {kEditorItem_Element, kElement_4Split3_Green, "4分-绿3", "FMElements_Split4.ani", "Splitfour3Idle", "Green"},
//    {kEditorItem_Element, kElement_4Split1_Blue, "4分-蓝1", "FMElements_Split4.ani", "Splitfour1Idle", "Blue"},
//    {kEditorItem_Element, kElement_4Split2_Blue, "4分-蓝2", "FMElements_Split4.ani", "Splitfour2Idle", "Blue"},
//    {kEditorItem_Element, kElement_4Split3_Blue, "4分-蓝3", "FMElements_Split4.ani", "Splitfour3Idle", "Blue"},
//    {kEditorItem_Element, kElement_4Split1_Pink, "4分-粉1", "FMElements_Split4.ani", "Splitfour1Idle", "Purple"},
//    {kEditorItem_Element, kElement_4Split2_Pink, "4分-粉2", "FMElements_Split4.ani", "Splitfour2Idle", "Purple"},
//    {kEditorItem_Element, kElement_4Split3_Pink, "4分-粉3", "FMElements_Split4.ani", "Splitfour3Idle", "Purple"},
//    {kEditorItem_Element, kElement_3Split1, "3分裂-1", "FMElements_Split3.ani", "SplitThree1Idle"},
//    {kEditorItem_Element, kElement_3Split2, "3分裂-2", "FMElements_Split3.ani", "SplitThree2Idle"},
//    {kEditorItem_Element, kElement_3Split3, "3分裂-3", "FMElements_Split3.ani", "SplitThree3Idle"},
//    {kEditorItem_Element, kElement_Cannon1, "大炮-上", "FMElements_Cannon.ani", "Init", "Up"},
//    {kEditorItem_Element, kElement_Cannon2, "大炮-下", "FMElements_Cannon.ani", "Init", "Down"},
//    {kEditorItem_Element, kElement_Cannon3, "大炮-左", "FMElements_Cannon.ani", "Init", "Left"},
//    {kEditorItem_Element, kElement_Cannon4, "大炮-右", "FMElements_Cannon.ani", "Init", "Right"},
//    {kEditorItem_Element, kElement_Ghost1Red, "小鬼-红", "FMElements_Ghost.ani", "NormalIdle" ,"Red"},
//    {kEditorItem_Element, kElement_Ghost2Orange, "小鬼-橙", "FMElements_Ghost.ani", "NormalIdle" ,"Orange"},
//    {kEditorItem_Element, kElement_Ghost3Yellow, "小鬼-黄", "FMElements_Ghost.ani", "NormalIdle" ,"Yellow"},
//    {kEditorItem_Element, kElement_Ghost4Green, "小鬼-绿", "FMElements_Ghost.ani", "NormalIdle" ,"Green"},
//    {kEditorItem_Element, kElement_Ghost5Blue, "小鬼-蓝", "FMElements_Ghost.ani", "NormalIdle" ,"Blue"},
//    {kEditorItem_Element, kElement_Ghost6Pink, "小鬼-粉", "FMElements_Ghost.ani", "NormalIdle" ,"Purple"},
//    {kEditorItem_Element, kElement_GhostStun1Red, "小鬼-红[晕]", "FMElements_Ghost.ani", "GiddyIdle" ,"Red"},
//    {kEditorItem_Element, kElement_GhostStun2Orange, "小鬼-橙[晕]", "FMElements_Ghost.ani", "GiddyIdle" ,"Orange"},
//    {kEditorItem_Element, kElement_GhostStun3Yellow, "小鬼-黄[晕]", "FMElements_Ghost.ani", "GiddyIdle" ,"Yellow"},
//    {kEditorItem_Element, kElement_GhostStun4Green, "小鬼-绿[晕]", "FMElements_Ghost.ani", "GiddyIdle" ,"Green"},
//    {kEditorItem_Element, kElement_GhostStun5Blue, "小鬼-蓝[晕]", "FMElements_Ghost.ani", "GiddyIdle" ,"Blue"},
//    {kEditorItem_Element, kElement_GhostStun6Pink, "小鬼-粉[晕]", "FMElements_Ghost.ani", "GiddyIdle" ,"Purple"},
//    {kEditorItem_Element, kElement_ChangeColor, "变色糖", "FMElements.ani", "TargetIdle" ,"Candy"},
//    {kEditorItem_Element, kElement_Drop, "弹跳果冻", "FMElements_Queen.ani", "Init"},
//    {kEditorItem_Status, kStatus_JumpSeat, "弹跳格子", "FMGridSeat.ani", "Init"},
//    
//    {kEditorItem_Element, kElement_SwitchRed, "红[粉]", "FMElements.ani", "TargetIdle", "RedHat"},
//    {kEditorItem_Element, kElement_SwitchOrange, "橙[黄]", "FMElements.ani", "TargetIdle", "OrangeHat"},
//    {kEditorItem_Element, kElement_SwitchYellow, "黄[橙]", "FMElements.ani", "TargetIdle", "YellowHat"},
//    {kEditorItem_Element, kElement_SwitchGreen, "绿[蓝]", "FMElements.ani", "TargetIdle", "GreenHat"},
//    {kEditorItem_Element, kElement_SwitchBlue, "蓝[绿]", "FMElements.ani", "TargetIdle", "BlueHat"},
//    {kEditorItem_Element, kElement_SwitchPink, "粉[红]", "FMElements.ani", "TargetIdle", "PurpleHat"},
//    
//    {kEditorItem_Wall, kElement_BedRed, "红[床]", "Bounce.ani", "jump", "red"},
//    {kEditorItem_Wall, kElement_BedOrange, "橙[床]", "Bounce.ani", "jump", "orange"},
//    {kEditorItem_Wall, kElement_BedYellow, "黄[床]", "Bounce.ani", "jump", "yellow"},
//    {kEditorItem_Wall, kElement_BedGreen, "绿[床]", "Bounce.ani", "jump", "green"},
//    {kEditorItem_Wall, kElement_BedBlue, "蓝[床]", "Bounce.ani", "jump", "blue"},
//    {kEditorItem_Wall, kElement_BedPink, "粉[床]", "Bounce.ani", "jump", "purple"},
//    {kEditorItem_Wall, kElement_BedRandom, "席梦思", "Bounce.ani", "jump", "random"},
//    
//    
//
};

int getEditorItemsCount()
{
    return sizeof(gEditorItemsData) / sizeof(EditorItemData);
}
static bool gButtonCanClick = false;

void FMGameNode::clickItem(cocos2d::CCObject *object, CCControlEvent event)
{
    CCControlButton * button = (CCControlButton *)object;
    int tag = button->getTag();

    if (event == CCControlEventTouchDown) {
        gButtonCanClick = true;
    }
    else if (event == CCControlEventTouchDragInside) { 
        gButtonCanClick = false;
    }
    else if (event == CCControlEventTouchUpInside) { 
        if (gButtonCanClick) {
            gButtonCanClick = false; 
            
            EditorItemData data = gEditorItemsData[tag];
            CCSpriteFrame * frame = NULL;
            if (data.animName) {
                int rowIndex = tag;
                CCRenderTexture * tex = CCRenderTexture::create(50, 60);
                tex->beginWithClear(0, 0, 0, 0);
                NEAnimNode * anim = NEAnimNode::createNodeFromFile(gEditorItemsData[rowIndex].file);
                if (data.skinName) {
                    anim->useSkin(data.skinName);
                }
                tex->addChild(anim);
                anim->playAnimation(gEditorItemsData[rowIndex].animName, 0, true, false);
                anim->setPosition(ccp(25, 30));
                anim->setScaleY(-1.f);
                anim->visit();
                tex->end();
                frame = tex->getSprite()->displayFrame();
            }
            else {
                frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(data.file);
            }
            m_toolIcon->setDisplayFrame(frame);
            m_toolInfo->setString(data.name);
            m_toolIcon->setTag(tag);
            showElements(true);
            showSpawner(true);
            m_childSliderParent->setVisible(false);
            m_childMode = 0;
        }
    }
}


void FMGameNode::clickSubItem(cocos2d::CCObject *object, CCControlEvent event)
{
    CCControlButton * button = (CCControlButton *)object;
    int tag = button->getTag();
    
    if (event == CCControlEventTouchDown) {
        gButtonCanClick = true;
    }
    else if (event == CCControlEventTouchDragInside) {
        gButtonCanClick = false;
    }
    else if (event == CCControlEventTouchUpInside) {
        if (gButtonCanClick) {
            gButtonCanClick = false;
            if (m_childMode == 1) {
                m_selectBoxid = tag; 
                if (m_selectBoxid != -1) {
                    CCString * str = CCString::createWithFormat("宝箱%d", m_selectBoxid);
                    m_toolInfo->setString(str->getCString());
                }
            }
        }
    }
}

CCNode * FMGameNode::createItemForSlider(GUIScrollSlider *slider)
{
    int tag = slider->getTag();
    if (tag == 1) {
        CCControlButton * button = CCControlButton::create();
        button->addTargetWithActionForControlEvents(this, cccontrol_selector(FMGameNode::clickItem), CCControlEventTouchDown);
        button->addTargetWithActionForControlEvents(this, cccontrol_selector(FMGameNode::clickItem), CCControlEventTouchDragInside);
        button->addTargetWithActionForControlEvents(this, cccontrol_selector(FMGameNode::clickItem), CCControlEventTouchUpInside);
        return button;
    }
    else if (tag == 2) {
        CCControlButton * button = CCControlButton::create();
        button->addTargetWithActionForControlEvents(this, cccontrol_selector(FMGameNode::clickSubItem), CCControlEventTouchDown);
        button->addTargetWithActionForControlEvents(this, cccontrol_selector(FMGameNode::clickSubItem), CCControlEventTouchDragInside);
        button->addTargetWithActionForControlEvents(this, cccontrol_selector(FMGameNode::clickSubItem), CCControlEventTouchUpInside);
        return button;
    }
    return NULL;
}

void FMGameNode::sliderUpdate(GUIScrollSlider *slider, int rowIndex, cocos2d::CCNode *node)
{
    int tag = slider->getTag();
    if (tag == 1) {
        CCControlButton * button = (CCControlButton *)node;
        
        EditorItemData data = gEditorItemsData[rowIndex];
        CCSpriteFrame * frame = NULL;
        if (data.animName) {
            int rowIndex = tag;
            CCRenderTexture * tex = CCRenderTexture::create(50, 60);
            tex->beginWithClear(0, 0, 0, 0);
            NEAnimNode * anim = NEAnimNode::createNodeFromFile(data.file);
            if (data.skinName) {
                anim->useSkin(data.skinName);
            }
            tex->addChild(anim);
            anim->playAnimation(data.animName, 0, true, false);
            anim->setPosition(ccp(25, 30));
            anim->setScaleY(-1.f);
            anim->visit();
            tex->end();
            frame = tex->getSprite()->displayFrame();
        }
        else {
            frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(data.file);
        }
        button->setBackgroundSpriteFrameForState(frame, CCControlStateNormal);
        button->setBackgroundSpriteFrameForState(frame, CCControlStateHighlighted);
        button->setBackgroundSpriteFrameForState(frame, CCControlStateDisabled);
        button->setAnchorPoint(ccp(0.5f, 0.5f));
        button->setPreferredSize(frame->getRect().size);
        button->setTag(rowIndex);
    }
    else if (tag == 2) {
        CCControlButton * button = (CCControlButton *)node;
        button->setPreferredSize(CCSize(40, 40));

        if (m_childMode == 1) {
        }
    }
    
}

int FMGameNode::itemsCountForSlider(GUIScrollSlider *slider)
{
    int tag = slider->getTag();
    
    switch (tag) {
        case 1:
        {
            return getEditorItemsCount();
        }
            break;
        case 2:
        {
            if (m_childMode == 1) {
            }
            else {
                return 0;
            }
        }
            break;
        default:
            break;
    }
    return 0;
}

void FMGameNode::showElements(bool show)
{
    for (int i=0; i<kGridNum; i++) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
            FMGameElement * element = grid->getElement();
            if (element) {
                element->restoreState();
//                if (show)
//                    element->playAnimation("Init");
//                else
//                    element->playAnimation("Transparent");
            }
        }
    }
}

void FMGameNode::showSpawner(bool show)
{
    for (int i=0; i<kGridNum; i++) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
            CCSprite * spawner = (CCSprite *)grid->getAnimNode()->getUserObject();
            if (spawner) {
                spawner->removeFromParent();
            }
            if (show) {
                if (grid->hasGridStatus(kGridStatus_Spawner)) {
                    spawner = CCSprite::createWithSpriteFrameName("Map.plist|spawner.png");
                    spawner->setAnchorPoint(ccp(0.5f, 0.5f));
                    grid->getAnimNode()->getParent()->addChild(spawner, 1000);
                    spawner->setPosition(grid->getPosition());
                    grid->getAnimNode()->setUserObject(spawner);
                }
            }
        }
    }
}

void FMGameNode::changeGridData(int row, int col)
{
    int tag = m_toolIcon->getTag();
    EditorItemData data = gEditorItemsData[tag];
    switch (data.type) {
        case kEditorItem_Grid:
        {
            kGridType type = (kGridType)data.value;
            FMGameGrid * grid = getNeighbor(row, col, kDirection_C);
            if (grid) {
                grid->setGridType(type);
                if (type == kGridNone) {
                    grid->getAnimNode()->setVisible(false);
                    grid->cleanGridStatus();
                    grid->getElement()->getAnimNode()->setVisible(false);
                }
                else {
                    grid->getAnimNode()->setVisible(true);
                    grid->getElement()->getAnimNode()->setVisible(true);
                }
            }
            updateBackGrids();
        }
            break;
        case kEditorItem_Status:
        {
            kGridStatus status = (kGridStatus)data.value;
            FMGameGrid * grid = getNeighbor(row, col, kDirection_C);
            if (!grid->isNone()) {
                switch (status) {
                    case kGridStatus_NoStatus:
                    {
                        grid->cleanGridStatus();
                        if (grid->getElement()->hasStatus(kStatus_Frozen)) {
                            grid->getElement()->removeStatus(kStatus_Frozen);
                        }
                    }
                        break;
                    case kGridStatus_Ice:
                    {
                        if (m_isStatusOn) {
                            grid->getElement()->addStatus(kStatus_Frozen);
                            grid->addGridStatus(status);
                        }
                        else {
                            grid->getElement()->removeStatus(kStatus_Frozen);
                            grid->removeGridStatus(status);
                        }
                    }
                        break;
//                    case kStatus_4Bonus:
//                    case kStatus_5Bonus:
//                    case kStatus_TBonus:
//                    {
//                        if (m_isStatusOn) {
//                            kGridBonus bonus = (kGridBonus)status;
//                            grid->setGridBonus(bonus);
//                        }
//                        else {
//                            grid->setGridBonus(kBonus_None);
//                        }
//                    }
//                        break;
                    default:
                    {
                        if (m_isStatusOn) {
                            grid->addGridStatus(status);
                        }
                        else {
                            grid->removeGridStatus(status);
                        }
                    }
                        break;
                }
            }
            showSpawner(true);
        }
            break;
        case kEditorItem_Element:
        {
            kElementType type = (kElementType)data.value;
            FMGameGrid * grid = getNeighbor(row, col, kDirection_C);
            if (!grid->isNone()) {
                grid->getElement()->setElementType(type);

            }
            if (grid->hasGridStatus(kGridStatus_Ice)) {
                grid->getElement()->addStatus(kStatus_Frozen);
            }
        }
            break;
            
//        case kEditorItem_Wall:
//        {
//            kElementType type = (kElementType)data.value;
//            if (type >= kElement_BedRed && type <= kElement_BedRandom) {
//                FMGameGrid * grid = getNeighbor(row, col, kDirection_C);
//                FMGameGrid* rightGrid = getNeighbor(row, col, kDirection_R);
//                FMGameGrid* leftGrid = getNeighbor(row, col, kDirection_L);
//                kElementType leftType = kElement_None;
//                kElementType rightType = kElement_None;
//
//                if (leftGrid && leftGrid->getElement()) leftType = leftGrid->getElement()->getElementType();
//                if (rightGrid && rightGrid->getElement()) rightType = rightGrid->getElement()->getElementType();
//                bool leftIsOk = (!FMGameElement::isBedType(leftType));
//                bool rightIsOk = (!FMGameElement::isBedType(rightType));
//                
//                if (!grid->isNone() && rightGrid && leftIsOk && rightIsOk) {
//                    grid->getElement()->setElementType(type);
//                    rightGrid->setGridType(kGridNormal);
//                    rightGrid->setElementType(kElement_PlaceHold);
//                    rightGrid->getAnimNode()->setVisible(false);
//                    rightGrid->cleanGridStatus();
//                    rightGrid->setGridBonus(kBonus_None);
//                    if (rightGrid->getElement()) {
//                        rightGrid->getElement()->setElementType(kElement_PlaceHold);
//                        rightGrid->getElement()->getAnimNode()->setVisible(false);
//                        
//                    }
//                    rightGrid->m_gridNode->setVisible(true);
//                }
//                if (grid->hasGridStatus(kStatus_Ice)) {
//                    grid->getElement()->setFrozen(true);
//                }
//                
//                
//                
//            }
//        }
//            break;
            
        default:
            break;
    }
}

void FMGameNode::setToolIconWithGrid(FMGameGrid * grid)
{
    int value;
    EditorItemType type;
    kGridType gtype = grid->getGridType();
    if (gtype == kGridNone) {
        type = kEditorItem_Grid;
        value = kGridNone;
    }else{
        FMGameElement * e = grid->getElement();
        if (e->getElementType() == kElement_Random) {
//            if (grid->hasGridStatus(kStatus_JumpSeat)) {
//                type = kEditorItem_Status;
//                value = kStatus_JumpSeat;
//            }
//            else if (grid->hasGridStatus(kStatus_TBonus)||grid->getGridBonus() == kBonus_Cross) {
//                type = kEditorItem_Status;
//                value = kStatus_TBonus;
//            }
//            else if (grid->hasGridStatus(kStatus_5Bonus)||grid->getGridBonus() == kBonus_5Line) {
//                type = kEditorItem_Status;
//                value = kStatus_5Bonus;
//            }
//            else if (grid->hasGridStatus(kStatus_4Bonus)||grid->getGridBonus() == kBonus_4Match) {
//                type = kEditorItem_Status;
//                value = kStatus_4Bonus;
//            }
            if (grid->hasGridStatus(kGridStatus_Ice)) {
                type = kEditorItem_Status;
                value = kGridStatus_Ice;
            }
//            else if (gtype == kGridGrass){
//                type = kEditorItem_Grid;
//                value = kGridGrass;
//            }
            else if (grid->hasGridStatus(kGridStatus_Spawner)) {
                type = kEditorItem_Status;
                value = kGridStatus_Spawner;
            }
            else{
                type = kEditorItem_Element;
                value = kElement_Random;
            }

        }else{
            type = kEditorItem_Element;
            kElementType et = e->getElementType();
            value = et;
//            if (et == kElement_Grow1) {
//                if (e->getPhase() == 1) {
//                    value = kElement_Grow2;
//                }
//                if (e->getPhase() == 2) {
//                    value = kElement_Grow3;
//                }
//            }
//            else if (e->isGhostType()){
//                if (e->getPhase() == 1) {
//                    value += 6;
//                }
//            }
//            else if (et == kElement_3Split1){
//                if (e->getPhase() == 1) {
//                    value = kElement_3Split2;
//                }
//                if (e->getPhase() == 2) {
//                    value = kElement_3Split3;
//                }
//            }
//            else if (et == kElement_4Split1){
//                int phase = e->getPhase();
//                int color = e->getElementColor();
//                value = phase*6+kElement_4Split1_Red+color;
//            }
        }
    }
    for (int i = 0; i < getEditorItemsCount(); i++) {
        EditorItemData data = gEditorItemsData[i];
        if (data.type == type && data.value == value) {
            CCSpriteFrame * frame = NULL;
            if (data.animName) {
                int rowIndex = i;
                CCRenderTexture * tex = CCRenderTexture::create(50, 60);
                tex->beginWithClear(0, 0, 0, 0);
                NEAnimNode * anim = NEAnimNode::createNodeFromFile(gEditorItemsData[rowIndex].file);
                if (data.skinName) {
                    anim->useSkin(data.skinName);
                }
                tex->addChild(anim);
                anim->playAnimation(gEditorItemsData[rowIndex].animName, 0, true, false);
                anim->setPosition(ccp(25, 30));
                anim->setScaleY(-1.f);
                anim->visit();
                tex->end();
                frame = tex->getSprite()->displayFrame();
            }
            else {
                frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(data.file);
            }
            m_toolIcon->setDisplayFrame(frame);
            m_toolInfo->setString(data.name);
            m_toolIcon->setTag(i);
            showElements(true);
            showSpawner(true);
            m_childSliderParent->setVisible(false);
            m_childMode = 0;
            break;
        }
    }
}

void FMGameNode::updateLevelData()
{
    CCArray * mapData = CCArray::create();

    for (int i=0; i<kGridNum; i++) {
        CCArray * rowData = CCArray::create();
        mapData->addObject(rowData);
        for (int j=0; j<kGridNum; j++) {
            CCArray * gridData = CCArray::create();
            rowData->addObject(gridData);
            FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
            if (grid->isNone()) {
                gridData->addObject(CCNumber::create(kGridNone));
            }
            else {
                kGridType gtype = grid->getGridType();
                kElementType etype = grid->getElement()->getElementPrototype();
//                kGridBonus bonus = grid->getGridBonus();
                
                if (grid->getGridStatusCount() != 0) {
                    gridData->addObject(CCNumber::create(gtype));
                    gridData->addObject(CCNumber::create(etype));
                    FMGameElement * element = grid->getElement();
                    if (element && element->hasStatus(kStatus_Frozen)) {
                        gridData->addObject(CCNumber::create(kGridStatus_Ice));
                    }
                    if (grid->hasGridStatus(kGridStatus_Spawner)) {
                        gridData->addObject(CCNumber::create(kGridStatus_Spawner));
                    }
//                    if (grid->hasGridStatus(kStatus_Snail)) {
//                        gridData->addObject(CCNumber::create(kStatus_Snail));
//                    }
                }
                else {
                    if (etype == kElement_Random) {
                        if (gtype == kGridNormal) {
                            // default
                        }
                        else {
                            gridData->addObject(CCNumber::create(gtype));
                        }
                    }
                    else {
                        gridData->addObject(CCNumber::create(gtype));
                        gridData->addObject(CCNumber::create(etype));
                    }
                }
               
            }
        }
    }
    
    m_levelData->setObject(mapData, "map");
    
    CCArray * wallData = CCArray::create();
    bool noWalls = true;
    for (int i=0; i<2; i++) {
        CCArray * data1 = CCArray::create();
        wallData->addObject(data1);
        for (int j=0; j<kGridNum-1; j++) {
            CCArray * data2 = CCArray::create();
            data1->addObject(data2);
            for (int k=0; k<kGridNum; k++) {
                CCArray * data3 = CCArray::create();
                data2->addObject(data3);
                kWallType type = m_walls[i][j][k]->getWallType();
                if (type != kWallNone) {
                    noWalls = false;
                }
                data3->addObject(CCNumber::create(type));
            }
        }
    }
    if (!noWalls) {
        m_levelData->setObject(wallData, "wall");
    }
    else {
        m_levelData->removeObjectForKey("wall");
    }
}

#endif

#pragma mark - animation callback
void FMGameNode::animationEnded(NEAnimNode * node, const char *animName)
{
}

void FMGameNode::animationCallback(NEAnimNode * node, const char *animName, const char *callback)
{
    
}

void FMGameNode::completedAnimationSequenceNamed(const char *name)
{

}

#pragma mark - touch 
bool FMGameNode::ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent)
{
#ifdef DEBUG
    if (m_isEditorMode) { 
        CCNode * offsetNode = m_gridParent->getChildByTag(1);
        m_touchBeginPoint = pTouch->getLocation();
        m_touchBeginPoint = offsetNode->convertToNodeSpace(m_touchBeginPoint);
        int row = (int)(-m_touchBeginPoint.y / (float)kGridHeight + 0.5f);
        int col = m_touchBeginPoint.x  / kGridWidth + 0.5f;
        m_currentCoord = ccp(row, col);
        FMGameGrid * touchingGrid = getNeighbor(row, col, kDirection_C);
        if (touchingGrid) { 
            int tag = m_toolIcon->getTag();
            if (tag == -1) {
                setToolIconWithGrid(touchingGrid);
                return false;
            }
            EditorItemData data = gEditorItemsData[tag];
            if (data.type == kEditorItem_Status) {
                kGridStatus status = (kGridStatus)data.value;
//                if (status == kStatus_4Bonus ||
//                    status == kStatus_5Bonus ||
//                    status == kStatus_TBonus) {
//                    kGridBonus bonus = (kGridBonus)status;
//                    if (touchingGrid->getGridBonus() != bonus) {
//                        m_isStatusOn = true;
//                    }
//                    else {
//                        m_isStatusOn = false;
//                    }
//                }
//                else {
                    if (touchingGrid->hasGridStatus(status)) {
                        m_isStatusOn = false;
                    }
                    else {
                        m_isStatusOn = true;
                    }
//                }
            }
            changeGridData(row, col);
            return true;
        }
        return false;
    }
#endif
    m_touchBegin = true;
//    makeGridSurprise(false);
    if (getGamePhase() == kPhase_ItemSelecting && m_usingItem != kBooster_None) {
        CCNode * offsetNode = m_gridParent->getChildByTag(1);
        m_touchBeginPoint = pTouch->getLocation();
        m_touchBeginPoint = offsetNode->convertToNodeSpace(m_touchBeginPoint);
        int row = (int)(-m_touchBeginPoint.y / (float)kGridHeight + 0.5f);
        int col = m_touchBeginPoint.x  / kGridWidth + 0.5f;
        if (isCoordExist(row, col) && isCoordTouchable(row, col)) {
            showSelectedGrids(true, row, col);
        }
        else {
            showSelectedGrids(false);
        }
        return true;
    }
    if (!canPlayerInput()) {
        return false;
    }
    
    CCNode * offsetNode = m_gridParent->getChildByTag(1);
    m_touchBeginPoint = pTouch->getLocation();
    m_touchBeginPoint = offsetNode->convertToNodeSpace(m_touchBeginPoint);
    
    int row = (int)ceilf(-m_touchBeginPoint.y / (float)kGridHeight - 0.5f);
    int col = m_touchBeginPoint.x  / kGridWidth + 0.5f;
    FMGameGrid * touchingGrid = getNeighbor(row, col, kDirection_C);
    
    if (touchingGrid && touchingGrid->isSwappable() && isCoordTouchable(row, col)) {
        if (m_swapGrid1) {
            //check can swap?
            CCPoint grid1Coord = m_swapGrid1->getCoord();
            CCPoint grid2Coord = touchingGrid->getCoord();
            float distance = ccpDistance(grid1Coord, grid2Coord);
            if (distance == 1.f) {
                //can swap
                
                FMGameGrid * g1 = m_swapGrid1;
                FMGameGrid * g2 = touchingGrid;
                kGameDirection dir = kDirection_None;
                if (grid1Coord.x < grid2Coord.x) {
                    dir = kDirection_B;
                }
                else if (grid1Coord.x > grid2Coord.x){
                    dir = kDirection_U;
                }
                if (grid1Coord.y < grid2Coord.y) {
                    dir = kDirection_R;
                }
                else if (grid1Coord.y > grid2Coord.y) {
                    dir = kDirection_L;
                }
                
                bool hasRoute = hasRouteToDirection(g1, dir);
                if (hasRoute && g2->isSwappable()) {
                    CCPoint coord2 = g2->getCoord();
                    int row2 = coord2.x;
                    int col2 = coord2.y;
                    if (isCoordTouchable(row2, col2)) {
                        swapElements(g1, g2);
                    }
                }
                else {
                    FMSound::playEffect("tap.mp3", 0.01f, 0.5f);
                    m_swapGrid1 = NULL;
                    m_swapGrid2 = NULL;
                    
                    m_swapBegin = false;
                    m_touchBegin = false;
                    showIndicator(false);
                    switch (dir) {
                        case kDirection_L:
                            g1->getElement()->playAnimation("BounceLeft");
                            break;
                        case kDirection_R:
                            g1->getElement()->playAnimation("BounceRight");
                            break;
                        case kDirection_U:
                            g1->getElement()->playAnimation("BounceUp");
                            break;
                        case kDirection_B:
                            g1->getElement()->playAnimation("BounceDown");
                            break;
                            
                        default:
                            break;
                    }
                }
 
            }
            else {
                //switch current to this one
                m_swapGrid1 = touchingGrid;
                showIndicator(true, grid2Coord.x, grid2Coord.y);
            }
        }
        else {
            m_swapGrid1 = touchingGrid;
            m_swapGrid2 = NULL;
            showIndicator(true, row, col);
        }
        return true;
    }
    return false;
}

void FMGameNode::ccTouchMoved(CCTouch *pTouch, CCEvent *pEvent)
{
    CCNode * offsetNode = m_gridParent->getChildByTag(1);
    CCPoint touchPoint = pTouch->getLocation();
    touchPoint = offsetNode->convertToNodeSpace(touchPoint);
#ifdef DEBUG
    if (m_isEditorMode) { 
        int row = (int)(-touchPoint.y / (float)kGridHeight + 0.5f);
        int col = touchPoint.x  / kGridWidth + 0.5f;
        if (m_currentCoord.x != row || m_currentCoord.y != col) {
            //change coord, check wall
            kGameDirection dir = kDirection_None;
            if (m_currentCoord.x > row) {
                dir = kDirection_U;
            }
            else if (m_currentCoord.x < row) {
                dir = kDirection_B;
            }
            
            if (m_currentCoord.y > col) {
                dir = kDirection_L;
            }
            else if (m_currentCoord.y < col){
                dir = kDirection_R;
            }
            if (dir != kDirection_None) {
                FMGameWall * wall = getWall(m_currentCoord.x, m_currentCoord.y, dir);
                if (wall) {
                    int tag = m_toolIcon->getTag();
                    EditorItemData data = gEditorItemsData[tag];
//                    if (data.type == kEditorItem_Wall) {
//                        kWallType type = (kWallType)data.value;
//                        wall->setWallType(type);
//                    }
                }
            }
            m_currentCoord = ccp(row, col);
        }
        FMGameGrid * grid = getNeighbor(row, col, kDirection_C);
        if (grid) {
            changeGridData(row, col);
        }
        return;
    }
#endif
    if (getGamePhase() == kPhase_ItemSelecting && m_usingItem != kBooster_None) { 
        int row = (int)ceilf(-touchPoint.y / (float)kGridHeight - 0.5f);
        int col = touchPoint.x  / kGridWidth + 0.5f;
        if (isCoordExist(row, col) && isCoordTouchable(row, col)) {
            showSelectedGrids(true, row, col);
        }
        else {
            showSelectedGrids(false);
        }

        return;
    }
    if (!canPlayerInput()) {
        return;
    }
    
    CCPoint localP = touchPoint;
    
    CCPoint offset = ccpSub(localP, m_touchBeginPoint);
    float distance = ccpLength(offset);
    if (distance >= kGridWidth * 0.5f) {
        float angle = atan2f(offset.y, offset.x);
        float cos = cosf(angle);
        static float root22 = 0.707f;
        kGameDirection dir = kDirection_C;
        if (cos > root22) {
            //right
            dir = kDirection_R;
        }
        else if (cos < -root22) {
            //left
            dir = kDirection_L;
        }
        else {
            float sin = sinf(angle);
            if (sin > root22) {
                //up
                dir = kDirection_U;
            }
            else {
                //down
                dir = kDirection_B;
            }
        }
        
        //swap
        
        int row = (int)(-m_touchBeginPoint.y / (float)kGridHeight + 0.5f);
        int col = m_touchBeginPoint.x  / kGridWidth + 0.5f;
        FMGameGrid * g1 = getNeighbor(row, col, kDirection_C);
        FMGameGrid * g2 = getNeighbor(row, col, dir);
        bool hasRoute = hasRouteToDirection(g1, dir);
        if (hasRoute && g2->isSwappable()) {
            CCPoint coord2 = g2->getCoord();
            int row2 = coord2.x;
            int col2 = coord2.y;
            if (isCoordTouchable(row2, col2)) {
                swapElements(g1, g2);
            }
        }
        else {
            FMSound::playEffect("tap.mp3", 0.01f, 0.5f);
            m_swapGrid1 = NULL;
            m_swapGrid2 = NULL;
            
            m_swapBegin = false;
            m_touchBegin = false;
            showIndicator(false);
            if (g1 && g1->getElement()) {
                switch (dir) { //
                    case kDirection_L:
                        g1->getElement()->playAnimation("BounceLeft"); //
                        break;
                    case kDirection_R:
                        g1->getElement()->playAnimation("BounceRight");
                        break;
                    case kDirection_U:
                        g1->getElement()->playAnimation("BounceUp"); //
                        break;
                    case kDirection_B:
                        g1->getElement()->playAnimation("BounceDown"); //
                        break;
                        
                    default:
                        break;
                }

            }
        }
    } 
} //

void FMGameNode::ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent)
{
    CCNode * offsetNode = m_gridParent->getChildByTag(1);
    CCPoint touchPoint = pTouch->getLocation();
    touchPoint = offsetNode->convertToNodeSpace(touchPoint);
#ifdef DEBUG
    if (m_isEditorMode) {
        return;
    }
#endif
    bool checkSurprise = true;
    if (getGamePhase() == kPhase_ItemSelecting) { 
        int row = (int)ceilf(-touchPoint.y / (float)kGridHeight - 0.5f);
        int col = touchPoint.x  / kGridWidth + 0.5f;
        if (isCoordExist(row, col) && isCoordTouchable(row, col)) {
            showSelectedGrids(true, row, col);
        }
        else {
            showSelectedGrids(false);
        }
        
        triggerItem(row, col);
        checkSurprise = false;
    }
    
//    if (checkSurprise && m_touchBegin && !m_swapBegin) {
//        int row = (int)ceilf(-m_touchBeginPoint.y / (float)kGridHeight - 0.5f);
//        int col = m_touchBeginPoint.x  / kGridWidth + 0.5f;
////        if (isCoordExist(row, col) && isCoordTouchable(row, col)) {
////            makeGridSurprise(true, row, col);
////        }
//    }
    m_touchBegin = false;
}

void FMGameNode::ccTouchCancelled(CCTouch *pTouch, CCEvent *pEvent)
{
    
}

#pragma mark - tutorials
void FMGameNode::setMapLimit(std::set<int> coords)
{
    resetMapLimit();
    for (std::set<int>::iterator it = coords.begin(); it != coords.end(); it++) {
        int index = *it;
        m_tutCoords.insert(index);
    }
}

void FMGameNode::resetMapLimit()
{
    m_tutCoords.clear();
}

void FMGameNode::setButtonLimit(std::set<int> indices)
{
    if (GAMEUI::isPaused()) {
        return;
    }
    for (int i=0; i<7; i++) {
        if (indices.find(i) != indices.end()) {
            m_buttons[i]->setEnabled(true);
        }
        else {
            m_buttons[i]->setEnabled(false);
        }
    }
}

void FMGameNode::resetButtonLimit()
{
    if (GAMEUI::isPaused()) {
        return;
    }
    for (int i=0; i<7; i++) {
        m_buttons[i]->setEnabled(true);
    }
}

CCPoint FMGameNode::getTutorialPosition(int index)
{
    switch (index) {
        case 0:
        {
            //move
            CCPoint wp = m_moveNode->convertToWorldSpace(m_moveNode->getAnchorPointInPoints());
            wp = ccpAdd(wp, ccp(0, 20));
            return wp;
        }
            break;
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        {
            CCPoint wp = m_boosterParent->getChildByTag(index-1)->convertToWorldSpace(CCPointZero);
            return wp;
        }
            break;
        case 7:
        {
            //boss target
//            CCPoint wp = m_bossMode->getChildByTag(3)->convertToWorldSpace(CCPointZero);
//            return wp;
        }
            break;
        case 8:
        {
            //harvest target
            CCSize size = m_modeNode[kGameMode_Harvest]->getParent()->getContentSize();
            CCPoint wp = m_modeNode[kGameMode_Harvest]->convertToWorldSpace(ccp(size.width * 0.5f, size.height * 0.5f));
            return wp;
        }
            break;
        case 9 :
        {
            CCPoint wp = m_boosterParent->convertToWorldSpace(CCPointZero);
            return wp;
        }
            break;
        default:
            break;
    }
    if (index >= 1000) {
        index -= 1000;
        for (std::map<int, elementTarget>::iterator it = m_targets.begin(); it != m_targets.end(); it++) {
            int ttype = it->first;
            if (ttype == index) {
                elementTarget target = it->second;
                int tindex = target.index;
                CCSize size = m_targetLabel[tindex]->getContentSize();
                CCPoint wp = m_targetLabel[tindex]->convertToWorldSpace(ccp(size.width * 0.5f, 30.f));
                return wp;
            }
        }
    }
    return CCPointZero;
}

#pragma mark - ui
void FMGameNode::updateHarvestTargets()
{
    switch (m_gameMode) {
        case kGameMode_Classic:
        {
            std::map<int, elementTarget>::iterator it = m_targets.begin();
            std::stringstream ss;
            for (; it != m_targets.end(); it++) {
                ss.str("");
                elementTarget target = it->second;
                int index = target.index;
                if (index < 4) {
                    int need = target.target - target.harvested;
                    ss <<  need;
                    m_targetLabel[index]->setString(ss.str().c_str());
                    if (target.harvested >= target.target) {
                        m_targetLabel[index]->setVisible(false);
                    }
                    else {
                        m_targetLabel[index]->setVisible(true);
                    }
                }
            }
            
        }
            break;
        case kGameMode_Harvest:
        {
            int totalHarvested = 0;
            int totalTarget = 0;
            for (std::map<int, elementTarget>::iterator it = m_targets.begin(); it != m_targets.end(); it++) {
                elementTarget & t = it->second;
                totalHarvested += t.harvested;
                totalTarget += t.target;
            }
            CCLabelBMFont * targetLabel = (CCLabelBMFont *) m_modeNode[kGameMode_Harvest]->getChildByTag(10);
            if (totalHarvested >= totalTarget) {
                //win
                targetLabel->setVisible(false);
            }
            else {
                std::stringstream ss;
                ss.str("");
                ss << (totalTarget - totalHarvested);
                targetLabel->setString(ss.str().c_str());
                targetLabel->setVisible(true);
            }
            
            float percent = totalHarvested / (float)totalTarget;
            if (percent > 1.f) {
                percent = 1.f;
            }
            float jellyScale = 0.5f + 0.5f * percent;
            CCNode * jellyParent = m_modeNode[kGameMode_Harvest]->getChildByTag(25);
            NEAnimNode * jelly = (NEAnimNode *)jellyParent->getChildByTag(0);
            jellyParent->setScale(jellyScale);
            jelly->playAnimation("hit");
        }
            break;
        default:
            break;
    }
    

//    int percent = totalHarvested * 100.f / (float) totalTarget;
//    if (m_gameMode == kGameMode_Boss) {
//        if (percent > 100) {
//            percent = 100;
//        }
//        percent = 100 - percent;
//        
//        m_bossState = 6;
//        int p = percent;
//        while (p > 0) {
//            p -= 20;
//            m_bossState--;
//            CCAssert(m_bossState > 0, "ddd");
//        }
//    }
//    else if (m_gameMode == kGameMode_Harvest) {
//        if (percent > 100) {
//            percent = 100;
//        } 
//        
//        CCLabelBMFont * harvested = (CCLabelBMFont *)m_vegeMode->getChildByTag(2);
//        ss.str("");
//        ss << totalHarvested << "/" << totalTarget;
//        harvested->setString(ss.str().c_str());
//    }
//    ss.str("");
//    ss << percent << "%";
//    m_percentageLabel->setString(ss.str().c_str());
}

void FMGameNode::updateMoves()
{
    NEAnimNode * node = (NEAnimNode *)m_moveNode->getChildByTag(0);
    CCLabelBMFont * label = (CCLabelBMFont *)node->getNodeByName("label");
    if (m_leftMoves < 0) {
        label->setString("0");
    }
    else {
        std::stringstream ss;
        if (m_leftMoves > 999) {
            ss << "∞";
        }else{
            ss << m_leftMoves;
        }
        label->setString(ss.str().c_str());
    }
}

void FMGameNode::updateBoostersTimer(float delta)
{
//    FMDataManager * manager = FMDataManager::sharedManager();
//    for (int i=0; i<5; i++) {
//        CCProgressTimer * timer = (CCProgressTimer *)m_boosterParent->getChildByTag(i)->getChildByTag(3);
//        int remainTime = manager->getBoosterTime(i);
//        if (remainTime == -1) {
//            timer->setPercentage(0.f);
//            continue;
//        }
//        remainTime = manager->getRemainTime(remainTime);
//        if (remainTime == 0) {
//            manager->stopBoosterTimer(i);
//            int amount = manager->getBoosterAmount(i);
//            manager->setBoosterAmount(i, amount+1);
//            updateBoosters();
//            continue;
//        }
//        
//        int defaultTime = manager->getBoosterDefaultTime(i);
//        float percent = remainTime * 100.f / (float)defaultTime;
//
//        timer->setPercentage(percent);
//    }
}

const char * FMGameNode::getBoosterSkin(kGameBooster type)
{
    switch (type) {
        case kBooster_Harvest1Grid:
        {
            return "Spoon";
        }
            break;
        case kBooster_Harvest1Row:
        {
            return "Cat";
        }
            break;
        case kBooster_PlusOne:
        {
            return "Sugar";
        }
            break;
        case kBooster_Harvest1Type:
        {
            return "Straw";
        }
            break;
        case kBooster_CureRot:
        {
            return "Cure";
        }
            break;
        case kBooster_MovePlusFive:
        {
            return "+5";
        }
            break;
        case kBooster_Shuffle:
        {
            return "Shuffle";
        }
            break;
        case kBooster_Locked:
        {
            return "Locked";
        }
            break;
        case kBooster_4Match:
        {
            return "4Match";
        }
            break;
        case kBooster_5Line:
        {
            return "5Line";
        }
            break;
        case kBooster_TCross:
        {
            return "TCross";
        }
            break;
        default:
            break;
    }
}

void FMGameNode::updateBoosters()
{
    FMDataManager * manager = FMDataManager::sharedManager(); 
    for (int i = 0; i< 6; i++) {
        CCAnimButton * boosterButton = (CCAnimButton *)m_boosterParent->getChildByTag(i)->getChildByTag(1);
        NEAnimNode * boosterIcon = (NEAnimNode *)boosterButton->getAnimNode()->getNodeByName("Booster");
        NEAnimNode * boosterBoard = (NEAnimNode *)boosterButton->getAnimNode()->getNodeByName("Count");
        NEAnimNode * boosterClock = (NEAnimNode *)boosterButton->getAnimNode()->getNodeByName("Clock");
        CCLabelBMFont * boosterCount = (CCLabelBMFont *)boosterBoard->getNodeByName("Label");
        kGameBooster type = (kGameBooster)i;
        int count = manager->getBoosterAmount(type);
        bool locked = manager->isBoosterLocked(type);
#ifdef DEBUG
        if (m_cheatMode) {
            count = 9;
            locked = false;
        }
#endif
        if (locked) {
            type = kBooster_Locked;
        }
        bool isTimingType = manager->isBoosterTiming(type);
        if (!locked) {
            const char * skinName = getBoosterSkin(type);
            boosterIcon->useSkin(skinName);
            boosterBoard->setVisible(true);
            
            if (count <= 0) {
                if (isTimingType) {
                    boosterClock->setVisible(true);
                }
                else {
                    boosterClock->setVisible(false);
                }
                boosterBoard->useSkin("None");
            }
            else {
                boosterClock->setVisible(false);
                boosterBoard->useSkin("Have");
                CCString * s = CCString::createWithFormat("%d", count);
                boosterCount->setString(s->getCString());
            }
        }
        else {
            boosterBoard->setVisible(false);
            boosterClock->setVisible(false);
            boosterIcon->useSkin("Locked");
        }
    } 
}

std::string FMGameNode::getBorderFileName(int flag)
{
    std::stringstream ss;
    ss.str("");
    ss << (flag & 0x1000 ? "1" : "0");
    ss << (flag & 0x0100 ? "1" : "0");
    ss << (flag & 0x0010 ? "1" : "0");
    ss << (flag & 0x0001 ? "1" : "0");
    return ss.str();
}

void FMGameNode::updateBackGrids()
{
    static int gridNum = kGridNum+1;
    static int outNum = kGridNum+2;
    int outterData[outNum][outNum];
    memset(outterData, 0, outNum * outNum * sizeof(int));
    for (int i=1; i<=kGridNum; i++) {
        for (int j=1; j<=kGridNum; j++) {
            FMGameGrid * grid = getNeighbor(i-1, j-1, kDirection_C);
            if (grid->getGridType() != kGridNone) {
                outterData[i][j] = 1;
            }
        }
    }
    

    for (int i=0; i<gridNum; i++) {
        for (int j=0; j<gridNum; j++) {
            int flag = 0x0000;
            flag |= (outterData[i][j] ? 0x1000 : 0);
            flag |= (outterData[i][j+1] ? 0x0100 : 0);
            flag |= (outterData[i+1][j] ? 0x0010 : 0);
            flag |= (outterData[i+1][j+1] ? 0x0001 : 0);
            std::string fileName = FMGameNode::getBorderFileName(flag);
            bool visible = flag != 0x0000;
            
            NEAnimNode * gridBG = (NEAnimNode *)m_borderGridParent->getChildByTag(i * gridNum + j);
            if (!gridBG) {
                gridBG = NEAnimNode::createNodeFromFile("FMGrid.ani");
                gridBG->setTexture(m_borderGridParent->getTexture());
                gridBG->setOpacity(0);
                gridBG->setDelegate(NULL);
                m_borderGridParent->addChild(gridBG, -1, i* gridNum+j);
            }
            gridBG->setSmoothPlaying(true);
            gridBG->playAnimation(fileName.c_str());
            gridBG->setAnchorPoint(ccp(1.f, 0.f));
            gridBG->setVisible(visible);
            gridBG->setPosition(ccp(j * kGridWidth, - i * kGridHeight));
        }
    }
    
    updateMarquee();
}

kGameDirection FMGameNode::getDirection(kGameDirection dir, bool inverse)
{
    if (!inverse) {
        return dir;
    }
    else {
        if (dir == kDirection_None || dir == kDirection_Center) {
            return dir;
        }
        return (kGameDirection)(9-dir);
    }
}

kGameDirection FMGameNode::getOutputDirection(int flag, kGameDirection inputDirection)
{
    kGameDirection dir = kDirection_None;
    static bool inverse = false;
    switch (flag) {
        case 0x0000:
            break;
        case 0x0001:
            dir = kDirection_R;
            break;
        case 0x0010:
            dir = kDirection_B;
            break;
        case 0x0011:
            dir = kDirection_R;
            break;
        case 0x0100:
            dir = kDirection_U;
            break;
        case 0x0101:
            dir = kDirection_U;
            break;
        case 0x0110:
            dir = inputDirection == kDirection_L ? kDirection_B : kDirection_U;
            break;
        case 0x0111:
            dir = kDirection_U;
            break;
        case 0x1000:
            dir = kDirection_L;
            break;
        case 0x1001:
            dir = inputDirection == kDirection_U ? kDirection_L : kDirection_R;
            break;
        case 0x1010:
            dir = kDirection_B;
            break;
        case 0x1011:
            dir = kDirection_R;
            break;
        case 0x1100:
            dir = kDirection_L;
            break;
        case 0x1101:
            dir = kDirection_L;
            break;
        case 0x1110:
            dir = kDirection_B;
            break;
        case 0x1111:
            break;
        default:
            break;
    }
    return getDirection(dir, inverse);
}

bool isCrossBorder(int flag)
{
    return flag == 0x0110 || flag == 0x1001;
}

void FMGameNode::playMarquee(bool play)
{
    for (std::vector<FMLoopGroup *>::iterator it = m_marquees.begin(); it != m_marquees.end(); it++) {
        FMLoopGroup * g = *it;
        if (play) {
            g->playMarquee();
        }
        else {
            g->stopMarquee();
        }
    }
}

void FMGameNode::updateMarquee()
{
    for (std::vector<FMLoopGroup *>::iterator it = m_marquees.begin(); it != m_marquees.end(); it++) {
        FMLoopGroup * g = *it;
        delete g;
    }
    m_marquees.clear();
    static int gridNum = kGridNum+1;
    static int outNum = kGridNum+2;
    int outterData[outNum][outNum];
    bool checkFlag[gridNum][gridNum];
    memset(outterData, 0, outNum * outNum * sizeof(int));
    memset(checkFlag, false, gridNum * gridNum * sizeof(bool));
    for (int i=1; i<=kGridNum; i++) {
        for (int j=1; j<=kGridNum; j++) {
            FMGameGrid * grid = getNeighbor(i-1, j-1, kDirection_C);
            if (grid->getGridType() != kGridNone) {
                outterData[i][j] = 1;
            }
        }
    }
    

    std::stringstream fileName;
    for (int i=0; i<gridNum; i++) {
        for (int j=0; j<gridNum; j++) {
            if (checkFlag[i][j]) {
                continue;
            }
            int flag = 0x0000;
            flag |= (outterData[i][j] ? 0x1000 : 0);
            flag |= (outterData[i][j+1] ? 0x0100 : 0);
            flag |= (outterData[i+1][j] ? 0x0010 : 0);
            flag |= (outterData[i+1][j+1] ? 0x0001 : 0);

            checkFlag[i][j] = true;
            kGameDirection dir = getOutputDirection(flag);
            if (dir != kDirection_None) {
                FMLoopGroup * loop = new FMLoopGroup;
                NEAnimNode * gridBG = (NEAnimNode *)m_borderGridParent->getChildByTag(i * gridNum + j);
                NEAnimNode * neighbor = gridBG;
                int r = i;
                int c = j;
                do {
                    MarqueeData data;
                    data.node = neighbor;
                    std::string fileName = getBorderFileName(flag);
                    std::stringstream ss;
                    ss << fileName;
                    data.normalFileName = ss.str();
                    ss << "b";
                    if (isCrossBorder(flag)) {
                        ss << dir;
                    }
                    
                    data.fileName = ss.str();
                    loop->m_borderNodes.push_back(data); 
                    CCPoint coord = getNeighborCoord(r, c, dir);
                    r = coord.x;
                    c = coord.y;
                    checkFlag[r][c] = true;
                    CCLog("check flag %d %d", r, c);
                    flag = 0x0000;
                    flag |= (outterData[r][c] ? 0x1000 : 0);
                    flag |= (outterData[r][c+1] ? 0x0100 : 0);
                    flag |= (outterData[r+1][c] ? 0x0010 : 0);
                    flag |= (outterData[r+1][c+1] ? 0x0001 : 0);
                    
                    neighbor = (NEAnimNode *)m_borderGridParent->getChildByTag(r * gridNum + c);
                    dir = getOutputDirection(flag, dir);
                } while (neighbor != gridBG);
                m_marquees.push_back(loop);
            }
        }
    }
}



int FMGameNode::getBaseScore(kElementType type)
{
    if ((type > 0 && type <= 12)) {
        return 50;
    }
//    else if (type == kElement_Grow1 || type == kElement_Egg3 || FMGameElement::isGhostType(type)) {
//        return 150;
//    }
//    else if (type == kElement_Drop){
//        return 200;
//    }
//    else if (type == kElement_ChangeColor){
//        return 100;
//    }
    else {
        return 0;
    }
}

int FMGameNode::getHarvestScore(kElementType type)
{
    int baseScore = getBaseScore(type);
    if (m_targets.find(type) != m_targets.end()) {
        return baseScore * 2;
    }
    else {
        return baseScore;
    }
}

void FMGameNode::addScore(int score)
{
    m_score += score;
}

void FMGameNode::setScoreBar(float percentage)
{
    if (percentage > 1.f) {
        percentage = 1.f;
    }
    if (percentage < 0.f) {
        percentage = 0.f;
    }
    CCSize size = m_scorebar->getOriginalSize();
    static float min = 0.05f * size.width;
    static float max = size.width;
    float v = ( max - min ) * percentage + min;
    m_scorebar->setPosition(ccp(v - size.width, 0.f));
}

void FMGameNode::updateScorebar(float delta)
{
    if (m_gameMode == kGameMode_Harvest) {
        int total = 0;
        int totalTarget = 0;
        for (std::map<int, elementTarget>::iterator it = m_targets.begin(); it != m_targets.end(); it++) {
            elementTarget & t = it->second;
            total += t.harvested;
            totalTarget += t.target;
        }
        float t = total / (float)totalTarget;
        if (t > 1.f) {
            //don't exceed 100%
            t = 1.f;
        }
        setScoreBar(t);
    }
    else {
        if (m_showScore < m_score) {
            int add = delta * 1000.f * 3.f;
            m_showScore += add;
            if (m_showScore > m_score) {
                m_showScore = m_score;
            }
            std::string str = FMDataManager::sharedManager()->getDollarString(m_showScore);
            CCString * s;
#ifdef BRANCH_CN
            s = CCString::createWithFormat("%d",m_showScore);
#else
            s = CCString::createWithFormat("%s", str.c_str());
#endif
            m_scoreLabel->setString(s->getCString());
        }
        
        if (m_starNumCurrent < 3) {
            if (m_score >= m_scoreCaps[m_starNumCurrent]) {
                m_star[m_starNumCurrent]->playAnimation("Get");
                FMSound::playEffect("getstar.mp3");
                m_starNumCurrent++;
                m_starNum = m_starNumCurrent;
            }
        }
    }

}

void FMGameNode::resetScorebar()
{
    m_starNum = 0;
    m_starNumCurrent = 0;
    FMDataManager * manager = FMDataManager::sharedManager();
    bool showguide = (manager->getWorldIndex() == 0 && manager->getLevelIndex() < 3 &&  !manager->isQuest());
    for (int i = 0; i<3; i++) {
        m_star[i]->playAnimation("Init");
        m_star[i]->setVisible(!showguide);
    }
    
    m_scoreLabel->setString("0");
    m_scoreLabel->setVisible(!showguide);
    
    CCNode * n2 = m_levelStatus->getChildByTag(3);
    n2->setVisible(showguide);
    
    switch (m_gameMode) {
        case kGameMode_Harvest:
        {
            setScoreBar(0.f);
        }
            break;
            
        default:
            break;
    }
//    if (m_scorebar && m_scorebar->getParent()) {
//        m_scorebar->removeFromParent();
//    }
//    
//    static const char * scoreFile[3] = {
//        "scorebar.png",
//        "scorebarboss.png",
//        "scorebarharvest.png"
//    };
//
//    const char * scoreFileName = scoreFile[m_gameMode < kGameMode_Boss ? 0 : m_gameMode-1]; 
//    m_scorebar = CCScale9Sprite::createWithSpriteFrameName(scoreFileName, CCRect(4.f, 0.f, 173.f, 8.f));
//    m_scorebar->setPosition(ccp(3.f, 3.f));
//    m_scorebar->setPreferredSize(CCSize(181.f, 8.f));
//    m_scorebar->setAnchorPoint(ccp(0.f, 0.f));
//    //m_scorebarParent->addChild(m_scorebar, 0, 0);
//    //CCNode * flowersParent = m_scorebarParent->getChildByTag(1);
////    flowersParent->setVisible(m_gameMode == kGameMode_Classic || m_gameMode == kGameMode_Collection);
////    m_scorebarParent->reorderChild(flowersParent, 1);
//    
//    if (m_gameMode == kGameMode_Boss || m_gameMode == kGameMode_Harvest) {
//        
//    }
//    else {
////        CCScale9Sprite * scorebar = (CCScale9Sprite *)m_scorebarParent->getChildByTag(0);
////        scorebar->setPreferredSize(CCSize(scorebarMin, scorebarHeight));
////        
////        CCNode * parent = m_scorebarParent->getChildByTag(1);
////
////        int maxScoreCap = m_scoreCaps[2] + scoreCapMaxAdd;
////        for (int i=0; i<3; i++) {
////            NEAnimNode * star = (NEAnimNode *)parent->getChildByTag(i);
////            star->playAnimation("Init");
//////            CCSprite * star = (CCSprite *)parent->getChildByTag(i);
//////            CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("star_grey.png");
//////            star->setDisplayFrame(frame);
////            float t = m_scoreCaps[i] / (float)maxScoreCap;
////            star->setPosition(ccp(t * (scorebarMax - scorebarMin) + scorebarMin, 0));
////        }
//    }
}

void FMGameNode::uiSlide(bool movein)
{
    if (movein) {
        setGamePhase(kPhase_NoInput);
        pause();
        CCBAnimationManager * anim = (CCBAnimationManager *)m_gameUI->getUserObject();
        anim->runAnimationsForSequenceNamed("SlideIn");
        
        CCSize s = CCDirector::sharedDirector()->getWinSize();
        m_gridParent->setPosition(ccp(-s.width * 1.5f, 0));
        CCMoveTo * m1 = CCMoveTo::create(0.6f, ccp(0, 0));
//        CCEaseExponentialOut * e1 = CCEaseExponentialOut::create(m1);
        CCCallFunc * c1 = CCCallFunc::create(this, callfunc_selector(FMGameNode::mapSlideInDone));
        CCSequence * seq = CCSequence::create(m1, c1, NULL);
        m_gridParent->runAction(seq);
        m_isLevelFirstIn = true;
    }
    else {
        setGamePhase(kPhase_NoInput);
        pause();
        CCBAnimationManager * anim = (CCBAnimationManager *)m_gameUI->getUserObject();
        anim->runAnimationsForSequenceNamed("SlideOut");

        CCSize s = CCDirector::sharedDirector()->getWinSize();
        m_gridParent->setPosition(ccp(0, 0));
        CCMoveTo * m1 = CCMoveTo::create(0.6f, ccp(s.width * 1.5f, 0));
//        CCEaseOut * e1 = CCEaseOut::create(m1, 2.f);
        CCCallFunc * c1 = CCCallFunc::create(this, callfunc_selector(FMGameNode::mapSlideOutDone));
        CCSequence * seq = CCSequence::create(m1, c1, NULL);
        m_gridParent->runAction(seq);
    }
}


void FMGameNode::checkTargetComplete()
{
    if (m_targetsCompleted) {
        return;
    }
    
    bool allDone = true;
    if (m_gameMode == kGameMode_Boss || m_gameMode == kGameMode_Harvest) {
        int total = 0;
        int totalNeed = 0;
        for (std::map<int, elementTarget>::iterator it = m_targets.begin(); it != m_targets.end(); it++) {
            elementTarget& t = it->second;
            total += t.harvested;
            totalNeed += t.target;
        }
        if (total < totalNeed) {
            allDone = false;
        }
    }
    else {
        for (std::map<int, elementTarget>::iterator it = m_targets.begin(); it != m_targets.end(); it++) {
            elementTarget& t = it->second;
            if (t.harvested < t.target) {
                allDone = false;
                break;
            }
        }
    }
    if (!m_targetsCompleted && allDone) {
        m_targetsCompleted = true;
        if (!checkWinner()) {
            switch (m_gameMode) {
                case kGameMode_Classic:
                {
                    //goto mania mode
                    if (m_enableManiaMode) {
                        maniaMode();
                        FMUIGreenPanel * panel = (FMUIGreenPanel *)m_greenPanel;
                        panel->setClassState(kPanelManiaMode);
                        panel->setVisible(true);
//                        CCCallFunc * call = CCCallFunc::create(this, callfunc_selector(FMGameNode::goalSlideDone));
//                        CCSequence * seq = CCSequence::create(panel->slide(), call, NULL);
//                        m_greenPanel->runAction(seq);
                    }else{
                        levelComplete();
                    }
                }
                    break;
                default:
                    break;
            }
        }
    }
    

}

bool FMGameNode::checkWinner()
{
    if (m_gameEnd) {
        return true;
    }
    if (m_targetsCompleted) {
        if (m_leftMoves <= 0 || (m_gameMode == kGameMode_Boss || m_gameMode == kGameMode_Harvest)) {
            levelComplete();
            return true;
        }
        return false;
    }
    else if (m_leftMoves <= 0){
//        levelFailed();
        setGamePhase(kPhase_NoInput);
        FMUIGreenPanel * panel = (FMUIGreenPanel *)m_greenPanel;
        panel->setClassState(kPanelFail);
        panel->setVisible(true);

        return true;
    }
    else {
        return false;
    }
}

void FMGameNode::maniaMode()
{
    m_scoreBeforeMania = getCurrentScore();
    m_maniaModeBegin = true;
//    FMSound::playMusic("maniamode.mp3");
    pause();
//    m_colorLayer->setColor(ccc3(0xff, 0xff, 0x59));
    m_colorLayer->setOpacity(0);
//    CCFadeTo * f = CCFadeTo::create(0.25f, 128);
//    m_colorLayer->runAction(f);
    
    int outterData[10][10];
    memset(outterData, 0, 100 * sizeof(int));
    for (int i=1; i<=kGridNum; i++) {
        for (int j=1; j<=kGridNum; j++) {
            FMGameGrid * grid = getNeighbor(i-1, j-1, kDirection_C);
            if (grid->getGridType() != kGridNone) {
                outterData[i][j] = 1;
                int odd = (int)(i + j) % 2 == 1;
                if (odd) {
                    grid->getAnimNode()->playAnimation("GridManiaLight");
                }
                else{
                    grid->getAnimNode()->playAnimation("GridManiaDark");
                }
            }
        }
    }
    
    std::stringstream fileName;
    
    for (int i=0; i<9; i++) {
        for (int j=0; j<9; j++) {
            fileName.str("");
            fileName << (outterData[i][j] ? "1" : "0");
            fileName << (outterData[i][j+1] ? "1" : "0");
            fileName << (outterData[i+1][j] ? "1" : "0");
            fileName << (outterData[i+1][j+1] ? "1" : "0");
            bool visible = strcmp(fileName.str().c_str(), "0000") != 0;
            if (visible) {
//                fileName << "a";
            }
            NEAnimNode * gridBG = (NEAnimNode *)m_borderGridParent->getChildByTag(i * 9 + j);
            bool n = (i % 2 + j % 2) % 2 == 0;
            int startframe = n ?  30 : 0;
            gridBG->playAnimation(fileName.str().c_str(), startframe);
            gridBG->setAnchorPoint(ccp(1.f, 0.f));
            gridBG->setVisible(visible);
            gridBG->setPosition(ccp(j * kGridWidth, - i * kGridHeight));
        }
    }
}


static bool fromLeft = false;
void FMGameNode::maniaPlusOne()
{
    setGamePhase(kPhase_HeroFlying);
    m_animChecker->cleanCheckingAnims();
    m_animChecker->cleanGrids();
    m_animChecker->resetPhase();
    m_animChecker->setMatchEnd(false);
//    for (int i=0; i<8; i++) {
//        for (int j=0; j<8; j++) {
//            FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
//            if (grid->getElement()) {
//                kElementType type = grid->getElement()->getElementType();
//                if (m_targets.find(type) != m_targets.end()) {
//                    grid->getElement()->addValue(1);
//                    m_animChecker->addAnimNode(grid->getElement()->getAnimNode());
//                }
//            }
//        }
//    }
}

bool FMGameNode::maniaUseMove()
{
    NEAnimNode * node = (NEAnimNode *)m_moveNode->getChildByTag(0);
    CCLabelBMFont * label = (CCLabelBMFont *)node->getNodeByName("label");
    if (m_leftMoves > 0) {
        m_leftMoves--;
        updateMoves();
        CCScaleTo * s = CCScaleTo::create(0.3f, 1.35f);
        CCEaseElasticOut * ease = CCEaseElasticOut::create(s);
        CCScaleTo * s2 = CCScaleTo::create(0.5f, 1.f);
        CCSequence * seq = CCSequence::create(ease, s2, NULL);
        label->runAction(seq);
        return true;
    }
    else {
        return false;
    }
}

//void FMGameNode::maniaFireworkCallback(FMGameGrid *grid)
//{
//    grid->setGridBonus(kBonus_Cross);
//    triggerGridBonus(grid);
//}

void FMGameNode::useItemMode(bool useItem)
{
    bool use = useItem;
    m_colorLayer->setColor(ccc3(0x7e, 0x00, 0xff));
    if (!m_maniaModeBegin) {
        if (use) {
            m_colorLayer->setOpacity(0);
            CCFadeTo * f = CCFadeTo::create(0.25f, 128);
            m_colorLayer->runAction(f);
            FMSound::playEffect("selectitem.mp3");
            
            for (int i=1; i<=kGridNum; i++) {
                for (int j=1; j<=kGridNum; j++) {
                    FMGameGrid * grid = getNeighbor(i-1, j-1, kDirection_C);
                    if (grid->getGridType() != kGridNone) {
                        int odd = (int)(i + j) % 2 == 1;
                        if (odd) {
                            grid->getAnimNode()->playAnimation("GridItemLight");
                        }
                        else{
                            grid->getAnimNode()->playAnimation("GridItemDark");
                        }
                    }
                }
            }
        }
        else {
            m_colorLayer->setOpacity(128);
            CCFadeTo * f = CCFadeTo::create(0.25f, 0);
            m_colorLayer->runAction(f);
            
            for (int i=1; i<=kGridNum; i++) {
                for (int j=1; j<=kGridNum; j++) {
                    FMGameGrid * grid = getNeighbor(i-1, j-1, kDirection_C);
                    if (grid->getGridType() != kGridNone) {
                        int odd = (int)(i + j) % 2 == 1;
                        if (odd) {
                            grid->getAnimNode()->playAnimation("GridLight");
                        }
                        else{
                            grid->getAnimNode()->playAnimation("GridDark");
                        }
                    }
                }
            }
        }
    }
    
    playMarquee(use);
    updateBoosters();
}

void FMGameNode::tractorCallback(FMGameGrid *grid)
{
//    if (m_animChecker->isGridInGroup(grid)) {
//        if (grid->getElement()) {
//            FMGameElement * e = grid->getElement();
////            if (e->isSnailOn() && e->getSnailStatus() == 0) {
////                grid->getElement()->hitSnail(m_combo+1);
////                return;
////            }
////            
//            kElementType type = e->getElementType();
//            if (FMGameElement::isGhostType(type)) {
//                grid->getElement()->addPhase(m_combo+1);
//                gridNextPhase(m_animChecker, grid);
//            }
//            else {
//                if (m_targets.find(type) != m_targets.end()) {
//                    gridNextPhase(m_animChecker, grid);
//                }
//                else {
//                    //猫道具消除掉非目标果冻时加分
//                    addScore(getBaseScore(type));
//                    //run away
//                    CCPoint coord = grid->getCoord();
//                    CCPoint target = getPositionForCoord(coord.x, 12);
//                    CCPoint from = getPositionForCoord(coord.x, coord.y);
//                    float length = target.x - from.x;
//                    float time = length / 300.f;
//                    CCMoveTo * moveAct = CCMoveTo::create(time, target);
//                    CCCallFuncO * remove = CCCallFuncO::create(this, callfuncO_selector(FMGameNode::removeElement), e);
//                    CCSequence * seq = CCSequence::create(moveAct, remove, NULL);
//                    m_animChecker->addCCNode(e->getAnimNode(), seq, "cc flag 22");
//                    e->getAnimNode()->playAnimation("ShuffleMove");
//                    grid->setOccupyElement(NULL);
//                }
//            }
//        }
//    }
//    
//    //add value to neighbor rows
//    CCPoint p = grid->getCoord();
//    int row = p.x;
//    int col = p.y;
//        for (int j = -1; j <2; j+=2) {
//            FMGameGrid * u = getNeighbor(row + j, col, kDirection_C);
//            if (u) {
//                FMGameElement * e = u->getElement();
//                if (e && e->isValueAddable()) {
//                    if (m_targets.find(e->getElementType()) != m_targets.end()) {
//                        e->addValue(1);
//                    }
//                }
//            }
//        }
}

void FMGameNode::elementStrawHarvest(FMGameElement *element)
{
    kElementType type = element->getElementType();
    if (m_targets.find(type) != m_targets.end()) {
        
    }
}

void FMGameNode::pigCallback()
{
    CCNode * offsetNode = m_gridParent->getChildByTag(1);
    NEAnimNode * strawAnim = (NEAnimNode *)offsetNode->getChildByTag(kTag_Straw);
    strawAnim->playAnimation("Sucking");
    strawAnim->setAutoRemove(true);
    CCNode * targetNode = strawAnim->getNodeByName("1");
    CCPoint targetPoint = targetNode->convertToWorldSpace(CCPointZero);
    targetPoint = offsetNode->convertToNodeSpace(targetPoint);
    
    FMMatchGroup * mg = m_animChecker;
    float delay = 0.0f;
    int score = 0;
    for (std::set<FMGameGrid *>::iterator it = mg->m_grids->begin(); it != mg->m_grids->end(); it ++) {
        FMGameGrid * g = *it;
        FMGameElement * e = g->getElement();
        score += getHarvestScore(e->getElementType());
        delay = (FMDataManager::getRandom() % 1000) * 0.00033f;
        e->playAnimation("Dropping");
        CCDelayTime * delayAct = CCDelayTime::create(delay);
        CCMoveTo * moveAct = CCMoveTo::create(0.25f, targetPoint);
        NEAnimationDoneAction * animAct = NEAnimationDoneAction::create(e->getAnimNode(), "Suck");
        CCCallFuncO * f = CCCallFuncO::create(this, callfuncO_selector(FMGameNode::triggerAddValueToTarget), e);
        CCSequence * s = CCSequence::create(delayAct, moveAct, animAct, f, NULL);
        m_animChecker->addCCNode(e->getAnimNode(), s, "cc flag 23");
         
    }
    //吸管道具消除果冻时加分
    addScore(score);
    
    for (std::set<FMGameGrid *>::iterator it = mg->m_grids->begin(); it != mg->m_grids->end(); it ++) {
        FMGameGrid * g = *it;
        FMGameElement * e = g->getElement();
        if (e) {
//            if (e->isValueAddable()) {
//                if (g->getGridBonus() != kBonus_None) {
//                    triggerGridBonus(g);
//                }                
//            }
            g->setOccupyElement(NULL);
        } 
    }
         
    
//    //shake all elements
//    for (int i=0; i<8; i++) {
//        for (int j=0; j<8; j++) {
//            FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
//
//            if (grid->isExistMovableElement()) {
//                bool pushed = false;
//                if (i >= 2 && i <= 5 && j >=2  && j<=5) {
//                    pushed = true;
//                    if ((i == 2 || i == 5) && (j == 2 || j == 5)) {
//                        pushed = false;
//                    }
//                }
//                if (pushed) {
//                    //pushed
//                    FMGameElement * e = grid->getElement();
//                    e->playAnimation("Pushed");
//                    m_animChecker->addAnimNode(e->getAnimNode());
//                }
//                else {
//                    FMGameElement * e = grid->getElement();
//                    float jumpheight = FMDataManager::getRandom() % 30 + 10;
//                    e->playAnimation("SurpriseDropping");
//                    CCJumpBy * j = CCJumpBy::create(0.5f, ccp(0.f, 0.f), jumpheight, 1);
//                    CCCallFunc * f = CCCallFunc::create(e, callfunc_selector(FMGameElement::makeNormal));
//                    CCSequence * s = CCSequence::create(j, f, NULL);
//                    m_animChecker->addCCNode(e->getAnimNode(), s);
//                }
//            }
//        }
//    }
//    
//    //shake the map
//    CCMoveBy * m1 = CCMoveBy::create(0.05f, ccp(3.f, 4.f));
//    CCMoveBy * m2 = CCMoveBy::create(0.05f, ccp(-5.f, -2.f));
//    CCMoveBy * m3 = CCMoveBy::create(0.05f, ccp(4.f, 3.f));
//    CCMoveBy * m4 = CCMoveBy::create(0.05f, ccp(-3.f, -3.f));
//    CCMoveTo * m5 = CCMoveTo::create(0.05f, CCPointZero);
//    CCSequence * m = CCSequence::create(m1, m2, m3, m4, m5, NULL);
//    m_gridParent->runAction(m);
}
bool FMGameNode::isSellingBooster(int type)
{
    CCArray * array = (CCArray*)m_levelData->objectForKey("sellingItems");
    if (!array) {
        array = CCArray::create();
        array->addObject(CCNumber::create(6));
        array->addObject(CCNumber::create(0));
        array->addObject(CCNumber::create(7));
    }
    for (int i = 0; i < array->count(); i++) {
        if (type == ((CCNumber*)array->objectAtIndex(i))->getIntValue()) {
            return true;
        }
    }
    return false;
}

bool FMGameNode::isBoosterUsable(kGameBooster type)
{
#ifdef DEBUG
    if (m_cheatMode) {
        return true;
    }
#endif
    FMDataManager * manager = FMDataManager::sharedManager();
    if (manager->getTutorialBooster() == type) {
        return true;
    }
    if (manager->isBoosterLocked(type)) {
        FMSound::playEffect("error.mp3", 0.01f, 0.5f);
        return false;
    }
    
    int amount = manager->getBoosterAmount(type);
    if (amount > 0) {
        return true;
    }
    else {
        FMUIBooster * window = (FMUIBooster *)manager->getUI(kUI_Booster);
        window->setClassState(kUIBooster_Buy);
        window->setBoosterType(type);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
    }
    return false;
}

void FMGameNode::useItem(kGameBooster type)
{
#ifdef DEBUG
    if (m_cheatMode) {
        setCheated(true);
        return;
    }
#endif
    //use item
    FMDataManager * manager = FMDataManager::sharedManager();
    if (manager->getTutorialBooster() == type) {
        manager->settutorialBooster(-1);
        return;
    }
    int amount = manager->getBoosterAmount(m_usingItem); 
    amount--;
    if (amount <= 0) {
        amount = 0;
        if (manager->isBoosterTiming(type)) {
            manager->resetBoosterTimer(m_usingItem);
        }
    }
    manager->setBoosterAmount(m_usingItem, amount);
    if (amount == 0) {
        if (!manager->isTutorialDone(9)) {
            //check boost empty
            bool allEmpty = true;
            for (int i=0; i<5; i++) {
                if (!manager->isBoosterLocked(i)) {
                    int n = manager->getBoosterAmount(i);
                    if (n != 0) {
                        allEmpty = false;
                        break;
                    }
                }
            }
            if (allEmpty) {
                manager->checkNewTutorial("boostempty");
                manager->tutorialBegin();
            }
        }
    }
    m_boosterUsed[m_usingItem]++;
    
    updateBoosters();
}
 
void FMGameNode::triggerItem(int row, int col)
{
    m_animChecker->cleanCheckingAnims();
    m_animChecker->cleanGrids();
    
    for (int i=0; i<kGridNum; i++) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * g = getNeighbor(i, j, kDirection_C);
            FMGameElement * e = g->getElement();
            if (e && e->isSelected()) {
                if (m_usingItem == kBooster_Shuffle) {
                    if (m_swapGrid1 == NULL) {
                        m_swapGrid1 = g;
                        showIndicator(true, row, col);
                    }else{
                        if (m_swapGrid1 == g) {
                            showIndicator(false, row, col);
                            m_swapGrid1 = NULL;
                            showSelectedGrids(false);
                            return;
                        }
                        showIndicator(false, row, col);
                        m_swapGrid2 = g;
                    }
                }
                m_animChecker->m_grids->insert(g);
                if (m_usingItem == kBooster_Harvest1Grid) {
                    m_animChecker->m_grid = g;
                    break;
                }
            }
            
        }
    }
    if (m_animChecker->m_grids->size() == 0) {
        showSelectedGrids(false);
        return;
    }
     
    m_animChecker->resetPhase();
    m_animChecker->setMatchEnd(false);
    addCombo();
    FMDataManager * manager = FMDataManager::sharedManager();
    
    if (m_usingItem == kBooster_Shuffle && m_swapGrid2 == NULL) {
        
    }else{
        CCBAnimationManager * anim = (CCBAnimationManager *)m_gameUI->getUserObject();
        anim->runAnimationsForSequenceNamed("BoosterSlideOut");
        
        if (manager->isTutorialRunning()) {
            manager->tutorialPhaseDone();
        }
    }

    switch (m_usingItem) {
        case kBooster_Harvest1Grid:
        {
            NEAnimNode * shovelAnim = NEAnimNode::createNodeFromFile("FMBoostSpoon.ani");
            shovelAnim->setAutoRemove(true);
            shovelAnim->playAnimation("Init");
            CCPoint p = getPositionForCoord(row, col);
            shovelAnim->setPosition(p);
            CCNode * offsetNode = m_gridParent->getChildByTag(1);
            offsetNode->addChild(shovelAnim, 100);
            
            FMGameElement * e = m_animChecker->m_grid->getElement();
//            if (e->isValueAddable()) {
                e->getAnimNode()->setZOrder(101);
                e->getAnimNode()->playAnimation("Match");
//            }
            m_animChecker->addAnimNode(shovelAnim, "anim flag 20");
        }
            break;
        case kBooster_Harvest1Row:
        {
            FMGameGrid * shooter = getNeighbor(row, col, kDirection_Center);
            
            FMSound::playEffect("T_remove.mp3");
            addScore(800);
            
            CCNode * offsetNode = m_gridParent->getChildByTag(1);
            CCPoint coord = shooter->getCoord();
            
            CCLayerColor* l = (CCLayerColor*)offsetNode->getChildByTag(kTagTcrossBG);
            if (l) {
                l->stopAllActions();
                l->removeFromParent();
            }
            ccColor4B color = {0,0,0,30};
            l = CCLayerColor::create(color);
            CCPoint cp = offsetNode->convertToWorldSpace(CCPointZero);
            l->setPosition(-cp.x, -cp.y);
            offsetNode->addChild(l,70,kTagTcrossBG);
            CCDelayTime * delay = CCDelayTime::create(1.f);
            CCCallFunc * call = CCCallFunc::create(l, callfunc_selector(CCLayerColor::removeFromParent));
            l->runAction(CCSequence::create(delay,call,NULL));

            NEAnimNode * effect = NEAnimNode::createNodeFromFile("FMGridBonusTMatch.ani");
            effect->playAnimation("Horizon");
            effect->setAutoRemove(true);
            offsetNode->addChild(effect, 70);
            CCPoint p = getPositionForCoord(coord.x, coord.y);
            effect->setPosition(p);
            m_animChecker->addAnimNode(effect, "anim flag 14");

            //trigger grids on the cross with delay
            static kGameDirection checkDirections[4] = {
                kDirection_U,
                kDirection_B,
                kDirection_L,
                kDirection_R
            };
            
            static float delayTime = 0.2f;
            for (int i=0; i<4; i++) {
                kGameDirection direction = checkDirections[i];
                FMGameGrid * neighbor = getNeighbor(shooter, direction);
                int index = 0;
//                while (neighbor) {
//                    index ++;
//                    FMGameWall * wall = getWall(neighbor, getDirection(direction, true));
//                    if (wall->getWallType() == kWallBreak) {
//                        //消除墙时加分
//                        addScore(200);
//                    }
//                    if (wall->breakWall()) {
//                     //   triggerAddValueToSpecailTarget(kElement_TargetWall);
//                    }
//
//                    FMGameElement * e = neighbor->getElement();
//                    if (e && !e->isMatched() && e->m_harvestType == kBonus_None) {
//                        kElementType type = e->getElementType();
//                        if ( type == kElement_Egg1 || type == kElement_Egg2) {
//                            
//                        }
//                        else {
//                            if (neighbor->m_4matchCount != 0) {
//                                //trigger immediately
//                                e->m_matchGroup = 100;
//                            }
//                            else {
//                                e->playAnimation("Match");
//                                CCDelayTime * delay = CCDelayTime::create(delayTime);
//                                CCCallFuncO * call = CCCallFuncO::create(this, callfuncO_selector(FMGameNode::triggerCrossEffect), neighbor);
//                                CCSequence * seq = CCSequence::create(delay, call, NULL);
//                                m_animChecker->addCCNode(neighbor->getElement()->getAnimNode(), seq, "cc flag 16");
//                            }
//
//                        }
//                    }
//                    neighbor = getNeighbor(neighbor, direction);
//                }
            }
            
//            shooter->setGridBonus(kBonus_None);
//            FMGameElement * e = shooter->getElement();
//            if (e && !e->isMatched() && e->m_harvestType == kBonus_None) {
//                triggerCrossEffect(shooter);
//            }
//            NEAnimNode * tractorAnim = NEAnimNode::createNodeFromFile("FMRoleCat.ani");
//            tractorAnim->playAnimation("Running");
//            CCPoint p = getPositionForCoord(row, -2);
//            CCPoint p2 = getPositionForCoord(row, 11);
//            p.y += kGridHeight * 0.5f;
//            p2.y += kGridHeight * 0.5f;
//            tractorAnim->setPosition(p);
//            CCMoveTo * m = CCMoveTo::create(13 * tractorMoveSpeed, p2);
//            CCCallFunc * remove = CCCallFunc::create(tractorAnim, callfunc_selector(CCNode::removeFromParent));
//            CCSequence * seq = CCSequence::create(m, remove, NULL);
//            offsetNode->addChild(tractorAnim, (row+1) * 5 + 1); 
//            m_animChecker->addCCNode(tractorAnim, seq, "cc flag 25");
//            FMSound::playEffect("cat.mp3");

        }
            break;
        case kBooster_Harvest1Type:
        {
            float delay = 0.4f;
            for (int i=0; i<kGridNum; i++) {
                for (int j=0; j<kGridNum; j++) {
                    FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
                    if (grid->isExistMovableElement()) {
                        FMGameElement * element = grid->getElement();
                        element->makeSurprise();
                    }
                }
            }
            
            NEAnimNode * strawAnim = NEAnimNode::createNodeFromFile("FMBoostStraw.ani");
            strawAnim->playAnimation("Init");
            strawAnim->setPosition(ccp(3.5f * kGridWidth, -3.5f * kGridHeight));
            NEAnimationDoneAction * animAct = NEAnimationDoneAction::create(strawAnim, "Init");
            CCCallFunc * callAct = CCCallFunc::create(this, callfunc_selector(FMGameNode::pigCallback));
            CCSequence * seq = CCSequence::create(animAct, callAct, NULL);
            CCNode * offsetNode = m_gridParent->getChildByTag(1);
            offsetNode->addChild(strawAnim, 120, kTag_Straw);
            m_animChecker->addCCNode(strawAnim, seq, "cc flag 26");
            FMSound::playEffect("pigfall.mp3");
        }
            break;
//        case kBooster_Shuffle:
//        {
//            if (m_swapGrid2 == NULL) {
//                showSelectedGrids(false);
//                return;
//            }
//            
//            FMGameElement * e1 = m_swapGrid1->getElement();
//            FMGameElement * e2 = m_swapGrid2->getElement();
//            
//            m_swapGrid2->setOccupyElement(e1);
//            m_swapGrid1->setOccupyElement(e2);
//            
//            elementShuffleToGrid(e1, m_swapGrid2);
//            elementShuffleToGrid(e2, m_swapGrid1);
//        }
//            break;
        default:
            break;
    } 
         
    showSelectedGrids(false);
    setGamePhase(kPhase_ItemUsing);
}

void FMGameNode::enterUseItemMode(int booster)
{
    if (booster == kBooster_CureRot ||
        booster == kBooster_PlusOne) {
        return;
    }
    CCBAnimationManager * anim = (CCBAnimationManager *)m_gameUI->getUserObject();
    anim->runAnimationsForSequenceNamed("BoosterSlideIn");

    NEAnimNode * b = (NEAnimNode *)m_boosterUseParent->getChildByTag(0);
    NEAnimNode * boosterIcon = (NEAnimNode *)b->getNodeByName("Booster");
    NEAnimNode * boosterBoard = (NEAnimNode *)b->getNodeByName("Count");
    NEAnimNode * boosterClock = (NEAnimNode *)b->getNodeByName("Clock");
    CCLabelBMFont * boosterCount = (CCLabelBMFont *)boosterBoard->getNodeByName("Label");
    FMDataManager * manager = FMDataManager::sharedManager();
    int count = manager->getBoosterAmount(booster);
#ifdef DEBUG
    if (m_cheatMode) {
        count = 9;
    }
#endif
    const char * skinName = getBoosterSkin((kGameBooster)booster);
    boosterIcon->useSkin(skinName);
    boosterBoard->setVisible(true);
    boosterClock->setVisible(false);
    boosterBoard->useSkin("Have");
    CCString * s = CCString::createWithFormat("%d", count);
    boosterCount->setString(s->getCString());

    CCLabelBMFont * boosterTip = (CCLabelBMFont *)m_boosterUseParent->getChildByTag(1);
    boosterTip->setAlignment(kCCTextAlignmentLeft);
    boosterTip->setWidth(220);
    boosterTip->setLineBreakWithoutSpace(manager->isCharacterType());
    
    switch (booster) {
        case kBooster_Harvest1Grid:
            boosterTip->setString(manager->getLocalizedString("V150_BOOSTERTIP_HARVEST1GRID"));
            break;
        case kBooster_Harvest1Row:
            boosterTip->setString(manager->getLocalizedString("V150_BOOSTERTIP_HARVEST1ROW"));
            break;
        case kBooster_Harvest1Type:
            boosterTip->setString(manager->getLocalizedString("V150_BOOSTERTIP_HARVEST1TYPE"));
            break;
        case kBooster_Shuffle:
            boosterTip->setString(manager->getLocalizedString("V150_BOOSTERTIP_SHUFFLE"));
            break;
        default:
            break;
    }

    
    
    m_usingItem = booster;
    //enter select mode
    useItemMode(true);
    setGamePhase(kPhase_ItemSelecting);
    //select this one
//    for (int i=0; i<6; i++) {
//        CCAnimButton * boosterButton = (CCAnimButton *)m_boosterParent->getChildByTag(i)->getChildByTag(1);
//        NEAnimNode * boosterIcon = (NEAnimNode *)boosterButton->getAnimNode()->getNodeByName("Booster");
//        if (i == m_usingItem) {
//            boosterIcon->playAnimation("Light");
//        }
//        else {
//            boosterIcon->playAnimation("Dark");
//        }
//    }
}

void FMGameNode::showSelectedGrids(bool show, int row, int col)
{
    for (int i=0; i<kGridNum; i++) {
        for (int j=0; j<kGridNum; j++) {
            FMGameGrid * grid = getNeighbor(i, j, kDirection_C);
            if (grid->getElement()) {
                grid->getElement()->showSelected(false);
            }
        }
    }
    
    if (!show) {
        return;
    }
    
    switch (m_usingItem) {
        case kBooster_Harvest1Grid:
        {
            FMGameGrid * grid = getNeighbor(row, col, kDirection_C); 
            if (grid->getElement()) {
                FMGameElement * e = grid->getElement();
                if (e->acceptBooster(kBooster_Harvest1Grid)) {
                    e->showSelected(true);
                }
            }
        }
            break;
        case kBooster_Harvest1Row:
        {
            for (int i=0; i<kGridNum; i++) {
                FMGameGrid * grid = getNeighbor(row, i, kDirection_C);
                FMGameElement * e = grid->getElement();
                if (e && !e->hasStatus(kStatus_Frozen)) {
                    if (e->acceptBooster(kBooster_Harvest1Row)) {
                        e->showSelected(true);
                    }
                }
            }
            for (int i = 0; i < kGridNum; i++) {
                FMGameGrid * grid = getNeighbor(i, col, kDirection_C);
                FMGameElement * e = grid->getElement();
                if (e && !e->hasStatus(kStatus_Frozen)) {
                    if (e->acceptBooster(kBooster_Harvest1Row)) {
                        e->showSelected(true);
                    }
                }
            }
        }
            break;
        case kBooster_Harvest1Type:
        {
            FMGameGrid * grid = getNeighbor(row, col, kDirection_C);
            FMGameElement * e = grid->getElement();
            if (e && e->acceptBooster(kBooster_Harvest1Type)) {
                kElementType type = e->getElementType();
                for (int i=0; i<kGridNum; i++) {
                    for (int j=0; j<kGridNum; j++) {
                        FMGameGrid * g = getNeighbor(i, j, kDirection_C); 
                        FMGameElement * ge = g->getElement();
                        if (ge && (ge->getElementType() == type ||
                             (ge->getElementType()-300) == type ||
                             ((ge->getElementType()+300) == type) ) && ge->acceptBooster(kBooster_Harvest1Type)) {
                            ge->showSelected(true);
                        }
                    }
                }
            }
        }
            break;
        case kBooster_Shuffle:
        {
            FMGameGrid * grid = getNeighbor(row, col, kDirection_C);
            if (grid->getElement()) {
                FMGameElement * e = grid->getElement();
                if (e->acceptBooster(kBooster_Shuffle)) {
                    e->showSelected(true);
                }
            }
        }
            break;
        default:
            break;
    }
    

}

void FMGameNode::levelComplete()
{
//    FMDataManager * manager = FMDataManager::sharedManager();
//    bool controlflag = !manager->isLevelBeaten();
//    if (SNSFunction_getRemoteConfigInt("kDifficultyControlDisable") == 1) {
//        controlflag = false;
//    }
//    if (controlflag) {
//        CCArray * control = (CCArray *)m_levelData->objectForKey("controlmoves");
//        if (control) {
//            int balanceCount = manager->getbalanceCount();
//            int passCount = ((CCNumber *)control->objectAtIndex(0))->getIntValue();
//            passCount += balanceCount;
//            
//            int FailCount = manager->getFailCount()+m_timeCount;
//            
//            int bc = passCount-FailCount-1;
//            manager->setbalanceCount(bc);
//        }
//    }

    FMSound::playEffect("win.mp3");
    FMSound::pauseMusic();
    setGamePhase(kPhase_NoInput);
    m_gameEnd = true;
    pause();
    
    FMUIGreenPanel * cPanel = (FMUIGreenPanel *)m_greenPanel;
    cPanel->setClassState(kPanelComplete);
    
    CCParticleSystemQuad * part = CCParticleSystemQuad::create("particle_winstar.plist");
    CCSize p = CCDirector::sharedDirector()->getWinSize();
    part->setSourcePosition(ccp(0.f, 0.f));
    part->setPosVar(ccp(p.width * 0.5f, 15.f));
    part->setPosition(0.f, -p.height * 0.5f);
    part->resetSystem();
    part->setAutoRemoveOnFinish(true);
    CCMoveTo * m1 = CCMoveTo::create(2.f, ccp(0.f, p.height * 1.5f));
    CCCallFunc * c1 = CCCallFunc::create(part, callfunc_selector(CCParticleSystemQuad::stopSystem));
    CCSequence * seq = CCSequence::create(m1, c1, NULL);
    part->runAction(seq);
    m_centerNode->addChild(part, 1000.f);
    
    //            part->setSourcePosition(ccp(0.f, p.height * 0.5f));
    //            part->setPosVar(ccp(p.width * 0.5f, 0));

//    CCCallFunc * call = CCCallFunc::create(this, callfunc_selector(FMGameNode::completeSlideDone));
//    CCSequence * seq = CCSequence::create(cPanel->slide(), call, NULL);
//    m_greenPanel->runAction(seq);
}

void FMGameNode::levelFailed()
{
    FMDataManager::sharedManager()->setNeedFailCount();
    
    FMSound::playEffect("lose.mp3");
    FMSound::pauseMusic();
    setGamePhase(kPhase_NoInput);
    m_gameEnd = true;
    pause();
    
    FMUIRedPanel * dialog = (FMUIRedPanel *)FMDataManager::sharedManager()->getUI(kUI_RedPanel);
    int state = m_gameMode;
    dialog->setClassState(state);
    GAMEUI_Scene::uiSystem()->nextWindow(dialog);
//    dialog->setHandleCallback(CCCallFuncN::create(this, callfuncN_selector(FMGameNode::handleDialogFailed)));
//    GAMEUI_Scene::uiSystem()->addDialog(dialog);
}


void FMGameNode::mapSlideInDone()
{
    //move in goal panel
    FMUIGreenPanel * goalPanel = (FMUIGreenPanel *)m_greenPanel;
    goalPanel->setClassState(kPanelGoal);
    goalPanel->setVisible(true);
}

void FMGameNode::mapSlideOutDone()
{
    FMUIResult * window = (FMUIResult *)FMDataManager::sharedManager()->getUI(kUI_Result);
    if (m_targetsCompleted) {
        window->setClassState(kResult_Win);
    }
    else {
        FMDataManager * manager = FMDataManager::sharedManager();
        if (!manager->isNeedFailCount()) {
            FMUILevelStart * twindow = (FMUILevelStart *)manager->getUI(kUI_LevelStart);
            GAMEUI_Scene::uiSystem()->nextWindow(twindow);
            return;
        }
        window->setClassState(kResult_Lose);
    }
    GAMEUI_Scene::uiSystem()->nextWindow(window);
}

void FMGameNode::goalSlideDone()
{
    FMUIGreenPanel* panel = (FMUIGreenPanel *)m_greenPanel;
    switch (panel->classState()) {
        case kPanelShuffle:
        {
            setGamePhase(kPhase_Shuffling);
            shuffle();            
            m_combo = 0;
            FMSound::playEffect("shuffle.mp3");
            return;
        }
            break;
        case kPanelManiaMode:
        {
            m_maniaMode = true;
            return;
        }
            break;
        case kPanelGoal:
        {
            m_isLevelFirstIn = false;
        }
            break;
        case kPanelComplete: 
        {
            uiSlide(false);
        }
            break;
        case kPanel5MovesLeft:
        {
//            setGamePhase(kPhase_WaitInput);
//            resume();
            return;
        }
            break;
        case kPanelGood:
        {
//            setGamePhase(kPhase_BeforeNewTurn);
//            resume();
            return;
        }
            break;
        case kPanelFail:
        {
            levelFailed();
        }
            break;
        default:
            break;
    } 

    setGamePhase(kPhase_WaitInput);
    resume();
    FMDataManager::sharedManager()->tutorialBegin();
    gameStart();
}

void FMGameNode::gameStart()
{
    if (!m_isLevelFirstIn) {
        beginFalling();
    }
}

void FMGameNode::userRetryAddLife()
{
    addLifeAndBooster();
    m_userQuit = true;
    m_gameEnd = true;
    uiSlide(false);
}
void FMGameNode::userQuiteAddLife()
{
    addLifeAndBooster();

    m_userQuit = true;
    m_gameEnd = true;
    FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
    scene->switchScene(kWorldMapNode);
}

void FMGameNode::addLifeAndBooster()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    int life = manager->getLifeNum();
    int maxlife = manager->getMaxLife();
    bool isQuest = manager->isQuest();
    if (manager->getUnlimitLifeTime() < manager->getCurrentTime()) {
        life++;
        manager->setLifeNum(life);
        if (isQuest) {
            manager->addWorldLifeUsed(-1);
        }
    }
    if (m_score == 0) {
        for (int i = 0; i < m_usedBonus.size(); i++) {
            int t = m_usedBonus[i];
            int num = manager->getBoosterAmount(t);
            num++;
            manager->setBoosterAmount(t, num);
        }
    }
}

void FMGameNode::handleDialogQuit(GAMEUI_Dialog * dialog)
{
    if (dialog->getHandleResult() == DIALOG_OK) {
        FMUIQuit * quitDialog = (FMUIQuit *)dialog;
        switch (quitDialog->classState()) {
            case kQuit_To_Retry:
            {
                m_userQuit = true;
                m_gameEnd = true;
                uiSlide(false);
                FMSound::playEffect("lose.mp3");
                FMSound::pauseMusic();
            }
                break;
            case kQuit_To_WorldMap:
            { 
                m_userQuit = true;
                m_gameEnd = true;
                
                FMDataManager * manager = FMDataManager::sharedManager();
                int globalIndex = manager->getGlobalIndex();
                int worldIndex = manager->getWorldIndex();
                int levelIndex = manager->getLevelIndex();
                bool isQuest = manager->isQuest();
                {
                    BubbleLevelStatInfo * info = new BubbleLevelStatInfo;
                    
                    if (isQuest) {
                        sprintf(info->levelIndex,"%d-%d", worldIndex+1, levelIndex+1);
                    }
                    else {
                        sprintf(info->levelIndex,"%d", globalIndex);
                    }
                    int levelid = -1;
                    {
                        BubbleLevelInfo * lInfo = manager->getLevelInfo(worldIndex);
                        BubbleSubLevelInfo * subInfo = isQuest ? lInfo->getUnlockLevel(levelIndex) : lInfo->getSubLevel(levelIndex);
                        levelid = subInfo->ID;
                        //delete lInfo;
                    }
                    info->levelID = levelid;
                    info->success = 0;
                    info->score = getCurrentScore();
                    info->star = getCurrentStarNum();
                    info->stepUsed = getUsedMoves();
                    info->stepTotal = getDefaultMoves();
                    info->failTimes = manager->getFailCount();
                    info->buyFiveStep = hasPlus5Booster() ? 1 : 0;
                    info->buySpade = -1;
                    info->useSpadeCount = getBoosterUsed(kBooster_Harvest1Grid);
                    info->useTractorCount = getBoosterUsed(kBooster_Harvest1Row);
                    info->useAddPointCount = getBoosterUsed(kBooster_PlusOne);
                    info->usePigCount = getBoosterUsed(kBooster_Harvest1Type);
                    info->useRecoverCount =getBoosterUsed(kBooster_CureRot);
                    info->buyFiveMoveCount = getContinueTimes();
                    info->beatRatBonus = -1;    //no use anymore
                    info->scoreBeforeMania = getScoreBeforeMania();
                    std::map<int, elementTarget> targets = getTargets();
                    for (std::map<int, elementTarget>::iterator it = targets.begin(); it != targets.end(); it++) {
                        elementTarget & t = it->second;
                        if (t.index < 4 && t.index >= 0) {
                            info->targetCount[t.index] = t.target;
                            info->collectCount[t.index] = t.harvested;
                        }
                    }
                    
                    BubbleServiceFunction_sendLevelStats(info); 
                    delete info;
                }
                
                
                //save game here
                manager->saveGame();
                
                FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
                scene->switchScene(kWorldMapNode);

            }
                break;
            default:
                break;
        }
    }
}

void FMGameNode::handleDialogFailed(int t)
{
    if (t == DIALOG_CANCELED) {
        uiSlide(false);
    }
    else {  
        m_continueTimes++;
        m_gameEnd = false;
        updateBoosters();
        FMSound::resumeMusic();
        resume();
        updateMoves();
        setGamePhase(kPhase_WaitInput);
    }
}

int FMGameNode::getCurrentScore()
{
    return m_score;
}

int FMGameNode::getScoreGap(int gap)
{
    return m_scoreCaps[gap];
}

int FMGameNode::getLeftMoves()
{
    return m_leftMoves;
}

int FMGameNode::getDefaultMoves()
{
    return ((CCNumber *)m_levelData->objectForKey("moves"))->getIntValue();;
}

#pragma mark - gameControl
 /*
 ////test
 //void makeInitJsonFile() {
 //    CCDictionary * dict = CCDictionary::create();
 //
 //    dict->setObject(CCArray::create(), "targets");
 //    dict->setObject(CCArray::create(), "gameModeData");
 //    dict->setObject(CCNumber::create(0), "gameMode");
 //    dict->setObject(CCNumber::create(0), "suggestedItem");
 //    dict->setObject(CCNumber::create(20), "moves");
 //    dict->setObject(CCArray::create(), "spawnables");
 //    dict->setObject(CCArray::create(), "percentage");
 //    CCArray * map = CCArray::create();
 //    dict->setObject(map, "map");
 //    for (int i=0; i<8; i++) {
 //        CCArray * row = CCArray::create();
 //        map->addObject(row);
 //        for (int j=0; j<8; j++) {
 //            row->addObject(CCArray::create());
 //        }
 //    }
 //
 //    const char * s = CCJSONConverter::sharedConverter()->strFrom(dict)->getCString();
 //    CCLOG("%s", s);
 //}
 //
 //int getDataConvertion(int input)
 //{
 //    switch (input) {
 //        case 1:
 //            return 4;
 //        case 2:
 //            return 6;
 //        case 4:
 //            return 2;
 //        case 6:
 //            return 1;
 //        case 7:
 //            return 10;
 //        case 8:
 //            return 12;
 //        case 10:
 //            return 8;
 //        case 12:
 //            return 7;
 //        case 701:
 //            return 101;
 //        case 702:
 //            return 102;
 //        case 703:
 //            return 103;
 //        case 704:
 //            return 104;
 //        case 710:
 //            return 105;
 //        default:
 //            return input;
 //            break;
 //    }
 //
 //}
 //
 //static std::map<int, int> spawnablesAnalyst;
 //CCDictionary * loadFromJsonFile() {
 //    CCString * s = CCString::createWithContentsOfFile("NeedDelete.dat");
 //    CCDictionary * map = CCJSONConverter::sharedConverter()->dictionaryFrom(s->getCString());
 //    CCArray * levels = (CCArray *)map->objectForKey("levels");
 //    CCDictionary * ret = CCDictionary::create();
 //
 //    for (int i=0; i<levels->count(); i++) {
 //        CCDictionary * leveldic = (CCDictionary *)levels->objectAtIndex(i);
 //        CCNumber * id = (CCNumber *)leveldic->objectForKey("id");
 //        CCDictionary * level = (CCDictionary *)leveldic->objectForKey("level");
 //        CCDictionary * convert = CCDictionary::create();
 //        CCString * key = CCString::createWithFormat("%d", id->getIntValue());
 //        ret->setObject(convert, key->getCString());
 //
 //        convert->setObject(id, "id");
 //
 //        //targets
 //        CCArray * cTargets = CCArray::create();
 //        convert->setObject(cTargets, "targets");
 //        CCArray * itemTargets = (CCArray *)level->objectForKey("itemTargets");
 //        for (int i=0; i<itemTargets->count(); i++) {
 //            CCDictionary * d = (CCDictionary *)itemTargets->objectAtIndex(i);
 //            CCNumber * amount = (CCNumber *)d->objectForKey("amount");
 //            CCNumber * type = (CCNumber *)d->objectForKey("type");
 //            if (amount->getIntValue() == 0) {
 //                continue;
 //            }
 //            CCArray * t = CCArray::create();
 //            cTargets->addObject(t);
 //            CCNumber * typeConvert = CCNumber::create(getDataConvertion(type->getIntValue()));
 //            t->addObject(typeConvert);
 //            t->addObject(amount);
 //        }
 //
 //
 //        //gameMode
 //        CCString * gameModeString = (CCString *)level->objectForKey("gameMode");
 //        int gameMode = 0;
 //        if (strcmp(gameModeString->getCString() , "farm_king_classic") == 0) {
 //            gameMode = 0;
 //        }
 //        else if (strcmp(gameModeString->getCString() , "farm_king_collection") == 0) {
 //            gameMode = 1;
 //        }
 //        else if (strcmp(gameModeString->getCString() , "farm_king_boss") == 0) {
 //            gameMode = 2;
 //        }
 //
 //        CCNumber * cgm = CCNumber::create(gameMode);
 //        convert->setObject(cgm, "gameMode");
 //
 //        //sellingItem
 //        CCNumber * si = CCNumber::create(0);
 //        convert->setObject(si, "sellingItem");
 //
 //        //gameModeData
 //        CCArray * cgmd = CCArray::create();
 //        convert->setObject(cgmd, "gameModeData");
 //        switch (gameMode) {
 //            case 0:
 //            {
 //                CCDictionary * outputs = (CCDictionary *)level->objectForKey("gameModeConfiguration");
 //                CCArray * a = (CCArray *)outputs->objectForKey("outputs");
 //                cgmd->addObject(a->objectAtIndex(0));
 //                cgmd->addObject(a->objectAtIndex(1));
 //                cgmd->addObject(a->objectAtIndex(2));
 //
 //            }
 //                break;
 //            case 1:
 //            {
 //                CCDictionary * outputs = (CCDictionary *)level->objectForKey("gameModeConfiguration");
 //                CCArray * a = (CCArray *)outputs->objectForKey("collectibleRewardIds");
 //                cgmd->addObject(a->objectAtIndex(0));
 //                cgmd->addObject(a->objectAtIndex(1));
 //                cgmd->addObject(a->objectAtIndex(2));
 //            }
 //                break;
 //            case 2:
 //            {
 //                CCDictionary * outputs = (CCDictionary *)level->objectForKey("gameModeConfiguration");
 //                CCArray * a = (CCArray *)outputs->objectForKey("levelSoftCurrencyInfos");
 //                std::vector<int> vec;
 //                for (int i=0; i<3; i++) {
 //                    CCDictionary * dic = (CCDictionary *)a->objectAtIndex(i);
 //                    int input = ((CCNumber *)dic->objectForKey("input"))->getIntValue();
 //                    vec.push_back(input);
 //                }
 //                std::sort(vec.begin(), vec.end());
 //
 //                cgmd->addObject(CCNumber::create(vec[0]));
 //                cgmd->addObject(CCNumber::create(vec[1]));
 //                cgmd->addObject(CCNumber::create(vec[2]));
 //            }
 //                break;
 //            default:
 //                break;
 //        }
 //
 //        //suggestedItem
 //        CCString * suggestedString = (CCString *)level->objectForKey("suggestedBooster");
 //        int suggested = 0;
 //        if (strcmp(suggestedString->getCString() , "Shovel") == 0) {
 //            suggested = 0;
 //        }
 //        else if (strcmp(suggestedString->getCString() , "Tractor") == 0) {
 //            suggested = 1;
 //        }
 //        else if (strcmp(suggestedString->getCString() , "PlusOne") == 0) {
 //            suggested = 2;
 //        }
 //        else if (strcmp(suggestedString->getCString() , "Hunter") == 0) {
 //            suggested = 3;
 //        }
 //        else {
 //            suggested = 4;
 //        }
 //        convert->setObject(CCNumber::create(suggested), "suggestedItem");
 //
 //        //moves
 //        CCNumber * moves = (CCNumber *)level->objectForKey("numberOfTurns");
 //        convert->setObject(CCNumber::create(moves->getIntValue()), "moves");
 //
 //        //spawnables
 //        CCArray * cSpawnables = CCArray::create();
 //        convert->setObject(cSpawnables, "spawnables");
 //        CCArray * spawnableItems = (CCArray *)level->objectForKey("spawnableItems");
 //        for (int j=0; j<spawnableItems->count(); j++) {
 //            CCObject * aa = spawnableItems->objectAtIndex(j);
 //            int type = 0;
 //            int weight = 100;
 //            if (dynamic_cast<CCNumber *>(aa) != NULL) {
 //                CCNumber * item = (CCNumber *)aa;
 //                type = item->getIntValue();
 //            }
 //            else {
 //                CCDictionary * item = (CCDictionary*) aa;
 //                CCNumber * tn = (CCNumber *)item->objectForKey("type");
 //                CCNumber * tw = (CCNumber *) item->objectForKey("weight");
 //                type = tn->getIntValue();
 //                weight = tw->getIntValue();
 //            }
 //            CCArray * s = CCArray::create();
 //            cSpawnables->addObject(s);
 //            s->addObject(CCNumber::create(getDataConvertion(type)));
 //            s->addObject(CCNumber::create(weight));
 //        }
 //
 //        //analyst
 //        int spc = cSpawnables->count();
 //        if (spawnablesAnalyst.find(spc) == spawnablesAnalyst.end()) {
 //            spawnablesAnalyst[spc] = 0;
 //        }
 //        spawnablesAnalyst[spc]++;
 //
 //        //percentage
 //        CCArray * cPercentage = CCArray::create();
 //        CCArray * cp = (CCArray *)level->objectForKey("starlevel");
 //        cPercentage->addObject(cp->objectAtIndex(0));
 //        cPercentage->addObject(cp->objectAtIndex(1));
 //        cPercentage->addObject(cp->objectAtIndex(2));
 //        convert->setObject(cPercentage, "percentage");
 //
 //        //map
 //        CCArray * boardState = (CCArray *)level->objectForKey("boardState");
 //        CCArray * cMap = CCArray::create();
 //        convert->setObject(cMap, "map");
 //        for (int i=0; i<8; i++) {
 //            CCArray * crow = CCArray::create();
 //            cMap->addObject(crow);
 //            for (int j=0; j<8; j++) {
 //                CCArray * citem = CCArray::create();
 //                crow->addObject(citem);
 //                CCArray * item = (CCArray *)boardState->objectAtIndex(i*8+j);
 //
 //                kGridType gt = kGridNormal;
 //                kElementType et = kElement_Random;
 //                std::vector<kGridStatus> status;
 //
 //                for (int k=0; k<item->count(); k++) {
 //                    CCNumber * n = (CCNumber *)item->objectAtIndex(k);
 //                    int nn = n->getIntValue();
 //                    nn = getDataConvertion(nn);
 //                    switch (nn) {
 //                        case 502:
 //                            status.push_back(kStatus_Ice);
 //                            break;
 //                        case 601:
 //                            status.push_back(kStatus_Spawner);
 //                            break;
 //                        case 504:
 //                            gt = kGridNone;
 //                            break;
 //                        case 711:
 //                            gt = kGridGrass;
 //                            break;
 //                        default:
 //                            et = (kElementType)nn;
 //                            break;
 //                    }
 //
 //                }
 //
 //                if (status.size() == 0) {
 //                    // 2 or 1 or 0
 //                    if (et == kElement_Random) {
 //                        //1 or 0
 //                        if (gt == kGridNormal) {
 //                            //0
 //                        }
 //                        else {
 //                            //1
 //                            citem->addObject(CCNumber::create(gt));
 //                        }
 //                    }
 //                    else  {
 //                        //2
 //                        citem->addObject(CCNumber::create(gt));
 //                        citem->addObject(CCNumber::create(et));
 //                    }
 //                }
 //                else {
 //                    //3 or 3+
 //                    citem->addObject(CCNumber::create(gt));
 //                    citem->addObject(CCNumber::create(et));
 //                    for (int v=0; v<status.size(); v++) {
 //                        kGridStatus s = status.at(v);
 //                        citem->addObject(CCNumber::create(s));
 //                    }
 //                }
 //            }
 //        }
 //
 //    }
 //    CCLOG("Data Analyst ");
 //    for (std::map<int, int>::iterator it = spawnablesAnalyst.begin(); it != spawnablesAnalyst.end(); it++) {
 //        CCLOG("used %d spawnables, stages: %d", it->first, it->second);
 //    }
 //
 //    const char * out = CCJSONConverter::sharedConverter()->strFrom(ret)->getCString();
 //
 //    std::string path = CCFileUtils::sharedFileUtils()->getWriteablePath();
 //    std::stringstream ss;
 //    ss.str("");
 //    ss << path << "output" << ".dat";
 //    std::string filePath = ss.str();
 //
 //    FILE * fp = fopen(filePath.c_str(), "w");
 //    if (fp) {
 //        fputs(out, fp);
 //    }
 //    fclose(fp);
 //    return ret;
 //}
 ////test
 */
