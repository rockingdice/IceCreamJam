//
//  TMBAdProtocol.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-6-20.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

@protocol TMBAdProtocol

+ (NSDictionary *) noticeDelegateMap;

- (void) show;

- (void) close;

- (BOOL) isReady;

- (BOOL) isShow;

@end
