//
//  TMBLog.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-18.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import "TMBLog.h"
#import "TMBConfig.h"

static NSMutableString *_tmb_debug_log = nil;
@implementation TMBLog

+(void)log: (NSString *)flag :(id) content
{
#ifdef TMB_DEBUG
    NSLog(@"[%@][TMB %@]:%@", [NSThread currentThread], flag, content);
    if (!_tmb_debug_log) {
        _tmb_debug_log = [[NSMutableString alloc] init];
    }
    
    [_tmb_debug_log insertString:[NSString stringWithFormat:@"[%@] [%@] [TMB %@]:%@\n", [NSDate date] ,[NSThread currentThread], flag, content] atIndex:0];
#endif
}

+(NSMutableString *)getLog
{
    return _tmb_debug_log;
}

+(void)clean
{
    if (_tmb_debug_log) {
        [_tmb_debug_log setString:@""];
    }
}
@end
