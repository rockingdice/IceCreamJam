//
//  FMUISpin.cpp
//  JellyMania
//
//  Created by lipeng on 14-4-20.
//
//

#include "FMUISpin.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "OBJCHelper.h"
#include "SNSFunction.h"
#include "FMUIWorldMap.h"
#include "FMUIRestore.h"
#include "FMUIConfig.h"
#include "FMStatusbar.h"
#include "FMUIBuySpin.h"
#include "FMUIPrizeList.h"
#include "FMUISpinReward.h"

#ifdef BRANCH_CN
static int kBuyMoreSpin = 12;
#else
static int kBuyMoreSpin = 6;
#endif

static float kBallStartY = 41.f;
static float kBarStartY = 14.f;
static float kBallEndY = -26.f;
static float kBarEndY = -13.f;
static float kBarMidY = -2.f;
static float kBarMidScaleY = 0.8f;
static float kBarEndScaleY = 1.2f;
static float kBallBackSpd = 400.f;

FMUISpin::FMUISpin():
m_instantMove(false),
m_parentNode(NULL),
m_list(NULL),
m_tiers(NULL),
m_timesLabel(NULL),
m_moreSpinBtn(NULL),
m_lever(NULL),
m_leverBar(NULL),
m_leverBall(NULL),
m_isSpin(false),
m_isLeverTouch(false),
m_titleLabel(NULL),
m_spinGuide(NULL)
{
    m_list = CCArray::create();
    m_list->retain();
    
    m_tiers = CCArray::create();
    m_tiers->retain();
    
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUISpin.ccbi", this);
    addChild(m_ccbNode);
    
    CCSize cullingSize = CCSize(78, 180);
    GUISpinView * spin = new GUISpinView(CCRect(-cullingSize.width * 0.5f, -cullingSize.height * 0.5f + 5.f, cullingSize.width, cullingSize.height), 42.f, this);
    spin->setPosition(ccp(0.f, -5.f));
    m_spinView = spin;
    m_parentNode->addChild(m_spinView, 10);
    
    CCNode * node = m_parentNode->getChildByTag(1);
    node->setZOrder(100);
}

FMUISpin::~FMUISpin()
{
    m_list->release();
    m_tiers->release();
}

#pragma mark - CCB Bindings
bool FMUISpin::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_timesLabel", CCLabelBMFont *, m_timesLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_moreSpinBtn", CCAnimButton *, m_moreSpinBtn);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_lever", CCSprite *, m_lever);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_leverBar", CCSprite *, m_leverBar);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_leverBall", CCSprite *, m_leverBall);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_titleLabel", CCLabelBMFont *, m_titleLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_spinGuide", NEAnimNode *, m_spinGuide);
    return true;
}

SEL_CCControlHandler FMUISpin::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUISpin::clickButton);
    return NULL;
}

void FMUISpin::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        //close
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUISpin::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    if (m_isSpin) {
        return;
    }

    CCControlButton * button = (CCControlButton *)object;
    int tag = button->getTag();
    FMDataManager * manager = FMDataManager::sharedManager();
    switch (tag) {
        case 0:
        {
            //close
            m_instantMove = false;
            GAMEUI_Scene::uiSystem()->prevWindow();
        }
            break;
        case 1:
        {
            //morespin
            if (manager->useMoney(kBuyMoreSpin, "Spin")) {
                manager->addSpinTimes();
                updateUI();
            }
        }
            break;
        case 2:
        {
            //prize list
            FMUIPrizeList * window = (FMUIPrizeList *)manager->getUI(kUI_PrizeList);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
            break;
        case 3:
        {
            //spin
            /*
            if (manager->getSpinTimes() <= 0) {
                FMUIBuySpin * window = (FMUIBuySpin *)manager->getUI(kUI_BuySpin);
                GAMEUI_Scene::uiSystem()->nextWindow(window);
                return;
            }
            m_isSpin = true;
            m_lever->playAnimation("Animation1");
            int index = getSpinResult();
            m_spinView->scrollTo(index);
            
            manager->useSpinTimes();
            updateUI();
             */
        }
            break;
        default:
            break;
    }
}

