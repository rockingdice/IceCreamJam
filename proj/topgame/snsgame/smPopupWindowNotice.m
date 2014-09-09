//
//  smWinQueueAlert.m
//  iPetHotel
//
//  Created by yang jie on 21/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import "smPopupWindowNotice.h"
#import "smPopupWindowAction.h"
#import "StatSendOperation.h"
#import "InAppStore.h"
#import "SNSLogType.h"

@implementation smPopupWindowNotice

@synthesize textView, setting, closeBtn, okBtn;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - User method

- (IBAction) closeBox
{
    [super closeDialog];
}


- (IBAction) doAction
{
	// [[smWinQueueAction action] doAction:[setting objectForKey:@"action"] prizeCoin:[[setting objectForKey:@"prizeCoin"] intValue] prizeLeaf:[[setting objectForKey:@"prizeLeaf"] intValue]];    
	[smPopupWindowAction doAction:[setting objectForKey:@"action"] withInfo:setting];    
    [self closeBox];
}

#pragma mark smPopupWindowQueueDelegate
// 检查目前是否可以显示
- (BOOL) isReadyToShow
{
    NSString *action = [setting objectForKey:@"action"];
    if(action==nil || [action length]<10) return YES;
    // 检查IAP是否已经下载
    // buyIAP#
    SNSLog(@"checking action:%@", action);
    if([[action substringToIndex:7] isEqualToString:@"buyIAP#"])
    {
        NSString *iapID = [action substringFromIndex:7];
        if([[InAppStore store] isIAPItemDownloaded:iapID]) {
            SNSLog(@"iap is ready:%@", iapID);
            return YES;
        }
        SNSLog(@"iap not ready:%@", iapID);
        return NO;
    }
    return YES;
}

#pragma mark -

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	SNSLog(@"%s: setting:%@", __FUNCTION__, setting);
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSString *contents = [setting objectForKey:@"content"];
	NSString *action = [setting objectForKey:@"action"];
    if (contents != nil) {
        textView.text = contents;
    }
    NSString *txtColor = [SystemUtils getSystemInfo:@"kNoticeTextColor"];
    if(txtColor) {
        NSArray *arr = [txtColor componentsSeparatedByString:@","];
        if([arr count]>=3) {
            int red = [[arr objectAtIndex:0] intValue];
            int green = [[arr objectAtIndex:1] intValue];
            int blue = [[arr objectAtIndex:2] intValue];
            textView.textColor = [UIColor colorWithRed:red green:green blue:blue alpha:255];
        }
    }
    
    int noClose = [[setting objectForKey:@"noClose"] intValue];
    if(action==nil || [action length]<=3 || noClose==1) {
        closeBtn.hidden = YES;
#ifndef SNS_NOTICE_FIX_CANCEL_BUTTON
        CGRect f = okBtn.frame;
        okBtn.frame = CGRectMake((closeBtn.frame.origin.x + f.origin.x)/2, f.origin.y, f.size.width, f.size.height);
        // okBtn.frame.origin.x = (closeBtn.frame.origin.x + okBtn.frame.origin.x)/2;
#endif
    }
    
    // send noticeReport
    if([setting objectForKey:@"noticeID"]) {
        int noticeID = [[setting objectForKey:@"noticeID"] intValue];
        if(noticeID>0) {
            SyncQueue *syncQueue = [SyncQueue syncQueue];
            NoticeReportOperation *repOp = [[NoticeReportOperation alloc] initWithManager:syncQueue andDelegate:nil];
            repOp.noticeID = noticeID; repOp.actionType = kSNSNoticeActionTypeView;
            [syncQueue.operations addOperation:repOp];
            [repOp release];
        }
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.textView = nil;
    self.setting = nil;
	self.closeBtn = nil;
	self.okBtn = nil;
}

@end
