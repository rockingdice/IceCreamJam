//
//  FMTutorial.cpp
//  FarmMania
//
//  Created by James Lee on 13-6-9.
//
//

#include "FMTutorial.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "FMWorldMapNode.h"
#include "FMStatusbar.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMUIBooster.h" 
#include "FMUIUnlockChapter.h"
#include "FMUILevelStart.h"
#include "FMUIFamilyTree.h"
#include "FMUIWorldMap.h"
#include "FMUIRedPanel.h"
static FMTutorial * m_tutInstance = NULL;

FMTutorial::FMTutorial() :
m_inScreen(false),
m_isTapToContinue(false),
    m_tapToContinue(NULL),
    m_chick(NULL),
    m_dialog(NULL),
    m_info(NULL),
    m_arrow(NULL),
    m_arrowtop(NULL),
    m_arrowbottom(NULL),
    m_skipBtn(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("Tutorial/FMTutorial.ccbi", this);
    addChild(m_ccbNode, 5);
    
    m_guildhand = NEAnimNode::createNodeFromFile("FMUI_TutorialHand.ani");
    addChild(m_guildhand, 10);
    m_guildhand->playAnimation("Init");
    m_guildhand->useSkin("Move");
    m_guildhand->setVisible(false);
    
    setTouchEnabled(true);
    setTouchPriority(-5000);
    setTouchMode(kCCTouchesOneByOne);
    
    CCSize s = CCDirector::sharedDirector()->getWinSize();
    m_mainTexture = CCRenderTexture::create(s.width, s.height);
    m_mainTexture->retain();
    
    CCSprite * tex = CCSprite::createWithTexture(m_mainTexture->getSprite()->getTexture());
    tex->setFlipY(true);
    tex->setAnchorPoint(CCPointZero);
    m_rt = tex;
    m_rt->setOpacity(0);
    addChild(tex);
    
    for (int i=0; i<2; i++) {
        m_mask[i] = CCScale9Sprite::createWithSpriteFrameName("tut_mask.png");
        m_mask[i]->retain();
        m_mask[i]->setPosition(ccp(0, 0));
        m_mask[i]->setBlendFunc((ccBlendFunc){GL_ZERO, GL_ONE_MINUS_SRC_ALPHA});
        m_mask[i]->setPreferredSize(CCSize(55.f, 55.f));
        m_mask[i]->setVisible(false);
    }
    
    m_maskCircle = CCSprite::createWithSpriteFrameName("tut_maskcircle.png");
    m_maskCircle->retain();
    m_maskCircle->setPosition(CCPointZero);
    m_maskCircle->setBlendFunc((ccBlendFunc){GL_ZERO, GL_ONE_MINUS_SRC_ALPHA});
    m_maskCircle->setVisible(false);
    
    m_bg = CCLayerColor::create(ccc4(0, 0, 0, 192), s.width, s.height);
    m_bg->retain();
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
    m_info->setAlignment(kCCTextAlignmentCenter);
#endif
#ifdef BRANCH_CN
    m_info->setFntFile("font_7.fnt");
#endif
    m_info->setWidth(200);
    m_info->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());

#ifdef BRANCH_TH
    m_tapToContinue->setPosition(ccp(67, -43));
#endif
    render();
    
}

FMTutorial::~FMTutorial()
{
    
}

bool FMTutorial::ccTouchBegan(cocos2d::CCTouch *pTouch, cocos2d::CCEvent *pEvent)
{
    if (!isVisible()) {
        return false;
    }
    if (m_isTapToContinue) {
//        CCPoint cp = m_tapToContinue->getParent()->convertTouchToNodeSpace(pTouch);
//        CCRect rect = m_tapToContinue->boundingBox();
//        if (rect.containsPoint(cp)) {
            m_isTapToContinue = false;
            FMDataManager::sharedManager()->tutorialPhaseDone();
//        }
        return true;
    }
    return false;
}

