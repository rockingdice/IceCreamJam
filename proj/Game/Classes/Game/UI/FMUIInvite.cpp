//
//  FMUIInvite.cpp
//  JellyMania
//
//  Created by lipeng on 14-4-3.
//
//

#include "FMUIInvite.h"
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
#include "FMUIInviteList.h"

FMUIInvite::FMUIInvite():
m_instantMove(false),
m_inviteLabel(NULL),
m_list(NULL)
{
    m_list = CCArray::create();
    m_list->retain();

    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIInvite.ccbi", this);
    addChild(m_ccbNode);
}

FMUIInvite::~FMUIInvite()
{
    m_list->release();
}

#pragma mark - CCB Bindings
bool FMUIInvite::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_inviteLabel", CCLabelBMFont *, m_inviteLabel);
    return true;
}

SEL_CCControlHandler FMUIInvite::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIInvite::clickButton);
    return NULL;
}

void FMUIInvite::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        //close
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIInvite::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    int tag = button->getTag();
    switch (tag) {
        case 0:
        {
            //close
            m_instantMove = false;
            GAMEUI_Scene::uiSystem()->prevWindow();
        }
            break;
        case 3:
        {
            SNSFunction_weixinUnlimitLife();
        }
            break;
        case 4:
        {
            FMUIInviteList * window = (FMUIInviteList *)FMDataManager::sharedManager()->getUI(kUI_InviteList);
            window->setClassState(1);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
        }
            break;
        case 10:
        {
            int tag = button->getParent()->getParent()->getTag();
            FMDataManager * manager = FMDataManager::sharedManager();
            manager->getInviteReward(tag);
            updateUI();
        }
            break;
        default:
            break;
    }
}

void FMUIInvite::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIInvite::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUIInvite::onEnter()
{
    GAMEUI_Window::onEnter();
    OBJCHelper::helper()->postRequest(this, callfuncO_selector(FMUIInvite::onRequstFinished), kPostType_SyncFrdData);
    updateUI();
}

void FMUIInvite::updateUI()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    m_list->removeAllObjects();
    CCDictionary * frdDic = manager->getFrdMapDic();
    if (frdDic) {
        CCArray * frdlist = (CCArray *)frdDic->objectForKey("list");
        if (frdlist) {
            for (int i = 0; i < frdlist->count(); i++) {
                CCDictionary * d = (CCDictionary*)frdlist->objectAtIndex(i);
                CCNumber * frm = (CCNumber *)d->objectForKey("frm");
                if (frm && frm->getIntValue() == 1) {
                    m_list->addObject(d);
                }
            }
        }
    }
//    for (int i = 0; i < 80; i++) {
//        CCDictionary * dic = CCDictionary::create();
//        dic->setObject(CCNumber::create(manager->getRandom()%6), "icon");
//        dic->setObject(CCString::createWithFormat("test%d测试",i), "name");
//        m_list->addObject(dic);
//    }

    CCNode * pNode = m_ccbNode->getChildByTag(0)->getChildByTag(0)->getChildByTag(0);
    for (int i = 0; i < 3; i++) {
        CCNode * node = pNode->getChildByTag(i)->getChildByTag(0);
        CCLabelBMFont * label = (CCLabelBMFont *)node->getChildByTag(1);
        CCString * str = CCString::createWithFormat(manager->getLocalizedString("V140_(D)_INVITE"), manager->getInviteRewardNeedCount(i));
        label->setString(str->getCString());
        
        label = (CCLabelBMFont *)node->getChildByTag(2);
        str = CCString::createWithFormat(manager->getLocalizedString("V140_(D)_HOUR"), manager->getInviteRewardTime(i)/3600);
        label->setString(str->getCString());
        
        label = (CCLabelBMFont *)node->getChildByTag(4);
        CCControlButton * btn = (CCControlButton*)node->getChildByTag(10);
        if (m_list->count() < manager->getInviteRewardNeedCount(i)) {
            btn ->setVisible(true);
            btn ->setEnabled(false);
            label->setVisible(false);
        }else{
            if (manager->isInviteRewardUseable(i)) {
                btn->setVisible(true);
                btn->setEnabled(true);
                label->setVisible(false);
            }else{
                btn->setVisible(false);
                btn->setEnabled(false);
                label->setVisible(true);
            }
        }
    }
    CCString * str = CCString::createWithFormat(manager->getLocalizedString("V140_ALLREADY_INVITE_(D)"),m_list->count());
    m_inviteLabel->setString(str->getCString());
}

void FMUIInvite::onRequstFinished(CCDictionary * dic)
{
    updateUI();
}
