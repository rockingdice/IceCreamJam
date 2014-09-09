//
//  TMBBaseController.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-12.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import "TMBBaseClass.h"

@implementation TMBBaseClass
@synthesize appId;
@synthesize secretKey;
@synthesize delegate;

- (void) dealloc
{
    [appId release];
    [secretKey release];
    [super dealloc];
}

@end