#pragma mark - CCB Bindings
bool FMTutorial::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_chick", CCNode *, m_chick);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_dialog", CCNode *, m_dialog);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_arrow", CCNode *, m_arrow);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_arrowtop", CCNode *, m_arrowtop);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_arrowbottom", CCNode *, m_arrowbottom);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_info", CCLabelBMFont *, m_info);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_tapToContinue", CCLabelBMFont *, m_tapToContinue);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_skipBtn", CCAnimButton *, m_skipBtn);
    
    return true;
}

SEL_CCControlHandler FMTutorial::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickSkip", FMTutorial::clickSkip);
    return NULL;
}

void FMTutorial::clickSkip(CCObject * object, CCControlEvent event)
{
    if (event == CCControlEventTouchUpInside) {
        FMDataManager::sharedManager()->tutorialSkip();
    }
}

FMTutorial * FMTutorial::tut()
{
    if (!m_tutInstance) {
        m_tutInstance = new FMTutorial;
    }
    return m_tutInstance;
}

void FMTutorial::render()
{
    m_mainTexture->beginWithClear(0.f, 0.f, 0.f, 0.f);
    m_bg->visit();
    for (int i=0; i<2; i++) {
        m_mask[i]->visit();
    }
    m_maskCircle->visit();
    m_mainTexture->end();
}

