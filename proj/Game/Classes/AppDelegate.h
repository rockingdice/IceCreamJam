//
//  FarmManiaAppDelegate.h
//  FarmMania
//
//  Created by  James Lee on 13-5-1.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//

#ifndef  _APP_DELEGATE_H_
#define  _APP_DELEGATE_H_

#include "CCApplication.h"
typedef enum kResolutionType {
    kResolutionType_None = -1,
    kResolutionType_0_5x = 0,
    kResolutionType_1x,
    kResolutionType_2x,
    kResolutionType_4x,
}kResolutionType ;
#define RES_FOLDER "V170"
/**
@brief    The cocos2d Application.

The reason to implement with private inheritance is to hide some interface details of CCDirector.
*/
class  AppDelegate : private cocos2d::CCApplication
{
public:
    AppDelegate();
    virtual ~AppDelegate();

    /**
    @brief    Implement CCDirector and CCScene init code here.
    @return true    Initialize success, app continue.
    @return false   Initialize failed, app terminate.
    */
    virtual bool applicationDidFinishLaunching();

    /**
    @brief  The function is called when the application enters the background
    @param  the pointer of the application instance
    */
    virtual void applicationDidEnterBackground();

    /**
    @brief  The function is called when the application enters the foreground
    @param  the pointer of the application instance
    */
    virtual void applicationWillEnterForeground();
    
    void initResPath();
    
    void initialize();
    
    kResolutionType getResolutionType();
    
    const char * getResolutionDir();
    
};

#endif // _APP_DELEGATE_H_

