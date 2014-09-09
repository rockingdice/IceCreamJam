//
//  FMUIFriendProfile.cpp
//  JellyMania
//
//  Created by lipeng on 14-8-6.
//
//

#include "FMUIFriendProfile.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "SNSFunction.h"

FMUIFriendProfile::FMUIFriendProfile():
m_instantMove(false),
m_avatarNode(NULL),
m_levelLabel(NULL),
m_nameLabel(NULL),
m_nameLabel2(NULL),
m_sendButton(NULL),
m_starLabel(NULL),
m_fid(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIKakaoFriendPopup.ccbi", this);
    addChild(m_ccbNode);
    
//    NEAnimNode * closeNode = m_sendButton->getAnimNode();
//    closeNode->releaseControl("Label", kProperty_FNTFile);
//    closeNode->releaseControl("Label", kProperty_Position);
//    CCLabelBMFont * closelabel = (CCLabelBMFont *)closeNode->getNodeByName("Label");
//    closelabel->setFntFile("font_2.fnt");
//    closelabel->setPosition(ccp(10, closelabel->getPosition().y));
}

FMUIFriendProfile::~FMUIFriendProfile()
{
}

#pragma mark - CCB Bindings
bool FMUIFriendProfile::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_levelLabel", CCLabelBMFont *, m_levelLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_starLabel", CCLabelBMFont *, m_starLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_nameLabel", CCLabelTTF *, m_nameLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_nameLabel2", CCLabelTTF *, m_nameLabel2);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_avatarNode", CCSprite *, m_avatarNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_sendButton", CCAnimButton *, m_sendButton);
    return true;
}

SEL_CCControlHandler FMUIFriendProfile::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIFriendProfile::clickButton);
    return NULL;
}

void FMUIFriendProfile::clickButton(cocos2d::CCObject *object, CCControlEvent event)
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
        case 5:
        {
            OBJCHelper::helper()->sendLifeToFriend(m_fid->getCString());
            
            m_instantMove = false;
            GAMEUI_Scene::uiSystem()->prevWindow();
        }
            break;
        default:
            break;
    }
}

void FMUIFriendProfile::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIFriendProfile::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUIFriendProfile::onEnter()
{
    GAMEUI_Window::onEnter();
}

void FMUIFriendProfile::setProfile(CCDictionary * dic)
{
    FMDataManager * manager = FMDataManager::sharedManager();
    m_avatarNode->removeAllChildren();
    CCBAnimationManager * lifeAnim = (CCBAnimationManager *)m_ccbNode->getUserObject();
    if (dic) {
        m_fid = (CCString *)dic->objectForKey("uid");
        
        if (OBJCHelper::helper()->isFrdMsgEnable(m_fid->getCString(), 1)) {
            lifeAnim->runAnimationsForSequenceNamed("1");
        }else{
            lifeAnim->runAnimationsForSequenceNamed("2");
        }
        
        CCNumber * page = (CCNumber *)dic->objectForKey("page");
        CCNumber * level = (CCNumber *)dic->objectForKey("level");
        int currentLevel = manager->getGlobalIndex(page->getIntValue(), level->getIntValue());

        const char * iconpath = SNSFunction_getFacebookIcon(m_fid->getCString());
        
        if (iconpath && manager->isFileExist(iconpath)) {
            CCSprite * spr = CCSprite::create(iconpath);
            float size = 50.f;
            spr->setScale(size / MAX(spr->getContentSize().width, size));
            m_avatarNode->addChild(spr);
            spr->setPosition(ccp(m_avatarNode->getContentSize().width/2, m_avatarNode->getContentSize().height/2));
        }
        
        const char * name = ((CCString *)dic->objectForKey("name"))->getCString();
        m_nameLabel->setString(name);
        m_nameLabel2->setString(name);
        
        m_levelLabel->setString(CCString::createWithFormat(manager->getLocalizedString("V150_KAKAO_FURTHESTLEVEL_(D)"), currentLevel)->getCString());
        
        CCNumber * star = (CCNumber *)dic->objectForKey("stars");
        if (!star) {
            star = CCNumber::create(0);
        }
        m_starLabel->setString(CCString::createWithFormat("%d/%d", star->getIntValue(), manager->getTotalStarsNumber())->getCString());
    }else{
        lifeAnim->runAnimationsForSequenceNamed("2");
        const char * name = SNSFunction_getFacebookUsername();
        m_nameLabel->setString(name);
        m_nameLabel2->setString(name);
        
        const char * uid = SNSFunction_getFacebookUid();
        const char * iconpath = SNSFunction_getFacebookIcon(uid);
        if (iconpath && manager->isFileExist(iconpath)) {
            CCSprite * spr = CCSprite::create(iconpath);
            float size = 50.f;
            spr->setScale(size / MAX(spr->getContentSize().width, size));
            m_avatarNode->addChild(spr);
            spr->setPosition(ccp(m_avatarNode->getContentSize().width/2, m_avatarNode->getContentSize().height/2));
        }
        
        int flevel = manager->getGlobalIndex(manager->getFurthestWorld(), manager->getFurthestLevel());
        m_levelLabel->setString(CCString::createWithFormat(manager->getLocalizedString("V150_KAKAO_FURTHESTLEVEL_(D)"), flevel)->getCString());
        
        m_starLabel->setString(CCString::createWithFormat("%d/%d", manager->getAllStarsFromSave(), manager->getTotalStarsNumber())->getCString());

    }
}
