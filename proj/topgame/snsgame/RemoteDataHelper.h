//
//  RemoteDataHelper.h
//  FarmSlots
//
//  Created by lcg on 8/15/14.
//
//

#import <Foundation/Foundation.h>

#import "ASIFormDataRequest.h"

#define kRemoteDataHelperNotificationCreateAuthFinished  @"topgame.kRemoteDataHelperNotificationCreateAuthFinished"
#define kRemoteDataHelperNotificationUpdateDataFinished  @"topgame.kRemoteDataHelperNotificationUpdateDataFinished"
#define kRemoteDataHelperNotificationGetDataFinished  @"topgame.kRemoteDataHelperNotificationGetDataFinished"

#define kRemoteDataDefaultSecret @"default key"

@interface RemoteDataHelper : NSObject{
}

+ (RemoteDataHelper *) helper;

- (id) init;

- (void)createAuthWithUUID:(NSString*)uuid secret:(NSString*)secret;
- (void)createAuthWithUUID:(NSString*)uuid password:(NSString*)password secret:(NSString*)secret;

- (void)updateDataWithToken:(NSString*)token data:(NSString*)data secret:(NSString*)secret;
- (void)updateDataWithToken:(NSString*)token data:(NSString*)data secret:(NSString*)secret cas:(NSNumber*)cas key:(NSString*)key;

- (void)getDataWithToken:(NSString*)token secret:(NSString*)secret;

@end
