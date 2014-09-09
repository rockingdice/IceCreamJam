//
//  FacebookHelperDelegate.h
//  PokerBonus
//
//  Created by Leon Qiu on 3/25/13.
//
//

#import <Foundation/Foundation.h>

@protocol FacebookHelperDelegate <NSObject>

@optional
// 获取好友列表
- (void) onGetAllFacebookFriends:(NSArray *)friends withError:(NSError *)error;
- (void) onGetFacebookMessages:(NSArray *)msgs withError:(NSError *)error;
- (void) onGetUserInfo:(NSDictionary *)info withError:(NSError *)error;
@end
