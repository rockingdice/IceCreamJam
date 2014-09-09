//
//  FMEditor.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-16.
//
//

#include "FMLevelSelectDialog.h"
#include "FMDataManager.h"
#include "BubbleServiceFunction.h"
#include "GAMEUI_Scene.h"

#pragma mark - CCB Bindings
FMLevelSelectDialog::FMLevelSelectDialog() :
    m_debugLevelLabel(NULL),
    m_levelButtonParent(NULL),
    m_localButton(NULL),
    m_questButton(NULL),
    m_worldIndex(0),
    m_levelIndex(0),
    m_isQuest(false),
    m_isLocalData(false)
{
    CCNode * ui = FMDataManager::sharedManager()->createNode("Editor/FMLevelSelect.ccbi", this);
    addChild(ui);
     
    FMDataManager * manager = FMDataManager::sharedManager();
    m_worldIndex = manager->getWorldIndex();
    m_levelIndex = manager->getLevelIndex();
    m_isQuest = manager->isQuest();
    updateUI();
}

FMLevelSelectDialog::~FMLevelSelectDialog()
{
    
}

bool FMLevelSelectDialog::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_debugLevelLabel", CCLabelTTF *, m_debugLevelLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_levelButtonParent", CCNode *, m_levelButtonParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_localButton", CCControlButton *, m_localButton);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_questButton", CCControlButton *, m_questButton);
    return true;
}

SEL_CCControlHandler FMLevelSelectDialog::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickLevelButton", FMLevelSelectDialog::clickLevelButton);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickExit", FMLevelSelectDialog::clickExit);;
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickSwitchData", FMLevelSelectDialog::clickSwitchData);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickSwitchQuest", FMLevelSelectDialog::clickSwitchQuest);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickPrevWorld", FMLevelSelectDialog::clickPrevWorld);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickNextWorld", FMLevelSelectDialog::clickNextWorld);
    
    return NULL;
}

void FMLevelSelectDialog::clickLevelButton(cocos2d::CCObject *object, CCControlState state)
{
    CCNode * node = (CCNode *)object;
    int tag = node->getTag();
    m_levelIndex = tag-1;
    m_result = DIALOG_OK;
    GAMEUI_Scene::uiSystem()->closeDialog();
}

void FMLevelSelectDialog::clickExit()
{
    m_result = DIALOG_CANCELED;
    GAMEUI_Scene::uiSystem()->closeDialog();
}


void FMLevelSelectDialog::clickSwitchData()
{
    m_isLocalData = !m_isLocalData;
#ifdef DEBUG
    FMDataManager * manager = FMDataManager::sharedManager();
    manager->setLocalMode(m_isLocalData);
#endif
    updateUI();
}

void FMLevelSelectDialog::clickNextWorld()
{
    int count = BubbleServiceFunction_getLevelCount();
    m_worldIndex++;
    if (m_worldIndex >= count) {
        m_worldIndex = count -1;
    }
    
    updateUI();
}

void FMLevelSelectDialog::clickPrevWorld()
{
    m_worldIndex --;
    if (m_worldIndex < 0) {
        m_worldIndex = 0;
    }
    updateUI();
}

void FMLevelSelectDialog::updateUI()
{
    FMDataManager * manager = FMDataManager::sharedManager();
#ifdef DEBUG
    m_isLocalData = manager->getLocalMode();
#endif
    std::stringstream ss;
    int worldIndex = manager->getWorldIndex();
    int levelIndex = manager->getLevelIndex();
    bool isQuest = manager->isQuest();
    
    
    
    BubbleLevelInfo * info = manager->getLevelInfo(m_worldIndex);
    int subCount = 0;
    
    if (m_isQuest) {
        subCount = info->unlockLevelCount;
    }
    else {
        subCount = info->subLevelCount;
    }

    
    for (int i=0; i<15; i++) {
        BubbleSubLevelInfo * subInfo = m_isQuest ? info->getUnlockLevel(i) : info->getSubLevel(i);
        CCControlButton * button = (CCControlButton *)m_levelButtonParent->getChildByTag(i+1);
        CCLabelTTF * label = (CCLabelTTF *)button->getTitleLabel();
        if (i == levelIndex && m_worldIndex == worldIndex && m_isQuest == isQuest) {
            button->setTitleColorForState(ccc3(255, 255, 8), CCControlStateNormal);
        }
        else {
            button->setTitleColorForState(ccc3(255, 255, 255), CCControlStateNormal);
        }
        if (i < subCount) {
            button->setEnabled(true);
            button->setVisible(true);
            ss.str("");
            ss << manager->getGlobalIndex(m_worldIndex, i) << "\n(" << subInfo->ID << ")";
            label->setString(ss.str().c_str());
        }
        else {
            button->setEnabled(false);
            button->setVisible(false);
        }
    }
    ss.str("");
    ss << "World " << m_worldIndex+1;
    m_debugLevelLabel->setString(ss.str().c_str());
    
    CCLabelTTF * label = (CCLabelTTF *)m_localButton->getTitleLabel();
    if (m_isLocalData) {
        label->setString("读取本地数据");
    }
    else {
        label->setString("读取远程数据");
    }
    
    label = (CCLabelTTF *)m_questButton->getTitleLabel();
    if (m_isQuest) {
        label->setString("任务");
    }
    else {
        label->setString("普通");
    }
    
}

void FMLevelSelectDialog::clickSwitchQuest()
{
    m_isQuest = !m_isQuest;
    updateUI();
}