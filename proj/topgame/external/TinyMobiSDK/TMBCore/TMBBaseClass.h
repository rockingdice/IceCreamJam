//
//  TMBBaseController.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-12.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//
#import "TinyMobiDelegate.h"

@interface TMBBaseClass : NSObject
{
    NSString *appId;
    NSString *secretKey;
    id<TinyMobiDelegate> delegate;
}

//TinyMoBi app id
@property (nonatomic, retain) NSString *appId;
//TinyMoBi secret key
@property (nonatomic, retain) NSString *secretKey;
//TinyMoBi delegate
@property (nonatomic, assign) id <TinyMobiDelegate> delegate;

@end
