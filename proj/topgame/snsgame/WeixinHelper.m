//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "WeixinHelper.h"
#import "SystemUtils.h"
#import "StringUtils.h"

@implementation WeixinHelper

static WeixinHelper *_gWeixinHelper = nil;

+ (WeixinHelper *) helper
{
    if(!_gWeixinHelper) {
        _gWeixinHelper = [[WeixinHelper alloc] init];
    }
    return _gWeixinHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO; isAdReady = NO; 
        // _scene = WXSceneSession;
        // if([[WXApi getWXAppSupportMaxApiVersion] compare:@"1.1"]>=0)
        _scene = WXSceneTimeline;
    }
    return self;
}

- (void) dealloc
{
    if(weixinInfo!=nil) [weixinInfo release];
    [super dealloc];
}

- (void) initSession
{
    if(isInitialized) return;
    if(![self isWeixinInstalled]) return;
    
    weixinInfo = [SystemUtils getSystemInfo:@"kWeixinInfo"];
    if(weixinInfo==nil) {
        SNSLog(@"init failed: invalid weixinInfo %@",weixinInfo);
        return;
    }
    
    [weixinInfo retain];
    
    NSString *wxID = [SystemUtils getGlobalSetting:@"kWeixinAppID"];
    // NSString *wxKey = [SystemUtils getGlobalSetting:@"kWeixinAppSecret"];
    
    if(wxID==nil || [wxID length]<3) wxID = [weixinInfo objectForKey:@"appID"];
    // if(wxKey==nil || [wxKey length]<3) wxKey = [SystemUtils getSystemInfo:@"kWeixinAppSecret"];
    if(wxID==nil || [wxID length]<3) {
        SNSLog(@"init failed: invalid wxID %@",weixinInfo);
        return;
    }
    isInitialized = YES;
    [WXApi registerApp:wxID];
}

- (BOOL) isWeixinInstalled
{
    if([WXApi isWXAppInstalled]) return YES;
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]]) return YES;
    return NO;
}
- (void) openWeixinApp
{
    [WXApi openWXApp];
}

- (BOOL) checkWeixinInstalled
{
    // alert weixin note installed
    if([self isWeixinInstalled]) return YES;
    
    NSString *strTitle = @"尚未安装微信";
    NSString *strMsg  = @"需要先安装微信才能使用微信分享功能，要现在安装吗？";
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"现在安装", nil];
    alert.tag = 1;
    alert.delegate = self;
    [alert show];
    [alert release];
    return NO;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	SNSLog(@"%s", __func__);
    if(alertView.tag==1 && buttonIndex==1) {
        [SystemUtils openAppLink:[WXApi getWXAppInstallUrl]];
    }
}

- (BOOL) handleOpenURL:(NSURL *)url
{
    if(!isInitialized) [self initSession];
    return [WXApi handleOpenURL:url delegate:self];
}

- (void) publishFeedToSession
{
    NSDictionary *feedInfo = [weixinInfo objectForKey:@"feedInfo"];
    NSString *nsText = [SystemUtils getGlobalSetting:@"kWeixinInviteTitle"];
    NSString *nsDesc = [SystemUtils getGlobalSetting:@"kWeixinInviteDesc"];
    if(nsText==nil || [nsText length]<10) {
        nsText = [feedInfo objectForKey:@"title"];
        nsDesc = [feedInfo objectForKey:@"desc"];
    }
    
    SendMessageToWXReq* req = [[[SendMessageToWXReq alloc] init]autorelease];
    req.bText = YES;
    req.text = nsText;
    req.scene = WXSceneSession;
    
    [WXApi sendReq:req];
}

