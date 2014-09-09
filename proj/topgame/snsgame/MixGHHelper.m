//
//  ChartBoostHelper.m
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "MixGHHelper.h"
#import "MIXView.h"
#import "SystemUtils.h"

@implementation MixGHHelper

static MixGHHelper *_gMixGHHelper = nil;

+ (MixGHHelper *) helper
{
    if(!_gMixGHHelper) {
        _gMixGHHelper = [[MixGHHelper alloc] init];
        // [_gChartBoostHelper initSession];
    }
    return _gMixGHHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO;
    }
    return self;
}

- (void) initSession
{
    if(isInitialized) return;
    SNSLog(@"start mixguohead sdk");
	NSString *appID = [SystemUtils getSystemInfo:@"kMixGuoHeadKey"];
	if(!appID || [appID length]<3) return;
    isInitialized = YES;
    BOOL testmode = NO;
#ifdef DEBUG
    // testmode = YES;
#endif
    [MIXView initWithID:appID setTestMode:testmode];
    // [self loadCacheOffer];
	
}


- (void) showPopupOffer
{
    if(!isInitialized)
        [self initSession];
    UIViewController *root = [SystemUtils getRootViewController];
    [MIXView showAdWithDelegate:self withPlace:@"default" viewController:root];
}



#pragma mark MIXViewDelegate
- (void)mixViewDidFailToShowAd:(MIXView *)view
{
    //加载推广橱窗失败时调用
}
- (void)mixViewDidShowAd:(MIXView *)view
{
    //加载推广橱窗成功时调用
}
- (void)mixViewDidClickedAd:(MIXView *)view
{
    //推广橱窗点击出现内容窗口时调用
}
- (void)mixViewDidClosed:(MIXView *)view
{
    SNSLog(@"mixViewDidClosed");
    //    CCLOG("mixViewDidClosed");
    //推广橱窗的关闭按钮被点击时调用
    //如果出现广告时 您的游戏是暂停状态，那么可以在广告时恢复游戏状态，代码如下：
}
- (void)mixViewNoAdWillPresent:(MIXView *)view
{
    //没有推广橱窗返回时调用
    SNSLog(@"no ad found");
}



#pragma mark -

@end
