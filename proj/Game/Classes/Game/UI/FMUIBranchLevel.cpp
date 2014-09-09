//
//  FMUIBranchLevel.cpp
//  JellyMania
//
//  Created by lipeng on 14-1-2.
//
//

#include "FMUIBranchLevel.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "NEAnimNode.h"
#include "FMMainScene.h"
#include "FMUILevelStart.h"
#include "FMStatusbar.h"
#include "FMUIBranchBonus.h"
#include "FMUIWorldMap.h"

using namespace neanim;

BranchRewardData rewardData[3] = {
    {2, 3},
    {6, 5},
    {14, 10},
};

FMUIBranchLevel::FMUIBranchLevel() :
m_parentNode(NULL),
m_titleLabel(NULL),
m_ccbNode(NULL),
m_crown(NULL),
m_instantMove(false),
m_jellyrole(NULL),
m_isClicked(false),
m_currentButton(NULL),
m_giftBox(NULL),
m_giftLabel(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIBranchLevel.ccbi", this);
    addChild(m_ccbNode);
    
    setUpSubLevelBtn();
    m_titleLabel->setAlignment(kCCTextAlignmentCenter);
}

FMUIBranchLevel::~FMUIBranchLevel()
{
    
}
static float buttonXID[5] = {100, 110, 120, 130, 140};
void FMUIBranchLevel::setUpSubLevelBtn()
{
    for (int i=0; i<16; i++) {
        CCString * str = CCString::createWithFormat("%d", i+1);
        
        NEAnimNode * buttonAnim = (NEAnimNode *)m_parentNode->getChildByTag(i+1);
        
        CCLabelBMFont * label = CCLabelBMFont::create(str->getCString(), "font_9.fnt");
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
        label->setAlignment(kCCTextAlignmentCenter);
#endif
        label->setPosition(ccp(0, -20));
        buttonAnim->addChild(label, 10, 1);
        
        for (int ii=0; ii<5; ii++) {
            buttonAnim->xidChange(buttonXID[0]+ii, buttonXID[4]+ii);
        }
        
        buttonAnim->releaseControl("FLOWER", kProperty_AnimationControl);
        buttonAnim->releaseControl("Ring", kProperty_AnimationControl);
        buttonAnim->releaseControl("Ring", kProperty_Visible);
        buttonAnim->releaseControl("Reward", kProperty_Visible);
        buttonAnim->releaseControl("Reward2", kProperty_Visible);
        buttonAnim->releaseControl("Reward3", kProperty_Visible);
        
        CCScale9Sprite * buttonSprite = CCScale9Sprite::create("transparent.png");
        CCControlButton * button = CCControlButton::create(buttonSprite);
        button->setPreferredSize(CCSize(50, 50));
        buttonAnim->replaceNode("1", button);
        button->addTargetWithActionForControlEvents(this, cccontrol_selector(FMUIBranchLevel::clickSubLevel), CCControlEventTouchDown | CCControlEventTouchDragInside | CCControlEventTouchUpInside | CCControlEventTouchDragEnter | CCControlEventTouchDragExit);
    }
}

#pragma mark - CCB Bindings
bool FMUIBranchLevel::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_crown", NEAnimNode *, m_crown);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_jellyrole", NEAnimNode *, m_jellyrole);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_titleLabel", CCLabelBMFont *, m_titleLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_giftLabel", CCLabelBMFont *, m_giftLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_giftBox", CCSprite *, m_giftBox);
    return true;
}

SEL_CCControlHandler FMUIBranchLevel::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickBackButton", FMUIBranchLevel::clickBackButton);
    return NULL;
}


void FMUIBranchLevel::clickBackButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMDataManager* manager = FMDataManager::sharedManager();
    manager->setBranch(false);
//    FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
//    FMWorldMapNode* wd = (FMWorldMapNode*)scene->getNode(kWorldMapNode);
//    wd->showSublevel();

    m_instantMove = false;
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
//    scene->switchScene(kWorldMapNode);
    GAMEUI_Scene::uiSystem()->prevWindow();
}

void FMUIBranchLevel::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        this->clickBackButton(NULL,0);
    }
}

void FMUIBranchLevel::onExit()
{
    GAMEUI_Window::onExit();
    unscheduleUpdate();
}

