//
//  SNSWebWindow.m
//  TapCar
//
//  Created by Jie Yang on 12/13/11.
//  Copyright (c) 2011 topgame.com. All rights reserved.
//

#import "SNSWebWindow.h"

@implementation SNSWebWindow
@synthesize titleContent;
@synthesize closeButton;
@synthesize webView;

- (id) initWithUrl:(NSString *)url title:(NSString *)title closeButtonTitle:(NSString *)closeButtonTitle
{
	self = [super initWithNibName:@"SNSWebWindow" bundle:nil];
	if (self) {
		m_closeButtonTitle = [closeButtonTitle retain];
		m_title = [title retain];
		m_webViewUrl = [url retain];
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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	closeButton.title = m_closeButtonTitle;
	((UINavigationItem *)titleContent).title = m_title;
	NSURL *url = [NSURL URLWithString:m_webViewUrl];
	[webView loadRequest:[NSURLRequest requestWithURL:url 
										  cachePolicy:NSURLRequestUseProtocolCachePolicy
									  timeoutInterval:5.0f
						  ]];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [m_title release]; [m_webViewUrl release]; [m_closeButtonTitle release];
	self.titleContent = nil;
	self.closeButton = nil;
	self.webView = nil;
}

- (void)didDialogClose
{
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
    /*
	[titleContent release];
	[closeButton release];
	[webView release];
     */
	[super dealloc];
}

#pragma mark - orientation function

- (void)sizeToFitOrientation:(BOOL)transform {
	//NSLog(@"%s - run orientation", __FUNCTION__);
	SNSCrashLog("start");
    if (transform) {
        self.view.transform = CGAffineTransformIdentity;
    }
    
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    CGPoint center = CGPointMake(frame.size.width * 0.5f, frame.size.height * 0.5f);
	CGFloat width = frame.size.width;
	CGFloat height = frame.size.height;
    
    self.privateOrientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
	
    if (UIInterfaceOrientationIsLandscape(self.privateOrientation)) {
        //横着的时候
		self.view.frame = CGRectMake(0, 0, height, width);
    } else {
        //竖着的时候
		self.view.frame = CGRectMake(0, 0, width, height);
    }
    self.view.center = center;
    
    if (transform) {
        self.view.transform = [self transformForOrientation];
    }
	SNSCrashLog("end");
}

@end
