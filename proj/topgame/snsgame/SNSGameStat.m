//
//  SNSGameStat.m
//  TapCar
//
//  Created by XU LE on 12-2-13.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "SNSGameStat.h"
#import "SystemUtils.h"
#import "SBJson.h"

@implementation SNSGameStat

@synthesize userID, updateDate, userExp, installTime,timeSinceInstall,playTime,playCount,payCount,payTotal,payLastTime;

@synthesize levelUpInfo,paymentInfo,buyItems, resourceLog, miniGameInfo;

- (id) init
{
    self = [super init];
    if(self) {
        userID = [[SystemUtils getCurrentUID] retain];
        installTime = [SystemUtils getInstallTime];
        updateDate = [SystemUtils getTodayDate];
    }
    return self;
}

- (void) dealloc
{
    self.userID = nil;
    self.levelUpInfo = nil;
    self.paymentInfo = nil;
    self.buyItems = nil;
    self.resourceLog = nil;
    self.miniGameInfo = nil;
    
    /*
    self.gainExp = nil;
    self.gainGold = nil;
    self.gainLeaf = nil;
    self.spendGold = nil;
    self.spendLeaf = nil;
     */
    
    [super dealloc];
}

- (NSString *) exportToString
{
    // userID, updateDate, userExp, installTime,timeSinceInstall,playTime,playCount,payCount,payTotal,payLastTime
    NSMutableString *str = [NSMutableString stringWithFormat:@"%@,%i,%i,%i,%i,%i,%i,%i,%i,%i", 
                            userID, updateDate, userExp, installTime, timeSinceInstall, playTime, playCount, payCount, payTotal, payLastTime];
    [str appendString:@"|||"];
    int count = 0;
    NSEnumerator *it = nil;
    NSString *info = nil;
    NSString *key = nil;
    // levelUpInfo
    if(levelUpInfo) {
        count = 0; it = [levelUpInfo keyEnumerator]; 
        key = [it nextObject]; 
        while(key) {
            info = [levelUpInfo objectForKey:key];
            if(count>0) [str appendString:@"|"];
            [str appendFormat:@"%@:%@",key,info];
            count++;
            key = [it nextObject];
        }
    }
    [str appendString:@"|||"];
    // paymentInfo
    if(paymentInfo) {
        count = 0; it = [paymentInfo objectEnumerator];
        info = [it nextObject];
        while(info) {
            if(count>0) [str appendString:@"|"];
            [str appendString:info];
            count++;
            info = [it nextObject];
        }
    }
    [str appendString:@"|||"];
    // buyItems
    if(buyItems) {
        NSString *json = [buyItems JSONRepresentation];
        if(json)
            [str appendString:json];
        else {
            SNSLog(@"failed to export buyItems:%@", buyItems);
        }
    }
    [str appendString:@"|||"];
    // resourceLog
    if(resourceLog) {
        NSString *json = [resourceLog JSONRepresentation];
        if(json)
            [str appendString:json];
        else {
            SNSLog(@"failed to export resourceLog:%@", resourceLog);
        }
    }
    // miniGameInfo
    [str appendString:@"|||"];
    if(miniGameInfo) {
        NSString *json = [miniGameInfo JSONRepresentation];
        if(json)
            [str appendString:json];
        else {
            SNSLog(@"failed to export miniGame:%@", miniGameInfo);
        }
    }
    
    return str;
}

