//
//  GAMEUI_Scene.m
//  CarGame
//
//  Copyright 2012 Playforge Games LLC. All rights reserved.
//  Created by James Lee on 11-8-17.
//  Copyright 2011 RockingDice. All rights reserved.
//

#include "GAMEUI_Scene.h"
#include "GAMEUI_Dialog.h"
#include "GAMEUI_Window.h"
#include "OBJCHelper.h"

static GAMEUI_Scene * m_sharedInstance = NULL;

GAMEUI_Scene::GAMEUI_Scene() :
    m_transitionState(WINDOW_STATABLE),
    m_transitionUi(NULL),
    m_ui(NULL),
    m_noUiCallback(NULL),
    m_noUiObject(NULL),
    m_dialog(NULL),
    m_windowMask(NULL)
{
    m_windowMask = CCLayerColor::create(ccc4(0, 0, 0, 0x80));
    m_windowMask->retain();
    addChild(m_windowMask, -1);
    m_windowMask->setVisible(false);
}

GAMEUI_Scene::~GAMEUI_Scene()
{
    
}

GAMEUI_Scene * GAMEUI_Scene::uiSystem()
{
    if (!m_sharedInstance) {
        m_sharedInstance = new GAMEUI_Scene();
    }
    return m_sharedInstance;
} 

#pragma mark -
#pragma mark ui
GAMEUI * GAMEUI_Scene::getCurrentUI()
{
    if (m_dialog) {
        return m_dialog;
    }
    else if (m_ui) {
        return m_ui;
    }
    else {
        return NULL;
    }
}

void GAMEUI_Scene::nextWindow(GAMEUI_Window *next)
{
    if (next == m_ui && next != NULL) {
        return;
    }
    next->retain();
    
	GAMEUI_Window* last = m_ui;
    m_windowMask->setVisible(true);
    m_windowMask->runAction(CCFadeTo::create(0.2f, 0x80));
    
	CCAssert(next, "none next window!");
    
	m_ui			= next; 
	m_ui->setLastUi(last);
	next->setState(GUI_WINDOW_ACTIVE);
	if (m_transitionState == WINDOW_STATABLE) {
		if (last) {
			if (last->getState() == GUI_WINDOW_ACTIVE) {
				//current window is active, and stable, transition it out.
				//make it idle
                CCCallFuncO * actionCallback = CCCallFuncO::create(this, callfuncO_selector(GAMEUI_Scene::transitionOutUiDone), last);
                last->setState(GUI_WINDOW_IDLE);
				m_transitionState = WINDOW_TRANSITION_OUT;
				m_transitionUi = last;
                last->pause();
                last->transitionOut(actionCallback);
			}
			else {
				CCAssert(0, "the window is active, but transitioning!");
			}
		}
		else {
			// no window
			// just move in the new one
            
            //[self switchUi:nil toUi:next];
			m_transitionUi = next;
            addChild(m_transitionUi);
            CCCallFuncO * actionCallback = CCCallFuncO::create(this, callfuncO_selector(GAMEUI_Scene::transitionInUiDone), next);
            next->setState(GUI_WINDOW_ACTIVE);
            next->setVisible(true);
            m_transitionState = WINDOW_TRANSITION_IN;
            next->transitionIn(actionCallback);
		}
        
        
	}
	else {
		if (m_transitionState == WINDOW_TRANSITION_OUT) {
			//there is a window transitioning out, it will trigger transition out done when finished.
			//already changed next window to new one, so do nothing.
			//NSLog(@"%@ is transitioning out. next window is : %@", [m_transitionUi class], [m_ui class]);
		}
		else {
			//there is a window transitioning in, just make it idle, and trigger its done callback.
			//so the window will be removed immediately. And next window will be shown.
			//NSLog(@"%@ is transitioning in. next window is : %@", [m_transitionUi class], [m_ui class]);
			m_transitionUi->setState(GUI_WINDOW_IDLE);
            transitionOutUiDone(m_transitionUi);
		}
        
	}
	
}

