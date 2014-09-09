//
//  TinyMobiAdWallViewController.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-6-27.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//
#import "TMBAdWallView.h"
#import "TMBConfig.h"
#import "TMBCommon.h"
#import "TMBSDKConfig.h"
#import "TMBCacheFile.h"
#import "TMBLog.h"

@interface TMBAdWallView ()
{
    UINavigationBar *adNavBar;
    CGRect navBound;
    UIWebView *adView;
    CGRect adViewBound;
    UIView *loadingView;
    BOOL loadingFlag;
    
}
@property (nonatomic, retain) UINavigationBar *adNavBar;
@property (nonatomic, retain) UIWebView *adView;
@property (nonatomic, retain) UIView *loadingView;
@property (nonatomic, assign) CGRect navBound;
@property (nonatomic, assign) CGRect adViewBound;
@property (nonatomic, assign) BOOL loadingFlag;
@end

@implementation TMBAdWallView
@synthesize adNavBar;
@synthesize adView;
@synthesize loadingView;
@synthesize navBound;
@synthesize adViewBound;
@synthesize loadingFlag;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    [TMBLog log:@"AD WALL" :@"INIT"];
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) dealloc
{
    [adView release];
    [adNavBar release];
    [loadingView release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [TMBLog log:@"AD WALL" :@"viewDidLoad"];
    //bounds
    CGRect viewBound = [self getAdFrame];
    double viewW = viewBound.size.width;
    double viewH = viewBound.size.height;
    self.navBound = CGRectMake(0, 0, viewW, 44);
    self.adViewBound = CGRectMake(0, navBound.size.height, viewW, viewH-navBound.size.height);
    //show nav bar
    [self showNavBar];
}

-(void) closeWall:(id) sender
{
    [self close];
}

-(void) showNavBar
{
    float backBtnW = 50;
    float backBtnH = 30;
    CGRect backBtnBound = CGRectMake(0, (navBound.size.height-backBtnH)/2, backBtnW, backBtnH);
    //nav bar
    [self setAdNavBar:[[[UINavigationBar  alloc] initWithFrame:navBound] autorelease]];
    //set bg img
    UIImageView *bgImgview = [[[UIImageView alloc] initWithFrame:navBound] autorelease];
    [bgImgview setImage:[UIImage imageNamed:TMB_AD_NAV_BG_IMG]];
    [bgImgview setClipsToBounds:YES];
    [adNavBar addSubview:bgImgview];
    
    //back btn
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setFrame:backBtnBound];
    [backBtn setBackgroundImage:[UIImage imageNamed:TMB_AD_BACK_BUTTON_IMG] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(closeWall:) forControlEvents:UIControlEventTouchUpInside];
    
    //nav item
    UINavigationItem *navItem = [[[UINavigationItem alloc] init] autorelease];
    [navItem setLeftBarButtonItem:[[[UIBarButtonItem alloc]initWithCustomView:backBtn]autorelease]];
    UIImage *icon = [UIImage imageNamed:TMB_AD_NAV_ICON_IMG];
    UIImageView *iconView = [[[UIImageView alloc] initWithImage:icon] autorelease];
    [iconView setFrame:CGRectMake(0, (navBound.size.height-30)/2, 110, 30)];
    [iconView setClipsToBounds:YES];
    [iconView setContentMode:UIViewContentModeScaleAspectFit];
    [navItem setTitleView:iconView];
    [adNavBar pushNavigationItem:navItem animated:NO];
    [self.view addSubview:adNavBar];
}

-(BOOL) checkLoadingConfig
{
    BOOL checkOK = TRUE;
    NSDictionary *loadingConfig = [adController.adConfig objectForKey:@"ad.wall.loading"];
    if (!loadingConfig) {
        return FALSE;
    }
    if (![loadingConfig objectForKey:@"bg"] || ![TMBCacheFile getCacheFileWithURL:[loadingConfig objectForKey:@"bg"]]) {
        checkOK = FALSE;
    }
    if (![loadingConfig objectForKey:@"loading"]){
        checkOK = FALSE;
    }else{
        id loadingList = [loadingConfig objectForKey:@"loading"];
        NSArray *imgs = nil;
        if ([loadingList isKindOfClass:[NSDictionary class]]) {
            imgs = [loadingList allValues];
        }else if ([loadingList isKindOfClass:[NSArray class]]){
            imgs = loadingList;
        }else{
            checkOK = FALSE;
        }
        if (imgs && [imgs count]>0) {
            NSEnumerator *en = [imgs objectEnumerator];
            NSString *imgUrl;
            while ((imgUrl = [en nextObject])) {
                if(!imgUrl || ![TMBCacheFile getCacheFileWithURL:imgUrl]){
                    checkOK = FALSE;
                }
            }
        }else{
            checkOK = FALSE;
        }
    }
    return checkOK;
}

