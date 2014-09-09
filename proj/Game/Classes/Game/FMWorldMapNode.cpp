//
//  FMWorldMapNode.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-12.
//
//

#include "FMWorldMapNode.h"
#include "FMDataManager.h" 
#include "FMUIWorldMap.h"
#include "FMUILevelStart.h"
#include "FMUIBooster.h"
#include "FMUIBranchLevel.h"
#include "FMTutorial.h"
#include "FMMainScene.h"
#include "FMStatusbar.h"
#include "GAMEUI_Scene.h"
#include "GAMEUI_Window.h"
#include "CCJSONConverter.h"
#include "FMGameNode.h"
#include "BubbleServiceFunction.h"
#include "SNSFunction.h"
#include "OBJCHelper.h"
#include "AppDelegate.h" 
#include "FMUIFamilyTree.h"
#include "FMMapAvatarNode.h"
#include "FMUIFriendProfile.h"
#include "FMUIDailyBoxPop.h"

static int kTagFrdAvatarBG = 9527;


FMWorldMapNode::FMWorldMapNode() :
    m_centerNode(NULL),
    m_currentButton(NULL),
    m_info(NULL),
    m_dialog(NULL),
    m_leftButton(NULL),
    m_rightButton(NULL),
    m_initAvatar(false),
    m_willUpdateStar(false),
    m_willUnlockBooster(kBooster_None),
    m_willUpdateUnlock(-1),
    m_hideSublevel(false),
    m_gameAdvance(kAdvance_Normal),
    m_isPhaseRunning(false),
    m_slider(NULL)
{
//    NEAnimManager::sharedManager()->preloadTextureForAnimFile("world1.ani", "Init");
    CCSpriteFrameCache::sharedSpriteFrameCache()->addSpriteFramesWithFile("CCBUI.plist");
    m_ccbNode = FMDataManager::sharedManager()->createNode("FMWorldMapNode.ccbi", this);
    addChild(m_ccbNode);
    
    CCControlButton * leftButton = (CCControlButton *)m_leftButton->getParent()->getChildByTag(15);
    leftButton->setTouchPriority(-100);
    leftButton->setDefaultTouchPriority(-100);
    CCControlButton * rightButton = (CCControlButton *)m_rightButton->getParent()->getChildByTag(16);
    rightButton->setTouchPriority(-100);
    rightButton->setDefaultTouchPriority(-100);
    
    
    m_avatar = FMDataManager::sharedManager()->createNode("UI/FMUIAvatar.ccbi", this);
//    m_avatar = CCNode::create();
//    CCSprite * s1 = CCSprite::createWithSpriteFrameName("avatar_board.png");
//    CCSprite * avatar = CCSprite::createWithSpriteFrameName("avatar_default.png");
//    CCSprite * frame = CCSprite::createWithSpriteFrameName("avatar_frame.png");
//    m_avatar->addChild(s1, 0, 0);
//    m_avatar->addChild(avatar, 1, 1);
//    m_avatar->addChild(frame, 2, 2);
//    m_avatar->setAnchorPoint(ccp(0.5f, 0.f));
    m_avatar->retain();
    
    CCSize winSize = CCDirector::sharedDirector()->getWinSize();

    m_mapNameNode = NEAnimNode::createNodeFromFile("LevelName.ani");
    m_mapNameNode->setPosition(ccp(0, winSize.height/2 - 50.f));
    m_mapNameNode->releaseControl("Label",kProperty_StringValue);
    m_centerNode->addChild(m_mapNameNode, 1000);

    winSize.height -= 100;
    CCSize winSizeInPixels = CCDirector::sharedDirector()->getWinSize();
    GUIScrollSlider * slider = new GUIScrollSlider(winSize, CCRect(-winSizeInPixels.width * 0.5f, -winSizeInPixels.height * 0.5f, winSizeInPixels.width, winSizeInPixels.height), 400.f, this, false);
    slider->setRevertDirection(true);
    slider->setPageMode(true);
    slider->getMainNode()->addChild(m_avatar, 1000);
    
    m_dailyBox = DailyBox::creat();
    slider->getMainNode()->addChild((CCNode *)m_dailyBox, 999);
    
    m_slider = slider;
    m_centerNode->addChild(slider);
    
    m_newVersionNode = FMDataManager::sharedManager()->createNode("UI/FMUIWorldEnd.ccbi", this);
    m_newVersionNode->retain();
    CCLabelBMFont * label = (CCLabelBMFont *)m_newVersionNode->getChildByTag(4);
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
    label->setAlignment(kCCTextAlignmentCenter);
#endif
    label->setWidth(280);
    label->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    //world end
//    NEAnimNode * n = NEAnimNode::createNodeFromFile("FMWorldEnd.ani");
//    CCNode * CCB = FMDataManager::sharedManager()->createNode("UI/FMUIWorldEnd.ccbi", this);
//    CCNode * button = FMDataManager::sharedManager()->createNode("UI/FMUIWorldEndButton.ccbi", this);
//
//    m_info->setWidth(200);
//    m_info->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
//    n->replaceNode("CCB", CCB);
//    n->replaceNode("Button", button);
//    n->playAnimation("Init");
//    n->retain();
//    int count = itemsCountForSlider(m_slider);
//    n->setPosition(m_slider->getPointFromSingleValue(-512.f * (count-0.5f)));
//    m_slider->getMainNode()->addChild(n, 10000, 1010);
    
    

    
    FMDataManager * manager = FMDataManager::sharedManager();
    
    FMUIWorldMap * bar = (FMUIWorldMap *)manager->getUI(kUI_WorldMap);
    addChild(bar, 10);
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
    OBJCHelper::helper()->addDownloadCallback(this, callfuncO_selector(FMWorldMapNode::onFileDownloaded));
#endif
//    GAMEUI_Window *window = new GAMEUI_Window;
//    window->addChild(CCSprite::create("bg.png"));
    //    GAMEUI_Scene::uiSystem()->nextWindow(window);
}

FMWorldMapNode::~FMWorldMapNode()
{
    m_avatar->release();
}

FMWorldMapNode *FMWorldMapNode::create()
{
    FMWorldMapNode *pRet = new FMWorldMapNode();
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



#pragma mark - CCB Bindings
bool FMWorldMapNode::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_centerNode", CCNode *, m_centerNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_info", CCLabelBMFont *, m_info);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_dialog", CCSprite *, m_dialog);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_leftButton", NEAnimNode *, m_leftButton);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_rightButton", NEAnimNode *, m_rightButton);
    return true;
}

SEL_CCControlHandler FMWorldMapNode::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickUpdate", FMWorldMapNode::clickUpdate);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickPlayBranch", FMWorldMapNode::clickPlayBranch);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMWorldMapNode::clickButton);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickAvatarBtn", FMWorldMapNode::clickAvatarBtn);
    return NULL;
}

#pragma mark - GUIScrollSliderDelegate

static float buttonXID[5] = {100, 110, 120, 130, 140};
CCNode * FMWorldMapNode::createItemForSlider(GUIScrollSlider * slider)
{
    NEAnimNode * worldNode = NULL;
    worldNode = NEAnimNode::createNodeFromFile("FMWorld.ani");
    worldNode->releaseControl("Map",kProperty_Scale);
    worldNode->releaseControl("Map2",kProperty_Scale);
    
    CCNode * map = worldNode->getNodeByName("Map");
    CCNode * map2 = worldNode->getNodeByName("Map2");
    
    map->setScale(2.f);
    map2->setScale(2.f);
    
    worldNode->playAnimation("World2");
    NEAnimNode * clouds = (NEAnimNode *)worldNode->getNodeByName("CLOUDS");
    worldNode->releaseControl("CLOUDS");
    
    CCLayerColor * bglayer = CCLayerColor::create(ccc4(0, 0, 0, 128), 400, 600);
    bglayer->setAnchorPoint(ccp(0.5f, 0.5f));
    bglayer->ignoreAnchorPointForPosition(false);
    clouds->replaceNode("BG", bglayer);

    FMDataManager * manager = FMDataManager::sharedManager();
    
    for (int j=0; j<16; j++) {
        int i = j;
        bool isQuest = j >= 15;
        if (isQuest) {
            i = j - 15;
        }
        CCString * str = CCString::createWithFormat(isQuest ? "Q%d" : "%d", i+1);

        NEAnimNode * buttonAnim = (NEAnimNode *)worldNode->getNodeByName(str->getCString());
        
        int globalIndex = manager->getGlobalIndex();
        str = NULL;
        if (isQuest) {
            const char * s = manager->getLocalizedString("V100_QUEST_D");
            str = CCString::createWithFormat(s, i+1);
            buttonAnim->releaseControl("jelly", kProperty_Animation);
            buttonAnim->releaseControl("jelly", kProperty_AnimationControl);
        }
        else {
            str = CCString::createWithFormat("%d", globalIndex);
        }

        CCLabelBMFont * label = CCLabelBMFont::create(str->getCString(), "font_9.fnt"); 
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
        label->setAlignment(kCCTextAlignmentCenter);
#endif
        label->setPosition(ccp(0, -20));
        buttonAnim->addChild(label, 10, 1);

        bool beaten = manager->isLevelBeaten();

        for (int ii=0; ii<5; ii++) {
            buttonAnim->xidChange(buttonXID[0]+ii, buttonXID[4]+ii);
        }
        int flag = 0;
        flag |= beaten ? kButton_Passed : 0;
        flag &= ~kButton_Locked;
        buttonAnim->setUserData((void *)flag);
        buttonAnim->setVisible(beaten);
        
        buttonAnim->releaseControl("FLOWER", kProperty_AnimationControl);
        buttonAnim->releaseControl("Ring", kProperty_AnimationControl);
        buttonAnim->releaseControl("Ring", kProperty_Visible);
        buttonAnim->releaseControl("Reward", kProperty_Visible);
        buttonAnim->releaseControl("Reward2", kProperty_Visible);
        buttonAnim->releaseControl("Reward3", kProperty_Visible);
        CCNode * reward = buttonAnim->getNodeByName("Reward");
        if (reward) {
            reward->setVisible(false);
        }
        reward = buttonAnim->getNodeByName("Reward2");
        if (reward) {
            reward->setVisible(false);
        }
        reward = buttonAnim->getNodeByName("Reward3");
        if (reward) {
            reward->setVisible(false);
        }

        CCScale9Sprite * buttonSprite = CCScale9Sprite::create("transparent.png");
        CCControlButton * button = CCControlButton::create(buttonSprite);
        button->setPreferredSize(CCSize(50, 50));
        buttonAnim->replaceNode("1", button);
        button->addTargetWithActionForControlEvents(this, cccontrol_selector(FMWorldMapNode::clickSubLevel), CCControlEventTouchDown | CCControlEventTouchDragInside | CCControlEventTouchUpInside | CCControlEventTouchDragEnter | CCControlEventTouchDragExit);
    }
    return worldNode;
}

