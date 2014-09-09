    //
//  AdmobViewController.m
//  navigation
//
//  Created by LEON on 11-5-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AdWhirlViewController.h"
#import "cocos2d.h"
#import "MyAdvertiseSetting.h"
#import "iPetHotelAppDelegate.h"
#import "SystemUtils.h"

@implementation AdWhirlViewController

// @synthesize delegate;

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
	self.view.frame = CGRectMake(0, 410, 320, 50);
	bannerView_ = [AdWhirlView requestAdWhirlViewWithDelegate:self];
	[self.view addSubview:bannerView_];
	NSLog(@"adWhirlView created");
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait); // || interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[bannerView_ release]; bannerView_ = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

- (NSString *)adWhirlApplicationKey {
	NSString *key = [SystemUtils getGlobalSetting:kAdWhirlPublisherIDKey];
	if(!key) key = kAdWhirlPublisherIDDefault;
	return key;
}

- (UIViewController *)viewControllerForPresentingModalView {
	iPetHotelAppDelegate *app = [SystemUtils getAppDelegate];
	return app.viewController;
	// return self;
	// return [[CCDirector sharedDirector] openGLView];
}


- (void)adWhirlDidReceiveAd:(AdWhirlView *)adView {
	NSLog(@"%s",__FUNCTION__);
	/*
	[UIView beginAnimations:@"AdWhirlDelegate.adWhirlDidReceiveAd:"
					context:nil];
	
	[UIView setAnimationDuration:0.7];
	
	CGSize adSize = [adView actualAdSize];
	CGRect newFrame = adView.frame;
	
	newFrame.size = adSize;
	newFrame.origin.x = (self.view.bounds.size.width - adSize.width)/ 2;
	
	adView.frame = newFrame;
	
	[UIView commitAnimations];
	 */
}


@end
