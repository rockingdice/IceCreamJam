//
//  FMTutorial.h
//  FarmMania
//
//  Created by James Lee on 13-6-9.
//
//

#ifndef __FarmMania__FMTutorial__
#define __FarmMania__FMTutorial__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "NEAnimNode.h"
#include "CCAnimButton.h"

using namespace cocos2d;
using namespace cocos2d::extension;
using namespace neanim;

class FMTutorial : public CCLayer, public CCBSelectorResolver, public CCBMemberVariableAssigner {
public:
    FMTutorial();
    ~FMTutorial();
    static FMTutorial * tut();
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
private:
    bool m_inScreen;
    bool m_isTapToContinue; 
    CCLabelBMFont * m_tapToContinue;
    CCNode * m_ccbNode;
    CCNode * m_chick;
    CCNode * m_dialog;
    CCLabelBMFont * m_info;
    CCNode * m_arrow;
    CCNode * m_arrowtop;
    CCNode * m_arrowbottom;
    CCRenderTexture * m_mainTexture;
    CCScale9Sprite * m_mask[2];
    CCSprite * m_maskCircle;
    CCLayerColor * m_bg;
    CCSprite * m_rt;
    NEAnimNode * m_guildhand;
    CCPoint getPointFromString(CCString * str);
    CCAnimButton * m_skipBtn;
public:
    void updateTutorial(CCDictionary * tut, int idx = 0);
    void tutorialEnd(CCDictionary * tut);
    void showMask(int tag, CCDictionary * maskData);
    void fade(bool fadein);
    void render();
    void clickSkip(CCObject * object, CCControlEvent event);
protected:
    virtual bool ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent);
};

#endif /* defined(__FarmMania__FMTutorial__) */
