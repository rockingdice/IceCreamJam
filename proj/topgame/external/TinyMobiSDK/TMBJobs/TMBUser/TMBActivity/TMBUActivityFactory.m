//
//  TMBUActivityFactory.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-18.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import "TMBUActivityFactory.h"

#import "TMBUAOpen.h"
#import "TMBUInstalled.h"

@implementation TMBUActivityFactory

+(id<TMBUActivityProtocol>) createActivityWithAppid: (NSString *)_appId AndSecretKey: (NSString *)_secretKey AndActivityType: (NSString *)type
{
    id<TMBUActivityProtocol> activity = nil;
    if ([type isEqualToString:TMB_USER_ACTIVITY_OPEN]) {
        activity = [[[TMBUAOpen alloc] init] autorelease];
    }else if([type isEqualToString:TMB_USER_ACTIVITY_INSTALLED]){
        activity = [[[TMBUInstalled alloc] init] autorelease];
    }
    if ([activity isKindOfClass:[TMBBaseClass class]]) {
        [(TMBBaseClass* )activity setAppId:_appId];
        [(TMBBaseClass* )activity setSecretKey:_secretKey];
    }
    return activity;
}

@end
