//
//  TMBUInstalled.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-8-24.
//
//

#import "TMBUInstalled.h"
#import "TMBNetWork.h"
#import "TMBConfig.h"
#import "TMBSDKConfig.h"
#import "TMBJob.h"
#import "TMBLog.h"

@implementation TMBUInstalled

-(BOOL) do
{
    TMBSDKConfig *config = [[[TMBSDKConfig alloc] initAppId:appId] autorelease];
    if([[config getConfigOfKey:@"user.activity.installed"] intValue] ==1){
        [TMBJob addJobQueueWithTarget:self selectot:@selector(appInstalled) object:nil];
        return TRUE;
    }else{
        return FALSE;
    }
}

- (void) appInstalled
{
        TMBNetWork *net = [[[TMBNetWork alloc] initWithSecretKey:secretKey] autorelease];
        [net setTimeout:TMB_NET_TIMEOUT];
        NSString *url = [NSString stringWithFormat:[TMBNetWork fullUrl:TMB_USER_ACTIVITY_CHECK_APP_LIST_URL], [TMBNetWork host], appId];
        NSData *response = [net sendRequestWithURL:url Data:nil];
        if (response) {
            id decodeResponse = [TMBNetWork decodeServerJsonResult:[[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] autorelease]];
            if(decodeResponse && [decodeResponse isKindOfClass:[NSDictionary class]]){
                NSDictionary *appInfos = (NSDictionary *)decodeResponse;
                [self checkStats:appInfos];
            }
        }
}

-(void)checkStats:(NSDictionary *)appInfos
{
    if (appInfos) {
        int count = 0;
        NSMutableDictionary *checks = [[NSMutableDictionary alloc] init];
        for (id key in appInfos) {
            count++;
            if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:[appInfos objectForKey:key]]]){
                [checks setObject:@"1" forKey:key];
            }else{
                [checks setObject:@"0" forKey:key];
            }
            //send per 20
            if([checks count] >= 20){
                //[self performSelectorInBackground:@selector(sendCheckRes:) withObject:checks];
                [self sendCheckRes:checks];
                [checks release];
                checks = [[NSMutableDictionary alloc] init];
            }
        }
        if([checks count] > 0){
            //[self performSelectorInBackground:@selector(sendCheckRes:) withObject:checks];
            [self sendCheckRes:checks];
            [checks release];
        }
    }
}

-(void)sendCheckRes:(NSDictionary *)checks
{
    if (checks) {
        TMBNetWork *net = [[[TMBNetWork alloc] initWithSecretKey:secretKey] autorelease];
        [net setTimeout:TMB_NET_TIMEOUT];
        NSString *url = [NSString stringWithFormat:[TMBNetWork fullUrl:TMB_USER_ACTIVITY_CHECK_INSTALLED_URL], [TMBNetWork host], appId];
        NSMutableDictionary *param = [[[NSMutableDictionary alloc] init] autorelease];
        [param setObject:checks forKey:@"check_res"];
        [net sendRequestWithURL:url Data:param];
    }
}

@end
