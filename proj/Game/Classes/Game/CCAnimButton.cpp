//
//  CCAnimButton.cpp
//  JellyMania
//
//  Created by  James Lee on 13-11-27.
//
//

#include "CCAnimButton.h"


#pragma mark - CCAnimButton
CCAnimButton::CCAnimButton() :
    m_buttonAnim(NULL),
    m_buttonType(kCCAnimButton_PushButton),
    m_switchFlag(false)
{
    m_buttonAnim = NEAnimNode::create();
    addChild(m_buttonAnim);
    
}

CCAnimButton::~CCAnimButton()
{
    removeChild(m_buttonAnim);
    m_buttonAnim = NULL;
}

bool CCAnimButton::init()
{
    if (CCControlButton::init()) {
//        CCSpriteFrame * empty = CCSpriteFrame::create("transparent.png", CCRectZero);
//        CCControlButton::setBackgroundSpriteFrameForState(empty, CCControlStateNormal);
//        CCControlButton::setBackgroundSpriteFrameForState(empty, CCControlStateHighlighted);
//        CCControlButton::setBackgroundSpriteFrameForState(empty, CCControlStateSelected);
//        CCControlButton::setBackgroundSpriteFrameForState(empty, CCControlStateDisabled);
        return true;
    }
    return false;
}

CCAnimButton * CCAnimButton::create()
{
    CCAnimButton *pControlButton = new CCAnimButton();
    if (pControlButton && pControlButton->init())
    {
        pControlButton->autorelease();
        return pControlButton;
    }
    CC_SAFE_DELETE(pControlButton);
    return NULL;
}

void CCAnimButton::needsLayout()
{
    CCRect rectBackground;
    CCScale9Sprite * f = getBackgroundSprite();
    if (f != NULL)
    {
        rectBackground = f->boundingBox();
    }
    
    CCRect maxRect = rectBackground;
    setContentSize(CCSizeMake(maxRect.size.width, maxRect.size.height));
    
    if (m_buttonAnim) {
        m_buttonAnim->setPosition(ccp (getContentSize().width / 2, getContentSize().height / 2));
    }
}

void CCAnimButton::useAnimFile(const char *fileName)
{
    m_buttonAnim->changeFile(fileName);
}

void CCAnimButton::useSkin(const char *skinName)
{
    m_buttonAnim->useSkin(skinName);
}

void CCAnimButton::setSelected(bool enabled)
{
    CCControl::setSelected(enabled);
    if (m_buttonType != kCCAnimButton_SwitchButton) {
        return;
    }
    if (enabled) {
        m_buttonAnim->playAnimation("OnIdle", 0 , false, true);
    }
    else {
        m_buttonAnim->playAnimation("OffIdle", 0, false, true);
    }
}

void CCAnimButton::setSelectedAnimated(bool enabled)
{
    CCControl::setSelected(enabled);
    if (m_buttonType != kCCAnimButton_SwitchButton) {
        return;
    }
    if (enabled) {
        m_buttonAnim->playAnimation("On");
    }
    else {
        m_buttonAnim->playAnimation("Off");
    }
}


void CCAnimButton::setHighlighted(bool enabled)
{
    CCControl::setHighlighted(enabled);
    if (m_buttonType != kCCAnimButton_PushButton) {
        return;
    }
    if (enabled) {
        m_buttonAnim->stopAllActions();
        m_buttonAnim->playAnimation("PushIdle", 0, false, true);
    }
    else {
        m_buttonAnim->stopAllActions();
        m_buttonAnim->playAnimation("ReleaseIdle", 0, false, true);
    }
}

void CCAnimButton::setHighlightedAnimated(bool enabled)
{
    bool h = isHighlighted();
    CCControl::setHighlighted(enabled);
    if (m_buttonType != kCCAnimButton_PushButton) {
        return;
    }
    if (h != enabled) {
        if (enabled) {
            m_buttonAnim->stopAllActions();
            NEAnimationDoneAction * a1 = NEAnimationDoneAction::create(m_buttonAnim, "Push");
            NEAnimationDoneAction * a2 = NEAnimationDoneAction::create(m_buttonAnim, "PushIdle");
            CCSequence * seq = CCSequence::create(a1, a2, NULL);
            m_buttonAnim->runAction(seq);
        }
        else {
            m_buttonAnim->stopAllActions();
            NEAnimationDoneAction * a1 = NEAnimationDoneAction::create(m_buttonAnim, "Release");
            NEAnimationDoneAction * a2 = NEAnimationDoneAction::create(m_buttonAnim, "ReleaseIdle");
            CCSequence * seq = CCSequence::create(a1, a2, NULL);
            m_buttonAnim->runAction(seq);
        }
    }
}