void FMUISpin::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUISpin::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUISpin::onEnter()
{
    GAMEUI_Window::onEnter();
    m_isLeverTouch = false;
    m_isSpin = false;
    FMDataManager * manager = FMDataManager::sharedManager();
    m_spinGuide->setVisible(manager->getSpinCount() == 0);
    m_list->removeAllObjects();
    m_tiers->removeAllObjects();
    m_tiers->addObjectsFromArray(manager->getSpinPrizes());
    
    CCArray * t = (CCArray *)m_tiers->objectAtIndex(0);
    for (int i = 0; i < t->count(); i++) {
        CCArray * t2 = (CCArray *)m_tiers->objectAtIndex(3);
        if (t2->count() > i) {
            m_list->addObject(t2->objectAtIndex(i));
        }
        
        t2 = (CCArray *)m_tiers->objectAtIndex(2);
        if (t2->count() > i) {
            m_list->addObject(t2->objectAtIndex(i));
        }

        t2 = (CCArray *)m_tiers->objectAtIndex(1);
        if (t2->count() > i) {
            m_list->addObject(t2->objectAtIndex(i));
        }

        m_list->addObject(t->objectAtIndex(i));
    }
    
    m_spinView->refresh();

    updateUI();
    
#ifdef BRANCH_TH
    m_titleLabel->setScale(0.75f);
    m_titleLabel->setPosition(ccp(5, -16));
    m_timesLabel->setScale(0.7f);
#endif
}

void FMUISpin::updateUI()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    NEAnimNode * node = m_moreSpinBtn->getAnimNode();
    node->releaseControl("Label", kProperty_StringValue);
    CCLabelBMFont * label = (CCLabelBMFont *)node->getNodeByName("Label");
    label->setString(CCString::createWithFormat(manager->getLocalizedString("V140_MORESPIN_(D)"), kBuyMoreSpin)->getCString());
    
    m_timesLabel->setString(CCString::createWithFormat(manager->getLocalizedString("V140_SPINTIMES_(D)"), manager->getSpinTimes())->getCString());
    
}

#pragma mark - slider delegate
CCNode * FMUISpin::createItemForSpinView(GUISpinView *slider, int rowIndex)
{
    CCNode * node = FMDataManager::sharedManager()->createNode("UI/FMUISpinItem.ccbi", this);
    CCArray * dic = (CCArray *)m_list->objectAtIndex(rowIndex);
    CCNumber * type = (CCNumber *)dic->objectAtIndex(0);
    CCNumber * amount = (CCNumber *)dic->objectAtIndex(1);
    CCNode * pNode = node->getChildByTag(0);
    CCNode * animNode = pNode->getChildByTag(0);
    CCSprite * picNode = (CCSprite *)pNode->getChildByTag(1);
    CCLabelBMFont * label = (CCLabelBMFont *)pNode->getChildByTag(2);
    label->setString(CCString::createWithFormat("x%d",amount->getIntValue())->getCString());
    if (type->getIntValue() == kBooster_FreeSpin) {
        animNode->setVisible(false);
        picNode->setScale(1.f);
        picNode->setVisible(true);
        
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("FreeSpin.png");
        picNode->setDisplayFrame(frame);
    }
    else if (type->getIntValue() == kBooster_UnlimitLife){
        animNode->setVisible(false);
        picNode->setScale(1.f);
        picNode->setVisible(true);
        
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("unlimit_life_icon.png");
        picNode->setDisplayFrame(frame);
        label->setString(CCString::createWithFormat("%d h",amount->getIntValue())->getCString());

    }
    else if (type->getIntValue() == kBooster_Gold){
        animNode->setVisible(false);
        picNode->setScale(0.8f);
        picNode->setVisible(true);
        
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_gold1.png");
        picNode->setDisplayFrame(frame);
    }
    else if (type->getIntValue() == kBooster_Life){
        animNode->setVisible(false);
        picNode->setScale(1.2f);
        picNode->setVisible(true);
        
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName("ui_life0.png");
        picNode->setDisplayFrame(frame);
    }
    else{
        const char * skin = FMGameNode::getBoosterSkin((kGameBooster)type->getIntValue());
        NEAnimNode * n = (NEAnimNode *)animNode;
        n->useSkin(skin);
        animNode->setVisible(true);
        picNode->setVisible(false);
        animNode->setScale(0.8f);
    }

    return node;
}

