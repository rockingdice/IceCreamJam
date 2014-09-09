//
//  FMUIWorldMap.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-26.
//
//

#include "FMUIWorldMap.h"
#include "FMDataManager.h"
#include "FMUIConfig.h"
#include "FMStatusbar.h"
#include "GAMEUI_Scene.h"
#include "FMMainScene.h"
#include "FMWorldMapNode.h"
#include "FMUIInAppStore.h"
#include "SNSFunction.h"
#include "OBJCHelper.h"
#include "FMUIFamilyTree.h"
#include "FMUIInvite.h"
#include "FMUIInputName.h"
#include "FMUISpin.h"
#include "FMUIStarReward.h"
#include "FMUIUnlimitLifeDiscount.h"
#include "FMUIGoldIapBonus.h"

static float m_widthForTwoCN = 36.f;
static float m_widthForThreeCN = 50.f;


FMUIWorldMap::FMUIWorldMap() :
    m_parentNode(NULL),
//    m_rewardParent(NULL),
    m_giftButton(NULL),
    m_facebookButton(NULL),
    m_rewardAnim(NULL),
    m_isShown(false),
    m_isExpand(false),
    m_isBonusExpand(false),
    m_wxNode(NULL),
    m_dailyAnim(NULL),
    m_friendsAnim(NULL),
    m_inviteAnim(NULL),
    m_hasNewQuest(false),
    m_bookBtn(NULL),
    m_spinTimesLabel(NULL),
    m_spinButton(NULL),
    m_unlimitLifeAnim(NULL),
    m_iapGoldBonusAni(NULL),
    m_starRewardAni(NULL),
    m_bonusNode(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIWorldMap.ccbi", this);
    addChild(m_ccbNode);
    
    CCBAnimationManager * manager = (CCBAnimationManager *)m_ccbNode->getUserObject();
    manager->setDelegate(this);
    
//    NEAnimNode * facebook = NEAnimNode::createNodeFromFile("FMUIButtonList.ani");
//    m_rewardParent->addChild(facebook, 1, 1);
    
    //init button list

#ifdef BRANCH_CN
//    CCControlButton * arrowButton = CCControlButton::create(CCScale9Sprite::create("transparent.png"));
//    arrowButton->setPreferredSize(CCSize(40, 21));
//    arrowButton->setAnchorPoint(CCPointZero);
//    arrowButton->addTargetWithActionForControlEvents(this, cccontrol_selector(FMUIWorldMap::clickMenuButton), CCControlEventTouchUpInside);
//    
//    p = facebook->getNodeByName("ButtonArrow");
//    p->addChild(arrowButton, 0, 1);
//    
//    CCControlButton * button1 = CCControlButton::create(CCScale9Sprite::create("transparent.png"));
//    button1->setPreferredSize(CCSize(37, 37));
//    button1->setAnchorPoint(CCPointZero);
//    button1->addTargetWithActionForControlEvents(this, cccontrol_selector(FMUIWorldMap::clickMenuButton), CCControlEventTouchDown);
//    
//    p = facebook->getNodeByName("Button1");
//    p->addChild(button1, 0, 3);
//    
//    CCControlButton * button2 = CCControlButton::create(CCScale9Sprite::create("transparent.png"));
//    button2->setPreferredSize(CCSize(37, 37));
//    button2->setAnchorPoint(CCPointZero);
//    button2->addTargetWithActionForControlEvents(this, cccontrol_selector(FMUIWorldMap::clickMenuButton), CCControlEventTouchDown);
//    
//    p = facebook->getNodeByName("Button2");
//    p->addChild(button2, 0, 4);
    CCLabelBMFont* label = (CCLabelBMFont*)m_friendsAnim->getNodeByName("Label");
    label->setWidth(m_widthForThreeCN);
    label->setAlignment(kCCTextAlignmentCenter);
    label->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    
    label = (CCLabelBMFont*)m_rewardAnim->getNodeByName("Label");
    label->setWidth(m_widthForTwoCN);
    label->setAlignment(kCCTextAlignmentCenter);
    label->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
#ifdef BRANCH_CN
    m_rewardAnim->setVisible(!FMDataManager::sharedManager()->hasPurchasedUnlimitLife());
#endif

    
    
    label = (CCLabelBMFont*)m_dailyAnim->getNodeByName("Label");
    label->setWidth(m_widthForTwoCN);
    label->setAlignment(kCCTextAlignmentCenter);
    label->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    
    label = (CCLabelBMFont*)m_inviteAnim->getNodeByName("Label");
    label->setWidth(m_widthForTwoCN);
    label->setAlignment(kCCTextAlignmentCenter);
    label->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
#endif

    CCSprite * tbg = CCSprite::createWithSpriteFrameName("UnreadMessage.png");
    tbg->setAnchorPoint(ccp(1, 1));
    tbg->setPosition(ccp(m_spinButton->getContentSize().width, m_spinButton->getContentSize().height));
    tbg->setScale(1.2f);
    m_spinButton->addChild(tbg);
    
    m_spinTimesLabel = CCLabelBMFont::create("", "font_7.fnt", 50, kCCTextAlignmentCenter);
    tbg->addChild(m_spinTimesLabel);
    m_spinTimesLabel->setPosition(ccp(tbg->getContentSize().width/2 - 0.5f , tbg->getContentSize().height/2 - 0.5f ));

    scheduleUpdate();
}

