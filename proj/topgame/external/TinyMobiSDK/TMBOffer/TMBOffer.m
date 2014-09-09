//
//  TMBOffer.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-9.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import "TMBOffer.h"
#import "TMBConfig.h"
#import "TMBNetWork.h"

#import "TMBLog.h"

@implementation TMBOffer

-(NSArray *)offer
{
    //get offer infos
    TMBNetWork *net = [[[TMBNetWork alloc] initWithSecretKey:secretKey] autorelease];
    [net setTimeout:TMB_NET_TIMEOUT];
    NSString *url = [NSString stringWithFormat:[TMBNetWork fullUrl:TMB_OFFER_INFO_URL], [TMBNetWork host], appId];
    NSData *ret = [net sendRequestWithURL:url Data:nil];
    id response = [TMBNetWork decodeServerJsonResult:[[[NSString alloc] initWithData:ret encoding:NSUTF8StringEncoding] autorelease]];
    if (response!=nil && [response isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [[[NSMutableArray alloc] init] autorelease];
        for (id dir in response) {
            if ([dir isKindOfClass:[NSDictionary class]]) {
                if ([(NSDictionary *)dir valueForKey:@"offerId"] && [(NSDictionary *)dir valueForKey:@"offerId"]!=[NSNull null] && [(NSDictionary *)dir valueForKey:@"offerInfo"] && [(NSDictionary *)dir valueForKey:@"offerId"]!=[NSNull null]) {
                    NSMutableDictionary *info = [[[NSMutableDictionary alloc] initWithCapacity:2] autorelease];
                    [info setObject:[(NSDictionary *)dir valueForKey:@"offerId"] forKey:@"rewardId"];
                    [info setObject:[(NSDictionary *)dir valueForKey:@"offerInfo"] forKey:@"rewardInfo"];
                    [result addObject:info];
                }
            }
        }
        return result;
    }else{
        return nil;
    }
}

-(BOOL)finish:(NSString *)offerIds
{
    if ([offerIds length] < 1) {
        return FALSE;
    }
    TMBNetWork *net = [[[TMBNetWork alloc] initWithSecretKey:secretKey] autorelease];
    [net setTimeout:TMB_NET_TIMEOUT];
    NSString *url = [NSString stringWithFormat:[TMBNetWork fullUrl:TMB_OFFER_FINISH_URL], [TMBNetWork host], appId];
    NSDictionary *params = [NSDictionary dictionaryWithObject:offerIds forKey:@"offerIds"];
    NSData *ret = [net sendRequestWithURL:url Data:params];
    id response = [TMBNetWork decodeServerJsonResult:[[[NSString alloc] initWithData:ret encoding:NSUTF8StringEncoding] autorelease]];
    if (response!=nil) {
        [TMBLog log:@"OFFER FINISH OK":offerIds];
        return TRUE;
    }else{
        [TMBLog log:@"OFFER FINISH FAIL":offerIds];
        return FALSE;
    }
}

@end