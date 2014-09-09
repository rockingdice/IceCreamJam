//
//  NetworkHelper.h
//  iPetHotel
//
//  Created by LEON on 11-6-7.
//  Copyright 2011 PlayDino. All rights reserved.
//
/*
 调用checkNetworkStatus方法后如果发现网络状态有变化，会发送一个通知kNetworkHelperNetworkStatusChanged。
 */

#import <Foundation/Foundation.h>
#import "Reachability.h"

#define kNetworkHelperNetworkStatusChanged @"kNetworkHelperNetworkStatusChanged"

@interface NetworkHelper : NSObject {
	Reachability *hostReach;
	Reachability *internetReach;
	//BOOL connectedToHost;
    //BOOL connectedToInternet;
}

@property (nonatomic,assign) BOOL connectedToHost;
@property (nonatomic,assign) BOOL connectedToInternet;

+(NetworkHelper *)helper;
+(BOOL) isConnected;
-(void) checkNetworkStatus;
- (void) reachabilityChanged: (NSNotification* )note;

@end
