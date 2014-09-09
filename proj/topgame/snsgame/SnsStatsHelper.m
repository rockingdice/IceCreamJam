//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "SnsStatsHelper.h"
#import "SystemUtils.h"
#import "SBJson.h"
#import "StatSendOperation.h"
#import "ASIFormDataRequest.h"

@implementation SnsStatsHelper

static SnsStatsHelper *_gSnsStatsHelper = nil;

+ (SnsStatsHelper *) helper
{
    if(!_gSnsStatsHelper) {
        _gSnsStatsHelper = [[SnsStatsHelper alloc] init];
    }
    return _gSnsStatsHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        [self setDefaultStats];
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
    [payItemInfo release]; [uid release]; [resInfo release];
    [achievementInfo release]; [timeStatInfo release]; [mainTimeStat release];
    [buyItemInfo release]; [actionInfo release];
    [dailyStats release];
}

- (void) setCurrentUID:(NSString *)userID
{
    if(uid) [uid release];
    uid = [userID retain];
}

- (NSString *) getGameStatsFile
{
	return [[SystemUtils getDocumentRootPath] stringByAppendingFormat:@"/stat2-%@.log",uid];
}

// 获得总的付费金额, 单位是美分
- (int) getTotalPay
{
    return payTotal;
}
// 获得安装时间
- (int) getInstallTime
{
    if(mainTimeStat==nil) return 0;
    return mainTimeStat.installTime;
}

// 保存到文件
- (void) saveStats
{
    NSString *file = [self getGameStatsFile];
    NSDictionary *dict = [self exportToDictionary];
    NSString *text = [SystemUtils addHashToSaveData:[dict JSONRepresentation]];
    [text writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void) initSession
{
    if(isInitialized) return;
    
    isInitialized = YES;
    if(uid) [uid release];
	uid = [[SystemUtils getCurrentUID] retain];
    
    NSString *file = [self getGameStatsFile];
    if([[NSFileManager defaultManager] fileExistsAtPath:file])
    {
        NSString *text = [SystemUtils readHashedSaveData:file];
        if(text) {
            NSDictionary *dict = [text JSONValue];
            if(dict && [dict isKindOfClass:[NSDictionary class]]) 
                [self importFromDictionary:dict];
        }
    }
    /*
    // 确保在游戏存档加载之后调用
    if([SystemUtils getGameDataDelegate]==nil) return;
    
    isInitialized = YES;
	uid = [[SystemUtils getCurrentUID] retain];
    
    // 从游戏存档中初始化统计数据
    NSDictionary *dict = [[SystemUtils getGameDataDelegate] getExtraInfo:@"kSGStats"];
    if(dict && [dict isKindOfClass:[NSDictionary class]]) [self importFromDictionary:dict];
     */
}

- (NSDictionary *) exportToDictionary
{
    // resInfo
    NSArray *keys = [resInfo allKeys];
    NSMutableDictionary *resDict = [NSMutableDictionary dictionary];
    for(NSString *resName in keys)
    {
        SnsResourceStats *st = [resInfo objectForKey:resName];
        [resDict setValue:[st exportToDictionary] forKey:resName];
    }
    
    // timeStatInfo
    keys = [timeStatInfo allKeys];
    NSMutableDictionary *timeDict = [NSMutableDictionary dictionary];
    for(NSString *resName in keys)
    {
        SnsTimeStats *st = [timeStatInfo objectForKey:resName];
        [timeDict setValue:[st exportToDictionary] forKey:resName];
    }
    
    // weekHourPlayTime
    NSMutableString *whpStr = [[NSMutableString alloc] init]; int *p = weekHourPlayTime;
    for(int i=0;i<24;i++)
    {
        [whpStr appendFormat:@"%i,%i,%i,%i,%i,%i,%i,", *p, *(p+1), *(p+2), *(p+3), *(p+4), *(p+5), *(p+6)];
        p+=7;
    }
    // dailyStat
    NSDictionary *dailySt = [dailyStats exportToDictionary];
    
    // delete last char(,)
    NSRange rang; rang.length = 1; rang.location = [whpStr length]-1;
    [whpStr deleteCharactersInRange:rang];
    
    NSDictionary *dict = [NSDictionary 
                          dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:isTester], @"test",
                          uid, @"uid",
                          [NSNumber numberWithInt:payTotal],@"pt", 
                          payItemInfo, @"pi",
                          resDict, @"res",
                          achievementInfo, @"ach",
                          buyItemInfo, @"item",
                          actionInfo, @"act",
                          [mainTimeStat exportToDictionary], @"mts",
                          timeDict, @"gts",
                          whpStr, @"whp",
                          dailySt, @"today",
                          nil];
    [whpStr release];
    return dict;
}