FMUIWorldMap::~FMUIWorldMap()
{
    
}
void FMUIWorldMap::onEnter()
{
    GAMEUI::onEnter();
    resetBookBtn();
    
#ifndef BRANCH_CN
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    updateGoogleLoginBtn(-1);
    m_bonusNode->setVisible(false);
#else
    m_bonusNode->setVisible(false);
#endif
    
#else
    m_bonusNode->setVisible(whetherShowBonusNode());
    updateBonusNodeLightAnim();
#endif
	m_spinButton->setVisible(OBJCHelper::helper()->showMinigame());
}

void FMUIWorldMap::updateGoogleLoginBtn( int islogined )
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    if( SNSFunction_getPackageType() == PT_GOOGLE_EN_FACEBOOK){
        CCNode *root = m_ccbNode->getChildByTag(0);
        CCNode *gameCenter = root ? root->getChildByTag(100) : NULL;
        if( gameCenter){
            //bool islogin = (islogined == -1 ? SNSFunction_isGooglePlayLogin() : islogined);
            gameCenter->setVisible(true);
            CCNode *btnGoogle = gameCenter->getChildByTag(1);
            CCNode *btnArchievement = gameCenter->getChildByTag(2);
            if( btnGoogle ) btnGoogle->setVisible(true);
            if( btnArchievement ) btnArchievement->setVisible(false);
        }
    }
#endif
}

void FMUIWorldMap::updateUnlimitLifeDiscountUI()
{
#ifndef BRANCH_CN
    return;
#endif

    FMDataManager* manager = FMDataManager::sharedManager();
    CCLabelBMFont* label = NULL;
    m_unlimitLifeAnim->releaseControl("Label", kProperty_StringValue);
    label = (CCLabelBMFont*)m_unlimitLifeAnim->getNodeByName("Label");

    CCString* timeStr = manager->getUnlimitLifeDiscountRestTimeStr();
    label->setVisible( !(strcmp(timeStr->getCString(), "")==0) );
    label->setString(timeStr->getCString());
}

void FMUIWorldMap::updateGoldIapBousUI()
{
#ifndef BRANCH_CN
    return;
#endif

    FMDataManager* manager = FMDataManager::sharedManager();
    m_iapGoldBonusAni->releaseControl("Label", kProperty_StringValue);
    CCLabelBMFont* label = (CCLabelBMFont*)m_iapGoldBonusAni->getNodeByName("Label");
    double endTime = manager->getDiscountTimeByKey(kGoldIapBouns,false);
    int remain = manager->getRemainTime(endTime);
    CCString* timeStr = manager->getTimeString(remain);
    label->setString(timeStr->getCString());
    
}
void FMUIWorldMap::update(float delta)
{
    int t = FMDataManager::sharedManager()->getSpinTimes();
    if (t == 0) {
        m_spinTimesLabel->getParent()->setVisible(false);
        m_spinTimesLabel->setString("0");
    }else{
        m_spinTimesLabel->getParent()->setVisible(true);
        m_spinTimesLabel->setString(CCString::createWithFormat("%d",t)->getCString());
    }

#ifdef BRANCH_CN
    m_rewardAnim->setVisible(!FMDataManager::sharedManager()->hasPurchasedUnlimitLife());
    if (m_isBonusExpand) {
        updateUnlimitLifeDiscountUI();
        updateGoldIapBousUI();
        updateStarRewardLabel();
    }
#endif
}






