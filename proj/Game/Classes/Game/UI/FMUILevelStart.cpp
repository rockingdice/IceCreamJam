//
//  FMUILevelStart.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-26.
//
//

#include "FMUILevelStart.h"
#include "FMDataManager.h"
#include "FMMainScene.h"
#include "FMStatusbar.h"
#include "FMUIBooster.h"
#include "FMUIBoosterInfo.h" 
#include "FMUINeedHeart.h"
#include "FMGameElement.h"
#include "GAMEUI_Scene.h"
#include "NEAnimNode.h"
#include "CCJSONConverter.h"
#include "SNSFunction.h"





using namespace neanim;
static kGameBooster boosterType[3];
FMUILevelStart::FMUILevelStart() :
    m_parentNode(NULL),
    m_instantMove(false),
    m_levelLabel(NULL),
    m_starParent(NULL),
    m_levelTargetParent(NULL),
//    m_highscoreLabel(NULL),
//    m_harvestMode(NULL),
    m_boosterParent(NULL),
    m_targetInfoLabel(NULL),
    m_isBranchLevel(false),
    m_rankList(NULL),
    m_connectTipLabel(NULL),
    m_tipPicture(NULL),
    m_loading(NULL),
    m_isLoading(false),
    m_boosterSelectParent(NULL),
    m_playClicked(false)
{
#ifdef BRANCH_CN
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUILevelStart.ccbi", this);
#else
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUILevelStartEN.ccbi", this);
#endif
    addChild(m_ccbNode);
    
    m_rankList = CCArray::create();
    m_rankList->retain();
    
    for (int i=0; i<3; i++) {
        CCString * name = CCString::createWithFormat("%d", i+1);
        m_star[i] = (NEAnimNode *)m_starParent->getNodeByName(name->getCString());
    }
    
    //boosters
    for (int i=0; i<3; i++) {
        CCAnimButton * boosterButton = (CCAnimButton *)m_boosterParent->getChildByTag(i)->getChildByTag(1);
        boosterButton->getAnimNode()->releaseControl("Booster");
        boosterButton->getAnimNode()->releaseControl("Count");
        boosterButton->getAnimNode()->releaseControl("Clock");
    }
    
#ifdef BRANCH_CN
    CCNode * targetNode = m_levelTargetParent->getChildByTag(11);
    ((CCBAnimationManager *)targetNode->getUserObject())->runAnimationsForSequenceNamed("TextWithTargets");
    
    m_targetInfoLabel = (CCLabelBMFont *)m_levelTargetParent->getChildByTag(11)->getChildByTag(10);
    m_targetInfoLabel->setString("");
    m_targetInfoLabel->setWidth(220.f);
    m_targetInfoLabel->setAlignment(kCCTextAlignmentCenter); 
    m_targetInfoLabel->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
#endif
    
    CCNode * ranknode = FMDataManager::sharedManager()->createNode("UI/FMUIRankList.ccbi", this);
    m_ccbNode->addChild(ranknode, 100, 1);
#ifdef BRANCH_CN
    ((CCBAnimationManager *)ranknode->getUserObject())->runAnimationsForSequenceNamed("Normal");
    CCLayer * frdsParent = (CCLayer *)ranknode->getChildByTag(1);
    CCSize sliderSize = frdsParent->getContentSize();
    sliderSize.width += 15.f;
    GUIScrollSlider * tgSlider = new GUIScrollSlider(sliderSize, CCRect(-sliderSize.width * 0.5f, -sliderSize.height * 0.5f, sliderSize.width, sliderSize.height), 70.f, this, false, 2);
    tgSlider->autorelease();
    tgSlider->setPosition(ccp(sliderSize.width * 0.5f - 15.f, sliderSize.height * 0.5f));
    tgSlider->setRevertDirection(true);
    frdsParent->addChild(tgSlider, 0, 2);
#else
    ((CCBAnimationManager *)ranknode->getUserObject())->runAnimationsForSequenceNamed("EN");
    CCLayer * frdsParent = (CCLayer *)ranknode->getChildByTag(2);
    CCSize sliderSize = frdsParent->getContentSize();
    sliderSize.height -= sliderSize.height * 0.2f;
    GUIScrollSlider * tgSlider = new GUIScrollSlider(sliderSize, CCRect(-sliderSize.width * 0.5f, -sliderSize.height * 0.5f, sliderSize.width, sliderSize.height), 75.f, this, false, 2);
    tgSlider->autorelease();
    tgSlider->setPosition(ccp(sliderSize.width * 0.5f, sliderSize.height * 0.5f ));
    tgSlider->setRevertDirection(true);
    frdsParent->addChild(tgSlider, 0, 2);
    
    m_connectTipLabel->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    m_connectTipLabel->setAlignment(kCCTextAlignmentCenter);
    m_connectTipLabel->setWidth(220);
#endif
}

