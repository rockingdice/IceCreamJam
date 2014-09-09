//
//  GAMEUI_Dialog.m
//  CarGame
//
//  Copyright 2012 TopGame. All rights reserved.
//  Created by James Lee on 11-8-17.
//  Copyright 2011 RockingDice. All rights reserved.
//

#include "GAMEUI_Dialog.h" 
#include "GAMEUI_Scene.h"

GAMEUI_Dialog::GAMEUI_Dialog() :
    m_next(NULL),
    m_object(NULL),
    m_callback(NULL)
{
    setZOrder(129);
}

GAMEUI_Dialog::~GAMEUI_Dialog()
{
    if (m_next) {
        m_next->release();
        m_next = NULL;
    }
    
    if (m_object) {
        delete m_object;
        m_object = NULL;
    }
}

void GAMEUI_Dialog::setNextDialog(GAMEUI_Dialog *dialog)
{
    if (m_next) {
        m_next->release();
    }
    m_next = dialog;
    m_next->retain();
}

void GAMEUI_Dialog::transitionIn(cocos2d::CCCallFunc *finishAction)
{
    FMSound::playEffect("open.mp3");
    setScale(1.f);
    CCCallFunc * actionCallFunc = CCCallFunc::create(this, callfunc_selector(GAMEUI_Dialog::transitionInDone));
    CCScaleTo * actionScale = CCScaleTo::create(0.25f, 1.f);
    CCEaseBackOut * actionEase = CCEaseBackOut::create(actionScale);
    CCSequence * actionSequence = CCSequence::create(actionEase, actionCallFunc, finishAction, NULL);
    
    runAction(actionSequence);
}
 
void GAMEUI_Dialog::transitionOut(cocos2d::CCCallFunc *finishAction)
{
    setScale(1.f);
        
    CCCallFunc * actionCallFunc = CCCallFunc::create(this, callfunc_selector(GAMEUI_Dialog::transitionOutDone));
    CCScaleTo * actionScale = CCScaleTo::create(0.25f, 1.f);
    CCEaseBackOut * actionEase = CCEaseBackOut::create(actionScale);
    CCSequence * actionSequence = CCSequence::create(actionEase, actionCallFunc, finishAction, NULL);
    
    runAction(actionSequence);
}

void GAMEUI_Dialog::handleDialog()
{
	if (m_callback) {
        m_callback->startWithTarget(this);
        m_callback->execute();
	} 
}

void GAMEUI_Dialog::setHandleCallback(cocos2d::CCCallFuncN *callback)
{
    if (m_callback) {
        m_callback->release();
        m_callback = NULL;
    }
    m_callback = callback;
    m_callback->retain();
}