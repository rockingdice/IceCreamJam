//
//  CCAnimButton.h
//  JellyMania
//
//  Created by  James Lee on 13-11-27.
//
//

#ifndef __JellyMania__CCAnimButton__
#define __JellyMania__CCAnimButton__

#include <iostream>
#include "cocos2d.h"
#include "cocos-ext.h"
#include "CCControlExtensions.h"
#include "CCControlButtonLoader.h"
#include "NEAnimNode.h"

using namespace cocos2d;
using namespace cocos2d::extension;
using namespace neanim;

enum CCAnimButtonType {
    kCCAnimButton_PushButton = 0,
    kCCAnimButton_SwitchButton = 1,
    kCCAnimButton_CustomButton = 3,
};

class CCAnimButton : public CCControlButton
{
public: 
    CCAnimButton();
    ~CCAnimButton();
    static CCAnimButton * create();
    bool init();
    void useAnimFile(const char * fileName);
    void useSkin(const char * skinName);
    void setButtonType(CCAnimButtonType type) { m_buttonType = type;}
    NEAnimNode * getAnimNode() { return m_buttonAnim; }
    virtual void setHighlighted(bool enabled);
    virtual void setHighlightedAnimated(bool enabled);
    virtual void setSelected(bool enabled);
    virtual void setSelectedAnimated(bool enabled);
    
protected:
    virtual void needsLayout(void);
    //events
    virtual bool ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchMoved(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchCancelled(CCTouch *pTouch, CCEvent *pEvent);
private:
    NEAnimNode * m_buttonAnim;
    CCAnimButtonType m_buttonType;
    bool m_switchFlag;
};

class CCAnimButtonLoader : public CCControlButtonLoader
{
public:
    CCB_STATIC_NEW_AUTORELEASE_OBJECT_METHOD(CCAnimButtonLoader, loader);
    
    CCB_VIRTUAL_NEW_AUTORELEASE_CREATECCNODE_METHOD(CCAnimButton);
    
protected:
    virtual void onHandlePropTypeString(CCNode * pNode, CCNode * pParent, const char * pPropertyName, const char * pString, CCBReader * pCCBReader);
    virtual void onHandlePropTypeInteger(CCNode * pNode, CCNode * pParent, const char* pPropertyName, int pInteger, CCBReader * pCCBReader);
};

#endif /* defined(__JellyMania__CCAnimButton__) */