FMUILevelStart::~FMUILevelStart()
{
    m_rankList->release();
}

#pragma mark - CCB Bindings
bool FMUILevelStart::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_starParent", NEAnimNode *, m_starParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_loading", NEAnimNode *, m_loading);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_levelLabel", CCLabelBMFont *, m_levelLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_levelTargetParent", CCNode *, m_levelTargetParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_boosterParent", CCNode *, m_boosterParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_targetInfoLabel", CCLabelBMFont *, m_targetInfoLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_connectTipLabel", CCLabelBMFont *, m_connectTipLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_tipPicture", CCSprite *, m_tipPicture);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_boosterSelectParent", CCNode *, m_boosterSelectParent);
    return true;
}

SEL_CCControlHandler FMUILevelStart::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUILevelStart::clickButton);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickBooster", FMUILevelStart::clickBooster);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickAddFrds", FMUILevelStart::clickAddFrds);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickMenuButton", FMUILevelStart::clickMenuButton);
    return NULL;
}

void FMUILevelStart::clickBooster(cocos2d::CCObject *object, CCControlEvent event)
{
    if (event == CCControlEventTouchUpInside) {
        CCControlButton * button = (CCControlButton *)object;
        int tag = button->getParent()->getTag();
        kGameBooster type = boosterType[tag];
        FMDataManager * manager = FMDataManager::sharedManager();
        bool locked = manager->isBoosterLocked(type);
        if (!locked) {
            int amount = manager->getBoosterAmount(type);
            if (amount <= 0) {
                FMSound::playEffect("click.mp3", 0.1f, 0.1f);
                FMUIBooster * window = (FMUIBooster *)manager->getUI(kUI_Booster);
                window->setClassState(kUIBooster_Buy);
                window->setBoosterType(type);
                GAMEUI_Scene::uiSystem()->nextWindow(window);
            }
            else {
                //do nothing
            }
        }
        else {
            FMSound::playEffect("error.mp3", 0.01f, 0.5f);
        }
    }
}

void FMUILevelStart::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        m_isBranchLevel = false;
        FMDataManager * manager = FMDataManager::sharedManager();
        FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
        
        m_instantMove = scene->getCurrentSceneType() == kWorldMapNode ? false : true;
        scene->switchScene(kWorldMapNode);
        GAMEUI_Scene::uiSystem()->prevWindow();
        
        if (manager->isInGame()) {
            FMStatusbar * status = (FMStatusbar*)manager->getUI(kUI_Statusbar);
            status->show(false);
        }
    }
}

