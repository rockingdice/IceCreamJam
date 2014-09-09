//
//  FlurryUtils.h
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "FlurryAdDelegate.h"

@interface FlurryHelper : NSObject<ASIHTTPRequestDelegate, FlurryAdDelegate> {
	NSArray *arrayInfo;
	NSMutableDictionary *clickedAppNames;
	ASIHTTPRequest *req;
	BOOL  isFlurrySessionStart;
	BOOL  isShowingVideo;
	BOOL  isShowingOffer;
	int   offerPrizeGold;
	int   offerPrizeType; // 0-gold, 1-leaf
	int   offerPrizeLeaf;
	int   videoPrizeGold;
}

@property (nonatomic,retain) NSMutableDictionary * clickedAppNames;
@property (nonatomic, assign) BOOL isFlurrySessionStart;
@property (nonatomic, assign) BOOL isShowingVideo;
@property (nonatomic, assign) BOOL isShowingOffer;
@property (nonatomic, assign) int  videoPrizeGold;
@property (nonatomic, assign) int  offerPrizeType;
@property (nonatomic, assign) int  offerPrizeGold;
@property (nonatomic, assign) int  offerPrizeLeaf;

+(FlurryHelper *)helper;

+(int)getOfferCount;
// 获取可用的Offers列表
+(NSArray *)getOffers;
// 显示Offer窗口
+(void) showOffers:(BOOL)showHintIfNoOffer;
// 显示Offer窗口，自定义奖励类型
// type:0-金币, 1-叶子
+(void) showOffers:(BOOL)showHintIfNoOffer prizeType:(int)type;

+(BOOL)hasVideoOffer;
+(void) showVideoOffer;
+(void) showVideoOffers:(BOOL)showNoOfferHint;

+(BOOL) hasRecommendation;
+(void) showRecommendation;

-(void)getRewards;
-(void)getRewardsLazy;

- (void) setVideoPrizeGold:(int)gold;
- (void) setOfferPrizeGold:(int)gold;

// init flurry session
-(void)initFlurrySession;


@end