-(void) showLoading
{
    NSInteger loadDelayTime = 3;
    if ([self checkLoadingConfig]) {
        float animationImagesW = 145;
        float animationImagesH = 238;
        CGRect animationImagesBound = CGRectMake((adViewBound.size.width-animationImagesW)/2, (adViewBound.size.height-animationImagesH)/2, animationImagesW, animationImagesH);
        [self setLoadingView:[[[UIImageView alloc] initWithFrame:adViewBound] autorelease]];
        NSDictionary *loadingConfig = [adController.adConfig objectForKey:@"ad.wall.loading"];
        //bg img
        NSString *bgImgPath = [TMBCacheFile getCacheFileWithURL:[loadingConfig objectForKey:@"bg"]];
        [(UIImageView *)loadingView setImage:[[[UIImage alloc] initWithContentsOfFile:bgImgPath] autorelease]];
        //loading img
        UIImageView *animationImagesView = [[[UIImageView alloc] initWithFrame:animationImagesBound] autorelease];
        NSMutableArray *loadImgs = [[[NSMutableArray alloc] init] autorelease];
        id loadingList = [loadingConfig objectForKey:@"loading"];
        NSArray *imgs;
        if ([loadingList isKindOfClass:[NSDictionary class]]) {
            imgs = [loadingList allValues];
        }else{
            imgs = loadingList;
        }
        if ([imgs count] > 1) {
            NSEnumerator *en = [imgs objectEnumerator];
            NSString *imgUrl;
            while ((imgUrl = [en nextObject])) {
                UIImage *_img = [[[UIImage alloc] initWithContentsOfFile:[TMBCacheFile getCacheFileWithURL:imgUrl]] autorelease];
                if (_img) {
                    [loadImgs addObject:_img];
                }
            }
            [animationImagesView setAnimationImages:loadImgs];
            [animationImagesView setAnimationDuration:[loadImgs count]/2];
            [animationImagesView setAnimationRepeatCount:0];
            [animationImagesView startAnimating];
            loadDelayTime = round([loadImgs count]/4);
        }else{
            [animationImagesView setImage:[[[UIImage alloc] initWithContentsOfFile:[TMBCacheFile getCacheFileWithURL:[imgs objectAtIndex:0]]] autorelease]];
        }
        
        [loadingView addSubview:animationImagesView];
    }else{
        //bg
        [self setLoadingView:[[[UIView alloc] initWithFrame:adViewBound] autorelease]];
        loadingView.backgroundColor = [UIColor whiteColor];
        //loading
        UIActivityIndicatorView *loading = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
        [loading setFrame:CGRectMake(0, 0, 32, 32)];
        [loading setCenter:CGPointMake(adViewBound.size.width/2, adViewBound.size.height/2)];
        [loading startAnimating];
        [loadingView addSubview:loading];
    }
    [self setLoadingFlag:TRUE];
    [self performSelector:@selector(closeLoading) withObject:nil afterDelay:loadDelayTime];
    [self.view addSubview:loadingView];
}

- (void) loadAdPre
{
    [self show];
    //show loading
    [self showLoading];
}

- (void) loadAd
{
    //ad view
    if (!adView) {
        [self setAdView:[[[UIWebView alloc] init] autorelease]];
    }
    [adView setFrame:adViewBound];
    [adView setScalesPageToFit:NO];
    [adView setDelegate:self];
    [self.view insertSubview:adView belowSubview:loadingView];
    [adView loadHTMLString:adController.adData baseURL:nil];
}

- (void) loadAdFinish
{
    [self setLoadingFlag:FALSE];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [TMBLog log:@"AD WALL" :@"view load finish"];
    [self loadAdFinish];
}

- (void) closeLoading
{
    if (!self.loadingFlag) {
        [loadingView removeFromSuperview];
    }else{
        [self performSelector:@selector(closeLoading) withObject:nil afterDelay:1];
    }
}

@end
