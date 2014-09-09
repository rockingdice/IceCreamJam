//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "MobiSageHelper.h"
#import "SystemUtils.h"
#import "StringUtils.h"
#import "SNSAlertView.h"
#import "smPopupWindowNotice.h"
#import "smPopupWindowQueue.h"

enum {
    OFFER_STATUS_NONE = 0,
    OFFER_STATUS_LOADING = 1,
    OFFER_STATUS_READY   = 2,
    OFFER_STATUS_LOADFAIL  = 3,
    OFFER_STATUS_SHOWING   = 4,
};

static MobiSageHelper *_gMobiSageHelper = nil;

@implementation MobiSageHelper
@synthesize owViewController = _owViewController;
@synthesize floatWindow;

+(MobiSageHelper *)helper
{
	@synchronized(self) {
		if(!_gMobiSageHelper) {
			_gMobiSageHelper = [[MobiSageHelper alloc] init];
		}
	}
	return _gMobiSageHelper;
}

-(id)init
{
    self = [super init];
    _owViewController = nil;
	isSessionInitialized = NO; stAppKey = nil; stFloatAppKey = nil;
	return self;
}

-(void)dealloc
{
    self.owViewController = nil;
    [stAppKey release];
    [stFloatAppKey release];
    [floatWindow release];
	[super dealloc];
}

-(void) initSession
{
	if(isSessionInitialized) return;

    stAppKey = [SystemUtils getGlobalSetting:@"kMobiSagePubID"];
    if(!stAppKey || [stAppKey length]<3) stAppKey = [SystemUtils getSystemInfo:@"kMobiSagePubID"];
    if(!stAppKey || [stAppKey length]<3) return;
    
    //插屏积分需要单独的KEY
    stFloatAppKey = [SystemUtils getGlobalSetting:@"kMobiSageFloatPubID"];
    if(!stFloatAppKey || [stFloatAppKey length]<3) stFloatAppKey = [SystemUtils getSystemInfo:@"kMobiSageFloatPubID"];
    if(!stFloatAppKey || [stFloatAppKey length]<3) return;
    
    stSlotAppKey = [SystemUtils getGlobalSetting:@"kMobiSageFloatSlotID"];
    if(!stSlotAppKey || [stSlotAppKey length]<3) stSlotAppKey = [SystemUtils getSystemInfo:@"kMobiSageFloatSlotID"];
    if(!stSlotAppKey || [stSlotAppKey length]<3) return;
    
    isSessionInitialized = YES; pendingCoins = 0;
    [stAppKey retain];
    [stFloatAppKey retain];
    
    //1.PublisherID的生效需要时间(未生效的pid是不显示广告的,生效时间一般在申请后20分钟),测试请用当前的ID(a8300de238a94ae0a7788e75b56d938b).测试完成后更换自己应用申请的PID.
    //2.实例化对象一定要在程序开始时初始化,并且网络畅通.因为需要读取网络配置开关.否则加载广告会失败!
    _owViewController=[[MobiSageJoyViewController  alloc ] initWithPublisherID:stAppKey];
    //插屏广告设置PublisherID,和积分墙的PublisherID是不同的,需要单独申请.
    [[MobiSageManager getInstance]setPublisherID:stFloatAppKey];
    
    
#ifdef DEBUG
    _owViewController.disableStoreKit=YES;//未上线的应用内下载app会失败!测试请设置disableStoreKit=YES,跳出到App Store下载.
#endif
    self.owViewController.delegate = self;

    interstitialStatus = OFFER_STATUS_NONE; offerStatus = OFFER_STATUS_NONE;
    [self loadInterstitial];
    [self loadOffer];
    [self checkPointsLazy];
}





// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy
{
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kMobiSageShowTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kMobiSageCheckTime"] intValue];
    if(checkTime>showTime+1) return;
    [self initSession];
    [self checkPoints];
}

- (void) loadOffer
{


}

- (void) loadInterstitial
{
    if(interstitialStatus==OFFER_STATUS_LOADING || interstitialStatus==OFFER_STATUS_READY || interstitialStatus==OFFER_STATUS_SHOWING) return;
    interstitialStatus = OFFER_STATUS_LOADING;
    // 加载弹窗
    self.floatWindow = nil;
    self.floatWindow = [[MobiSageFloatWindow alloc] initWithAdSize:Float_size_3
                                                              delegate:self
                                                             slotToken:stSlotAppKey];
    self.floatWindow.delegate = self;

}

