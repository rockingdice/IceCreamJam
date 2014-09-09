//
//  FMLevelConfig.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-21.
//
//

#include "FMLevelConfig.h"
#include "FMDataManager.h"
#include "FMInputNumberDialog.h"
#include "GAMEUI_Scene.h"
#include "CCJSONConverter.h"
#include "FMGameNode.h"
#include "FMMainScene.h"
#include <algorithm>


static ElementAmountPairData spData[] = {
    {kElement_1Red, 0, "FMElements.ani", "TargetIdle", "Red"},
    {kElement_2Orange, 0,"FMElements.ani", "TargetIdle", "Orange"},
    {kElement_3Yellow, 0, "FMElements.ani", "TargetIdle", "Yellow"},
    {kElement_4Green, 0, "FMElements.ani", "TargetIdle", "Green"},
    {kElement_5Blue, 0, "FMElements.ani", "TargetIdle", "Blue"},
//    {kElement_6Pink, 0, "FMElements.ani", "TargetIdle", "Purple"},
//    {kElement_1RedJello, 0, "FMElements.ani", "TargetIdle", "JelloRed"},
//    {kElement_2OrangeJello, 0, "FMElements.ani", "TargetIdle", "JelloOrange"},
//    {kElement_3YellowJello, 0, "FMElements.ani", "TargetIdle", "JelloYellow"},
//    {kElement_4GreenJello, 0, "FMElements.ani", "TargetIdle", "JelloGreen"},
//    {kElement_5BlueJello, 0, "FMElements.ani", "TargetIdle", "JelloBlue"},
//    {kElement_6PinkJello, 0, "FMElements.ani", "TargetIdle", "JelloPurple"},
//    {kElement_1RedBad, 0, "FMElements.ani", "TargetIdle", "RedBad"},
//    {kElement_2OrangeBad, 0, "FMElements.ani", "TargetIdle", "OrangeBad"},
//    {kElement_3YellowBad, 0, "FMElements.ani", "TargetIdle", "YellowBad"},
//    {kElement_4GreenBad, 0, "FMElements.ani", "TargetIdle", "GreenBad"},
//    {kElement_5BlueBad, 0, "FMElements.ani", "TargetIdle", "BlueBad"},
//    {kElement_6PinkBad, 0, "FMElements.ani", "TargetIdle", "PurpleBad"},
//    {kElement_Egg1, 0, "FMElements_Combine.ani", "Combine1Idle"},
//    {kElement_Egg2, 0, "FMElements_Combine.ani", "Combine2Idle"},
//    {kElement_Ghost1Red, 0, "FMElements_Ghost.ani", "NormalIdle", "Red"},
//    {kElement_Ghost2Orange, 0, "FMElements_Ghost.ani", "NormalIdle", "Orange"},
//    {kElement_Ghost3Yellow, 0, "FMElements_Ghost.ani", "NormalIdle", "Yellow"},
//    {kElement_Ghost4Green, 0, "FMElements_Ghost.ani", "NormalIdle", "Green"},
//    {kElement_Ghost5Blue, 0, "FMElements_Ghost.ani", "NormalIdle", "Blue"},
//    {kElement_Ghost6Pink, 0, "FMElements_Ghost.ani", "NormalIdle", "Purple"},
//    {kElement_ChangeColor, 0, "FMElements.ani", "TargetIdle", "Candy"},
//    {kElement_Drop, 0, "FMElements_Queen.ani", "Init"},
//    
//    {kElement_SwitchRed, 0, "FMElements.ani", "TargetIdle", "RedHat"},
//    {kElement_SwitchOrange, 0, "FMElements.ani", "TargetIdle", "OrangeHat"},
//    {kElement_SwitchYellow, 0, "FMElements.ani", "TargetIdle", "YellowHat"},
//    {kElement_SwitchGreen, 0, "FMElements.ani", "TargetIdle", "GreenHat"},
//    {kElement_SwitchBlue, 0, "FMElements.ani", "TargetIdle", "BlueHat"},
//    {kElement_SwitchPink, 0, "FMElements.ani", "TargetIdle", "PurpleHat"},
    
};

static ElementAmountPairData tgData[] = {
    {kElement_1Red, 0, "FMElements.ani", "TargetIdle", "Red"},
    {kElement_2Orange, 0,"FMElements.ani", "TargetIdle", "Orange"},
    {kElement_3Yellow, 0, "FMElements.ani", "TargetIdle", "Yellow"},
    {kElement_4Green, 0, "FMElements.ani", "TargetIdle", "Green"},
    {kElement_5Blue, 0, "FMElements.ani", "TargetIdle", "Blue"},
    {kElement_6Pink, 0, "FMElements.ani", "TargetIdle", "Purple"},
//    {kElement_Grow1, 0, "FMElements_Grow.ani", "Grow1Idle"},
//    {kElement_Egg3, 0, "FMElements_Combine.ani", "Combine3Idle"},
//    {kElement_Ghost1Red, 0, "FMElements_Ghost.ani", "NormalIdle", "Red"},
//    {kElement_Ghost2Orange, 0, "FMElements_Ghost.ani", "NormalIdle", "Orange"},
//    {kElement_Ghost3Yellow, 0, "FMElements_Ghost.ani", "NormalIdle", "Yellow"},
//    {kElement_Ghost4Green, 0, "FMElements_Ghost.ani", "NormalIdle", "Green"},
//    {kElement_Ghost5Blue, 0, "FMElements_Ghost.ani", "NormalIdle", "Blue"},
//    {kElement_Ghost6Pink, 0, "FMElements_Ghost.ani", "NormalIdle", "Purple"},
//    {kElement_Drop, 0, "FMElements_Queen.ani", "Init"},
//    {kElement_TargetIce, 0, "FMIceEffect.ani", "IceIdle"},
//    {kElement_TargetWall, 0, "FMElements_CandyWall.ani", "1Idle", "Vertical"},
//    {kElement_Target4Match, 0, "FMGridBonus.ani", "4"},
//    {kElement_TargetTMatch, 0, "FMGridBonus.ani", "T"},
//    {kElement_Target5Line, 0, "FMGridBonus.ani", "5"},
//    {kElement_TargetBed, 0, "Bounce.ani", "init","target"}, 
    
};

