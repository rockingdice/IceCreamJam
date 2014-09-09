//
//  AdmobViewController.h
//  navigation
//
//  Created by LEON on 11-5-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GADBannerView.h"
#import "GADBannerViewDelegate.h"

@interface AdmobViewController : UIViewController <GADBannerViewDelegate> {

	GADBannerView *bannerView_;
	BOOL adLoaded;
	BOOL adStopped;
    BOOL isShowing;
    CGSize bannerSize;
}

@property (nonatomic, assign) BOOL adLoaded;
@property (nonatomic, assign) BOOL adStopped;
@property (nonatomic, assign) BOOL isShowing;

- (void) updatePosition;

@end
