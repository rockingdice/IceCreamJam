//
//  iOmniataHelper.m
//  JellyMania
//
//  Created by lipeng on 14-5-29.
//
//

#import "iOmniataHelper.h"
#import "SystemUtils.h"
#import "ASIFormDataRequest.h"
#import "StringUtils.h"
#import "SystemUtils.h"

#ifdef MINICLIP_DEBUG
#define iOmniataAPIKEY @"77313b33"
#else
#define iOmniataAPIKEY @"f0c46163"
#endif

@implementation iOmniataHelper
static iOmniataHelper *_gHelper = nil;

+ (iOmniataHelper *) helper
{
    if(!_gHelper) {
        _gHelper = [[iOmniataHelper alloc] init];
    }
    return _gHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        NSString * user_id = [SystemUtils getCurrentUID];
        bool debug = false;
#ifdef MINICLIP_DEBUG
        debug = true;
#endif
        [iOmniataAPI initializeWithApiKey:iOmniataAPIKEY UserId:user_id AndDebug:debug]; // Tracks against realtime event monitor
    }
    return self;
}

- (void)requestContent
{
    int chanelId = 37;
#ifdef MINICLIP_DEBUG
    chanelId = 36;
#endif
    NSString * link = [NSString stringWithFormat:@"https://api.omniata.com/channel?uid=%@&api_key=%@&channel_id=%d",[SystemUtils getCurrentUID],iOmniataAPIKEY,chanelId];
    SNSLog(@"link:%@",link);
    NSURL *url = [NSURL URLWithString:link];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"GET"];
	[request setDelegate:self];
    [request startAsynchronous];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    int status = request.responseStatusCode;
	if(status>=400) {
		return;
	}
    NSString *text = [request responseString];
    NSDictionary *dict = [StringUtils convertJSONStringToObject:text];
    NSArray * list = [dict objectForKey:@"content"];
    if ([list count] > 0) {
        BOOL flag  = [[[list objectAtIndex:0] objectForKey:@"mini_game"] boolValue];
        [SystemUtils setNSDefaultObject:[NSNumber numberWithBool:flag] forKey:@"showMiniGame"];
    }
    SNSLog(@"resp:%@", text);

}

- (void)trackEvent:(NSDictionary *)dic
{
    NSString * key = [dic objectForKey:@"key"];
    NSDictionary * value = [dic objectForKey:@"value"];
    
    if ([SystemUtils isJailbreak]) {
        if (![key isEqualToString:@"mc_info"] && ![key isEqualToString:@"om_load"]) {
            return;
        }
    }
    
    if ([key isEqualToString:@"om_load"]) {
        [iOmniataAPI trackLoadEventWithParameters:value];
    }else{
        [iOmniataAPI trackEvent:key :value];
    }
    
    if ([key isEqualToString:@"om_load"]) {
        [self requestContent];
    }
}

- (void)trackPurchaseEvent:(double)amount currency_code:(NSString *)currency_code additional_params:(NSDictionary*)additional_params
{
    [iOmniataAPI trackPurchaseEvent:amount currency_code:currency_code additional_params:additional_params];
}

@end