void FMUIWorldMap::updateStarRewardLabel()
{
    FMDataManager* manager = FMDataManager::sharedManager();
    int idx = manager->getNextStarRewardIndex();
    int maxIdx = sizeof(s_starReward) / (sizeof(int)*3) -1;
    idx = MIN(idx, maxIdx);
    int curStar = manager->getAllStarsFromSave();
    int nextStar = s_starReward[idx][0];
    //curStar = MIN(curStar, nextStar);
    
    char buf[16] = {0};
    sprintf(buf, "%d/%d",curStar,nextStar);
    
    m_starRewardAni->releaseControl("Label", kProperty_StringValue);
    CCLabelBMFont* label = (CCLabelBMFont*)m_starRewardAni->getNodeByName("Label");
    label->setString(buf);
}


void FMUIWorldMap::completedAnimationSequenceNamed(const char *name)
{
    if (strcmp(name, "SlideIn") == 0) {
        FMMainScene * scene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMWorldMapNode * worldmap = (FMWorldMapNode *)scene->getNode(kWorldMapNode);
        worldmap->slideDone();
    }
}

void FMUIWorldMap::animationCallback(neanim::NEAnimNode *node, const char *animName, const char *callback)
{
//#ifdef BRANCH_CN
//    if (strcmp(animName, "CNExpand") == 0 && strcmp(callback, "expandCallback") == 0)  {
//        NEAnimNode * shareNode = (NEAnimNode *)m_rewardParent->getChildByTag(1);
//        
//        NEAnimNode * label2 = (NEAnimNode *)shareNode->getNodeByName("Label2");
//        label2->resumeAnimation();
//        
//        NEAnimNode * label1 = (NEAnimNode *)shareNode->getNodeByName("Label1");
//        label1->resumeAnimation();
//        setButtonListEnabled(true);
//    }
//#endif
}

void FMUIWorldMap::animationEnded(neanim::NEAnimNode *node, const char *animName)
{
    
}

#pragma mark - CCB Bindings
bool FMUIWorldMap::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
//    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_rewardParent", CCNode *, m_rewardParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_wxNode", CCNode *, m_wxNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_giftButton", CCAnimButton *, m_giftButton);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_facebookButton", CCAnimButton *, m_facebookButton);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_bookBtn", CCAnimButton *, m_bookBtn);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_rewardAnim", NEAnimNode *, m_rewardAnim);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_friendsAnim", NEAnimNode *, m_friendsAnim);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_dailyAnim", NEAnimNode *, m_dailyAnim);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_inviteAnim", NEAnimNode *, m_inviteAnim);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_spinButton", CCAnimButton *, m_spinButton);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_starRewardAni", NEAnimNode *, m_starRewardAni);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_iapGoldBonusAni", NEAnimNode * , m_iapGoldBonusAni);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_unlimitLifeAnim", NEAnimNode * , m_unlimitLifeAnim);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_bonusNode", CCNode *, m_bonusNode);

    return true;
}

SEL_CCControlHandler FMUIWorldMap::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickMenuButton", FMUIWorldMap::clickMenuButton);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickPopBonusBtn", FMUIWorldMap::clickPopBonusBtn);
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickAchievements", FMUIWorldMap::clickAchievements);
    return NULL;
}

void FMUIWorldMap::clickAchievements(CCObject * object, CCControlEvent event)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    if( SNSFunction_getPackageType() == PT_GOOGLE_EN_FACEBOOK){
        SNSFunction_openAchievement();
    }
#endif
}