bool GAMEUI_Scene::prevWindow()
{
    
    GAMEUI_Window*  current = m_ui;
	GAMEUI_Window*  prev = m_ui->getLastUi();
    bool hasParent  = prev != NULL;
     
	if (m_transitionState == WINDOW_STATABLE) {
		if (!current) {
			// there is no window on the screen, do nothing.
			//NSLog(@"Check windows order!");
			return hasParent;
		}
		else {
			//stable window on the screen, transition out it
            m_ui = prev;
            m_transitionUi = current;
            m_transitionState = WINDOW_TRANSITION_OUT;
            
            CCCallFuncO * actionCallback = CCCallFuncO::create(this, callfuncO_selector(GAMEUI_Scene::transitionOutUiDone), current);
            current->setState(GUI_WINDOW_ABANDON);
            current->pause();
            current->transitionOut(actionCallback);
            if (prev) {
                prev->setState(GUI_WINDOW_ACTIVE);
            }
		}
	}
	else {
        if (!m_transitionUi) {
            return false;
        }
		//there is a window transitioning
		if (m_transitionState == WINDOW_TRANSITION_IN) {
            //1 is trans-in. make 1 in, then 1 begins out
			//finish current action
            GAMEUI_Window * transitionUi = m_transitionUi;
            
            m_transitionUi->stopAllActions();
            transitionInUiDone(m_transitionUi);
            m_ui = prev;
            
            m_transitionUi = transitionUi;
            
            CCCallFuncO * actionCallback = CCCallFuncO::create(this, callfuncO_selector(GAMEUI_Scene::transitionOutUiDone), m_transitionUi);
            m_transitionUi->setState(GUI_WINDOW_IDLE);
            m_transitionState = WINDOW_TRANSITION_OUT;
            m_transitionUi->pause();
            m_transitionUi->transitionOut(actionCallback);        
		}
		else {
			//1 is trans-out. make 1 out, 2 in, then 2 begins out
            //next window is 2
            //1 out
            m_transitionUi->stopAllActions();
            transitionOutUiDone(m_transitionUi);                         
            if (m_transitionState == WINDOW_TRANSITION_IN) {
                //2 in
                GAMEUI_Window * transitionUi = m_transitionUi;
                
                m_transitionUi->stopAllActions();
                transitionInUiDone(m_transitionUi);
                
                m_ui = prev;
                //2 begins out
                m_transitionUi = transitionUi;
                m_transitionState = WINDOW_TRANSITION_OUT;
                
                CCCallFuncO * actionCallback = CCCallFuncO::create(this, callfuncO_selector(GAMEUI_Scene::transitionOutUiDone), m_transitionUi);
                m_transitionUi->setState(GUI_WINDOW_ABANDON);
                m_transitionUi->pause();
                m_transitionUi->transitionOut(actionCallback);
                
            }
            else {
                //do nothing ,since there is no windows to prev!
            }
			
		}
        
	}
    return hasParent;
}

void GAMEUI_Scene::closeAllWindows()
{
    bool hasParentWindows = true;
    while (hasParentWindows) {
        hasParentWindows = prevWindow();
    }
}

void GAMEUI_Scene::forceCloseAllWindows()
{
	GAMEUI_Window*  prev = m_ui->getLastUi();
    if (m_ui) {
        removeChild(m_ui, true);
        m_ui->release();
    }
    if (prev) {
        removeChild(prev, true);
        prev->release();
    }
    m_ui = NULL;
    hideMask();
}

void GAMEUI_Scene::transitionInUiDone(GAMEUI_Window *window)
{
    if (m_dialog == NULL) {
        m_ui->resume();
    }
    m_transitionUi = NULL;
    m_transitionState = WINDOW_STATABLE;
}