void FMTutorial::updateTutorial(cocos2d::CCDictionary *tut, int idx)
{ 
    if (tut) {
        CCArray * phase = (CCArray *)tut->objectForKey("phase");
        CCDictionary * phaseData = (CCDictionary *)phase->objectAtIndex(idx);

        setVisible(true);
        m_maskCircle->setVisible(false);
        m_mask[0]->setVisible(false);
        m_mask[1]->setVisible(false);
        m_mask[0]->setAnchorPoint(ccp(0.5f, 0.5f));
        m_mask[1]->setAnchorPoint(ccp(0.5f, 0.5f));
        m_guildhand->setVisible(false);
        m_guildhand->stopAllActions();
        
        CCString * event = (CCString *)tut->objectForKey("event");
        if (event) {
            const char * eventStr = event->getCString();
            if (strcmp(eventStr, "failed") == 0) {
                //fade out the status bar
                FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
                status->show(true, true);
            }
        }

        CCNumber* r = (CCNumber*)tut->objectForKey("repeat");
        bool repeat = r!=NULL && r->getIntValue() == 1;
        CCNumber * tutTap = (CCNumber *)phaseData->objectForKey("tap");
        bool skip = tutTap!=NULL && tutTap->getIntValue() == 1;

        CCDictionary * mask1 = (CCDictionary *)phaseData->objectForKey("mask1");
        if (mask1) {
            showMask(0, mask1);
        }
        
        CCDictionary * mask2 = (CCDictionary *)phaseData->objectForKey("mask2");
        if (mask2) {
            showMask(1, mask2);
        }
        
        CCString * tutAnim = (CCString *)phaseData->objectForKey("tut");
        if (tutAnim) {
            CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
            anim->runAnimationsForSequenceNamed(tutAnim->getCString());
            setVisible(true);
            m_skipBtn->setVisible(!skip);
            m_skipBtn->setEnabled(!skip);
//            FMSound::playEffect("Tcow.mp3");
        }
        else { 
            setVisible(false);
        }
        
        CCString * tutInfo = (CCString *)phaseData->objectForKey("tutinfo");
        if (tutInfo) {
            const char * s = FMDataManager::sharedManager()->getLocalizedString(tutInfo->getCString());
            m_info->setString(s);
            if (m_info->boundingBox().intersectsRect(m_tapToContinue->boundingBox())) {
                m_info->setFntFile("font_7.fnt");
            }
        }
        
        CCString * showui = (CCString *)phaseData->objectForKey("showui");
        if (showui) {
            const char * showuistr= showui->getCString();
            if (strcmp(showuistr, "unlockbooster") == 0) {
                FMDataManager * manager = FMDataManager::sharedManager();
                FMUIBooster * window = (FMUIBooster *)manager->getUI(kUI_Booster);
                window->setClassState(kUIBooster_Unlock);
                CCNumber * boosterType = (CCNumber *)phaseData->objectForKey("boosterid");
                window->setBoosterType(boosterType->getIntValue());
                int number = manager->getBoosterAmount(boosterType->getIntValue());
                manager->setBoosterAmount(boosterType->getIntValue(), MAX(0, number)+3);
                GAMEUI_Scene::uiSystem()->nextWindow(window);
                FMDataManager::sharedManager()->tutorialPhaseDone();
                FMDataManager::sharedManager()->saveGame();
                return;
            }
        }
        
        if (tutTap && tutTap->getIntValue()==1) {
            m_isTapToContinue = true;
            m_tapToContinue->setVisible(true);
        }
        else {
            m_isTapToContinue = false;
            m_tapToContinue->setVisible(false);
        }
        
        CCString * anifile = (CCString *)phaseData->objectForKey("anifile");
        NEAnimNode* anim = (NEAnimNode*)m_chick->getChildByTag(0);
        if (anifile) {
            CCString * aniname = (CCString *)phaseData->objectForKey("aniname");
            anim->changeFile(anifile->m_sString.c_str());
            anim->playAnimation(aniname->m_sString.c_str());
        }else{
            FMDataManager* manager = FMDataManager::sharedManager();
            if (manager->getWorldIndex() == 0) {
                
            }else{
                CCString* aniname = CCString::createWithFormat("Jelly_Role%d.ani",FMDataManager::sharedManager()->getWorldIndex());
                if (manager->isFileExist(aniname->getCString())) {
                    anim->changeFile(aniname->getCString());
                    aniname = CCString::createWithFormat("Idle%d",FMDataManager::sharedManager()->getRandom()%2+1);
                    anim->playAnimation(aniname->getCString());
                }
            }
        }
        
        CCString * ui = (CCString *)tut->objectForKey("ui");
        const char * uiStr = ui->getCString();
        if (strcmp(uiStr, "game") == 0) {
            FMGameNode * game = (FMGameNode *)((FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene))->getNode(kGameNode);
            
            CCDictionary * indicators = (CCDictionary *)phaseData->objectForKey("indicator");
            if (indicators) {
                CCPoint from = getPointFromString((CCString *)indicators->objectForKey("from"));
                CCPoint to = getPointFromString((CCString *)indicators->objectForKey("to"));
                game->showIndicator(true, from.x, from.y, to.x, to.y);
            }
            else {
                game->showIndicator(false);
            }
            
            CCDictionary * guidehand = (CCDictionary *)
            phaseData->objectForKey("hand");
            if (guidehand) {
                CCPoint from = getPointFromString((CCString *)guidehand->objectForKey("from"));
                CCPoint to = getPointFromString((CCString *)guidehand->objectForKey("to"));
                from = game->getWorldPositionForCoord(from.x, from.y);
                to = game->getWorldPositionForCoord(to.x, to.y);
                m_guildhand->setVisible(true);
                NEFrame * f1 = m_guildhand->getVariableKeyframe("Move", "SourcePos");
                NEFrame * f2 = m_guildhand->getVariableKeyframe("Move", "TargetPos");
                f1->setDataPosition(from);
                f2->setDataPosition(to);
                m_guildhand->playAnimation("Init");
            }
            
            
            CCArray * maplimit = (CCArray *)phaseData->objectForKey("maplimit");
            if (maplimit) {
                std::set<int> limits;
                for (int i=0; i<maplimit->count(); i++) {
                    CCPoint p = getPointFromString((CCString *)maplimit->objectAtIndex(i));
                    int index = p.x * 8 + p.y;
                    limits.insert(index);
                }
                game->setMapLimit(limits);
            }
            else {
                game->resetMapLimit();
            }
            
            CCArray * buttonlimit = (CCArray *)phaseData->objectForKey("buttonlimit");
            if (buttonlimit) {
                std::set<int> limits;
                for (int i=0; i<buttonlimit->count(); i++) {
                    int index = ((CCNumber *)buttonlimit->objectAtIndex(i))->getIntValue();
                    limits.insert(index);
                }
                game->setButtonLimit(limits);
            }
            else {
                game->resetButtonLimit();
            }
        }
        else if (strcmp(uiStr, "FMUIBossModifier") == 0) {
            //move status bar to front
            FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
            status->show(true, true);
            status->setZOrder(2000);
        }
        fade(true);
    }
    render();
}