int FMWorldMapNode::itemsCountForSlider(GUIScrollSlider * slider)
{
//#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
//    return 8;
//#else
//    CCLog("--------%d-----",BubbleServiceFunction_getLevelCount());
    return BubbleServiceFunction_getLevelCount() + 1;
//#endif
}

void FMWorldMapNode::sliderEnterPage(GUIScrollSlider *slider, int rowIndex, cocos2d::CCNode *node)
{
    if (rowIndex == 0) {
        m_leftButton->playAnimation("OffLeft");
        m_rightButton->playAnimation("OnRight", 0, false, true);
    }
    else if (rowIndex == itemsCountForSlider(slider) - 1) {
        m_leftButton->playAnimation("OnLeft", 0, false, true);
        m_rightButton->playAnimation("OffRight");
    }
    else {
        m_leftButton->playAnimation("OnLeft", 0, false, true);
        m_rightButton->playAnimation("OnRight", 0, false, true);
    }
}
void FMWorldMapNode::sliderStopInPage(GUIScrollSlider * slider, int rowIndex, CCNode * node)
{
    if (isWorldExist(rowIndex)) {
        if (m_mapNameNode) {
            BubbleLevelInfo* info = FMDataManager::sharedManager()->getLevelInfo(rowIndex);
            if (!info) {
                m_mapNameNode->stopAnimation();
                return;
            }

            const char * s = FMDataManager::sharedManager()->getLocalizedString(info->name.c_str());
            CCLabelBMFont* label = (CCLabelBMFont*)m_mapNameNode->getNodeByName("Label");
            label->setFntFile("font_1.fnt");
            if (strcmp(label->getString(), s) == 0) {
                m_mapNameNode->playAnimation("Animation1", 0, false, true);
            }else{
                label->setString(s);
                m_mapNameNode->playAnimation("Animation1");
            }
        }
    }else{
        if (m_mapNameNode) {
            m_mapNameNode->stopAnimation();
        }
    }
}
void FMWorldMapNode::sliderLeavePage(GUIScrollSlider * slider, int rowIndex, CCNode * node)
{
    if (node) {
        node->removeChildByTag(kTagFrdAvatarBG, true);
    }
}

