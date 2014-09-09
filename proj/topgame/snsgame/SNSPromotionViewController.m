//
//  SNSPromotionViewController.m
//  MovieSlots
//
//  Created by Leon Qiu on 4/21/14.
//
//

#import "SystemUtils.h"
#import "SnsServerHelper.h"
#import "StatSendOperation.h"
#import "SNSPromotionViewController.h"

@interface SNSPromotionViewController ()

@end

@implementation SNSPromotionViewController

SNSPromotionViewController *_promotionViewController = nil;

NSMutableArray *_promotionNoticeList = nil;
int _promotionNewNoticeCount = 0;
int _promotionCurrentNoticeIndex = 0;
@synthesize btnClose,btnNext,btnPrev, btnOK,labelInfo,imgBG, imgNew, noticeInfo, imgInfo,isPortrait;


// 创建并显示通知
+(SNSPromotionViewController *) createAndShow
{
    if(_promotionViewController!=nil) return _promotionViewController;
    @synchronized(self){
        NSString *nib = @"SNSPromotionView_landscape";
        if([SystemUtils getGameOrientation]==UIDeviceOrientationPortrait) nib = @"SNSPromotionView_portrait";
        if([SystemUtils isiPad]) nib = [nib stringByAppendingString:@"_ipad"];
        _promotionViewController = [[SNSPromotionViewController alloc] initWithNibName:nib bundle:nil];
        UIViewController *root = [SystemUtils getAbsoluteRootViewController];
        [root presentModalViewController:_promotionViewController animated:NO];
    }
    return _promotionViewController;
}
// 是否正在显示
+ (BOOL) isShowing
{
    if(_promotionViewController!=nil) return YES;
    return NO;
}
// 关闭通知
+ (void) closePromotionView
{
    if(_promotionViewController==nil) return;
    UIViewController *root = [SystemUtils getAbsoluteRootViewController];
    [root dismissModalViewControllerAnimated:NO];
    [_promotionViewController autorelease];
    _promotionViewController = nil;
}
// 添加文字通知
+ (void) addMessageNotice:(NSString *)mesg withAction:(NSString *)action
{
    /*
    @{
      @"action":@"https://itunes.apple.com/app/id538339878",
      @"auto_update": @0,
      @"country": @"GENERAL",
      @"country_limit":@0,
      @"endTime":@1399967800,
      @"hideClose":@0,
      @"id":@2,
      @"level":@0,
      @"message":@"在龙之魂中达到10级，可以获得10个宝石奖励，要接受挑战吗？",
      @"noticeVer":@1,
      @"os":@0,
      @"picBig":@"photo_hd5.png",
      @"picExt":@"png",
      @"picSmall":@"photo5.png",
      @"picVer":@0,
      @"prizeCond":@"4:10",
      @"prizeMesg":@"You've reached level 10 in Dragon Soul, you got 10 gems as bonus!",
      @"prizeGold":@0,
      @"prizeItem":@"",
      @"prizeId":@0,
      @"prizeLeaf":@10,
      @"startTime":@1389190200,
      @"subID":@2,
      @"type":@3,
      @"updateTime":@0,
      @"noClose":@1,
      @"urlScheme":@"dragonsoul://"
      }
     */
    NSDictionary *dict = @{@"action":action, @"message":mesg};
    [self addNotice:dict];
}

// 添加通知
+ (void) addNotice:(NSDictionary *)notice
{
    if(![SystemUtils isNoticeValid:notice]) return;
    
    NSDictionary *noticeInfo = notice;
    // set version
    int noticeID = [[noticeInfo objectForKey:@"id"] intValue];
    int noticeVer = [[noticeInfo objectForKey:@"noticeVer"] intValue];
    NSString *key = [NSString stringWithFormat:@"noticeVer-%i", noticeID];
    int autoUpdate = [[noticeInfo objectForKey:@"auto_update"] intValue];
    if(autoUpdate==1)
        [SystemUtils setGlobalSetting:[NSNumber numberWithInt:[SystemUtils getTodayDate]] forKey:key];
    else
        [SystemUtils setGlobalSetting:[NSNumber numberWithInt:noticeVer] forKey:key];

    
    if(_promotionNoticeList==nil) _promotionNoticeList = [[NSMutableArray alloc] init];
    _promotionNewNoticeCount++;
    int newID = [[notice objectForKey:@"id"] intValue];
    if(newID!=0) {
        // 排除重复的ID
        for(NSDictionary *info in _promotionNoticeList) {
            if([[info objectForKey:@"id"] intValue]==newID) {
                [notice retain];
                [_promotionNoticeList removeObject:info];
                [_promotionNoticeList addObject:notice];
                [notice release];
                return;
            }
        }
    }
    [_promotionNoticeList addObject:[NSMutableDictionary dictionaryWithDictionary:notice]];
}
// 删除通知
+ (void) deleteNotice:(NSDictionary *)notice
{
    [_promotionNoticeList removeObject:notice];
}
// 标记展示状态
+ (void) setViewStatus:(NSDictionary *)notice
{
    if([[notice objectForKey:@"shown"] intValue]==1) return;
    NSMutableDictionary *notice1 = nil;
    if([notice isKindOfClass:[NSMutableDictionary class]])
        notice1 = (id)notice;
    else {
        notice1 = [NSMutableDictionary dictionaryWithDictionary:notice];
        [_promotionNoticeList replaceObjectAtIndex:_promotionCurrentNoticeIndex withObject:notice1];
    }
    [notice1 setValue:[NSNumber numberWithInt:1] forKey:@"shown"];
    _promotionNewNoticeCount--;
    if(_promotionNewNoticeCount<0) _promotionNewNoticeCount = 0;
    [self saveNoticeList];
}
// 获得新通知数量
+ (int) getNewNoticeCount
{
    return _promotionNewNoticeCount;
}

