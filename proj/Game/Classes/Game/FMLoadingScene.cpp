//
//  FMLoadingScene.cpp
//  FarmMania
//
//  Created by  James Lee on 13-6-9.
//
//

#include "FMLoadingScene.h"
#include "AppDelegate.h"
#include "FMSoundManager.h"
#include "FMDataManager.h"
#include "FMMainScene.h"
#include "FMWorldMapNode.h"
#include "SNSFunction.h"
#include "OBJCHelper.h"

#include "FMStoryScene.h"

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include "SNSGameHelper.h"
#endif

const char * preloadTextureFiles[] = {
//    "Boosters.pvr.ccz",
//    "CCBUI.pvr.ccz",
//    "Editor.pvr.ccz",
//    "Elements.pvr.ccz",
//    "GridEffects.pvr.ccz",
//    "Map.pvr.ccz",
//    "Missing.pvr.ccz",
//    "SpecialElements.pvr.ccz",
//    "UIAnim.pvr.ccz",
//    "UIEffects.pvr.ccz",
//    "WorldBG1.pvr.ccz",
//    "WorldBG2.pvr.ccz",
//    "WorldBG3.pvr.ccz",
//    "WorldBG4.pvr.ccz",
//    "WorldMap.pvr.ccz",
//    "WorldMapButtons.pvr.ccz"
};
FMLoadingScene::FMLoadingScene() :
    m_loadingLabel(NULL),
    m_time(0.f),
    m_texturesLoaded(false),
    m_uiLoaded(false),
    m_count(0),
    m_index(0),
    m_playClicked(false),
    m_fbClicked(false)
{
    FMDataManager * manager = FMDataManager::sharedManager();
    
    AppDelegate * app = (AppDelegate *)CCApplication::sharedApplication();
    app->initialize();
    

    FMSound::setMusicOn(manager->isMusicOn());
    FMSound::setEffectOn(manager->isSFXOn());
    FMSound::playMusic("main_bg.mp3");
    
    for (int i=0; i<9; i++) {
        CCString * fi = CCString::createWithFormat("font_%d.png", i+1);
        CCTexture2D * tex = CCTextureCache::sharedTextureCache()->addImage(fi->getCString());
        tex->retain();
        tex->setDefaultAlphaPixelFormat(kTexture2DPixelFormat_RGBA4444);
    }
    
    m_ccbNode = manager->createNode("UI/FMUILoading.ccbi", this);
    addChild(m_ccbNode);
    
    CCLabelBMFont * loadinglabel = m_loadingLabel;
    CCSize s = loadinglabel->getContentSize();
    CCPoint p = loadinglabel->getPosition();
    m_loadingLabel2 = CCLabelBMFont::create("", loadinglabel->getFntFile());
    m_loadingLabel2->setPosition(ccp(p.x + s.width * 0.5f, p.y));
    m_loadingLabel2->setAnchorPoint(ccp(0.f, 0.5f));
    loadinglabel->getParent()->addChild(m_loadingLabel2);
    
//#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
//    CCTextureCache::sharedTextureCache()->addImageAsync(preloadTextureFiles[m_index], this, callfuncO_selector(FMLoadingScene::textureLoadDone));
//#endif
    
}

FMLoadingScene::~FMLoadingScene()
{
    removeAllChildrenWithCleanup(true);
    CCSpriteFrameCache::sharedSpriteFrameCache()->removeSpriteFramesFromFile("loading.plist"); 
    CCTextureCache::sharedTextureCache()->removeUnusedTextures();
//    CCTextureCache::sharedTextureCache()->dumpCachedTextureInfo();
}


#pragma mark - CCB Bindings
bool FMLoadingScene::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_loadingLabel", CCLabelBMFont *, m_loadingLabel);
    return true;
}

SEL_CCControlHandler FMLoadingScene::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMLoadingScene::clickButton);
    return NULL;
}

void FMLoadingScene::clickButton(CCObject * object)
{
    CCControlButton * button = (CCControlButton *)object;
    switch (button->getTag()) {
        case 0:
        {
            //play
            if (m_playClicked) {
                return;
            }
            CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
            anim->runAnimationsForSequenceNamed("InitEN2");

            runAction(CCSequence::create(CCDelayTime::create(0.2f),CCCallFunc::create(this, callfunc_selector(FMLoadingScene::playAction)), NULL));
        }
            break;
        case 1:
        {
            //connect
            if (m_fbClicked) {
                return;
            }
            m_fbClicked = true;
            OBJCHelper::helper()->connectToFacebook(this);
        }
            break;
        default:
            break;
    }
}

