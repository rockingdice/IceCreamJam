//
//  smWinQueueAlert.m
//  iPetHotel
//
//  Created by yang jie on 21/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import "smPopupWindowImageNotice.h"
#import "smPopupWindowAction.h"
#import "StatSendOperation.h"

@implementation smPopupWindowImageNotice
@synthesize setting, closeBtn, adImage, shouldDeleteImage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        shouldDeleteImage = YES;
    }
    return self;
}

- (void)dealloc {
	self.setting = nil;
	self.closeBtn = nil;
	self.adImage = nil;
    // delete notice image
    if(shouldDeleteImage && m_imageFilePath) {
        [[NSFileManager defaultManager] removeItemAtPath:m_imageFilePath error:nil];
        [m_imageFilePath release]; m_imageFilePath = nil;
    }
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - User method

- (IBAction)closeBox {
    [super closeDialog];
    // delete notice image
    if(shouldDeleteImage && m_imageFilePath) {
        SNSLog(@"delete notice image:%@",m_imageFilePath);
        [[NSFileManager defaultManager] removeItemAtPath:m_imageFilePath error:nil];
        [m_imageFilePath release]; m_imageFilePath = nil;
    }
}

- (void)didDialogClose {
	[super didDialogClose];
    // delete notice image
    if(shouldDeleteImage && m_imageFilePath) {
        SNSLog(@"delete notice image:%@",m_imageFilePath);
        [[NSFileManager defaultManager] removeItemAtPath:m_imageFilePath error:nil];
        [m_imageFilePath release]; m_imageFilePath = nil;
    }
}

- (IBAction)doAction {
	NSString *action = (NSString *)[setting objectForKey:@"action"];
	if([action isKindOfClass:[NSString class]] && [action length] >= 3) {
		// [[smWinQueueAction action] doAction:[setting objectForKey:@"action"] prizeCoin:[[setting objectForKey:@"prizeCoin"] intValue] prizeLeaf:[[setting objectForKey:@"prizeLeaf"] intValue]];    
		[smPopupWindowAction doAction:action withInfo:setting];
	}
	[self closeBox];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
	SNSLog(@"%s: setting:%@", __FUNCTION__, setting);
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSString *imageName = [setting objectForKey:@"image"]; //[[NSBundle mainBundle] pathForResource:@"JuChu_Icon" ofType:@"png"]; //
    if(![imageName isKindOfClass:[NSString class]]) return;
    m_imageFilePath = nil;
    if([SystemUtils isRetina]) {
        imageName = [imageName stringByReplacingOccurrencesOfString:@"@2x" withString:@""];
        m_imageFilePath = [imageName stringByReplacingOccurrencesOfString:@".png" withString:@"@2x.png"];
        if([[NSFileManager defaultManager] fileExistsAtPath:m_imageFilePath])
            [m_imageFilePath retain];
        else
            m_imageFilePath = nil;
    }
    if(m_imageFilePath==nil) {
        m_imageFilePath = [imageName retain];
    }
	UIImage *images = [UIImage imageWithContentsOfFile:m_imageFilePath];
	[self.adImage setImage:images];
    
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
    
    NSString *closeBtnImage = [setting objectForKey:@"closeBtnImage"];
    if(closeBtnImage) {
        UIImage *img = [UIImage imageWithContentsOfFile:closeBtnImage];
        CGRect r = closeBtn.frame;
        r.size.width = img.size.width;
        r.size.height = img.size.height;
        closeBtn.frame = r;
        // [closeBtn setImage:img forState:UIControlStateNormal];
        [closeBtn setBackgroundImage:img forState:UIControlStateNormal];
        // [closeBtn.imageView setImage:img];
        
        // noClose=1时不显示关闭按钮
        int noClose = [[setting objectForKey:@"noClose"] intValue];
        if(noClose==1) closeBtn.hidden = YES;
        
    }
    
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.setting = nil;
	self.closeBtn = nil;
	self.adImage = nil;
}

- (void)sizeToFitOrientation:(BOOL)transform {
	if (transform) {
		self.view.transform = CGAffineTransformIdentity;
	}
	
	self.privateOrientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
    CGRect frame =[UIScreen mainScreen].applicationFrame;
	CGPoint center = CGPointMake(frame.size.width * 0.5f, frame.size.height * 0.5f);
	
	self.view.center = center;
	CGFloat width = frame.size.width;
	CGFloat height = frame.size.height;
	
	if (UIInterfaceOrientationIsLandscape(self.privateOrientation)) {
        //横着的时候
		self.view.frame = CGRectMake(0, 0, height, width);
	} else {
		//竖着的时候
		self.view.frame = CGRectMake(0, 0, width, height);
	}
	
	float imageWidth = self.adImage.image.size.width;
	float imageHeight = self.adImage.image.size.height;
	if (imageWidth > self.view.frame.size.width || imageHeight > self.view.frame.size.height) {
		self.adImage.contentMode = UIViewContentModeScaleAspectFit;
	} else {
		self.adImage.contentMode = UIViewContentModeCenter;
	}
	//NSLog(@"frame size:%f -- %f", self.view.frame.size.width, self.view.frame.size.height);
	//NSLog(@"%s - image size:%f -- %f", __FUNCTION__, imageWidth, imageHeight);
	//NSLog(@"close Button size:%f -- %f", self.closeBtn.frame.size.width, self.closeBtn.frame.size.height);
	float closeButtonX = (self.view.frame.size.width + imageWidth) * 0.5f - self.closeBtn.frame.size.width;
	float closeButtonY = (self.view.frame.size.height - imageHeight) * 0.5f;
	if (closeButtonX < 0) closeButtonX = 0;
	if (closeButtonY < 0) closeButtonY = 0;
	if (closeButtonX >= self.view.frame.size.width) closeButtonX = (float)(self.view.frame.size.width - self.closeBtn.frame.size.width);
	if (closeButtonY >= self.view.frame.size.height) closeButtonY = (float)(self.view.frame.size.height - self.closeBtn.frame.size.height);
	//NSLog(@"%s - close button position:%f -- %f", __FUNCTION__, closeButtonX, closeButtonY);
	self.closeBtn.frame = CGRectMake(closeButtonX, closeButtonY, self.closeBtn.frame.size.width, self.closeBtn.frame.size.height);
	
	if (transform) {
		self.view.transform = [self transformForOrientation];
	}
}

@end
