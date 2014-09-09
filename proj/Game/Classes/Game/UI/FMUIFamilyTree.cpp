//
//  FMUIFamilyTree.cpp
//  JellyMania
//
//  Created by lipeng on 14-2-20.
//
//

#include "FMUIFamilyTree.h"

#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMWorldMapNode.h"
#include "FMMainScene.h"
#include "FMStatusbar.h"
#include "NEAnimNode.h"
#include "SNSFunction.h"
#include "FMUIBranchLevel.h"
#include "CCBAnimationManager.h"
using namespace neanim;

FMUIFamilyTree::FMUIFamilyTree():
m_parentNode(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIFamilyTreeUI.ccbi", this);
    addChild(m_ccbNode);

    CCSize winSize = CCDirector::sharedDirector()->getWinSize();
//    winSize.height -= 100;
    CCSize cullingSize = CCDirector::sharedDirector()->getWinSize();
    cullingSize.width = 400.f;
    GUIScrollSlider * slider = new GUIScrollSlider(winSize, CCRect(-cullingSize.width*0.5 , -cullingSize.height*0.5 , cullingSize.width, cullingSize.height), 512.f, this, true);
    slider->setRevertDirection(true);
    m_slider = slider;
    m_parentNode->addChild(slider);
    m_slider->setCrossBorderEnable(false);
}

FMUIFamilyTree::~FMUIFamilyTree()
{
}

bool isJellyUnlock(int idx){
    FMDataManager* manager = FMDataManager::sharedManager();
    int wi = manager->getWorldIndex();
    int li = manager->getLevelIndex();
    bool quest = manager->isQuest();
    bool branch = manager->isBranch();
    BubbleLevelInfo * info = manager->getLevelInfo(idx);
    bool isdone = true;
    if (info && info->unlockLevelCount > 0) {
        manager->setLevel(idx, 0, true);
        if (!manager->isLevelBeaten()) {
            isdone = false;
        }
    }else{
        isdone = false;
    }
    manager->setLevel(idx+1, 0, false);
    if (manager->isLevelUnlocked()) {
        isdone = true;
    }
    manager->setLevel(wi, li, quest, branch);
    return isdone;
}

#pragma mark - CCB Bindings
bool FMUIFamilyTree::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
        return true;
}

SEL_CCControlHandler FMUIFamilyTree::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIFamilyTree::clickButton);
    return NULL;
}

void FMUIFamilyTree::updateButtonState(neanim::NEAnimNode *animNode, int flag, bool refresh)
{
    
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
    CCString * s = CCString::createWithFormat("%s1", key);
    
    animNode->playAnimation(s->getCString(), 0, false, !refresh);
}

void FMUIFamilyTree::clickJelly(cocos2d::CCObject *object, CCControlEvent event)
{
    CCControlButton * button = (CCControlButton *)object;
    CCNumber * nObject = (CCNumber *)button->getUserObject();
    if (!nObject) {
        return;
    }
    
    NEAnimNode * animNode = (NEAnimNode*)button->getParent();
    int flag = 0;
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
    if (nObject && !isDragging) {
        updateButtonState(animNode, flag, false);
    }
    if (event == CCControlEventTouchDown) {
        m_isClicked = true;
    }
    
    if (event == CCControlEventTouchDragInside) {
        m_isClicked = false;
    }
    
    
    if (event == CCControlEventTouchUpInside && m_isClicked) {
        int tag = nObject->getIntValue();
        if (!isJellyUnlock(tag)) {
            return;
        }
        FMSound::playEffect("click.mp3", 0.1f, 0.1f);
        FMDataManager* manager = FMDataManager::sharedManager();
        if (manager->isTutorialRunning()) {
            manager->tutorialPhaseDone();
        }
        manager->setLevel(tag, 0, true, true);
        GAMEUI_Scene::uiSystem()->prevWindow();
        FMUIBranchLevel * window = (FMUIBranchLevel* )manager->getUI(kUI_BranchLevel);
        GAMEUI_Scene::uiSystem()->nextWindow(window);
    }
}