// 从存档数据中导入
- (void) importFromDictionary:(NSDictionary *)dict
{
    // NSDictionary *dict = [text JSONValue];
    if(!dict || ![dict isKindOfClass:[NSDictionary class]]) return;
    int val = 0;
    // isTester
    val = [[dict objectForKey:@"test"] intValue];
    if(val==1) isTester = 1;
    // uid
    if(uid!=nil) [uid release];
    uid = [dict objectForKey:@"uid"]; 
    if(uid!=nil) [uid retain];
    // payTotal
    val = [[dict objectForKey:@"pt"] intValue];
    if(val>0) payTotal += val;
    // payItemInfo
    NSDictionary *pi = [dict objectForKey:@"pi"];
    if(pi && [pi isKindOfClass:[NSDictionary class]] && [pi count]>0) {
        NSMutableDictionary *pi2 = [[NSMutableDictionary alloc] initWithDictionary:pi];
        SNSLog(@"pi2:%@",pi2);
        if([payItemInfo count]>0) {
            NSArray *keys = [payItemInfo allKeys];
            for(NSString *itemID in keys) {
                if([itemID isEqualToString:@"recs"]) continue;
                val = [[payItemInfo objectForKey:itemID] intValue];
                val += [[pi2 objectForKey:itemID] intValue];
                [pi2 setValue:[NSNumber numberWithInt:val] forKey:itemID];
            }
        }
        [payItemInfo release];
        payItemInfo = pi2;
    }
    
    // resInfo
    NSDictionary *resDict = [dict objectForKey:@"res"];
    if(resDict && [resDict count]>0)
    {
        NSArray *keys = [resDict allKeys];
        for(NSString *resName in keys)
        {
            NSDictionary *st = [resDict objectForKey:resName];
            if(![st isKindOfClass:[NSDictionary class]]) continue;
            SnsResourceStats *res = [[SnsResourceStats alloc] init];
            [res importFromDictionary:st];
            [resInfo setValue:res forKey:resName];
        }
    }
    
    // achievementInfo
    NSDictionary *achDict = [dict objectForKey:@"ach"];
    if(achDict && [achDict count]>0) {
        NSArray *keys = [achDict allKeys];
        for(NSString *key in keys)
        {
            NSDictionary *st = [achDict objectForKey:key];
            if(![st isKindOfClass:[NSDictionary class]]) continue;
            NSMutableDictionary *st2 = [NSMutableDictionary dictionaryWithDictionary:st];
            [achievementInfo setValue:st2 forKey:key];
        }
    }
    
    // buyItemInfo
    NSDictionary *itemDict = [dict objectForKey:@"item"];
    if(itemDict && [itemDict count]>0) {
        NSArray *keys = [itemDict allKeys];
        for(NSString *key in keys)
        {
            NSDictionary *st = [itemDict objectForKey:key];
            if(![st isKindOfClass:[NSDictionary class]]) continue;
            NSMutableDictionary *st2 = [NSMutableDictionary dictionaryWithDictionary:st];
            [buyItemInfo setValue:st2 forKey:key];
        }
    }
    
    // actionInfo
    NSDictionary *actDict = [dict objectForKey:@"act"];
    if(actDict && [actDict count]>0) {
        [actionInfo addEntriesFromDictionary:actDict];
    }
    
    NSDictionary *timeDict = [dict objectForKey:@"mts"];
    if(timeDict && [timeDict count]>0) [mainTimeStat importFromDictionary:timeDict];
    
    // timeStatInfo
    timeDict = [dict objectForKey:@"gts"];
    if(timeDict && [timeDict count]>0) {
        NSArray *keys = [timeDict allKeys];
        for(NSString *key in keys)
        {
            NSDictionary *st = [timeDict objectForKey:key];
            if(![st isKindOfClass:[NSDictionary class]]) continue;
            SnsTimeStats *st2 = [[SnsTimeStats alloc] init];
            [st2 importFromDictionary:st];
            [timeStatInfo setValue:st2 forKey:key];
            [st2 release];
        }
    }
    
    // weekHourPlayTime
    NSString *str = [dict objectForKey:@"whp"];
    if(str && [str isKindOfClass:[NSString class]])
    {
        NSArray *arr = [str componentsSeparatedByString:@","];
        if([arr count]==168)
        {
            for(int i=0;i<168;i++)
            {
                weekHourPlayTime[i] = [[arr objectAtIndex:i] intValue];
            }
        }
    }
    
    // todayStats
    NSDictionary *todaySt = [dict objectForKey:@"today"];
    if(todaySt && [todaySt count]>0) [dailyStats importFromDictionary:todaySt];
    
    // check kLostPayInfo
    NSString *lostPayInfo = [SystemUtils getNSDefaultObject:@"kLostPayInfo"];
    if(lostPayInfo!=nil && [lostPayInfo length]>10) {
        NSArray *arr = [lostPayInfo componentsSeparatedByString:@","];
        if([arr count]>=3) {
            int price = [[arr objectAtIndex:0] intValue];
            if(price>0) [self logPayment:price withItem:[arr objectAtIndex:1] andTransactionID:[arr objectAtIndex:2]];
        }
        [SystemUtils setNSDefaultObject:@"" forKey:@"kLostPayInfo"];
    }
}

