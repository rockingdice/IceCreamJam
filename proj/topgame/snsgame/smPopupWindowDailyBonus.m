//
//  smWIndowQueueRunLogin.m
//  iPetHotel
//
//  Created by yang jie on 22/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import "smPopupWindowDailyBonus.h"
#import "smPopupWindowAction.h"
#import "SystemUtils.h"
#ifndef SNS_DISABLE_FLURRY_V1
#import "FlurryHelper.h"
#endif

@implementation smPopupWindowDailyBonus
@synthesize dayNum, todayCoin, tomorrowCoin, todayIcon, tomorrowIcon;
@synthesize setting,addReward;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		//self.setting = [[NSDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
	self.dayNum = nil;
	self.todayCoin = nil;
	self.tomorrowCoin = nil;
	self.todayIcon = nil;
	self.tomorrowIcon = nil;
	self.setting = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - User method

- (IBAction)doAction {
	// GameData *gamedata = [GameData gameData];
	if(addReward){
		if ([[setting objectForKey:@"todayLeaf"] intValue] > 0) {
			[smPopupWindowAction doAction:[setting objectForKey:@"action"] prizeCoin:0 prizeLeaf:[[setting objectForKey:@"todayLeaf"] intValue]];
		} else {
			[smPopupWindowAction doAction:[setting objectForKey:@"action"] prizeCoin:[[setting objectForKey:@"todayCoin"] intValue] prizeLeaf:0];
		}
	}
    [super closeDialog];
}

- (void)didDialogClose {
#ifndef SNS_DISABLE_FLURRY_V1

	[FlurryHelper helper].isShowingOffer = NO;
#endif
	[super didDialogClose];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	dayNum.text = [setting objectForKey:@"dayNum"];
	dayNum.textAlignment = UITextAlignmentCenter;
	if ([[setting objectForKey:@"todayLeaf"] intValue] > 0) {
		todayCoin.text = [setting objectForKey:@"todayLeaf"];
		todayIcon.image = [UIImage imageNamed:@"wqRunLoginLeafage.png"];
	} else {
		todayCoin.text = [setting objectForKey:@"todayCoin"];
		todayIcon.image = [UIImage imageNamed:@"wqRunLoginYB.png"];
	}

	if ([[setting objectForKey:@"tomorrowLeaf"] intValue] > 0) {
		tomorrowCoin.text = [setting objectForKey:@"tomorrowLeaf"];
		tomorrowIcon.image = [UIImage imageNamed:@"wqRunLoginLeafage.png"];
	} else {
		tomorrowCoin.text = [setting objectForKey:@"tomorrowCoin"];
		tomorrowIcon.image = [UIImage imageNamed:@"wqRunLoginYB.png"];
	}
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.setting = nil;
	self.dayNum = nil;
	self.todayCoin = nil;
	self.tomorrowCoin = nil;
	self.todayIcon = nil;
	self.tomorrowIcon = nil;
}

@end