void FMWorldMapNode::sliderUpdate(GUIScrollSlider * slider, int rowIndex, CCNode * node)
{
    int count = itemsCountForSlider(m_slider);
    m_newVersionNode->setPosition(m_slider->getPointFromSingleValue(-400.f * (count-0.5f)));
    node->removeChildByTag(kTagFrdAvatarBG, true);

    NEAnimNode * world = (NEAnimNode *)node;
    if (isWorldExist(rowIndex)) {
        const char * worldName = CCString::createWithFormat("World%d", rowIndex +1)->getCString();
        world->playAnimation(worldName);
        
        BubbleLevelInfo* info = FMDataManager::sharedManager()->getLevelInfo(rowIndex);
        if (!info) {
            return;
        }
        updateWorld(world, rowIndex);
    }
    else
    {
        
        NEAnimNode * clouds = (NEAnimNode *)world->getNodeByName("CLOUDS");
        clouds->setVisible(false);
        if (rowIndex == itemsCountForSlider(m_slider)-1) {
            bool canUpdate = BubbleServiceFunction_isUpdateReady(); 
            if (canUpdate) {
                world->playAnimation("WorldNewVersion");
                ((CCBAnimationManager *)m_newVersionNode->getUserObject())->runAnimationsForSequenceNamed("NewVersion");
            }
            else {
                CCLabelBMFont * label = (CCLabelBMFont*)m_newVersionNode->getChildByTag(4);
                world->playAnimation("WorldComingSoon");
                switch (m_gameAdvance) {
                    case kAdvance_Normal:
                        ((CCBAnimationManager *)m_newVersionNode->getUserObject())->runAnimationsForSequenceNamed("PlayBranch");
                        label->setString(FMDataManager::sharedManager()->getLocalizedString("V100_COMING_SOON"));
                        break;
                    case kAdvance_MasterComplete:
                        ((CCBAnimationManager *)m_newVersionNode->getUserObject())->runAnimationsForSequenceNamed("PlayBranch");
                        label->setString(FMDataManager::sharedManager()->getLocalizedString("V100_COMING_SOON1"));
                        break;
                    case kAdvance_AllComplete:
                        ((CCBAnimationManager *)m_newVersionNode->getUserObject())->runAnimationsForSequenceNamed("ComingSoon");
                        label->setString(FMDataManager::sharedManager()->getLocalizedString("V100_COMING_SOON2"));
                        break;
                    default:
                        break;
                }
            }
        }
        else {
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
#ifdef DEBUG
            world->playAnimation("World2");
            
            BubbleLevelInfo* info = FMDataManager::sharedManager()->getLevelInfo(rowIndex);
            if (!info) {
                return;
            }
            updateWorld(world, rowIndex);
#else
            world->playAnimation("WorldDownloading");
//        world->setZOrder(10000 + rowIndex);
#endif
#else
            world->playAnimation("WorldComingSoon");
            ((CCBAnimationManager *)m_newVersionNode->getUserObject())->runAnimationsForSequenceNamed("ComingSoon");
#endif
        }
    }
    
    
//    if (!m_needUpdate) {
//        return;
//    } 
}
void FMWorldMapNode::updateWorld(NEAnimNode * node, int world)
{
//    CCLog("update node : %x", node);
    CCNode * avatarbg = CCNode::create();
    node->addChild(avatarbg, 100, kTagFrdAvatarBG);
    
    FMDataManager * manager = FMDataManager::sharedManager();
    CCDictionary * frdDic = NULL;
    CCArray * frdlist = NULL;
    frdDic = manager->getFrdMapDic();
    if (frdDic) {
        frdlist = (CCArray *)frdDic->objectForKey("list");
    }

    int wi = manager->getWorldIndex();
    int li = manager->getLevelIndex();
    bool quest = manager->isQuest();
    bool branch = manager->isBranch();
    
    //update world map state
    int index = world;
    NEAnimNode * n = node;
          
    BubbleLevelInfo * info = manager->getLevelInfo(index);
    
    manager->setLevel(index-1, 0, false, manager->isBranch());
    bool worldBeaten = manager->isWorldBeaten(true);
    
    manager->setLevel(index, 0, false, manager->isBranch());
    
    //clouds
    if (m_willUpdateUnlock != world) {
//        bool opened = manager->isWorldOpened() ;
        NEAnimNode * clouds = (NEAnimNode *)n->getNodeByName("CLOUDS");
        if (worldBeaten) {
            clouds->setVisible(false);
        }
        else {
            clouds->playAnimation("ChatperlockedIdle");
            clouds->setVisible(true); 
        }
    }
    else {
        NEAnimNode * clouds = (NEAnimNode *)n->getNodeByName("CLOUDS");
        clouds->playAnimation("ChatperlockedIdle");
        clouds->setVisible(true);
    }
    
    for (int i=0; i<15; i++) {
        bool isInWorld = i < info->subLevelCount;
        CCString * cstr = CCString::createWithFormat("%d", i+1);
        NEAnimNode * buttonAnim = (NEAnimNode *)n->getNodeByName(cstr->getCString());
        CCControlButton * button = (CCControlButton *)buttonAnim->getNodeByName("1");
        if (!button) {
            continue;
        }
        button->setEnabled(isInWorld);
        
        if (isInWorld) {
            manager->setLevel(index, i, false);
            
#ifdef BRANCH_CN
            if (frdlist) {
                if (!manager->isFurthestLevel()) {
                    for (int f = 0; f < frdlist->count(); f++) {
                        CCDictionary * frd = (CCDictionary *)frdlist->objectAtIndex(f);
                        CCNumber * uid = (CCNumber *)frd->objectForKey("uid");
                        if (uid) {
                            if (uid->getIntValue() == atoi(manager->getUID())) {
                                break;
                            }
                        }
                        CCNumber * page = (CCNumber *)frd->objectForKey("page");
                        CCNumber * level = (CCNumber *)frd->objectForKey("level");
                        CCNumber * iconid = (CCNumber *)frd->objectForKey("icon");
                        if (page->getIntValue() == index && level->getIntValue() == i && iconid) {
                            CCNode * avatarnode = FMDataManager::sharedManager()->createNode("UI/FMUIAvatar.ccbi", this);
                            int iconint = iconid->getIntValue() - 1;
                            if (iconint > 5 || iconint < 0) {
                                iconint = 0;
                            }
                            CCString * iconname = CCString::createWithFormat("touxiang-%02d.png",iconint);
                            CCSprite * icon = (CCSprite*)avatarnode->getChildByTag(1);
                            CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(iconname->getCString());
                            icon->setDisplayFrame(frame);
                            
                            CCPoint p = buttonAnim->getPosition();
                            p.y += kAvatarOffsetY;
                            avatarnode->setPosition(p);
                            avatarbg->addChild(avatarnode);
                            
                            CCSprite * namebg = (CCSprite *)avatarnode->getChildByTag(2);
                            namebg->setOpacity(0);
                            CCLabelTTF * label = (CCLabelTTF *)namebg->getChildByTag(2);
                            label->setOpacity(0);
                            CCString * name = (CCString *)frd->objectForKey("name");
                            if (name) {
                                label->setString(name->getCString());
                            }
                            break;
                        }
                    }
                }
            }
#else
            if (SNSFunction_isFacebookConnected() && frdlist) {
                const char * fbUid = SNSFunction_getFacebookUid();
                bool includeSelf = false;
                if (manager->getFurthestWorld() == index && manager->getFurthestLevel() == i) {
                    includeSelf = true;
                }
                
                FMMapAvatarNode * node = NULL;
                for (int f = 0; f < frdlist->count(); f++) {
                    CCDictionary * frd = (CCDictionary *)frdlist->objectAtIndex(f);
                    CCString * uid = (CCString *)frd->objectForKey("uid");
                    if (uid) {
                        if (strcmp(fbUid, uid->getCString()) == 0) {
                            continue;
                        }
                    }

                    CCNumber * page = (CCNumber *)frd->objectForKey("page");
                    CCNumber * level = (CCNumber *)frd->objectForKey("level");
                    if (page->getIntValue() == index && level->getIntValue() == i) {
                        if (node) {
                            bool success = node->addAvatarNode(frd);
                            if (!success) {
                                break;
                            }
                        }else{
                            if (includeSelf) {
                                setAvatarEnable(false);
                            }
                            node = FMMapAvatarNode::creatAvatarNode(includeSelf, frd);
                            CCPoint p = buttonAnim->getPosition();
                            p.y += kAvatarOffsetY;
                            CCNode * n = (CCNode *)node;
                            n->setPosition(p);
                            avatarbg->addChild(n);
                        }
                    }
                }
                
            }
#endif
            
            int gameMode = manager->getGameMode();
            static const char * gameModeSkins[] = {"Classic", "Harvest", "Boss"};
            if (gameMode > 2) {
                gameMode = 0;
            }
            buttonAnim->useSkin(gameModeSkins[gameMode]);
            //not support collection yet
//            gameMode = gameMode == kGameMode_Collection ? kGameMode_Classic : gameMode;

            //TODO: change skin
//            for (int ii=0; ii<5; ii++) {
//                buttonAnim->xidChange(buttonXID[0]+ii, buttonXID[gameMode]+ii);
//            }
            bool isBeaten = manager->isLevelBeaten() || manager->getStarNum() > 0;
            bool isLevelUnlocked = manager->isLevelUnlocked();
            if (i == 0) {
                if (worldBeaten) {
                    isLevelUnlocked = true;
                }
            }
            bool isFurthestLevel = manager->isFurthestLevel() && !isBeaten;
            
            int flag = 0;
            flag |= isBeaten ? kButton_Passed : 0;
            flag |= !isLevelUnlocked ? kButton_Locked : 0;
            flag |= isFurthestLevel ? kButton_Highlighted : 0;
            
            buttonAnim->setUserData((void *)flag);
            buttonAnim->setVisible(!m_hideSublevel);
            
            CCLabelBMFont * label = (CCLabelBMFont *)buttonAnim->getChildByTag(1);
            int globalIndex = manager->getGlobalIndex();
            cstr = CCString::createWithFormat("%d", globalIndex);
            label->setString(cstr->getCString());
            label->setVisible(isLevelUnlocked);
            
            updateButtonState(buttonAnim, (int)buttonAnim->getUserData());
            
            if (button->getUserObject()) {
                button->getUserObject()->release();
            }
            CCArray * levelObject = CCArray::create(CCNumber::create(world), CCNumber::create(i), CCNumber::create(false), NULL);
            levelObject->retain();
            button->setUserObject(levelObject);
            
            
            NEAnimNode * flower = (NEAnimNode *)buttonAnim->getNodeByName("FLOWER");
            int starNum = manager->getStarNum();
            cstr = CCString::createWithFormat("%dIdle", starNum);
            flower->playAnimation(cstr->getCString());
            
            NEAnimNode * ring = (NEAnimNode *)buttonAnim->getNodeByName("Ring");
            ring->setVisible(isFurthestLevel);
            ring->playAnimation("Init");
        }
        else {
            
        }
    }
    
    
    NEAnimNode * buttonAnim = (NEAnimNode *)n->getNodeByName("Q1");
    CCControlButton * button = (CCControlButton *)buttonAnim->getNodeByName("1");
    if (info->unlockLevelCount > 0) {
        button->setEnabled(true);
        manager->setLevel(index, 0, true);
        
        
        CCString* cstr = CCString::createWithFormat("Jelly_Role%d.ani",index+1);
        NEAnimNode * jelly = (NEAnimNode *)buttonAnim->getNodeByName("jelly");
        if (manager->isFileExist(cstr->getCString())) {
            jelly->changeFile(cstr->m_sString.c_str());
        }
        
        bool isBeaten = manager->isLevelBeaten();
        bool isLevelUnlocked = manager->isLevelUnlocked() || manager->isPreLevelBeaten();
        if (manager->isWorldBeaten(true)) {
            isBeaten = true;
            isLevelUnlocked = true;
        }
        int flag = 0;
        flag |= isBeaten ? kButton_Passed : 0;
        flag |= !isLevelUnlocked ? kButton_Locked : 0;
        buttonAnim->setUserData((void *)flag);
        
        buttonAnim->setVisible(!m_hideSublevel);
        
        NEAnimNode * ring = (NEAnimNode *)buttonAnim->getNodeByName("Ring");
        ring->setVisible(isLevelUnlocked && !isBeaten);
        ring->playAnimation("Init");
        
        if (isBeaten) {
            cstr = CCString::createWithFormat("Idle%d",manager->getRandom()%2+1);
            jelly->playAnimation(cstr->m_sString.c_str());
        }else{
            jelly->playAnimation("ForCage");
        }
        
        updateButtonState(buttonAnim, (int)buttonAnim->getUserData());
        
        if (button->getUserObject()) {
            button->getUserObject()->release();
            button->setUserObject(NULL);
        }
        CCLabelBMFont * label = (CCLabelBMFont *)buttonAnim->getChildByTag(1);
        cstr = CCString::createWithFormat("V110_JELLY_NAME%d", world+1);
        label->setFntFile("font_8.fnt");
        label->setString(manager->getLocalizedString(cstr->getCString()));
        label->setVisible(isLevelUnlocked);
        
        CCArray * levelObject = CCArray::create(CCNumber::create(world), CCNumber::create(0), CCNumber::create(true), NULL);
        levelObject->retain();
        button->setUserObject(levelObject);
    }else{
        button->setEnabled(false);
        buttonAnim->setVisible(false);
    }

    manager->setLevel(wi, li, quest, branch);
    
//    m_avatar->setVisible(isAvatarIn);

    //delete info;
}
void FMWorldMapNode::hideSublevel(int idx)
{
    GAMEUI_Scene::uiSystem()->setNoUiCallback(CCCallFuncO::create(this, callfuncO_selector(FMWorldMapNode::noUiCallback), NULL));

//    m_hideSublevel = true;
    m_hideSublevel = false;

    m_avatar->setVisible(false);
    
    m_leftButton->setVisible(false);
    m_rightButton->setVisible(false);
    
    FMDataManager * manager = FMDataManager::sharedManager();
    FMUIWorldMap * bar = (FMUIWorldMap *)manager->getUI(kUI_WorldMap);
    bar->setVisible(false);

    int wi = idx;
    if (idx == -1) {
        wi = manager->getWorldIndex();
    }
    if (m_slider->getPageIndex() == wi) {
//        NEAnimNode * n = (NEAnimNode*)m_slider->getItemForRow(wi);
//        CCString * cstr = CCString::createWithFormat("Q%d", 1);
//        NEAnimNode * buttonAnim = (NEAnimNode *)n->getNodeByName(cstr->getCString());
//        buttonAnim->setVisible(false);
//        
//        buttonAnim = (NEAnimNode *)n->getNodeByName("ANIM");
//        buttonAnim->setVisible(false);
//        
//        for (int i = 0; i < 15; i++) {
//            CCString * cstr = CCString::createWithFormat("%d", i+1);
//            buttonAnim = (NEAnimNode *)n->getNodeByName(cstr->getCString());
//            buttonAnim->setVisible(false);
//        }
    }else{
////        m_slider->scrollToRow(wi);
        m_slider->setPageIndex(wi);
    }
}