// 设置数据为初始状态
- (void) setDefaultStats
{
    isInitialized = NO; payTotal = 0;
    isTester = 0;
#ifdef DEBUG
    isTester = 1;
#endif
    if(uid) {
        [uid release]; 
        uid = nil;
    }
    if(payItemInfo) [payItemInfo release];
    payItemInfo = [[NSMutableDictionary alloc] init];
    
    if(resInfo) [resInfo release];
    resInfo = [[NSMutableDictionary alloc] init];
    if(achievementInfo) [achievementInfo release];
    achievementInfo = [[NSMutableDictionary alloc] init];
    if(timeStatInfo) [timeStatInfo release];
    timeStatInfo = [[NSMutableDictionary alloc] init];
    if(buyItemInfo) [buyItemInfo release];
    buyItemInfo = [[NSMutableDictionary alloc] init];
    if(actionInfo) [actionInfo release];
    actionInfo  = [[NSMutableDictionary alloc] init];

    if(mainTimeStat) [mainTimeStat release];
    mainTimeStat = [[SnsTimeStats alloc] init];
    
    if(dailyStats) [dailyStats release];
    dailyStats = [[SnsDailyStats alloc] init];
    /*
    mainTimeStat.installTime = [SystemUtils getCurrentTime];
    mainTimeStat.lastPlayTime = [SystemUtils getCurrentTime];
    mainTimeStat.playTimes = 0; mainTimeStat.playSeconds = 0;
    mainTimeStat.lastPlayDate = mainTimeStat.lastPlayTime/86400;
    mainTimeStat.playDays = 1; 
     */
    memset(weekHourPlayTime, 0, sizeof(int)*168);
}

// 重置统计数据，在切换帐号时调用
- (void) resetStats
{
    [self setDefaultStats];
    [self initSession];
}

// 付费统计, price-用户消费的价格（美分），itemID－道具ID
- (void) logPayment:(int)price withItem:(NSString *)itemID  andTransactionID:(NSString *)tid
{
    payTotal += price;
    if([SystemUtils getGameDataDelegate]) {
        [[SystemUtils getGameDataDelegate] setExtraInfo:[NSString stringWithFormat:@"%d",payTotal] forKey:@"pay"];
    }
    else {
        [SystemUtils setNSDefaultObject:[NSString stringWithFormat:@"%d,%@,%@", price, itemID, tid] forKey:@"kLostPayInfo"];
    }
    
    int num = [[payItemInfo objectForKey:itemID] intValue];
    [payItemInfo setValue:[NSNumber numberWithInt:num+1] forKey:itemID];
    NSMutableArray *tids = [payItemInfo objectForKey:@"recs"];
    if(tids && ![tids isKindOfClass:[NSArray class]]) tids = nil;
    if(tids)
    {
        if(![tids isKindOfClass:[NSMutableArray class]]) {
            tids = [NSMutableArray arrayWithArray:tids];
            [payItemInfo setValue:tids forKey:@"recs"];
        }
    }
    else {
        tids = [NSMutableArray arrayWithCapacity:1];
        [payItemInfo setValue:tids forKey:@"recs"];
    }
    NSString *payInfo = [NSString stringWithFormat:@"%@,%@,%i",tid, itemID, price];
    [tids addObject:payInfo];
}

// 检查tid是否已经存在
- (BOOL) isTransactionIDExisting:(NSString *)tid
{
    NSArray *tids = [payItemInfo objectForKey:@"recs"];
    if(tids==nil) return NO;
    for (NSString *tid2 in tids)
    {
        NSArray *arr = [tid2 componentsSeparatedByString:@","];
        if([tid isEqualToString:[arr objectAtIndex:0]]) return YES;
    }
    return NO;
}


