//
//  TMBViewProtocol.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-18.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

@protocol TMBViewProtocol <NSObject>

@optional
- (BOOL) isShow;

- (void) loadAdPre;

- (void) loadAd;

- (void) loadAdFinish;

- (void) close;
@end