void FMTutorial::tutorialEnd(cocos2d::CCDictionary *tut)
{
    if (tut) {
        fade(false);
        CCString * ui = (CCString *)tut->objectForKey("ui");
        if (ui) {
            const char * uiStr = ui->getCString();
            if (strcmp(uiStr, "game") == 0) {
                FMGameNode * game = (FMGameNode *)((FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene))->getNode(kGameNode);
                game->showIndicator(false);
                game->resetMapLimit();
                game->resetButtonLimit();
            }
            else if (strcmp(uiStr, "FMUIBossModifier") == 0) {
                FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
                status->setZOrder(50);
            }
        }
        
        CCString * event = (CCString *)tut->objectForKey("event");
        if (event) {
            const char * eventStr = event->getCString();
            if (strcmp(eventStr, "failed") == 0) {
                //fade out the status bar
                FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
                status->show(false, true);
            }
        }
    }
}

void FMTutorial::showMask(int tag, cocos2d::CCDictionary *maskData)
{
    CCString * type = (CCString *)maskData->objectForKey("type");
    const char * typeStr = type->getCString();
    if (strcmp(typeStr, "grid") == 0) {
        CCScale9Sprite * mask = m_mask[tag];
        mask->setVisible(true);
        
        FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);

        CCPoint from = getPointFromString((CCString *)maskData->objectForKey("from"));
        CCPoint to = getPointFromString((CCString *)maskData->objectForKey("to"));;
        
        CCPoint wpfrom = game->getWorldPositionForCoord(to.x + 0.5f, from.y - 0.5f);
        static float offset = 5.f;
        wpfrom = ccpAdd(wpfrom, ccp(-offset, -offset));
        CCPoint wpto = game->getWorldPositionForCoord(from.x - 0.5f, to.y + 0.5f);
        wpto = ccpAdd(wpto, ccp(offset, offset));
        CCSize size = CCSize(fabsf(wpfrom.x - wpto.x), fabsf(wpfrom.y - wpto.y));
        mask->setPosition(wpfrom);
        mask->setAnchorPoint(CCPointZero);
        mask->setPreferredSize(size);
    }
    else if (strcmp(typeStr, "booster") == 0) {
        FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);
        CCNumber * boostertype = (CCNumber *)maskData->objectForKey("boosterid");
        CCPoint p = game->getTutorialPosition(boostertype->getIntValue() + 1);
        m_maskCircle->setVisible(true);
        m_maskCircle->setPosition(p);
        CCPoint size = getPointFromString((CCString *)maskData->objectForKey("size"));
        float scalex = size.x / 50.f;
        float scaley = size.y / 50.f;
        
        m_maskCircle->setScaleX(scalex);
        m_maskCircle->setScaleY(scaley);
        
        //check amount for this booster
        FMDataManager * manager = FMDataManager::sharedManager();
        manager->settutorialBooster(boostertype->getIntValue());