void GAMEUI_Scene::transitionOutUiDone(GAMEUI_Window *ui)
{
    if (!m_dialog) {
//        [self switchUi:ui toUi:m_ui];
    }
    
    GUI_WINDOW_STATE state = ui->getState();
	if (state == GUI_WINDOW_IDLE) {
		//nextWindow:
        removeChild(ui, false);
	}
	else if (state == GUI_WINDOW_ABANDON) {
		//prevWindow:
        if (ui->isCached()) {
            removeChild(ui, false);
        }
        else {
            removeChild(ui, true);
        }
        ui->release();
	}
	
	if (m_ui) {
		// transition next window in.
		m_transitionUi = m_ui;
        addChild(m_ui);
        CCCallFuncO * actionCallback = CCCallFuncO::create(this, callfuncO_selector(GAMEUI_Scene::transitionInUiDone), m_transitionUi);
        m_transitionUi->setVisible(true);
        m_transitionState = WINDOW_TRANSITION_IN;
        m_transitionUi->transitionIn(actionCallback);
	}
	else {
        m_transitionUi = NULL;
		m_transitionState = WINDOW_STATABLE;
        if (!m_dialog) {
            if (m_noUiCallback) {
                noUiCallback(NULL);
            }
            
            CCCallFunc * callback = CCCallFunc::create(this, callfunc_selector(GAMEUI_Scene::hideMask));
            CCFadeTo * fade = CCFadeTo::create(0.2f, 0);
            CCSequence * seq = CCSequence::create(fade, callback, NULL);
            m_windowMask->setOpacity(0x80);
            m_windowMask->runAction(seq);
        }
        else {
            m_dialog->resume();
        }
	}
}

void GAMEUI_Scene::setNoUiCallback(cocos2d::CCCallFuncO *callback)
{
    if (m_noUiCallback) {
        m_noUiCallback->release();
        m_noUiCallback = NULL;
    }
    m_noUiCallback = callback;
    m_noUiCallback->retain();
}


void GAMEUI_Scene::noUiCallback(CCObject * object)
{
    if (m_noUiCallback) { 
        m_noUiCallback->execute();
        m_noUiCallback->release();
        m_noUiCallback = NULL;
    }
}

void GAMEUI_Scene::hideMask()
{
    m_windowMask->setVisible(false);
}
 
#pragma mark -
#pragma mark dialog

void GAMEUI_Scene::selDialogClosed(GAMEUI_Dialog *dialog)
{
    
	GAMEUI_Dialog * next = dialog ? dialog->getNextDialog() : NULL;
	
	if ( dialog )
	{
		if ( next )
		{
//            [self switchUi:dialog toUi:next];
			m_dialog = next;
            m_dialog->resume();
            addChild(next, next->getZOrder());

            CCCallFunc * finishAction = CCCallFunc::create(m_dialog, callfunc_selector(GAMEUI_Dialog::transitionInDone));
            next->transitionIn(finishAction);
		}
		else if ( m_dialog == NULL )
		{
			// Closing the last dialog sets it back to the last state if it hasn't
			// already been set to a non-idle state. Only do this if there isn't
			// a ui open.
//            [self switchUi:dialog toUi:m_ui];
			if ( m_ui )
			{
                m_ui->resume();
			}
            else {
                if (m_noUiCallback)
                {
                    noUiCallback(NULL);
                }
                
                CCCallFunc * callback = CCCallFunc::create(this, callfunc_selector(GAMEUI_Scene::hideMask));
                CCFadeTo * fade = CCFadeTo::create(0.2f, 0);
                CCSequence * seq = CCSequence::create(fade, callback, NULL);
                m_windowMask->setOpacity(0x80);
                m_windowMask->runAction(seq);
            }
		}
		
        dialog->handleDialog();
        removeChild(dialog, true);
	}
}

void GAMEUI_Scene::addDialog(GAMEUI_Dialog *dialog)
{
    
    m_windowMask->setVisible(true);
    CCFadeTo * fade = CCFadeTo::create(0.2f, 0x80);
    m_windowMask->runAction(fade);
	if ( m_dialog == NULL )
	{
		// Set this as the current dialog
		m_dialog			= dialog;
        
		if ( m_ui )
		{
            m_ui->pause();
		}
//        [self switchUi:m_ui toUi:dialog];
		// Show it now
        int z = m_dialog->getZOrder();
        addChild(m_dialog, z+2);
        m_windowMask->setZOrder(z+1);
        

        CCCallFunc * finishAction = CCCallFunc::create(m_dialog, callfunc_selector(GAMEUI_Dialog::transitionInDone));
        m_dialog->transitionIn(finishAction);
	}
	else
	{
		GAMEUI_Dialog *	current	= m_dialog;
		
		// Find the first dialog with no linked dialog
		while (		current != NULL
			   &&	current->getNextDialog() != NULL
			   )
		{
			current	= current->getNextDialog();
		}
		
		// Store this as a linked dialog for later
		current->setNextDialog(dialog);
	}
}

