//
//  FMEditor.h
//  FarmMania
//
//  Created by  James Lee on 13-5-16.
//
//

#ifndef __FarmMania__FMEditor__
#define __FarmMania__FMEditor__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Dialog.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMLevelSelectDialog : public GAMEUI_Dialog, public CCBSelectorResolver, public CCBMemberVariableAssigner{
public:
    FMLevelSelectDialog();
    ~FMLevelSelectDialog();
public:
    CCLabelTTF * m_debugLevelLabel;
    CCControlButton * m_localButton;
    CCNode * m_levelButtonParent;
    CCControlButton * m_questButton;
    bool m_isLocalData;
    int m_worldIndex;
    int m_levelIndex;
    bool m_isQuest;
private:
    void updateUI();
protected:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    void clickLevelButton(CCObject * object, CCControlState state);
    void clickSwitchData();
    void clickSwitchQuest();
    void clickNextWorld();
    void clickPrevWorld();
    void clickExit();
public:
    bool isLocalMode() { return m_isLocalData; }
    int getWorldIndex() { return m_worldIndex; }
    int getLevelIndex() { return m_levelIndex; }
    bool isQuest() { return m_isQuest; }
};
#endif /* defined(__FarmMania__FMEditor__) */
