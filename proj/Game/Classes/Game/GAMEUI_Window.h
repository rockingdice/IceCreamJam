//
//  GAMEUI_Window.h
//  uitest
//
//  Copyright 2012 TopGame. All rights reserved.
//  Created by James Lee on 11-8-17.
//  Copyright 2011 RockingDice. All rights reserved.
//
#pragma once
#include "GAMEUI.h" 

/*!
 
 GAMEUI_Window
 
 */

typedef enum {
	GUI_WINDOW_IDLE,
	GUI_WINDOW_ACTIVE,
	GUI_WINDOW_ABANDON,
}GUI_WINDOW_STATE;

class GAMEUI_Window : public GAMEUI {
public:
    GAMEUI_Window();
    ~GAMEUI_Window();
private:
    GAMEUI_Window * m_lastUi;
    GUI_WINDOW_STATE m_state;
public:
    void setLastUi(GAMEUI_Window * lastUi) { m_lastUi = lastUi; }
    void setState(GUI_WINDOW_STATE state) { m_state = state; }
    GAMEUI_Window * getLastUi() { return m_lastUi; }
    GUI_WINDOW_STATE getState() { return m_state; }
     
    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void transitionInDone(){}
    virtual void transitionOutDone(){}
};