void GAMEUI_Scene::closeDialog()
{
    m_windowMask->setZOrder(-1);
	GAMEUI_Dialog* current = m_dialog;
	GAMEUI_Dialog* next    = m_dialog ? m_dialog->getNextDialog() : NULL;
	if ( current )
	{
		m_dialog        = NULL;
		
		// Don't transition if another dialog is just going to open up, only
		// transition out on the last dialog.
		if ( next == NULL )
		{
			CCCallFuncO * dialogClosed	= CCCallFuncO::create(this, callfuncO_selector(GAMEUI_Scene::selDialogClosed), current);
            current->transitionOut(dialogClosed);
		}
		else
		{
            selDialogClosed(current);
		}
	}
}

void GAMEUI_Scene::OnEnter()
{
    CCLayer::onEnter();
}

void GAMEUI_Scene::keyBackClicked()
{
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
    CCLog("keyBackClicked--called");
#endif
}

//
//- (void) reset
//{
//	GAMEUI_Window * ui = m_ui;
//	while (ui != nil) {
//		GAMEUI_Window * lastUi = ui.lastUi;
//		[ui release];
//		ui = lastUi;
//	}
//    [self removeAllChildrenWithCleanup:YES];
//    m_ui = nil;
//    m_dialog = nil;
//}
//
//#pragma mark - command
//- (void) switchUi:(GAMEUI *) ui toUi:(GAMEUI *) nextUi
//{
//    //    NSLog(@"from %@, to %@", ui, nextUi);
//    GAMEUI_Command * command = [self currentCommand];
//    if (command) {
//        [command callbackOnChangeUi:ui toUi:nextUi];
//    }
//}
//
//- (void) checkAllCommandsAvailable
//{
//    //SHOULD BE ORDERED CHECK!
//    GAMEUI_Command * command = [self currentCommand];
//    while (command && ![command checkAvailable]) {
//        [self popCommand];
//        command = [self currentCommand];
//    }
//    
//    //    NSMutableArray * willDelete = [NSMutableArray array];
//    //    for (int i=0; i<[m_commandList count]; i++) {
//    //        GAMEUI_Command * command = [m_commandList objectAtIndex:i];
//    //        if (![command checkAvailable]) {
//    //            [willDelete addObject:command];
//    //        }
//    //    }
//    //
//    //    for (int i=0; i<[willDelete count]; i++) {
//    //        GAMEUI_Command * command = [willDelete objectAtIndex:i];
//    //        [m_commandList removeObject:command];
//    //    }
//}
//
//- (GAMEUI_Command *) currentCommand
//{
//    if ([m_commandList count]!=0) {
//        return [m_commandList objectAtIndex:0];
//    }
//    return nil;
//}
//
//- (void) pushCommand:(GAMEUI_Command *)command
//{
//    if (![self currentCommand]) {
//        [command callbackOnExec:self];
//    }
//    [m_commandList addObject:command];
//}
//
//- (void) popCommand
//{
//    GAMEUI_Command * command = [[self currentCommand] retain];
//    [m_commandList removeObject:command];
//    
//    if (command) {
//        [command callbackOnComplete:self];
//        [command release];
//    }
//    
//    command = [self currentCommand];
//    if (command) {
//        [command callbackOnExec:self];
//    }
//}
//
//- (void) completeCommand:(int)commandID withObject:(id)object
//{
//    GAMEUI_Command * command = [self currentCommand];
//    if ([command commandID] == commandID) {
//        if ([command isComplete:object]) {
//            [self popCommand];            
//        }
//    }
//} 
//
//- (void) cleanAllCommands
//{
//    [m_commandList removeAllObjects];
//}
//
//@end
