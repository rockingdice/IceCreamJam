//
//  FMLoadingScene.h
//  FarmMania
//
//  Created by  James Lee on 13-6-9.
//
//

#ifndef __FarmMania__FMLoadingScene__
#define __FarmMania__FMLoadingScene__

#include <iostream>
#include "cocos2d.h"
using namespace cocos2d;
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "OBJCHelper.h"
using namespace cocos2d;
using namespace cocos2d::extension;

class FMLoadingScene : public CCScene , public CCBSelectorResolver, public CCBMemberVariableAssigner, public OBJCHelperDelegate, public CCKeypadDelegate{
public:
    FMLoadingScene();
    ~FMLoadingScene();
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual void facebookLoginSuccess();
    virtual void facebookLoginFaild() {m_fbClicked = false;}
    void textureLoadDone(CCObject * texture);
private:
    float m_time;
    int m_count;
    int m_index;
    bool m_texturesLoaded;
    bool m_uiLoaded;
    bool m_playClicked;
    bool m_fbClicked;
    CCNode * m_ccbNode;
    CCLabelBMFont * m_loadingLabel;
    CCLabelBMFont * m_loadingLabel2;

    virtual void update(float delta);
    virtual void onEnter();
    virtual void onExit();
    
    void clickButton(CCObject * object);
    void showButton();
    void playAction();
    virtual void keyBackClicked();
};

#endif /* defined(__FarmMania__FMLoadingScene__) */
