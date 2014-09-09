//
//  FMMapAvatarNode.h
//  JellyMania
//
//  Created by lipeng on 14-8-5.
//
//

#ifndef __JellyMania__FMMapAvatarNode__
#define __JellyMania__FMMapAvatarNode__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
using namespace cocos2d;
using namespace cocos2d::extension;

class FMMapAvatarNode : CCNode, public CCBMemberVariableAssigner, public CCBSelectorResolver
{
public:
    static FMMapAvatarNode * creatAvatarNode(bool includeSelf, CCDictionary * dic);
    FMMapAvatarNode();
    ~FMMapAvatarNode();
    bool addAvatarNode(CCDictionary * dic);
protected:
    virtual bool onAssignCCBMemberVariable(CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode);
    virtual SEL_MenuHandler onResolveCCBCCMenuItemSelector(CCObject * pTarget, const char* pSelectorName){return 0;}
    virtual SEL_CCControlHandler onResolveCCBCCControlSelector(CCObject * pTarget, const char* pSelectorName);

private:
    CCArray * m_avatarList;
    CCNode * m_mainAvatarNode;
    CCArray * m_dicList;
    bool m_includeSelf;
    bool m_isExpand;
    
    
    void expandAvatars(bool flag);
public:
    void clickAvatarBtn(CCObject * object, CCControlEvent event);
    
    
};

#endif /* defined(__JellyMania__FMMapAvatarNode__) */
