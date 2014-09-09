//
//  FMUIConfig.cpp
//  FarmMania
//
//  Created by  James Lee on 13-5-26.
//
//

#include "FMUIConfig.h"
#include "FMDataManager.h"
#include "GAMEUI_Scene.h"
#include "FMUIQuit.h"
#include "FMMainScene.h"
#include "FMGameNode.h"
#include "OBJCHelper.h"
#include "SNSFunction.h"
#include "FMUIWorldMap.h"
#include "FMUIRestore.h"
#include "FMStatusbar.h"
#include "FMUIInputName.h"


FMUIConfig::FMUIConfig() :
    m_titleLabel(NULL), 
    m_useridLabel(NULL),
    m_versionLabel(NULL),
    m_buttonParent(NULL),
    m_button1Label(NULL),
    m_centerNode(NULL),
    m_instantMove(false),
    m_facebookButton(NULL),
    m_facebookInfo(NULL),
    m_facebookIcon(NULL),
    m_facebookName(NULL),
    m_connectNode(NULL)
//    m_buttonsCN(NULL),
//    m_buttonsEN(NULL)
{
    m_ccbNode = FMDataManager::sharedManager()->createNode("UI/FMUIConfig.ccbi", this);
    addChild(m_ccbNode);
    
    m_facebookInfo->setString("");
    m_facebookInfo->setWidth(150.f);
    m_facebookInfo->setAlignment(kCCTextAlignmentCenter);
    m_facebookInfo->setLineBreakWithoutSpace(FMDataManager::sharedManager()->isCharacterType());
    
    
    FMDataManager * manager = FMDataManager::sharedManager();
    CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    anim->runAnimationsForSequenceNamed("SettingNoRestore");
#else
    anim->runAnimationsForSequenceNamed("Setting");
#endif
    m_titleLabel->setString(manager->getLocalizedString("V100_SETTINGS"));
}

FMUIConfig::~FMUIConfig()
{
    
}

#pragma mark - CCB Bindings
bool FMUIConfig::onAssignCCBMemberVariable(cocos2d::CCObject *pTarget, const char *pMemberVariableName, cocos2d::CCNode *pNode)
{
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_titleLabel", CCLabelBMFont *, m_titleLabel); 
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_useridLabel", CCLabelBMFont *, m_useridLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_versionLabel", CCLabelBMFont *, m_versionLabel);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_buttonParent", CCNode *, m_buttonParent);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_button1Label", CCLabelBMFont *, m_button1Label);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_centerNode", CCNode *, m_centerNode);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_facebookButton", CCAnimButton *, m_facebookButton);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_facebookInfo", CCLabelBMFont *, m_facebookInfo);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_facebookIcon", CCSprite *, m_facebookIcon);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_facebookName", CCLabelTTF *, m_facebookName);
    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_connectNode", CCNode *, m_connectNode);
//    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_buttonsEN", CCNode *, m_buttonsEN);
//    CCB_MEMBERVARIABLEASSIGNER_GLUE(this, "m_buttonsCN", CCNode *, m_buttonsCN);
    
    return true;
}

SEL_CCControlHandler FMUIConfig::onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName)
{
    CCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "clickButton", FMUIConfig::clickButton);
    return NULL;
}


void FMUIConfig::keyBackClicked()
{
    if( GAMEUI_Scene::uiSystem()->getCurrentUI() == this )
    {
        m_instantMove = false;
        GAMEUI_Scene::uiSystem()->prevWindow();
    }
}