int FMUISpin::itemsCountForSpinView(GUISpinView *slider)
{
    return m_list->count();
}

void FMUISpin::spinFinished(int index)
{
    m_isSpin = false;
    FMDataManager * manager = FMDataManager::sharedManager();
    CCArray * dic = (CCArray *)m_list->objectAtIndex(index);
    CCNumber * type = (CCNumber *)dic->objectAtIndex(0);
    CCNumber * amount = (CCNumber *)dic->objectAtIndex(1);
    if (type->getIntValue() == kBooster_Gold) {
        manager->setGoldNum(manager->getGoldNum() + amount->getIntValue());
    }else if (type->getIntValue() == kBooster_FreeSpin){
        int t = amount->getIntValue();
        while (t > 0) {
            t--;
            manager->addSpinTimes();
        }
    }
    else if (type->getIntValue() == kBooster_UnlimitLife){
        int t = amount->getIntValue();
        manager->setUnlimitLifeTime(MAX(manager->getCurrentTime(), manager->getUnlimitLifeTime()) + t * 3600);
    }
    else if (type->getIntValue() == kBooster_Life){
        manager->setLifeNum(manager->getLifeNum()+amount->getIntValue());
        manager->updateStatusBar();
    }
    else{
        manager->setBoosterAmount(type->getIntValue(), MAX(manager->getBoosterAmount(type->getIntValue()), 0) + amount->getIntValue());
    }

    updateUI();
    
    FMUISpinReward * window = (FMUISpinReward *)manager->getUI(kUI_SpinReward);
    window->setReward(dic);
    GAMEUI_Scene::uiSystem()->addDialog(window);
}
int FMUISpin::getSpinResult()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    int count = manager->getSpinCount();
    int r = 0;
    switch (count) {
//        case 0:
//        case 2:
//        {
//            for (int i = 0; i < m_list->count(); i++) {
//                CCDictionary * dic = (CCDictionary *)m_list->objectAtIndex(i);
//                CCNumber * type = (CCNumber *)dic->objectForKey("type");
//                if (type->getIntValue() == kBooster_FreeSpin) {
//                    r = i;
//                    break;
//                }
//            }
//        }
//            break;
//        case 1:
//        {
//            if (manager->hasPurchasedUnlimitLife()) {
//                manager->setSpinCount(count + 1);
//                return getSpinResult();
//            }
//            for (int i = 0; i < m_list->count(); i++) {
//                CCDictionary * dic = (CCDictionary *)m_list->objectAtIndex(i);
//                CCNumber * type = (CCNumber *)dic->objectForKey("type");
//                CCNumber * amount = (CCNumber *)dic->objectForKey("amount");
//                if (type->getIntValue() == kBooster_UnlimitLife && amount->getIntValue() == 1) {
//                    r = i;
//                    break;
//                }
//            }
//        }
//            break;
//        case 3:
//        {
//            for (int i = 0; i < m_list->count(); i++) {
//                CCDictionary * dic = (CCDictionary *)m_list->objectAtIndex(i);
//                CCNumber * type = (CCNumber *)dic->objectForKey("type");
//                CCNumber * amount = (CCNumber *)dic->objectForKey("amount");
//                if (type->getIntValue() == kBooster_Gold && amount->getIntValue() == 10) {
//                    r = i;
//                    break;
//                }
//            }
//        }
//            break;
        default:
        {
            int rand = manager->getRandom()%10000;
#ifdef DEBUG
            CCLog("1/4 rand is : %d", rand);
#endif
            CCArray * t = CCArray::create();
            if (rand < 5) {
                t = (CCArray *)m_tiers->objectAtIndex(3);
            }
            else if (rand < 200){
                t = (CCArray *)m_tiers->objectAtIndex(2);
            }
            else if (rand < 1700){
                t = (CCArray *)m_tiers->objectAtIndex(1);
            }
            else{
                t = (CCArray *)m_tiers->objectAtIndex(0);
            }
            
            rand = manager->getRandom()%t->count();
#ifdef DEBUG
            CCLog("array rand is : %d", rand);
#endif
            CCArray * a = (CCArray *)t->objectAtIndex(rand);
            int type = ((CCNumber *)a->objectAtIndex(0))->getIntValue();
            int number = ((CCNumber *)a->objectAtIndex(1))->getIntValue();
//            
//            if (type == kBooster_Life) {
//                int life = manager->getLifeNum();
//                int max = manager->getMaxLife();
//                if (max-life < number) {
//                    return getSpinResult();
//                }
//            }
            
            for (int i = 0; i < m_list->count(); i++) {
                CCArray * dic = (CCArray *)m_list->objectAtIndex(i);
                CCNumber * tt = (CCNumber *)dic->objectAtIndex(0);
                CCNumber * tn = (CCNumber *)dic->objectAtIndex(1);
                if (type == tt->getIntValue() && number == tn->getIntValue()) {
                    r = i;
                    break;
                }
            }
        }
            break;
    }
    return r;
}