void FMWorldMapNode::showSublevel()
{
    m_hideSublevel = false;
    m_avatar->setVisible(true);
    
    m_leftButton->setVisible(true);
    m_rightButton->setVisible(true);
    
    FMDataManager * manager = FMDataManager::sharedManager();
    FMUIWorldMap * bar = (FMUIWorldMap *)manager->getUI(kUI_WorldMap);
    bar->setVisible(true);

//    int wi = m_slider->getPageIndex();
//    if (!isWorldExist(wi)) {
//        return;
//    }
//    NEAnimNode * n = (NEAnimNode*)m_slider->getItemForRow(m_slider->getPageIndex());
//    BubbleLevelInfo * info = manager->getLevelInfo(wi);
//    NEAnimNode * buttonAnim = (NEAnimNode *)n->getNodeByName("Q1");
//    if (info && info->unlockLevelCount > 0) {
//        buttonAnim->setVisible(true);
//    }
//    
//    buttonAnim = (NEAnimNode *)n->getNodeByName("ANIM");
//    buttonAnim->setVisible(true);
//    
//    for (int i = 0; i < 15; i++) {
//        CCString * cstr = CCString::createWithFormat("%d", i+1);
//        buttonAnim = (NEAnimNode *)n->getNodeByName(cstr->getCString());
//        buttonAnim->setVisible(true);
//    }
}
void FMWorldMapNode::clickAvatarBtn(CCObject * object, CCControlEvent event)
{
    CCControlButton * btn = (CCControlButton *)object;
#ifdef BRANCH_CN
    CCSprite * spr = (CCSprite *)btn->getParent()->getChildByTag(2);
    spr->setOpacity(255);
    CCLabelTTF * label = (CCLabelTTF *)spr->getChildByTag(2);
    label->setOpacity(255);
    CCSequence * seq = CCSequence::create(CCDelayTime::create(2), CCFadeTo::create(0.2, 0), NULL);
    spr->stopAllActions();
    spr->runAction(seq);
    
    label->stopAllActions();
    label->runAction(CCSequence::create(CCDelayTime::create(2),CCFadeTo::create(0.2, 0),NULL));
#else
    if (!SNSFunction_isFacebookConnected()) {
        return;
    }
    CCNode * p = btn->getParent();
    if (p == m_avatar) {
        FMUIFriendProfile * window = (FMUIFriendProfile *)FMDataManager::sharedManager()->getUI(kUI_FriendProfile);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
        window->setProfile(NULL);
        return;
    }
    FMMapAvatarNode * node = (FMMapAvatarNode *)p->getParent();
    node->clickAvatarBtn(object, event);
#endif
}

void FMWorldMapNode::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    if (m_isPhaseRunning) {
        return;
    }

    CCNode * node = (CCNode *)object;
    int tag = node->getTag();
    int pageIndex = m_slider->getPageIndex();
    FMUIWorldMap * bar = (FMUIWorldMap *)FMDataManager::sharedManager()->getUI(kUI_WorldMap);
    
    switch (tag) {
        case 15:
        {
            //left
            if (pageIndex == 0) {
                //do nothing
            }
            else {
                m_slider->scrollToRow(pageIndex - 1);
            }
            
            bar->shrinkPopBar();
        }
            break;
        case 16:
        {
            //right
            int lastIndex = itemsCountForSlider(m_slider) -1;
            if (pageIndex == lastIndex) {
                //do nothing
            }
            else {
                m_slider->scrollToRow(pageIndex + 1);
            }
            
            bar->shrinkPopBar();
        }
            break;
        default:
            break;
    }
}

void FMWorldMapNode::clickUpdate(cocos2d::CCObject *object, CCControlEvent event)
{
    if (event == CCControlEventTouchDown) {
        m_isClicked = true;
    }
    
    if (event == CCControlEventTouchDragInside) {
        m_isClicked = false;
    }
    
    if (event == CCControlEventTouchUpInside && m_isClicked) {
        bool canUpdate = BubbleServiceFunction_isUpdateReady();
        if (canUpdate) {
            // update
            OBJCHelper::helper()->goUpdate();
        }
        else {
            //coming soon
        }
    }
}

void FMWorldMapNode::clickPlayBranch(cocos2d::CCObject *object, CCControlEvent event)
{
    if (event == CCControlEventTouchDown) {
        m_isClicked = true;
    }
    
    if (event == CCControlEventTouchDragInside) {
        m_isClicked = false;
    }
    
    if (event == CCControlEventTouchUpInside && m_isClicked) {
        showFamilyTree(true);
//        FMUIFamilyTree * window = (FMUIFamilyTree* )FMDataManager::sharedManager()->getUI(kUI_FamilyTree);
//        GAMEUI_Scene::uiSystem()->nextWindow(window);
    }
}

