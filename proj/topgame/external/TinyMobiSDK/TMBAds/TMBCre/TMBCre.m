//
//  TMBCre.m
//  TMBDemo
//
//  Created by 高 峰 on 13-2-28.
//
//

#import "TMBCre.h"
#import "TMBLog.h"
#import "TMBGTMNSDictionary+URLArguments.h"

@implementation TMBCre
@synthesize creDelegate;

- (void) run:(NSURL *)command
{
    if (command) {
        if ([[command scheme] isEqualToString:@"js"] || [[command scheme] isEqualToString:@"tmb"]) {
            NSString *method = [command host];
            NSString *query = [command query];
            NSDictionary *args = [NSDictionary TMBGTM_dictionaryWithHttpArgumentsString:query];
            if ([method isEqualToString:@"window.close"]) {
                method = @"adClose";
            }else if([method isEqualToString:@"open"] || [method isEqualToString:@"install"]){
                method = @"appInstall";
            }else if([method isEqualToString:@"play"]){
                method = @"appPlay";
            }
            //call method
            if (method && [method length]>0) {
                SEL fun = NSSelectorFromString([NSString stringWithFormat:@"%@:", method]);
                if (creDelegate && [creDelegate respondsToSelector:fun]) {
                    [creDelegate performSelector:fun withObject:args];
                }else{
                    [TMBLog log:@"CRE" :[NSString stringWithFormat:@"unsupport method %@", method]];
                }
            }else{
                [TMBLog log:@"CRE" :[NSString stringWithFormat:@"empty method %@", command]];
            }
        }else{
            NSDictionary *args = [NSDictionary dictionaryWithObject:[command absoluteString] forKey:@"url"];
            if (creDelegate && [creDelegate respondsToSelector:@selector(openUrl:)]) {
                [creDelegate performSelector:@selector(openUrl:) withObject:args];
            }else{
                [[UIApplication sharedApplication] openURL:command];
            }
        }
    }else{
        [TMBLog log:@"CRE" :[NSString stringWithFormat:@"unsupport url command %@", command]];
    }
}
@end
