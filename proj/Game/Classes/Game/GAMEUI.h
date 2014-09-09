//
//  GAMEUI.h
//  SNSEngine
//
//  Copyright 2012 TopGame. All rights reserved.
//  Created by James Lee on 11-7-7.
//  Copyright 2011 RockingDice. All rights reserved.
//

#include "cocos2d.h"
#include "CCControlExtensions.h"
#include "FMSoundManager.h"
#include "CCAnimButton.h"

#pragma once

using namespace cocos2d;
using namespace cocos2d::extension;

/*!
 
 GAMEUI
 
 in charge of loading Graphical User Interface.
 
 */

class GAMEUI : public CCLayer  {
public:
    GAMEUI();
    ~GAMEUI();
private:
    bool                m_isPaused;
    bool                m_isCached;
    std::map<CCNode *, std::vector<bool> *>  m_buttonStates;
protected:
    const char *        m_classType;
    int                 m_classState;
public:
    bool isCached() {return m_isCached;}
    bool isPaused() {return m_isPaused;}
    virtual const char * classType() {return m_classType;}
    virtual int classState() { return m_classState; }
    virtual void setClassState(int state) { m_classState = state; }
    
    void pause();
    void resume();
    
    void disableButtons(CCNode * parentNode);
    void recoverButtons(CCNode * parentNode);
    void backupChildrenButtonStates(CCNode * parentNode);
    void recoverChildrenButtonState(CCNode * parentNode);
    void setButtonEnabledRecursively(bool enabled, CCNode * parentNode);
    void setButtonTouchpriority(CCNode * parentNode, int priority);
    
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void transitionInDone(){}
    virtual void transitionOutDone(){}
    
    virtual bool ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent) { return true; }
    virtual void ccTouchMoved(CCTouch *pTouch, CCEvent *pEvent) {}
    virtual void ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent) {}
    virtual void ccTouchCancelled(CCTouch *pTouch, CCEvent *pEvent) {}
    
    virtual void registerWithTouchDispatcher();
    
    virtual void onEnter();
};
  