//
//  FarmManiaAppDelegate.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-1.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//

#include "AppDelegate.h"

#include "cocos2d.h"
#include "SimpleAudioEngine.h"
#include "FMMainScene.h"
#include "FMDataManager.h"
#include "NEAnimNode.h"
#include "BubbleServiceFunction.h"
#include "OBJCHelper.h"
#include "ZipUtils.h"
#include "SNSFunction.h"
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include "FMLoadingScene.h"
#include "MyPurchase.h"
#include "SnsGameHelper.h"
#endif
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
#include <mach/mach.h>
#include <mach/mach_host.h>
#endif
USING_NS_CC;


using namespace CocosDenshion;
using namespace neanim;
bool gInitialized = false;

AppDelegate::AppDelegate()
{

}

AppDelegate::~AppDelegate()
{
}

typedef struct tagResource
{
    cocos2d::CCSize size;
    char directory[100];
    float resScaleFactor;
}Resource;

static Resource resources[4] = {{CCSize(200, 284), "0.5x", 0.5f}, { CCSize(400, 568), "1x", 1.f}, { CCSize(800, 1136), "2x", 2.f}, { CCSize(1600, 2272), "4x", 4.f}};
static CCSize coreSize = CCSize(320, 480); 
float deviceScaleFactor = -1.f;
kResolutionType deviceResolutionType = kResolutionType_None;


#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
const static int modelListLen = 22;
static std::string modelList[modelListLen] = {
    "GT-S5360", "GT-S5360L", "GT-S5363", "GT-S6102E", "GT-S6802B",
    "GT-S5369", "SCH-I509", "SCH-i509","GT-S6102", "GT-S6102B",
    "GT-S5570", "GT-S5570B", "GT-S5570I", "GT-S5302", "GT-S5302B"
    "GT-S5570L", "GT-S5578", "SGH-T499", "SGH-T499V", "SGH-T499Y",
    "GT-S5300", "GT-S5300B",};
static int res_available[] = {
    kResolutionType_0_5x,
    kResolutionType_1x,
    kResolutionType_2x,
    kResolutionType_4x
};
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)

//#ifndef BRANCH_TH
        static int res_available[] = {
            kResolutionType_1x,
            kResolutionType_2x,
            kResolutionType_4x
        };
//    #else
//        static int res_available[] = {
//            kResolutionType_1x,
//           kResolutionType_2x
//        };
//    #endif
#endif

bool isLoadingDone = false;

bool AppDelegate::applicationDidFinishLaunching()
{
    CCLog("application did finished");
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    if( SNSFunction_getPackageType() == PT_GOOGLE_EN_FACEBOOK ||
       SNSFunction_getPackageType() == PT_GOOGLE_TW_FACEBOOK ||
       SNSFunction_getPackageType() == PT_MM_CN_WEIXIN_MM_ALIPAY ||
       SNSFunction_getPackageType() == PT_MAXIS_EN_FACEBOOK_MAXIS ||
       SNSFunction_getPackageType() == PT_MOL_EN_FACEBOOK_MOL ||
       SNSFunction_getPackageType() == PT_CY_EN_FACEBOOK_CY ||
       SNSFunction_getPackageType() == PT_GOOGLE_TH_FACEBOOK)
    {
        CCLog("applicationDidFinishLaunching --- set 3 to 2");
        memcpy(resources[3].directory,resources[2].directory,100);
        resources[3].resScaleFactor = resources[2].resScaleFactor;
    }
    initResPath();
    initialize();
    FMDataManager::sharedManager()->initTutorial();
    MyPurchase::sharedPurchase()->loadIAPPlugin();
    OBJCHelper::helper()->livesRefillNote();
    //OBJCHelper::helper()->freeSpinNote();
#endif
    CCDirector * pDirector = CCDirector::sharedDirector();
    // turn on display FPS
#ifdef DEBUG
    pDirector->setDisplayStats(true);
#endif
    
    // set FPS. the default value is 1.0/60 if you don't call this
    pDirector->setAnimationInterval(1.0 / 60);
    
    //random seed
    FMDataManager::setRandomSeed(0);
    
    // start sync levels
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
    BubbleServiceFunction_startLoadLevels();
#endif
    
    int levelCount  =BubbleServiceFunction_getLevelCount();
    CCLog("level count: %d", levelCount);
    
    isLoadingDone = true;
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    isLoadingDone = true;
    FMLoadingScene * scene = new FMLoadingScene;
    scene->autorelease();
    CCDirector::sharedDirector()->runWithScene(scene);
    CCLOG("enter loading scene......");
    
    SNSFunction_onGameLoadCompleted();
    
#endif
    return true;

}

