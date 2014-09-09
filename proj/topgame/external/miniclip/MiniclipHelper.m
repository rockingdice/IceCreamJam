//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "MiniclipHelper.h"
//#import "TapjoyConnect.h"
#import "SystemUtils.h"
//#import "smPopupWindowNotice.h"
//#import "smPopupWindowQueue.h"
// #import "AudioPlayer.h"
//#import "cocos2d.h"
//#import "SNSWebWindow.h"
#import "StringUtils.h"
//#import "ZFGuiLayer.h"
//#import "GameDefines.h"
//#import "SimpleAudioEngine.h"
//#import "ZFSoundIDs.h"
#import "SNSAlertView.h"
#import "smPopupWindowNotice.h"
#import "smPopupWindowQueue.h"
#import "MCRate.h"
#import "MCPostman.h"

static MiniclipHelper *_gMiniclipHelper = nil;

@implementation MiniclipHelper

+(MiniclipHelper *)helper
{
	@synchronized(self) {
		if(!_gMiniclipHelper) {
			_gMiniclipHelper = [[MiniclipHelper alloc] init];
		}
	}
	return _gMiniclipHelper;
}

-(id)init
{
    self = [super init];
    
	isSessionInitialized = NO;
	return self;
}

-(void)dealloc
{
	[super dealloc];
}

-(void) initSession:(NSDictionary *)options
{
	if(isSessionInitialized) return;

    NSString *appID = [SystemUtils getSystemInfo:@"kiTunesAppID"];
    if(appID==nil) return;
    [MCRate startWithDelegate:self andAppId:appID];
    
    
#ifdef DEBUG
    [MCPostman setSandBox:YES]; // YES for DEBUG builds and NO for AppStore builds
    [MCPostman setShouldLog:YES]; // will log a lot of debug information into the console. Useful during implementation
#else
    [MCPostman setSandBox:NO];
    [MCPostman setShouldLog:NO]; // will log a lot of debug information into the console. Useful during implementation
#endif
    [MCPostman setLaunchOptions:options]; // the dictionary that is provided in [ application: didFinishLaunchingWithOptions:]
    [MCPostman setShowBadge:YES];
    [MCPostman startWithDelegate:self]; // should not be nil
    
    isSessionInitialized = YES;
	
}
- (BOOL) showPopup
{
	if(!isSessionInitialized) return NO;
    return [MCRate showRatePopup];
}

- (BOOL) showUrgentBoard
{
    return [MCPostman showUrgentBoard];
}


#pragma mark MCRateDelegate
// Will be called to customize title
-(NSString*)titleText
{
    NSString *gameName = [SystemUtils getLocalizedString:@"GameName"];
    
    return [NSString stringWithFormat:@"Love %@?", gameName];
}

// Will be called to customize message
-(NSString*)messageText
{
    return @"Please rate it on the App Store.";
}

// Will be called to customize cancel button text
-(NSString*)cancelText
{
    return @"Not yet";
}

// Will be called to customize confirm button text
-(NSString*)rateText
{
    return @"Rate it!";
}

#pragma mark -

#pragma mark MCPostmanDelegate
// Will be called if newsfeed board is about to be displayed
- (void)boardWillAppear
{
    
}

// Will be called if newsfeed board was displayed
- (void)boardDidAppear
{
    
}

// Will be called if newsfeed board is about to be dismissed
- (void)boardWillDisappear
{
    
}

// Will be called if newsfeed board is about to be dismissed
- (void)boardDidDisappear
{
    
}

// Will be called if newsfeed becomes available or unavailable
// User can show or hide news button when this function is called
- (void)availabilityChanged:(BOOL)availability
{
    
}

// Will be sent if new message is received
- (void)nrOfUnreadMessagesChanged:(int)nrOfUnreadMessages
{
    
}

// Will be called if urgent message is received and should be shown
// Urgent message is shown once per session and no earlier than after a certain
// delay from session start. The delay is defined in server-side.
// If NO is returned, library retries the call after every 20 seconds.
- (BOOL)shouldShowUrgentMessage
{
    return [SystemUtils getInterruptMode];
}

// Sent to the application in the beginning of launch when database records indicate
// more recent version is available than the usre currently has.
- (void)newApplicationVersionAvailable:(NSString*)version
{
    
}


#pragma mark -

@end