void FMUIWorldMap::clickPopBonusBtn(CCObject * object, CCControlEvent event)
{
    if (!m_bonusNode->isVisible() || !whetherShowBonusNode()) {
        m_bonusNode->setVisible(false);
        return;
    }
    
    
#ifdef BRANCH_CN
    
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    FMDataManager * manager = FMDataManager::sharedManager();
    int tag = button->getTag();
    tag > 10 ? tag /= 10 : 1;
    
    switch (tag) {
        case 1:
        {
            CCNode* barNode = button->getParent()->getChildByTag(999);
            //expand || !expand
            m_isBonusExpand = !m_isBonusExpand;
            CCBAnimationManager * anim = (CCBAnimationManager *)m_bonusNode->getUserObject();
            
            if (m_isBonusExpand) {
                int itemCount = 0;
                CCNode* unShowNodes[3] = {NULL,NULL,NULL};
                CCNode* showNodes[3] = {NULL,NULL,NULL};
                
                bool starBonusVisible = manager->whetherUnsealStarBonus();
                if (starBonusVisible) {
                    m_starRewardAni->playAnimation("BlueInToLeft", 0, false, true);
                    updateStarRewardLabel();
                    ++itemCount;
                    showNodes[0] = m_starRewardAni;
                }else{
                    unShowNodes[0] = m_starRewardAni;
                }
                
                bool iapBonus = manager->whetherUnsealIapBouns();
                if (iapBonus) {
                    m_iapGoldBonusAni->playAnimation("GreenInToLeft", 0, false, true);
                    ++itemCount;
                    showNodes[1] = m_iapGoldBonusAni;
                }else{
                    unShowNodes[1] = m_iapGoldBonusAni;
                }
                
                bool unlimitVisible = manager->whetherUnsealUnlimitLifeDiscount();
                if (unlimitVisible) {
                    m_unlimitLifeAnim->playAnimation("PurInToLeft", 0, false, true);
                    ++itemCount;
                    showNodes[2] = m_unlimitLifeAnim;
                }else{
                    unShowNodes[2] = m_unlimitLifeAnim;
                }

                char aniName[8] = {0};
                sprintf(aniName, "On%d",itemCount);
                anim->runAnimationsForSequenceNamed(aniName);
                
                int posIndex = 0;
                for (int i = 0; i < 3; ++i) {
                    if (unShowNodes[i] != NULL) {
                        unShowNodes[i]->setVisible(false);
                        unShowNodes[i]->setPosition(ccp(0, 99999));
                        CCControlButton* btn1 = (CCControlButton* )barNode->getChildByTag(i+3);
                        CCControlButton* btn2 = (CCControlButton* )barNode->getChildByTag((i+3)*10);
                        btn1->setEnabled(false);
                        btn1->setPosition(ccp(0, 99999));
                        btn2->setEnabled(false);
                        btn2->setPosition(ccp(0, 99999));
                    }
                    
                    if (showNodes[i] != NULL) {
                        setItemPositionAtIndex(showNodes[i], posIndex);
                        posIndex++;
                    }
                }
            }
            else {
                anim->runAnimationsForSequenceNamed("Off");
                
                if (m_unlimitLifeAnim->isVisible()) {
                    m_unlimitLifeAnim->playAnimation("PurOut", 0, false, true);
                }
                if (m_iapGoldBonusAni->isVisible()) {
                    m_iapGoldBonusAni->playAnimation("GreenOut", 0, false, true);
                }
                m_starRewardAni->playAnimation("BlueOut", 0, false, true);
            }
            updateBonusNodeLightAnim();
            
        }
            break;
            
        case 3:
        {
            //星星奖励
            if (manager->whetherUnsealStarBonus()) {
                manager->showStarReward();
            }
            
        }
            break;
            
        case 4:
        {
            //iap充值奖励
            FMUIGoldIapBonus * window = (FMUIGoldIapBonus* )manager->getUI(kUI_GoldIapBonus);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
            break;
            
        case 5:
        {
            //无限生命促销
            bool hasPurchased = manager->hasPurchasedUnlimitLife();
            if (hasPurchased) {
                return;
            }
            
            int maxLife = manager->getMaxLife();
            bool free = maxLife == 8;
            
            FMUIUnlimitLifeDiscount * window = (FMUIUnlimitLifeDiscount *) manager->getUI(kUI_UnlimitLifeDiscount);
            window->setFreeUpgread(free);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
            
        }
            break;
            
    }
    
    
#endif
}

void FMUIWorldMap::setItemPositionAtIndex(CCNode* item, int index)
{
    CCNode* parent = item->getParent();
    CCPoint mainBtnPt = CCPointZero;
    CCPoint barPt = CCPointZero;
    switch (index) {
        case 0:
        {
            //最靠近箭头的位置
            mainBtnPt = ccp(16, -19);
            barPt = ccp(-87, -21);
        }
            break;
            
        case 1:
        {
            mainBtnPt = ccp(16, -58);
            barPt = ccp(-87, -60);
        }
            break;
            
        case 2:
        {
            mainBtnPt = ccp(16, -97);
            barPt = ccp(-87, -98);
        }
            break;
            
        default:
            break;
    }
    
    item->setPosition(barPt);
    CCControlButton* barBtn = (CCControlButton* )parent->getChildByTag(item->getTag() /10);
    barBtn->setPosition(barPt);
    barBtn->setTouchEnabled(true);
    barBtn->setEnabled(true);
    CCControlButton* mainBtn = (CCControlButton* )parent->getChildByTag(item->getTag() / 100);
    mainBtn->setPosition(mainBtnPt);
    mainBtn->setTouchEnabled(true);
    mainBtn->setEnabled(true);
}



void FMUIWorldMap::clickMenuButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    FMDataManager * manager = FMDataManager::sharedManager();
    switch (button->getTag()) {
        case 0:
        {
            //gift
#ifdef BRANCH_CN
            SNSFunction_showFreeGemsOffer();
#else
            OBJCHelper::helper()->showTinyMobiOffer();
#endif
        }
            break;
        case 1:
        case 7:
        {
#ifdef BRANCH_CN
            if (button->getTag() == 7 && manager->hasPurchasedUnlimitLife() ) {
                return;
            }
            
            //weixin
            m_isExpand = !m_isExpand;
//            setButtonListEnabled(false);
            bool isFirstTimeRewarded = SNSFunction_isWeixinConnected();    //need to change
            bool isDailyFriendRewarded5Times = SNSFunction_getWeixinInviteCount() >= 5;
            bool isDailyCircleRewarded = SNSFunction_getWeixinPublishNoteStatus() == 1;
            CCBAnimationManager * anim = (CCBAnimationManager *)m_wxNode->getUserObject();
            const char * key = manager->getLocalizedString("V110_SHAREREWARD");

            if (m_isExpand) {
                if (manager->hasPurchasedUnlimitLife())
                    anim->runAnimationsForSequenceNamed("OnNoLife");
                else
                    anim->runAnimationsForSequenceNamed("On");

                bool visible = !(isDailyFriendRewarded5Times && isDailyCircleRewarded && isFirstTimeRewarded);

                m_rewardAnim->releaseControl("Label", kProperty_StringValue);
                CCLabelBMFont* label = (CCLabelBMFont*)m_rewardAnim->getNodeByName("Label");
                const char* str;
                if (!isFirstTimeRewarded) {
//                    label->setWidth(m_widthForThreeCN);

                    str = CCString::createWithFormat(key, 30)->getCString();
//                    label->setString(str);
//                    if (visible) {
//                        m_rewardAnim->playAnimation("GreenOut", 0, false, true);
//                    }
                }else{
//                    label->setWidth(m_widthForTwoCN);

                    str = CCString::createWithFormat(key, 1)->getCString();
//                    if (visible) {
//                        m_rewardAnim->playAnimation("BlueOut", 0, false, true);
//                    }
                }
//                m_rewardAnim->setVisible(visible);
                m_rewardAnim->playAnimation("PurOut", 0, false, true);
                
                visible = !isDailyCircleRewarded;
                m_friendsAnim->releaseControl("Label", kProperty_StringValue);
                label = (CCLabelBMFont*)m_friendsAnim->getNodeByName("Label");
                label->setString(str);
                if (visible) {
                    m_friendsAnim->playAnimation("GreenIn", 0, false, true);
                }
                m_friendsAnim->setVisible(visible);

                visible = !isDailyFriendRewarded5Times;
                if (visible) {
                    m_dailyAnim->playAnimation("BlueIn", 0, false, true);
                }
                m_dailyAnim->setVisible(visible);
                
                m_inviteAnim->playAnimation("PurIn", 0, false, true);
            }
            else {
                anim->runAnimationsForSequenceNamed("Off");
                                
                bool visible = !(isDailyFriendRewarded5Times && isDailyCircleRewarded && isFirstTimeRewarded);
                
                m_rewardAnim->releaseControl("Label", kProperty_StringValue);
                CCLabelBMFont* label = (CCLabelBMFont*)m_rewardAnim->getNodeByName("Label");
//                if (!isFirstTimeRewarded) {
//                    label->setWidth(m_widthForThreeCN);
//                    const char* str = CCString::createWithFormat(key, 30)->getCString();
//                    label->setString(str);
//                    if (visible) {
//                        m_rewardAnim->playAnimation("GreenIn", 0, false, true);
//                    }
//                }else{
//                    label->setWidth(m_widthForTwoCN);
//
//                    if (visible) {
//                        m_rewardAnim->playAnimation("BlueIn", 0, false, true);
//                    }
//                }
//                m_rewardAnim->setVisible(visible);
                m_rewardAnim->playAnimation("PurIn", 0, false, true);
                
                if (m_friendsAnim->isVisible()) {
                    m_friendsAnim->playAnimation("GreenOut", 0, false, true);
                }
                if (m_dailyAnim->isVisible()) {
                    m_dailyAnim->playAnimation("BlueOut", 0, false, true);
                }
                m_inviteAnim->playAnimation("PurOut", 0, false, true);
            }
#else

            //facebook
            if (!SNSFunction_isFacebookConnected()) {
                OBJCHelper::helper()->connectToFacebook(NULL);
            }else{
                OBJCHelper::helper()->inviteFBFriends();
            }
#endif
        }
            break;
        case 2:
        {
//            CCTextureCache::sharedTextureCache()->dumpCachedTextureInfo();
            FMUIConfig * window = (FMUIConfig *)manager->getUI(kUI_Config);
            window->setClassState(1);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
            break;
        case 3:
        {
            //share to friend
            CCLOG("share to friend clicked");
            SNSFunction_weixinInviteFriends();
        }
            break;
        case 4:
        {
            //share to friend circle
            CCLOG("share to friend circle clicked");
            SNSFunction_weixinPublishNote();
        }
            break;
        case 5:
        {
            if (manager->getUserName()) {
                FMUIInvite * window = (FMUIInvite *)manager->getUI(kUI_Invite);
                window->setClassState(1);
                GAMEUI_Scene::uiSystem()->nextWindow(window);
            }else{
                FMUIInputName * dialog = (FMUIInputName *)FMDataManager::sharedManager()->getUI(kUI_InputName);
                dialog->setIsRename(false);
                GAMEUI_Scene::uiSystem()->addDialog(dialog);
            }
        }
            break;
        case 6:
        {
            FMUISpin * window = (FMUISpin *)FMDataManager::sharedManager()->getUI(kUI_Spin);
            window->setClassState(1);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
            break;
        case 10:
        {
            FMMainScene *pScene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
            FMWorldMapNode * worldmap = (FMWorldMapNode *)pScene->getNode(kWorldMapNode);
            worldmap->showFamilyTree();

//            FMUIFamilyTree * window = (FMUIFamilyTree* )FMDataManager::sharedManager()->getUI(kUI_FamilyTree);
//            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
            break;
        default:
            break;
    }

}

void FMUIWorldMap::setButtonListEnabled(bool enable)
{
//    NEAnimNode * shareNode = (NEAnimNode *)m_rewardParent->getChildByTag(1);
//     
//    CCControlButton * button1 = (CCControlButton *)shareNode->getNodeByName("Button1")->getChildByTag(3);
//    button1->setEnabled(enable);
//
//    CCControlButton * button2 = (CCControlButton *)shareNode->getNodeByName("Button2")->getChildByTag(4);
//    button2->setEnabled(enable);
}

void FMUIWorldMap::updateUI(bool showFacebook)
{
    CCBAnimationManager * anim = (CCBAnimationManager *)m_parentNode->getUserObject();
    FMDataManager* manager = FMDataManager::sharedManager();
    int wi = manager->getWorldIndex();
    int li = manager->getLevelIndex();
    bool quest = manager->isQuest();
    bool branch = manager->isBranch();
    manager->setLevel(0, 0, true);
    bool showBook = manager->isWorldBeaten(true);
    manager->setLevel(wi, li, quest, branch);
#ifdef BRANCH_CN
    if (showBook) {
        anim->runAnimationsForSequenceNamed("CN1");
    }
    else {
        anim->runAnimationsForSequenceNamed("CN2");
    }

    CCBAnimationManager * wxanim = (CCBAnimationManager *)m_wxNode->getUserObject();
    wxanim->runAnimationsForSequenceNamed("Default");
    m_isExpand = false;
    
    CCBAnimationManager * bonusAni = (CCBAnimationManager *)m_bonusNode->getUserObject();
    bonusAni->runAnimationsForSequenceNamed("Default");
    m_isBonusExpand = false;
    updateBonusNodeLightAnim();
    
//    setButtonListEnabled(m_isExpand);
    bool isFirstTimeRewarded = SNSFunction_isWeixinConnected();
    bool isDailyFriendRewarded5Times = SNSFunction_getWeixinInviteCount() >= 5;
    bool isDailyCircleRewarded = SNSFunction_getWeixinPublishNoteStatus() == 1;
    
    bool visible = !(isDailyFriendRewarded5Times && isDailyCircleRewarded && isFirstTimeRewarded);
    
    
    const char* str;
    const char * key = manager->getLocalizedString("V110_SHAREREWARD");

    CCLabelBMFont* label = (CCLabelBMFont*)m_rewardAnim->getNodeByName("Label");
//    m_rewardAnim->releaseControl("Label", kProperty_StringValue);
    if (!isFirstTimeRewarded) {
//        label->setWidth(m_widthForThreeCN);
        str = CCString::createWithFormat(key, 30)->getCString();
//        label->setString(str);
//        m_rewardAnim->playAnimation("GreenInit", 0, false, true);
    }else{
//        label->setWidth(m_widthForTwoCN);
//        str = manager->getLocalizedString("V110_DAILYREWARD");
//        label->setString(str);
        str = CCString::createWithFormat(key, 1)->getCString();
//        m_rewardAnim->playAnimation("BlueInit", 0, false, true);
    }
//    m_rewardAnim->setVisible(visible);
    m_rewardAnim->playAnimation("PurInit", 0, false, true);
    
    m_dailyAnim->playAnimation("BlueOut", 0, false, true);
    
    m_friendsAnim->releaseControl("Label", kProperty_StringValue);
    label = (CCLabelBMFont*)m_friendsAnim->getNodeByName("Label");
    label->setString(str);
    m_friendsAnim->playAnimation("GreenOut", 0, false, true);
    
    m_inviteAnim->playAnimation("PurOut", 0, false, true);
#else
    if (showBook) {
        anim->runAnimationsForSequenceNamed("EN1");
    }
    else {
        anim->runAnimationsForSequenceNamed("EN2");
    }

    updateFacebook(showFacebook);
    m_spinButton->setVisible(OBJCHelper::helper()->showMinigame());
#endif
}

void FMUIWorldMap::updateFacebook(bool showFacebook)
{
#ifdef BRANCH_CN
#else
    bool isConnect = SNSFunction_isFacebookConnected();
    if (isConnect || !showFacebook) {
        m_facebookButton->getAnimNode()->useSkin("FBInvite");
        m_facebookButton->getAnimNode()->playAnimation("ReleaseIdle");
        m_rewardAnim->setVisible(false);
    }
    else {
        m_facebookButton->getAnimNode()->useSkin("Facebook");
        m_facebookButton->getAnimNode()->playAnimation("ReleaseIdle");
        bool isFacebookRewarded = SNSFunction_ifGotFacebookConnectPrize();
        m_rewardAnim->setVisible(!isFacebookRewarded);
    }
#endif
}

void FMUIWorldMap::show(bool isShown)
{
    if (m_isShown == isShown) {
        //do nothing
        return;
    }
    m_isShown = isShown;
    updateUI();
    if (m_isShown) {
        CCBAnimationManager * manager = (CCBAnimationManager *)m_ccbNode->getUserObject();
        manager->runAnimationsForSequenceNamed("SlideIn");
    }
    else {
        CCBAnimationManager * manager = (CCBAnimationManager *)m_ccbNode->getUserObject();
        manager->runAnimationsForSequenceNamed("SlideOut");
    }
}

bool FMUIWorldMap::ccTouchBegan(cocos2d::CCTouch *pTouch, cocos2d::CCEvent *pEvent)
{
    shrinkPopBar();
    CCSprite * bg = (CCSprite *)m_parentNode->getParent();
    CCSize size = bg->getContentSize();
    CCPoint p = pTouch->getLocation();
    p = bg->convertToNodeSpace(p);
    if (p.x >=0.f && p.y >= 0.f && p.x <= size.width && p.y <= size.height) {
        return true;
    }
    return false;
}

void FMUIWorldMap::resetBookBtn()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    bool haveNew = manager->haveNewBranchLevel();
    if (!m_bookBtn) {
        return;
    }
    NEAnimNode* bn = m_bookBtn->getAnimNode();
    bn->releaseControl("New", kProperty_Visible);
    NEAnimNode* n = (NEAnimNode*)bn->getNodeByName("New");
    if (manager->haveNewJelly()) {
        n->setVisible(true);
    }else{
        n->setVisible(false);
    }
    
    int wi = manager->getWorldIndex();
    int li = manager->getLevelIndex();
    bool q = manager->isQuest();
    bool b = manager->isBranch();
    manager->setLevel(0, 0, true);
    bool beaten = manager->isWorldBeaten(true);
//    bool visible = beaten && !manager->isInGame();
//    bookBtn->setVisible(visible);
//    bookBtn->setEnabled(visible);
    manager->setLevel(wi, li, q, b);
    
    if (haveNew && beaten) {
        m_hasNewQuest = true;
    }
}

CCPoint FMUIWorldMap::getTutorialPosition(int index)
{
    CCPoint p = m_bookBtn->getPosition();
    
    CCSize s = CCDirector::sharedDirector()->getWinSize();
    p.x += s.width * 0.5f;
//    p.y += s.height;
    return p;
}


bool FMUIWorldMap::whetherShowBonusNode()
{
#ifndef BRANCH_CN
    return false;
#endif
    FMDataManager* manager = FMDataManager::sharedManager();
    bool unlimitLife = manager->whetherUnsealUnlimitLifeDiscount();
    bool goldIapBonus = manager->whetherUnsealIapBouns();
    bool starBonus = manager->whetherUnsealStarBonus();
    bool whetherShow = unlimitLife || goldIapBonus || starBonus;
    
    return whetherShow;
}

void FMUIWorldMap::updateBonusNodeLightAnim()
{
    //是否显示光圈,当只剩下星星领奖时,达到领奖条件则显示,反之不显示
    CCNode* lightNode = m_bonusNode->getChildByTag(0);
    FMDataManager* manager = FMDataManager::sharedManager();
    
    if (!m_bonusNode->isVisible()) {
        lightNode->setVisible(false);
        return;
    }
    
    bool canGetStarRwd = FMDataManager::sharedManager()->whetherCanGetStarReward();
    bool showLight = canGetStarRwd || manager->whetherUnsealUnlimitLifeDiscount() || manager->whetherUnsealIapBouns();
    lightNode->setVisible(showLight);
}


void FMUIWorldMap::shrinkPopBar()
{
    if (m_isExpand) {
        m_isExpand = false;
        CCBAnimationManager * anim = (CCBAnimationManager *)m_wxNode->getUserObject();
        anim->runAnimationsForSequenceNamed("Off");
        m_rewardAnim->releaseControl("Label", kProperty_StringValue);
        m_rewardAnim->playAnimation("PurIn", 0, false, true);
        if (m_friendsAnim->isVisible()) {
            m_friendsAnim->playAnimation("GreenOut", 0, false, true);
        }
        if (m_dailyAnim->isVisible()) {
            m_dailyAnim->playAnimation("BlueOut", 0, false, true);
        }
        m_inviteAnim->playAnimation("PurOut", 0, false, true);
    }
    
    if (m_isBonusExpand) {
        m_isBonusExpand = false;
        if (!m_bonusNode->isVisible())return;
        CCBAnimationManager * anim = (CCBAnimationManager *)m_bonusNode->getUserObject();
        anim->runAnimationsForSequenceNamed("Off");
        
        if (m_unlimitLifeAnim->isVisible()) {
            m_unlimitLifeAnim->playAnimation("PurOut", 0, false, true);
        }
        if (m_iapGoldBonusAni->isVisible()) {
            m_iapGoldBonusAni->playAnimation("GreenOut", 0, false, true);
        }
        m_starRewardAni->playAnimation("BlueOut", 0, false, true);
    }
    updateBonusNodeLightAnim();
}

void FMUIWorldMap::keyBackClicked(void)
{
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
    
    if(FMDataManager::sharedManager()->isTutorialRunning()){
        FMDataManager::sharedManager()->tutorialSkip();
        return;
    }
    
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() != NULL )
        return;
    
    OBJCHelper::helper()->keyBackClickedInRootLayer();
    
#endif
}