int get_platform_memory_limit()
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS) 
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    
    vm_statistics_data_t vm_stat;
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        return 50000000;
    }
    else {
        natural_t mem_used = (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pagesize;
        natural_t mem_free = vm_stat.free_count * pagesize;
        natural_t mem_total = mem_used + mem_free;
        
        return (int)mem_total/10;
    }
#else
    return 50000000;
#endif
}

// This function will be called when the app is inactive. When comes a phone call,it's be invoked too
void AppDelegate::applicationDidEnterBackground()
{
    CCDirector::sharedDirector()->stopAnimation();
    SimpleAudioEngine::sharedEngine()->pauseBackgroundMusic();
    SimpleAudioEngine::sharedEngine()->pauseAllEffects();
}
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
bool forground = false;
#endif
// this function will be called when the app is active again
void AppDelegate::applicationWillEnterForeground()
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    forground = true;
#endif
    CCDirector::sharedDirector()->startAnimation();
    SimpleAudioEngine::sharedEngine()->resumeBackgroundMusic();
    SimpleAudioEngine::sharedEngine()->resumeAllEffects();
}

float getMF(int index, CCSize frameSize)
{
    float mf1 = resources[index].size.height / frameSize.height;
    if (frameSize.width * mf1 <= resources[index].size.width) {
        return mf1;
    }
    
    float mf2 = resources[index].size.width / frameSize.width;
    if (frameSize.height * mf2 <= resources[index].size.height) {
        return mf2;
    }
    
    CCLog("no mf!");
    return mf2;
}

float getCF(int index, CCSize frameSize)
{
    float ch = coreSize.height * resources[index].resScaleFactor;
    float cw = coreSize.width * resources[index].resScaleFactor;
    float cf1 = ch / frameSize.height;
    if (cf1 * frameSize.width >= cw) {
        return cf1;
    }
    
    float cf2 = cw / frameSize.width;
    if (cf2 * frameSize.height >= ch) {
        return cf2;
    }
    return -1;
}

void AppDelegate::initResPath()
{
    //clean file search cache
    CCFileUtils::sharedFileUtils()->purgeCachedEntries();
    
    std::vector<std::string> searchPaths;
    
    const char * resDir = getResolutionDir();
    const char * lang = OBJCHelper::helper()->getLanguageCode();

    //add remote path before local
    searchPaths.push_back(SNSFunction_getDownloadFolderPath());
    
    searchPaths.push_back(SNSFunction_getDownloadFilePath(resDir));
    
    const char * remotePath = SNSFunction_getDownloadFilePath(RES_FOLDER);
    searchPaths.push_back(remotePath);
    
    CCString * str = CCString::createWithFormat("%s/%s", RES_FOLDER, resDir);
    remotePath = SNSFunction_getDownloadFilePath(str->getCString());
    searchPaths.push_back(remotePath);
    
    str = CCString::createWithFormat("%s/%s/%s", RES_FOLDER, resDir,lang);
    remotePath = SNSFunction_getDownloadFilePath(str->getCString());
    searchPaths.push_back(remotePath);
    
    searchPaths.push_back("ccb");
    searchPaths.push_back("ani");
    searchPaths.push_back("png");
    searchPaths.push_back("soundFX");
    searchPaths.push_back("data");
    
    {
        
        //local resource path
        std::stringstream ss;
        ss << "localized/" << resDir << "/" << lang;
        searchPaths.push_back(ss.str().c_str());
        ss.str("");
        ss << "loading/" << resDir << "/" << lang;
        searchPaths.push_back(ss.str().c_str());
        ss.str("");
        ss << "universe/" << resDir;
        searchPaths.push_back(ss.str().c_str());
        ss.str("");
        ss << "universe/" << resDir << "/png";
        searchPaths.push_back(ss.str().c_str()); 
    }
    
    CCLog("searchPaths added");
    
    CCFileUtils::sharedFileUtils()->setSearchPaths(searchPaths);
}
 
