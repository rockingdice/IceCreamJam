//
//  TapjoyHelper.h
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TJC_COMPLETE_TUTORIAL_IN_PET_INN @"32045a61-6966-463c-96a4-b2ef11e32e9d" // Complete Tutorial in Pet Inn

@interface TapjoyHelper : NSObject {
	NSMutableArray *pendingActions;
	BOOL isSessionInitialized;
    BOOL isWebModeEnabled;
}

@property(nonatomic,assign) BOOL isWebModeEnabled;

+(TapjoyHelper *)helper;

// 显示Offer
+ (void) showOffers;
+(void)showTapjoyOffers;

+ (void) showTapjoyOrLiMeiOffers;

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
