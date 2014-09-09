//
//  LocalNotificationHelper.m
//  TapCar
//
//  Created by yang jie on 19/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LocalNotificationHelper.h"
#import "SystemUtils.h"

@implementation LocalNotificationHelper
@synthesize notificationCount, localNotificationEnable;
static LocalNotificationHelper *sinleton = nil;

+ (id)sharedHelper {
	@synchronized(self) {
		if (sinleton == nil) {
			sinleton = [[LocalNotificationHelper alloc] init];
		}
	}
	return sinleton;
}

- (id)init {
	self = [super init];
	if (self) {
		self.notificationCount = 0;
		self.localNotificationEnable = [self isLocalNotificationEnabled];
	}
	return self;
}

- (id)setLocalNotification:(int)popTime body:(NSString *)body action:(NSString *)action soundName:(NSString *)soundName {
	SNSLog(@"Start send notification!popTime:%d", popTime);
	/* 判断本地通知启用 */
	if ( !localNotificationEnable ) {
		// Notifications are not enabled!
		return nil;
	}
	
	// Create the local noticiation and setup
	UILocalNotification *notification = [[[UILocalNotification alloc] init] autorelease];
    if ( notification ) {
		//先判断一下时间是否合理（必须在早10点到22点之间）
		//NSLog(@"day:::::::%@", [[NSDate dateWithTimeIntervalSince1970:popTime] description]);
		int notificationTimeForDay = (int)(popTime % 86400);
		if (notificationTimeForDay < 36000) {
			//小于10点的时候顺延至10点
			SNSLog(@"[%s] - [LINE:%d] time:%d", __FUNCTION__, __LINE__, 36000 - notificationTimeForDay);
			popTime += (36000 - notificationTimeForDay);
		} else if (notificationTimeForDay > 79200) {
			//大于22点的时候顺延至明天10点之后
			popTime += (86400 - notificationTimeForDay + 36000);
		}

		
		//create NSDate
		NSDate *date = [NSDate dateWithTimeIntervalSince1970:popTime];
		SNSLog(@"[%s] - [line:%d] - in time:%d timestemp:%@ timeForDay:%d", __FUNCTION__, __LINE__, popTime, [date description],  notificationTimeForDay);
		
		// Set the time zone created earlier
		notification.fireDate = date;
		notification.timeZone = [NSTimeZone defaultTimeZone];
		
		// Fill in the harvest info
		notification.alertBody = body;
		notification.alertAction = action;
		//8lb james fix notification
		// Use the default sound
        if (!body && !action ) {
            notification.soundName	= nil;            
        } else {
			if (soundName == nil) {
				notification.soundName = UILocalNotificationDefaultSoundName;
			} else {
				notification.soundName = soundName;
			}
		}
		//8lb end
		// Add just +1 to the badge number
		++notificationCount;
		notification.applicationIconBadgeNumber = notificationCount;
		SNSLog(@"[%s] - [LINE:%d] - badge:%d", __FUNCTION__, __LINE__, notification.applicationIconBadgeNumber);
		
		// Push the local notification to the application
		// This will cause the notification to trigger
		[[UIApplication sharedApplication] scheduleLocalNotification:notification];
	}
	return notification;
}

- (void)cancelLocalNotification {
	if([self isLocalNotificationEnabled])
		[[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void)dealloc {
	
	[super dealloc];
}

// 是否支持本地通知
- (BOOL) isLocalNotificationEnabled
{
	Class localNotificationClass = NSClassFromString(@"UILocalNotification");
	
	// this iOS may not know what UILocalNotification is
	if (localNotificationClass) 
	{
		return YES;
	}
	
	return NO;
}



@end