void FMWorldMapNode::clickSubLevel(cocos2d::CCObject *object, CCControlEvent event)
{
    if (m_isPhaseRunning) {
        if (m_phases.size() > 0) {
            AnimPhaseStruct & phase = m_phases.front();
            if (!m_avatar->getActionByTag(10) && phase.type != kPhase_Tutorial && phase.type != kPhase_TutorialUnlock && phase.type != kPhase_QuestComplete) {
                runPhase();
            }
            return;
        }
    }
    CCControlButton * button = (CCControlButton *)object;
    FMDataManager * manager = FMDataManager::sharedManager();
//    CCPoint index = manager->getIndexFromGlobalIndex(button->getTag());
    CCArray * levelObject = (CCArray *)button->getUserObject();

    int world = ((CCNumber *)levelObject->objectAtIndex(0))->getIntValue();
    int level = ((CCNumber *)levelObject->objectAtIndex(1))->getIntValue();
    bool isQuest = ((CCNumber *)levelObject->objectAtIndex(2))->getIntValue();
//    { 
//        NEAnimNode * targetButton = getLevelNode(world, level, isQuest); 
//        CCPoint targetPosition = targetButton->convertToWorldSpace(CCPointZero);
//        targetPosition = m_centerNode->convertToNodeSpace(targetPosition);
//        CCLog("pos %f, %f", targetPosition.x, targetPosition.y);
//    }
    NEAnimNode * animNode = (NEAnimNode *)getLevelNode(world, level, isQuest);
    int flag = (int)animNode->getUserData();
    bool isPressed = event == CCControlEventTouchDown || event == CCControlEventTouchDragEnter;
    bool isReleased = event == CCControlEventTouchDragExit || event == CCControlEventTouchUpInside;
    bool isDragging = event == CCControlEventTouchDragInside;
    if (isPressed) {
        flag |= kButton_Pressed;
    }
    else {
        flag &= ~kButton_Pressed;
    }
    if (isReleased) {
        flag |= kButton_Released;
    }
    else {
        flag &= ~kButton_Released;
    }
    if (level != -1 && !isDragging) {
        updateButtonState(animNode, flag, false);
    }

    if (event == CCControlEventTouchDown) {
        m_isClicked = true;
    }
    
    if (event == CCControlEventTouchDragInside) {
        m_isClicked = false;
    }

    if (event == CCControlEventTouchUpInside && m_isClicked) {
        kWorldButtonState s = (kWorldButtonState)(int)animNode->getUserData();
        if (s == kButton_Locked) {
            std::vector<int> rewardlevel = manager->getDailyRewardLevel();
            if (!isQuest) {
                if (world == rewardlevel[0] && level == rewardlevel[1]) {
                    FMUIDailyBoxPop * window = (FMUIDailyBoxPop *)manager->getUI(kUI_DailyBox);
                    GAMEUI_Scene::uiSystem()->nextWindow(window);
                    window->showTip(true);
                }
            }

            return;
        }
        manager->setLevel(world, level, isQuest);
        bool showBranch = false;
//        if (level == -1) {
//            if (manager->isWorldUnlocked()) {
//                //do nothing
//                return;
//            }
//        }
        
        if (isQuest) {
            //check if this is beaten
            if (manager->isWorldUnlocked()) {
                showBranch = true;
            }
            bool w = manager->isWorldBeaten(true);
            if (w) {
                showBranch = true;
            }
//            else {
//                return;
//            }
        }
        
        FMSound::playEffect("click.mp3", 0.1f, 0.1f);
        m_lastPosition = m_slider->getMainNode()->getPosition();
        if (showBranch) {
            FMUIBranchLevel * window = (FMUIBranchLevel* )manager->getUI(kUI_BranchLevel);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
        else {
            FMUILevelStart * window = (FMUILevelStart *)manager->getUI(kUI_LevelStart);
            kGameMode mode = (kGameMode)manager->getGameMode();
            window->setClassState(mode);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
    }
}

void FMWorldMapNode::onExit()
{
    updateToLatestState();
    CCLayer::onExit();
}

void FMWorldMapNode::onEnter()
{
    CCLayer::onEnter();
    m_isPhaseRunning = false;
    if (m_phases.size() > 0) {
        m_slider->setTouchEnabled(false);
        m_isPhaseRunning = true;
    }
    
    FMUIWorldMap * bar = (FMUIWorldMap *)FMDataManager::sharedManager()->getUI(kUI_WorldMap);
    bar->setVisible(true);
    m_hideSublevel = false;
    updateToLatestState();
    updatePhases();
    SNSFunction_setPopupStatus(true);
    FMDataManager* manager = FMDataManager::sharedManager();
    if (manager->getShowPopupFlag() == 0) {
        SNSFunction_showCNPopupOffer();
    }
    manager->setShowPopupFlag(manager->getShowPopupFlag()+1);
    
//    SNSFunction_showRandomPopup();
    checkGameCleared();
    
#ifdef BRANCH_CN
    int iconid = FMDataManager::sharedManager()->getUserIcon() - 1;
    CCString * iconname = CCString::createWithFormat("touxiang-%02d.png",iconid);
    CCSprite * icon = (CCSprite*)m_avatar->getChildByTag(1);
    CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(iconname->getCString());
    icon->setDisplayFrame(frame);
    CCSprite * namebg = (CCSprite *)m_avatar->getChildByTag(2);
    namebg->setOpacity(0);
    CCLabelTTF * name = (CCLabelTTF *)namebg->getChildByTag(2);
    name->setOpacity(0);
    name->setString(FMDataManager::sharedManager()->getLocalizedString("V110_ME_NAME"));
#else
    //FMDataManager * manager = FMDataManager::sharedManager();
    CCSprite * icon = (CCSprite*)m_avatar->getChildByTag(1);
    icon->removeChildByTag(1);
    const char * iconpath = SNSFunction_getFacebookIcon();
    if (iconpath && manager->isFileExist(iconpath)) {
        CCSprite * spr = CCSprite::create(iconpath);
        float size = 26.f;
        spr->setScale(size / MAX(spr->getContentSize().width, size));
        icon->addChild(spr, 0, 10);
        spr->setPosition(ccp(icon->getContentSize().width/2, icon->getContentSize().height/2));
    }
    CCSprite * namebg = (CCSprite *)m_avatar->getChildByTag(2);
    namebg->setOpacity(0);
    CCLabelTTF * name = (CCLabelTTF *)namebg->getChildByTag(2);
    name->setString(manager->getLocalizedString("V110_ME_NAME"));
    name->setOpacity(0);
#endif
    
    if (m_newVersionNode->getParent()) {
        m_newVersionNode->removeFromParent();
    }
    m_slider->getMainNode()->addChild(m_newVersionNode, 10000);
    
}

void FMWorldMapNode::slideDone()
{
    FMDataManager * manager = FMDataManager::sharedManager();
#ifdef BRANCH_CN
    CCArray * fid = manager->getFid();
    if (fid->count() > 1) {
        CCString * idstr = (CCString *)fid->objectAtIndex(0);
        if (strcmp(idstr->getCString(), "0") != 0) {
            CCNumber * type = (CCNumber *)fid->objectAtIndex(1);
            if (type->getIntValue() == 4) {
                OBJCHelper::helper()->postRequest(this, callfuncO_selector(FMWorldMapNode::onRequestFinished), kPostType_AddFriend);
            }else{
                OBJCHelper::helper()->postRequest(this, callfuncO_selector(FMWorldMapNode::onRequestFinished), kPostType_InviteFriend);
            }
        }
    }
#endif
//    manager->setLevel(m_worldIndex, m_levelIndex);

//    if (m_willUnlockBooster != kBooster_None) {
//        GAMEUI_Scene::uiSystem()->setNoUiCallback(CCCallFuncO::create(this, callfuncO_selector(FMWorldMapNode::noUiCallback), NULL));
//        //show unlock booster window
//        FMUIBooster * window = (FMUIBooster *)manager->getUI(kUI_Booster);
//        window->setBoosterType(m_willUnlockBooster);
//        window->setClassState(kUIBooster_Unlock);
//        GAMEUI_Scene::uiSystem()->nextWindow(window);
//        manager->setBoosterAmount(m_willUnlockBooster, 3);
//        m_willUnlockBooster = kBooster_None;
//    }
//    else {
//        noUiCallback();
//    }
    OBJCHelper::helper()->getFacebookMessages();
    OBJCHelper::helper()->postRequest(this, callfuncO_selector(FMWorldMapNode::onRequestFinished), kPostType_SyncFrdData);

    manager->checkNewTutorial();
//    manager->tutorialBegin();
    GAMEUI * ui = GAMEUI_Scene::uiSystem()->getCurrentUI();
    if (ui) {
        GAMEUI_Scene::uiSystem()->setNoUiCallback(CCCallFuncO::create(this, callfuncO_selector(FMWorldMapNode::noUiCallback), NULL));
    }
    else {
        noUiCallback();
    }
}
 
void FMWorldMapNode::noUiCallback()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
    if (scene->getCurrentSceneType() != kWorldMapNode) {
        return;
    }
    
    if (manager->isBranch()) {
        FMUIBranchLevel * window = (FMUIBranchLevel* )manager->getUI(kUI_BranchLevel);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
        return;
    }
    if (OBJCHelper::helper()->showUnlimitLife()) {
        GAMEUI_Scene::uiSystem()->setNoUiCallback(CCCallFuncO::create(this, callfuncO_selector(FMWorldMapNode::noUiCallback), NULL));
        return;
    }
    if (manager->showDailySign()) {
        GAMEUI_Scene::uiSystem()->setNoUiCallback(CCCallFuncO::create(this, callfuncO_selector(FMWorldMapNode::noUiCallback), NULL));
        return;
    }
    if (OBJCHelper::helper()->showFreeSpin()) {
        GAMEUI_Scene::uiSystem()->setNoUiCallback(CCCallFuncO::create(this, callfuncO_selector(FMWorldMapNode::noUiCallback), NULL));
        return;
    }
    if (!manager->isTutorialRunning()) {
//        FMStatusbar * status = (FMStatusbar *)manager->getUI(kUI_Statusbar);
        FMUIWorldMap * bar = (FMUIWorldMap *)FMDataManager::sharedManager()->getUI(kUI_WorldMap);
        if (bar->isHaveNewQuest() && manager->haveNewJelly()) {
            manager->checkNewTutorial("newbranch");
            bar->resetHaveNewQuest();
        }
    }
    manager->tutorialBegin();

    showSublevel();
    runPhase();
    
}

void FMWorldMapNode::updateUnlockBooster(int booster)
{
    m_willUnlockBooster = booster;
}


#pragma mark - phase 
CCPoint FMWorldMapNode::getScrollPosition(int worldIndex, int levelIndex, bool isQuest)
{
    NEAnimNode * animNode = getLevelNode(worldIndex, levelIndex, isQuest);
    CCPoint p = animNode->convertToWorldSpace(CCPointZero);
    p = m_slider->getItemForRow(worldIndex)->convertToNodeSpace(p);
    CCPoint pos = m_slider->getRowPosition(worldIndex);
    float y = p.y- pos.y;
    y = m_slider->checkBoundary(y);
    p.y = -y;
    p.x = 0.f;
    return p;
}

CCPoint FMWorldMapNode::getMapPosition(int worldIndex, int levelIndex, bool isQuest)
{
    m_slider->showItem(worldIndex);
    NEAnimNode * animNode = getLevelNode(worldIndex, levelIndex, isQuest);
    CCPoint localp = animNode->convertToWorldSpace(CCPointZero);
    localp = m_slider->getMainNode()->convertToNodeSpace(localp);
    return localp;
}

void FMWorldMapNode::pushPhase(int num, ...)
{
    va_list arguments;
    va_start(arguments, num);
    for (int i=0; i<num; i++) {
        pushPhase(va_arg(arguments, AnimPhaseStruct));
    }
    va_end(arguments);
}

void FMWorldMapNode::pushPhase(AnimPhaseStruct phase)
{
    m_phases.push_back(phase);
    switch (phase.type) {
        case kPhase_WorldUnlock:
        {
            m_willUpdateUnlock = phase.worldIndex;
        }
            break;
        default:
            break;
    }
}

void FMWorldMapNode::phaseDone()
{
    if (m_phases.size() == 0) {
        m_slider->setTouchEnabled(true);
        m_isPhaseRunning = false;
        return;
    }
    AnimPhaseStruct & phase = m_phases.front();
    switch (phase.type) {
        case kPhase_LevelUnlock:
        { 
            NEAnimNode * button = getLevelNode(phase.worldIndex, phase.levelIndex, phase.isQuest);
            if (phase.levelIndex != -1) {
                updateButtonState(button, (int)button->getUserData());
            }
        }
            break;
//        case kPhase_KeyFlying:
//        {
//            NEAnimNode * key = (NEAnimNode *)m_slider->getMainNode()->getChildByTag(1005);
//            key->removeFromParent();
//        }
//            break;
        default:
            break;
    }
    
    m_phases.pop_front();
    if (m_phases.size() != 0) {
        runPhase();
    }
    else {
        m_slider->setTouchEnabled(true);
        m_isPhaseRunning = false;
        //phase done
    }
}

void FMWorldMapNode::runPhase()
{
    if (m_phases.size() == 0) {
        return;
    } 
    AnimPhaseStruct & phase = m_phases.front();
    m_slider->showItem(phase.worldIndex);

    switch (phase.type) {
        case kPhase_WorldUnlock:
        {
            CCActionInterval * scroll = m_slider->scrollToRowAction(phase.worldIndex);
            CCCallFunc * call = CCCallFunc::create(this, callfunc_selector(FMWorldMapNode::worldUnlockCallback));
            CCSequence * seq = CCSequence::create(scroll, call, NULL);
            m_slider->getMainNode()->runAction(seq);            
        }
            break;
        case kPhase_ShowAdv:
        {
            FMDataManager * manager = FMDataManager::sharedManager();
            if (manager->getGlobalIndex(manager->getFurthestWorld(),manager->getFurthestLevel()) > 10) {
                //SNSFunction_showRandomPopup();
#ifdef SNS_ENABLE_MINICLIP
                SNSFunction_showPopupAd();
#else
                //SNSFunction_showCNPopupOffer();
#endif
            }
            phaseDone();
        }
            break;
        case kPhase_MoveAvatar:
        {
            CCPoint pStart = getMapPosition(phase.worldIndex, phase.levelIndex, phase.isQuest);
            std::vector<int> nextLevel = FMDataManager::sharedManager()->getNextLevel(phase.worldIndex, phase.levelIndex);
            CCPoint pEnd;
            if (nextLevel[0] == -1) {
                pEnd = getMapPosition(phase.worldIndex, 0, true);
                
            }else if (nextLevel[0] != phase.worldIndex && nextLevel[1] == 0){
                pEnd = getMapPosition(phase.worldIndex, 0, true);
                
            }else{
                pEnd = getMapPosition(nextLevel[0], nextLevel[1], false);
            }
            
            static float moveSpeed = 1.f;
            pStart.y += kAvatarOffsetY;
            pEnd.y += kAvatarOffsetY;
            if (phase.levelIndex == -1) {
                pStart.x -= kTreeTrunkOffsetX;
            }
            
            m_avatar->setPosition(pStart);
            CCMoveTo * m = CCMoveTo::create(moveSpeed, pEnd);
            CCCallFunc * call = CCCallFunc::create(this, callfunc_selector(FMWorldMapNode::phaseDone));
            CCSequence * seq = CCSequence::create(m, call, NULL);
            seq->setTag(10);
            m_avatar->runAction(seq);
        }
            break;
        case kPhase_PopStars:
        {
            FMDataManager * manager = FMDataManager::sharedManager();
            NEAnimNode * animNode = getLevelNode(phase.worldIndex, phase.levelIndex, phase.isQuest);
            NEAnimNode * flower = (NEAnimNode *)animNode->getNodeByName("FLOWER");
            int starNum = manager->getStarNum();
            if (starNum > 0) {
                CCString * s = CCString::createWithFormat("to%d", starNum);
                flower->playAnimation(s->getCString());
                flower->setDelegate(this);
            }
            else {
                //CCAssert(0, "");
                phaseDone();
            }
        }
            break;
        case kPhase_LevelUnlock:
        { 
            NEAnimNode * animNode = getLevelNode(phase.worldIndex, phase.levelIndex, phase.isQuest);
            if (phase.levelIndex == -1) {
                int flag = (int)animNode->getUserData();
                flag &= ~kButton_Locked;
                animNode->setUserData((void *)flag);
                animNode->playAnimation("idle2");
                //this is a loop animation, no end
                phaseDone();
            }
            else {
                
                int flag = (int)animNode->getUserData();
                flag &= ~kButton_Locked;
                animNode->setUserData((void *)flag);
                animNode->setDelegate(this);
                animNode->playAnimation("LockToNormal");
                if (phase.isQuest) {
                    FMSound::playEffect("unlocklock.mp3");                    
                }
                else {
                    FMSound::playEffect("unlocklevel.mp3");
                }

                CCLabelBMFont * label = (CCLabelBMFont *)animNode->getChildByTag(1);
                label->setVisible(true);
            }
        }
            break;
        case kPhase_QuestPassed:
        {
            //made the button not passed
            NEAnimNode * buttonAnim = getLevelNode(phase.worldIndex, phase.levelIndex, phase.isQuest);
            
            int flag = 0;
            flag |= kButton_Passed;
            buttonAnim->setUserData((void *)flag);
            buttonAnim->setVisible(true);
            NEAnimNode * flower = (NEAnimNode *)buttonAnim->getNodeByName("FLOWER");
            int starNum = 0;
            CCString * cstr = CCString::createWithFormat("%dIdle", starNum);
            flower->playAnimation(cstr->getCString());
            
            updateButtonState(buttonAnim, (int)buttonAnim->getUserData());
            phaseDone();
        }
            break;
        case kPhase_QuestComplete:
        {
            NEAnimNode * anim = NEAnimNode::createNodeFromFile("FMWorldMap_QuestButton.ani");
            anim->releaseControl("jelly", kProperty_Animation);
            NEAnimNode * jelly = (NEAnimNode*)anim->getNodeByName("jelly");
            CCString* cstr = CCString::createWithFormat("Jelly_Role%d.ani",phase.worldIndex+1);
            if (!FMDataManager::sharedManager()->isFileExist(cstr->getCString())) {
                phaseDone();
                return;
            }
            jelly->changeFile(cstr->m_sString.c_str());
            m_centerNode->addChild(anim, 100);
            anim->playAnimation("QuestPass");
            anim->setAutoRemove(true);
            anim->setDelegate(this);
            
            ccColor4B color = {0,0,0,128};
            CCLayerColor* l = CCLayerColor::create(color);
            CCPoint cp = anim->convertToWorldSpace(anim->getPosition());
            l->setPosition(-cp.x, -cp.y);
            anim->addChild(l,0,-1);
        }
            break;
        case kPhase_TutorialUnlock:
        {
            NEAnimNode * anim = NEAnimNode::createNodeFromFile("FMUI_GuideNPC.ani");
            m_centerNode->addChild(anim, 100);
            anim->playAnimation("Release");
            anim->setAutoRemove(true);
            anim->setDelegate(this);
            
            ccColor4B color = {0,0,0,128};
            CCLayerColor* l = CCLayerColor::create(color);
            CCPoint cp = anim->convertToWorldSpace(anim->getPosition());
            l->setPosition(-cp.x, -cp.y);
            anim->addChild(l,0,-1);
        }
            break;
        case kPhase_Tutorial:
        {
            FMDataManager* manager = FMDataManager::sharedManager();
            manager->setWorldInPhase(false);
            manager->checkNewTutorial("jellyRelease");
            manager->tutorialBegin();
            if (!manager->isTutorialRunning()) {
                phaseDone();
            }
        }
            break;
        case kPhase_NextLevel:
        {
            FMDataManager* manager = FMDataManager::sharedManager();
            GAMEUI * ui = GAMEUI_Scene::uiSystem()->getCurrentUI();
            if (!manager->isTutorialRunning() && !ui) {
                m_slider->scrollToRow(phase.worldIndex);
                manager->setLevel(phase.worldIndex, phase.levelIndex, phase.isQuest);
                FMUILevelStart * window = (FMUILevelStart *)manager->getUI(kUI_LevelStart);
                kGameMode mode = (kGameMode)manager->getGameMode();
                window->setClassState(mode);
                GAMEUI_Scene::uiSystem()->nextWindow(window);
            }
            phaseDone();
        }
            break;
        case kPhase_GetBonus:
        {
            FMUIDailyBoxPop * window = (FMUIDailyBoxPop *)FMDataManager::sharedManager()->getUI(kUI_DailyBox);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
            window->showTip(false);
        }
            break;
//        case kPhase_KeyFlying:
//        {
//            NEAnimNode * key = (NEAnimNode *)m_slider->getMainNode()->getChildByTag(1005);
//            CCPoint pEnd = getMapPosition(phase.worldIndex, -1, false);
//            
//            NEAnimNode * tree = getLevelNode(phase.worldIndex, -1, false);
//            tree->setVisible(true);
//            CCString * s = CCString::createWithFormat("%d", phase.levelIndex + 1);
//            NEAnimNode * keyNode = (NEAnimNode *)tree->getNodeByName(s->getCString());
//            CCPoint pOffset = keyNode->getPosition();
//            pEnd = ccpAdd(pEnd, pOffset);
//            
//            static float moveSpeed = 0.5f;
//            CCMoveTo * m = CCMoveTo::create(moveSpeed, pEnd);
//            CCCallFunc * call = CCCallFunc::create(this, callfunc_selector(FMWorldMapNode::phaseDone));
//            CCSequence * seq = CCSequence::create(m, call, NULL);
//            key->runAction(seq);
////            m_slider->getMainNode()->addChild(key, 1005, 1005);
//
//            m_slider->getMainNode()->setPosition(m_lastPosition);
//            NEAnimNode * targetButton = getLevelNode(phase.worldIndex, -1, false);
//            CCPoint targetPosition = targetButton->convertToWorldSpace(CCPointZero);
//            targetPosition = m_centerNode->convertToNodeSpace(targetPosition);
//            CCLog("pos %f, %f", targetPosition.x, targetPosition.y);
//            if (targetPosition.y > 100 ) {
//                float offset = targetPosition.y - 100;
//                targetPosition = ccp(m_lastPosition.x, m_lastPosition.y - offset);
//                m_lastPosition = targetPosition;
//                if (!m_slider->isScrolling()) {
////                    m_slider->getMainNode()->setPosition(m_lastPosition);
//                    CCMoveTo * m2 = CCMoveTo::create(0.3f, targetPosition);
//                    m_slider->getMainNode()->runAction(m2);
//                    m_slider->updateShowRange(m_slider->getSingleValue(targetPosition));
//                }
//            }
//            
////            CCPoint scrollPosition = getScrollPosition(phase.worldIndex, -1, false);
////            float f = m_slider->getSingleValue(scrollPosition);
////            f = m_slider->checkBoundary(f);
////            scrollPosition = m_slider->getPointFromSingleValue(f);
////            
////            if (!m_slider->isScrolling()) {
////                CCMoveTo * m2 = CCMoveTo::create(moveSpeed, scrollPosition);
////                m_slider->getMainNode()->runAction(m2);
////                m_slider->updateShowRange(m_slider->getSingleValue(scrollPosition));
////            }
//        }
//            break;
//        case kPhase_TreeOpenLock:
//        {
//            int index = phase.levelIndex;
//            NEAnimNode * tree = getLevelNode(phase.worldIndex, -1, false);
//            CCString * s = CCString::createWithFormat("%d", index + 1);
//            NEAnimNode * lock = (NEAnimNode *)tree->getNodeByName(s->getCString());
//            lock->playAnimation("Unlock");
//            lock->setDelegate(this);
//        }
//            break;
//        case kPhase_TreeRemove:
//        {
//            NEAnimNode * tree = getLevelNode(phase.worldIndex, -1, false);
//            tree->setVisible(true);
//            tree->playAnimation("unlock");
//            tree->setDelegate(this); 
//        }
//            break;
//        case kPhase_CloudsFade:
//        {
//            CCPoint p = m_slider->getRowPosition(phase.worldIndex);
//            m_slider->updateShowRange(m_slider->getSingleValue(p));
//            NEAnimNode * world = (NEAnimNode *)m_slider->getItemForRow(phase.worldIndex);
//            NEAnimNode * clouds = (NEAnimNode *)world->getNodeByName("CLOUDS");
//            clouds->playAnimation("Unlock");
//            clouds->setVisible(true);
//            phaseDone();
//        }
//            break;
        default:
            break;
    }
}

void FMWorldMapNode::cleanPhase()
{
    m_phases.clear();
    m_isPhaseRunning = false;
}


void FMWorldMapNode::animationEnded(neanim::NEAnimNode *node, const char *animName)
{
    node->setDelegate(NULL);
//    CCLog("animation done %s, phase done", animName);
    phaseDone();
}



void FMWorldMapNode::updateButtonState(neanim::NEAnimNode *animNode, int flag, bool refresh)
{
    
    if (flag & kButton_Locked) {
        animNode->playAnimation("Locked");
        return;
    }
    int passed  = flag & kButton_Passed ? 1 : 2;
    const char * key = "";
    if (flag & kButton_Pressed)
    {
        key = "Pressed";
    }
    else if (flag & kButton_Highlighted) {
        key = "NormalShine";
    }
    else if (flag & kButton_Released) {
        key = "Release";
    }
    else {
        key = "Normal";
    }
    CCString * s = CCString::createWithFormat("%s%d", key, passed);

    animNode->playAnimation(s->getCString(), 0, false, !refresh);
}

void FMWorldMapNode::clearCurrentButton()
{
    if (m_currentButton) {
        int flag = (int)m_currentButton->getUserData();
        flag &= ~kButton_Highlighted;
        m_currentButton->setUserData((void *)flag);
        updateButtonState(m_currentButton, flag);
        m_currentButton = NULL;
    }
}




NEAnimNode * FMWorldMapNode::getLevelNode(int world, int level, bool isQuest)
{
    NEAnimNode * node = (NEAnimNode *)m_slider->getItemForRow(world);
    const char * key = NULL;
    if (level == -1) {
//        key = "BLOCK";
    }
    else {
        if (isQuest) {
            key = "Q%d";
            CCString * str = CCString::createWithFormat(key, level+1);
            key = str->getCString();
        }
        else {
            key = "%d";
            CCString * str = CCString::createWithFormat(key, level+1);
            key = str->getCString();
        }
    }
    NEAnimNode * animNode = (NEAnimNode *)node->getNodeByName(key);
    return animNode;
}


void FMWorldMapNode::updateToLatestState()
{
//    m_slider->refresh();
}

void FMWorldMapNode::updatePhases()
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    int count = 0;
#endif
    //update all phases that will change the map
    if (m_phases.size() != 0) {
        for (std::list<AnimPhaseStruct>::iterator it = m_phases.begin(); it != m_phases.end(); it++) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
            count ++;
            if(count > m_phases.size()) {
                break;
            }
#endif
            AnimPhaseStruct & phase = *it;
            
            switch (phase.type) {
                case kPhase_WorldUnlock:
                {
                    m_willUpdateUnlock = phase.worldIndex;
                }
                    break;
                case kPhase_MoveAvatar:
                {
                    std::vector<int> nextLevel = FMDataManager::sharedManager()->getNextLevel(phase.worldIndex, phase.levelIndex);
                    
//                    if (nextLevel[0] != -1) {
//                        NEAnimNode * button = getLevelNode(nextLevel[0], nextLevel[1], false);
//                        int flag = (int)button->getUserData();
//                        flag |= kButton_Locked;
//                        flag &= ~kButton_Highlighted;
//                        button->setUserData((void *)flag);
//                        updateButtonState(button, flag);
//                    }
                }
                    break;
                case kPhase_PopStars:
                {
                    m_slider->showItem(phase.worldIndex);
                    NEAnimNode * button = getLevelNode(phase.worldIndex, phase.levelIndex, phase.isQuest);
                    int flag = (int)button->getUserData();
                    flag |= kButton_Passed;
                    button->setUserData((void *)flag);
                    updateButtonState(button, flag);
                    
                    NEAnimNode * flower = (NEAnimNode *)button->getNodeByName("FLOWER");
                    flower->playAnimation("0Idle");
                }
                    break;
                case kPhase_LevelUnlock:
                {
                    m_slider->setPageIndex(phase.worldIndex);
                    NEAnimNode * button = getLevelNode(phase.worldIndex, phase.levelIndex, phase.isQuest);
                    int flag = (int)button->getUserData();
                    flag &= ~kButton_Highlighted;
                    flag |= kButton_Locked;
                    button->setUserData((void *)flag);
                    updateButtonState(button, flag);
                    
                    clearCurrentButton();
                    if (phase.levelIndex != -1) {
                        m_currentButton = button;
                    }
                    
                    //show all quest buttons
                    if (phase.levelIndex == -1) {
                        for (int i=0; i<3; i++) {
                            NEAnimNode * questButton = getLevelNode(phase.worldIndex, i, true);
                            questButton->setVisible(true);
                            questButton->playAnimation("Pop");
                        }
                    }
                }
                    break;
                case kPhase_QuestPassed:
                {
                    //made the button not passed
                    NEAnimNode * button = getLevelNode(phase.worldIndex, phase.levelIndex, phase.isQuest);
                    int flag = (int)button->getUserData();
                    flag |= kButton_Highlighted;
                    flag &= ~kButton_Locked;
                    button->setUserData((void *)flag);
                }
                    break;
//                case kPhase_KeyFlying:
//                {
//                    NEAnimNode * questButton = getLevelNode(phase.worldIndex, phase.levelIndex, phase.isQuest);
//                    int flag = (int)questButton->getUserData();
//                    flag |= kButton_Passed;
//                    questButton->setUserData((void*) flag);
//                    updateButtonState(questButton, flag);
//                      
//                    NEAnimNode * tree = getLevelNode(phase.worldIndex, -1, false);
//                    CCString * s = CCString::createWithFormat("%d", phase.levelIndex + 1);
//                    NEAnimNode * lock = (NEAnimNode *)tree->getNodeByName(s->getCString());
//                    lock->playAnimation("Init");
//                    tree->setVisible(true);
//                    
//                    NEAnimNode * key = NEAnimNode::createNodeFromFile("FMKey.ani"); 
//                    key->playAnimation("Shine");
//                    CCPoint pStart = getMapPosition(phase.worldIndex, phase.levelIndex, phase.isQuest);
//                    pStart.y += 48.f;
//                    key->setPosition(pStart);
//                    m_slider->getMainNode()->addChild(key, 1005, 1005);
//                }
//                    break; 
//                case kPhase_TreeOpenLock:
//                {
//                    NEAnimNode * questButton = getLevelNode(phase.worldIndex, phase.levelIndex, phase.isQuest);
//                    int flag = (int)questButton->getUserData();
//                    flag |= kButton_Passed;
//                    questButton->setUserData((void*) flag);
//                    updateButtonState(questButton, flag);
//                }
//                    break;
//                case kPhase_TreeRemove:
//                {
//                    //make 3 quest to passed
//                    for (int i =0; i<3; i++) {
//                        NEAnimNode * quest = getLevelNode(phase.worldIndex, i, true);
//                        int flag = (int)quest->getUserData();
//                        flag |= kButton_Passed;
//                        quest->setUserData((void*)flag);
//                        updateButtonState(quest, flag);
//                    }
//                }
//                    break;
//                case kPhase_CloudsFade:
//                {
//                    CCPoint p = m_slider->getRowPosition(phase.worldIndex);
//                    m_slider->updateShowRange(m_slider->getSingleValue(p));
//                    NEAnimNode * world = (NEAnimNode *)m_slider->getItemForRow(phase.worldIndex);
//                    NEAnimNode * clouds = (NEAnimNode *)world->getNodeByName("CLOUDS");
//                    clouds->playAnimation("Locked");
//                    clouds->setVisible(true); 
//                }
//                    break;
                case kPhase_ComingSoon:
                {
//                    updateWorld(itemsCountForSlider(m_slider)-1);
                    phaseDone();
                }
                    break;
                default:
                    break;
            }

        }
    }
}
kAnimPhaseType FMWorldMapNode::getCurrentPhaseType()
{
    if (m_phases.size() == 0) {
        return kPhase_NULL;
    }
    AnimPhaseStruct & phase = m_phases.front();
    return phase.type;
}

