//
//  TMBCreDelegate.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-8-1.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

@protocol TMBCreDelegate <NSObject>

- (void)adClose:(NSDictionary *)args;

- (void)appInstall:(NSDictionary *)args;

- (void)appPlay:(NSDictionary *)args;

- (void)openNewAd:(NSDictionary *)args;

- (void)openUrl:(NSDictionary *)args;
@end