//
//  kakaoPoliceViewController.m
//  JellyMania
//
//  Created by lipeng on 14-7-13.
//
//

#import "kakaoPoliceViewController.h"

@interface kakaoPoliceViewController ()

@end

@implementation kakaoPoliceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImage * titleImg = [UIImage imageNamed:@"pageheader_more.jpg"];
    CGSize size = titleImg.size;
    CGSize winsize = [[UIScreen mainScreen] bounds].size;
    
    UIImageView * titleView = [[UIImageView alloc] initWithImage:titleImg];
    titleView.frame = CGRectMake(0, 0, winsize.width, size.height/size.width*winsize.width);
    [self.view addSubview:titleView];
    [titleView release];
    
    m_webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, titleView.frame.size.height, winsize.width, winsize.height - titleView.frame.size.height)];
     m_webView.scalesPageToFit = YES;
    [self.view addSubview:m_webView];
    [m_webView release];
    
    UIButton * close = [[UIButton alloc] initWithFrame:titleView.frame];
    [close addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:close];
    [close release];

	// Do any additional setup after loading the view.
}
- (void)closeAction
{
    [self dismissModalViewControllerAnimated:false];
}

- (void)showWithURL:(NSString *)url
{
    NSURLRequest *request =[NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [m_webView loadRequest:request];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