void FMUILevelStart::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    switch (button->getTag()) {
        case 0:
        {
            //close
            m_isBranchLevel = false;
            FMDataManager * manager = FMDataManager::sharedManager();
            FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
            
            m_instantMove = scene->getCurrentSceneType() == kWorldMapNode ? false : true;
            scene->switchScene(kWorldMapNode);
            GAMEUI_Scene::uiSystem()->prevWindow();
            
            if (manager->isInGame()) {
                FMStatusbar * status = (FMStatusbar*)manager->getUI(kUI_Statusbar);
                status->show(false);
            }
        }
            break;
        case 1:
        {
            //play
            FMDataManager * manager = FMDataManager::sharedManager();
            
//            kGameMode gameMode = (kGameMode)manager->getGameMode();
//            if (gameMode == kGameMode_Boss || gameMode == kGameMode_Harvest) {
//                if (manager->getLifeNum() > 0) {
//                    FMUIBossModifier * window =(FMUIBossModifier *) manager->getUI(kUI_BossModifier);
//                    window->setClassState(gameMode);
//                    GAMEUI_Scene::uiSystem()->prevWindow();
//                    GAMEUI_Scene::uiSystem()->nextWindow(window);
//                }
//                else { 
//                    FMUINeedHeart * window = (FMUINeedHeart *)manager->getUI(kUI_NeedHeart);
//                    GAMEUI_Scene::uiSystem()->nextWindow(window);
//                }
//            }
//            else {
                if (manager->useLife()) {
                    if (m_playClicked) {
                        return;
                    }
                    m_playClicked = true;
                    manager->saveGame();
                    if (manager->isQuest()) {
                        manager->addWorldLifeUsed(1);
                    }
                    GAMEUI_Scene::uiSystem()->prevWindow();
                    FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
                    m_instantMove = scene->getCurrentSceneType() == kGameNode ? false : true;
                    scene->switchScene(kGameNode);
                    if (m_isBranchLevel) {
                        m_isBranchLevel = false;
                        GAMEUI_Scene::uiSystem()->prevWindow();
                    }
                     
                    if (manager->isInGame()) {
                        FMStatusbar * status = (FMStatusbar*)manager->getUI(kUI_Statusbar);
                        status->show(false);
                    }
//                }
            } 
            
        }
            break;
        case 2:
        {
            //info
            FMDataManager * manager = FMDataManager::sharedManager();
            FMUIBoosterInfo * dialog = (FMUIBoosterInfo *)manager->getUI(kUI_BoosterInfo);
            GAMEUI_Scene::uiSystem()->addDialog(dialog);
        }
            break;
        case 4:
        {
            //connectFB
            OBJCHelper::helper()->connectToFacebook(this);
        }
            break;
        default:
            break;
    }
}
void FMUILevelStart::clickAddFrds(CCObject * object)
{
//    SNSFunction_weixinAddFriend();
    SNSFunction_weixinUnlimitLife();
}

void FMUILevelStart::clickMenuButton(CCObject * object)
{
    CCControlButton * btn = (CCControlButton *)object;
    int tag = btn->getTag();
    if (tag == 1) {
        OBJCHelper::helper()->inviteFBFriends();
    }
    else if (tag == 2){
        CCNode * node = btn->getParent()->getParent();
        int index = node->getTag() - 1;
        if (index < m_rankList->count()) {
            CCDictionary * dic = (CCDictionary *)m_rankList->objectAtIndex(index);
            CCString * uid = (CCString *)dic->objectForKey("uid");
            OBJCHelper::helper()->sendLifeToFriend(uid->getCString(), this, callfuncO_selector(FMUILevelStart::onSendLifeSuccess));
        }
    }
}

void FMUILevelStart::onExit()
{
    GAMEUI_Window::onExit();
    OBJCHelper::helper()->releaseDelegate(this);
    unscheduleUpdate();
}