//        int bType = boostertype->getIntValue();
//        int amount = manager->getBoosterAmount(bType);
//        if (amount <= 0) {
//            amount = 1;
//            manager->setBoosterAmount(bType, amount);
//            manager->stopBoosterTimer(bType);
//            game->updateBoosters();
//        } 
    }
    else if (strcmp(typeStr, "allboost") == 0) {
        FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);
        CCPoint p = game->getTutorialPosition(9);
        m_mask[tag]->setPreferredSize(CCSize(306, 60));
        m_mask[tag]->setPosition(p);
        m_mask[tag]->setVisible(true);
    }
    else if (strcmp(typeStr, "boss") == 0) {
        FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMWorldMapNode * world = (FMWorldMapNode *)scene->getNode(kWorldMapNode);
        
        CCPoint wp = world->getTutorialPosition(0);
        wp.y += 30.f;
        m_maskCircle->setVisible(true);
        m_maskCircle->setPosition(wp);
        
        CCPoint size = getPointFromString((CCString *)maskData->objectForKey("size"));
        float scalex = size.x / 50.f;
        float scaley = size.y / 50.f;
        
        m_maskCircle->setScaleX(scalex);
        m_maskCircle->setScaleY(scaley);
    }
    else if (strcmp(typeStr, "quest") == 0) {
        FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMWorldMapNode * world = (FMWorldMapNode *)scene->getNode(kWorldMapNode);
        
        CCPoint wp = world->getTutorialPosition(2);
        m_maskCircle->setVisible(true);
        m_maskCircle->setPosition(wp);
        
        CCPoint size = getPointFromString((CCString *)maskData->objectForKey("size"));
        float scalex = size.x / 50.f;
        float scaley = size.y / 50.f;
        
        m_maskCircle->setScaleX(scalex);
        m_maskCircle->setScaleY(scaley);
    }
    else if (strcmp(typeStr, "levelbutton") == 0) {
        FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMWorldMapNode * world = (FMWorldMapNode *)scene->getNode(kWorldMapNode);
        
        CCPoint wp = world->getTutorialPosition(1);
        m_maskCircle->setVisible(true);
        m_maskCircle->setPosition(wp);
        
        CCPoint size = getPointFromString((CCString *)maskData->objectForKey("size"));
        float scalex = size.x / 50.f;
        float scaley = size.y / 50.f;
        
        m_maskCircle->setScaleX(scalex);
        m_maskCircle->setScaleY(scaley);
    }
    else if (strcmp(typeStr, "move") == 0) {
        FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);
        CCPoint wp = game->getTutorialPosition(0);
        m_maskCircle->setVisible(true);
        m_maskCircle->setPosition(wp);
        
        CCPoint size = getPointFromString((CCString *)maskData->objectForKey("size"));
        float scalex = size.x / 50.f;
        float scaley = size.y / 50.f;
        
        m_maskCircle->setScaleX(scalex);
        m_maskCircle->setScaleY(scaley);
    }
    else if (strcmp(typeStr, "statuslife") == 0) {
        FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
        CCPoint p = status->getTutorialPosition(0);
        CCPoint size = getPointFromString((CCString *)maskData->objectForKey("size"));
        m_mask[tag]->setPreferredSize(CCSize(size.x, size.y));
        m_mask[tag]->setPosition(p);
        m_mask[tag]->setVisible(true);
    }
    else if (strcmp(typeStr, "statusgold") == 0) {
        FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
        CCPoint p = status->getTutorialPosition(1);
        CCPoint size = getPointFromString((CCString *)maskData->objectForKey("size"));
        m_mask[tag]->setPreferredSize(CCSize(size.x, size.y));
        m_mask[tag]->setPosition(p);
        m_mask[tag]->setVisible(true);
    }
    else if (strcmp(typeStr, "statusbook") == 0) {
//        FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
        FMUIWorldMap * status = (FMUIWorldMap *)FMDataManager::sharedManager()->getUI(kUI_WorldMap);
        CCPoint p = status->getTutorialPosition(2);
        CCPoint size = getPointFromString((CCString *)maskData->objectForKey("size"));
        m_mask[tag]->setPreferredSize(CCSize(size.x, size.y));
        m_mask[tag]->setPosition(p);
        m_mask[tag]->setVisible(true);
    }