static ElementAmountPairData currentlimit[] = {
////    {kElement_1Red, 0, "FMElements.ani", "TargetIdle", "Red"},
////    {kElement_2Orange, 0,"FMElements.ani", "TargetIdle", "Orange"},
////    {kElement_3Yellow, 0, "FMElements.ani", "TargetIdle", "Yellow"},
////    {kElement_4Green, 0, "FMElements.ani", "TargetIdle", "Green"},
////    {kElement_5Blue, 0, "FMElements.ani", "TargetIdle", "Blue"},
////    {kElement_6Pink, 0, "FMElements.ani", "TargetIdle", "Purple"},
//    {kElement_Ghost1Red, 0, "FMElements_Ghost.ani", "NormalIdle", "Red"},
////    {kElement_Ghost2Orange, 0, "FMElements_Ghost.ani", "NormalIdle", "Orange"},
////    {kElement_Ghost3Yellow, 0, "FMElements_Ghost.ani", "NormalIdle", "Yellow"},
////    {kElement_Ghost4Green, 0, "FMElements_Ghost.ani", "NormalIdle", "Green"},
////    {kElement_Ghost5Blue, 0, "FMElements_Ghost.ani", "NormalIdle", "Blue"},
////    {kElement_Ghost6Pink, 0, "FMElements_Ghost.ani", "NormalIdle", "Purple"},
//    {kElement_ChangeColor, 0, "FMElements.ani", "TargetIdle", "Candy"},
//    {kElement_Drop, 0, "FMElements_Queen.ani", "Init"},
};

static ElementAmountPairData levellimit[] = {
////    {kElement_1Red, 0, "FMElements.ani", "TargetIdle", "Red"},
////    {kElement_2Orange, 0,"FMElements.ani", "TargetIdle", "Orange"},
////    {kElement_3Yellow, 0, "FMElements.ani", "TargetIdle", "Yellow"},
////    {kElement_4Green, 0, "FMElements.ani", "TargetIdle", "Green"},
////    {kElement_5Blue, 0, "FMElements.ani", "TargetIdle", "Blue"},
////    {kElement_6Pink, 0, "FMElements.ani", "TargetIdle", "Purple"},
//    {kElement_Ghost1Red, 0, "FMElements_Ghost.ani", "NormalIdle", "Red"},
////    {kElement_Ghost2Orange, 0, "FMElements_Ghost.ani", "NormalIdle", "Orange"},
////    {kElement_Ghost3Yellow, 0, "FMElements_Ghost.ani", "NormalIdle", "Yellow"},
////    {kElement_Ghost4Green, 0, "FMElements_Ghost.ani", "NormalIdle", "Green"},
////    {kElement_Ghost5Blue, 0, "FMElements_Ghost.ani", "NormalIdle", "Blue"},
////    {kElement_Ghost6Pink, 0, "FMElements_Ghost.ani", "NormalIdle", "Purple"},
//    {kElement_ChangeColor, 0, "FMElements.ani", "TargetIdle", "Candy"},
//    {kElement_Drop, 0, "FMElements_Queen.ani", "Init"},
};

struct propertyData {
    const char * name;
    int size;
};

propertyData properties[] = {
    {"percentage", 3},
    {"gameMode", 1},
    {"gameModeData", 3},
    {"moves", 1},
    {"suggestedItem", 1},
    {"sellingItems", 1},
    {"spawnables", -1},
    {"targets", -1},
    {"seeds", -1},
    {"mbox", -1},
    {"snails", 2},
    {"bgmusic", 1},
    {"controlmoves",6},
    {"controlstats",2},
    {"currentlimit",-1},
    {"levellimit",-1}
};