void FMLoadingScene::playAction()
{
    m_playClicked = true;
    FMDataManager * manager = FMDataManager::sharedManager();
    FMMainScene *pScene = (FMMainScene *)manager->getUI(kUI_MainScene);
    
    FMWorldMapNode * worldmap = (FMWorldMapNode *)pScene->getNode(kWorldMapNode);
    worldmap->initMapPosition();
    
    if (!manager->isTutorialDone(1)) {
        CCScene * scene = FMStoryScene::scene();
        CCDirector::sharedDirector()->replaceScene(scene);
        return;
    }
    
    pScene->switchScene(kWorldMapNode);
    // run
    CCDirector::sharedDirector()->replaceScene(pScene);
}
void FMLoadingScene::facebookLoginSuccess()
{
    CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
    anim->runAnimationsForSequenceNamed("InitEN1");
}

//void FMLoadingScene::clickBoss(cocos2d::CCObject *object, CCControlEvent event)
//{
//    int rand = FMDataManager::getRandom();
//    rand = rand % 5 + 1;
//    CCString* str= CCString::createWithFormat("Loading%d", rand);
//    ((CCBAnimationManager *)m_ccbNode->getUserObject())->runAnimationsForSequenceNamed(str->getCString());
//}

extern bool isLoadingDone;
void FMLoadingScene::update(float delta)
{

    if (m_time > 0.1f) {
        m_time = 0.f;
        m_count ++;
        if (m_count > 3) {
            m_count = 0;
        }
        std::stringstream ss;
//        const char * s = FMDataManager::sharedManager()->getLocalizedString("V100_LOADING");
//        ss << s;
        for (int i=0; i<m_count; i++) {
            ss << ".";
        }
        m_loadingLabel2->setString(ss.str().c_str());
    }
    m_time += delta;
    
    if (!m_texturesLoaded) {
        m_index++;
        int texCount = sizeof(preloadTextureFiles) / sizeof(const char *);
        if (m_index <texCount) {
            CCTextureCache::sharedTextureCache()->addImage(preloadTextureFiles[m_index]);
        }
        else {
            m_texturesLoaded = true;
            
            m_index = 0;
        }
        
    }
    else if (!m_uiLoaded)
    { 
//        if (m_index < kUI_Num) {
//            CCNode * uiNode = FMDataManager::sharedManager()->getUI((kGameUI)m_index);
//            GAMEUI * ui = dynamic_cast<GAMEUI *>(uiNode);
//            if (ui) {
//                CCLog("ui %s loaded", ui->classType());
//            }
//            m_index++;
//        }
//        else {
            m_uiLoaded = true;
//        }
    }
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    CCLOG("isLoadingDone=%d  m_texturesLoaded=%d", isLoadingDone ? 1 : 0, m_texturesLoaded ? 1 : 0);
    if (isLoadingDone) {
#else
    if (m_texturesLoaded && m_uiLoaded && isLoadingDone) {
#endif
        //go to main scene
#ifdef BRANCH_CN
        // create a scene. it's an autorelease object
        FMDataManager * manager = FMDataManager::sharedManager();
        FMMainScene *pScene = (FMMainScene *)manager->getUI(kUI_MainScene);
        
        FMWorldMapNode * worldmap = (FMWorldMapNode *)pScene->getNode(kWorldMapNode);
        worldmap->initMapPosition();
        
        if (!manager->isTutorialDone(1)) {
            CCScene * scene = FMStoryScene::scene();
            CCDirector::sharedDirector()->replaceScene(scene);
            return;
        }
        
        pScene->switchScene(kWorldMapNode);
        // run
        CCDirector::sharedDirector()->replaceScene(pScene);
#else
        unscheduleUpdate();
        CCDelayTime * delay = CCDelayTime::create(2.f);
        CCCallFunc * call = CCCallFunc::create(this, callfunc_selector(FMLoadingScene::showButton));
        runAction(CCSequence::create(delay,call,NULL));
#endif
    }
}

void FMLoadingScene::showButton()
{
    CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
    if (SNSFunction_isFacebookConnected()) {
        anim->runAnimationsForSequenceNamed("InitEN1");
    }else{
        anim->runAnimationsForSequenceNamed("InitEN");
    }
    
}

void FMLoadingScene::onEnter()
{
    CCScene::onEnter();
    scheduleUpdate();
    CCDirector::sharedDirector()->getKeypadDispatcher()->addDelegate(this);
}
    
void FMLoadingScene::keyBackClicked()
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
        SNSGameHelper_keyBackClickedInRootLayer();
#endif
}

void FMLoadingScene::onExit()
{
    OBJCHelper::helper()->releaseDelegate(this);
    CCScene::onExit();
    unscheduleUpdate();
    CCDirector::sharedDirector()->getKeypadDispatcher()->removeDelegate(this);
}

void FMLoadingScene::textureLoadDone(cocos2d::CCObject *texture)
{
    CCLog("texture loaded: %s", preloadTextureFiles[m_index]);
    m_index++;
    int texCount = sizeof(preloadTextureFiles) / sizeof(const char *);
    if (m_index <texCount) {
        CCTextureCache::sharedTextureCache()->addImageAsync(preloadTextureFiles[m_index], this, callfuncO_selector(FMLoadingScene::textureLoadDone));
    }
    else {
        m_texturesLoaded = true;

    }
}
