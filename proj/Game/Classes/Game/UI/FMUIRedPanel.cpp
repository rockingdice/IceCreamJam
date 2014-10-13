//
//  FMUIRedPanel.cpp
//  FarmMania
//
//  Created by James Lee on 13-5-29.
//
//

#include "FMUIRedPanel.h"

#include "FMDataManager.h"
#include "FMMainScene.h"
#include "FMStatusbar.h"
#include "GAMEUI_Scene.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "FMGameElement.h"
#include "FMUIInAppStore.h"
#include "SNSFunction.h"
#include "FMUIFreeGolds.h"

int gPlayOnTimes = 0;

#ifdef BRANCH_CN
static kPlayOnData gPlayOnItems[] = {
    {19,  kPlayOnItem_5Moves, kPlayOnItem_None, kPlayOnItem_None},
    {55,  kPlayOnItem_5Moves, kPlayOnItem_Booster2, kPlayOnItem_None},
    {75,  kPlayOnItem_5Moves, kPlayOnItem_Booster3, kPlayOnItem_Booster4}
};
#else
static kPlayOnData gPlayOnItems[] = {
    {10,  kPlayOnItem_5Moves, kPlayOnItem_None, kPlayOnItem_None},
    {28,  kPlayOnItem_5Moves, kPlayOnItem_Booster2, kPlayOnItem_None},
    {38,  kPlayOnItem_5Moves, kPlayOnItem_Booster3, kPlayOnItem_Booster4}
};
#endif

FMUIRedPanel::FMUIRedPanel() :
    m_panel(NULL),
    m_levelTargetParent(NULL),
    m_priceLabel(NULL),
    m_targetInfoLabel(NULL),
    m_rewardCCB(NULL),
    m_playOnButton(NULL),
    m_coin(NULL)
{
#ifdef BRANCH_CN
    if (SNSFunction_isAdVisible()) {
        m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIRedPanelCN.ccbi", this);
    }else{
        m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIRedPanel.ccbi", this);
    }
#else
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIRedPanel.ccbi", this);
#endif
    addChild(m_ccbNode);
    
    m_targetInfoLabel = (CCLabelBMFont *)m_levelTargetParent->getChildByTag(11)->getChildByTag(10);
    m_targetInfoLabel->setString("");
    m_targetInfoLabel->setWidth(220.f);
    m_targetInfoLabel->setAlignment(kCCTextAlignmentCenter);
    m_targetInfoLabel->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
}

FMUIRedPanel::~FMUIRedPanel()
{
    
}

#pragma mark - CCB Bindings
bool FMUIRedPanel::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_panel", CCSprite *, m_panel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_levelTargetParent", CCNode *, m_levelTargetParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_priceLabel", CCLabelBMFont *, m_priceLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_targetInfoLabel", CCLabelBMFont *, m_targetInfoLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_rewardCCB", CCNode *, m_rewardCCB);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_playOnButton", CCAnimButton *, m_playOnButton);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_coin", CCSprite *, m_coin);
    return true;
}

SEL_CCControlHandler FMUIRedPanel::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIRedPanel::clickButton);
    return NULL;
}

void FMUIRedPanel::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    switch (button->getTag()) { 
        case 5:
        {
            //play on
            FMDataManager* manager = FMDataManager::sharedManager();
            kPlayOnData & data = gPlayOnItems[gPlayOnTimes];
            
            bool success = false;
            
            if (manager->getWorldIndex() == 0 && manager->getLevelIndex() < 10 && !manager->isQuest()) {
                if (manager->isTutorialRunning()) {
                    manager->tutorialPhaseDone();
                }
                FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
                status->show(false, false);
                
                FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
                FMGameNode* gd = (FMGameNode*)scene->getNode(kGameNode);
                gd->addLeftMoves(5);
                gd->handleDialogFailed(DIALOG_OK);
                GAMEUI_Scene::uiSystem()->prevWindow();

            }else if (manager->useMoney(data.price, "Play On")) {
                success = true;
            }
            
            if (success) {
                FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
                status->show(false, false);

                givePlayerPlayOnReward();
                
                FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
                FMGameNode* gd = (FMGameNode*)scene->getNode(kGameNode);
                gd->handleDialogFailed(DIALOG_OK);
                GAMEUI_Scene::uiSystem()->prevWindow();
                
                //check if next is avaliable
                int next = gPlayOnTimes +1;
                int maxPlayOnTimes = sizeof(gPlayOnItems) / sizeof(kPlayOnData);
                if (next >= maxPlayOnTimes) {
                    next = maxPlayOnTimes-1;
                }
                
                kPlayOnData & data = gPlayOnItems[next];
                
                FMDataManager * manager = FMDataManager::sharedManager();
                bool available = true;
                for (int i=0; i<3; i++) {
                    kPlayOnItems type = data.item[i];
                    if (type <= kPlayOnItem_Booster6 && type >= kPlayOnItem_Booster1) {
                        int boosterType = type - kPlayOnItem_Booster1;
                        if (manager->isBoosterLocked(boosterType)) {
                            available = false;
                            break;
                        }
                    }
                }
                
                if (available) {
                    gPlayOnTimes = next;
                }
            }
        }
            break;
        case 0:
        {
            //quit
//            setHandleResult(DIALOG_CANCELED);
//            GAMEUI_Scene::uiSystem()->closeDialog();
            FMDataManager* manager = FMDataManager::sharedManager();
            
            if (manager->isTutorialRunning()) {
                return;
            }
            
            FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
            FMGameNode* gd = (FMGameNode*)scene->getNode(kGameNode);
            gd->handleDialogFailed(DIALOG_CANCELED);
            GAMEUI_Scene::uiSystem()->prevWindow();

            //reset play on
            gPlayOnTimes = 0;
        }
            break;
        case 6:
        {
#ifdef BRANCH_CN
            
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
                SNSFunction_showFreeGemsOffer();
#else
                FMUIFreeGolds * window = (FMUIFreeGolds *)FMDataManager::sharedManager()->getUI(kUI_FreeGolds);
                GAMEUI_Scene::uiSystem()->nextWindow(window);
#endif
            return;
#endif
            SNSFunction_showFreeGemsOffer();
        }
            break;
        default:
            break;
    }
}

