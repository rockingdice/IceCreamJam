//
//  FMLevelConfig.h
//  FarmMania
//
//  Created by  James Lee on 13-5-21.
//
//

#ifndef __FarmMania__FMLevelConfig__
#define __FarmMania__FMLevelConfig__

#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GUIScrollSlider.h" 
#include "FMGameElement.h"
using namespace cocos2d;
using namespace cocos2d::extension;

typedef struct ElementAmountPairData
{
    kElementType type;
    int amount;
    const char * file;
    const char * anim;
    const char * skin;
	bool operator < (const ElementAmountPairData& ti) const {
        if (amount == ti.amount)
            return type < ti.type;
        else
            return amount > ti.amount;
	}
}ElementAmountPairData;

typedef struct PairData
{
    int pair1;
    int pair2;
    bool operator < (const PairData& p) const {
        return pair1 < p.pair1;
	}
}PairData;

typedef struct BoxData
{
    int boxid;
    int boxhp;
    std::vector<PairData> spawnlist;
    std::vector<PairData> randomrate;
    
	bool operator < (const BoxData& bd) const {
        return boxid < bd.boxid;
    }
}BoxData;

class FMLevelConfig : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner, public GUIScrollSliderDelegate {
public:
    FMLevelConfig();
    ~FMLevelConfig();
    
private:
    CCDictionary * m_levelData;
    CCScrollView * m_container;
    CCNode * m_ui;
    CCNode * m_buttonParent;
    CCNode * m_mainbuttonParent;
    std::vector<ElementAmountPairData> m_spData;
    std::vector<ElementAmountPairData> m_tgData;
    std::vector<ElementAmountPairData> m_cLimitData;
    std::vector<ElementAmountPairData> m_lLimitData;
    std::vector<BoxData> m_boxesData;
    int m_row;
    int m_col;
    CCArray * m_seeds;  
    int m_selectedSeed;
    int m_selectedBox;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual CCNode * createItemForSlider(GUIScrollSlider * slider);
    virtual int itemsCountForSlider(GUIScrollSlider * slider);
    virtual void sliderUpdate(GUIScrollSlider * slider, int rowIndex, CCNode * node);
    void clickExit(CCObject * object, CCControlEvent event);
    void clickButton(CCObject * object, CCControlEvent event);
    void clickPairButton(CCObject * object, CCControlEvent event);
    void clickSeedButton(CCObject * object, CCControlEvent event); 
    void handleInputNumberDialog(CCNode * node);
    void loadLevelData(CCDictionary * data);
    std::vector<ElementAmountPairData> * getElementDataArray(int row);
    void updateUI();
    void setSelectedSeed(int index) {m_selectedSeed = index;}
    virtual void onEnter() { CCLayer::onEnter(); }
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    
    
};

#endif /* defined(__FarmMania__FMLevelConfig__) */
