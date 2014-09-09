//
//  FMUIGreenPanel.cpp
//  FarmMania
//
//  Created by James Lee on 13-5-27.
//
//

#include "FMUIGreenPanel.h"
#include "FMDataManager.h"
#include "NEAnimNode.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "FMGameElement.h"
using namespace neanim;

FMUIGreenPanel::FMUIGreenPanel() : 
    m_harvestMode(NULL),
    m_levelTargetParent(NULL),
    m_targetInfoLabel(NULL),
    m_goalLabel(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIGreenPanel.ccbi", this);
    CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
    anim->setDelegate(this);
    addChild(m_ccbNode);
    
    m_animNode = NEAnimNode::createNodeFromFile("FMUI_Transition.ani");
    addChild(m_animNode, 2);
    
    CCSize winSize = CCDirector::sharedDirector()->getWinSize();
    CCLayerColor * grey = CCLayerColor::create(ccc4(0, 0, 0, 128), winSize.width, winSize.height);
    grey->setAnchorPoint(ccp(0.5f, 0.5f));
    grey->ignoreAnchorPointForPosition(false);
    m_animNode->replaceNode("BG", grey);
    
    CCSize s = CCDirector::sharedDirector()->getWinSize();
    m_animNode->setPosition(ccp(s.width * 0.5f, s.height * 0.5f));
    
    
    m_targetInfoLabel = (CCLabelBMFont *)m_levelTargetParent->getChildByTag(11)->getChildByTag(10);
    m_targetInfoLabel->setString("");
    m_targetInfoLabel->setWidth(220.f);
    m_targetInfoLabel->setAlignment(kCCTextAlignmentCenter);
    m_targetInfoLabel->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    
    setTouchEnabled(false);
}

FMUIGreenPanel::~FMUIGreenPanel()
{
    
}

#pragma mark - CCB Bindings
bool FMUIGreenPanel::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_harvestMode", CCNode *, m_harvestMode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_levelTargetParent", CCNode *, m_levelTargetParent)
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_goalLabel", CCLabelBMFont *, m_goalLabel);
    return true;
}

SEL_CCControlHandler FMUIGreenPanel::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
//    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickIAP", FMUIGreenPanel::clickIAP);
    return NULL;
}

void FMUIGreenPanel::setGameMode(int gameMode)
{
    m_gameMode = gameMode;
    CCNode * targetNode = m_levelTargetParent->getChildByTag(11);
    switch (gameMode) {
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
}

void FMUIGreenPanel::setHarvestNumber(int number)
{
    GAMEUI::setClassState(kPanelGood);
    setVisible(true);
    m_ccbNode->setVisible(false);
    m_animNode->setVisible(true);
    if (number >= 10) {
        m_animNode->useSkin("unbelievable");
    }else if (number >= 8){
        m_animNode->useSkin("amazing");
    }else if (number >= 6){
        m_animNode->useSkin("awesome");
    }else if (number >= 5){
        m_animNode->useSkin("excellent");
    }else if (number >= 4){
        m_animNode->useSkin("great");
    }else{
        m_animNode->useSkin("good");
    }
    m_animNode->playAnimation("Good");
    m_animNode->setDelegate(this);
}

void FMUIGreenPanel::setClassState(int state)
{
    GAMEUI::setClassState(state);
    setVisible(true);
    CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
    m_ccbNode->setVisible(true);
    m_animNode->setVisible(false);
    switch (state) {
        case kPanelGoal:
        {
            anim->runAnimationsForSequenceNamed("SlideGoal");
        }
            break;
        case kPanelFail:
        {
            anim->runAnimationsForSequenceNamed("LevelFail");
        }
            break;
        case kPanelManiaMode:
        { 
            m_ccbNode->setVisible(false);
            m_animNode->setVisible(true); 
            m_animNode->playAnimation("ManiaTime");
            m_animNode->setDelegate(this);
            FMSound::playEffect("rainbow.mp3");
        }
            break;
        case kPanelComplete:
        {
            m_ccbNode->setVisible(false);
            m_animNode->setVisible(true);
            m_animNode->playAnimation("WellDone");
            m_animNode->setDelegate(this);
            FMSound::playEffect("completed.mp3");

        }
            break;
        case kPanel5MovesLeft:
        {
            m_ccbNode->setVisible(false);
            m_animNode->setVisible(true);
            m_animNode->playAnimation("FiveMovesLeft");
            m_animNode->setDelegate(this);
        }
            break;
//        case kPanelBoss:
//        {
//            anim->runAnimationsForSequenceNamed("SlideBoss");
//            m_targetInfoLabel->setString(FMDataManager::sharedManager()->getLocalizedString("V108_LEVEL_TARGET_BEAT_BOSS"));
//        }
//            break;
//        case kPanelVege:
//        {
//            anim->runAnimationsForSequenceNamed("SlideBoss");
//            m_targetInfoLabel->setString(FMDataManager::sharedManager()->getLocalizedString("V120_LEVEL_TARGET_HARVEST_CROPS"));
//        } 
//            break;
        case kPanelShuffle:
        {
            m_ccbNode->setVisible(false);
            m_animNode->setVisible(true);
            m_animNode->playAnimation("Shuffle");
            m_animNode->setDelegate(this);
        }
            break;
        default:
            break;
    }
    
}

void FMUIGreenPanel::animationEnded(neanim::NEAnimNode *node, const char *animName)
{
    FMDataManager * manager = FMDataManager::sharedManager();
    FMGameNode * game = (FMGameNode *)((FMMainScene *)manager->getUI(kUI_MainScene))->getNode(kGameNode);
    game->goalSlideDone();
    setVisible(false);
   
}

void FMUIGreenPanel::completedAnimationSequenceNamed(const char *name)
{ 
    FMDataManager * manager = FMDataManager::sharedManager();
    FMGameNode * game = (FMGameNode *)((FMMainScene *)manager->getUI(kUI_MainScene))->getNode(kGameNode);
    game->goalSlideDone();
    setVisible(false);    
}

void FMUIGreenPanel::animationCallback(neanim::NEAnimNode *node, const char *animName, const char *callback)
{
    
}


void FMUIGreenPanel::onEnter()
{
    CCLayer::onEnter();
    
    FMDataManager * manager = FMDataManager::sharedManager();
    int gameMode = manager->getGameMode();
    setGameMode(gameMode);
    if (m_gameMode == kGameMode_Classic) {
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
        
        for (int i =count; i<4; i++) {
            NEAnimNode * targetAnim = (NEAnimNode *)m_levelTargetParent->getChildByTag(11)->getChildByTag(i);
            targetAnim->setVisible(false);
        }
    }

    
#ifdef BRANCH_TH
    m_goalLabel->setVisible(false);
#endif
    
    
    
    
}