// 生成礼物信息, type:0-朋友圈礼物，1-好友礼物
// 礼物里包含params,msgTitle,msgDetail, noteTitle
- (NSDictionary *)getGiftInfo:(int) type
{
    // $info = {'uid':1234,'type':1,'count':100,'gid':'1308211'}
	// $link = "$scheme://userGift?gift=".urlencode($giftText)."&sig=$sig";
    // inviteGift, publishGift
    NSDictionary *info = nil; NSString *txt = nil;
    if(type==0) {
        txt = [SystemUtils getGlobalSetting:@"kWeixinCircleGift"];
    }
    else {
        txt = [SystemUtils getGlobalSetting:@"kWeixinInviteGift"];
    }
    if(txt!=nil && [txt length]>3) {
        info = [StringUtils convertJSONStringToObject:txt];
        if(info!=nil && ![info isKindOfClass:[NSDictionary class]]) info = nil;
    }
    if(info==nil) {
        if(type==0) {
            info = [weixinInfo objectForKey:@"publishGift"];
        }
        else {
            info = [weixinInfo objectForKey:@"inviteGift"];
        }
    }
    if(info==nil) return nil;
    NSMutableDictionary *giftInfo = [NSMutableDictionary dictionaryWithCapacity:4];
    [giftInfo setObject:[SystemUtils getCurrentUID] forKey:@"from_uid"];
    [giftInfo setObject:[info objectForKey:@"type"] forKey:@"type"];
    [giftInfo setObject:[info objectForKey:@"count"] forKey:@"count"];
    [giftInfo setObject:[info objectForKey:@"hint"] forKey:@"hint"];
    int today = [SystemUtils getTodayDate];
    NSString *gid = [NSString stringWithFormat:@"%d%@",today, [info objectForKey:@"type"]];
    [giftInfo setObject:gid forKey:@"gid"];
    NSString *giftTxt = [StringUtils convertObjectToJSONString:giftInfo];
    
    NSString *sig = [NSString stringWithFormat:@"%@-sdf28s070etrw3470", [StringUtils stringByHashingStringWithMD5:giftTxt]];
    sig = [StringUtils stringByHashingStringWithMD5:sig];
    NSString *params = [NSString stringWithFormat:@"gift=%@&sig=%@", [StringUtils stringByUrlEncodingString:giftTxt], sig];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:info];
    [dict setObject:params forKey:@"params"];
    return dict;
}

// 分享到朋友圈
- (void) publishNote
{
    if(![self checkWeixinInstalled]) return;
    
    if(!isInitialized) [self initSession];
    [self publishAppLink:0];
}
// 邀请好友
- (void) inviteFriend
{
    if(![self checkWeixinInstalled]) return;
    
    if(!isInitialized) [self initSession];
    [self publishAppLink:1];
}
// 添加好友
- (void) addFriend
{
    if(![self checkWeixinInstalled]) return;
    
    if(!isInitialized) [self initSession];
    [self publishAppLink:4];
}
// 邀请获得无限体力
- (void) unlimitLife
{
    if(![self checkWeixinInstalled]) return;
    
    if(!isInitialized) [self initSession];
    [self publishAppLink:5];
}

