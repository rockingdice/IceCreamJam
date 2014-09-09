//
//  smWinQueueLoginCell.m
//  iPetHotel
//
//  Created by yang jie on 25/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import "smPopupWindowFlurryOfferCell.h"


@implementation smPopupWindowFlurryOfferCell
@synthesize icon, coinIcon, appName, downBtn, appPrice, prizeGold;

- (void)dealloc {
	self.icon = nil;
	self.coinIcon = nil;
	self.appName = nil;
	self.downBtn = nil;
	self.appPrice = nil;
	self.prizeGold = nil;
    [super dealloc];
}

@end
