//
//  PopGameDelegate.h
//  PopGameDemo
//
//  Created by op-mac1 on 13-6-27.
//  Copyright (c) 2013年 op-mac1. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PopGameDelegate <NSObject>

@required

-(void) customResult:(NSDictionary*) dic;

-(void) versionResult:(NSDictionary*) dic;

@end
