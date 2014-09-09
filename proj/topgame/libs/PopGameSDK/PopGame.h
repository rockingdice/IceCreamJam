//
//  PopGame.h
//  PopGameDemo
//
//  Created by op-mac1 on 13-6-27.
//  Copyright (c) 2013年 op-mac1. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PopGame : NSObject

//初始化
//产品唯一标识：channelId
+(NSString *) initCenter:(UIViewController *)rootViewController
               channelId:(NSString *) cId
                 version:(NSString *) gameVersion
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
  itunesApplicationAppId:(NSString*) appId;

//初始化
//产品唯一标识：channelId
//用户唯一标识：userId
+(NSString *) initCenter:(UIViewController *)rootViewController
               channelId:(NSString *) cId
                 version:(NSString *) gameVersion
            userIdentify:(NSString *) userId
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
  itunesApplicationAppId:(NSString*) appId;

//结算
//付费金额:price 货币类型: currency
//返回值：YES为日志发送成功，NO日志发送失败
//NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:@"9.99",@"price",@"USD",@"currency", nil];
//注：currency请参照http://en.wikipedia.org/wiki/ISO_4217  例如，美元USD,人民币CNY
//+(NSDictionary*) charge:(NSDictionary *) chargeRecord;
+(NSString *) charge:(NSDictionary *) chargeRecord;
+(void) confirmCharge;

//参数recordData：付费账号:account  付费金额:money 货币类型: currency 付费服务器:server 付费点名称:feeName
//返回值：YES为日志发送成功，NO日志发送失败
//NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:@"9.99",@"money",@"USD",@"currency",@"91",@"feeName", nil];
//注：currency请参照http://en.wikipedia.org/wiki/ISO_4217  例如，美元USD,人民币CNY
+(NSString *) feeRecord:(NSDictionary *) recordData;

+(void) setDelegate:(id) delegate;

//广告推广
+(void) showAppWall;
+(void) closeAppWall;

+(void) showBanner;
+(void) closeBanner;

+(void) showBigImage;
+(void) closeBigImage;


@end
