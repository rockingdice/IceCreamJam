//
//  TMBUActivityFactory.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-18.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import "TMBUActivityProtocol.h"

#define TMB_USER_ACTIVITY_OPEN @"open"
#define TMB_USER_ACTIVITY_INSTALLED @"installed"

@interface TMBUActivityFactory : NSObject

+(id<TMBUActivityProtocol>) createActivityWithAppid: (NSString *)_appId AndSecretKey: (NSString *)_secretKey AndActivityType: (NSString *)type;

@end