- (void) showInterstitial
{
    [self initSession];
    if(interstitialStatus!=OFFER_STATUS_READY)
    {
        if(interstitialStatus==OFFER_STATUS_LOADFAIL || interstitialStatus == OFFER_STATUS_NONE)
            [self loadInterstitial];
        return;
    }
    if(interstitialStatus==OFFER_STATUS_SHOWING || offerStatus==OFFER_STATUS_SHOWING) {
        SNSLog(@"offers is showing");
        return;
    }
    
    interstitialStatus = OFFER_STATUS_SHOWING;

    [self.floatWindow showAdvView];
    
//    if([self.owViewController isJoyInterstitialReady])
//    {
//        [self.owViewController presentJoyInterstitial];
//    }
//    else
//    {
//        NSLog(@"插屏积分墙还没请求完成:isOfferWallInterstitialReady=NO");
//    }
}

- (void) showOffers
{
    NSLog(@"%s",__func__);
    [self initSession];

    
//    if(interstitialStatus==OFFER_STATUS_SHOWING || offerStatus==OFFER_STATUS_SHOWING) {
//        NSLog(@"offers is showing");
//        return;
//    }
    offerStatus = OFFER_STATUS_SHOWING;
    
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kMobiSageShowTime"];
    
    //显示广告墙
    UIViewController *root = [SystemUtils getAbsoluteRootViewController];
    [self.owViewController presentJoyWithViewController:root];
}

-(void) hideOffers
{
    
}

-(void)checkPoints
{
    [self initSession];
    SNSLog(@"start checking points");
    //请求在线积分检查
    [self.owViewController requestOnlinePointCheck];

    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kMobiSageCheckTime"];
}

-(BOOL) isOfferReady
{
    return (offerStatus==OFFER_STATUS_READY);
}



//积分查询成功之后,回调该接口,获取剩余积分和总已消费积分。
- (void)JoyDidFinishCheckPointWithBalancePoint:(MobiSageJoyViewController *)owInterstitial balance:(NSInteger)balance
                         andTotalConsumedPoint:(NSInteger)consumed
{
    if(owInterstitial== self.owViewController)
    {
        NSLog(@"剩余积分:%d",balance);
        [self.owViewController requestOnlineConsumeWithPoint:balance];
        NSLog(@"已消费积分:%d",consumed);
        NSLog(@"检查积分DidFinish");
    }
    
}


//积分查询失败之后,回调该接口,返回查询失败的错误原因。
- (void)JoyDidFailCheckPointWithError:(MobiSageJoyViewController *)owInterstitial withError:(NSError *)error
{
    if(owInterstitial== self.owViewController)
    {
        NSLog(@"检查积分offerWallDidFailCheckPointWithError:%@",error);
    }
    
}


//请求在线消费指定积分,请注意需要消费的积分为非负值 [owViewController requestOnlineConsumeWithPoint:10];

// 消费请求正常应答后,回调该接口,并返回消费状态(成功或余额不足),以及剩余积分和总已消费积分。

- (void)JoyDidFinishConsumePointWithStatusCode:(MobiSageJoyViewController *)owInterstitial code:(MobiSageJoyConsumeStatusCode)statusCode
                                  balancePoint:(NSInteger)balance
                            totalConsumedPoint:(NSInteger)consumed
{
    if(owInterstitial== self.owViewController)
    {
        if(statusCode==MobiSageJoyConsumeStatusCodeSuccess)
        {
            NSLog(@"消费积分完成");
            //NSLog(@"剩余积分:%d",balance);
            //NSLog(@"已消费积分:%d",consumed);
            if(consumed<=0) return;
            int coinType = [[SystemUtils getGlobalSetting:@"kMobiSageCoinType"] intValue];
            if(coinType<=0)coinType = [[SystemUtils getSystemInfo:@"kMobiSageCoinType"] intValue];
            if(coinType<=0) coinType = 1;
            int amount = consumed;
            [SystemUtils addGameResource:amount ofType:coinType];
            
            NSString *coinKey = [NSString stringWithFormat:@"CoinName%d",coinType];
            NSString *leafName = [SystemUtils getLocalizedString:coinKey];
            if(amount>1) leafName = [StringUtils getPluralFormOfWord:leafName];
            NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], amount, leafName];
            NSString *title = [SystemUtils getLocalizedString:@"Ad Bonus Received"];
            [SystemUtils showSNSAlert:title message:mesg];
            
        }
        if(statusCode==MobiSageJoyConsumeStatusCodeInsufficient)
        {
            NSLog(@"消费积分余额不足");

        }
        if(statusCode==MobiSageJoyConsumeStatusCodeDuplicateOrder)
        {
            NSLog(@"消费积分错误未知");
        }
    }
}