void AppDelegate::initialize()
{
    if (gInitialized) {
        return;
    }
    gInitialized = true;
    
    CCTexture2D::PVRImagesHavePremultipliedAlpha(true);
    int mem = get_platform_memory_limit();
    CCLOG("memory limit: %d", mem); 
    
    unsigned int val = 0x32fe32;
    // 设置资源解密key:227f5ae3a9224580eb7796fa43a74754
    // 227f5ae3 a9224580 eb7796fa 43a74754
    val = 0x227f5ae3;
    ZipUtils::ccSetPvrEncryptionKeyPart(0, val);
    val = 0xa9224580;
    ZipUtils::ccSetPvrEncryptionKeyPart(1, val);
    val = 0xeb7796fa;
    ZipUtils::ccSetPvrEncryptionKeyPart(2, val);
    val = 0x43a74754;
    ZipUtils::ccSetPvrEncryptionKeyPart(3, val);
     

    const std::vector<std::string> & sp = CCFileUtils::sharedFileUtils()->getSearchPaths();
    std::vector<std::string> searchPaths;
    for (std::vector<std::string>::const_iterator it = sp.begin(); it != sp.end(); it++) {
        searchPaths.push_back(*it);
    } 
    
    
    CCLog("will load localized strings");
    OBJCHelper::helper()->loadLocalizedStrings();
}

kResolutionType AppDelegate::getResolutionType()
{
    if (deviceResolutionType != kResolutionType_None) {
        return deviceResolutionType;
    }
    
    // initialize director
    CCDirector *pDirector = CCDirector::sharedDirector();
    pDirector->setProjection(kCCDirectorProjection2D);
    pDirector->setOpenGLView(CCEGLView::sharedOpenGLView());
    
    // Set the design resolution
    CCEGLView * pEGLView = CCEGLView::sharedOpenGLView();
    CCSize frameSize = pEGLView->getFrameSize();
    
    float contentScaleFactor = 1.f;
    float scaleFactor = 1.f;
    
    
    //try to get the scale factor
    float scales[4][2];
    int selectedRes = -1;
    float minScale = 10.f;
    
    int itCount = sizeof(res_available) / sizeof(int);
    for (int it=0; it<itCount; it++) {
        int i = res_available[it];
        scales[i][0] = frameSize.width / (coreSize.width * resources[i].resScaleFactor);
        scales[i][1] = frameSize.height/ (coreSize.height * resources[i].resScaleFactor);
        float s1 = fabsf(scales[i][0] - 1);
        float s2 = fabsf(scales[i][1] - 1);
        if (minScale > s1) {
            minScale = s1;
            selectedRes = i;
        }
        if (minScale > s2) {
            minScale = s2;
            selectedRes = i;
        }
    }
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    const char* deviceModel = SNSFunction_getDeviceModel();
    if(deviceModel != NULL) {
        CCLog("devicemodel=%s", deviceModel);
        for(int i = 0; i < modelListLen; i ++) {
            if(strcmp(deviceModel, modelList[i].c_str())==0
               && frameSize.width < 500
               && frameSize.height < 500)
            {
                CCLog("this model in android modelList, use 0.5x");
                selectedRes = 0;
            }
        }
    }
#endif
    
    float mf = getMF(selectedRes, frameSize);
    float cf = getCF(selectedRes, frameSize);
    float finalf = mf;
    if (cf != -1) {
        //improve the f
        float max = MAX(mf, cf);
        float min = MIN(mf, cf);
        if (min <= 1.f && max >= 1.f) {
            finalf = 1.f;
        }
        else {
            finalf = 0.5f* (min + max);
        }
    }
    deviceScaleFactor = finalf;
    deviceResolutionType = (kResolutionType)selectedRes;
     
    contentScaleFactor = resources[selectedRes].resScaleFactor;
    frameSize.width /= contentScaleFactor;
    frameSize.height /= contentScaleFactor;
    frameSize.width *= finalf;
    frameSize.height *= finalf;
    
    CCLog("use %1.0fx resources, finalf: %f", resources[selectedRes].resScaleFactor, finalf);
    scaleFactor = 1.f;
    
    pDirector->setContentScaleFactor(contentScaleFactor);
    pEGLView->setDesignResolutionSize(frameSize.width, frameSize.height, kResolutionShowAll);
    CCLog("anim scaleFactor %f, content scale factor %f, designResolutionSize %f,%f ", scaleFactor, contentScaleFactor, frameSize.width, frameSize.height);
    NEAnimManager::sharedManager()->setScaleFactor(scaleFactor);
    
    return deviceResolutionType;
}

const char * AppDelegate::getResolutionDir()
{
    kResolutionType type = getResolutionType();
    return resources[type].directory;
}
