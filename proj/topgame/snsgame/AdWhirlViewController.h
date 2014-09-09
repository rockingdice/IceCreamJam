//
//  AdmobViewController.h
//  navigation
//
//  Created by LEON on 11-5-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdWhirlDelegateProtocol.h"
#import "AdWhirlView.h"

@interface AdWhirlViewController : UIViewController <AdWhirlDelegate> {

	AdWhirlView *bannerView_;
	
	// GADBannerView *bannerView_;
	// id<GADBannerViewDelegate> *delegate;
}

// @property (nonatomic, assign) id<GADBannerViewDelegate> *delegate;

@end
