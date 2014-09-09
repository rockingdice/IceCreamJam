//
//  TinyMobiInit.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-12.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//
#import "TMBConfig.h"
#import "TMBUAOpen.h"
#import "TMBNetWork.h"
#import "TMBJob.h"
#import "TMBLog.h"

@implementation TMBUAOpen

-(BOOL) do
{
    [TMBJob addJobQueueWithTarget:self selectot:@selector(appOpen) object:nil];
    return TRUE;
}

- (void) appOpen
{
    TMBNetWork *net = [[[TMBNetWork alloc] initWithSecretKey:secretKey] autorelease];
    [net setTimeout:TMB_NET_TIMEOUT];
    NSString *url = [NSString stringWithFormat:[TMBNetWork fullUrl:TMB_USER_ACTIVITY_OPEN_URL], [TMBNetWork host], appId];
    [net sendRequestWithURL:url Data:nil];
}

@end