// 资源统计，resType－资源类型，num－变化数量，正数增加，负数减少，type－渠道类型，消耗渠道和来源渠道, level－当前等级
// 发送格式：resType,num,type,level
- (void) logResource:(int)resType change:(int)num channelType:(int)type
{
    if(num==0) return;
    NSString *resName = [NSString stringWithFormat:@"%i",resType];
    SnsResourceStats *st = [resInfo objectForKey:resName];
    if(st==nil) {
        st = [[SnsResourceStats alloc] init];
        [resInfo setObject:st forKey:resName];
    }
    int level = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel];
    [st logChange:num channelType:type atLevel:level];
    
    [dailyStats logResource:resType change:num channelType:type];
    
    NSString *data = [NSString stringWithFormat:@"%d,%d,%d,%d", resType, num, type, level];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:@"1",@"type",data,@"data", nil];
    [self performSelectorInBackground:@selector(reportToStatServer:) withObject:info];
}

// 成就统计
// 发送格式：achieveName
- (void) logAchievement:(NSString *)achieveName
{
    if(!achieveName) return;
    int level = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel];
    NSMutableDictionary *dict = [achievementInfo objectForKey:achieveName];
    if(dict) return; 
    dict = [NSMutableDictionary dictionary];
    // tm,pt,pc,lv
    int now = [SystemUtils getCurrentTime];
    if(now <= mainTimeStat.installTime) return;
    [dict setValue:[NSNumber numberWithInt:now-mainTimeStat.installTime] forKey:@"tm"];
    [dict setValue:[NSNumber numberWithInt:now-mainTimeStat.lastPlayTime+mainTimeStat.playSeconds] forKey:@"pt"];
    [dict setValue:[NSNumber numberWithInt:mainTimeStat.playTimes+1] forKey:@"pc"];
    [dict setValue:[NSNumber numberWithInt:level] forKey:@"lv"];
    [achievementInfo setValue:dict forKey:achieveName];
    
    [dailyStats.achievementInfo setValue:dict forKey:achieveName];
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:@"2",@"type",achieveName,@"data", nil];
    [self performSelectorInBackground:@selector(reportToStatServer:) withObject:info];
    
}
// 道具购买统计, itemID-道具ID，count－购买数量，cost－价格／消耗资源数量，resType－货币类型／消耗资源类型, place-发生此事件的位置
// 发送格式：itemID,itemType,count,cost,resType,place
- (void) logBuyItem:(NSString *)itemID count:(int)count cost:(int)cost resType:(int)moneyType  itemType:(int)itemType placeName:(NSString *)place
{
    if(itemID==nil) return;
    NSMutableDictionary *dict = [buyItemInfo objectForKey:itemID];
    if(!dict) {
        dict = [NSMutableDictionary dictionary];
        [buyItemInfo setValue:dict forKey:itemID];
    }
    count += [[dict objectForKey:@"num"] intValue];
    [dict setValue:[NSNumber numberWithInt:count] forKey:@"num"];
    [dict setValue:[NSNumber numberWithInt:itemType] forKey:@"tp"];
    if(cost>0) {
        NSString *key = [NSString stringWithFormat:@"m%i",moneyType];
        cost += [[dict objectForKey:key] intValue];
        [dict setValue:[NSNumber numberWithInt:cost] forKey:key];
    }
    
    [dailyStats logBuyItem:itemID count:count cost:cost resType:moneyType itemType:itemType];
    
    // always log buy item report
    SyncQueue* syncQueue = [SyncQueue syncQueue];
    
    BuyItemReportOperation* statusCheckOp = [[BuyItemReportOperation alloc] initWithManager:syncQueue andDelegate:nil];
    statusCheckOp.itemID = itemID; statusCheckOp.itemType = itemType; statusCheckOp.costType = moneyType; statusCheckOp.cost = cost;
    [syncQueue.operations addOperation:statusCheckOp];
    [statusCheckOp release];
    
    NSString *data = [NSString stringWithFormat:@"%@,%d,%d,%d,%d,%@", itemID, itemType, count, cost, moneyType, place];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:@"3",@"type",data,@"data", nil];
    [self performSelectorInBackground:@selector(reportToStatServer:) withObject:info];
    
}