void FMWorldMapNode::initMapPosition()
{ 
    cleanPhase();
    m_slider->getMainNode()->stopAllActions();
    m_avatar->stopAllActions();
    FMDataManager * manager = FMDataManager::sharedManager();
    int world = manager->getFurthestWorld();
    int level = manager->getFurthestLevel();
    if (world >= BubbleServiceFunction_getLevelCount()) {
        world = 0;
        level = 0;
    }
    CCPoint p = getMapPosition(world, level, false);
    
    int wi = manager->getWorldIndex();
    int li = manager->getLevelIndex();
    bool q = manager->isQuest();
    bool b = manager->isBranch();
    
    manager->setLevel(world, level, false);
    if (manager->isLevelBeaten()) {
        p = getMapPosition(world, 0, true);
    }
    
    manager->setLevel(wi, li, q, b);
    p.y += kAvatarOffsetY;
    if (level == -1) {
        p.x -= kTreeTrunkOffsetX;
    }
    m_avatar->setPosition(p);
    
    std::vector<int> dailyLevel = manager->getDailyRewardLevel();
    if (dailyLevel[0] >= 0 && dailyLevel[1] >= 0) {
        int w = dailyLevel[0];
        int l = dailyLevel[1];
        p = getMapPosition(w, l, false);
        CCNode * n = (CCNode *)m_dailyBox;
        n->setPosition(p);
    }
    
    //    p = getScrollPosition(world, level, false);
    m_slider->setPageIndex(world);
    m_lastPosition = p;
}

