//
//  smWinQueueAlert.h
//  iPetHotel
//
//  Created by yang jie on 21/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "smPopupWindowBase.h"

@interface smPopupWindowNotice : smPopupWindowBase {
	
@private
    IBOutlet UITextView *textView;
    IBOutlet UIButton *closeBtn, *okBtn;
}
@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) NSDictionary *setting;
@property (nonatomic, retain) IBOutlet UIButton *closeBtn;
@property (nonatomic, retain) IBOutlet UIButton *okBtn;

- (IBAction) closeBox;
- (IBAction) doAction;

@end