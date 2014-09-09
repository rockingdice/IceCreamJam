//
//  LiMeiHelper.h
//  
//  require framework: MapKit,EventKit,EventKitUI,CoreLocation
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCRate.h"
#import "MCPostman.h"

@interface MiniclipHelper : NSObject<MCRateDelegate,MCPostmanDelegate> {
	BOOL isSessionInitialized;
}


+(MiniclipHelper *)helper;

- (void) initSession:(NSDictionary *)options;
- (BOOL) showPopup;
- (BOOL) showUrgentBoard;
@end
