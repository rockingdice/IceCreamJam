//
//  ChartBoostHelper.m
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "iCloudHelper.h"
#import "SystemUtils.h"
#import "StringUtils.h"

enum {
    kiCloudHelperAlertTagNone,
    kiCloudHelperAlertTagConfirmFirstTime,
    kiCloudHelperAlertTagAccountChange,
};

enum {
    kiCloudEnableStatusNone,
    kiCloudEnableStatusUsed,
    kiCloudEnableStatusDenied,
};

@implementation iCloudHelper

static iCloudHelper *_giCloudHelper = nil;

+ (iCloudHelper *) helper
{
    if(!_giCloudHelper) {
        _giCloudHelper = [[iCloudHelper alloc] init];
        // [_gChartBoostHelper initSession];
    }
    return _giCloudHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO; enableStatus = kiCloudEnableStatusNone; currentToken = nil; newToken = nil; isAvailable = NO;
        myUbiquityContainer = nil; iCloudQuery = nil;
    }
    return self;
}

- (void) dealloc
{
    if(currentToken!=nil) [currentToken release];
    if(iCloudQuery!=nil) [iCloudQuery release];
    [super dealloc];
}

- (void) initSession
{
    if(isInitialized) return;
    SNSLog(@"start icloud helper");
    isInitialized = YES;
    if([[SystemUtils getiOSVersion] compare:@"6.0"]<0) return;
    isAvailable = YES;
    
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector (iCloudAccountAvailabilityChanged:)
     name: NSUbiquityIdentityDidChangeNotification
     object: nil];
    
    NSData *tokenData = [[NSUserDefaults standardUserDefaults] objectForKey:@"iCloudUbiquityIdentityToken"];
    if(tokenData!=nil) {
        currentToken = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
        if(currentToken!=nil) [currentToken retain];
        enableStatus = [[[NSUserDefaults standardUserDefaults] objectForKey:@"iCloudStatus"] intValue];
    }
}

// 重新获取token，在启动和从后台恢复时调用
- (void) refreshToken
{
    if(!isAvailable) return;
    
    id iCloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
    
    if (iCloudToken) {
        if(currentToken!=nil && [currentToken isEqualToString:iCloudToken]) return;
        newToken = [iCloudToken retain];
        [self saveNewToken];
        if(currentToken==nil) {
            [self showFirstTimeConfirmAlert];
            return;
        }
        
        if(currentToken!=nil && ![iCloudToken isEqual:currentToken]) {
            // show account change alert
            [self showAccountChangeAlert];
            return;
        }
        
        
    } else {
        enableStatus = kiCloudEnableStatusNone;
        [[NSUserDefaults standardUserDefaults]
         removeObjectForKey: @"iCloudUbiquityIdentityToken"];
        [[NSUserDefaults standardUserDefaults]
         removeObjectForKey: @"iCloudStatus"];
        if(currentToken!=nil ) {
            [currentToken release]; currentToken = nil;
        }
    }
}

- (void) deleteCurrentToken
{
    if(currentToken!=nil) {
        [currentToken release]; currentToken = nil;
        [[NSUserDefaults standardUserDefaults]
         removeObjectForKey: @"iCloudUbiquityIdentityToken"];
        [[NSUserDefaults standardUserDefaults]
         removeObjectForKey: @"iCloudStatus"];
    }
}

- (void) saveNewToken
{
    NSData *newTokenData =
    [NSKeyedArchiver archivedDataWithRootObject: newToken];
    [[NSUserDefaults standardUserDefaults]
     setObject: newTokenData
     forKey: @"iCloudUbiquityIdentityToken"];
}

- (void) clearNewToken
{
    if(newToken != nil) {
        [newToken release]; newToken = nil;
    }
}

- (void) setEnableStatus:(int)status
{
    enableStatus = status;
    [[NSUserDefaults standardUserDefaults]
     setObject: [NSNumber numberWithInt:status]
     forKey: @"iCloudStatus"];
    myUbiquityContainer = nil;
}

- (void) checkiCloudGameData
{
    if(myUbiquityContainer==nil) {
        [self refreshUbiquityContainer];
        return;
    }
    // 检查是否存在存档文件
    iCloudQuery = [[NSMetadataQuery alloc] init];
    
    iCloudQuery.searchScopes = @[NSMetadataQueryUbiquitousDataScope];
    
    NSString *filePattern = @"save.dat";
    
    // kMDItemFSName
    // iCloudQuery.predicate = [NSPredicate predicateWithFormat:@"%K LIKE %@", NSMetadataItemFSNameKey, filePattern];
    iCloudQuery.predicate = [NSPredicate predicateWithFormat:@"%K == %@", NSMetadataItemFSNameKey, filePattern];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudQueryDidFinishGathering:) name:NSMetadataQueryDidFinishGatheringNotification object:iCloudQuery];
    
    // 检查这个帐号下是否已经有存档文件了，如果有，并且和当前UID不同，就提示切换，否则禁用iCloud
    [iCloudQuery startQuery];
}