FMLevelConfig::FMLevelConfig() :
    m_buttonParent(NULL),
    m_mainbuttonParent(NULL),
    m_levelData(NULL),
    m_container(NULL),
    m_selectedSeed(-1),
    m_selectedBox(-1)
{
    m_ui = FMDataManager::sharedManager()->createNode("Editor/FMLevelConfig.ccbi", this);
    addChild(m_ui);
    
    CCNode * spawnablesParent = m_mainbuttonParent->getChildByTag(6);
    CCLayer * spParent = (CCLayer *)spawnablesParent->getChildByTag(1);
    CCSize sliderSize = spParent->getContentSize();
    GUIScrollSlider * spSlider = new GUIScrollSlider(sliderSize, CCRect(-sliderSize.width * 0.5f, -sliderSize.height * 0.5f, sliderSize.width, sliderSize.height), 50.f, this, false, 1);
    spSlider->setPosition(ccp(sliderSize.width * 0.5f, sliderSize.height * 0.5f));
    spSlider->autorelease();
    spSlider->setRevertDirection(true);
    spParent->addChild(spSlider, 0 , 1);
    
    CCNode * targetsParent = m_mainbuttonParent->getChildByTag(7);
    CCLayer * tgParent = (CCLayer *)targetsParent->getChildByTag(1);
    sliderSize = tgParent->getContentSize();
    GUIScrollSlider * tgSlider = new GUIScrollSlider(sliderSize, CCRect(-sliderSize.width * 0.5f, -sliderSize.height * 0.5f, sliderSize.width, sliderSize.height), 50.f, this, false, 2);
    tgSlider->autorelease();
    tgSlider->setPosition(ccp(sliderSize.width * 0.5f, sliderSize.height * 0.5f));
    tgSlider->setRevertDirection(true);
    tgParent->addChild(tgSlider, 0, 2);
    
    CCNode * seedsParent = m_buttonParent->getChildByTag(8);
    CCLayer * seedParent = (CCLayer *)seedsParent->getChildByTag(99);
    sliderSize = seedParent->getContentSize();
    GUIScrollSlider * seedSlider = new GUIScrollSlider(sliderSize, CCRect(-sliderSize.width * 0.5f, - sliderSize.height * 0.5f, sliderSize.width , sliderSize.height), 20.f, this, true, 3);
    seedSlider->autorelease();
    seedSlider->setPosition(ccp(sliderSize.width * 0.5f, sliderSize.height * 0.5f));
    seedSlider->setRevertDirection(false);
    seedParent->addChild(seedSlider, 0, 3);
    
    {
        CCNode * nodeParent = m_buttonParent->getChildByTag(14);
        CCLayer * sliderParent = (CCLayer *)nodeParent->getChildByTag(1);
        sliderSize = sliderParent->getContentSize();
        GUIScrollSlider * slider = new GUIScrollSlider(sliderSize, CCRect(-sliderSize.width * 0.5f, -sliderSize.height * 0.5f, sliderSize.width, sliderSize.height), 50.f, this, false, 2);
        slider->autorelease();
        slider->setPosition(ccp(sliderSize.width * 0.5f, sliderSize.height * 0.5f));
        slider->setRevertDirection(true);
        sliderParent->addChild(slider, 0, 4);
    }
    
    {
        CCNode * nodeParent = m_buttonParent->getChildByTag(15);
        CCLayer * sliderParent = (CCLayer *)nodeParent->getChildByTag(1);
        sliderSize = sliderParent->getContentSize();
        GUIScrollSlider * slider = new GUIScrollSlider(sliderSize, CCRect(-sliderSize.width * 0.5f, -sliderSize.height * 0.5f, sliderSize.width, sliderSize.height), 50.f, this, false, 2);
        slider->autorelease();
        slider->setPosition(ccp(sliderSize.width * 0.5f, sliderSize.height * 0.5f));
        slider->setRevertDirection(true);
        sliderParent->addChild(slider, 0, 5);
    }
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    this->scheduleOnce(schedule_selector(FMLevelConfig::clickExit), 5.0f);
#endif
}

FMLevelConfig::~FMLevelConfig()
{
    if (m_levelData) {
        m_levelData->release();
        m_levelData = NULL;
    }
}

void FMLevelConfig::loadLevelData(cocos2d::CCDictionary *data)
{
    if (m_levelData) {
        m_levelData->release();
        m_levelData = NULL;
    }
    m_levelData = data;
    m_levelData->retain();
    m_selectedSeed = 0;
    m_selectedBox = 0;
    
    updateUI();
}

std::vector<ElementAmountPairData> * FMLevelConfig::getElementDataArray(int row)
{
    std::vector<ElementAmountPairData> * data = NULL;
    switch (row) {
        case 6:
            data = &m_spData;
            break;
        case 7:
            data = &m_tgData;
            break;
        case 14:
            data = &m_cLimitData;
            break;
        case 15:
            data = &m_lLimitData;
            break;
        default:
            break;
    }
    return data;
}

ElementAmountPairData * getElementData(kElementType type, int mode)
{
    switch (mode) {
        case 0:
        {
            int count  = sizeof(spData)/sizeof(ElementAmountPairData);
            for (int i=0; i<count; i++) {
                if (spData[i].type == type) {
                    return &spData[i];
                }
            }
            return NULL;
            
        }
            break;
        case 1:
        {
            int count  = sizeof(tgData)/sizeof(ElementAmountPairData);
            for (int i=0; i<count; i++) {
                if (tgData[i].type == type) {
                    return &tgData[i];
                }
            }
            return NULL;
        }
            break;
        case 2:
        {
            int count  = sizeof(currentlimit)/sizeof(ElementAmountPairData);
            for (int i=0; i<count; i++) {
                if (currentlimit[i].type == type) {
                    return &currentlimit[i];
                }
            }
            return NULL;
            
        }
            break;
        case 3:
        {
            int count  = sizeof(levellimit)/sizeof(ElementAmountPairData);
            for (int i=0; i<count; i++) {
                if (levellimit[i].type == type) {
                    return &levellimit[i];
                }
            }
            return NULL;
            
        }
            break;
        default:
            break;
    }
    return NULL;
}

void FMLevelConfig::updateUI()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    //LEVEL
    {
        CCLabelTTF * label = (CCLabelTTF *)m_mainbuttonParent->getChildByTag(100);
        int worldIndex = manager->getWorldIndex();
        int levelIndex = manager->getLevelIndex();
        int globalIndex = manager->getGlobalIndex();
        CCString * cstr = CCString::createWithFormat("世界: %d  子关卡:%d  全局: %d", worldIndex+1, levelIndex+1, globalIndex);
        label->setString(cstr->getCString());
    }
    
    //hmac
    {
        CCLabelTTF * label = (CCLabelTTF *)m_mainbuttonParent->getChildByTag(101);
        const char * s = manager->getHMAC();
        CCString * cstr = CCString::createWithFormat("HMAC: %s", s);
        label->setString(cstr->getCString());
    }
    
    //3 star score cap
    {
        CCArray * percentage = (CCArray *)m_levelData->objectForKey("percentage");
        for (int i=0; i<3; i++) {
            CCNumber * number = (CCNumber *)percentage->objectAtIndex(i);
            int value = number->getIntValue();
            CCControlButton * button = (CCControlButton *)m_mainbuttonParent->getChildByTag(0)->getChildByTag(i+1);
            CCString * s = CCString::createWithFormat("%d", value);
            button->setTitleForState(s, CCControlStateNormal);
            button->setTitleForState(s, CCControlStateHighlighted);
        }
    }
    
    //game mode
    {
        CCNumber * mode = (CCNumber *)m_levelData->objectForKey("gameMode");
        int tag = mode->getIntValue() + 1;
        CCControlButton * b = (CCControlButton *)m_mainbuttonParent->getChildByTag(1)->getChildByTag(tag);
        CCSprite * s = (CCSprite *)m_mainbuttonParent->getChildByTag(1)->getChildByTag(-5);
        CCPoint bPos = b->getPosition();
        s->setPosition(ccp(bPos.x + 32, bPos.y));
//        CCLabelTTF * gameModeInfo = (CCLabelTTF *)m_mainbuttonParent->getChildByTag(2)->getChildByTag(0);
//        switch (tag) {
//            case 1:
//            {
//                gameModeInfo->setString("奖励绿豆：");
//            }
//                break;
//            case 2:
//            {
//                gameModeInfo->setString("动物ID：");
//            }
//                break;
//            case 3:
//            {
//                gameModeInfo->setString("消耗绿豆：");
//            }
//                break;
//            default:
//                break;
//        }
    }
    
    //game mode data
