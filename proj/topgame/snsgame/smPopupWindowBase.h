//
//  smWindowQueueDelegate.h
//  iPetHotel
//
//  Created by yang jie on 22/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SmDialogBaseController.h"
#import "SystemUtils.h"
#import "smPopupWindowQueue.h"
#import "smPopupWindowQueueDelegate.h"

#ifndef SNSLocal
#define SNSLocal(_arg1_ , _arg2_) [SystemUtils getLocalizedString:_arg1_]
#endif

@interface smPopupWindowBase : SmDialogBaseController<smPopupWindowQueueDelegate> {
    smPopupWindowQueue *delegate;
}

@property (nonatomic, assign) smPopupWindowQueue *delegate;
@property (nonatomic) float timeOut;

@end

