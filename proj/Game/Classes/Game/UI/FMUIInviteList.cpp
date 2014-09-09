//
//  FMUIInviteList.cpp
//  JellyMania
//
//  Created by lipeng on 14-4-8.
//
//

#include "FMUIInviteList.h"
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

FMUIInviteList::FMUIInviteList():
m_instantMove(false),
m_inviteLabel(NULL),
m_tipLabel(NULL),
m_list(NULL),
m_parentNode(NULL)
{
    m_list = CCArray::create();
    m_list->retain();
    
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIMyInvite.ccbi", this);
    addChild(m_ccbNode);
    
    CCSize winSize = CCSize(250, 225);
    CCSize cullingSize = CCSize(500, 235);
    GUIScrollSlider * slider = new GUIScrollSlider(winSize, CCRect(-cullingSize.width * 0.5f, -cullingSize.height * 0.5f + 5.f, cullingSize.width, cullingSize.height), 50.f, this, true);
    slider->setPosition(ccp(0.f, 5.f));
    m_slider = slider;
    m_parentNode->addChild(slider, 10);
    
    m_tipLabel->setWidth(200);
    m_tipLabel->setAlignment(kCCTextAlignmentCenter);
    m_tipLabel->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
}

FMUIInviteList::~FMUIInviteList()
{
    m_list->release();
}

#pragma mark - CCB Bindings
bool FMUIInviteList::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_parentNode", CCNode *, m_parentNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_inviteLabel", CCLabelBMFont *, m_inviteLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_tipLabel", CCLabelBMFont *, m_tipLabel);
    return true;
}

SEL_CCControlHandler FMUIInviteList::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIInviteList::clickButton);
    return NULL;
}

void FMUIInviteList::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIInviteList::clickButton(cocos2d::CCObject *object, CCControlEvent event)
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
        default:
            break;
    }
}

void FMUIInviteList::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIInviteList::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUIInviteList::onEnter()
{
    GAMEUI_Window::onEnter();
    updateUI();
}

void FMUIInviteList::updateUI()
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
//    for (int i = 0; i < 10; i++) {
//        CCDictionary * dic = CCDictionary::create();
//        dic->setObject(CCNumber::create(manager->getRandom()%6), "icon");
//        dic->setObject(CCString::createWithFormat("test%d测试",i), "name");
//        m_list->addObject(dic);
//    }
    CCString * str = CCString::createWithFormat(manager->getLocalizedString("V140_ALLREADY_INVITE_(D)"),m_list->count());
    m_inviteLabel->setString(str->getCString());
    
    m_slider->refresh();
}

#pragma mark - slider delegate
CCNode * FMUIInviteList::createItemForSlider(GUIScrollSlider *slider)
{
    CCNode * node = FMDataManager::sharedManager()->createNode("UI/FMUIMyInviteItem.ccbi", this);
    return node;
}

int FMUIInviteList::itemsCountForSlider(GUIScrollSlider *slider)
{
    return m_list->count();
}

void FMUIInviteList::sliderUpdate(GUIScrollSlider *slider, int rowIndex, cocos2d::CCNode *node)
{
    CCDictionary * frd = (CCDictionary *)m_list->objectAtIndex(rowIndex);
    CCNumber * iconid = (CCNumber *)frd->objectForKey("icon");
    CCString * name = (CCString *)frd->objectForKey("name");
    CCNode * pNode = node->getChildByTag(0)->getChildByTag(0);
    if (iconid && name) {
        int iconint = iconid->getIntValue()-1;
        if (iconint > 5 || iconint < 0) {
            iconint = 0;
        }
        CCString * iconname = CCString::createWithFormat("touxiang-%02d.png",iconint);
        CCSprite * icon = (CCSprite*)pNode->getChildByTag(0);
        CCSpriteFrame * frame = CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(iconname->getCString());
        icon->setDisplayFrame(frame);

        CCLabelTTF * label = (CCLabelTTF *)pNode->getChildByTag(1);
        label->setString(name->getCString());
    }
}