//    else if (strcmp(typeStr, "bossmodifier") == 0) {
//        FMUIBossModifier * window = (FMUIBossModifier *)FMDataManager::sharedManager()->getUI(kUI_BossModifier);
//        CCPoint wp = window->getTutorialPosition(0);
//        m_mask[tag]->setPreferredSize(CCSize(290, 110));
//        m_mask[tag]->setPosition(wp);
//        m_mask[tag]->setVisible(true);
//    }
    else if (strcmp(typeStr, "failed") == 0) {
        CCSize s = CCDirector::sharedDirector()->getWinSize();
        CCPoint p = ccp(s.width * 0.5f, s.height * 0.5f);
        p.y -= 15.f;
        m_mask[tag]->setPosition(p);
        CCPoint size = getPointFromString((CCString *)maskData->objectForKey("size"));
        m_mask[tag]->setPreferredSize(CCSize(size.x, size.y));
        m_mask[tag]->setVisible(true);
    }
    else if (strcmp(typeStr, "hpbar") == 0) {
        FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);
        CCPoint wp = game->getTutorialPosition(6);
        wp.x += 25.f;
        m_mask[tag]->setPreferredSize(CCSize(245, 25));
        m_mask[tag]->setPosition(wp);
        m_mask[tag]->setVisible(true);
    }
    else if (strcmp(typeStr, "bosstarget") == 0) {
        FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);
        CCPoint wp = game->getTutorialPosition(7);
        m_mask[tag]->setPreferredSize(CCSize(45, 45));
        m_mask[tag]->setPosition(wp);
        m_mask[tag]->setVisible(true);
    }
    else if (strcmp(typeStr, "harvesttarget") == 0) {
        FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);
        CCPoint wp = game->getTutorialPosition(8);
        m_mask[tag]->setPreferredSize(CCSize(237, 43));
        m_mask[tag]->setPosition(wp);
        m_mask[tag]->setVisible(true);
    }
    else if (strcmp(typeStr, "target") == 0)
    {
        FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMGameNode * game = (FMGameNode *)scene->getNode(kGameNode);
        CCNumber * targettype = (CCNumber *)maskData->objectForKey("targetid");
        CCPoint wp = game->getTutorialPosition(targettype->getIntValue() + 1000);
        CCPoint size = getPointFromString((CCString *)maskData->objectForKey("size"));
        m_mask[tag]->setPreferredSize(CCSize(size.x, size.y));
        m_mask[tag]->setPosition(wp);
        m_mask[tag]->setVisible(true);
    }
    else if (strcmp(typeStr, "unlockworld") == 0) {
        FMUIUnlockChapter * window = (FMUIUnlockChapter *)FMDataManager::sharedManager()->getUI(kUI_UnlockChapter);
        CCPoint wp = window->getTutorialPosition(0);
        m_mask[0]->setPreferredSize(CCSize(210, 120));
        m_mask[0]->setPosition(wp);
        m_mask[0]->setVisible(true);
        wp = window->getTutorialPosition(1);
        m_mask[1]->setPreferredSize(CCSize(210, 70));
        m_mask[1]->setPosition(wp);
        m_mask[1]->setVisible(true);
    }
    else if (strcmp(typeStr, "boosterbuy") == 0) {
        FMUILevelStart * window = (FMUILevelStart *)FMDataManager::sharedManager()->getUI(kUI_LevelStart);
        CCPoint wp = window->getTutorialPosition(0); 
        m_mask[0]->setPreferredSize(CCSize(260, 120));
        m_mask[0]->setPosition(wp);
        m_mask[0]->setVisible(true);
    }
    else if (strcmp(typeStr, "story") == 0) {
        m_mask[0]->setPreferredSize(CCSizeZero);
        m_mask[0]->setPosition(ccp(-100, -100));
        m_mask[0]->setVisible(true);
    }
    else if (strcmp(typeStr, "playbranch") == 0) {
        FMUIFamilyTree * window = (FMUIFamilyTree *)FMDataManager::sharedManager()->getUI(kUI_FamilyTree);
        CCPoint wp = window->getTutorialPosition(10);
        CCPoint size = getPointFromString((CCString *)maskData->objectForKey("size"));
        m_mask[tag]->setPreferredSize(CCSize(size.x, size.y));
        m_mask[0]->setPosition(wp);
        m_mask[0]->setVisible(true);
    }
    else if (strcmp(typeStr, "playon") == 0){
        FMUIRedPanel * window = (FMUIRedPanel *)FMDataManager::sharedManager()->getUI(kUI_RedPanel);
        CCPoint wp = window->getTutorialPosition();
        CCSize ws = window->getTutorialSize();
        m_mask[tag]->setPosition(wp);
        m_mask[tag]->setPreferredSize(ws);
        m_mask[tag]->setVisible(true);
    }
}