// 消费请求异常应答后,回调该接口,并返回异常的错误原因。
- (void)JoyDidFailConsumePointWithError:(MobiSageJoyViewController *)owInterstitial withError:(NSError *)error;
{
    if(owInterstitial== self.owViewController)
    {
        NSLog(@"消费积分JoyDidFailConsumePointWithError:%@",error);
    }
}



// 当积分墙插屏广告被成功加载时,回调该方法,建议在此回调方法触发之后,再调用插屏积分墙的展示方 法

- (void)JoyInterstitialSuccessToLoadAd:(MobiSageJoyViewController *)dmOWInterstitial
{
    NSLog(@"积分墙插屏广告被成功加载OfferWallInterstitialSuccessToLoadAd");
    interstitialStatus = OFFER_STATUS_READY;
}

// 当积分墙插屏广告加载失败时,回调该方法
- (void)JoyInterstitialFailToLoadAd:(MobiSageJoyViewController *)dmOWInterstitial withError:(NSError *)err
{
    interstitialStatus = OFFER_STATUS_LOADFAIL;
    NSLog(@"插屏广告加载失败OfferWallInterstitialFailToLoadAd:%@",err);
    
}

// 当积分墙插屏广告要被呈现出来前,回调该方法
- (void)JoyInterstitialWillPresentScreen:(MobiSageJoyViewController *)dmOWInterstitial
{
    NSLog(@"插屏广告要被呈现出来OfferWallInterstitialWillPresentScreen");
}

// 当积分墙插屏广告被关闭时,回调该方法
- (void)JoyInterstitialDidDismissScreen:(MobiSageJoyViewController *)dmOWInterstitial
{
    interstitialStatus = OFFER_STATUS_NONE;
    NSLog(@"插屏广告被关闭OfferWallInterstitialDidDismissScreen");
    
}


//积分墙开始加载列表数据
-(void)JoyDidStartLoad:(MobiSageJoyViewController *)owInterstitial
{
    if(owInterstitial==_owViewController)
    {
        NSLog(@"列表积分墙offerWallDidStartLoad");
    }
    return ;
}



//积分墙加载完成。此方法实现中可进行积分墙入口 Button 显示等操作。
- (void)JoyDidFinishLoad:(MobiSageJoyViewController *)owInterstitial
{
    if(owInterstitial==_owViewController)
    {
        offerStatus = OFFER_STATUS_READY;
        NSLog(@"列表积分墙offerWallDidFinishLoad");
    }
}


//积分墙加载失败。可能的原因由 error 部分提供,例如网络连接失败、被禁用等,建议在此隐藏积分墙入 口 Button
- (void)JoyDidFailLoadWithError:(MobiSageJoyViewController *)owInterstitial withError:(NSError *)error
{
    if(owInterstitial==_owViewController)
    {
        offerStatus = OFFER_STATUS_LOADFAIL;
        NSLog(@"列表积分墙offerWallDidFailLoadWithError:%@",error);
    }
    
}

//积分墙页面被关闭
- (void)JoyDidClosed:(MobiSageJoyViewController *)owInterstitial
{
    if(owInterstitial==_owViewController)
    {
        offerStatus = OFFER_STATUS_NONE;
        NSLog(@"列表积分墙offerWallDidClosed");
    }
    
}





#pragma mark - MobiSageFloatWindowDelegate
#pragma mark

- (void)mobiSageFloatClick:(MobiSageFloatWindow*)adFloat
{
    interstitialStatus=OFFER_STATUS_NONE;
    NSLog(@"mobiSageFloatClick");
    [self loadInterstitial];
}

- (void)mobiSageFloatClose:(MobiSageFloatWindow*)adFloat
{
    NSLog(@"mobiSageFloatClose");
    self.floatWindow.delegate = nil;
    self.floatWindow = nil;
    interstitialStatus=OFFER_STATUS_NONE;
    [self loadInterstitial];
}

- (void)mobiSageFloatSuccessToRequest:(MobiSageFloatWindow*)adFloat
{
    NSLog(@"mobiSageFloatSuccessToRequest");
    interstitialStatus=OFFER_STATUS_READY;

}

- (void)mobiSageFloatFaildToRequest:(MobiSageFloatWindow*)adFloat withError:(NSError *)error
{
    NSLog(@"mobiSageFloatFaildToRequest error = %@", [error description]);
        interstitialStatus=OFFER_STATUS_LOADFAIL;
    
}










@end