bool CCAnimButton::ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent)
{
    if (!isTouchInside(pTouch) || !isEnabled() || !isVisible())
    {
        return false;
    }
    
    p_touchBegan = pTouch->getLocation(); // Get the touch position
    m_eState=CCControlStateHighlighted;
    m_isPushed=true;
    this->setHighlightedAnimated(true);
    sendActionsForControlEvents(CCControlEventTouchDown);
    return true;
}

static float distanceBetweenPointAndPoint(CCPoint point1, CCPoint point2)
{
    float dx = point1.x - point2.x;
    float dy = point1.y - point2.y;
    return sqrt(dx*dx + dy*dy);
}

void CCAnimButton::ccTouchMoved(CCTouch *pTouch, CCEvent *pEvent)
{
    if (!isEnabled() || !isPushed() || isSelected())
    {
        if (isHighlighted())
        {
            setHighlighted(false);
        }
        return;
    }
    
    bool isTouchMoveInside = isTouchInside(pTouch);
    if (isTouchMoveInside && !isHighlighted())
    {
        m_eState = CCControlStateHighlighted;
        setHighlighted(true);
        sendActionsForControlEvents(CCControlEventTouchDragEnter);
    }
    else if (isTouchMoveInside && isHighlighted())
    {
        CCPoint p_touchMoved = pTouch->getLocation();
        double dis = distanceBetweenPointAndPoint(p_touchBegan, p_touchMoved);
        if(dis > 10) {
            sendActionsForControlEvents(CCControlEventTouchDragInside);
        }
    }
    else if (!isTouchMoveInside && isHighlighted())
    {
        m_eState = CCControlStateNormal;
        setHighlightedAnimated(false);
        
        sendActionsForControlEvents(CCControlEventTouchDragExit);
    }
    else if (!isTouchMoveInside && !isHighlighted())
    {
        sendActionsForControlEvents(CCControlEventTouchDragOutside);
    }
}
void CCAnimButton::ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent)
{
    m_eState = CCControlStateNormal;
    m_isPushed = false;
    setHighlightedAnimated(false);
    
    
    if (isTouchInside(pTouch))
    {
        if (m_buttonType == kCCAnimButton_SwitchButton) {
            bool s = !isSelected();
            setSelectedAnimated(s);
        }
        sendActionsForControlEvents(CCControlEventTouchUpInside);
    }
    else
    {
        sendActionsForControlEvents(CCControlEventTouchUpOutside);
    }
}

void CCAnimButton::ccTouchCancelled(CCTouch *pTouch, CCEvent *pEvent)
{
    m_eState = CCControlStateNormal;
    m_isPushed = false;
    setHighlightedAnimated(false);
    sendActionsForControlEvents(CCControlEventTouchCancel);
}


#pragma mark - CCAnimButtonLoader
void CCAnimButtonLoader::onHandlePropTypeString(cocos2d::CCNode *pNode, cocos2d::CCNode *pParent, const char *pPropertyName, const char *pString, cocos2d::extension::CCBReader *pCCBReader)
{
    if(strcmp(pPropertyName, "file") == 0) {
        ((CCAnimButton *)pNode)->useAnimFile(pString);
        ((CCAnimButton *)pNode)->setHighlighted(false);
    }
    else if (strcmp(pPropertyName, "anim") == 0) {
        ((CCAnimButton *)pNode)->getAnimNode()->playAnimation(pString);
    }
    else if (strcmp(pPropertyName, "skin") == 0) {
        ((CCAnimButton *)pNode)->useSkin(pString);
    }
}

void CCAnimButtonLoader::onHandlePropTypeInteger(CCNode * pNode, CCNode * pParent, const char* pPropertyName, int pInteger, CCBReader * pCCBReader) {
    CCNodeLoader::onHandlePropTypeInteger(pNode, pParent, pPropertyName, pInteger, pCCBReader);
    if(strcmp(pPropertyName, "buttonType") == 0) {
        ((CCAnimButton *)pNode)->setButtonType((CCAnimButtonType)pInteger);
    }
}