// 道具购买统计
// 发送格式：itemID,itemType,count,money,moneyType
- (void) logBuyItem:(NSString *)itemID count:(int)count cost:(int)cost resType:(int)moneyType itemType:(int)itemType
{
    [self logBuyItem:itemID count:count cost:cost resType:moneyType itemType:itemType placeName:@"default"];
}

// 行为统计，记录累计次数和最后一次操作的时间
// 发送格式：actionName
- (void) logAction:(NSString *)actionName
{
    if(actionName==nil)return;
    int count = [[actionInfo objectForKey:actionName] intValue];
    [actionInfo setValue:[NSNumber numberWithInt:count+1] forKey:actionName];
    [dailyStats logAction:actionName withCount:1];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:@"3",@"type",actionName,@"data", nil];
    [self performSelectorInBackground:@selector(reportToStatServer:) withObject:info];
}

// 行为统计，记录累计次数和最后一次操作的时间
- (void) logAction:(NSString *)actionName withCount:(int)num
{
    if(actionName==nil)return;
    int count = [[actionInfo objectForKey:actionName] intValue];
    [actionInfo setValue:[NSNumber numberWithInt:count+num] forKey:actionName];
    [dailyStats logAction:actionName withCount:num];
}

// 记录游戏开始时间
- (void) logStartTime:(NSString *)gameName
{
    if(gameName==nil || [gameName isEqualToString:@"main"] || [gameName length]==0)
    {
        [mainTimeStat logStartTime];
    }
    else {
        SnsTimeStats *st = [timeStatInfo objectForKey:gameName];
        if(!st) {
            st = [[SnsTimeStats alloc] init];
            [st autorelease];
            [timeStatInfo setObject:st forKey:gameName];
        }
        [st logStartTime];
    }
}

// 记录游戏结束时间
- (void) logStopTime:(NSString *)gameName
{
    if(gameName==nil || [gameName isEqualToString:@"main"] || [gameName length]==0)
    {
        [mainTimeStat logStopTime];
        int now = [SystemUtils getCurrentTime];
        int seconds = now - mainTimeStat.lastPlayTime; int i = 0;
        
        [dailyStats logPlayTime:seconds];
        
        // 计算一周内每小时的时间分布
        NSDate *dt1 = [NSDate dateWithTimeIntervalSince1970:mainTimeStat.lastPlayTime];
        NSDate *dt2 = [NSDate dateWithTimeIntervalSince1970:now];
        NSCalendar *gregorian = [[NSCalendar alloc]
                                 initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *dtc1 =
        [gregorian components:( NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) 
                     fromDate:dt1];
        NSDateComponents *dtc2 =
        [gregorian components:( NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) 
                     fromDate:dt2];
        int weekday1 = dtc1.weekday; int hour1 = dtc1.hour; // 1-sunday,2-monday,...,6-saturday
        int weekday2 = dtc2.weekday; int hour2 = dtc2.hour;
        [gregorian release];
        int idx1 = (weekday1-1)*24 + hour1; int idx2 = (weekday2-1)*24+hour2;
        if(idx1==idx2) 
            weekHourPlayTime[idx1] += seconds;
        else {
            weekHourPlayTime[idx1] += 3600-(dtc1.second + dtc1.minute*60);
            weekHourPlayTime[idx2] += dtc2.second + dtc2.minute*60;
            if(idx1+1<idx2) {
                for(i=idx1+1;i<idx2;i++) 
                {
                    weekHourPlayTime[i] += 3600;
                }
            }
            if(weekday1==7 && weekday2 == 1)
            {
                int idx3 = idx2+168;
                if(idx1+1<idx3) {
                    for(i=idx1+1;i<idx3;i++)
                    {
                        if(i<168) weekHourPlayTime[i] += 3600;
                        else weekHourPlayTime[i-168] += 3600;
                    }
                }
            }
        }
    }    
    else {
        SnsTimeStats *st = [timeStatInfo objectForKey:gameName];
        if(st) [st logStopTime];
    }
}

// 发送数据到统计服务器, type: 1-resource, 2-achievement, 3-buy item, 4-action
- (void) reportToStatServer:(NSDictionary *) info
{
    int type = [[info objectForKey:@"type"] intValue];
    NSString *data = [info objectForKey:@"data"];
    if(type==0 || data==nil) return;
    if(type<1 || type>4) return;
    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *data2 = [NSString stringWithString:data];
    NSString *statLink = [SystemUtils getSystemInfo:@"kTopStatLinkRoot"];
    NSString *appID = [SystemUtils getSystemInfo:@"kTopStatAppID"];
    if(statLink==nil || [statLink length]<10 || appID==nil || [appID length]<2) {
        [pool release];
        return;
    }
    if(type==1)
        statLink = [statLink stringByAppendingString:@"statResource.php"];
    else if(type==2)
        statLink = [statLink stringByAppendingString:@"statAchievement.php"];
    else if(type==3)
        statLink = [statLink stringByAppendingString:@"statBuyItem.php"];
    else if(type==4)
        statLink = [statLink stringByAppendingString:@"statAction.php"];
    
    // NSString *isNew = @"0";
    // if([isNewUser boolValue]) isNew = @"1";
    
	NSString *country = [SystemUtils getCountryCode];
	NSString *clientVer = [SystemUtils getClientVersion];
	NSString *userID = [SystemUtils getCurrentUID];
    NSString *subID = [SystemUtils getSystemInfo:@"kSubAppID"];
    int level = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel];
    if(!subID) subID = @"0";
	NSString *isTestUser = @"0";
#ifdef DEBUG
	isTestUser = @"1";
#endif
    
    
	NSURL *url = [NSURL URLWithString:statLink];
    
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
	[request addPostValue:appID forKey:@"appID"];
	// [request addPostValue:isNew forKey:@"isNewUser"];
	[request addPostValue:country forKey:@"country"];
	[request addPostValue:isTestUser forKey:@"isTestUser"];
	[request addPostValue:[NSString stringWithFormat:@"%d",level] forKey:@"level"];
	[request addPostValue:userID forKey:@"userID"];
	[request addPostValue:clientVer forKey:@"clientVer"];
	[request addPostValue:subID forKey:@"subID"];
	[request addPostValue:@"0" forKey:@"osType"];
	[request addPostValue:data2 forKey:@"data"];
    
	[request setTimeOutSeconds:10.0f];
	[request buildPostBody];
#ifdef DEBUG
	NSLog(@"%s: url:%@\npost len:%i data: %s", __func__, statLink, [request postBody].length, [request postBody].bytes);
#endif
    [request startSynchronous];
#ifdef DEBUG
    NSLog(@"%s: response: %@",__func__, [request responseString]);
#endif
	[pool release];
}