//    {
//        CCArray * a = (CCArray *)m_levelData->objectForKey("gameModeData");
//        for (int i=0; i<3; i++) {
//            CCNumber * number = (CCNumber *)a->objectAtIndex(i);
//            int value = number->getIntValue();
//            CCControlButton * button = (CCControlButton *)m_mainbuttonParent->getChildByTag(2)->getChildByTag(i+1);
//            CCString * s = CCString::createWithFormat("%d", value);
//            button->setTitleForState(s, CCControlStateNormal);
//            button->setTitleForState(s, CCControlStateHighlighted);
//        }
//    }
    
    //moves
    {
        CCNumber * number = (CCNumber *)m_levelData->objectForKey("moves");
        int value = number->getIntValue();
        CCControlButton * button = (CCControlButton *)m_mainbuttonParent->getChildByTag(3)->getChildByTag(1);
        CCString * s = CCString::createWithFormat("%d", value);
        button->setTitleForState(s, CCControlStateNormal);
        button->setTitleForState(s, CCControlStateHighlighted);
    }
    
    //suggested item
//    {
//        CCNumber * number = (CCNumber *)m_levelData->objectForKey("suggestedItem");
//        int tag = number->getIntValue() + 1;
//        CCControlButton * b = (CCControlButton *)m_mainbuttonParent->getChildByTag(4)->getChildByTag(tag);
//        CCSprite * s = (CCSprite *)m_mainbuttonParent->getChildByTag(4)->getChildByTag(-5);
//        CCPoint bPos = b->getPosition();
//        s->setPosition(ccp(bPos.x + 32, bPos.y));
//    }
    
    //selling item