// 获得有效通知数量
+ (int) getNoticeCount
{
    if(_promotionNoticeList==nil) return 0;
    return [_promotionNoticeList count];
}

// 存储通知
+ (void) saveNoticeList
{
    NSString *path = [SystemUtils getDocumentRootPath];
    path = [path stringByAppendingPathComponent:@"notice.plist"];
    if(_promotionNoticeList==nil) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        return;
    }
    [_promotionNoticeList writeToFile:path atomically:YES];
}
// 加载通知
+ (void) loadNoticeList
{
    NSString *path = [SystemUtils getDocumentRootPath];
    path = [path stringByAppendingPathComponent:@"notice.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) return;

    NSArray *arr = [NSArray arrayWithContentsOfFile:path];
    if(arr==nil || [arr count]==0) return;
    if(_promotionNoticeList==nil) _promotionNoticeList = [[NSMutableArray alloc] initWithCapacity:[arr count]];
    int skipCount = 0;
    for(NSDictionary *dict in arr) {
        if(![dict isKindOfClass:[NSDictionary class]]) {
            skipCount++;
            continue;
        }
        // 检查通知是否仍然有效
        if(![SystemUtils isSavedNoticeValid:dict]) {
            skipCount++; continue;
        }
        if([[dict objectForKey:@"shown"] intValue]==0) _promotionNewNoticeCount++;
        [_promotionNoticeList addObject:[NSMutableDictionary dictionaryWithDictionary:dict]];
    }
    if(skipCount>0) {
        [self saveNoticeList];
    }
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.isPortrait = YES;
        if(nibNameOrNil!=nil) {
            NSRange r = [nibNameOrNil rangeOfString:@"landscape"];
            if(r.location!=NSNotFound) self.isPortrait = NO;
        }
    }
    return self;
}