@end

@implementation SnsResourceStats

-(id) init
{
    self = [super init];
    if(self) {
        [self setDefaultStats];
    }
    return self;
}

-(void)dealloc
{
    [levelsGet release];
    [levelsSpend release];
    [channelGet release];
    [channelSpend release];
    [super dealloc];
}

// 设置数据为初始状态
- (void) setDefaultStats
{
    totalGet = 0; totalSpend = 0;
    if(levelsGet) [levelsGet release];
    levelsGet = [[NSMutableDictionary alloc] init];
    if(levelsSpend) [levelsSpend release];
    levelsSpend = [[NSMutableDictionary alloc] init];
    if(channelGet) [channelGet release];
    channelGet = [[NSMutableDictionary alloc] init];
    if(channelSpend) [channelSpend release];
    channelSpend = [[NSMutableDictionary alloc] init];
}

-(NSDictionary *)exportToDictionary
{
    NSDictionary *dict = [NSDictionary
                          dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:totalGet],@"tg", 
                          [NSNumber numberWithInt:totalSpend], @"ts",
                          levelsGet, @"lg",
                          levelsSpend, @"ls",
                          channelGet, @"cg",
                          channelSpend, @"cs",
                          nil];
    return dict;
}

-(void) importFromDictionary:(NSDictionary *)dict
{
    // NSDictionary *dict = [text JSONValue];
    totalGet = [[dict objectForKey:@"tg"] intValue];
    totalSpend = [[dict objectForKey:@"ts"] intValue];
    NSDictionary *dict2 = [dict objectForKey:@"lg"];
    if(dict2 && [dict2 count]>0) [levelsGet addEntriesFromDictionary:dict2];
    dict2 = [dict objectForKey:@"ls"];
    if(dict2 && [dict2 count]>0) [levelsSpend addEntriesFromDictionary:dict2];
    dict2 = [dict objectForKey:@"cg"];
    if(dict2 && [dict2 count]>0) [channelGet addEntriesFromDictionary:dict2];
    dict2 = [dict objectForKey:@"cs"];
    if(dict2 && [dict2 count]>0) [channelSpend addEntriesFromDictionary:dict2];
}

