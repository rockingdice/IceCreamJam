//
//  GAMEUI_Window.m
//  uitest
//
//  Copyright 2012 TopGame. All rights reserved.
//  Created by James Lee on 11-8-17.
//  Copyright 2011 RockingDice. All rights reserved.
//

#include "GAMEUI_Window.h"

GAMEUI_Window::GAMEUI_Window() :
    m_state(GUI_WINDOW_IDLE),
    m_lastUi(NULL)
{
    setZOrder(129);
}

GAMEUI_Window::~GAMEUI_Window()
{
    
}

void GAMEUI_Window::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    FMSound::playEffect("open.mp3");
    CCSize size = CCDirector::sharedDirector()->getWinSize();
    setPosition(ccp(-size.width, 0));
 
    CCCallFunc * actionCallFunc = CCCallFunc::create(this, callfunc_selector(GAMEUI_Window::transitionInDone));
    CCMoveTo * actionSlide = CCMoveTo::create(0.3f, CCPointZero);
    CCEaseBackOut * actionEase = CCEaseBackOut::create(actionSlide);
    CCSequence * actionSequence = CCSequence::create(actionEase, actionCallFunc, finishAction, NULL);
    
    runAction(actionSequence);
}

void GAMEUI_Window::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    CCSize size = CCDirector::sharedDirector()->getWinSize();
    setPosition(CCPointZero);
                
    CCCallFunc * actionCallFunc = CCCallFunc::create(this, callfunc_selector(GAMEUI_Window::transitionOutDone));
    CCMoveTo * actionSlide = CCMoveTo::create(0.3f, ccp(size.width, 0));
    CCEaseBackIn * actionEase = CCEaseBackIn::create(actionSlide);
    CCSequence * actionSequence = CCSequence::create(actionEase, actionCallFunc, finishAction, NULL);
    
    runAction(actionSequence);
}