void FMUILevelStart::onEnter()
{
    GAMEUI_Window::onEnter();
    m_playClicked = false;
    scheduleUpdate();
    updateFb();
    m_isLoading = OBJCHelper::helper()->postRequest(this, callfuncO_selector(FMUILevelStart::onRequstFinished), kPostType_SyncLevelRank);
    FMDataManager * manager = FMDataManager::sharedManager();
    int globalIndex = manager->getGlobalIndex();
    bool isQuest = manager->isQuest();
    CCString * str;
    if (isQuest) {
        int world = manager->getWorldIndex();
        int level = manager->getLevelIndex();
        const char * key = manager->getLocalizedString("V100_QUEST_(D)_(D)");
        str = CCString::createWithFormat(key, world+1, level+1);
    }
    else {
        const char * key = manager->getLocalizedString("V100_LEVEL_(D)");
        str = CCString::createWithFormat(key, globalIndex);
    }
    m_levelLabel->setString(str->getCString());
    
    int starNum = manager->getStarNum();
    for (int i=0; i<3; i++) {
        const char * on = i < starNum ? "On" : "Off";
        CCString * animName = CCString::createWithFormat("%d_%s", i+1, on);
        m_star[i]->playAnimation(animName->getCString());
    }
    
#ifdef BRANCH_CN
    if (classState() == kGameMode_Classic) {
        //targets
        std::map<int, int> m_targets;
#ifdef DEBUG
        CCDictionary * levelData = manager->getLevelData(manager->getLocalMode());
#else
        CCDictionary * levelData = manager->getLevelData(false);
#endif
        CCArray * targets = (CCArray *)levelData->objectForKey("targets");
        int count = targets->count();
        static float unitLength = 50.f;
        float totalLength = unitLength * (count-1);
        if (count > 4) {
            count = 4;
        }
        for (int i=0; i<count; i++) {
            NEAnimNode * targetAnim = (NEAnimNode *)m_levelTargetParent->getChildByTag(11)->getChildByTag(i);
            CCPoint p = targetAnim->getPosition();
            if (count != 1) {
                targetAnim->setPosition(ccp(unitLength * i - totalLength * 0.5f, p.y));
            }
            else {
                targetAnim->setPosition(ccp(0.f, p.y));
            }
            
            targetAnim->setVisible(true);
            CCLabelBMFont * label = (CCLabelBMFont *)targetAnim->getNodeByName("Label");
            NEAnimNode * target = (NEAnimNode *)targetAnim->getNodeByName("Element");
            
            CCArray * targetData = (CCArray *)targets->objectAtIndex(i);
            int targetType = ((CCNumber *)targetData->objectAtIndex(0))->getIntValue();
            int targetAmount = ((CCNumber *)targetData->objectAtIndex(1))->getIntValue();
            
            FMGameElement::changeAnimNode(target, (kElementType)targetType);
            target->playAnimation("TargetHarvest", 0 ,true);
            CCString * s = CCString::createWithFormat("%d", targetAmount);
            label->setString(s->getCString());
        }
        
        for (int i =targets->count(); i<4; i++) {
            NEAnimNode * targetAnim = (NEAnimNode *)m_levelTargetParent->getChildByTag(11)->getChildByTag(i);
            targetAnim->setVisible(false);
        }

    }
#endif
    
    
    //discount icon
    bool enableDiscount = FMDataManager::sharedManager()->whetherUnsealLevelStartDiscount();
    CCArray* boosterChildren = m_boosterParent->getChildren();
    for (int i = 0; i < boosterChildren->count(); ++i) {
        CCNode* child = (CCNode* )boosterChildren->objectAtIndex(i);
        CCNode* discountSpt = child->getChildByTag(10);
        if (discountSpt) discountSpt->setVisible(enableDiscount);
    }
    
    //boosters
    CCArray * a = manager->getSellingBooster();
    for (int i = 0; i < 3; i++) {
        int t = kBooster_Locked;
        if (i < a->count()) {
            t = ((CCNumber*)a->objectAtIndex(i))->getIntValue();
        }
        boosterType[i] = (kGameBooster)t;
        
        CCNode* iconParent = (CCNode* )m_boosterParent->getChildren()->objectAtIndex(i);
        CCNode* icon = iconParent->getChildByTag(10);
        
        NEAnimNode* sele = (NEAnimNode*)m_boosterSelectParent->getChildByTag(i+10);
        bool locked = manager->isBoosterLocked(boosterType[i]);
        if (!locked) {
            sele->playAnimation("SelectBoost");
        }else{
            sele->stopAnimation();
        }

        if (icon) {
            icon->setVisible( (!locked) && enableDiscount );
            int boosterAmount = manager->getBoosterAmount(t);
            if (boosterAmount > 0) {//可能为-1
                //hide discount icon
                icon->setVisible(false);
            }

        }
    }
    updateBoosters();
    updateFrdList();
    
#ifdef BRANCH_CN
    CCLayer * frdsParent = (CCLayer *)m_ccbNode->getChildByTag(1)->getChildByTag(1);
#else
    CCLayer * frdsParent = (CCLayer *)m_ccbNode->getChildByTag(1)->getChildByTag(2);
#endif
    GUIScrollSlider * slider = (GUIScrollSlider *)frdsParent->getChildByTag(2);
    slider->setMainNodePosition(CCPointZero);
    slider->refresh();
}

void FMUILevelStart::updateFb()
{
#ifndef BRANCH_CN
    CCNode * rankNode = m_ccbNode->getChildByTag(1);
    CCLayer * frdsParent = (CCLayer *)rankNode->getChildByTag(2);
    
    if (SNSFunction_isFacebookConnected()) {
        ((CCBAnimationManager *)rankNode->getUserObject())->runAnimationsForSequenceNamed("EN");
        frdsParent->getChildByTag(2)->setVisible(true);
    }else{
        ((CCBAnimationManager *)rankNode->getUserObject())->runAnimationsForSequenceNamed("Unconnect");
        frdsParent->getChildByTag(2)->setVisible(false);
    }
#endif
}
void FMUILevelStart::facebookLoginSuccess()
{
    updateFb();
}

