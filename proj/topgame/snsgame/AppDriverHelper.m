//
//  ChartBoostHelper.m
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "AppDriverHelper.h"
#import "SystemUtils.h"
#import "ADCPowerWallViewController.h"
#import "StringUtils.h"
#import "SNSAlertView.h"
#import "smPopupWindowNotice.h"
#import "smPopupWindowQueue.h"

@implementation AppDriverHelper

static AppDriverHelper *_gAppDriverHelper = nil;

+ (AppDriverHelper *) helper
{
    if(!_gAppDriverHelper) {
        _gAppDriverHelper = [[AppDriverHelper alloc] init];
        // [_gChartBoostHelper initSession];
    }
    return _gAppDriverHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO; siteID = nil;
    }
    return self;
}

- (void) initSession
{
    if(isInitialized) return;
    
	siteID = [[SystemUtils getSystemInfo:@"kAppDriverSiteID"] retain];
	if(!siteID) return;
    isInitialized = YES;
    siteKey = [[SystemUtils getSystemInfo:@"kAppDriverSiteKey"] retain];
    mediaID = [[SystemUtils getSystemInfo:@"kAppDriverMediaID"] retain];
    
    
    _powerWallViewController = [[ADCPowerWallViewController initWithSiteId:siteID
                                                                   siteKey:siteKey
                                                                   mediaId:mediaID 
                                                            userIdentifier:[SystemUtils getCurrentUID]
                                                                useSandBox:NO 
                                                                 useReward:YES
                                           powerWallViewControllerDelegate:self] retain];
    
}

- (void) showOffer
{
    if(!isInitialized)
        [self initSession];
    // Load interstitial
    if(!siteID) return;
    NSLog(@"%s: siteID:%@ siteKey:%@ mediaID:%@",__func__, siteID, siteKey, mediaID);
    UIViewController *root = [SystemUtils getAbsoluteRootViewController];
    if(!root) return;
    [ADCPowerWallViewController showPowerWallViewFromViewController:root 
                                                             siteId:siteID
                                                            siteKey:siteKey
                                                            mediaId:mediaID
                                                     userIdentifier:[SystemUtils getCurrentUID] 
                                                          useReward:YES 
                                                         useSandBox:NO];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kAppDriverShowTime"];
}


// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy
{
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kAppDriverShowTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kAppDriverCheckTime"] intValue];
    if(checkTime>showTime+1) return;
    [self initSession];
    [self checkPoints];
}


-(void)checkPoints
{
    [self initSession];
    SNSLog(@"start checking limei points");
	// This method requests the tapjoy server for current virtual currency of the user.
	// if([TapjoyConnect 
	// [TapjoyConnect getTapPoints];
    [_powerWallViewController getScore];
    
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kAppDriverCheckTime"];
}

#pragma mark ADCADCPowerWallViewControllerDelegate

-(void)getScoreFinished:(CGFloat)score
{
    int rate = [[SystemUtils getSystemInfo:@"kAppDriverLeafRate"] intValue];
    if(rate<=0) rate = 1;
	int amount = score/rate;
    SNSLog(@"get %i points(%.2lf)", amount, score);
	if (amount <= 0) return;
	// int localAmount = [SystemUtils getTapjoyPoint];
	// TODO: add log
    
	[SystemUtils addGameResource:amount ofType:kGameResourceTypeLeaf];
    // [[LmmobAdWallSDK defaultSDK] ScoreSubstract:amount*rate];
    [_powerWallViewController reduceScore:amount*rate];
    
    NSString *leafName = [SystemUtils getLocalizedString:@"CoinName2"];
    if(amount>1) leafName = [StringUtils getPluralFormOfWord:leafName];
	NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], amount, leafName];
	// show notice
	smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
	swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"content", @"", @"action", @"0", @"prizeCoin", @"0", @"prizeLeaf", nil];
	[[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:0];
    [swqAlert release];
    
}

#pragma mark -

@end
