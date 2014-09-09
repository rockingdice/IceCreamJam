//
//  smWinQueueAlertAction.h
//  iPetHotel
//
//  Created by yang jie on 22/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface smPopupWindowAction:NSObject {
    
@private
	
}

+ (void) doAction:(NSString *)action prizeCoin:(int)prizeCoin prizeLeaf:(int)prizeLeaf;
+ (void) doAction:(NSString *)action withInfo:(NSDictionary *)info;

@end
