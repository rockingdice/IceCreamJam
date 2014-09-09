//
//  smWindowQueueDelegate.m
//  iPetHotel
//
//  Created by yang jie on 22/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import "smPopupWindowBase.h"

@implementation smPopupWindowBase
@synthesize delegate, timeOut;

- (void) viewDidLoad {
	[super viewDidLoad];
	/*
	UIScrollView *mainView = [[UIScrollView alloc] init];
	if ([self IsDeviceIPad]) {
		NSLog(@"is ipad");
        self.view.frame = CGRectMake(768/2-320/2, 1024/2-480/2, self.view.frame.size.width, self.view.frame.size.height);
    } else {
		NSLog(@"is iphone");
		self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	}
	mainView.frame = CGRectMake(0, WINDOW_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT);
	[mainView addSubview:self.view];
	self.view = mainView;
	[UIView beginAnimations:@"popoWindow" context:UIGraphicsGetCurrentContext()];
	[UIView setAnimationBeginsFromCurrentState:NO];
	[UIView setAnimationDuration:0.8f];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDelegate:self];
	//[UIView setAnimationDidStopSelector:@selector(cleanupAchievementBox)]; //动画结束时的委托处理
	self.view.frame = CGRectMake(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
	[UIView commitAnimations];
	[mainView release];
	 */
}

- (void) dealloc {
    if (delegate) {
        // [(NSObject *)delegate release];
    }
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) viewDidUnload {
    [super viewDidUnload];
    self.delegate = nil;
}
- (void)didDialogClose {
	[self.delegate winWasClose];
}

// 检查目前是否可以显示
- (BOOL) isReadyToShow
{
    return YES;
}


@end