CCPoint FMWorldMapNode::getTutorialPosition(int index)
{
    switch (index) {
        case 0:
        {
            //boss, world 0
            CCPoint p = getScrollPosition(0, 0, false);
//            m_slider->getMainNode()->setPosition(p);
            m_slider->setPageIndex(0);
            m_slider->updateShowRange(m_slider->getSingleValue(p));
            
            NEAnimNode * world = (NEAnimNode *)m_slider->getItemForRow(0);
            NEAnimNode * boss = (NEAnimNode *)world->getNodeByName("BOSS");
            CCPoint wp = boss->convertToWorldSpace(CCPointZero);
            return wp;
        }
            break;
        case 1:
        {
            //level 2 button, world 0
            CCPoint p = getScrollPosition(0, 0, false);
            m_slider->setPageIndex(0);
            m_slider->updateShowRange(m_slider->getSingleValue(p));
            
            NEAnimNode * button = getLevelNode(0, 1, false);
            CCPoint wp = button->convertToWorldSpace(CCPointZero);
            return wp;
        }
            break;
        case 2:
        {
            //world 0, quest
            m_slider->setPageIndex(0);
            NEAnimNode * quest = getLevelNode(0, 0, true);
            CCPoint wp = quest->convertToWorldSpace(CCPointZero);
            return wp;
        }
            break;
            
        default:
            break;
    }
    return CCPointZero;
}

