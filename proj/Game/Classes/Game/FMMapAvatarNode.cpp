//
//  FMMapAvatarNode.cpp
//  JellyMania
//
//  Created by lipeng on 14-8-5.
//
//

#include "FMMapAvatarNode.h"
#include "FMDataManager.h"
#include "SNSFunction.h"
#include "FMUIFriendProfile.h"
#include "GAMEUI_Scene.h"
#include "FMWorldMapNode.h"
#include "FMMainScene.h"

static float avatarDiffx = 3.f;
static float avatarDiffy = 3.f;
static float expandAvatarx = 36.f;
static float expandAvatary = 36.f;

FMMapAvatarNode * FMMapAvatarNode::creatAvatarNode(bool includeSelf, CCDictionary * dic)
{
    FMMapAvatarNode * node = new FMMapAvatarNode();
    if (node) {
        FMDataManager * manager = FMDataManager::sharedManager();
        
        node->m_includeSelf = includeSelf;
        node->m_dicList->addObject(dic);
        
        if (includeSelf) {
            CCBAnimationManager * anim = (CCBAnimationManager *)node->m_mainAvatarNode->getUserObject();
            anim->runAnimationsForSequenceNamed("2");
            node->m_mainAvatarNode->setPosition(ccp(avatarDiffx, avatarDiffy));
        }
        
        CCString * uid = (CCString *)dic->objectForKey("uid");
        const char * iconpath = SNSFunction_getFacebookIcon(uid->getCString());

        CCSprite * icon = (CCSprite*)node->m_mainAvatarNode->getChildByTag(1);
        
        if (iconpath && manager->isFileExist(iconpath)) {
            CCSprite * spr = CCSprite::create(iconpath);
            float size = 26.f;
            spr->setScale(size / MAX(spr->getContentSize().width, size));
            icon->addChild(spr);
            spr->setPosition(ccp(icon->getContentSize().width/2, icon->getContentSize().height/2));
        }
        
        node->autorelease();
        return node;
    }
    CC_SAFE_DELETE(node);
    return NULL;
}

FMMapAvatarNode::FMMapAvatarNode():
m_avatarList(NULL),
m_dicList(NULL),
m_mainAvatarNode(NULL),
m_includeSelf(false),
m_isExpand(false)
{
    m_avatarList = CCArray::create();
    m_avatarList->retain();
    
    m_dicList = CCArray::create();
    m_dicList->retain();
    
    FMMainScene * mainScene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
    FMWorldMapNode* wd = (FMWorldMapNode*)mainScene->getNode(kWorldMapNode);
    m_mainAvatarNode = FMDataManager::sharedManager()->createNode("UI/FMUIAvatar.ccbi", wd);
    addChild(m_mainAvatarNode, 10, 0);
    
    m_avatarList->addObject(m_mainAvatarNode);
}

FMMapAvatarNode::~FMMapAvatarNode()
{
    CC_SAFE_RELEASE(m_avatarList);
    CC_SAFE_RELEASE(m_dicList);
}


bool FMMapAvatarNode::addAvatarNode(CCDictionary * dic)
{
    if (m_avatarList->count() >= 4) {
        return false;
    }
    FMDataManager * manager = FMDataManager::sharedManager();
    
    FMMainScene * mainScene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
    FMWorldMapNode* wd = (FMWorldMapNode*)mainScene->getNode(kWorldMapNode);
    CCNode * n = manager->createNode("UI/FMUIAvatar.ccbi", wd);
    addChild(n,10-m_avatarList->count(),m_avatarList->count());
    m_avatarList->addObject(n);
    
    CCString * uid = (CCString *)dic->objectForKey("uid");
    const char * iconpath = SNSFunction_getFacebookIcon(uid->getCString());
    
    CCSprite * icon = (CCSprite*)n->getChildByTag(1);
    
    if (iconpath && manager->isFileExist(iconpath)) {
        CCSprite * spr = CCSprite::create(iconpath);
        float size = 26.f;
        spr->setScale(size / MAX(spr->getContentSize().width, size));
        icon->addChild(spr);
        spr->setPosition(ccp(icon->getContentSize().width/2, icon->getContentSize().height/2));
    }
    
    int cnt = m_avatarList->count()-1;
    if (m_includeSelf) {
        cnt++;
    }
    n->setPosition(ccp(cnt * avatarDiffx, cnt * avatarDiffy));
    
    CCBAnimationManager * anim = (CCBAnimationManager *)n->getUserObject();
    anim->runAnimationsForSequenceNamed("2");

    m_dicList->addObject(dic);
    
    return true;
}

bool FMMapAvatarNode::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    return true;
}

SEL_CCControlHandler FMMapAvatarNode::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickAvatarBtn", FMMapAvatarNode::clickAvatarBtn);
    return NULL;
}

void FMMapAvatarNode::clickAvatarBtn(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    int t = 1;
    if (m_includeSelf) {
        t--;
    }
    if (!m_isExpand && m_avatarList->count() > t) {
        expandAvatars(true);
    }else{
        FMDataManager* manager = FMDataManager::sharedManager();
        expandAvatars(false);
        CCControlButton * button = (CCControlButton *)object;
        
        int index = button->getParent()->getTag();
        
        if (m_dicList) {
            if (index < m_dicList->count()) {
                FMUIFriendProfile * window = (FMUIFriendProfile *)manager->getUI(kUI_FriendProfile);
                GAMEUI_Scene::uiSystem()->nextWindow(window);
                CCDictionary * dic = (CCDictionary *)m_dicList->objectAtIndex(index);
                window->setProfile(dic);
            }
        }
    }
}

void FMMapAvatarNode::expandAvatars(bool flag)
{
    m_isExpand = flag;
    int index = 1;
    if (m_includeSelf) {
        FMMainScene * mainScene = (FMMainScene *)FMDataManager::sharedManager()->getUI(kUI_MainScene);
        FMWorldMapNode* wd = (FMWorldMapNode*)mainScene->getNode(kWorldMapNode);
        wd->setAvatarEnable(flag);
        
        index = 0;
    }
    
    float time = 0.1f;
    int t = 0;
    for (int i = index; i < m_avatarList->count(); i++) {
        t++;
        CCNode * n = (CCNode *)m_avatarList->objectAtIndex(i);
        if (m_isExpand) {
            float x = t%2;
            float y = t/2;
            CCPoint end = ccp(x * expandAvatarx, y * expandAvatary);
            n->runAction(CCMoveTo::create(time, end));
        }else{
            CCPoint end = ccp(t * avatarDiffx, t * avatarDiffy);
            n->runAction(CCMoveTo::create(time, end));
        }
    }
}