//    {
//        CCNumber * number = (CCNumber *)m_levelData->objectForKey("sellingItem");
//        int tag = number->getIntValue() + 1;
//        CCControlButton * b = (CCControlButton *)m_mainbuttonParent->getChildByTag(5)->getChildByTag(tag);
//        CCSprite * s = (CCSprite *)m_mainbuttonParent->getChildByTag(5)->getChildByTag(-5);
//        CCPoint bPos = b->getPosition();
//        s->setPosition(ccp(bPos.x + 32, bPos.y));
//    }
    //selling items
    {
        CCArray * array = (CCArray *)m_levelData->objectForKey("sellingItems");
        if (!array) {
            array = CCArray::create();
            array->addObject(CCNumber::create(6));
            array->addObject(CCNumber::create(0));
            array->addObject(CCNumber::create(7));
            m_levelData->setObject(array, "sellingItems");
        }
        for (int i = 0; i < 3; i++) {
            CCLabelBMFont * s = (CCLabelBMFont *)m_mainbuttonParent->getChildByTag(5)->getChildByTag(-5-i);
            if (i < array->count()) {
                CCNumber * number = (CCNumber*)array->objectAtIndex(i);
                int tag = number->getIntValue() + 1;
                CCControlButton * b = (CCControlButton *)m_mainbuttonParent->getChildByTag(5)->getChildByTag(tag);
                CCPoint bPos = b->getPosition();
                s->setPosition(ccp(bPos.x - 20, bPos.y));
                s->setVisible(true);
            }else{
                s->setVisible(false);
            }
        }
    }
    //spawnables
    {
        m_spData.clear();
        CCArray * a = (CCArray *)m_levelData->objectForKey("spawnables");
        std::map<kElementType, ElementAmountPairData> d;
        for (int i=0; i<a->count(); i++) {
            CCArray * aa = (CCArray *)a->objectAtIndex(i);
            CCNumber * type = (CCNumber *)aa->objectAtIndex(0);
            CCNumber * weight = (CCNumber *)aa->objectAtIndex(1);
            ElementAmountPairData p;
            p.type = (kElementType)type->getIntValue();
            p.amount = weight->getIntValue();
            ElementAmountPairData * dd = getElementData(p.type, 0);
            p.file = dd->file;
            p.anim = dd->anim;
            p.skin = dd->skin;
            d[p.type] = p;
        }
        int count = sizeof(spData) / sizeof(ElementAmountPairData);
        for (int i=0; i<count; i++) {
            ElementAmountPairData & p = spData[i];
            if (d.find(p.type) != d.end()) {
                ElementAmountPairData data = d[p.type];
                m_spData.push_back(data);
            }
            else {
                m_spData.push_back(p);
            }
        }
        std::sort(m_spData.begin(), m_spData.end());
        CCLayer * parent = (CCLayer *)m_mainbuttonParent->getChildByTag(6)->getChildByTag(1);
        GUIScrollSlider * slider = (GUIScrollSlider *)parent->getChildByTag(1);
        slider->refresh();
    }
    
    //targets
    {
        m_tgData.clear();
        CCArray * a = (CCArray *)m_levelData->objectForKey("targets");
        std::map<kElementType, ElementAmountPairData> d;
        for (int i=0; i<a->count(); i++) {
            CCArray * aa = (CCArray *)a->objectAtIndex(i);
            CCNumber * type = (CCNumber *)aa->objectAtIndex(0);
            CCNumber * weight = (CCNumber *)aa->objectAtIndex(1);
            ElementAmountPairData p;
            p.type = (kElementType)type->getIntValue();
            p.amount = weight->getIntValue();
            ElementAmountPairData * dd = getElementData(p.type, 1);
            p.file = dd->file;
            p.anim = dd->anim;
            p.skin = dd->skin;
            d[p.type] = p;
        }
        int count = sizeof(tgData) / sizeof(ElementAmountPairData);
        for (int i=0; i<count; i++) {
            ElementAmountPairData & p = tgData[i];
            if (d.find(p.type) != d.end()) {
                ElementAmountPairData data = d[p.type];
                m_tgData.push_back(data);
            }
            else {
                m_tgData.push_back(p);
            }
        }
        std::sort(m_tgData.begin(), m_tgData.end());
        CCLayer * parent = (CCLayer *)m_mainbuttonParent->getChildByTag(7)->getChildByTag(1);
        GUIScrollSlider * slider = (GUIScrollSlider *)parent->getChildByTag(2);
        slider->refresh();
    }
    //current limit
    {
        m_cLimitData.clear();
        CCArray * a = (CCArray *)m_levelData->objectForKey("currentlimit");
        if (!a) {
            a = CCArray::create();
        }
        std::map<kElementType, ElementAmountPairData> d;
        for (int i=0; i<a->count(); i++) {
            CCArray * aa = (CCArray *)a->objectAtIndex(i);
            CCNumber * type = (CCNumber *)aa->objectAtIndex(0);
            CCNumber * weight = (CCNumber *)aa->objectAtIndex(1);
            ElementAmountPairData p;
            p.type = (kElementType)type->getIntValue();
            p.amount = weight->getIntValue();
            ElementAmountPairData * dd = getElementData(p.type, 2);
            p.file = dd->file;
            p.anim = dd->anim;
            p.skin = dd->skin;
            d[p.type] = p;
        }
        int count = sizeof(currentlimit) / sizeof(ElementAmountPairData);
        for (int i=0; i<count; i++) {
            ElementAmountPairData & p = currentlimit[i];
            if (d.find(p.type) != d.end()) {
                ElementAmountPairData data = d[p.type];
                m_cLimitData.push_back(data);
            }
            else {
                m_cLimitData.push_back(p);
            }
        }
        std::sort(m_cLimitData.begin(), m_cLimitData.end());
        CCLayer * parent = (CCLayer *)m_buttonParent->getChildByTag(14)->getChildByTag(1);
        GUIScrollSlider * slider = (GUIScrollSlider *)parent->getChildByTag(4);
        slider->refresh();
    }
    //level limits
    {
        m_lLimitData.clear();
        CCArray * a = (CCArray *)m_levelData->objectForKey("levellimit");
        if (!a) {
            a = CCArray::create();
        }
        std::map<kElementType, ElementAmountPairData> d;
        for (int i=0; i<a->count(); i++) {
            CCArray * aa = (CCArray *)a->objectAtIndex(i);
            CCNumber * type = (CCNumber *)aa->objectAtIndex(0);
            CCNumber * weight = (CCNumber *)aa->objectAtIndex(1);
            ElementAmountPairData p;
            p.type = (kElementType)type->getIntValue();
            p.amount = weight->getIntValue();
            ElementAmountPairData * dd = getElementData(p.type, 3);
            p.file = dd->file;
            p.anim = dd->anim;
            p.skin = dd->skin;
            d[p.type] = p;
        }
        int count = sizeof(levellimit) / sizeof(ElementAmountPairData);
        for (int i=0; i<count; i++) {
            ElementAmountPairData & p = levellimit[i];
            if (d.find(p.type) != d.end()) {
                ElementAmountPairData data = d[p.type];
                m_lLimitData.push_back(data);
            }
            else {
                m_lLimitData.push_back(p);
            }
        }
        std::sort(m_lLimitData.begin(), m_lLimitData.end());
        CCLayer * parent = (CCLayer *)m_buttonParent->getChildByTag(15)->getChildByTag(1);
        GUIScrollSlider * slider = (GUIScrollSlider *)parent->getChildByTag(5);
        slider->refresh();
    }
    
    {
        //seeds
        CCArray * seeds = (CCArray *)m_levelData->objectForKey("seeds");
        if (!seeds) {
            seeds = CCArray::create();
            m_levelData->setObject(seeds, "seeds");
        }
        m_seeds = seeds;
    }
    
    {
        //snails 
        CCArray * a = (CCArray *)m_levelData->objectForKey("snails");
        if (!a) {
            a = CCArray::create();
            m_levelData->setObject(a, "snails");
            a->addObject(CCNumber::create(0));
            a->addObject(CCNumber::create(0));
        }
        for (int i=0; i<2; i++) {
            CCNumber * number = (CCNumber *)a->objectAtIndex(i);
            int value = number->getIntValue();
            CCControlButton * button = (CCControlButton *)m_buttonParent->getChildByTag(10)->getChildByTag(i+1);
            CCString * s = CCString::createWithFormat("%d", value);
            button->setTitleForState(s, CCControlStateNormal);
            button->setTitleForState(s, CCControlStateHighlighted);
        }
    }
    
    {
        //bg music
        CCNumber * n = (CCNumber *)m_levelData->objectForKey("bgmusic");
        if (!n) {
            n = CCNumber::create(1);
            m_levelData->setObject(n, "bgmusic");
        }
        int value = n->getIntValue();
        CCControlButton * button = (CCControlButton *)m_mainbuttonParent->getChildByTag(11)->getChildByTag(1);
        CCString * s = CCString::createWithFormat("%d", value);
        button->setTitleForState(s, CCControlStateNormal);
        button->setTitleForState(s, CCControlStateHighlighted);
    }
    
    //controlmoves
    {
        CCArray * a = (CCArray *)m_levelData->objectForKey("controlmoves");
        if (a && a->count() == 3) {
            a->addObject(CCNumber::create(0));
            a->addObject(CCNumber::create(1));
        }
        if (a && a->count() == 5) {
            a->addObject(CCNumber::create(0));
        }
        if (!a) {
            a = CCArray::create();
            m_levelData->setObject(a, "controlmoves");
            a->addObject(CCNumber::create(5));
            a->addObject(CCNumber::create(48));
            a->addObject(CCNumber::create(50));
            a->addObject(CCNumber::create(0));
            a->addObject(CCNumber::create(1));
            a->addObject(CCNumber::create(0));
        }
        for (int i=0; i<6; i++) {
            CCNumber * number = (CCNumber *)a->objectAtIndex(i);
            int value = number->getIntValue();
            CCControlButton * button = (CCControlButton *)m_buttonParent->getChildByTag(12)->getChildByTag(i+1);
            CCString * s = CCString::createWithFormat("%d", value);
            button->setTitleForState(s, CCControlStateNormal);
            button->setTitleForState(s, CCControlStateHighlighted);
        }
    }
    //controlstats
    {
        CCNumber* a = (CCNumber *)m_levelData->objectForKey("controlstats");
        if (!a) {
            a = CCNumber::create(1);
        }
        int tag = a->getIntValue() + 1;
        CCControlButton * b = (CCControlButton *)m_buttonParent->getChildByTag(13)->getChildByTag(tag);
        CCSprite * s = (CCSprite *)m_buttonParent->getChildByTag(13)->getChildByTag(-5);
        CCPoint bPos = b->getPosition();
        s->setPosition(ccp(bPos.x + 32, bPos.y));
    }
}

