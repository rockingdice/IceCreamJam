//
//  LiMeiHelper.h
//  
//  require framework: MapKit,EventKit,EventKitUI,CoreLocation
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AdjustHelper : NSObject {
	BOOL isSessionInitialized;
}


+(AdjustHelper *)helper;

-(void) initSession;
- (void) trackRevenue:(int) price ofItem:(NSString *)itemID;

@end