void FMUIFamilyTree::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        //close
        FMSound::playEffect("click.mp3", 0.1f, 0.1f);
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIFamilyTree::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    CCControlButton * button = (CCControlButton *)object;
    switch (button->getTag()) {
        case 0:
        {
            //close
            FMSound::playEffect("click.mp3", 0.1f, 0.1f);
            GAMEUI_Scene::uiSystem()->prevWindow();
        }
            break;
        case 10:
        {
            if (event == CCControlEventTouchDown) {
                m_isClicked = true;
            }
            
            if (event == CCControlEventTouchDragInside) {
                m_isClicked = false;
            }
            
            
            if (event == CCControlEventTouchUpInside && m_isClicked) {
                CCNumber * n = (CCNumber *)button->getUserObject();
                int tag = n->getIntValue();
                if (!isJellyUnlock(tag)) {
                    return;
                }
                FMSound::playEffect("click.mp3", 0.1f, 0.1f);
                FMDataManager* manager = FMDataManager::sharedManager();
                if (manager->isTutorialRunning()) {
                    manager->tutorialPhaseDone();
                }
                manager->setLevel(tag, 0, true, true);
                GAMEUI_Scene::uiSystem()->prevWindow();
                FMUIBranchLevel * window = (FMUIBranchLevel* )manager->getUI(kUI_BranchLevel);
                GAMEUI_Scene::uiSystem()->nextWindow(window);
            }
        }
            break;
            
        default:
            break;
    }
    
}

void FMUIFamilyTree::setClassState(int state)
{
    GAMEUI::setClassState(state);
}

void FMUIFamilyTree::onEnter()
{
    GAMEUI_Window::onEnter();
//    CCPoint p = m_slider->getMainNode()->getPosition();
//    if (p.y >= 0) {
//        CCSize winsize = CCDirector::sharedDirector()->getWinSize();
//        if (winsize.height > 512.f) {
//            p.y = -56;
//            m_slider->getMainNode()->setPosition(p);
//        }
//    }
//    m_slider->refresh();
}

#pragma mark - slider delegate
CCNode * FMUIFamilyTree::createItemForSlider(GUIScrollSlider *slider)
{
    CCNode * node = FMDataManager::sharedManager()->createNode("UI/FMUIFamilyTree.ccbi", this);
//    CCLabelBMFont * label = (CCLabelBMFont*)node->getChildByTag(0)->getChildByTag(2)->getChildByTag(0);
//    if (label) {
//        label->setWidth(200);
//        label->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
//    }
    for (int i = 0; i < 4; i++) {
        CCNode * parent = node->getChildByTag(0)->getChildByTag(0)->getChildByTag(i)->getChildByTag(0);
        NEAnimNode* jelly = (NEAnimNode*)parent->getChildByTag(1);
        jelly->setScale(2.f);
        jelly->releaseControl("jelly", kProperty_Animation);
        jelly->releaseControl("jelly", kProperty_AnimationControl);
        jelly->releaseControl("Ring", kProperty_Visible);
        CCNode * ring = jelly->getNodeByName("Ring");
        ring->setVisible(false);
        
        CCScale9Sprite * buttonSprite = CCScale9Sprite::create("transparent.png");
        CCControlButton * button = CCControlButton::create(buttonSprite);
        button->setPreferredSize(CCSize(50, 50));
        jelly->replaceNode("1", button);
        button->addTargetWithActionForControlEvents(this, cccontrol_selector(FMUIFamilyTree::clickJelly), CCControlEventTouchDown | CCControlEventTouchDragInside | CCControlEventTouchUpInside | CCControlEventTouchDragEnter | CCControlEventTouchDragExit);
        
    }
    return node;
}
bool isFileExist(const char *filePath)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    return FMDataManager::sharedManager()->isFileExist(filePath);
#else
    std::string fullPath = CCFileUtils::sharedFileUtils()->fullPathForFilename(filePath);
    FILE *fp = fopen(fullPath.c_str(), "r");
    if (! fp)
    {
        return false;
    }
    else {
        fclose(fp);
        return true;
    }
#endif
}

int FMUIFamilyTree::itemsCountForSlider(GUIScrollSlider *slider)
{
    int t = 0;
    int number = 0;
    const char * jellyName = CCString::createWithFormat("Jelly_Role%d.ani", t+1)->getCString();
    bool exist = isFileExist(jellyName);
    while (exist) {
        if (number%4 == 0) {
            t++;
        }
        number++;
        jellyName = CCString::createWithFormat("Jelly_Role%d.ani", number+1)->getCString();
        exist = isFileExist(jellyName);
    }
    
    return t;
}

