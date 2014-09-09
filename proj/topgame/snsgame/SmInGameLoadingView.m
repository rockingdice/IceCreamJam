//
//  SmLoading.m
//  TapCar
//
//  Created by yang jie on 16/11/2011.
//  Copyright 2011 topgame.com. All rights reserved.
//

#import "SmInGameLoadingView.h"
#import "SystemUtils.h"

@implementation SmInGameLoadingView

- (id) init {
	self = [super init];
	if (self) {
		if (HUD == nil) {
			HUD = [[MBProgressHUD alloc] initWithView:self];
			[self addSubview:HUD];
			HUD.delegate = self;
			// HUD.labelText = @"Loading";
			HUD.labelText = @"";
			[HUD show:NO];
			[HUD release];
		} else {
			[self addSubview:HUD];
			[HUD show:NO];
		}
		CGRect winSize = [UIScreen mainScreen].applicationFrame;
		
		UIDeviceOrientation v = [SystemUtils getGameOrientation];
		if(v == UIDeviceOrientationLandscapeRight || v == UIDeviceOrientationLandscapeLeft) 
		{
			winSize = CGRectMake(0, 0, winSize.size.height, winSize.size.width);
		}
		
		self.frame = winSize; // CGRectMake(0, 0, winSize.width, winSize.height);
		self.backgroundColor = [UIColor blackColor];
		self.alpha = 0.6f;
	}
	return self;
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
	//smLog(@"Hud: %d", [hud retainCount]);
    // Remove HUD from screen when the HUD was hidded
	if (hud.superview != nil) {
		[hud removeFromSuperview];
	}
}

- (void) dealloc {
	[HUD hide:NO];
	[super dealloc];
}

-(void)setSize:(CGSize) s
{
    CGRect winSize = CGRectMake(0, 0, s.width, s.height);
    self.frame =winSize;
    CGRect r2 = HUD.frame;
    r2.origin.x = (winSize.size.width-r2.size.width)/2;
    r2.origin.y = (winSize.size.height-r2.size.height)/2;
    HUD.frame = r2;
}

@end
