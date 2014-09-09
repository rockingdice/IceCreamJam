//
//  GAMEUI_Scene.h
//  CarGame
//
//  Copyright 2012 Playforge Games LLC. All rights reserved.
//  Created by James Lee on 11-8-17.
//  Copyright 2011 RockingDice. All rights reserved.
//

#include "GAMEUI.h"

/*!
 
 GAMEUI_Scene
 
 */
typedef enum {
	WINDOW_STATABLE,
	WINDOW_TRANSITION_IN,
	WINDOW_TRANSITION_OUT,
}GUI_WINDOW_TRANS_STATE;

class GAMEUI_Window;
class GAMEUI_Dialog;
class GAMEUI_Scene : public CCLayer {
private:
    GAMEUI_Scene();
    ~GAMEUI_Scene();

    GAMEUI_Dialog *         m_dialog;
    GAMEUI_Window *         m_ui;
    
    GAMEUI_Window *         m_transitionUi;
    GUI_WINDOW_TRANS_STATE  m_transitionState;
    
    CCCallFuncO *           m_noUiCallback;
    void *                  m_noUiObject;
    
    CCLayerColor *          m_windowMask;
    
public:
    static GAMEUI_Scene * uiSystem();
    GAMEUI_Window * getWindow() { return m_ui; }
    GAMEUI_Dialog * getDialog() { return m_dialog; }
    GAMEUI * getCurrentUI();
    void setNoUiCallback(CCCallFuncO * callback);
    void setNoUiObject(void * object) { m_noUiObject = object; }
    void * getNoUiObject() { return m_noUiObject; }
    void noUiCallback(CCObject * object);

    void nextWindow(GAMEUI_Window * next);
    bool prevWindow();
    void closeAllWindows();
    void forceCloseAllWindows();

    void selDialogClosed(GAMEUI_Dialog * dialog);
    void addDialog(GAMEUI_Dialog * dialog);
    void closeDialog();
    void transitionInUiDone(GAMEUI_Window * window);
    void transitionOutUiDone(GAMEUI_Window * ui);
    
    void hideMask();
    void keyBackClicked();
    
    virtual void OnEnter();

    CREATE_FUNC(GAMEUI_Scene);
};
 