// feedType: 0-朋友圈, 1-发给好友， 3-自动, 4-添加好友， 5-邀请好友获得无限体力
- (void) publishAppLink:(int)feedType
{
    if(![self checkWeixinInstalled]) return;
    if ((feedType == 4 || feedType == 5) && [[SystemUtils getCurrentUID] intValue] == 0) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"添加失败" message:@"请稍后再试" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        [alert release];
        return;
    }
    
    if(!isInitialized) [self initSession];
    
    int scene = _scene;
    NSString *thumbFileName = @"weixin-feed-thumb.jpg";
    // if([self hasGotTodayPrize])
    if(feedType==3) {
        if([self hasConnected]) feedType = 1;
        else feedType = 0;
    }
    currentRequestType = feedType;
    if(feedType==1)
    {
        // [self publishFeedToSession];
        // return;
        thumbFileName = @"weixin-invite-icon.jpg";
        scene = WXSceneSession;
    }
    else if(feedType == 4 || feedType == 5){
        thumbFileName = @"weixin-addfrd-icon.jpg";
        scene = WXSceneSession;
    }
    else {
        if([self getTodayPublishCount]>0) thumbFileName = @"weixin-passlevel-thumb.jpg";
    }
    NSDictionary *feedInfo = [weixinInfo objectForKey:@"feedInfo"];
    if (feedType == 4 || feedType == 5) {
        feedInfo = [weixinInfo objectForKey:@"unlimitLife"];
    }
    NSString *nsText = nil;
    NSString *nsDesc = nil;
    NSString *titleCircle = nil;
    
    NSString *remotePath = [SystemUtils getItemImagePath];
    NSString *remoteThumb = [remotePath stringByAppendingPathComponent:thumbFileName];
    NSString *remoteFile  = [remotePath stringByAppendingPathComponent:@"weixin-passlevel.jpg"];
    NSFileManager *mgr = [NSFileManager defaultManager];
    BOOL useRemote = NO;
    if([mgr fileExistsAtPath:remotePath] && [mgr fileExistsAtPath:remoteThumb]) useRemote = YES;
    
    UIImage *img1 = nil;
    if(useRemote) img1 = [UIImage imageWithContentsOfFile:remoteThumb];
    if(img1==nil) img1 = [UIImage imageNamed:thumbFileName];
    if(img1==nil) return;
    
    NSDictionary *giftInfo = nil;
    if([self hasConnected]) {
        if((feedType==1 && ![self isConnectedFirstDay]) || feedType==0) {
            giftInfo = [self getGiftInfo:feedType];
        }
    }
    if(giftInfo!=nil) {
        if(feedType==1) {
            nsText = [giftInfo objectForKey:@"msgTitle"];
            nsDesc = [giftInfo objectForKey:@"msgDetail"];
            
            NSString *t2 = [SystemUtils getGlobalSetting:@"kWeixinInviteTitle"];
            if(t2!=nil && [t2 length]>3) nsText = t2;
            t2 = [SystemUtils getGlobalSetting:@"kWeixinInviteDesc"];
            if(t2!=nil && [t2 length]>3) nsDesc = t2;
            
            if(titleCircle==nil)
                titleCircle = [SystemUtils getGlobalSetting:@"kWeixinCircleTitle"];
            
        }
        else {
            titleCircle = [giftInfo objectForKey:@"noteTitle"];
            NSString *t2 = [SystemUtils getGlobalSetting:@"kWeixinCircleTitle"];
            if(t2!=nil && [t2 length]>3) titleCircle = t2;

        }
    }
    
    if(nsText==nil || [nsText length]<3) {
        nsText = [feedInfo objectForKey:@"title"];
        nsDesc = [feedInfo objectForKey:@"desc"];
    }
    if(titleCircle==nil || [titleCircle length]<3)
        titleCircle = [feedInfo objectForKey:@"titleCircle"];

    BOOL publishImageFeed = NO;
    //发送内容给微信
    WXMediaMessage *message = [WXMediaMessage message];
    [message setThumbImage:img1];
    if(feedType==1 || feedType ==4 || feedType == 5) {
        message.title = nsText;
        message.description = nsDesc;
        SNSLog(@"title: %@\ndescription:%@", nsText, nsDesc);
    }
    else {
        message.title = titleCircle;
        // message.description = nsDesc;
        SNSLog(@"title: %@\ndescription:%@", titleCircle, nsDesc);
        if([self getTodayPublishCount]>0) {
            NSData *imgData = nil;
            if(useRemote) imgData = [NSData dataWithContentsOfFile:remoteFile];
            if(imgData==nil) {
                NSString *filePath = [[NSBundle mainBundle] pathForResource:@"weixin-passlevel" ofType:@"jpg"];
                imgData = [NSData dataWithContentsOfFile:filePath];
            }
            if(imgData!=nil) {
                WXImageObject *ext = [WXImageObject object];
                ext.imageData =  imgData;
                message.mediaObject = ext;
                publishImageFeed = YES; 
            }
            
        }
    }
    /*
    if(feedType==0) {
        NSData *imgData = nil;
        if(useRemote) imgData = [NSData dataWithContentsOfFile:remoteFile];
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"weixin-feed" ofType:@"jpg"];
        if(imgData==nil) imgData = [NSData dataWithContentsOfFile:filePath];
        if(imgData==nil) return;
        
        WXImageObject *ext = [WXImageObject object];
        ext.imageData =  imgData;
        message.mediaObject = ext;
    }
     */
    // if(feedType==1) {
    NSString *feedLink = nil;
    feedLink = [SystemUtils getGlobalSetting:@"kWeixinInviteLink"];
    if(feedLink==nil || [feedLink length]<3) feedLink = [feedInfo objectForKey:@"link"];
    if(giftInfo!=nil) {
        feedLink = [feedLink stringByAppendingFormat:@"&%@", [giftInfo objectForKey:@"params"]];
    }
    if (feedType == 4 || feedType == 5) {
        feedLink = [NSString stringWithFormat:@"%@from_uid=%@",[feedInfo objectForKey:@"link"],[SystemUtils getCurrentUID]];
    }
    // 添加客户端版本号
    feedLink = [feedLink stringByAppendingFormat:@"&cVer=%@",[SystemUtils getClientVersion]];
