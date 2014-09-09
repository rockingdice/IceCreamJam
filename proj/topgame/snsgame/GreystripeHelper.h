//
//  TapjoyHelper.h
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GreystripeDelegate.h"
#import "GSAdView.h"

@interface GreystripeHelper : NSObject<GreystripeDelegate> {
	NSMutableArray *pendingActions;
	BOOL isSessionInitialized;
	BOOL m_bShowHint;
	BOOL hasPopupOffer;
    BOOL isShowingOffer;
	GSAdView *myAdView;
}

+(GreystripeHelper *)helper;

- (BOOL) showOffers:(BOOL)showHint;
- (void) hideOffers;

- (void) initSession;

- (void) showNoOfferHint;

/*
-(void) checkTapjoyPoints;
-(void) getUpdatedPoints:(NSNotification*)notifyObj;
// 完成一项任务
-(void) completeAction:(NSString *)action;
// 提交等候的任务
- (void) completePendingAction;
 */
@end