- (void) checkSaveDataOwner:(NSURL *)path
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:path];
    // verify
    NSString *uid = [dict objectForKey:@"uid"];
    NSString *time = [dict objectForKey:@"time"];
    NSString *data = [dict objectForKey:@"data"];
    NSString *hash = [dict objectForKey:@"tag"];
    if(uid!=nil && time!=nil && data!=nil && hash!=nil) {
        NSString *text = [NSString stringWithFormat:@"%@-%@-xdifw7033-%@",uid, time, [StringUtils stringByHashingStringWithMD5:data]];
        if(![hash isEqualToString:[StringUtils stringByHashingStringWithMD5:text]]) return;
        NSString *curUID = [SystemUtils getCurrentUID];
        if(curUID!=nil && ![uid isEqualToString:curUID]) {
            // TODO: 这是另一个用户的存档，提示切换存档
        }
        if(curUID==nil || [curUID intValue]==0) {
            // TODO: 设置当前用户UID
        }
        
        int saveID = [[dict objectForKey:@"saveID"] intValue];
        int curSaveID = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeExp];
        if(saveID > curSaveID)
        {
            // 使用iCloud中的存档
        }
    }
}

- (void) iCloudQueryDidFinishGathering
{
    int resultCount = [iCloudQuery resultCount];
    // for (int i = 0; i < resultCount; i++) {
    if(resultCount>0) {
        NSMetadataItem *item = [iCloudQuery resultAtIndex:0];
        
        // BOOL isUploaded = [[item valueForAttribute:NSMetadataUbiquitousItemIsUploadedKey] boolValue];
        // BOOL isDownloaded = [[item valueForAttribute:NSMetadataUbiquitousItemIsDownloadedKey] boolValue];
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
        BOOL documentExists = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
        
        // You'll need to check isUploaded against the URL of the file you injected, rather than against any other files your query returns
        if(documentExists) {
            // 有存档，检查UID
            [self checkSaveDataOwner:url];
        }
    }

}

- (void) refreshUbiquityContainer
{
    dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        myUbiquityContainer = [[NSFileManager defaultManager]
                               URLForUbiquityContainerIdentifier: nil];
        if (myUbiquityContainer != nil) {
            // Your app can write to the ubiquity container
            
            
            dispatch_async (dispatch_get_main_queue (), ^(void) {
                // On the main thread, update UI and state as appropriate
                [self checkiCloudGameData];
            });
        }
    });
}


- (void) showFirstTimeConfirmAlert
{
    NSString *msg = [SystemUtils getLocalizedString:@"Will you use iCloud to store your game data? iCloud can sync your game data to your other devices."];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: [SystemUtils getLocalizedString:@"iCloud Confirm"]
                          message: msg
                          delegate: self
                          cancelButtonTitle: [SystemUtils getLocalizedString:@"Not Now"]
                          otherButtonTitles: [SystemUtils getLocalizedString:@"Great!"], nil];
    alert.tag = kiCloudHelperAlertTagConfirmFirstTime;
    [alert show];
}

- (void) showAccountChangeAlert
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: [SystemUtils getLocalizedString:@"iCloud Account Changed"]
                          message: [SystemUtils getLocalizedString:@"Will you save your game data in the current iCloud account?"]
                          delegate: self
                          cancelButtonTitle: [SystemUtils getLocalizedString:@"No"]
                          otherButtonTitles: [SystemUtils getLocalizedString:@"Yes"], nil];
    alert.tag = kiCloudHelperAlertTagAccountChange;
    [alert show];
}

- (BOOL) isiCloudUsed
{
    return (enableStatus==kiCloudEnableStatusUsed);
}

- (void) iCloudAccountAvailabilityChanged:(NSNotification *)note
{
    [self refreshToken];
}


#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == kiCloudHelperAlertTagConfirmFirstTime) {
        if(buttonIndex==1) {
            [self setEnableStatus:kiCloudEnableStatusUsed];
            [self checkiCloudGameData];
        }
        else {
            [self setEnableStatus:kiCloudEnableStatusDenied];
        }
        currentToken = newToken; newToken = nil;
    }
    if(alertView.tag == kiCloudHelperAlertTagAccountChange) {
        if(buttonIndex==1) {
            [self setEnableStatus:kiCloudEnableStatusUsed];
            [self checkiCloudGameData];
        }
        else {
            [self setEnableStatus:kiCloudEnableStatusDenied];
        }
        if(currentToken!=nil) [currentToken release];
        currentToken = newToken; newToken = nil;
    }
}

#pragma mark -



@end