- (BOOL) importFromString:(NSString *)info
{
    NSArray *arr = [info componentsSeparatedByString:@"|||"];
    if([arr count]<5) return NO;
    // userID, updateDate, userExp, installTime,timeSinceInstall,playTime,playCount,payCount,payTotal,payLastTime
    NSString *str = [arr objectAtIndex:0];
    NSArray *arr2 = [str componentsSeparatedByString:@","];
    if([arr2 count]>=10) {
        self.userID = [arr2 objectAtIndex:0];
        updateDate = [[arr2 objectAtIndex:1] intValue];
        userExp = [[arr2 objectAtIndex:2] intValue];
        installTime = [[arr2 objectAtIndex:3] intValue];
        timeSinceInstall = [[arr2 objectAtIndex:4] intValue];
        playTime = [[arr2 objectAtIndex:5] intValue];
        playCount = [[arr2 objectAtIndex:6] intValue];
        payCount = [[arr2 objectAtIndex:7] intValue];
        payTotal = [[arr2 objectAtIndex:8] intValue];
        payLastTime = [[arr2 objectAtIndex:9] intValue];
    }
    // levelUpInfo
    str = [arr objectAtIndex:1];
    if([str length]>0) {
        if(!levelUpInfo) self.levelUpInfo = [NSMutableDictionary dictionary];
        arr2 = [str componentsSeparatedByString:@"|"];
        for(NSString *str2 in arr2) {
            NSArray *arr3 = [str2 componentsSeparatedByString:@":"];
            if([arr2 count]<2) continue;
            [levelUpInfo setValue:[arr3 objectAtIndex:1] forKey:[arr3 objectAtIndex:0]];
        }
    }
    // paymentInfo
    str = [arr objectAtIndex:2];
    if([str length]>0) {
        if(!paymentInfo) self.paymentInfo = [NSMutableArray array];
        arr2 = [str componentsSeparatedByString:@"|"];
        [paymentInfo addObjectsFromArray:arr2];
    }
    // buyItems
    str = [arr objectAtIndex:3];
    if([str length]>0) {
        NSDictionary *dict = [str JSONValue];
        if(dict && [dict isKindOfClass:[NSDictionary class]])
        {
            if(!buyItems) self.buyItems = [NSMutableDictionary dictionary];
            [buyItems addEntriesFromDictionary:dict];
        }
    }
    // resourceLog
    str = [arr objectAtIndex:4];
    if([str length]>0) {
        NSDictionary *dict = [str JSONValue];
        if(dict && [dict isKindOfClass:[NSDictionary class]])
        {
            if(!resourceLog) self.resourceLog = [NSMutableDictionary dictionary];
            [resourceLog addEntriesFromDictionary:dict];
        }
    }
    if([arr count]<=5) return YES;
    // miniGameInfo
    str = [arr objectAtIndex:5];
    if([str length]>0) {
        NSDictionary *dict = [str JSONValue];
        if(dict && [dict isKindOfClass:[NSDictionary class]])
        {
            if(!miniGameInfo) self.miniGameInfo = [NSMutableDictionary dictionaryWithCapacity:2];
            [miniGameInfo addEntriesFromDictionary:dict];
        }
    }
    return YES;
}

-(void) logPayment:(int)cost withItem:(NSString *)itemID
{
    payCount++;
    payTotal += cost;
    int timeNow = [SystemUtils getCurrentTime];
    payLastTime = timeNow;
    
    if(!paymentInfo) {
        self.paymentInfo = [NSMutableArray array];
    }
    int level = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel];
    int timeFromInstall = timeNow - installTime;
    NSString *info = [NSString stringWithFormat:@"%i,%i,%i,%@,%i", timeNow, timeFromInstall, level, itemID, cost];
    [paymentInfo addObject:info];
}

- (void) startPlaySession
{
    sessionStartTime = [SystemUtils getCurrentTime];
    updateDate = [SystemUtils getTodayDate];
}

- (void) endPlaySession
{
    // updateDate = [SystemUtils getTodayDate];
    int now = [SystemUtils getCurrentTime];
    timeSinceInstall = now - installTime;
    if(timeSinceInstall<0) timeSinceInstall = 0;
    playCount++;
    int timePlayed = now - sessionStartTime;
    if(timePlayed<=10) timePlayed = 10;
    playTime += timePlayed;
    userExp = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeExp];
}

