//
//  TMBBaseAd.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-18.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import "TMBBaseAd.h"
#import "TMBBaseView.h"
#import "TMBNetWork.h"
#import "TMBCommon.h"
#import "TMBLog.h"
#import "TMBAdStore.h"
#import "TMBJob.h"
#import "TMBAdPop.h"
#import "TMBAdWall.h"

@interface TMBBaseAd ()
@end

@implementation TMBBaseAd
@synthesize fvc;
@synthesize adView;
@synthesize adArgs;
@synthesize adConfig;
@synthesize adData;

- (void) setFatherViewController:(UIViewController *)vc
{
    if(!vc){
        vc = [TMBCommon getRootViewController];
    }
    [self setFvc:vc];
}

- (BOOL) isShow
{
    if (adView) {
        return [adView isShow];
    }else{
        return FALSE;
    }
}

- (void) close
{
    if (adView && [adView isShow]) {
        [adView close];
    }
}

- (void) dealloc
{
    [adView release];
    [adConfig release];
    [adData release];
    [super dealloc];
}

- (void)adClose:(NSDictionary *)args
{
    [self close];
}

- (void)appInstall:(NSDictionary *)args
{
    if (args) {
        if ([[args valueForKey:@"fvc_close"] intValue]==1) {
            [self close];
        }else if([self isKindOfClass:[TMBAdPop class]]){
            [self close];
        }
        [self noticeDelegate:TMB_AD_EVENT_APP_INSTALL];
        TMBAdStore *store = (TMBAdStore *)[TMBAdStore sharedAd];
        [store setAdArgs:args];
        [store show];
    }
}

- (void)appPlay:(NSDictionary *)args
{
    if (args) {
        NSString *urlStr=[args valueForKey:@"url"];
        if (urlStr && [urlStr length]>0) {
            NSURL  *url= [NSURL URLWithString:urlStr];
            [self noticeDelegate:TMB_AD_EVENT_APP_PLAY];
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (void)openUrl:(NSDictionary *)args
{
    if (args) {
        NSURL *url = [NSURL URLWithString:[args valueForKey:@"url"]];
        if (url) {
            if ([[args valueForKey:@"fvc_close"] intValue]==1) {
                [self close];
            }else if([self isKindOfClass:[TMBAdPop class]]){
                [self close];
            }
            [self noticeDelegate:TMB_AD_EVENT_APP_INSTALL];
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (void)openNewAd:(NSDictionary *)args
{
    if (args) {
        NSString *adType = [NSString stringWithFormat:@"TMBAd%@", [(NSString *)[args valueForKey:@"ad_type"] capitalizedString]];
        if (!adType || !NSClassFromString(adType) || ![NSClassFromString(adType) isSubclassOfClass:[TMBBaseAd class]] || [self class]==NSClassFromString(adType)) {
            return;
        }
        TMBBaseAd *newAd = [NSClassFromString(adType) sharedAd];
        if ([newAd isShow]) {
            return;
        }
        if (args && [[args valueForKey:@"fvc_close"] intValue]==1) {
            [self close];
        }else if([self isKindOfClass:[TMBAdPop class]]){
            [self close];
        }
        [newAd setAdArgs:args];
        [newAd setAppId:self.appId];
        [newAd setSecretKey:self.secretKey];
        [newAd setDelegate:self.delegate];
        [newAd setFatherViewController:nil];
        [newAd show];
    }
}

- (void) noticeDelegate:(NSString *)type
{
    NSDictionary *map = [self.class noticeDelegateMap];
    if (map && [map objectForKey:type]) {
        NSString *method = [map objectForKey:type];
        if (method && delegate && [delegate respondsToSelector:NSSelectorFromString(method)]) {
            [TMBJob addJobQueueWithTarget:delegate selectot:NSSelectorFromString(method) object:nil];
        }
    }
}

+ (NSDictionary *) noticeDelegateMap
{
    return nil;
}

@end
