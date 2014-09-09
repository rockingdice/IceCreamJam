//
//  TMBLog.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-18.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

@interface TMBLog : NSObject

+(void)log: (NSString *)flag :(id) content;

+(NSMutableString *)getLog;

+(void)clean;
@end
