//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "AdjustHelper.h"
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
#import "Adjust.h"

static AdjustHelper *_gAdjustHelper = nil;

@implementation AdjustHelper

+(AdjustHelper *)helper
{
	@synchronized(self) {
		if(!_gAdjustHelper) {
			_gAdjustHelper = [[AdjustHelper alloc] init];
		}
	}
	return _gAdjustHelper;
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

-(void) initSession
{
	if(isSessionInitialized) return;
    isSessionInitialized = YES;

    NSString *appToken = [SystemUtils getSystemInfo:@"kAdjustAppToken"];
    if(appToken==nil || [appToken length]<=3) return;
    
    [Adjust appDidLaunch:appToken];
#ifdef DEBUG
    // [Adjust setLogLevel:AILogLevelInfo];
    [Adjust setEnvironment:AIEnvironmentSandbox];
#else
    [Adjust setEnvironment:AIEnvironmentProduction];
#endif
    
}

- (void) trackRevenue:(int) price ofItem:(NSString *)itemID
{
    [Adjust trackRevenue:price forEvent:itemID];
}


@end
