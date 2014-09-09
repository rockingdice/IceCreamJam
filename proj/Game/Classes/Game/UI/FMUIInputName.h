//
//  FMUIInputName.h
//  JellyMania
//
//  Created by lipeng on 14-4-14.
//
//

#ifndef __JellyMania__FMUIInputName__
#define __JellyMania__FMUIInputName__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "GAMEUI_Window.h"
#include "GAMEUI_Dialog.h"

using namespace cocos2d;
using namespace cocos2d::extension;

class FMUIInputName : public GAMEUI_Dialog , public CCBSelectorResolver, public CCBMemberVariableAssigner, public CCEditBoxDelegate{
private:
    CCNode * m_ccbNode;
    CCNode * m_panel;
    CCScale9Sprite * m_textfieldParent;
    CCEditBox * m_editBox;
    bool m_isRename;
public:
    FMUIInputName();
    ~FMUIInputName();
    
private:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual void editBoxReturn(CCEditBox* editBox);
public:
    void setIsRename(bool flag) {m_isRename = flag;}
    virtual const char * classType() {return "FMUIInputName";}
    void clickButton(CCObject * object , CCControlEvent event);
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void transitionInDone();
    virtual void onEnter();
    void nameEmpty();
    void nameLength();
};

#endif /* defined(__JellyMania__FMUIInputName__) */
