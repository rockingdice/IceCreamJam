//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "PopGameHelper.h"
#import "SystemUtils.h"
#import "InAppStore.h"

@implementation PopGameHelper

static PopGameHelper *_gPopGameHelper = nil;

+ (PopGameHelper *) helper
{
    if(!_gPopGameHelper) {
        _gPopGameHelper = [[PopGameHelper alloc] init];
    }
    return _gPopGameHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO;
    }
    return self;
}

- (void) initSession:(NSDictionary *)options
{
    if(isInitialized) return;
    // [options retain];
    isInitialized = YES;
    //******************************初始化*******************************
    // 1.启动日志接口：分配cid（推广渠道号）：1908233016-1908342870
    // 2.支付日志接口：分配支付渠道号：vp5ky95fna（苹果渠道）

    NSString *cId = @"1908233016-1908342870";             //分配
    NSString *appID = [SystemUtils getSystemInfo:@"kiTunesAppID"];
    NSString* gameVersion = [SystemUtils getClientVersion];
    UIViewController *root = [SystemUtils getAbsoluteRootViewController];
    
    [PopGame initCenter:root channelId:cId version:gameVersion
    didFinishLaunchingWithOptions:options itunesApplicationAppId:appID];
    [PopGame setDelegate:self];
    // [options release];

    // register payment notification
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onReceivePayment:)
												 name:@"kInAppStoreItemBoughtNotification"
											   object:nil];

}

- (BOOL) recordFee
{
    if(!isInitialized)
        [self initSession:nil];
    
    if(!isInitialized) return NO;
    if(priceInfo==nil) return NO;

    NSString *price = [priceInfo objectForKey:@"price"];
    NSString *iapID = [priceInfo objectForKey:@"itemID"];
    
    NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [SystemUtils getCurrentUID],@"userId",
                         price, @"price", @"USD", @"currency",
                         iapID,  @"iapName",
                         @"u90wo85su8", @"feeName",
                         @"1",@"feeType",nil];
    NSString* result = [PopGame feeRecord:dic];
    SNSLog(@"result:%@",result);
    [priceInfo release]; priceInfo = nil;
    return YES;
}

- (void) onReceivePayment:(NSNotification *)note
{
	SNSLog(@"%s:%@",__FUNCTION__,note);
	NSDictionary *info = note.userInfo;
	NSString* buyID = [info objectForKey:@"itemId"];
	// NSString *tid = [info objectForKey:@"tid"];
    // NSString *receiptData = [info objectForKey:@"receiptData"];
    // NSString *verifyPostData = [info objectForKey:@"verifyPostData"];
	priceInfo = [[InAppStore store] getProductPrice:buyID];
	if(!priceInfo) {
		// LOG to pending iap
		SNSLog(@"invalid payment info:%@", info);
		return;
	}
    [priceInfo retain];
    [self performSelectorInBackground:@selector(recordFee) withObject:nil];
	

    
}

@end
