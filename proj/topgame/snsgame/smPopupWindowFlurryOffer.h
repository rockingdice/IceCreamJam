//
//  smWinQueueLogin.h
//  iPetHotel
//
//  Created by yang jie on 21/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "smPopupWindowBase.h"

@interface smPopupWindowFlurryOffer : smPopupWindowBase <UITableViewDelegate, UITableViewDataSource> {
	
@private
	int prizeType; // 0-gold, 1-leaf
    
}

@property (nonatomic, retain) IBOutlet UIView *bodyView;
@property (nonatomic, retain) IBOutlet UILabel *tableTitle;
@property (nonatomic, retain) IBOutlet UINavigationItem *titleContent;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *closeButton;
@property (nonatomic, retain) NSDictionary *setting;
@property (nonatomic, assign) int prizeType;

- (IBAction) closeWindow;


// 设置显示状态
+ (BOOL) isShowing;
+ (void) setShowing:(BOOL)show;

@end
