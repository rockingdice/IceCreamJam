//
//  OBJCHelper.h
//  FarmMania
//
//  Created by  James Lee on 13-5-23.
//
//

#include "cocos2d.h"
#pragma once
using namespace cocos2d;

typedef struct iapItemGroup
{
    int index;
    const char * icon;
    const char * price;
    int amount;
    int sale;
    bool bestValue;
    const char * ID;
    const char * symbol;
    const char * code;
} iapItemGroup;

enum kPostRequestType {
    kPostType_SyncInfo,//上传玩家id，名字，头像信息
    kPostType_AddFriend,//添加好友
    kPostType_InviteFriend,//邀请好友
    kPostType_SyncData,//上传玩家游戏进度
    kPostType_SyncFrdData,//获取好友游戏进度
    kPostType_SyncLevelRank,//获取关卡排名
};

typedef void (*PTRCCCALLBACK)(CCObject *);

class OBJCHelperDelegate;
class OBJCHelper {
public:
    CCArray * m_iapProducts;
    CCArray * m_fbMessages;
    CCArray * m_fbFriends;
    OBJCHelperDelegate * m_delegate;
public:
    OBJCHelper();
    ~OBJCHelper();
private:
    std::map<std::string, std::string> m_localizedStrings;
    int m_startTime;
public:
    void loadLocalizedStrings();
    static OBJCHelper * helper();
    void loadFont(const char * path);
    const char * getLocalizedString(const char * string);
    const char * getUID();
    const char * getVersion();
    const char * getLanguageCode();
    int getCurrentTime();
    void uploadLevelData(int worldIndex, int levelIndex, bool isQuest, const char * content);
    const char * getHMAC();
    CCArray * getIAPProducts();
    void updateIAPGroup(iapItemGroup * group);
    void buyIAPItem(const char * itemID, int amount, CCObject * target, SEL_CallFuncO callback);
    void saveGame();
    void contactUs();
    bool isConnectedToFacebook();
    void connectFacebook(bool connect);
    void showTinyMobiOffer();
    void goUpdate();
    //2013.7.10
    void restoreIAP(CCObject * target, SEL_CallFuncO callback);
    //2013.7.11
    void showRate();
    //2013.8.14
    void addDownloadCallback(CCObject * target, SEL_CallFuncO callback);
    //2014.3.26
    bool postRequest(CCObject * target, SEL_CallFuncO callback, kPostRequestType type, CCObject * userObject = NULL);
    //2014.3.26
    void initRequest();
    bool showUnlimitLife();
    bool showFreeSpin();
    bool getFacebookMessages();
    int  facebookFrdCount();
    void acceptFBRequest();
    void inviteFBFriends();
    void askLifeFromFriend();
    void sendLifeToFriend(const char * uid, CCObject * target = NULL, SEL_CallFuncO callback = NULL);
    void connectToFacebook(OBJCHelperDelegate * delegate);
    void facebookLoginFinished();
    void facebookLoginFaild();
    void releaseDelegate(OBJCHelperDelegate * delegate);
    void livesRefillNote();
    void freeSpinNote();
    void publicFBPassLevel(const char * level, const char * score);
    void publicFBDailyBonus(CCArray * tdic);
    void requestIOMContent();
    
    //2014.4.16
    double convertStringDateTo1970Sec(const char* timeStr);
    //确保value是字符串
    CCDictionary* converJsonStrToCCDic(const char* str);
    
    
    void trackLoginSuccess();
    void trackPurchase(const char* str, double price, const char* code);
    void trackLoginFb(const char* gender, const char* dob);
    void trackLevelFinish(const char* level, bool complete);
    void trackBuyBooster(const char* name, int cost);
    void trackTutorial(int step);
    void trackLevelUp(int level);
    bool showMinigame();
    void trackRegistration();
    void trackSessionStart();
    void trackSessionEnd();
    void trackBIPurchase(const char* amount, const char* pid, int gameAmount, const char* tid, const char* code);
    CCArray * getAllFBMessage() {return m_fbMessages;}
    CCArray * getAllFBFriends() {return m_fbFriends;}

    bool isFrdMsgEnable(const char* fid, int type);

    void showWeb(const char* urlstring);
    const char* getDeviceType();
    const char* getSysVersion();
    const char* getClientVersion();
    bool canShowMiniclipPopup();
    
};

class OBJCHelperDelegate {
    friend class OBJCHelper;
protected:
    virtual void facebookLoginSuccess() {};
    virtual void facebookLoginFaild() {};
};