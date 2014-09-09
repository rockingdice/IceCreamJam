//
//  SmLoading.h
//  TapCar
//
//  Created by yang jie on 16/11/2011.
//  Copyright 2011 topgame.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

@interface SmInGameLoadingView : UIScrollView <MBProgressHUDDelegate> {

@private
	MBProgressHUD *HUD;
}

-(void)setSize:(CGSize) s;

@end