// 变化记录，num－增加／减少数量，type－渠道类型，level－用户等级
- (void) logChange:(int)num channelType:(int)type atLevel:(int)level
{
    NSMutableDictionary *dict = nil;
    NSMutableDictionary *dict1 = nil;
    if(num>0) {
        dict = levelsGet; totalGet += num; dict1 = channelGet;
    }
    else {
        dict = levelsSpend; num = 0-num; totalSpend += num; dict1 = channelSpend;
    }
    NSString *stLevel = [NSString stringWithFormat:@"%i",level];
    int count = [[dict objectForKey:stLevel] intValue];
    count += num;
    [dict setObject:[NSNumber numberWithInt:count] forKey:stLevel];
    NSString *stChannel = [NSString stringWithFormat:@"%i",type];
    count = [[dict1 objectForKey:stChannel] intValue];
    count += num;
    [dict1 setObject:[NSNumber numberWithInt:count] forKey:stChannel];
}

@end

@implementation SnsTimeStats

@synthesize installTime,lastPlayDate,lastPlayTime,playDays, playSeconds, playTimes;

-(NSDictionary *)exportToDictionary
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:installTime], @"int",
                          [NSNumber numberWithInt:lastPlayTime], @"lpt",
                          [NSNumber numberWithInt:playTimes], @"pts",
                          [NSNumber numberWithInt:playSeconds], @"pss",
                          [NSNumber numberWithInt:lastPlayDate], @"lpd",
                          [NSNumber numberWithInt:playDays], @"pds",
                          nil];
    return dict;
}

-(void) importFromDictionary:(NSDictionary *)dict
{
    int val = 0;
    val = [[dict objectForKey:@"int"] intValue]; if(val>0) installTime = val;
    val = [[dict objectForKey:@"lpt"] intValue]; if(val>0) lastPlayTime = val;
    val = [[dict objectForKey:@"pts"] intValue]; if(val>0) playTimes = val;
    val = [[dict objectForKey:@"pss"] intValue]; if(val>0) playSeconds = val;
    val = [[dict objectForKey:@"lpd"] intValue]; if(val>0) lastPlayDate = val;
    val = [[dict objectForKey:@"pds"] intValue]; if(val>0) playDays = val;
    
}

// 设置数据为初始状态
- (void) setDefaultStats
{
    installTime = [SystemUtils getCurrentTime];
    lastPlayTime = [SystemUtils getCurrentTime];
    playTimes = 0; playSeconds = 0;
    lastPlayDate = lastPlayTime/86400;
    playDays = 1; 
}

// 记录游戏开始时间
- (void) logStartTime
{
    lastPlayTime = [SystemUtils getCurrentTime];
    if(installTime>lastPlayTime) installTime = lastPlayTime;
    int today = lastPlayTime/86400;
    if(today!=lastPlayDate) {
        lastPlayDate = today; playDays++;
    }
}

// 记录游戏结束时间
- (void) logStopTime
{
    int now = [SystemUtils getCurrentTime];
    if(now<=lastPlayTime) return;
    int seconds = now - lastPlayTime;
    playTimes++; playSeconds += seconds;
}


@end

@implementation SnsDailyStats

@synthesize resInfo,achievementInfo,buyItemInfo,actionInfo;

-(id)init
{
    self = [super init];
    if(self)
    {
        [self setDefaultStats];
    }
    return self;
}

-(void)dealloc
{
    self.resInfo = nil;
    self.achievementInfo = nil;
    self.buyItemInfo = nil;
    self.actionInfo = nil;
    [super dealloc];
}

-(NSDictionary *)exportToDictionary
{
    // resInfo
    NSArray *keys = [resInfo allKeys];
    NSMutableDictionary *resDict = [NSMutableDictionary dictionary];
    for(NSString *resName in keys)
    {
        SnsResourceStats *st = [resInfo objectForKey:resName];
        [resDict setValue:[st exportToDictionary] forKey:resName];
    }
    
    NSDictionary *dict = [NSDictionary
                          dictionaryWithObjectsAndKeys:
                          resDict, @"res",
                          achievementInfo, @"ach",
                          buyItemInfo, @"item",
                          actionInfo, @"act",
                          [NSNumber numberWithInt:today], @"date",
                          [NSNumber numberWithInt:playSeconds], @"sec",
                          [NSNumber numberWithInt:playTimes], @"tms",
                          nil];
    return dict;
}