void FMUIRedPanel::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        //quit
        //            setHandleResult(DIALOG_CANCELED);
        //            GAMEUI_Scene::uiSystem()->closeDialog();
        FMDataManager* manager = FMDataManager::sharedManager();
        
        if (manager->isTutorialRunning()) {
            return;
        }
        
        FMMainScene * scene = (FMMainScene *)manager->getUI(kUI_MainScene);
        FMGameNode* gd = (FMGameNode*)scene->getNode(kGameNode);
        gd->handleDialogFailed(DIALOG_CANCELED);
        GAMEUI_Scene::uiSystem()->prevWindow();
        
        //reset play on
        gPlayOnTimes = 0;
    }
}

void FMUIRedPanel::buyIAPCallback(cocos2d::CCObject *object)
{
    CCNumber * num = (CCNumber *)object;
    bool succeed = num->getIntValue() == 1;
    if (succeed) {
        givePlayerPlayOnReward();
        
//        setHandleResult(DIALOG_OK);
        GAMEUI_Scene::uiSystem()->closeDialog();
        
        //check if next is avaliable
        int next = gPlayOnTimes +1;
        int maxPlayOnTimes = sizeof(gPlayOnItems) / sizeof(kPlayOnData);
        if (next >= maxPlayOnTimes) {
            next = maxPlayOnTimes-1;
        }
        
        kPlayOnData & data = gPlayOnItems[next];
        
        FMDataManager * manager = FMDataManager::sharedManager();
        bool available = true;
        for (int i=0; i<3; i++) {
            kPlayOnItems type = data.item[i];
            if (type <= kPlayOnItem_Booster6 && type >= kPlayOnItem_Booster1) {
                int boosterType = type - kPlayOnItem_Booster1;
                if (manager->isBoosterLocked(boosterType)) {
                    available = false;
                    break;
                }
            }
        }
        
        if (available) {
            gPlayOnTimes = next;
        }
    }
    CCLOG("iap buy : %d" , succeed);
}

void FMUIRedPanel::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);

    FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
//    status->show(false, false);
    status->makeReadOnly(true);
    status->show(true, true);
    status->setZOrder(2000);

//    setVisible(true);
//    GAMEUI_Dialog::transitionIn(finishAction);
}

void FMUIRedPanel::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionOut(finishAction);

//    FMStatusbar * status = (FMStatusbar *)FMDataManager::sharedManager()->getUI(kUI_Statusbar);
//    status->show(true, false);
//    status->makeReadOnly(false);
//    status->setZOrder(50);
//    setVisible(false);
//    GAMEUI_Dialog::transitionIn(finishAction);
}

void FMUIRedPanel::setClassState(int state)
{
    GAMEUI::setClassState(state);
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
        default:
            break;
    }
}

