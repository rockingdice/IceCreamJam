//
//  SNSAlertView.m
//  TapCar
//
//  Created by Jie Yang on 12/13/11.
//  Copyright (c) 2011 topgame.com. All rights reserved.
//

#import "SNSAlertView.h"
#import "smPopupWindowQueue.h"
#import "SystemUtils.h"

@implementation SNSAlertView
@synthesize alertDelegate = m_alertDelegate;
@synthesize alertTitle = m_title;
@synthesize alertContent = m_content;
@synthesize alertCancelButton = m_cancelButton;
@synthesize tag = m_tag;
@synthesize showInQueue = m_showInQueue;

- (id) initWithTitle:(NSString *)title message:(NSString *)message delegate:(id<SNSAlertViewDelegate>)delegates cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitle:(NSString *)otherButtonTitle, ...
{
	self = [super initWithNibName:@"SNSAlertView" bundle:nil];
	if (self) {
		m_tempTitle = [title copy];
		m_tempContent = [message copy];
		m_tempCancelButton = [cancelButtonTitle copy];
		self.alertDelegate = delegates;
		m_otherButton = otherButtonTitle;
        if(m_otherButton) [m_otherButton retain];
		va_list args;
		va_start(args, otherButtonTitle);
		m_args = args;
		va_end(args);
        m_buttonIndex = 0;
		//[[smPopupWindowQueue createQueue] pushToQueue:self timeOut:0];
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - User function


- (void) clickOtherButton:(id)sender
{
	if ([sender isKindOfClass:[UIButton class]]) {
		m_buttonIndex = ((UIButton *)sender).tag;
	}
    [self closeDialog];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	SNSLog(@"self view:%@", [self.view description]);
	self.alertTitle.text = m_tempTitle;
	self.alertContent.text = m_tempContent;
	[m_cancelButton setTitle:m_tempCancelButton forState:UIControlStateNormal];
	//设置可拉伸图像，让按钮的图片看起来不那么怪
	UIImage *stretchableButtonImageNormal = [[UIImage imageNamed:@"wqAlertButton.png"] stretchableImageWithLeftCapWidth:20 topCapHeight:10];
    // 设置文字颜色
    NSString *txtColor = [SystemUtils getSystemInfo:@"kNoticeTextColor"];
#ifdef JELLYMANIA
    stretchableButtonImageNormal = [[UIImage imageNamed:@"wqAlertButton.png"] stretchableImageWithLeftCapWidth:40 topCapHeight:10];
    txtColor = @"105,60,47";
#endif
    if(txtColor) {
        NSArray *arr = [txtColor componentsSeparatedByString:@","];
        if([arr count]>=3) {
            float red = [[arr objectAtIndex:0] floatValue];
            float green = [[arr objectAtIndex:1] floatValue];
            float blue = [[arr objectAtIndex:2] floatValue];
            self.alertTitle.textColor = [UIColor colorWithRed:red/255.f green:green/255.f blue:blue/255.f alpha:1.f];
            self.alertContent.textColor = [UIColor colorWithRed:red/255.f green:green/255.f blue:blue/255.f alpha:1.f];
        }
    }
	
	int z = 0;
	if (m_otherButton) {
		NSString *i = m_otherButton;
		// while(i) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
#ifdef SNS_NOTICE_FIX_CANCEL_BUTTON
        CGRect fm = m_cancelButton.frame;
        button.frame = CGRectMake(fm.origin.x-fm.size.width/2-20, fm.origin.y, fm.size.width, fm.size.height);
        m_cancelButton.frame = CGRectMake(fm.origin.x+fm.size.width/2+20, fm.origin.y, fm.size.width, fm.size.height);
        button.titleLabel.font = m_cancelButton.titleLabel.font;
#else
			button.frame = CGRectMake(169, 272 + (40 * z), 118, 38);
			button.titleLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:18.0f];
#endif
			button.tag = z+1;
			[button setBackgroundImage:stretchableButtonImageNormal forState:UIControlStateNormal];
			[button setTitle:i forState:UIControlStateNormal];
			[button addTarget:self action:@selector(clickOtherButton:) forControlEvents:UIControlEventTouchUpInside];
			[self.view addSubview:button];
			z++;
			i = va_arg(m_args, NSString*);
		// }
	} else {
#ifndef SNS_NOTICE_FIX_CANCEL_BUTTON
		//否则移动取消按钮的位置到屏幕正中间来
		[m_cancelButton setBackgroundImage:stretchableButtonImageNormal forState:UIControlStateNormal];
		m_cancelButton.frame = CGRectMake(m_cancelButton.frame.origin.x, m_cancelButton.frame.origin.y, 256, m_cancelButton.frame.size.height);
#ifdef JELLYMANIA
        m_cancelButton.frame = CGRectMake(m_cancelButton.frame.origin.x, m_cancelButton.frame.origin.y, 256, 48);
#endif
#endif
	}
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)didDialogClose
{
    if (self.alertDelegate && [self.alertDelegate respondsToSelector:@selector(snsAlertView:clickedButtonAtIndex:)]) {
        [self.alertDelegate snsAlertView:self clickedButtonAtIndex:m_buttonIndex];
    }
	if (self.delegate && [self.delegate respondsToSelector:@selector(winWasClose)]) {
		[self.delegate winWasClose];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) dealloc
{
	self.alertTitle = nil;
	self.alertContent = nil;
	self.alertCancelButton = nil;
    SNSReleaseObj(m_tempTitle);
    SNSReleaseObj(m_tempContent);
    SNSReleaseObj(m_tempCancelButton);
    SNSReleaseObj(m_otherButton);
	// [m_title release];
	// [m_content release];
	// [m_cancelButton release];
	[super dealloc];
}

@end