void FMWorldMapNode::worldUnlockCallback()
{
    int world = m_slider->getPageIndex();
    FMDataManager::sharedManager()->setLevel(world, 0, false);
    NEAnimNode * node = (NEAnimNode *)m_slider->getItemForRow(world);
    NEAnimNode * clouds = (NEAnimNode *)node->getNodeByName("CLOUDS");
    clouds->playAnimation("ChapterUnlock");
    clouds->setVisible(true);
    clouds->setDelegate(this);
    
    //move avatar to first button
    CCPoint pEnd = getMapPosition(world, 0, false);
    //move avatar
    pEnd.y += kAvatarOffsetY;
    m_avatar->setPosition(pEnd);
    
    m_willUpdateUnlock = -1;
    
    SNSFunction_showPopupAd();
}

bool FMWorldMapNode::isWorldExist(int rowIndex)
{
    if (rowIndex == itemsCountForSlider(m_slider)-1) {
        return false;
    }
    bool exist = true;
    const char * worldName = CCString::createWithFormat("World%d", rowIndex +1)->getCString();
    NEAnimFileData * animData = NEAnimManager::sharedManager()->getSharedDataForFile("FMWorld.ani");
    if (!animData->hasAnimationNamed(worldName)) {
        exist = false;
        return exist;
    }
//#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
//
//    const char * worldTextureFilename = CCString::createWithFormat("WorldBG%d.plist", rowIndex + 1)->getCString();
//    const char * path = SNSFunction_getDownloadSubFolderFilePath("1x", worldTextureFilename);
//    FMDataManager * manager = FMDataManager::sharedManager();
//    if (!manager->isFileExist(path)) {
//        //check local file
//        std::string filepath = CCFileUtils::sharedFileUtils()->fullPathForFilename(worldTextureFilename);
//        if (!manager->isFileExist(filepath.c_str())) {
//            exist = false;
//        }
//    }
//#endif
    return exist;
}

void FMWorldMapNode::onFileDownloaded(cocos2d::CCString *fileName)
{
    std::string subString = std::string(fileName->getCString());
    CCString * verString = CCString::createWithFormat("%s_WORLDMAP", RES_FOLDER);
    if (subString.compare(verString->getCString()) == 0) {
        CCFileUtils::sharedFileUtils()->purgeCachedEntries();
        std::string fullPath = CCFileUtils::sharedFileUtils()->fullPathForFilename("FMWorld.ani");
        m_slider->purgeCachedItems();
        NEAnimManager::sharedManager()->reloadDataWithFile(fullPath.c_str());
        m_slider->createItems();
        m_slider->refresh();
    }
    FMDataManager* manager = FMDataManager::sharedManager();
    const char * remotePath = SNSFunction_getDownloadFilePath(RES_FOLDER);
    CCString * str = CCString::createWithFormat("%s/%s", remotePath, "tutorial.dat");
    if (manager->isFileExist(str->getCString())) {
        manager->initTutorial();
    }
    str = CCString::createWithFormat("%s/%s",remotePath,"LOCALIZATION.csv");
    if (manager->isFileExist(str->getCString())) {
        manager->reloadLocalizedString();
    }
    manager->resetTotalStarsNumber();
}
void FMWorldMapNode::requestFriendsData()
{
    OBJCHelper::helper()->postRequest(this, callfuncO_selector(FMWorldMapNode::onRequestFinished), kPostType_SyncFrdData);
}

void FMWorldMapNode::onRequestFinished(CCDictionary * dic)
{
    FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
    if (scene->getCurrentSceneType() != kWorldMapNode) {
        return;
    }
    
    int page = m_slider->getPageIndex();
    NEAnimNode * node = (NEAnimNode *)m_slider->getItemForRow(page);
    updateWorld(node, page);
#ifdef BRANCH_CN
    return;
#endif
    FMDataManager * manager = FMDataManager::sharedManager();
    CCSprite * icon = (CCSprite*)m_avatar->getChildByTag(1);
    icon->removeChildByTag(1);
    const char * iconpath = SNSFunction_getFacebookIcon();
    if (iconpath && manager->isFileExist(iconpath)) {
        CCSprite * spr = CCSprite::create(iconpath);
        float size = 30.f;
        spr->setScale(size / MAX(spr->getContentSize().width, size));
        icon->addChild(spr, 0, 10);
        spr->setPosition(ccp(icon->getContentSize().width/2, icon->getContentSize().height/2));
    }
    CCSprite * namebg = (CCSprite *)m_avatar->getChildByTag(2);
    namebg->setOpacity(0);
    CCLabelTTF * name = (CCLabelTTF *)namebg->getChildByTag(2);
    name->setString("You");
    name->setOpacity(0);
    
    int world = manager->getFurthestWorld();
    int level = manager->getFurthestLevel();
    bool over = false;
    for (int i = 0; i < BubbleServiceFunction_getLevelCount(); i++) {
        BubbleLevelInfo * info = manager->getLevelInfo(i);
        for (int j = 0; j < info->subLevelCount; j++) {
            bool unlock = manager->isLevelUnlocked(i, j, 0)||manager->isPreLevelBeaten(i, j, 0);
            bool beaten = manager->isLevelBeaten(i, j, 0)||manager->getStarNum(i, j, 0)>0;
            if (unlock && !beaten) {
                over = true;
                manager->setFurthestLevel(i, j, 0);
                break;
            }else if (!unlock){
                over = true;
                break;
            }
        }
        if (over) {
            break;
        }
    }

    int tw = manager->getFurthestWorld();
    int tl = manager->getFurthestLevel();
    if ((tw == world && tl == level)||(tw == world+1 && tl == 0)) {
        return;
    }
    
    m_avatar->stopAllActions();
    m_slider->getMainNode()->stopAllActions();

    world = manager->getFurthestWorld();
    level = manager->getFurthestLevel();
    if (world >= BubbleServiceFunction_getLevelCount()) {
        world = 0;
        level = 0;
    }
    CCPoint p = getMapPosition(world, level, false);
    
    if (manager->isLevelBeaten(world, level, 0)) {
        p = getMapPosition(world, 0, true);
    }
    
    p.y += kAvatarOffsetY;
    if (level == -1) {
        p.x -= kTreeTrunkOffsetX;
    }
    m_avatar->setPosition(p);
    m_slider->setPageIndex(world);
//    m_slider->refresh();
}

CCSpriteFrame * FMWorldMapNode::getCurrentWorldBGFrame()
{
    int pageIndex = m_slider->getPageIndex();
    if (isWorldExist(pageIndex)) {
        NEAnimNode * world = (NEAnimNode *)m_slider->getItemForRow(pageIndex);
        CCSprite * map = (CCSprite *)world->getNodeByName("Map");
        return map->displayFrame();
    }
    else {
        return CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("WorldBG1.plist|WorldBG1.png");
    }
}

void FMWorldMapNode::checkGameCleared()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    if (manager->isGameCleared()) {
        m_gameAdvance = kAdvance_AllComplete;
        int i = 0;
        while (1) {
            if (!isWorldExist(i)) {
                return;
            }
            if (!manager->isChallengeCleared(i)) {
                m_gameAdvance = kAdvance_MasterComplete;
                return;
            }
            i++;
        }

    }else{
        m_gameAdvance = kAdvance_Normal;
        return;
    }
}

void FMWorldMapNode::showFamilyTree(bool scroll)
{
//    if (scroll) {
//        m_slider->scrollToRow(m_slider->getItemsCount()-2);
//    }else{
//        m_slider->setPageIndex(m_slider->getItemsCount()-2);
//    }
    FMUIFamilyTree * window = (FMUIFamilyTree* )FMDataManager::sharedManager()->getUI(kUI_FamilyTree);
    GAMEUI_Scene::uiSystem()->nextWindow(window);
}

void FMWorldMapNode::showBranchLevel()
{
    int index = m_slider->getPageIndex();
    FMDataManager * manager = FMDataManager::sharedManager();
    if (manager->isLevelBeaten(index, 0, 1)) {
        manager->setLevel(index, 0, 1, 1);
        FMUIBranchLevel * window = (FMUIBranchLevel* )manager->getUI(kUI_BranchLevel);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
    }else{
        
    }
}

void FMWorldMapNode::setAvatarEnable(bool flag)
{
    if (m_avatar) {
        CCControlButton * btn = (CCControlButton *)m_avatar->getChildByTag(10);
        btn->setEnabled(flag);
    }
}

