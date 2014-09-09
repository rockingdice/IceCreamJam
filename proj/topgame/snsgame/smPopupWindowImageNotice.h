//
//  smWinQueueAlert.h
//  iPetHotel
//
//  Created by yang jie on 21/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "smPopupWindowBase.h"

@interface smPopupWindowImageNotice : smPopupWindowBase {
	
@private
    
    NSString *m_imageFilePath;
	
}
@property (nonatomic, retain) NSDictionary *setting;
@property (nonatomic, retain) IBOutlet UIButton *closeBtn;
@property (nonatomic, retain) IBOutlet UIImageView *adImage;
@property (nonatomic, assign) BOOL shouldDeleteImage;

- (IBAction) closeBox;
- (IBAction) doAction;

@end