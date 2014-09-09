//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "AdxHelper.h"
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

static AdxHelper *_gAdxHelper = nil;

@implementation AdxHelper

+(AdxHelper *)helper
{
	@synchronized(self) {
		if(!_gAdxHelper) {
			_gAdxHelper = [[AdxHelper alloc] init];
		}
	}
	return _gAdxHelper;
}

-(id)init
{
    self = [super init];
    
	isSessionInitialized = NO; tracker = nil; isFirstTimeLaunch = YES;
	return self;
}

-(void)dealloc
{
	[super dealloc];
}

-(void) initSession
{
	if(isSessionInitialized) return;

    NSString *adxScheme = [SystemUtils getSystemInfo:@"kAdxURLScheme"];
    NSString *adxClientID = [SystemUtils getSystemInfo:@"kAdxClientID"];
    NSString *appID = [SystemUtils getSystemInfo:@"kiTunesAppID"];
    if(adxScheme==nil || [adxScheme length]<3) return;
    if(adxClientID==nil || [adxClientID length]<3) return;
    if(appID==nil || [appID length]<3) return;
    
    tracker = [[AdXTracking alloc] init];
    [tracker setURLScheme:adxScheme];
    [tracker setClientId:adxClientID];
    [tracker setAppleId:appID];
    int isUpdated = [[SystemUtils getNSDefaultObject:@"kAdxUpdate"] intValue];
    if(isUpdated==0) {
        [SystemUtils setNSDefaultObject:@"1" forKey:@"kAdxUpdate"];
        int saveID = [SystemUtils getSaveID];
        if(saveID>0) [tracker isUpgrade:TRUE];
    }
#ifdef MINICLIP_DEBUG
    [tracker useQAServerUntilYear:2014 month:9 day:1];
#endif
    // [tracker setEventParameter:@"upgrade" withValue:@"1"];
    [tracker reportAppOpen];
    
    isSessionInitialized = YES;
	
}

-(BOOL) handleOpenURL:(NSURL *)url
{
    if(tracker==nil) return NO;
    NSDictionary *dict = [StringUtils parseURLQueryStringToDictionary:[url query]];
    NSString *ADXID = [dict objectForKey:@"ADXID"];
    if (ADXID) {
        [tracker sendEvent:@"DeepLinkLaunch" withData:ADXID];
        return [tracker handleOpenURL:url];
    }
    return false;
}

-(void) reportAppOpen
{
    if(tracker!=nil) {
        [tracker reportAppOpen];
        [tracker sendEvent:@"Launch" withData:@""];
        NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
        NSString *installVersion = [SystemUtils getNSDefaultObject:@"ADXInstallVersion"];
        if (!installVersion || ![installVersion isEqualToString:version]) {
            [SystemUtils setNSDefaultObject:version forKey:@"ADXInstallVersion"];
            [tracker sendEvent:@"Install" withData:@""];
        }
    }
}

- (void) trackPurchase:(NSString *)price currency:(NSString *)currency withTransaction:(SKPaymentTransaction *)transaction sandbox:(int)isSandbox
{
    if ([SystemUtils isJailbreak]) {
        return;
    }
    if(tracker==nil) return;
    NSString *event = @"Sale";
    if(isSandbox==1) event = @"TestSale";
    // [tracker sendEvent:@"Sale" withData:price];
    [tracker sendAndValidateSaleEvent:transaction withValue:price andCurrency:currency andCustomData:@""];
}

- (void) trackPurchase:(NSString *)price
{
    if ([SystemUtils isJailbreak]) {
        return;
    }

    if(tracker==nil) return;
    [tracker sendEvent:@"Sale" withData:price];
}


@end
