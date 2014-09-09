//
//  GAMEUI_Dialog.h
//  CarGame
//
//  Copyright 2012 TopGame. All rights reserved.
//  Created by James Lee on 11-8-17.
//  Copyright 2011 RockingDice. All rights reserved.
//

#pragma once
#include "GAMEUI.h"

/*!
 
 GAMEUI_Dialog
 
 */
 
typedef enum {
	DIALOG_CANCELED,
	DIALOG_OK,
}GUI_DIALOG_RESULT;

class GAMEUI_Dialog : public GAMEUI {
public:
    GAMEUI_Dialog();
    ~GAMEUI_Dialog();
private:
	GAMEUI_Dialog	*		m_next;
protected:
	GUI_DIALOG_RESULT		m_result;
    void *                  m_object;
    CCCallFuncN *           m_callback;
	CCLayerColor *          m_mask;
public:
    GAMEUI_Dialog * getNextDialog() { return m_next; }
    void setNextDialog(GAMEUI_Dialog * dialog);
    GUI_DIALOG_RESULT getHandleResult() { return m_result; }
    void setHandleResult(GUI_DIALOG_RESULT result) { m_result = result; }
    void * getCustomObject() { return m_object; }
    void setCustomObject(void * object) { m_object = object; }
    //
    //void addMask();
    //void removeMask();
    void setHandleCallback(CCCallFuncN * callback);
    void handleDialog();

    virtual void transitionIn(CCCallFunc* finishAction);
    virtual void transitionOut(CCCallFunc* finishAction);
    virtual void transitionInDone(){}
    virtual void transitionOutDone(){}
};
//
//@interface GAMEUI_Dialog : GAMEUI {
//	CCLayerColor *		m_mask;
//	GAMEUI_Dialog	*		m_next; 
//	GUI_DIALOG_RESULT		m_result;
//    id                      m_object;
//} 
//@property (nonatomic, readwrite, retain)	GAMEUI_Dialog * next;
//@property (readwrite, assign)				GUI_DIALOG_RESULT result;
//@property (retain)                          id object;
//
//- (void) addMask;
//- (void) removeMask;
//- (void) setHandleCallback:(id)target selector:(SEL)selector; 
//- (void) handleDialog; 
//@end