void FMUILevelStart::updateFrdList()
{
    m_rankList->removeAllObjects();
    FMDataManager * manager = FMDataManager::sharedManager();
    if (manager->getFrdLevelDic()) {
        m_rankList->addObjectsFromArray(manager->getFrdLevelDic());
    }
    sortList(m_rankList);
    
    updateScrollView();
}

void FMUILevelStart::updateScrollView()
{
#ifdef BRANCH_CN
    CCLayer * frdsParent = (CCLayer *)m_ccbNode->getChildByTag(1)->getChildByTag(1);

#else
    CCLayer * frdsParent = (CCLayer *)m_ccbNode->getChildByTag(1)->getChildByTag(2);

    m_loading->setVisible(m_isLoading && m_rankList->count() == 0 && SNSFunction_isFacebookConnected());
    m_tipPicture->setVisible(!m_isLoading && m_rankList->count() == 0 && SNSFunction_isFacebookConnected());
#endif
    
    GUIScrollSlider * slider = (GUIScrollSlider *)frdsParent->getChildByTag(2);
    slider->refresh();
}

void FMUILevelStart::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
    if (FMDataManager::sharedManager()->isInGame()) {
        //show status bar
        FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
        status->show(true);
        status->updateUI();
    }
}

void FMUILevelStart::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUILevelStart::setClassState(int state)
{
    GAMEUI::setClassState(state);
#ifdef BRANCH_CN
    CCNode * targetNode = m_levelTargetParent->getChildByTag(11);
    switch (state) {
        case kGameMode_Classic:
        {
            ((CCBAnimationManager *)targetNode->getUserObject())->runAnimationsForSequenceNamed("TextWithTargets");
            m_targetInfoLabel->setString(FMDataManager::sharedManager()->getLocalizedString("V100_LEVEL_TARGET_CLASSIC"));
        }
            break;
        case kGameMode_Harvest:
        {
            ((CCBAnimationManager *)targetNode->getUserObject())->runAnimationsForSequenceNamed("Text");
            m_targetInfoLabel->setString(FMDataManager::sharedManager()->getLocalizedString("V100_LEVEL_TARGET_HARVEST"));
        }
            break;
        case kGameMode_Boss:
        {
            ((CCBAnimationManager *)targetNode->getUserObject())->runAnimationsForSequenceNamed("Text");
            m_targetInfoLabel->setString(FMDataManager::sharedManager()->getLocalizedString("V100_LEVEL_TARGET_BOSS"));
        }
            break;
        default:
            break;
    }
#endif
}

void FMUILevelStart::update(float delta)
{
    FMDataManager * manager = FMDataManager::sharedManager();
    for (int i=0; i<3; i++) {
        kGameBooster type = boosterType[i];
        int defaultTime = manager->getBoosterDefaultTime(type);
        if (defaultTime == -1) {
            continue;
        }
        int boosterTime = manager->getBoosterTime(type);
        if (boosterTime == -1) {
            if (m_recharging[i]) {
                m_recharging[i] = false;
                updateBoosters();
            }
            continue;
        }
        int remainTime = manager->getRemainTime(boosterTime);
        if (remainTime == 0 && boosterTime != -1) {
            manager->stopBoosterTimer(type);
            int amount = manager->getBoosterAmount(type);
            amount++;
            manager->setBoosterAmount(type, amount);
            updateBoosters();
            continue;
        }
    }
}