void FMUIRedPanel::onEnter()
{
    GAMEUI_Window::onEnter();
    FMDataManager * manager = FMDataManager::sharedManager();
    FMGameNode * game = (FMGameNode *)((FMMainScene *)manager->getUI(kUI_MainScene))->getNode(kGameNode);
    
    if (classState() == kGameMode_Classic) {
        //targets
        std::map<int, int> m_targets;
#ifdef DEBUG
        CCDictionary * levelData = manager->getLevelData(manager->getLocalMode());
#else
        CCDictionary * levelData = manager->getLevelData(false);
#endif
        std::map<int, elementTarget> harvested = game->getTargets();
        
        CCArray * targets = (CCArray *)levelData->objectForKey("targets");
        int count = targets->count();
        static float unitLength = 50.f;
        float totalLength = unitLength * (count-1);
        if (count > 4) {
            count = 4;
        }
        for (int i=0; i<count; i++) {
            NEAnimNode * targetAnim = (NEAnimNode *)m_levelTargetParent->getChildByTag(11)->getChildByTag(i);
            targetAnim->releaseControl("Element");
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
            int harvestAmount = harvested[targetType].harvested;
            
            FMGameElement::changeAnimNode(target, (kElementType)targetType);
            target->playAnimation("TargetHarvest");
            if (targetAmount - harvestAmount > 0) {
                targetAnim->playAnimation("Init");
                CCString * s = CCString::createWithFormat("%d", targetAmount-harvestAmount);
                label->setString(s->getCString());
                label->setColor(ccc3(255, 0, 0));
            }else{
                targetAnim->playAnimation("check");
                label->setString("");
            }
            
        }
        
        for (int i =targets->count(); i<4; i++) {
            NEAnimNode * targetAnim = (NEAnimNode *)m_levelTargetParent->getChildByTag(11)->getChildByTag(i);
            targetAnim->setVisible(false);
        }
        
    }

    
    kPlayOnData & data = gPlayOnItems[gPlayOnTimes];
    int itemCount = 0;
    if (data.item[1] == kPlayOnItem_None) {
        itemCount = 1;
    }
    else if (data.item[2] == kPlayOnItem_None) {
        itemCount = 2;
    }
    else {
        itemCount = 3;
    }
    if (manager->getWorldIndex() == 0 && manager->getLevelIndex() < 10 && !manager->isQuest()) {
        itemCount = 1;
    }
    
    const char* tmpStr = FMDataManager::sharedManager()->getLocalizedString("V150_PLAYON_COST");
    CCString * s = CCString::createWithFormat(tmpStr, data.price);
    m_priceLabel->setString(s->getCString());
    
#ifdef BRANCH_CN
    CCPoint pricePt = m_priceLabel->getPosition();
    m_priceLabel->setPosition(ccp(3, pricePt.y));
    CCPoint coinPt = m_coin->getPosition();
    m_coin->setPosition(ccp(60, coinPt.y));
    
#endif
    
    CCNode * rewardParent = m_rewardCCB;
    CCBAnimationManager * ccbAnim = (CCBAnimationManager *)m_ccbNode->getUserObject();
    CCString * str = CCString::createWithFormat("%d", itemCount);
    ccbAnim->runAnimationsForSequenceNamed(str->getCString());
    
    for (int i=0; i<itemCount; i++) {
        CCAnimButton * button = (CCAnimButton *)rewardParent->getChildByTag(i)->getChildByTag(1);
        kGameBooster type = (kGameBooster)data.item[i];
        NEAnimNode * anim = (NEAnimNode *)button->getAnimNode()->getNodeByName("Booster");
        anim->useSkin(FMGameNode::getBoosterSkin(type));
        NEAnimNode * boosterCount = (NEAnimNode *)button->getAnimNode()->getNodeByName("Count");
        NEAnimNode * boosterClock = (NEAnimNode *)button->getAnimNode()->getNodeByName("Clock");
        boosterClock->setVisible(false);
        boosterCount->useSkin("Have");
        if (data.item[i] >= kPlayOnItem_5Moves) {
            boosterCount->setVisible(false);
        }
        else {
            boosterCount->setVisible(true);
            CCLabelBMFont * label = (CCLabelBMFont *)boosterCount->getNodeByName("Label");
            label->setString("1");
        }
    }
    m_coin->setVisible(true);
    if (manager->getWorldIndex() == 0 && manager->getLevelIndex() < 10 && !manager->isQuest()) {
        m_priceLabel->setString(manager->getLocalizedString("V150_FREE_PLAYON"));
        manager->checkNewTutorial("playon");
        m_coin->setVisible(false);
    }
//    manager->tutorialBegin();
}

void FMUIRedPanel::givePlayerPlayOnReward()
{
    kPlayOnData & data = gPlayOnItems[gPlayOnTimes];
    FMDataManager * manager = FMDataManager::sharedManager();
    FMGameNode * game = (FMGameNode *)((FMMainScene *)manager->getUI(kUI_MainScene))->getNode(kGameNode);
    for (int i=0; i<3; i++) {
        kPlayOnItems type = data.item[i];
        switch (type) {
            case kPlayOnItem_5Moves:
            {
                game->addLeftMoves(5);
            }
                break;
            case kPlayOnItem_Booster1:
            case kPlayOnItem_Booster2:
            case kPlayOnItem_Booster3:
            case kPlayOnItem_Booster4:
            case kPlayOnItem_Booster5:
            case kPlayOnItem_Booster6:
            {
                int boosterType = type - kPlayOnItem_Booster1;
                int num = manager->getBoosterAmount(boosterType);
                num += 1;
                manager->setBoosterAmount(boosterType, num);
            }
                break;
            default:
                break;
        }
    }
}

CCPoint FMUIRedPanel::getTutorialPosition()
{
    CCSize s = m_playOnButton->getContentSize();
    CCPoint pos = m_playOnButton->getPosition();
    CCPoint p = m_playOnButton->getParent()->convertToWorldSpace(pos);
    CCPoint p2 = m_playOnButton->getParent()->getParent()->getParent()->convertToNodeSpace(p);
    return p2;
}

CCSize FMUIRedPanel::getTutorialSize()
{
    CCSize s = m_playOnButton->getContentSize();
    return s;
}