//    // NSString *deviceType = @"&devicetype=iPhone%20OS";
//    if (feedType == 4|| feedType == 5) {
//        WXAppExtendObject *etInfo = [WXAppExtendObject object];
//        etInfo.extInfo = [NSString stringWithFormat:@"%@,%d",[SystemUtils getCurrentUID],feedType];
//        message.mediaObject = etInfo;
//    }else{
        if(!publishImageFeed) {
            WXWebpageObject *pageInfo = [WXWebpageObject object];
            pageInfo.webpageUrl = feedLink;
            message.mediaObject = pageInfo;
            SNSLog(@"webpageURL:%@", feedLink);
        }
//    }
    
    SendMessageToWXReq* req = [[[SendMessageToWXReq alloc] init]autorelease];
    req.message = message;
    req.bText = NO;
    req.scene = scene;
    
    [WXApi sendReq:req];
}

- (void)publishCustomerFeed:(NSString *)imagePath
{
    currentRequestType = 100;
    if(![self checkWeixinInstalled]) return;
    
    if(!isInitialized) [self initSession];
    
    int scene = WXSceneTimeline;
    UIImage *img1 = [UIImage imageWithContentsOfFile:imagePath];
    if(img1==nil) return;
    
    WXMediaMessage *message = [WXMediaMessage message];
//    [message setThumbImage:img1];
    NSData * imgData = [NSData dataWithContentsOfFile:imagePath];
    if (!imgData) {
        return;
    }
    WXImageObject *ext = [WXImageObject object];
    ext.imageData =  imgData;
    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[[SendMessageToWXReq alloc] init]autorelease];
    req.message = message;
    req.bText = NO;
    req.scene = scene;
    
    [WXApi sendReq:req];
}

- (void) shareToFriends
{
    NSString *nsText = [SystemUtils getGlobalSetting:@"kWeixinFeedText"];
    if(nsText==nil || [nsText length]<10)
        nsText = [weixinInfo objectForKey:@"feedText"];
    
    SendMessageToWXReq* req = [[[SendMessageToWXReq alloc] init] autorelease];
    req.bText = YES;
    req.text = nsText;
    req.scene = WXSceneSession;
    
    [WXApi sendReq:req];
}


// 是否已经分享过了
- (BOOL) hasConnected
{
    int lastDate = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"kWeixinDate"] intValue];
    if(lastDate>0) return YES;
    return NO;
}
// 是否是connect的第一天
- (BOOL) isConnectedFirstDay
{
    int lastDate = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"kWeixinConnectDate"] intValue];
    if(lastDate==[SystemUtils getTodayDate]) return YES;
    return NO;
}

// 今天是否已经获得奖励了
- (BOOL) hasGotTodayPrize
{
    int lastDate = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"kWeixinDate"] intValue];
    if(lastDate==[SystemUtils getTodayDate]) return YES;
    return NO;
}

// 今天是否已经获得第2次奖励了
- (BOOL) hasGotTodayInvitePrize
{
    int todayTimes = [[SystemUtils getGlobalSetting:@"kWeixinTodayTimes"] intValue];
    if(todayTimes>=2) return YES;
    return NO;
}