void FMUIBranchLevel::onEnter()
{
    GAMEUI_Window::onEnter();
    scheduleUpdate();
    
    FMDataManager * manager = FMDataManager::sharedManager();
    
    FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
    FMWorldMapNode* wd = (FMWorldMapNode*)scene->getNode(kWorldMapNode);
    wd->hideSublevel();
    
    int wi = manager->getWorldIndex();
    int li = manager->getLevelIndex();
    bool quest = manager->isQuest();
    
    manager->setNewJelly(wi, false);
//    FMStatusbar* bar = (FMStatusbar *)manager->getUI(kUI_Statusbar);
    FMUIWorldMap * bar = (FMUIWorldMap *)FMDataManager::sharedManager()->getUI(kUI_WorldMap);
    bar->resetBookBtn();

    CCString* cstr = CCString::createWithFormat("Jelly_Role%d.ani", wi + 1);
    if (manager->isFileExist(cstr->getCString())) {
        m_jellyrole->changeFile(cstr->m_sString.c_str());
        cstr = CCString::createWithFormat("Idle%d",manager->getRandom()%2 + 1);
        m_jellyrole->playAnimation(cstr->getCString());        
    }


    BubbleLevelInfo * info = manager->getLevelInfo(wi);
    manager->setLevel(wi, 0, true, true);
    
    const char * s = FMDataManager::sharedManager()->getLocalizedString(info->name.c_str());
    m_titleLabel->setString(s);

    bool allDone = true;
    bool isbonus = false;
    bool lastBeaten = true;
    int bonusIndex = 0;
    for (int i=0; i<16; i++) {
        bool isInWorld = i < info->unlockLevelCount;

        NEAnimNode * buttonAnim = (NEAnimNode *)m_parentNode->getChildByTag(i+1);
        buttonAnim->setZOrder(100 - i);
        CCControlButton * button = (CCControlButton *)buttonAnim->getNodeByName("1");
        if (!button) {
            continue;
        }
//        button->setEnabled(isInWorld);
        if (isInWorld) {
            manager->setLevel(wi, i, true, true);
            
            int gameMode = manager->getGameMode();
            static const char * gameModeSkins[] = {"Classic", "Harvest", "Boss"};
            if (gameMode > 2) {
                gameMode = 0;
            }
            buttonAnim->useSkin(gameModeSkins[gameMode]);

            bool isRewardGetted = manager->isRewardGetted();
            bool isBeaten = manager->isLevelBeaten();
            bool isLevelUnlocked = manager->isLevelUnlocked();
            if (!isLevelUnlocked) {
                isLevelUnlocked = lastBeaten;
            }
            lastBeaten = isBeaten;
            
            if (i == 0 && manager->isWorldBeaten(true)) {
                isBeaten = true;
                isLevelUnlocked = true;
            }
            bool isFurthestLevel = !manager->isLevelBeaten() && isLevelUnlocked;

            if (!isBeaten) {
                allDone = false;
            }
            
            int flag = 0;
            flag |= isBeaten ? kButton_Passed : 0;
            flag |= !isLevelUnlocked ? kButton_Locked : 0;
            flag |= isFurthestLevel ? kButton_Highlighted : 0;
            
            buttonAnim->setUserData((void *)flag);
            buttonAnim->setVisible(true);
            
            updateButtonState(buttonAnim, (int)buttonAnim->getUserData());
            
            if (button->getUserObject()) {
                button->getUserObject()->release();
            }
            CCArray * levelObject = CCArray::create(CCNumber::create(wi), CCNumber::create(i), CCNumber::create(true), NULL);
            levelObject->retain();
            button->setUserObject(levelObject);
            
            
            NEAnimNode * flower = (NEAnimNode *)buttonAnim->getNodeByName("FLOWER");
            int starNum = manager->getStarNum();
            cstr = CCString::createWithFormat("%dIdle", starNum);
            flower->playAnimation(cstr->getCString());
            
            NEAnimNode * ring = (NEAnimNode *)buttonAnim->getNodeByName("Ring");
            ring->setVisible(isFurthestLevel);
            ring->playAnimation("Init");
            
            CCNode * reward = buttonAnim->getNodeByName("Reward");
            CCNode * reward2 = buttonAnim->getNodeByName("Reward2");
            CCNode * reward3 = buttonAnim->getNodeByName("Reward3");
            if (!isRewardGetted && haveBonus(i)) {
                bonusIndex++;
                if (bonusIndex == 2) {
                    reward->setVisible(false);
                    reward2->setVisible(true);
                    reward3->setVisible(false);
                }
                else if (bonusIndex == 3){
                    reward->setVisible(false);
                    reward2->setVisible(false);
                    reward3->setVisible(true);
                }
                else{
                    reward->setVisible(true);
                    reward2->setVisible(false);
                    reward3->setVisible(false);
                }
                isbonus = true;
            }else{
                reward->setVisible(false);
                reward2->setVisible(false);
                reward3->setVisible(false);
            }
        }else{
            buttonAnim->setVisible(false);
        }
    }
    
    manager->setLevel(wi, li, quest, true);
    if (allDone) {
        m_crown->playAnimation("1Idle");
    }else{
        m_crown->playAnimation("0Idle");
    }
    m_giftBox->setVisible(false);
    updatePhases();
}