bool FMUISpin::ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent)
{
    if (m_isLeverTouch || m_isSpin) {
        return true;
    }
    CCPoint touchP = m_lever->getParent()->convertTouchToNodeSpace(pTouch);
    CCRect rect = m_lever->boundingBox();
    if (rect.containsPoint(touchP)) {
        m_isLeverTouch = true;
        m_touchStartY = touchP.y;
    }
    
    return true;
}
void FMUISpin::ccTouchMoved(CCTouch *pTouch, CCEvent *pEvent)
{
    if (!m_isLeverTouch || m_isSpin) {
        return;
    }
    CCPoint touchP = m_lever->getParent()->convertTouchToNodeSpace(pTouch);
    float deltaY = m_touchStartY - touchP.y;
    if (deltaY < 0) {
        deltaY = 0;
    }
    if (deltaY > kBallStartY - kBallEndY) {
        deltaY = kBallStartY - kBallEndY;
    }
    
    CCPoint ballp = m_leverBall->getPosition();
    ballp.y = kBallStartY-deltaY;
    m_leverBall->setPosition(ballp);
    
    float kbar = (kBarStartY - kBarEndY) / (kBallStartY - kBallEndY);
    CCPoint barp = m_leverBar->getPosition();
    barp.y = kBarStartY - deltaY*kbar;
    m_leverBar->setPosition(barp);
    
    if (barp.y >= kBarMidY) {
        m_leverBar->setRotation(0.f);
        float scale = 1.f - (kBarStartY - barp.y) / (kBarStartY - kBarMidY) * (1.f-kBarMidScaleY);
        if (scale > 1.f) {
            scale = 1.f;
        }
        if (scale < kBarMidScaleY) {
            scale = kBarMidScaleY;
        }
        m_leverBar->setScaleY(scale);
    }else{
        m_spinGuide->setVisible(false);
        m_leverBar->setRotation(180.f);
        float scale = kBarMidScaleY + (kBarMidY - barp.y)/(kBarMidY - kBarEndY) * (kBarEndScaleY - kBarMidScaleY);
        if (scale < kBarMidScaleY) {
            scale = kBarMidScaleY;
        }
        if (scale > kBarEndScaleY) {
            scale = kBarEndScaleY;
        }
        m_leverBar->setScaleY(scale);
    }
}
void FMUISpin::ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent)
{
    if (!m_isLeverTouch || m_isSpin) {
        return;
    }
    CCPoint barp = m_leverBar->getPosition();
    CCPoint ballp = m_leverBall->getPosition();
    float time = (kBallStartY-ballp.y)/kBallBackSpd;
    CCMoveTo * move = CCMoveTo::create(time, ccp(ballp.x, kBallStartY));
    CCCallFunc * call = CCCallFunc::create(this, callfunc_selector(FMUISpin::leverCallBack));
    m_leverBall->runAction(CCSequence::create(move, call, NULL));
    if (barp.y >= kBarMidY) {
        CCMoveTo * move = CCMoveTo::create(time, ccp(barp.x, kBarStartY));
        CCScaleTo * scale = CCScaleTo::create(time, 1.f);
        m_leverBar->runAction(CCSpawn::create(move,scale,NULL));
    }else{
        CCMoveTo * move = CCMoveTo::create(time, ccp(barp.x, kBarStartY));
        CCScaleTo * scale = CCScaleTo::create(time * (kBarMidY - barp.y)/(kBarStartY - barp.y), 1.f, kBarMidScaleY);
        CCRotateTo * rotate = CCRotateTo::create(0.f, 0.f);
        CCScaleTo * scale2 = CCScaleTo::create(time * (kBarStartY - kBarMidY)/(kBarStartY - barp.y), 1.f, 1.f);
        CCSequence * seq = CCSequence::create(scale,rotate,scale2,NULL);
        m_leverBar->runAction(CCSpawn::create(move,seq,NULL));
        
        FMDataManager * manager = FMDataManager::sharedManager();
        if (manager->getSpinTimes() <= 0) {
            FMUIBuySpin * window = (FMUIBuySpin *)manager->getUI(kUI_BuySpin);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
            return;
        }
        m_isSpin = true;
        int index = getSpinResult();
        m_spinView->scrollTo(index);
        
        manager->useSpinTimes();
        updateUI();
    }
    
}
void FMUISpin::ccTouchCancelled(CCTouch *pTouch, CCEvent *pEvent)
{
    if (!m_isLeverTouch || m_isSpin) {
        return;
    }
    CCPoint barp = m_leverBar->getPosition();
    CCPoint ballp = m_leverBall->getPosition();
    float time = (kBallStartY-ballp.y)/kBallBackSpd;
    CCMoveTo * move = CCMoveTo::create(time, ccp(ballp.x, kBallStartY));
    CCCallFunc * call = CCCallFunc::create(this, callfunc_selector(FMUISpin::leverCallBack));
    m_leverBall->runAction(CCSequence::create(move, call, NULL));
    if (barp.y >= kBarMidY) {
        CCMoveTo * move = CCMoveTo::create(time, ccp(barp.x, kBarStartY));
        CCScaleTo * scale = CCScaleTo::create(time, 1.f);
        m_leverBar->runAction(CCSpawn::create(move,scale,NULL));
    }else{
        CCMoveTo * move = CCMoveTo::create(time, ccp(barp.x, kBarStartY));
        CCScaleTo * scale = CCScaleTo::create(time * (kBarMidY - barp.y)/(kBarStartY - barp.y), 1.f, kBarMidScaleY);
        CCRotateTo * rotate = CCRotateTo::create(0.f, 0.f);
        CCScaleTo * scale2 = CCScaleTo::create(time * (kBarStartY - kBarMidY)/(kBarStartY - barp.y), 1.f, 1.f);
        CCSequence * seq = CCSequence::create(scale,rotate,scale2,NULL);
        m_leverBar->runAction(CCSpawn::create(move,seq,NULL));
        
        FMDataManager * manager = FMDataManager::sharedManager();
        if (manager->getSpinTimes() <= 0) {
            FMUIBuySpin * window = (FMUIBuySpin *)manager->getUI(kUI_BuySpin);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
            return;
        }
        m_isSpin = true;
        int index = getSpinResult();
        m_spinView->scrollTo(index);
        
        manager->useSpinTimes();
        updateUI();
    }
}
void FMUISpin::leverCallBack()
{
    m_isLeverTouch = false;
}
