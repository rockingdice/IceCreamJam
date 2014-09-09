//
//  GAMEUI.m
//  SNSEngine
//
//  Copyright 2012 TopGame. All rights reserved.
//  Created by James Lee on 11-7-7.
//  Copyright 2011 RockingDice. All rights reserved.
//

#include "GAMEUI.h"
#include "GUIScrollSlider.h"

GAMEUI::GAMEUI() :
    m_isCached(false),
    m_classType("GAMEUI"),
    m_classState(0),
    m_isPaused(false)
{
    setTouchMode(kCCTouchesOneByOne);
    setTouchPriority(0);
    setTouchEnabled(true);
}

GAMEUI::~GAMEUI()
{
    
}


void GAMEUI::pause()
{
    if (!m_isPaused) {
        m_isPaused = true;
        disableButtons(this);
    }
}

void GAMEUI::resume()
{
    if (m_isPaused) {
        m_isPaused = false;
        recoverButtons(this);
    }
}


void GAMEUI::backupChildrenButtonStates(cocos2d::CCNode *parentNode)
{
    CCControlButton * button = dynamic_cast<CCControlButton*>(parentNode);
    if ( button != NULL) {
        bool enabled = button->isEnabled();
        std::vector<bool> * buttonStates = NULL;
        std::map<CCNode *, std::vector<bool> *>::iterator it = m_buttonStates.find(parentNode);
        if (it == m_buttonStates.end()) {
            buttonStates = new std::vector<bool>();
            m_buttonStates[parentNode] = buttonStates;
        }
        else {
            buttonStates = it->second;
        }
        buttonStates->push_back(enabled);
    }
    else {
        GUIScrollSlider * slider = dynamic_cast<GUIScrollSlider *>(parentNode);
        if (slider != NULL) {
            bool enabled = slider->isEnabled();
            std::vector<bool> * buttonStates = NULL;
            std::map<CCNode *, std::vector<bool> *>::iterator it = m_buttonStates.find(parentNode);
            if (it == m_buttonStates.end()) {
                buttonStates = new std::vector<bool>();
                m_buttonStates[parentNode] = buttonStates;
            }
            else {
                buttonStates = it->second;
            }
            buttonStates->push_back(enabled);
        }
    }
    
    
    
    int count = parentNode->getChildrenCount();
    if (count != 0) {
        for (int i=0; i<count; i++) {
            CCNode * node = (CCNode *)parentNode->getChildren()->objectAtIndex(i);
            backupChildrenButtonStates(node);
        }
    }
}

void GAMEUI::disableButtons(cocos2d::CCNode *parentNode)
{
    backupChildrenButtonStates(parentNode);
    setButtonEnabledRecursively(false, parentNode);
}

void GAMEUI::recoverButtons(cocos2d::CCNode *parentNode)
{
    recoverChildrenButtonState(parentNode);
}

void GAMEUI::recoverChildrenButtonState(cocos2d::CCNode *parentNode)
{
    CCControlButton * button = dynamic_cast<CCControlButton*>(parentNode);
    if ( button != NULL) { 
        std::vector<bool> * buttonStates = NULL;
        std::map<CCNode *, std::vector<bool> *>::iterator it = m_buttonStates.find(parentNode);
        if (it == m_buttonStates.end()) {
            CCLOG("cannot find!");
        }
        else {
            buttonStates = it->second;
        }
        bool enabled = buttonStates->back();
        button->setEnabled(enabled);
        buttonStates->pop_back();
        if (buttonStates->size() == 0) {
            delete buttonStates;
            m_buttonStates.erase(parentNode);
        }
    }
    else {
        GUIScrollSlider * slider = dynamic_cast<GUIScrollSlider *>(parentNode);
        if (slider != NULL) {
            std::vector<bool> * buttonStates = NULL;
            std::map<CCNode *, std::vector<bool> *>::iterator it = m_buttonStates.find(parentNode);
            if (it == m_buttonStates.end()) {
                CCLOG("cannot find!");
            }
            else {
                buttonStates = it->second;
            }
            bool enabled = buttonStates->back();
            slider->setEnabled(enabled);
            buttonStates->pop_back();
            if (buttonStates->size() == 0) {
                delete buttonStates;
                m_buttonStates.erase(parentNode);
            }
        }
    }
    

    int count = parentNode->getChildrenCount();
    if (count != 0) {
        for (int i=0; i<count; i++) {
            CCNode * node = (CCNode *)parentNode->getChildren()->objectAtIndex(i);
            recoverChildrenButtonState(node);
        }
    }
}

void GAMEUI::setButtonEnabledRecursively(bool enabled, cocos2d::CCNode *parentNode)
{ 
    CCControlButton * button = dynamic_cast<CCControlButton*>(parentNode);
    if ( button != NULL) {
        button->setEnabled(enabled);
    }
    else {
        GUIScrollSlider * slider = dynamic_cast<GUIScrollSlider *>(parentNode);
        if (slider != NULL) {
            slider->setEnabled(enabled);
        }
    }
    
    
    int count = parentNode->getChildrenCount();
    if (count != 0) {
        for (int i=0; i<count; i++) {
            CCNode * node = (CCNode *)parentNode->getChildren()->objectAtIndex(i);
            setButtonEnabledRecursively(enabled, node);
        }
    }
}

void GAMEUI::setButtonTouchpriority(CCNode * parentNode, int priority)
{
    CCControl * button = dynamic_cast<CCControl*>(parentNode);
    int z = parentNode->getZOrder();
    if ( button != NULL) {
        button->setDefaultTouchPriority(priority - z);
        button->setTouchPriority(priority - z);
    }
    else {
        GUIScrollSlider * slider = dynamic_cast<GUIScrollSlider *>(parentNode);
        if (slider != NULL) {
            slider->setTouchPriority(priority - z);
        }
    }
    
    
    int count = parentNode->getChildrenCount();
    if (count != 0) {
        for (int i=0; i<count; i++) {
            CCNode * node = (CCNode *)parentNode->getChildren()->objectAtIndex(i);
            setButtonTouchpriority(node, priority - z );
        }
    }
}

void GAMEUI::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    CCSize size = CCDirector::sharedDirector()->getWinSize();
    setPosition(size.width * 0.5f, size.height * 0.5f);
    CCCallFunc * actionCallFunc = CCCallFunc::create(this, callfunc_selector(GAMEUI::transitionInDone));
    CCSequence * actionSequence = CCSequence::create(actionCallFunc, finishAction, NULL);
    runAction(actionSequence);
}

void GAMEUI::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    CCSize size = CCDirector::sharedDirector()->getWinSize();
    setPosition(size.width * 0.5f, size.height * 1.5f);
    CCCallFunc * actionCallFunc = CCCallFunc::create(this, callfunc_selector(GAMEUI::transitionOutDone));
    CCSequence * actionSequence = CCSequence::create(actionCallFunc, finishAction, NULL);
    runAction(actionSequence);
}

void GAMEUI::registerWithTouchDispatcher()
{ 
    CCTouchDispatcher* pDispatcher = CCDirector::sharedDirector()->getTouchDispatcher();
    pDispatcher->addTargetedDelegate(this, getTouchPriority(), true);
}

void GAMEUI::onEnter()
{
    CCLayer::onEnter();
    setTouchPriority(-getZOrder());
    setButtonTouchpriority(this, -getZOrder());
    
    
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
    setKeypadEnabled(true);
#endif
}
