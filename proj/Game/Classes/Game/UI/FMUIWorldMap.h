//
//  FMUIWorldMap.h
//  FarmMania
//
//  Created by  James Lee on 13-5-26.
//
//

#ifndef __FarmMania__FMUIWorldMap__
#define __FarmMania__FMUIWorldMap__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI.h"
#include "NEAnimNode.h"
using namespace neanim;
using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIWorldMap : public GAMEUI , public CCBSelectorResolver, public CCBMemberVariableAssigner, public CCBAnimationManagerDelegate, public NEAnimCallback {
public:
    FMUIWorldMap();
    ~FMUIWorldMap();
private:
    CCNode * m_ccbNode;
    CCNode * m_parentNode;
//    CCNode * m_rewardParent;
    CCAnimButton * m_facebookButton;
    CCAnimButton * m_giftButton;
    CCAnimButton * m_bookBtn;
    NEAnimNode * m_rewardAnim;
    CCNode * m_wxNode;
    NEAnimNode * m_dailyAnim;
    NEAnimNode * m_friendsAnim;
    NEAnimNode * m_inviteAnim;

    CCAnimButton * m_spinButton;
    CCLabelBMFont * m_spinTimesLabel;

    //pop bonus
    NEAnimNode * m_unlimitLifeAnim;
    NEAnimNode * m_iapGoldBonusAni;
    NEAnimNode * m_starRewardAni;
    CCNode * m_bonusNode;
    bool m_isBonusExpand;

    bool m_isShown;
    bool m_isExpand;
    void setButtonListEnabled(bool enable);
    bool m_hasNewQuest;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual void completedAnimationSequenceNamed(const char *name);
    virtual void animationEnded(NEAnimNode * node, const char * animName);
    virtual void animationCallback(NEAnimNode * node, const char * animName, const char * callback);
public:
    virtual const char * classType() {return "FMUIWorldMap";}
    void show(bool isShown);
    void updateUI(bool showFacebook = true);
    void updateFacebook(bool showFacebook = true);
    void clickMenuButton(CCObject * object , CCControlEvent event);
    virtual bool ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent);
    virtual void onEnter();

    bool isHaveNewQuest() {return m_hasNewQuest;}
    void resetHaveNewQuest() {m_hasNewQuest = false;}
    void resetBookBtn();

    virtual void update(float delta);
    void updateStarRewardLabel();
    CCPoint getTutorialPosition(int index);
    void updateUnlimitLifeDiscountUI();

    
    void updateGoldIapBousUI();
    
    void clickAchievements(CCObject * object , CCControlEvent event);
    void clickPopBonusBtn(CCObject * object , CCControlEvent event);
    //item是m_unlimitLifeAnim等 星星奖励的位置idx是0
    void setItemPositionAtIndex(CCNode* item,int index);
    
    //true/show false/hide
    bool whetherShowBonusNode();
    void updateBonusNodeLightAnim();
    
    void shrinkPopBar();
    void updateGoogleLoginBtn(int islogin);
    
    virtual void keyBackClicked(void);
    
};

#endif /* defined(__FarmMania__FMUIWorldMap__) */