CCPoint FMTutorial::getPointFromString(cocos2d::CCString *str)
{
    CCString * sFrom = CCString::createWithFormat("{%s}", str->getCString());
    CCPoint p = CCPointFromString(sFrom->getCString());
    p = ccpSub(p, ccp(1,1));
    return p;
}

void FMTutorial::fade(bool fadein)
{
    if (fadein == !m_inScreen) {
        if (fadein) {
            CCFadeIn * f = CCFadeIn::create(0.5f);
            m_rt->runAction(f);
            
            ((CCBAnimationManager*)m_arrow->getUserObject())->runAnimationsForSequenceNamed("Init");
            ((CCBAnimationManager*)m_arrowtop->getUserObject())->runAnimationsForSequenceNamed("Init");
            ((CCBAnimationManager*)m_arrowbottom->getUserObject())->runAnimationsForSequenceNamed("Init");
            ((CCBAnimationManager*)m_chick->getUserObject())->runAnimationsForSequenceNamed("MoveIn");
            
            m_dialog->setScale(0.f);
            CCDelayTime * act1 = CCDelayTime::create(0.f);
            CCScaleTo * act2 = CCScaleTo::create(0.1f, 0.123f, 0.645f);
            CCScaleTo * act3 = CCScaleTo::create(0.1f, 0.785f, 1.416f);
            CCScaleTo * act4 = CCScaleTo::create(0.1f, 1.f, 1.f);
            CCSequence * seq = CCSequence::create(act1, act2, act3, act4, NULL);
            m_dialog->runAction(seq);
        }
        else {
            CCFadeOut * f = CCFadeOut::create(0.5f);
            m_rt->runAction(f);
            
            ((CCBAnimationManager*)m_arrow->getUserObject())->runAnimationsForSequenceNamed("Hide");
            ((CCBAnimationManager*)m_arrowtop->getUserObject())->runAnimationsForSequenceNamed("Hide");
            ((CCBAnimationManager*)m_arrowbottom->getUserObject())->runAnimationsForSequenceNamed("Hide");
            ((CCBAnimationManager*)m_chick->getUserObject())->runAnimationsForSequenceNamed("MoveOut");
            m_guildhand->setVisible(false);
            m_guildhand->pauseAnimation();
            m_dialog->setScale(1.f);
            CCScaleTo * act1 = CCScaleTo::create(0.1f, 0.785f, 1.416f);
            CCScaleTo * act2 = CCScaleTo::create(0.1f, 0.123f, 0.645f);
            CCScaleTo * act3 = CCScaleTo::create(0.1f, 0.f, 0.f);
            CCSequence * seq = CCSequence::create(act1, act2, act3, NULL);
            m_dialog->runAction(seq);
        }
    }
    else {
        setVisible(fadein);
    }
    m_inScreen = fadein;
}