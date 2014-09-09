//
//  LocalNotificationHelper.h
//  TapCar
//
//  Created by yang jie on 19/10/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LocalNotificationHelper : NSObject {
	
@private
	
}

@property (nonatomic, assign) int notificationCount; //本地通知数量
@property (nonatomic, assign) BOOL localNotificationEnable; //本地通知开关，默认为开启

+ (id)sharedHelper;

//发送本地系统通知
- (id)setLocalNotification:(int)popTime body:(NSString *)body action:(NSString *)action soundName:(NSString *)soundName;
//取消所有本地通知
- (void)cancelLocalNotification;

// 是否支持本地通知
- (BOOL)isLocalNotificationEnabled;

@end