void FMUIConfig::clickButton(cocos2d::CCObject *object, CCControlEvent event)
{
    FMSound::playEffect("click.mp3", 0.1f, 0.1f);
    CCControlButton * button = (CCControlButton *)object;
    switch (button->getTag()) {
        case 0:
        {
            //close
            m_instantMove = false;
            GAMEUI_Scene::uiSystem()->prevWindow();
        }
            break;
        case 1:
        {
#ifdef BRANCH_CN
            SNSFunction_weixinOpen();
#else
            //connect facebook
            if (!m_isConnectedToFacebook) {
                OBJCHelper::helper()->connectToFacebook(NULL);
            }
            else {
                SNSFunction_disconnectFacebook();
                
                //show the facebook button in worldmap
                FMUIWorldMap * ui = (FMUIWorldMap *)FMDataManager::sharedManager()->getUI(kUI_WorldMap);
                ui->updateUI();
            }
#endif
            GAMEUI_Scene::uiSystem()->prevWindow();
        }
            break;
        case 2:
        {
            //contact us
#ifdef BRANCH_TH
            OBJCHelper* helper = OBJCHelper::helper();
            const char* gameName = "JellyMania";
            const char* language = helper->getLanguageCode();
            const char* uid = helper->getUID();
            int pay = SNSFunction_getTotalPayment();
            pay > 0 ? pay = 1: pay = 0;
            const char* snsid = CCString::createWithFormat("%d",pay)->getCString();
            const char* userName = "anonymity";
            const char* device = "1";
            const char* deviceMode = helper->getDeviceType();
            const char* sysVersion = helper->getSysVersion();
            const char* appVersion = helper->getClientVersion();
            CCString* linkStr = CCString::createWithFormat("http://support-jmm.funplusgame.com/SM?game=%s&lang=%s&farmid=%s&uname=%s&snsid=%s&device=%s&device_model=%s&system_version=%s&app_version=%s",gameName,language,uid,userName,snsid,device,deviceMode,sysVersion,appVersion);
            
            OBJCHelper::helper()->showWeb(linkStr->getCString());
#else
            OBJCHelper::helper()->contactUs();
#endif
        }
            break;
        case 3:
        {
            SNSFunction_disconnectFacebook();
            
            //show the facebook button in worldmap
            FMUIWorldMap * ui = (FMUIWorldMap *)FMDataManager::sharedManager()->getUI(kUI_WorldMap);
            ui->updateUI();
            
            updateUI();
        }
            break;
        case 4:
        {
#ifdef BRANCH_CN
            //rename
            GAMEUI_Scene::uiSystem()->closeAllWindows();
            FMUIInputName * dialog = (FMUIInputName *)FMDataManager::sharedManager()->getUI(kUI_InputName);
            dialog->setIsRename(true);
            GAMEUI_Scene::uiSystem()->addDialog(dialog);
#else
            //restore
            FMUIRestore * window = (FMUIRestore *)FMDataManager::sharedManager()->getUI(kUI_LevelEnd);
            window->setClassState(kSRestore);
            GAMEUI_Scene::uiSystem()->nextWindow(window);
#endif
        }
            break;
        case 5:
        {
            //go to weixin
#ifdef BRANCH_CN
            SNSFunction_weixinOpen();
#endif
        }
            break;
        case 10:
        {
            FMDataManager * manager = FMDataManager::sharedManager();
            bool on = manager->isMusicOn();
            on = !on;
            manager->setMusicOn(on);
            FMSound::setMusicOn(on);
//            updateUI();
        }
            break;
        case 11:
        {
            FMDataManager * manager = FMDataManager::sharedManager();
            bool on = manager->isSFXOn();
            on = !on;
            manager->setSFXOn(on);
            FMSound::setEffectOn(on);
//            updateUI();
        }
            break;
        case 12:
        {
            // logout google play
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
            SNSFunction_googlePlayLogout();
            FMUIWorldMap * ui = (FMUIWorldMap *)FMDataManager::sharedManager()->getUI(kUI_WorldMap);
            if( ui ) ui->updateGoogleLoginBtn(0);
            keyBackClicked();
#endif
        }
            break;
        default:
            break;
    }
} 



void FMUIConfig::setClassState(int state)
{
    GAMEUI::setClassState(state);
}


void FMUIConfig::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    GAMEUI_Window::transitionIn(finishAction);
}

void FMUIConfig::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    if (m_instantMove) {
        setVisible(false);
        runAction(finishAction);
    }
    else {
        GAMEUI_Window::transitionOut(finishAction);
    }
}

void FMUIConfig::onEnter()
{
    GAMEUI_Window::onEnter();

    updateUI();
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    if(SNSFunction_getPackageType() == PT_GOOGLE_EN_FACEBOOK){
        CCBAnimationManager * anim = (CCBAnimationManager *)m_ccbNode->getUserObject();
        bool islogin = SNSFunction_isGooglePlayLogin();
        if(islogin) anim->runAnimationsForSequenceNamed("SettingGoogleLogout");
        else anim->runAnimationsForSequenceNamed("SettingNoRestore");
    }
#endif
}