void FMUILevelStart::updateBoosters()
{
    FMDataManager * manager = FMDataManager::sharedManager(); 
    for (int i = 0; i< 3; i++) {
        CCAnimButton * boosterButton = (CCAnimButton *)m_boosterParent->getChildByTag(i)->getChildByTag(1);
        NEAnimNode * boosterIcon = (NEAnimNode *)boosterButton->getAnimNode()->getNodeByName("Booster");
        NEAnimNode * boosterBoard = (NEAnimNode *)boosterButton->getAnimNode()->getNodeByName("Count");
        NEAnimNode * boosterClock = (NEAnimNode *)boosterButton->getAnimNode()->getNodeByName("Clock");
        CCLabelBMFont * boosterCount = (CCLabelBMFont *)boosterBoard->getNodeByName("Label");
        
        kGameBooster type = boosterType[i];
        int count = manager->getBoosterAmount(type);
        bool locked = manager->isBoosterLocked(type); 
        if (locked) {
            type = kBooster_Locked;
        }
        if (!locked) {

            const char * skinName = FMGameNode::getBoosterSkin(type);
            boosterIcon->useSkin(skinName);
            boosterBoard->setVisible(true);
            
            if (count <= 0) {
                bool showClock = manager->isBoosterTiming(type);
                boosterClock->setVisible(showClock);
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
void FMUILevelStart::setBranchLevel()
{
    m_isBranchLevel = true;
}

CCPoint FMUILevelStart::getTutorialPosition(int index)
{ 
    switch (index) {
        case 0:
        {
            CCPoint wp = m_boosterParent->convertToWorldSpace(CCPointZero);
            return wp;
        }
            break;
        default:
            break;
    }
    return CCPointZero;
}


void FMUILevelStart::transitionInDone()
{
    GAMEUI_Window::transitionInDone();
    FMDataManager::sharedManager()->checkNewTutorial("unlockbooster");
//    FMDataManager::sharedManager()->tutorialBegin();
}

#pragma mark - GUIScrollSliderDelegate

void FMUILevelStart::sliderUpdate(GUIScrollSlider *slider, int rowIndex, cocos2d::CCNode *node)
{
    node->setTag(rowIndex);
    CCBAnimationManager * cbm = (CCBAnimationManager *)node->getUserObject();
    if (rowIndex == 0) {
        cbm->runAnimationsForSequenceNamed("AddFrd");
    }else{
        cbm->runAnimationsForSequenceNamed("Default");
#ifdef BRANCH_CN
        FMDataManager * manager = FMDataManager::sharedManager();
        CCDictionary * dic = (CCDictionary *)m_rankList->objectAtIndex(rowIndex - 1);
        CCNumber * uid = (CCNumber *)dic->objectForKey("uid");
        CCString * name = (CCString *)dic->objectForKey("name");
        CCNumber * icon = (CCNumber *)dic->objectForKey("icon");
        CCNumber * highscore = (CCNumber *)dic->objectForKey("highscore");
        CCSprite * bg = (CCSprite *)node->getChildByTag(1);
        CCSprite * avatar = (CCSprite *)node->getChildByTag(2);
        CCSprite * up = (CCSprite *)node->getChildByTag(3);
        CCLabelTTF * namelabel = (CCLabelTTF *)node->getChildByTag(4);
        CCLabelTTF * scorelabel = (CCLabelTTF *)node->getChildByTag(5);
        CCSprite * crown = (CCSprite *)node->getChildByTag(10);
        crown->setVisible(true);
        CCLabelBMFont * ranklabel = (CCLabelBMFont *)crown->getChildByTag(1);
        CCSpriteFrame * bgframe;
        CCSpriteFrame * upframe;

        if (rowIndex == 1) {
            bgframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_b_1.png");
            upframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_u_1.png");
            CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_rank_1.png");
            crown->setDisplayFrame(frame);
            ranklabel->setString("1.");
        }
        else if (rowIndex < 4){
            bgframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_b_2.png");
            upframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_u_2.png");
            CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(CCString::createWithFormat("ui_icon_rank_%d.png",rowIndex)->getCString());
            crown->setDisplayFrame(frame);
            ranklabel->setString(CCString::createWithFormat("%d.",rowIndex)->getCString());
        }
        else if (uid->getIntValue() == atoi(manager->getUID())){
            bgframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_b_4.png");
            upframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_u_4.png");
            crown->setVisible(false);
        }
        else{
            bgframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_b_3.png");
            upframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_u_3.png");
            crown->setVisible(false);
        }
        if (name) {
            namelabel->setString(name->getCString());
        }else{
            namelabel->setString(CCString::createWithFormat("%d",uid->getIntValue())->getCString());
        }
        bg->setDisplayFrame(bgframe);
        up->setDisplayFrame(upframe);
        scorelabel->setString(CCString::createWithFormat("%d",highscore->getIntValue())->getCString());

        int iconint = icon->getIntValue() - 1;
        if (iconint < 0 || iconint > 5) {
            iconint = 0;
        }
        CCSpriteFrame * iconframe = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(CCString::createWithFormat("usericon%d.png",iconint)->getCString());
        avatar->setDisplayFrame(iconframe);
        
        
        if (uid->getIntValue() == atoi(manager->getUID())) {
            const char* me = manager->getLocalizedString("V110_ME_NAME");
            namelabel->setString(me);
        }
#else
        FMDataManager * manager = FMDataManager::sharedManager();
        CCDictionary * dic = (CCDictionary *)m_rankList->objectAtIndex(rowIndex - 1);
        CCString * uid = (CCString *)dic->objectForKey("uid");
        CCString * name = (CCString *)dic->objectForKey("name");
        CCNumber * highscore = (CCNumber *)dic->objectForKey("highscore");
        CCNode * parentNode = node->getChildByTag(1);
        CCSprite * avatar = (CCSprite *)parentNode->getChildByTag(1);
        CCLabelTTF * namelabel = (CCLabelTTF *)parentNode->getChildByTag(3);
        CCLabelTTF * scorelabel = (CCLabelTTF *)parentNode->getChildByTag(4);
        CCSprite * crown = (CCSprite *)parentNode->getChildByTag(10);
        crown->setVisible(true);
        CCLabelBMFont * ranklabel = (CCLabelBMFont *)crown->getChildByTag(1);
        if (rowIndex == 1) {
            CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_icon_rank_1.png");
            crown->setDisplayFrame(frame);
            ranklabel->setString("1");
        }
        else if (rowIndex < 4){
            CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(CCString::createWithFormat("ui_icon_rank_%d.png",rowIndex)->getCString());
            crown->setDisplayFrame(frame);
            ranklabel->setString(CCString::createWithFormat("%d",rowIndex)->getCString());
        }
        else if (SNSFunction_isFacebookConnected() && strcmp(uid->getCString(), SNSFunction_getFacebookUid()) == 0){
            crown->setVisible(false);
        }
        else{
            crown->setVisible(false);
        }
        if (name) {
            namelabel->setString(name->getCString());
        }else{
            namelabel->setString("");
        }
        scorelabel->setString(CCString::createWithFormat("%s",FMDataManager::sharedManager()->getDollarString(highscore->getIntValue()).c_str())->getCString());
        
        const char * icon = SNSFunction_getFacebookIcon(uid->getCString());
        avatar->removeChildByTag(10);
        if (icon && FMDataManager::sharedManager()->isFileExist(icon)){
            CCSprite * spr = CCSprite::create(icon);
            float size = 52.f;
            spr->setScale(size / MAX(spr->getContentSize().width, size));
            avatar->addChild(spr, 0, 10);
            spr->setPosition(ccp(avatar->getContentSize().width/2, avatar->getContentSize().height/2));
        }else{
            
        }
        
        
        CCNode * sendlifeBtn = parentNode->getChildByTag(2);
        if (uid != NULL && SNSFunction_getFacebookUid() != NULL && strcmp(uid->getCString(), SNSFunction_getFacebookUid()) == 0) {
            const char* me = manager->getLocalizedString("V110_ME_NAME");
            namelabel->setString(me);
            sendlifeBtn->setVisible(false);
        }else{
            sendlifeBtn->setVisible(OBJCHelper::helper()->isFrdMsgEnable(uid->getCString(), 1));
        }
#endif
    }
}

CCNode * FMUILevelStart::createItemForSlider(GUIScrollSlider *slider)
{
#ifdef BRANCH_CN
    CCNode * node = FMDataManager::sharedManager()->createNode("UI/FMUIRankAvatar.ccbi", this);
#else
    CCNode * node = FMDataManager::sharedManager()->createNode("UI/FMUIRankAvatarFB.ccbi", this);
#endif
    
    return node;
}

int FMUILevelStart::itemsCountForSlider(GUIScrollSlider *slider)
{
    return m_rankList->count()+1;
}

int FMUILevelStart::less(const CCObject* in_pCcObj0, const CCObject* in_pCcObj1) {
    return ((CCNumber *)((CCDictionary *)in_pCcObj0)->objectForKey("highscore"))->getIntValue() > ((CCNumber *)((CCDictionary *)in_pCcObj1)->objectForKey("highscore"))->getIntValue();
}

void FMUILevelStart::sortList(CCArray* list) {
    std::sort(list->data->arr, list->data->arr + list->data->num, FMUILevelStart::less);
}

void FMUILevelStart::onRequstFinished(CCDictionary * dic)
{
    m_isLoading = false;
    updateFrdList();
}
void FMUILevelStart::onSendLifeSuccess()
{
    updateScrollView();
}