// 今天的邀请次数
- (int) getTodayInviteCount
{
    int today = [SystemUtils getTodayDate];
    int lastDate = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"kWeixinInviteDate"] intValue];
    int todayTimes = [[SystemUtils getGlobalSetting:@"kWeixinTodayInviteTimes"] intValue];
    if(lastDate<today) return 0;
    return todayTimes;
}
// 今天发布到朋友圈的次数
- (int) getTodayPublishCount
{
    int today = [SystemUtils getTodayDate];
    int lastDate = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"kWeixinDate"] intValue];
    int todayTimes = [[SystemUtils getGlobalSetting:@"kWeixinTodayTimes"] intValue];
    if(lastDate<today) return 0;
    return todayTimes;
}


// onReq是微信终端向第三方程序发起请求，要求第三方程序响应。第三方程序响应完后必须调用sendRsp返回。在调用sendRsp返回时，会切回到微信终端程序界面
-(void) onReq:(BaseReq*)req
{
    ShowMessageFromWXReq * r = (ShowMessageFromWXReq *)req;
    WXMediaMessage * message = r.message;
    WXAppExtendObject * ex = message.mediaObject;
    NSString * exinfo = ex.extInfo;
    NSDictionary * dic = NULL;
    if (exinfo && exinfo.length > 0) {
        NSArray * array = [exinfo componentsSeparatedByString:@","];
        if ([array count] > 1) {
            dic = [NSDictionary dictionaryWithObjectsAndKeys:[array objectAtIndex:0],@"fid", [array objectAtIndex:1],@"type",  nil];
        }
    }
    
//     req.message;
//    [req ]
//    WXAppExtendObject *etInfo
    // post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAddWXFrd object:nil userInfo:dic];
}