void FMUIConfig::updateUI()
{
    FMDataManager * manager = FMDataManager::sharedManager();
    bool switches[2];
    switches[0] = manager->isMusicOn();
    switches[1] = manager->isSFXOn();
    CCAnimButton * buttonSound = (CCAnimButton *)m_buttonParent->getChildByTag(10);
    buttonSound->setSelected(switches[0]);
    CCAnimButton * buttonSFX = (CCAnimButton *)m_buttonParent->getChildByTag(11);
    buttonSFX->setSelected(switches[1]);
    
#ifdef BRANCH_CN
    NEAnimNode* anim = m_facebookButton->getAnimNode();
    anim->changeFile("FMButton_ImageButton.ani");
    anim->useSkin("Weixin");
    anim->playAnimation("Release");

    m_facebookInfo->setString(FMDataManager::sharedManager()->getLocalizedString("V100_WEIXIN"));
#else
    m_isConnectedToFacebook = SNSFunction_isFacebookConnected();
    m_facebookButton->setSelected(m_isConnectedToFacebook);
    m_facebookButton->setVisible(!m_isConnectedToFacebook);
    m_facebookInfo->setVisible(!m_isConnectedToFacebook);
    m_connectNode->setVisible(m_isConnectedToFacebook);
    m_facebookIcon->setVisible(m_isConnectedToFacebook);
    m_facebookName->setVisible(m_isConnectedToFacebook);
    
    
    if (!m_isConnectedToFacebook) {
        m_facebookInfo->setString(FMDataManager::sharedManager()->getLocalizedString("V100_FACEBOOK_CONNECTED"));
    }
    else {
//        m_facebookInfo->setString(FMDataManager::sharedManager()->getLocalizedString("V100_FACEBOOK_DISCONNECTED"));
        const char * userName = SNSFunction_getFacebookUsername();
        const char * icon = SNSFunction_getFacebookIcon();
        if (userName) {
            m_facebookName->setString(userName);
            m_facebookIcon->removeAllChildrenWithCleanup(true);
            if (FMDataManager::sharedManager()->isFileExist(icon)) {
                CCSprite * spr = CCSprite::create(icon);
                float size = 45.f;
                spr->setScale(size / MAX(spr->getContentSize().width, size));
                m_facebookIcon->addChild(spr);                
            }
        }
    }
#endif

    
//    for (int i = 0; i<2; i++) {
//        NEAnimNode * button = (NEAnimNode *)m_buttonParent->getChildByTag(i);
//        if (switches[i]) {
//            button->playAnimation("On");
//        }
//        else {
//            button->playAnimation("Off");
//        }
//    }
    bool willShow = classState() != 0;
    
//#ifdef BRANCH_CN  
//    m_buttonsEN->setVisible(false);
//    m_buttonsCN->setVisible(willShow ? true : false);
//    
//    CCControlButton * button = (CCControlButton *)m_buttonsEN->getChildByTag(1);
//    button->setEnabled(false);
//    
//    button = (CCControlButton *)m_buttonsCN->getChildByTag(5);
//    button->setEnabled(willShow ? true : false);
//    
//    CCLabelBMFont * f1 = (CCLabelBMFont *)m_buttonsCN->getChildByTag(1);
//    CCLabelBMFont * f2 = (CCLabelBMFont *)m_buttonsCN->getChildByTag(2);
//    f1->setString(FMDataManager::sharedManager()->getLocalizedString("V130_WEIXIN_PUBLIC_TITLE"));
//    f2->setString(FMDataManager::sharedManager()->getLocalizedString("V130_WEIXIN_PUBLIC_INFO"));
//#else
//    m_buttonsEN->setVisible(willShow ? true : false);
//    m_buttonsCN->setVisible(false);
//    
//    CCControlButton * button = (CCControlButton *)m_buttonsEN->getChildByTag(1);
//    button->setEnabled(willShow ? true : false);
//    
//    button = (CCControlButton *)m_buttonsCN->getChildByTag(5);
//    button->setEnabled(false);
//    
//    m_isConnectedToFacebook = SNSFunction_isFacebookConnected();
//    
//    const char * connectString = m_isConnectedToFacebook? "V108_DISCONNECT" : "V108_CONNECT";
//    const char * c = FMDataManager::sharedManager()->getLocalizedString(connectString);
//    m_button1Label->setString(c);
//#endif
    CCString * cstr = CCString::createWithFormat("V %s", manager->getVersion());
    m_versionLabel->setString(cstr->getCString());
    
    cstr = CCString::createWithFormat(manager->getLocalizedString("V100_SUPPORT_ID"), manager->getUID());
    m_useridLabel->setString(cstr->getCString());
}