bool FMUIBranchLevel::haveBonus(int lv)
{
    for (int i = 0; i < _BonusRewardCount_; i++) {
        if (rewardData[i].level == lv) {
            return true;
        }
    }
    return false;
}

void FMUIBranchLevel::clickSubLevel(CCObject * object, CCControlEvent event)
{
    CCControlButton * button = (CCControlButton *)object;
    FMDataManager * manager = FMDataManager::sharedManager();
    CCArray * levelObject = (CCArray *)button->getUserObject();
    if (!levelObject) {
        return;
    }
    
    int world = ((CCNumber *)levelObject->objectAtIndex(0))->getIntValue();
    int level = ((CCNumber *)levelObject->objectAtIndex(1))->getIntValue();
    bool isQuest = ((CCNumber *)levelObject->objectAtIndex(2))->getIntValue();

    NEAnimNode * animNode = (NEAnimNode *)m_parentNode->getChildByTag(level+1);
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
            if (haveBonus(level)) {
                m_giftBox->setPosition(button->getParent()->getPosition());
                m_giftBox->setVisible(true);
                m_giftBox->setZOrder(999);
                
                for (int i = 0; i < _BonusRewardCount_; i++) {
                    if (rewardData[i].level == level) {
                        CCString * num = CCString::createWithFormat("x%d", rewardData[i].number);
                        m_giftLabel->setString(num->getCString());
                        break;
                    }
                }
                
                stopActionByTag(10);
                CCDelayTime * delay = CCDelayTime::create(1.5);
                CCCallFunc * call = CCCallFunc::create(this, callfunc_selector(FMUIBranchLevel::hideGiftBox));
                runAction(CCSequence::create(delay,call,NULL));
            }
            return;
        }
        manager->setLevel(world, level, isQuest, true);
        
        FMSound::playEffect("click.mp3", 0.1f, 0.1f);
        
        FMUILevelStart * window = (FMUILevelStart *)manager->getUI(kUI_LevelStart);
        window->setBranchLevel();
        kGameMode mode = (kGameMode)manager->getGameMode();
        window->setClassState(mode);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
    }
}
void FMUIBranchLevel::hideGiftBox()
{
    m_giftBox->setVisible(false);
}

void FMUIBranchLevel::updateButtonState(neanim::NEAnimNode *animNode, int flag, bool refresh)
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

void FMUIBranchLevel::clearCurrentButton()
{
    if (m_currentButton) {
        int flag = (int)m_currentButton->getUserData();
        flag &= ~kButton_Highlighted;
        m_currentButton->setUserData((void *)flag);
        updateButtonState(m_currentButton, flag);
        m_currentButton = NULL;
    }
}

void FMUIBranchLevel::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
    
    FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
    status->makeReadOnly(true);
    status->show(true, true);
    status->setZOrder(2000);
}

void FMUIBranchLevel::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
    FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
    status->makeReadOnly(false);
    status->setZOrder(50);
}


void FMUIBranchLevel::transitionInDone()
{
    GAMEUI_Window::transitionInDone();
    runPhase();
}

void FMUIBranchLevel::update(float delta)
{
}

void FMUIBranchLevel::pushPhase(int num, ...)
{
    va_list arguments;
    va_start(arguments, num);
    for (int i=0; i<num; i++) {
        pushPhase(va_arg(arguments, AnimPhaseStruct));
    }
    va_end(arguments);
}

void FMUIBranchLevel::pushPhase(AnimPhaseStruct phase)
{
    m_phases.push_back(phase);
}

