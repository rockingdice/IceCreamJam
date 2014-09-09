    //
//  AdmobViewController.m
//  navigation
//
//  Created by LEON on 11-5-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AdmobViewController.h"
#import "SystemUtils.h"
// #import "ZFGuiLayer.h"

@implementation AdmobViewController

@synthesize adLoaded;
@synthesize adStopped,isShowing;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	adLoaded = NO; adStopped = NO; isShowing = YES;
    CGSize gadSize = GAD_SIZE_320x50;
    if([SystemUtils isiPad]) gadSize = GAD_SIZE_728x90;
	// for iPhone: GAD_SIZE_320x50
	// for iPad: GAD_SIZE_300x250, GAD_SIZE_468x60, GAD_SIZE_728x90
	// Create a view of the standard size at the bottom of the screen.
	bannerView_ = [[GADBannerView alloc]
                   initWithFrame:CGRectMake(0.0,
                                            0.0,
                                            gadSize.width,
                                            gadSize.height)];
    
    bannerSize = gadSize;
	
	bannerView_.delegate = self;
	// Specify the ad's "unit identifier." This is your AdMob Publisher ID.
    NSString *pubID = [SystemUtils getGlobalSetting:@"kAdMobPublisherID"];
    if(!pubID || [pubID length]<3) pubID = [SystemUtils getSystemInfo:@"kAdMobPublisherID"];
	bannerView_.adUnitID = pubID;
	// Let the runtime know which UIViewController to restore after taking
	// the user wherever the ad goes and add it to the view hierarchy.
	bannerView_.rootViewController = self;
	// [self.view addSubview:bannerView_];
	
    self.view.frame = CGRectMake(0, 0, gadSize.width, gadSize.height);
    
	// Initiate a generic request to load it with an ad.
	GADRequest *request = [GADRequest request];
	/*
	request.testDevices = [NSArray arrayWithObjects:
						   GAD_SIMULATOR_ID,                               // Simulator
						   @"28ab37c3902621dd572509110745071f0101b124",    // Test iPhone 3G 3.0.1
						   @"8cf09e81ef3ec5418c3450f7954e0e95db8ab200",    // Test iPod 4.3.1
						   nil];	
	
	 request.gender = kGADGenderMale;
	 
	 [request setLocationWithLatitude:locationManager_.location.coordinate.latitude
	 longitude:locationManager_.location.coordinate.longitude
	 accuracy:locationManager_.location.horizontalAccuracy];
	 
	 [request setBirthdayWithMonth:3 day:13 year:1976];
	 */
#ifdef DEBUG
    // request.testing = YES;
#endif
	[bannerView_ loadRequest:request];	
	//NSLog(@"ad view load finish");
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    UIDeviceOrientation o = [SystemUtils getGameOrientation];
    if(o == UIDeviceOrientationPortrait) return (interfaceOrientation == UIInterfaceOrientationPortrait);
    if(UIDeviceOrientationIsLandscape(o)) return (UIInterfaceOrientationIsLandscape(interfaceOrientation));
    return NO;
    // return (interfaceOrientation == UIInterfaceOrientationLandscapeRight || interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    bannerView_.delegate = nil;
	[bannerView_ release]; bannerView_ = nil;
    [super dealloc];
}

- (void) updatePosition
{
    BOOL isPortrait = NO;
    if([SystemUtils getGameOrientation]==UIDeviceOrientationPortrait) isPortrait = YES;
    
	
    // [[[CCDirector sharedDirector] openGLView] addSubview:self.view];	
    UIViewController *vc = [SystemUtils getRootViewController];
    if(vc) {
        if(isPortrait) {
            CGRect r = vc.view.frame;
            self.view.frame = CGRectMake((r.size.width-bannerSize.width)/2, (r.size.height-bannerSize.height), bannerSize.width, bannerSize.height);
        }
        else 
        {
            // put the ad at the top middle of the screen in landscape mode
            self.view.frame = CGRectMake(0, 0, bannerSize.width, bannerSize.height);
            CGAffineTransform makeLandscape = CGAffineTransformMakeRotation(M_PI * 0.5f);
            // makeLandscape = CGAffineTransformTranslate(makeLandscape, 220, 130);//centers the ad in landscape mode
            if([SystemUtils isiPad]) {
                // iPad 
                makeLandscape = CGAffineTransformTranslate(makeLandscape, 440, 300);//centers the ad in landscape mode
            }
            else {
                makeLandscape = CGAffineTransformTranslate(makeLandscape, 220, 130);//centers the ad in landscape mode
            }
            self.view.transform = makeLandscape;
        }
        // [vc.view addSubview:self.view];
    }
}

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView {
	NSLog(@"%s:banner loaded",__func__);
	if(adStopped || adLoaded) return;
    self.view.hidden = YES; // default hide ad
    // [SystemUtils setNSDefaultObject:@"0" forKey:@"showingOffer"];
    // int showingOffer = [[SystemUtils getNSDefaultObject:@"showingOffer"] intValue];
    // if(showingOffer==1) return;
	/*
	[UIView beginAnimations:@"BannerSlide" context:nil];
	bannerView.frame = CGRectMake(0.0,
								  self.view.frame.size.height -
								  bannerView.frame.size.height,
								  bannerView.frame.size.width,
								  bannerView.frame.size.height);
	[UIView commitAnimations];
	 */
	// for iPhone: GAD_SIZE_320x50
	// for iPad: GAD_SIZE_300x250, GAD_SIZE_468x60, GAD_SIZE_728x90
	[[self view] addSubview:bannerView];
	adLoaded = YES;
    [self updatePosition];
}

- (void)adView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(GADRequestError *)error {
	NSLog(@"adView:didFailToReceiveAdWithError:%@", [error localizedDescription]);
}

- (void)adViewWillPresentScreen:(GADBannerView *)bannerView
{
}

- (void)adViewDidDismissScreen:(GADBannerView *)bannerView
{
	NSLog(@"adViewDidDismissScreen");
	// [self.view removeFromSuperview];
	// [[ZFGuiLayer gui] stopAdsenseOffer];
    [self updatePosition];
}

- (void)adViewWillDismissScreen:(GADBannerView *)bannerView
{
    // [self updatePosition];
}

- (void)adViewWillLeaveApplication:(GADBannerView *)bannerView
{
}


@end
