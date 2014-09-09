//
//  TMBAdPopViewViewController.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-8-7.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import "TMBAdPopView.h"
#import "TMBConfig.h"
#import "TMBCommon.h"
#import "TMBGTMNSString+HTML.h"
#import "TinyMobiDelegate.h"
#import "TMBCre.h"
#import "TMBLog.h"

@interface TMBAdPopView ()
{
    UIView *adView;
}
@property (nonatomic, retain) UIView *adView;
@end

@implementation TMBAdPopView
@synthesize adView;

-(void) dealloc
{
    [adView release];
    [super dealloc];
}

- (void) loadAd
{
    id adData = [adController adData];
    if (!adData || [adData objectForKey:@"body"]==[NSNull null]) {
        return;
    }
    [self setShowFlag:TRUE];
    //show
    //add webview
    if (!adView || ![adView isKindOfClass:[UIWebView class]]){
        [self setAdView:[[[UIWebView alloc]init]autorelease]];
        [(UIWebView *)adView setScalesPageToFit:NO];
        for (UIView *_aView in [adView subviews]) {
            if ([_aView isKindOfClass:[UIScrollView class]]) {
                [(UIScrollView *)_aView setBounces:FALSE];
                [(UIScrollView *)_aView setScrollEnabled:FALSE];
            }
        }
        [(UIWebView *)adView setDelegate:self];
    }
    NSString *html = [(NSDictionary *)adData objectForKey:@"body"];
    [(UIWebView *)adView loadHTMLString:[html tmb_gtm_stringByUnescapingFromHTML] baseURL:nil];
}

- (void) loadAdFinish
{
    [self show];
    //auto close
    NSDictionary *adConfig = [adController adConfig];
    if ([adConfig objectForKey:@"ad.pop.auto.close.time"] && [[adConfig objectForKey:@"ad.pop.auto.close.time"] intValue]>0) {
        [self performSelector:@selector(close) withObject:nil afterDelay:[[adConfig objectForKey:@"ad.pop.auto.close.time"] intValue]];
    }else{
        [self performSelector:@selector(close) withObject:nil afterDelay:[[adConfig objectForKey:@"ad.pop.show.max"] intValue]];
    }
    [self performSelector:@selector(checkShow) withObject:nil afterDelay:0.1f];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [TMBLog log:@"AD POP" :@"viewDidLoad"];
    CGRect viewBound = [self getAdFrame];
    [self.view setFrame:viewBound];
    self.view.backgroundColor = [UIColor clearColor];
    id adData = [adController adData];
    //custom alert
    NSString *size = [(NSDictionary *)adData objectForKey:@"size"];
    double w = 0;
    double h = 0;
    double viewW = viewBound.size.width;
    double viewH = viewBound.size.height;
    if (size && [[size componentsSeparatedByString:@"x"] count]==2) {
        NSArray *sizeArray = [size componentsSeparatedByString:@"x"];
        w = [[sizeArray objectAtIndex:0] doubleValue];
        h = [[sizeArray objectAtIndex:1] doubleValue];
        if(w > viewW){
            w = viewW;
        }
        if(h > viewH){
            h = viewH;
        }
    }else{
        w = viewW;
        h = viewH;
    }
    int x = (viewW-w)/2;
    int y = (viewH-h)/2;
    CGRect adsViewBound = CGRectMake(x, y, w, h);
    [adView setFrame:adsViewBound];
    adView.backgroundColor = [UIColor clearColor];
    adView.opaque = NO;
    [self.view addSubview:adView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self loadAdFinish];
}

-(void) checkShow
{
    if (![self isViewLoaded]) {
        [self.adController setFatherViewController:nil];
        [self show];
    }
}

@end
