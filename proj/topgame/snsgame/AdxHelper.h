//
//  LiMeiHelper.h
//  
//  require framework: MapKit,EventKit,EventKitUI,CoreLocation
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdXTracking.h"

@interface AdxHelper : NSObject {
	BOOL isSessionInitialized;
    AdXTracking *tracker;
    BOOL isFirstTimeLaunch;
}


+(AdxHelper *)helper;

-(void) initSession;
-(BOOL) handleOpenURL:(NSURL *)url;
-(void) reportAppOpen;

- (void) trackPurchase:(NSString *)price;
- (void) trackPurchase:(NSString *)price currency:(NSString *)currency withTransaction:(SKPaymentTransaction *)transaction sandbox:(int)isSandbox;

@end