-(void)tapDetected{
    NSLog(@"single Tap on imageview");
    [self onClickBtnOK];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if(_promotionNoticeList==nil || [_promotionNoticeList count]==0) {
        labelInfo.text = [SystemUtils getLocalizedString:@"No notice available!"];
        btnNext.hidden = YES; btnPrev.hidden = YES;
        return;
    }
    if(_promotionNewNoticeCount>0) {
        // 定位到新的通知，通知上加个new标志
        int i = 0;
        for(i=0;i<[_promotionNoticeList count];i++) {
            NSDictionary *info = [_promotionNoticeList objectAtIndex:i];
            if([[info objectForKey:@"shown"] intValue]==0) break;
        }
        if(i<[_promotionNoticeList count]) _promotionCurrentNoticeIndex = i;
    }
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected)];
    singleTap.numberOfTapsRequired = 1;
    imgInfo.userInteractionEnabled = YES;
    [imgInfo addGestureRecognizer:singleTap];
    
    if(_promotionCurrentNoticeIndex>=[_promotionNoticeList count]) _promotionCurrentNoticeIndex = 0;
    SNSLog(@"Show Notice:%d/%d", _promotionCurrentNoticeIndex, [_promotionNoticeList count]);
    NSDictionary *notice = [_promotionNoticeList objectAtIndex:_promotionCurrentNoticeIndex];
    self.noticeInfo = notice;
    int type = [[notice objectForKey:@"type"] intValue];
    if(type==4) {
        // new image notice
        labelInfo.hidden = YES;
        int noticeID = [[noticeInfo objectForKey:@"id"] intValue];
        int picVer = [[noticeInfo objectForKey:@"picVer"] intValue];
        NSString *countryCode = [SystemUtils getNoticeCountryCode:[noticeInfo objectForKey:@"country"]];
        NSString *imageFile = [SystemUtils getNoticeImageFile:noticeID withVer:picVer andCountry:countryCode];
        if([SystemUtils isRetina]) imageFile = [imageFile stringByReplacingOccurrencesOfString:@"@2x" withString:@""];
        UIImage *img = [UIImage imageWithContentsOfFile:imageFile];
        imgInfo.image = img;
        /*
        CGRect f = imgInfo.frame; // 图片允许的最大尺寸
        float fw = img.size.width;
        float fh = img.size.height;
        if(fw>f.size.width) {
            fh = fh * f.size.width/fw;
            fw = f.size.width;
        }
        if(fh>f.size.height) {
            fw = fw * f.size.height/fh;
            fh = f.size.height;
        }
        
        float dx = (f.size.width-fw)/2;
        float dy = (f.size.height-fh)/2;
        imgInfo.frame = CGRectMake(f.origin.x+dx, f.origin.y+dy, fw, fh);
         */
    }
    else
    {
        // new text notice
        NSString *mesg = [notice objectForKey:@"message"];
        if(mesg!=nil) {
            mesg = [SystemUtils parseMultiLangStrForCurrentLang:mesg];
            labelInfo.text = mesg;
            imgInfo.hidden = YES;
        }
    }
    if([_promotionNoticeList count]==1) {
        btnNext.hidden = YES;
        btnPrev.hidden = YES;
    }
    
    btnPrev.transform = CGAffineTransformMake(btnPrev.transform.a * -1, 0, 0, 1, btnPrev.transform.tx, 0);
    [self.view setContentMode:UIViewContentModeCenter];
    if([[notice objectForKey:@"shown"] intValue]==1) imgNew.hidden = YES;
    else {
        [SNSPromotionViewController setViewStatus:noticeInfo];
        self.noticeInfo = [_promotionNoticeList objectAtIndex:_promotionCurrentNoticeIndex];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) onClickBtnOK
{
    // ok, do action
    [self doNoticeAction];
    [SNSPromotionViewController deleteNotice:self.noticeInfo];
    [SNSPromotionViewController closePromotionView];
}

- (IBAction) onClick:(UIButton *)btn
{
    SNSLog(@"tag=%d",btn.tag);
    
    if(btn.tag==1) {
        [self onClickBtnOK];
    }
    else {
        [SNSPromotionViewController closePromotionView];
    }
    if(btn.tag==2) {
        // next notice
        _promotionCurrentNoticeIndex++;
        if(_promotionCurrentNoticeIndex>=[_promotionNoticeList count])
            _promotionCurrentNoticeIndex = 0;
        [SNSPromotionViewController createAndShow];
    }
    if(btn.tag==3) {
        // prev notice
        _promotionCurrentNoticeIndex--;
        if(_promotionCurrentNoticeIndex<0)
            _promotionCurrentNoticeIndex = [_promotionNoticeList count]-1;
        [SNSPromotionViewController createAndShow];
    }
}