void FMUIBranchLevel::phaseDone()
{
    if (m_phases.size() == 0) {
        return;
    }
    FMDataManager * manager = FMDataManager::sharedManager();
    AnimPhaseStruct & phase = m_phases.front();
    if (phase.worldIndex == manager->getWorldIndex()) {
        switch (phase.type) {
            case kPhase_LevelUnlock:
            {
                NEAnimNode * button = (NEAnimNode *)m_parentNode->getChildByTag(phase.levelIndex + 1);
                if (phase.levelIndex != -1 && button) {
                    updateButtonState(button, (int)button->getUserData());
                }
            }
                break;
            default:
                break;
        }
    }
    
    m_phases.pop_front();
    if (m_phases.size() != 0) {
        runPhase();
    }
    else {
        //phase done
    }
}

void FMUIBranchLevel::runPhase()
{
    if (m_phases.size() == 0) {
        return;
    }
    FMDataManager * manager = FMDataManager::sharedManager();
    AnimPhaseStruct & phase = m_phases.front();
    if (phase.worldIndex != manager->getWorldIndex()) {
        phaseDone();
        return;
    }
    switch (phase.type) {
        case kPhase_PopStars:
        {
            NEAnimNode * animNode = (NEAnimNode *)m_parentNode->getChildByTag(phase.levelIndex+1);
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
            NEAnimNode * animNode = (NEAnimNode *)m_parentNode->getChildByTag(phase.levelIndex+1);
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
            }
        }
            break;
        case kPhase_QuestComplete:
        {
            m_crown->playAnimation("0-1");
            m_crown->setDelegate(this);
        }
            break;
        case kPhase_NextLevel:
        {
            phaseDone();
            if (phase.worldIndex == manager->getWorldIndex()) {
                manager->setLevel(phase.worldIndex, phase.levelIndex, phase.isQuest, true);
                FMUILevelStart * window = (FMUILevelStart *)manager->getUI(kUI_LevelStart);
                window->setBranchLevel();
                kGameMode mode = (kGameMode)manager->getGameMode();
                window->setClassState(mode);
                GAMEUI_Scene::uiSystem()->nextWindow(window);
            }
        }
            break;
        case kPhase_GetBonus:
        {
            FMUIBranchBonus * dialog = (FMUIBranchBonus *)manager->getUI(kUI_BranchBonus);
            dialog->setLevelIndex(phase.levelIndex);
            GAMEUI_Scene::uiSystem()->addDialog(dialog);
        }
            break;
        default:
            break;
    }
}

void FMUIBranchLevel::cleanPhase()
{
    m_phases.clear();
}

void FMUIBranchLevel::animationEnded(neanim::NEAnimNode *node, const char *animName)
{
    node->setDelegate(NULL);
    //    CCLog("animation done %s, phase done", animName);
    if (node == m_crown) {
        m_crown->playAnimation("1Idle");
    }
    phaseDone();
}

void FMUIBranchLevel::updatePhases()
{
    //update all phases that will change the map
    FMDataManager* manager = FMDataManager::sharedManager();
    if (m_phases.size() != 0) {
        for (std::list<AnimPhaseStruct>::iterator it = m_phases.begin(); it != m_phases.end(); it++) {
            AnimPhaseStruct & phase = *it;
            
            switch (phase.type) {
                case kPhase_PopStars:
                {
                    if (phase.worldIndex == manager->getWorldIndex()) {
                        NEAnimNode * button = (NEAnimNode*)m_parentNode->getChildByTag(phase.levelIndex+1);
                        int flag = (int)button->getUserData();
                        flag |= kButton_Passed;
                        button->setUserData((void *)flag);
                        updateButtonState(button, flag);
                        
                        NEAnimNode * flower = (NEAnimNode *)button->getNodeByName("FLOWER");
                        flower->playAnimation("0Idle");

                    }
                }
                    break;
                case kPhase_LevelUnlock:
                {
                    if (phase.worldIndex == manager->getWorldIndex()) {
                        NEAnimNode * button = (NEAnimNode *)m_parentNode->getChildByTag(phase.levelIndex+1);
                        int flag = (int)button->getUserData();
                        flag &= ~kButton_Highlighted;
                        flag |= kButton_Locked;
                        button->setUserData((void *)flag);
                        updateButtonState(button, flag);
                        
                        clearCurrentButton();
                        if (phase.levelIndex != -1) {
                            m_currentButton = button;
                        }
                    }
                }
                    break;
                case kPhase_QuestComplete:
                {
                    m_crown->playAnimation("0Idle");
                }
                    break;
                default:
                    break;
            }
        }
    }
}