-(void) importFromDictionary:(NSDictionary *)dict
{
    if(!dict || ![dict isKindOfClass:[NSDictionary class]]) return;
    if(![dict objectForKey:@"date"]) return;
    int date = [[dict objectForKey:@"date"] intValue];
    if(date!=today) return;
    
    playSeconds = [[dict objectForKey:@"sec"] intValue];
    playTimes = [[dict objectForKey:@"tms"] intValue];
    
    // resInfo
    NSDictionary *resDict = [dict objectForKey:@"res"];
    if(resDict && [resDict count]>0)
    {
        NSArray *keys = [resDict allKeys];
        for(NSString *resName in keys)
        {
            NSDictionary *st = [resDict objectForKey:resName];
            if(![st isKindOfClass:[NSDictionary class]]) continue;
            SnsResourceStats *res = [[SnsResourceStats alloc] init];
            [res importFromDictionary:st];
            [resInfo setValue:res forKey:resName];
        }
    }
    
    // achievementInfo
    NSDictionary *achDict = [dict objectForKey:@"ach"];
    if(achDict && [achDict count]>0) {
        NSArray *keys = [achDict allKeys];
        for(NSString *key in keys)
        {
            NSDictionary *st = [achDict objectForKey:key];
            if(![st isKindOfClass:[NSDictionary class]]) continue;
            NSMutableDictionary *st2 = [NSMutableDictionary dictionaryWithDictionary:st];
            [achievementInfo setValue:st2 forKey:key];
        }
    }
    
    // buyItemInfo
    NSDictionary *itemDict = [dict objectForKey:@"item"];
    if(itemDict && [itemDict count]>0) {
        NSArray *keys = [itemDict allKeys];
        for(NSString *key in keys)
        {
            NSDictionary *st = [itemDict objectForKey:key];
            if(![st isKindOfClass:[NSDictionary class]]) continue;
            NSMutableDictionary *st2 = [NSMutableDictionary dictionaryWithDictionary:st];
            [buyItemInfo setValue:st2 forKey:key];
        }
    }
    
    // actionInfo
    NSDictionary *actDict = [dict objectForKey:@"act"];
    if(actDict && [actDict count]>0) {
        [actionInfo addEntriesFromDictionary:actDict];
    }
    
}

-(void) setDefaultStats
{
    if(resInfo) [resInfo release];
    resInfo = [[NSMutableDictionary alloc] init];
    if(achievementInfo) [achievementInfo release];
    achievementInfo = [[NSMutableDictionary alloc] init];
    if(buyItemInfo) [buyItemInfo release];
    buyItemInfo = [[NSMutableDictionary alloc] init];
    if(actionInfo) [actionInfo release];
    actionInfo  = [[NSMutableDictionary alloc] init];
    
    today = [SystemUtils getTodayDate]; playSeconds = 0; playTimes = 0;
}

// 资源统计，resType－资源类型，num－变化数量，正数增加，负数减少，type－渠道类型，消耗渠道和来源渠道, level－当前等级
- (void) logResource:(int)resType change:(int)num channelType:(int)type
{
    if(num==0) return;
    NSString *resName = [NSString stringWithFormat:@"%i",resType];
    SnsResourceStats *st = [resInfo objectForKey:resName];
    if(st==nil) {
        st = [[SnsResourceStats alloc] init];
        [resInfo setObject:st forKey:resName];
    }
    int level = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel];
    [st logChange:num channelType:type atLevel:level];
}


// 道具购买统计
- (void) logBuyItem:(NSString *)itemID count:(int)count cost:(int)cost resType:(int)moneyType itemType:(int)itemType
{
    if(!itemID) return;
    NSMutableDictionary *dict = [buyItemInfo objectForKey:itemID];
    if(!dict) {
        dict = [NSMutableDictionary dictionary];
        [buyItemInfo setValue:dict forKey:itemID];
    }
    count += [[dict objectForKey:@"num"] intValue];
    [dict setValue:[NSNumber numberWithInt:count] forKey:@"num"];
    [dict setValue:[NSNumber numberWithInt:itemType] forKey:@"tp"];
    if(cost>0) {
        NSString *key = [NSString stringWithFormat:@"m%i",moneyType];
        cost += [[dict objectForKey:key] intValue];
        [dict setValue:[NSNumber numberWithInt:cost] forKey:key];
    }
    
}

// 行为统计，记录累计次数和最后一次操作的时间
- (void) logAction:(NSString *)actionName withCount:(int)num
{
    if(actionName==nil)return;
    int count = [[actionInfo objectForKey:actionName] intValue];
    [actionInfo setValue:[NSNumber numberWithInt:count+num] forKey:actionName];
}

// 记录本次玩游戏的时间
- (void) logPlayTime:(int)seconds
{
    playSeconds += seconds;
    playTimes += 1;
}


@end
