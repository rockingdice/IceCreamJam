//
//  smWinQueueAlertAction.m
//  iPetHotel
//
//  Created by yang jie on 22/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import "smPopupWindowAction.h"
#import "SystemUtils.h"
#import "StringUtils.h"
#import "StatSendOperation.h"
#import "ASIFormDataRequest.h"
#import "SnsServerHelper.h"

@implementation smPopupWindowAction

//打开游戏中各种窗口
+ (void)doAction:(NSString *)action prizeCoin:(int)prizeCoin prizeLeaf:(int)prizeLeaf {
    //NSLog(@"开始做各种打开窗口、给钱等等的事情");
	if (prizeCoin > 0) {
		//[[GameData gameData] addCoines:prizeCoin];
        //[[AudioPlayer sharedPlayer] playEffect:kEffect_Coins];
        [SystemUtils addGameResource:prizeCoin ofType:kGameResourceTypeCoin];
	}
	if (prizeLeaf > 0) {
        [SystemUtils addGameResource:prizeLeaf ofType:kGameResourceTypeLeaf];
		//[[GameData gameData] addTreats:prizeLeaf];
        //[[AudioPlayer sharedPlayer] playEffect:kEffect_Coins];
	}
	
	if ([action isKindOfClass:[NSString class]] && [action length]>3) {
        NSRange r = [action rangeOfString:@"://"];
		if(r.location!=NSNotFound)
		{
			// 处理打开网页连接
			// [[UIApplication sharedApplication] openURL:[NSURL URLWithString:action]];
            [SystemUtils openAppLink:action];
		}
		else {
			SNSLog(@"%s - action:%@", __FUNCTION__, action);
			// [[CGameScene gameScene] runCommand:action];
            [SystemUtils runCommand:action];
		}
	}
}


//打开游戏中各种窗口
+ (void)doAction:(NSString *)action withInfo:(NSDictionary *)info {
	SNSLog(@"%s: info:%@", __func__, info);
	int prizeCoin = [[info objectForKey:@"prizeCoin"] intValue];
	int prizeLeaf = [[info objectForKey:@"prizeLeaf"] intValue];
	int prizeExp  = [[info objectForKey:@"prizeExp"] intValue];
    int level     = [[info objectForKey:@"setLevel"] intValue];
    int pendingPrize = [[info objectForKey:@"pendingPrize"] intValue];
    int noticeID = [[info objectForKey:@"noticeID"] intValue];

    NSString *items = [info objectForKey:@"prizeItems"];
    if(items && [items length]>0) {
        NSArray *arr = [items componentsSeparatedByString:@","];
        for (NSString *str in arr) {
            NSArray *arr2 = [str componentsSeparatedByString:@":"];
            if([arr2 count]==2) {
                int resType = [[arr2 objectAtIndex:0] intValue];
                int count = [[arr2 objectAtIndex:1] intValue];
                if(resType>0 && count>0) {
                    SNSLog(@"add resource: type:%i count:%i", resType, count);
                    [SystemUtils addGameResource:count ofType:resType];
                }
            }
        }
    }
    
    //NSLog(@"开始做各种打开窗口、给钱等等的事情");
	if (prizeCoin > 0) {
        [SystemUtils addGameResource:prizeCoin ofType:kGameResourceTypeCoin];
		// [[GameData gameData] addCoines:prizeCoin];
	}
	if (prizeLeaf > 0) {
        [SystemUtils addGameResource:prizeLeaf ofType:kGameResourceTypeLeaf];
	}
	if (prizeExp > 0) {
        [SystemUtils addGameResource:prizeExp ofType:kGameResourceTypeExp];
	}
    if(level>0) {
        [SystemUtils addGameResource:level ofType:kGameResourceTypeLevel];
    }
	if(prizeExp>0 || prizeCoin>0 || prizeLeaf>0) {
		// [[AudioPlayer sharedPlayer] playEffect:kEffect_Coins];
	}
	
    BOOL doAction = YES;
    if(pendingPrize==1 && noticeID>0) {
        NSDictionary *noticeInfo = [SystemUtils getNSDefaultObject:[NSString stringWithFormat:@"prizeNotice-%d",noticeID]];
        if(noticeInfo && [noticeInfo isKindOfClass:[NSDictionary class]]) {
            doAction = NO;
            NSString *prizeCond = [noticeInfo objectForKey:@"prizeCond"];
            if(prizeCond && [prizeCond isEqualToString:@"install"]) {
                NSString *key = @"pendingInstallPrize";
                NSString *prizeList = [SystemUtils getNSDefaultObject:key];
                if(prizeList!=nil && [prizeList length]>0) prizeList = [prizeList stringByAppendingFormat:@",%d",noticeID];
                else prizeList = [NSString stringWithFormat:@"%d",noticeID];
                [SystemUtils setNSDefaultObject:prizeList forKey:key];
                doAction = YES;
            }
            else {
                // 标记点击状态
                NSString *clickKey = [NSString stringWithFormat:@"prizeClick_%d",noticeID];
                [[SystemUtils getGameDataDelegate] setExtraInfo:@"1" forKey:clickKey];
                [[SnsServerHelper helper] startCrossPromoTask:noticeInfo];
            }
        }
    }
    if(doAction) {
        if ([action isKindOfClass:[NSString class]] && [action length]>3) {
            NSRange r = [action rangeOfString:@"://"];
            if (r.location!=NSNotFound) {
                // 处理打开网页连接
                // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:action]];
                [SystemUtils openAppLink:action];
            } else {
                // [[CGameScene gameScene] runCommand:action];
                [SystemUtils runCommand:action];
            }
        }
    }
    
    // send noticeReport
    if(noticeID>0) {
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:noticeID] forKey:kClickedNoticeID];
        
        SyncQueue *syncQueue = [SyncQueue syncQueue];
        NoticeReportOperation *repOp = [[NoticeReportOperation alloc] initWithManager:syncQueue andDelegate:nil];
        repOp.noticeID = noticeID; repOp.actionType = kSNSNoticeActionTypeClick;
        [syncQueue.operations addOperation:repOp];
        [repOp release];
    }
    
}


@end
