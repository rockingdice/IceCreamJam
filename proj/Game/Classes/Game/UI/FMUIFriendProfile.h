//
//  FMUIFriendProfile.h
//  JellyMania
//
//  Created by lipeng on 14-8-6.
//
//

#ifndef __JellyMania__FMUIFriendProfile__
#define __JellyMania__FMUIFriendProfile__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"
#include "CCAnimButton.h"
#include "OBJCHelper.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIFriendProfile : public GAMEUI_Window , public CCBSelectorResolver, public CCBMemberVariableAssigner,OBJCHelperDelegate {
public:
    FMUIFriendProfile();
    ~FMUIFriendProfile();
private:
    bool m_instantMove;
    CCNode * m_ccbNode;
    CCLabelBMFont * m_levelLabel;
    CCSprite * m_avatarNode;
    CCLabelTTF * m_nameLabel;
    CCLabelBMFont * m_starLabel;
    CCLabelTTF * m_nameLabel2;
    CCAnimButton * m_sendButton;
    CCString * m_fid;
public:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);

public:
    virtual const char * classType() {return "FMUIFriendProfile";}
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void onEnter();
    void setProfile(CCDictionary * dic);
};


#endif /* defined(__JellyMania__FMUIFriendProfile__) */
