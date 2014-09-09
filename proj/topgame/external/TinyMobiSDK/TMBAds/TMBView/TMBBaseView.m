//
//  TMBBaseView.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-18.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//
#import "TMBConfig.h"
#import "TMBBaseView.h"
#import "TMBCommon.h"
#import "TMBSDKConfig.h"
#import "TMBCre.h"
#import "TMBLog.h"

@interface TMBBaseView ()
@end

@implementation TMBBaseView
@synthesize adController;
@synthesize showFlag;


-(CGRect) getAdFrame
{
    CGRect full_frame = [[UIScreen mainScreen] bounds];
    int x = full_frame.origin.x;
    int y = full_frame.origin.y;
    int w = full_frame.size.width;
    int h = full_frame.size.height;
    if ([UIApplication sharedApplication].statusBarHidden) {
        //hidde sb
        if ([[TMBCommon getAppOrientation] isEqualToString:@"0"]) {
            if (w < h) {
                w = full_frame.size.height;
                h = full_frame.size.width;
            }
        }else{
            if (w > h) {
                w = full_frame.size.height;
                h = full_frame.size.width;
            }
        }
    }else{
        //show sb
        CGRect sb_frame = [[UIApplication sharedApplication] statusBarFrame];
        int sb_h = sb_frame.size.height;
        if (sb_frame.size.width < sb_frame.size.height) {
            sb_h = sb_frame.size.width;
        }
        if ([[TMBCommon getAppOrientation] isEqualToString:@"0"]) {
            if (w < h) {
                w = full_frame.size.height;
                h = full_frame.size.width;
            }
        }else{
            if (w > h) {
                w = full_frame.size.height;
                h = full_frame.size.width;
            }
        }
        y = sb_h;
        h = h - sb_h;
    }
    return CGRectMake(x, y, w, h);
}

- (void) show
{
    self.showFlag = TRUE;
    [TMBLog log:@"AD" :[NSString stringWithFormat:@"%@ %@", [self class], @"SHOW"]];
    if (!self.adController.fvc || ![self.adController.fvc isViewLoaded]) {
        [self.adController setFatherViewController:nil];
    }
    self.adController.fvc.modalPresentationStyle = UIModalPresentationCurrentContext;
    if ([self.adController.fvc respondsToSelector:@selector(isBeingDismissed)]) {
        if ([self.adController.fvc performSelector:@selector(isBeingDismissed)] || [self.adController.fvc performSelector:@selector(isMovingFromParentViewController)]) {
            [self performSelector:@selector(show) withObject:nil afterDelay:1];
            return;
        }
    }
    if ([self.adController.fvc respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        [self.adController.fvc presentViewController:self animated:NO completion:^(void){
        }];
    }else{
        [self.adController.fvc presentModalViewController:self animated:NO];
    }
    [self.adController noticeDelegate:TMB_AD_EVENT_DISPLAY];
}

- (void) close
{
    [TMBLog log:@"AD" :[NSString stringWithFormat:@"%@ %@", [self class], @"CLOSE"]];
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:NO completion:^(void){
        }];
    }else{
        [self dismissModalViewControllerAnimated:NO];
    }
    self.showFlag = FALSE;
    [self.adController noticeDelegate:TMB_AD_EVENT_DISMISS];
}

- (BOOL) isShow
{
    return self.showFlag;
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [self shouldAutorotate];
}

//supportedInterfaceOrientations
-(NSUInteger)supportedInterfaceOrientations
{
    if ([[TMBCommon getAppOrientation] isEqualToString:@"0"] ) {
        return UIInterfaceOrientationMaskLandscape;
    }else{
        return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
    }
}

//preferredInterfaceOrientationForPresentation
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if ([[TMBCommon getAppOrientation] isEqualToString:[TMBCommon getOrientation]]) {
        return [TMBCommon getSharedOrientation];
    }else{
        if ([[TMBCommon getAppOrientation] isEqualToString:@"0"]) {
            return UIInterfaceOrientationLandscapeLeft;
        }else{
            return UIInterfaceOrientationPortrait;
        }
    }
}

-(BOOL)shouldAutorotate
{
    BOOL ok = [[TMBCommon getOrientation] isEqualToString:[TMBCommon getAppOrientation]];
    return ok;
}

//webview open url
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];
    if (![[url scheme] isEqualToString:@"about"] && ![[url scheme] isEqualToString:@"applewebdata"]) {
        TMBCre *cre = [[[TMBCre alloc] init] autorelease];
        [cre setCreDelegate:self.adController];
        [cre run:url];
        return NO;
    }
    return YES;
}

-(void) dealloc
{
    [super dealloc];
}

@end