void FMUIFamilyTree::sliderUpdate(GUIScrollSlider *slider, int rowIndex, cocos2d::CCNode *node)
{
    CCNode * mainnode = node->getChildByTag(0);
//    mainnode->getChildByTag(2)->setVisible(rowIndex==0);
//    mainnode->getChildByTag(1)->setVisible(rowIndex==slider->getItemsCount()-1);
    
    FMDataManager * manager = FMDataManager::sharedManager();
    
    for (int i = 0; i < 4; i++) {
        CCNode * parent = mainnode->getChildByTag(0)->getChildByTag(i)->getChildByTag(0);
        int jellyIndex = rowIndex*4+i;
        
        CCControlButton* btn = (CCControlButton*)parent->getChildByTag(10);
        btn->setDefaultTouchPriority(-getZOrder() -1);
        btn->setTouchPriority(-getZOrder()-1);
        CCNumber * nobject = CCNumber::create(jellyIndex);

        btn->setUserObject(nobject);
        
        //        btn = (CCControlButton*)parent->getChildByTag(11);
        //        btn->setDefaultTouchPriority(-getZOrder() -1);
        //        btn->setTouchPriority(-getZOrder()-1);
        //        nobject = CCNumber::create(jellyIndex);
        //        btn->setUserObject(nobject);
        
        NEAnimNode* buttonAnim = (NEAnimNode*)parent->getChildByTag(1);
        CCLabelBMFont* l1 = (CCLabelBMFont*)parent->getChildByTag(2);
        CCLabelBMFont* l2 = (CCLabelBMFont*)parent->getChildByTag(3);
        l2->setAlignment(kCCTextAlignmentCenter);
        l2->setWidth(100);
        l2->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
        
#ifdef BRANCH_TH
        l1->setPosition(ccp(0, -60));
        l2->setScale(0.85f);
        l2->setPosition(ccp(0, -80));
#endif
        
        updateButtonState(buttonAnim, 0);
        
        NEAnimNode* jelly = (NEAnimNode*)buttonAnim->getNodeByName("jelly");
        CCControlButton* button = (CCControlButton *)buttonAnim->getNodeByName("1");
        
        CCBAnimationManager * m = (CCBAnimationManager *)mainnode->getChildByTag(0)->getChildByTag(i)->getUserObject();
        if (isJellyUnlock(jellyIndex)) {
            m->runAnimationsForSequenceNamed("Init0");

            l1->setString(manager->getLocalizedString(CCString::createWithFormat("V110_JELLY_NAME%d",jellyIndex+1)->m_sString.c_str()));
            CCString * cstr = CCString::createWithFormat(manager->getLocalizedString("V100_HANDBOOK_CHAPTER"),jellyIndex+1);
            l2->setString(cstr->m_sString.c_str());
            
            cstr = CCString::createWithFormat("Jelly_Role%d.ani",jellyIndex+1);
            jelly->changeFile(cstr->m_sString.c_str());
            cstr = CCString::createWithFormat("Idle%d",manager->getRandom()%2+1);
            jelly->playAnimation(cstr->m_sString.c_str());
            
            btn->setVisible(true);
            
            if (button->getUserObject()) {
                button->setUserObject(NULL);
            }
            nobject = CCNumber::create(jellyIndex);
            button->setUserObject(nobject);
            button->setEnabled(true);

        }else{
            m->runAnimationsForSequenceNamed("Init1");
            
            l1->setString("");
            CCString * cstr = CCString::createWithFormat(manager->getLocalizedString("V100_HANDBOOK_CHAPTERUNLOCK"),jellyIndex+1);
            l2->setString(cstr->m_sString.c_str());
            jelly->changeFile("Jelly_Role1.ani");
            jelly->playAnimation("Unlock");
            
            btn->setVisible(false);
            button->setEnabled(false);
        }
        
        NEAnimNode* crown = (NEAnimNode*)parent->getChildByTag(4);
        if (manager->isChallengeCleared(jellyIndex)) {
            crown->playAnimation("1Idle");
        }else{
            crown->playAnimation("0Idle");
        }
        
        bool isnew = manager->isNewJelly(jellyIndex);
        CCNode* n = parent->getChildByTag(5);
        n->setVisible(isnew);
        
        n = parent->getChildByTag(6);
        n->setVisible(isnew);
    }
}


void FMUIFamilyTree::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIFamilyTree::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionOut(finishAction);
}
void FMUIFamilyTree::transitionInDone()
{
    GAMEUI_Window::transitionInDone();
    FMDataManager::sharedManager()->checkNewTutorial("familytree");
    FMDataManager::sharedManager()->tutorialBegin();
}

CCPoint FMUIFamilyTree::getTutorialPosition(int idx)
{
    CCNode* node = m_slider->getItemForRow(0);
    CCNode * parent = node->getChildByTag(0)->getChildByTag(0)->getChildByTag(0)->getChildByTag(0);
    CCNode * tnode = parent->getChildByTag(idx);
//    CCPoint p = tnode->getPosition();
//    p = parent->convertToWorldSpace(p);
//    p = convertToNodeSpace(p);
//    
//    CCSize winsize = CCDirector::sharedDirector()->getWinSize();
//    p.x += winsize.width/2;
//    p.y += winsize.height/2;

    CCPoint p = tnode->convertToWorldSpace(ccp(tnode->boundingBox().size.width/2, tnode->boundingBox().size.height/2));
    
    return p;
}

