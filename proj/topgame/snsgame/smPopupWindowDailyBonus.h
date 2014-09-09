//
//  smWIndowQueueRunLogin.h
//  iPetHotel
//
//  Created by yang jie on 22/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "smPopupWindowBase.h"


@interface smPopupWindowDailyBonus:smPopupWindowBase {
	BOOL addReward;//是否添加奖励	
@private
    
}

@property (nonatomic, retain) IBOutlet UILabel *dayNum, *todayCoin, *tomorrowCoin;
@property (nonatomic, retain) IBOutlet UIImageView *todayIcon, *tomorrowIcon;
@property (nonatomic, retain) NSDictionary *setting;
@property (nonatomic, readwrite) BOOL addReward;

- (IBAction) doAction;

@end
