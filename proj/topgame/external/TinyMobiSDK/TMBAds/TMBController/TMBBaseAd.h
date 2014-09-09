//
//  TMBBaseAd.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-18.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMBBaseClass.h"
#import "TMBAdProtocol.h"
#import "TMBViewProtocol.h"
#import "TMBCreDelegate.h"

#define TMB_AD_EVENT_DISPLAY @"DISPLAY"
#define TMB_AD_EVENT_DISMISS @"DISMISS"
#define TMB_AD_EVENT_APP_INSTALL @"APP_INSTALL"
#define TMB_AD_EVENT_APP_PLAY @"APP_PLAY"
#define TMB_AD_EVENT_OTHER_AD_WALL @"OTHER_AD_WALL"

@interface TMBBaseAd : TMBBaseClass <TMBAdProtocol, TMBCreDelegate>
{
    //father view controller
    UIViewController *fvc;
    id adView;
    NSDictionary *adArgs;
    NSDictionary *adConfig;
    id adData;
}
@property (nonatomic, retain) UIViewController *fvc;
@property (nonatomic, retain) id adView;
@property (nonatomic, retain) NSDictionary *adArgs;
@property (nonatomic, retain) NSDictionary *adConfig;
@property (nonatomic, retain) id adData;

+ (TMBBaseAd *) sharedAd;

- (void) setFatherViewController:(UIViewController *)vc;

- (void) noticeDelegate:(NSString *)type;
@end