bool FMLevelConfig::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_buttonParent", CCNode *, m_buttonParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_mainbuttonParent", CCNode *, m_mainbuttonParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_container", CCScrollView *, m_container);
    return true;
}

SEL_CCControlHandler FMLevelConfig::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickPairButton", FMLevelConfig::clickPairButton);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMLevelConfig::clickButton);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickExit", FMLevelConfig::clickExit);;
    return NULL;
}

void FMLevelConfig::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    CCControlButton * button = (CCControlButton *)object;
    int tag = button->getTag();
    int parentTag = button->getParent()->getTag();
    m_row = parentTag;
    if (m_row == 1 || m_row == 4 || (m_row == 13 && tag < 3)) {
        m_col = tag;
        int value = tag-1;
        m_levelData->setObject(CCNumber::create(value), properties[m_row].name);
        updateUI();
    }
    else if (m_row == 5){
        CCArray * array = (CCArray * )m_levelData->objectForKey(properties[m_row].name);
        int value = tag-1;
        bool alreadyHave = false;
        for (int i = 0; i < array->count(); i++) {
            CCNumber * number = (CCNumber*)array->objectAtIndex(i);
            if (number->getIntValue() == value) {
                array->removeObjectAtIndex(i);
                alreadyHave = true;
                break;
            }
        }
        if (!alreadyHave) {
            if (array->count() >= 3) {
                return;
            }
            array->addObject(CCNumber::create(value));
        }
        m_levelData->setObject(array, properties[m_row].name);
        updateUI();
    }
    else if (m_row == 13 && tag == 3){
        FMDataManager::sharedManager()->setLevelBeaten(0);
    }
    else if (m_row == 8) {
        switch (tag) {
            case 1:
            {
                //add seed
                m_seeds->addObject(CCNumber::create(0));
                m_selectedSeed = m_seeds->count()-1;
            }
                break;
            case 2:
            {
                //modify seed
                int count = m_seeds->count();
                if (m_selectedSeed < count && m_selectedSeed >= 0) {
                    int value = ((CCNumber *)m_seeds->objectAtIndex(m_selectedSeed))->getIntValue();
                    FMInputNumberDialog * dialog = new FMInputNumberDialog();
                    dialog->autorelease();
                    dialog->setNumber(value);
                    dialog->setHandleCallback(CCCallFuncN::create(this, callfuncN_selector(FMLevelConfig::handleInputNumberDialog)));
                    GAMEUI_Scene::uiSystem()->addDialog(dialog);
                }
            }
                break;
            case 3:
            {
                //remove
                if (m_seeds->count() > m_selectedSeed && m_selectedSeed >= 0) {
                    m_seeds->removeObjectAtIndex(m_selectedSeed);
                }
            }
                break;
            case 4:
            {
                //test
#ifdef DEBUG
                int count = m_seeds->count();
                if (m_selectedSeed < count && m_selectedSeed >= 0) {
                    GAMEUI_Scene::uiSystem()->prevWindow();
                    FMDataManager * manager = FMDataManager::sharedManager();
                    FMGameNode * game = (FMGameNode *)((FMMainScene *)manager->getUI(kUI_MainScene))->getNode(kGameNode);
                    int value = ((CCNumber *)m_seeds->objectAtIndex(m_selectedSeed))->getIntValue();
                    FMDataManager::setRandomSeed(value, true);
                    game->testLevel();
                }
#endif                
            }
                break;
            default:
                break;
        }
        
        CCNode * seedsParent = m_buttonParent->getChildByTag(8);
        CCLayer * seedParent = (CCLayer *)seedsParent->getChildByTag(99);
        GUIScrollSlider * slider = (GUIScrollSlider *)seedParent->getChildByTag(3);
        slider->refresh();
    }
    else if (m_row == 9) {
        //mysteric box
    }
    else {
        m_col = tag;
        int value = atoi(button->getTitleForState(CCControlStateNormal)->getCString());
        FMInputNumberDialog * dialog = new FMInputNumberDialog;
        dialog->autorelease();
        dialog->setNumber(value);
        dialog->setHandleCallback(CCCallFuncN::create(this, callfuncN_selector(FMLevelConfig::handleInputNumberDialog)));
        GAMEUI_Scene::uiSystem()->addDialog(dialog);
    }
}

