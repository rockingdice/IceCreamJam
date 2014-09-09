//
//  InAppStoreProtocol.h
//  iPetHotel
//
//  Created by LEON on 11-6-8.
//  Copyright 2011 PlayDino. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol InAppStoreDelegate

@required
// 交易完成通知，应该在这里关闭等候界面
// info中包含两个字段:
// itemId : NSString, 购买的产品ID
// amount : NSNumber, 购买数量
-(void) transactionFinished:(NSDictionary *)info;
// 交易取消通知，应该在这里关闭等候界面
-(void) transactionCancelled;
@optional
// 恢复购买通知
-(void) restoreFinished:(NSDictionary *)info;

@end
