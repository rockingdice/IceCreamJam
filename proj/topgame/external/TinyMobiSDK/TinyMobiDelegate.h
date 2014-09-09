//
//  TinyMobiDelegate.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-8-1.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TinyMobiDelegate <NSObject>

@optional

//the pop-up advertisement will have a yes/no interface.
//If the user selects yes then the pop-up advertisement will be displayed,
//otherwise it will continue to wait for input
- (BOOL) shouldDisplayPop;

//tinyWall Tracking
//Events
- (void) tinyWallWillInstall;
- (void) tinyWallWillPlay;
- (void) tinyWallDidDisplay;
- (void) tinyWallDidDismiss;

//tinyPopup Tracking
//Events
- (void) tinyPopDidDisplay;
- (void) tinyPopDidDismiss;
- (void) tinyPopWillInstall;
- (void) tinyPopWillPlay;
@end