- (void) addUpResource:(int)type method:(int)method count:(int) count
{
    if(!resourceLog) {
        self.resourceLog = [NSMutableDictionary dictionary];
    }
    NSString *key = [NSString stringWithFormat:@"%i",type];
    NSMutableDictionary *info = [resourceLog objectForKey:key];
    if(!info || ![info isKindOfClass:[NSDictionary class]]) {
        info = [NSMutableDictionary dictionary];
        [resourceLog setValue:info forKey:key];
    }
    else if(![info isKindOfClass:[NSMutableDictionary class]]) {
        info = [NSMutableDictionary dictionaryWithDictionary:info];
        [resourceLog setValue:info forKey:key];
    }
    key = [NSString stringWithFormat:@"%i",method];
    int sum = [[info objectForKey:key] intValue];
    sum += count;
    [info setValue:[NSNumber numberWithInt:sum] forKey:key];
}

- (void)logResourceChange:(int)type method:(int)method itemID:(NSString *)itemID count:(int) count
{
    [self addUpResource:type method:method count:count];
}

- (void) logItemBuy:(int)type withID:(NSString *)ID
{
    if(!buyItems) {
        self.buyItems = [NSMutableDictionary dictionary];
    }
    NSString *key = [NSString stringWithFormat:@"%i",type];
    NSMutableDictionary *info = [buyItems objectForKey:key];
    if(!info || ![info isKindOfClass:[NSDictionary class]]) {
        info = [NSMutableDictionary dictionary];
        [buyItems setValue:info forKey:key];
    }
    else if(![info isKindOfClass:[NSMutableDictionary class]]) {
        info = [NSMutableDictionary dictionaryWithDictionary:info];
        [buyItems setValue:info forKey:key];
    }
    int sum = [[info objectForKey:ID] intValue];
    sum ++;
    [info setValue:[NSNumber numberWithInt:sum] forKey:ID];
}

- (void)logLevelUp:(int)level
{
    if(!levelUpInfo) {
        self.levelUpInfo = [NSMutableDictionary dictionary];
    }
    int now = [SystemUtils getCurrentTime];
    timeSinceInstall = now - installTime;
    int playInterval = now - sessionStartTime;
    NSArray *prevInfo = nil;
    if(level>1) {
        NSString *text = [levelUpInfo objectForKey:[NSString stringWithFormat:@"%i",level-1]];  
        if(text) {
            prevInfo = [text componentsSeparatedByString:@","];
            if([prevInfo count]<6) prevInfo = nil;
        }
        
    }
    int timeAPL = timeSinceInstall;
    if(prevInfo)
        timeAPL = now - [[prevInfo objectAtIndex:2] intValue];
    int playTimeAPL = playTime + playInterval;
    if(prevInfo)
        playTimeAPL = playTime + playInterval - [[prevInfo objectAtIndex:4] intValue];
    
    NSString *key = [NSString stringWithFormat:@"%i",level];
    NSString *info = [NSString stringWithFormat:@"%i,%i,%i,%i,%i,%i",
                      level, now, timeSinceInstall, timeAPL, playTime+playInterval, playTimeAPL];
    [levelUpInfo setValue:info forKey:key];
}

- (void)logPlayMiniGame:(int)gameID forTime:(int)seconds
{
    if(!miniGameInfo) {
        self.miniGameInfo = [NSMutableDictionary dictionary];
    }
    // 格式：用Array存储，第一个是累计时间time, 第二个是累计次数count
    NSString *key = [NSString stringWithFormat:@"%i",gameID];
    
    NSMutableArray *arr = [miniGameInfo objectForKey:key];
    if(arr) {
        if([arr isKindOfClass:[NSArray class]]) {
            if(![arr isKindOfClass:[NSMutableArray class]])
            {
                arr = [NSMutableArray arrayWithArray:arr];
                [miniGameInfo setValue:arr forKey:key];
            }
        }
        else 
            arr = nil;
    }
    if(!arr) {
        arr = [NSMutableArray arrayWithCapacity:2];
        [miniGameInfo setValue:arr forKey:key];
    }
    int time = 0; int num = 0;
    if([arr count]>=2) {
        time  = [[arr objectAtIndex:0] intValue];
        num   = [[arr objectAtIndex:1] intValue];
        [arr removeAllObjects];
    }
    time += seconds; num++;
    [arr addObject:[NSNumber numberWithInt:time]];
    [arr addObject:[NSNumber numberWithInt:num]];
}

@end