void FMLevelConfig::clickExit(cocos2d::CCObject *object, CCControlEvent event)
{
    GAMEUI_Scene::uiSystem()->prevWindow();
}

#pragma mark - GUIScrollSliderDelegate
static CCSpriteFrame * getSpriteFrame(const char * file, const char * anim, const char * skin)
{
    CCSpriteFrame * frame = NULL;
    if (anim) {
        CCRenderTexture * tex = CCRenderTexture::create(50, 60);
        tex->beginWithClear(0, 0, 0, 0);
        NEAnimNode * a = NEAnimNode::createNodeFromFile(file);
        if (skin) {
            a->useSkin(skin);
        }
        tex->addChild(a);
        a->playAnimation(anim, 0, true, false);
        a->setPosition(ccp(25, 30));
        a->setScaleY(-1.f);
        a->visit();
        tex->end();
        frame = tex->getSprite()->displayFrame();
    }
    else {
        frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(file);
    }
    return frame;
}

void FMLevelConfig::sliderUpdate(GUIScrollSlider *slider, int rowIndex, cocos2d::CCNode *node)
{
    node->setTag(rowIndex);
    int sliderTag = slider->getTag();
    switch (sliderTag) {
        case 1:
        {
            CCSprite * icon = (CCSprite *)node->getChildByTag(2);
            ElementAmountPairData & d = m_spData[rowIndex];
            
            CCString * s = CCString::createWithFormat("%d", d.amount);
            CCLabelTTF * title = (CCLabelTTF *)node->getChildByTag(5);
            title->setString(s->getCString());
            
            CCSpriteFrame * frame = getSpriteFrame(d.file, d.anim, d.skin);
            icon->setDisplayFrame(frame);
        }
            break;
        case 2:
        { 
            CCSprite * icon = (CCSprite *)node->getChildByTag(2);
            ElementAmountPairData & d = m_tgData[rowIndex];
            
            CCString * s = CCString::createWithFormat("%d", d.amount);
            CCLabelTTF * title = (CCLabelTTF *)node->getChildByTag(5);
            title->setString(s->getCString());
            
            CCSpriteFrame * frame = getSpriteFrame(d.file, d.anim, d.skin);
            icon->setDisplayFrame(frame);
        }
            break;
        case 3:
        {
            node->setUserData((void*)(rowIndex+100));
            CCNumber * seed = (CCNumber *)m_seeds->objectAtIndex(rowIndex);
            int seedid = seed->getIntValue();
            CCControlButton * button = (CCControlButton *)node->getChildByTag(2);
            CCString * str = CCString::createWithFormat("%d", seedid);
            button->setTitleForState(str, CCControlStateNormal);
            button->setTitleForState(str, CCControlStateHighlighted);
            button->setTitleForState(str, CCControlStateSelected);
            
            CCLayerColor * bg = (CCLayerColor *)node->getChildByTag(1);
            if (rowIndex == m_selectedSeed) {
                bg->setColor(ccc3(255, 0, 0));
            }
            else {
                if (rowIndex % 2 == 0) {
                    bg->setColor(ccc3(192, 192, 192));
                }
                else {
                    bg->setColor(ccc3(255, 255, 255));
                }

            }
            
        }
            break;
        case 4:
        {
            CCSprite * icon = (CCSprite *)node->getChildByTag(2);
            ElementAmountPairData & d = m_cLimitData[rowIndex];
            
            CCString * s = CCString::createWithFormat("%d", d.amount);
            CCLabelTTF * title = (CCLabelTTF *)node->getChildByTag(5);
            title->setString(s->getCString());
            
            CCSpriteFrame * frame = getSpriteFrame(d.file, d.anim, d.skin);
            icon->setDisplayFrame(frame);
        }
            break;
        case 5:
        {
            CCSprite * icon = (CCSprite *)node->getChildByTag(2);
            ElementAmountPairData & d = m_lLimitData[rowIndex];
            
            CCString * s = CCString::createWithFormat("%d", d.amount);
            CCLabelTTF * title = (CCLabelTTF *)node->getChildByTag(5);
            title->setString(s->getCString());
            
            CCSpriteFrame * frame = getSpriteFrame(d.file, d.anim, d.skin);
            icon->setDisplayFrame(frame);
        }
            break;
        default:
            break;
    }

}

