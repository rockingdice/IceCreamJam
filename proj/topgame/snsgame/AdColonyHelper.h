//
//  TapjoyHelper.h
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdColonyPublic.h"


@interface AdColonyHelper : NSObject<AdColonyDelegate,AdColonyTakeoverAdDelegate> {
	NSMutableArray *pendingActions;
	BOOL isSessionInitialized;
	BOOL m_bShowHint;
	int  prizeGold;
	BOOL hasVideo;
}

@property (nonatomic, assign) int prizeGold;

+(AdColonyHelper *)helper;

-(BOOL) showOffers:(BOOL)showHint;

-(void) initSession;

- (void) showNoOfferHint;

- (void) setPrizeGold:(int)gold;

/*
-(void) checkTapjoyPoints;
-(void) getUpdatedPoints:(NSNotification*)notifyObj;
// 完成一项任务
-(void) completeAction:(NSString *)action;
// 提交等候的任务
- (void) completePendingAction;
 */
@end
