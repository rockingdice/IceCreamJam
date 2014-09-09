//
//  TMBAdMyGames.m
//  TMBDemo
//
//  Created by gaofeng on 12-11-9.
//
//

#import "TMBAdMyGames.h"
#import "TMBConfig.h"
#import "TMBNetWork.h"

static TMBBaseAd *_sharedAdMyGames = nil;

@implementation TMBAdMyGames

+ (TMBBaseAd *) sharedAd
{
    if(!_sharedAdMyGames)
	{
        TMBBaseAd *adObj = [[self alloc] init];
        _sharedAdMyGames = adObj;
	}
	return _sharedAdMyGames;
}

- (void) loadData
{
    TMBNetWork *net = [[[TMBNetWork alloc] initWithSecretKey:secretKey] autorelease];
    [net setTimeout:TMB_NET_TIMEOUT];
    NSString *url = [NSString stringWithFormat:[TMBNetWork fullUrl:TMB_AD_WALL_URL], [TMBNetWork host], appId];
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] initWithCapacity:1] autorelease];
    [params setObject:@"moregame" forKey:@"wall_type"];
    [net sendAsyncRequestWithURL:url Data:params ResponseObj:self Method:@selector(loadDataFinish:)];
}

@end