CCNode * FMLevelConfig::createItemForSlider(GUIScrollSlider *slider)
{
    if (slider->getTag() == 1) {
        //spawables
        CCNode * node = FMDataManager::sharedManager()->createNode("Editor/FMItemPair.ccbi", this);
        return node;
    }
    else if (slider->getTag() == 2){
        //targets
        CCNode * node = FMDataManager::sharedManager()->createNode("Editor/FMItemPair.ccbi", this);
        return node;
    }
    else if (slider->getTag() == 4){
        //targets
        CCNode * node = FMDataManager::sharedManager()->createNode("Editor/FMItemPair.ccbi", this);
        return node;
    }
    else if (slider->getTag() == 5){
        //targets
        CCNode * node = FMDataManager::sharedManager()->createNode("Editor/FMItemPair.ccbi", this);
        return node;
    }
    else if (slider->getTag() == 3){
        CCNode * node = CCNode::create();
        CCLayerColor * layer = CCLayerColor::create(ccc4(255, 255, 255, 128), 230.f, 20.f);
        layer->setAnchorPoint(ccp(0.5f, 0.5f));
        layer->ignoreAnchorPointForPosition(false);
        node->addChild(layer, 1, 1);
        CCLabelTTF * idlabel = CCLabelTTF::create("", "Courier-Bold", 12.f);
        CCControlButton * button = CCControlButton::create(idlabel, CCScale9Sprite::create("transparent.png"));
        button->setPreferredSize(CCSize(130.f, 20.f));
        button->addTargetWithActionForControlEvents(this, cccontrol_selector(FMLevelConfig::clickSeedButton), CCControlEventTouchDown | CCControlEventTouchDragInside | CCControlEventTouchUpInside | CCControlEventTouchDragEnter | CCControlEventTouchDragExit);
        button->setZoomOnTouchDown(false);
        node->addChild(button, 1, 2);
        return node;
    }
    return NULL;
}

int FMLevelConfig::itemsCountForSlider(GUIScrollSlider *slider)
{
    if (slider->getTag() == 1) {
        return m_spData.size();
    }
    else if (slider->getTag() == 2) {
        return m_tgData.size();
    }
    else if (slider->getTag() == 3) {
        return m_seeds->count();
    }
    else if (slider->getTag() == 4) {
        return m_cLimitData.size();
    }
    else if (slider->getTag() == 5) {
        return m_lLimitData.size();
    }
    return 0;
}

static bool gButtonCanClick = false;  

void FMLevelConfig::clickPairButton(cocos2d::CCObject *object, CCControlEvent event)
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
            
            int parentTag = GUIScrollSlider::getParentScrollSlider(button)->getParent()->getParent()->getTag();
            CCLabelTTF * label = (CCLabelTTF *)button->getParent()->getChildByTag(5);
            int value = atoi(label->getString());
            FMInputNumberDialog * dialog = new FMInputNumberDialog();
            dialog->autorelease();
            dialog->setNumber(value);
            dialog->setHandleCallback(CCCallFuncN::create(this, callfuncN_selector(FMLevelConfig::handleInputNumberDialog)));
            GAMEUI_Scene::uiSystem()->addDialog(dialog);
            m_row = parentTag;
            m_col = button->getParent()->getTag();
        }
    }
}

void FMLevelConfig::clickSeedButton(cocos2d::CCObject *object, CCControlEvent event)
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
            m_selectedSeed = button->getParent()->getTag();            
            CCNode * seedsParent = m_buttonParent->getChildByTag(8);
            CCLayer * seedParent = (CCLayer *)seedsParent->getChildByTag(99);
            GUIScrollSlider * slider = (GUIScrollSlider *)seedParent->getChildByTag(3);
            slider->refresh();
        }
    }
}


void FMLevelConfig::handleInputNumberDialog(cocos2d::CCNode *node)
{
    FMInputNumberDialog * dialog = (FMInputNumberDialog *)node;
    if (dialog->getHandleResult() == DIALOG_CANCELED) {
        return;
    }
    int number = dialog->getNumber();
    if (m_row == 8) {
        m_seeds->replaceObjectAtIndex(m_selectedSeed, CCNumber::create(number));
        
        CCNode * seedsParent = m_buttonParent->getChildByTag(8);
        CCLayer * seedParent = (CCLayer *)seedsParent->getChildByTag(99);
        GUIScrollSlider * slider = (GUIScrollSlider *)seedParent->getChildByTag(3);
        slider->refresh();
        return;
    }
    
    
    int size = properties[m_row].size;
    if (size == 1) {
        m_levelData->setObject(CCNumber::create(number), properties[m_row].name);
    }
    else if (size == -1) {
        CCArray * data = (CCArray *)m_levelData->objectForKey(properties[m_row].name);
        if (!data) {
            data = CCArray::create();
            m_levelData->setObject(data, properties[m_row].name);
        }
        data->removeAllObjects();
        std::vector<ElementAmountPairData> & vector = *getElementDataArray(m_row);
        ElementAmountPairData & d = vector.at(m_col);
        d.amount = number;
        for (int i=0; i<vector.size(); i++) {
            ElementAmountPairData & dd = vector[i];
            int ddamount = dd.amount;
            if (ddamount != 0) {
                CCArray * pairdata = CCArray::create();
                pairdata->addObject(CCNumber::create(dd.type));
                pairdata->addObject(CCNumber::create(dd.amount));
                data->addObject(pairdata);
            }
        }
    }
    else {
        CCArray * data = (CCArray *)m_levelData->objectForKey(properties[m_row].name);
        data->replaceObjectAtIndex(m_col-1, CCNumber::create(number));
    }
    updateUI();
}


void FMLevelConfig::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    setScale(1.f);
    CCCallFunc * actionCallFunc = CCCallFunc::create(this, callfunc_selector(GAMEUI_Window::transitionInDone));
    CCScaleTo * actionScale = CCScaleTo::create(0.25f, 1.f);
    CCEaseBackOut * actionEase = CCEaseBackOut::create(actionScale);
    CCSequence * actionSequence = CCSequence::create(actionEase, actionCallFunc, finishAction, NULL);
    
    runAction(actionSequence);
}

void FMLevelConfig::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    setScale(1.f);
    
    CCCallFunc * actionCallFunc = CCCallFunc::create(this, callfunc_selector(GAMEUI_Window::transitionOutDone));
    CCScaleTo * actionScale = CCScaleTo::create(0.25f, 1.f);
    CCEaseBackOut * actionEase = CCEaseBackOut::create(actionScale);
    CCSequence * actionSequence = CCSequence::create(actionEase, actionCallFunc, finishAction, NULL);
    
    runAction(actionSequence);
}
