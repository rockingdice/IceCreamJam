//
//  DailyBox.h
//  JellyMania
//
//  Created by lipeng on 14-8-15.
//
//

#ifndef __JellyMania__DailyBox__
#define __JellyMania__DailyBox__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
using namespace cocos2d;
using namespace cocos2d::extension;

class DailyBox : CCNode, public CCBMemberVariableAssigner, public CCBSelectorResolver
{
public:
    static DailyBox * creat();
    DailyBox();
    ~DailyBox();
protected:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);
    virtual void update(float delta);
private:
    CCNode * m_ccbNode;
};

#endif /* defined(__JellyMania__DailyBox__) */
