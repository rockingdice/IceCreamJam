//
//  TapjoyHelper.h
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TapjoyHelper2 : NSObject {
	NSMutableArray *pendingActions;
	BOOL isSessionInitialized;
    BOOL isWebModeEnabled;
}

@property(nonatomic,assign) BOOL isWebModeEnabled;

+(TapjoyHelper2 *)helper;

// 显示Offer
-(void) showOffers;

-(void) initTapjoySession;

-(void)checkPointsLazy;
-(void) checkTapjoyPoints;
-(void) getUpdatedPoints:(NSNotification*)notifyObj;
// 完成一项任务
-(void) completeAction:(NSString *)action;
// 提交等候的任务
- (void) completePendingAction;

// show tapjoy feature app
- (BOOL) startGettingTapjoyFeaturedApp;
- (void) onGetTapjoyFeaturedApp:(NSNotification*)notifyObj;

@end