// 如果第三方程序向微信发送了sendReq的请求，那么onResp会被回调。sendReq请求调用后，会切到微信终端程序界面。
-(void) onResp:(BaseResp*)resp
{
    if([resp isKindOfClass:[SendMessageToWXResp class]])
    {
        SNSLog(@"resp.errorCode:%d",resp.errCode);
        if(resp.errCode==WXSuccess) {
            // succeed, give prize
            NSString *title = @"发布成功"; NSString *hint = nil;
            int today = [SystemUtils getTodayDate];
            int lastDate = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"kWeixinDate"] intValue];
            int todayTimes = [[SystemUtils getGlobalSetting:@"kWeixinTodayTimes"] intValue];
            if(currentRequestType==0) {
                // 发到朋友圈
#ifdef DEBUG
                // today = lastDate+1;
#endif
                if(lastDate<today || (lastDate==today && todayTimes<1)) {
                    if(lastDate<today) todayTimes = 1;
                    else todayTimes++;
                    int prizeCount = 0; int prizeType = 0;
                    if(lastDate==0) {
                        // 首次发布到朋友圈，奖励30宝石
                        NSDictionary *info = [weixinInfo objectForKey:@"connectPrize"];
                        if(info && [info isKindOfClass:[NSDictionary class]]) {
                            prizeCount = [[info objectForKey:@"amount"] intValue];
                            prizeType  = [[info objectForKey:@"type"] intValue];
                            hint = [info objectForKey:@"hint"];
                        }
                    }
                    else {
                        // 当天第一次分享到朋友圈，奖励100星星
                        NSDictionary *info = [weixinInfo objectForKey:@"dailyPrize"];
                        if(info && [info isKindOfClass:[NSDictionary class]]) {
                            prizeCount = [[info objectForKey:@"amount"] intValue];
                            prizeType  = [[info objectForKey:@"type"] intValue];
                            hint = [info objectForKey:@"hint"];
                        }
                    }
                    [SystemUtils setGlobalSetting:[NSString stringWithFormat:@"%d",todayTimes] forKey:@"kWeixinTodayTimes"];
                    [[SystemUtils getGameDataDelegate] setExtraInfo:[NSString stringWithFormat:@"%d",today] forKey:@"kWeixinDate"];
                    // set kWeixinConnectDate
                    if(lastDate==0) [[SystemUtils getGameDataDelegate] setExtraInfo:[NSString stringWithFormat:@"%d",today] forKey:@"kWeixinConnectDate"];
                    if(prizeType>0 && prizeCount>0) {
                        [SystemUtils addGameResource:prizeCount ofType:prizeType];
                    }
                }
                else {
                    // duplicate, notice
                    NSDictionary *info = [weixinInfo objectForKey:@"dailyPrize"];
                    hint = [info objectForKey:@"hintAgain"];
                }
            }
            else if (currentRequestType == 4) {
                hint = @"发送好友请求成功，等待对方点击确认后你们将成为好友!";
            }
            else if (currentRequestType == 5) {
                hint = @"发送邀请成功，等待对方点击确认后你们将成为好友!";
            }
            else if (currentRequestType == 100){
                return;
            }
            else {
                // 邀请好友
                lastDate = [[[SystemUtils getGameDataDelegate] getExtraInfo:@"kWeixinInviteDate"] intValue];
                todayTimes = [[SystemUtils getGlobalSetting:@"kWeixinTodayInviteTimes"] intValue];
                // dailyInvitePrize
                if(lastDate<today || (lastDate==today && todayTimes<1)) {
                    if(lastDate<today) todayTimes = 1;
                    else todayTimes++;
                    int prizeCount = 0; int prizeType = 0;
                    NSDictionary *info = [weixinInfo objectForKey:@"dailyInvitePrize"];
                    if(info && [info isKindOfClass:[NSDictionary class]]) {
                        prizeCount = [[info objectForKey:@"amount"] intValue];
                        prizeType  = [[info objectForKey:@"type"] intValue];
                        hint = [info objectForKey:@"hint"];
                        // 邀请成功，这是今天第%d次邀请，你得到了30个星星的奖励。
                        hint = [NSString stringWithFormat:hint,todayTimes];
                        if(todayTimes<1) {
                            // 请继续邀请，你还有%d次获得奖励的机会。
                            NSString *hint2 = [info objectForKey:@"hintMore"];
                            if(hint2!=nil) {
                                hint2 = [NSString stringWithFormat:hint2,5-todayTimes];
                                hint = [hint stringByAppendingString:hint2];
                            }
                        }
                    }
                    [SystemUtils setGlobalSetting:[NSString stringWithFormat:@"%d",todayTimes] forKey:@"kWeixinTodayInviteTimes"];
                    [[SystemUtils getGameDataDelegate] setExtraInfo:[NSString stringWithFormat:@"%d",today] forKey:@"kWeixinInviteDate"];
                    if(prizeType>0 && prizeCount>0) {
                        [SystemUtils addGameResource:prizeCount ofType:prizeType];
                    }
                }
                else {
                    // duplicate, notice
                    NSDictionary *info = [weixinInfo objectForKey:@"dailyPrize"];
                    hint = [info objectForKey:@"hintAgain"];
                }
            }
            
            if(hint!=nil)
                [SystemUtils showSNSAlert:title message:hint];
            
            // post notification
            [[NSNotificationCenter defaultCenter] postNotificationName:kSNSNotificationWeixinFeedSuccess object:nil userInfo:nil];
            
            
            return;
        }
        return;
        if(resp.errCode==WXErrCodeUserCancel) return;
        NSString *strTitle = [NSString stringWithFormat:@"分享失败"];
        NSString *strMsg = [NSString stringWithFormat:@"微信分享失败，错误代码: %d", resp.errCode];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
        
    }
    /*
    else if([resp isKindOfClass:[SendAuthResp class]])
    {
        if(resp.errCode==WXSuccess) return;
        NSString *strTitle = [NSString stringWithFormat:@"验证失败"];
        NSString *strMsg = [NSString stringWithFormat:@"微信验证失败，错误代码: %d", resp.errCode];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
    }
     */
    
}

/*
[4] 如果你的程序要发消息给微信，那么需要调用WXApi的sendReq函数：
 -(BOOL) sendReq:(BaseReq*)req
其中req参数为SendMessageToWXReq类型。
需要注意的是，SendMessageToWXReq的scene成员，如果scene填WXSceneSession，那么消息会发送至微信的会话内。如果scene填WXSceneTimeline（微信4.2以上支持，如果需要检查微信版本支持API的情况， 可调用 [WXApi getWXAppSupportMaxApiVersion],SDK1.1版以上支持发送朋友圈），那么消息会发送至朋友圈。scene默认值为WXSceneSession。
*/

@end
