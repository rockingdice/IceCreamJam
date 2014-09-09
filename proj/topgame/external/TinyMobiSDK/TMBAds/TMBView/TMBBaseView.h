//
//  TMBBaseView.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-18.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMBBaseAd.h"
#import "TMBViewProtocol.h"

@interface TMBBaseView : UIViewController <TMBViewProtocol>
{
    TMBBaseAd *adController;
    BOOL showFlag;
}
@property (nonatomic, assign) TMBBaseAd *adController;
@property (assign) BOOL showFlag;

-(CGRect) getAdFrame;

- (void) show;

@end
