//
//  TinyMobiConnect.h
//  TinyMobi SDK
//  version: 2.0.3, release date: 2012-9-12
//
//  Created by gaofeng on 12-6-20.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//
//  The TinyMobi access file encapsulates the whole process.
//  The user only needs to call the method of this interface and that will complete the service with TinyMobi.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TinyMobiDelegate.h"

//operation define
#define TMB_OPT_APP_ORIENTATION @"tmb_app_orientation"
#define TMB_OPT_IS_POP_AUTO_OPEN @"tmb_pop_auto_open"

//app orientation define
#define TMB_APP_ORIENTATION_PORTRAIT    @"1"
#define TMB_APP_ORIENTATION_LANDSCAPE   @"0"

#define TMB_POP_IS_NOT_AUTO_OPEN @"0"
#define TMB_POP_IS_AUTO_OPEN @"1"

@interface TinyMobiConnect : NSObject
{
    NSString *appId;
    NSString *secretKey;
    id <TinyMobiDelegate> delegate;
}
//TinyMoBi app id
@property (nonatomic, retain) NSString *appId;
//TinyMoBi secret key
@property (nonatomic, retain) NSString *secretKey;
//TinyMoBi delegate
@property (nonatomic, assign) id <TinyMobiDelegate> delegate;

//get singleton obj of TinyMobi
+ (TinyMobiConnect *) sharedTinyMobi;

//TinyMobi delegate
- (void) start;

//display TinyPop advertisement
- (void) showTinyPop:(UIViewController *)viewController;

//TinyPop ready
- (BOOL) isTinyPopReady;

//display TinyWall advertisement
- (void) showTinyWall:(UIViewController *)viewController;

//TinyWall ready
- (BOOL) isTinyWallReady;

//display TinyMyGames advertisement
- (void) showTinyMyGames:(UIViewController *)viewController;

//get rewards info
- (NSArray *) getRewardsInfo;

//finished rewards
- (BOOL) finishRewardsInfo:(NSArray *)rewardsIdArray;

//use sandbox
- (void) useSandbox:(BOOL) isUseSandbox;

//set option
- (void) setOption:(NSString *)optionName WithValue:(NSString*)optionValue;
@end