// 执行通知的动作
- (void) doNoticeAction
{
    /*
     @{
     @"action":@"https://itunes.apple.com/app/id538339878",
     @"auto_update": @0,
     @"country": @"GENERAL",
     @"country_limit":@0,
     @"endTime":@1399967800,
     @"hideClose":@0,
     @"id":@2,
     @"level":@0,
     @"message":@"在龙之魂中达到10级，可以获得10个宝石奖励，要接受挑战吗？",
     @"noticeVer":@1,
     @"os":@0,
     @"picBig":@"photo_hd5.png",
     @"picExt":@"png",
     @"picSmall":@"photo5.png",
     @"picVer":@0,
     @"prizeCond":@"4:10",
     @"prizeMesg":@"You've reached level 10 in Dragon Soul, you got 10 gems as bonus!",
     @"prizeGold":@0,
     @"prizeItem":@"",
     @"prizeId":@0,
     @"prizeLeaf":@10,
     @"startTime":@1389190200,
     @"subID":@2,
     @"type":@3,
     @"updateTime":@0,
     @"noClose":@1,
     @"urlScheme":@"dragonsoul://"
     }
     */
    
    NSDictionary *info = self.noticeInfo;
    
    int prizeCoin = [[info objectForKey:@"prizeGold"] intValue];
	int prizeLeaf = [[info objectForKey:@"prizeLeaf"] intValue];
	int prizeExp  = [[info objectForKey:@"prizeExp"] intValue];
    int level     = [[info objectForKey:@"setLevel"] intValue];
    int noticeID = [[info objectForKey:@"id"] intValue];
    NSString *action = [info objectForKey:@"action"];
    
    NSString *items = [info objectForKey:@"prizeItems"];
    NSString *urlScheme = [noticeInfo objectForKey:@"urlScheme"];
    int pendingPrize = 0;
    BOOL hasPrize = (prizeCoin>0 || prizeLeaf>0 || prizeExp>0 || level>0 || (items!=nil && [items length]>0));
    if(hasPrize && urlScheme && [urlScheme length]>0) {
        prizeCoin = 0; prizeLeaf = 0; items = nil;
        pendingPrize = 1;
        [SystemUtils setNSDefaultObject:info forKey:[NSString stringWithFormat:@"prizeNotice-%d",noticeID]];
    }

    if(items && [items length]>0) {
        NSArray *arr = [items componentsSeparatedByString:@","];
        for (NSString *str in arr) {
            NSArray *arr2 = [str componentsSeparatedByString:@":"];
            if([arr2 count]==2) {
                int resType = [[arr2 objectAtIndex:0] intValue];
                int count = [[arr2 objectAtIndex:1] intValue];
                if(resType>0 && count>0) {
                    SNSLog(@"add resource: type:%i count:%i", resType, count);
                    [SystemUtils addGameResource:count ofType:resType];
                }
            }
        }
    }
    
    //NSLog(@"开始做各种打开窗口、给钱等等的事情");
	if (prizeCoin > 0) {
        [SystemUtils addGameResource:prizeCoin ofType:kGameResourceTypeCoin];
		// [[GameData gameData] addCoines:prizeCoin];
	}
	if (prizeLeaf > 0) {
        [SystemUtils addGameResource:prizeLeaf ofType:kGameResourceTypeLeaf];
	}
	if (prizeExp > 0) {
        [SystemUtils addGameResource:prizeExp ofType:kGameResourceTypeExp];
	}
    if(level>0) {
        [SystemUtils addGameResource:level ofType:kGameResourceTypeLevel];
    }
	
    BOOL doAction = YES;
    if(pendingPrize==1 && noticeID>0) {
        if(noticeInfo && [noticeInfo isKindOfClass:[NSDictionary class]]) {
            doAction = NO;
            NSString *prizeCond = [noticeInfo objectForKey:@"prizeCond"];
            if(prizeCond && [prizeCond isEqualToString:@"install"]) {
                NSString *key = @"pendingInstallPrize";
                NSString *prizeList = [SystemUtils getNSDefaultObject:key];
                if(prizeList!=nil && [prizeList length]>0) prizeList = [prizeList stringByAppendingFormat:@",%d",noticeID];
                else prizeList = [NSString stringWithFormat:@"%d",noticeID];
                [SystemUtils setNSDefaultObject:prizeList forKey:key];
                doAction = YES;
            }
            else {
                // 标记点击状态
                NSString *clickKey = [NSString stringWithFormat:@"prizeClick_%d",noticeID];
                [[SystemUtils getGameDataDelegate] setExtraInfo:@"1" forKey:clickKey];
                [[SnsServerHelper helper] startCrossPromoTask:noticeInfo];
            }
        }
    }
    if(doAction) {
        if ([action isKindOfClass:[NSString class]] && [action length]>3) {
            NSRange r = [action rangeOfString:@"://"];
            if (r.location!=NSNotFound) {
                // 处理打开网页连接
                // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:action]];
                [SystemUtils openAppLink:action];
            } else {
                // [[CGameScene gameScene] runCommand:action];
                [SystemUtils runCommand:action];
            }
        }
    }
    
    // send noticeReport
    if(noticeID>0) {
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:noticeID] forKey:kClickedNoticeID];
        
        SyncQueue *syncQueue = [SyncQueue syncQueue];
        NoticeReportOperation *repOp = [[NoticeReportOperation alloc] initWithManager:syncQueue andDelegate:nil];
        repOp.noticeID = noticeID; repOp.actionType = kSNSNoticeActionTypeClick;
        [syncQueue.operations addOperation:repOp];
        [repOp release];
    }
}

// Override to allow orientations other than the default portrait orientation.
// This method is deprecated on ios6
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if(self.isPortrait) return UIInterfaceOrientationIsPortrait(interfaceOrientation);
    return UIInterfaceOrientationIsLandscape( interfaceOrientation );
}

// For ios6, use supportedInterfaceOrientations & shouldAutorotate instead
- (NSUInteger) supportedInterfaceOrientations{
    if(self.isPortrait) return UIInterfaceOrientationPortrait;
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL) shouldAutorotate {
    return NO;
}

- (IBAction) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{    
    UITouch *touch = [touches anyObject];
    
    if ([touch view] == imgInfo)
    {
        // add your code for image touch here
        [self onClickBtnOK];
    }
    
}

@end
