//
//  FacebookFeedViewController.m
//  DragonSoul
//
//  Created by LEON on 12-10-30.
//
//

#import <FacebookSDK/FacebookSDK.h>
#import "FacebookFeedViewController.h"
#import "SystemUtils.h"
#import "FacebookHelper.h"
#import "SmInGameLoadingView.h"

@interface FacebookFeedViewController ()<UITextViewDelegate,UIAlertViewDelegate>

@property(retain,nonatomic) IBOutlet UITextView *postMessageTextView;
@property(retain,nonatomic) IBOutlet UIImageView *postImageView;
@property(retain,nonatomic) IBOutlet UILabel *postNameLabel;
@property(retain,nonatomic) IBOutlet UILabel *postCaptionLabel;
@property(retain,nonatomic) IBOutlet UILabel *postDescriptionLabel;

@property (retain, nonatomic) NSMutableDictionary *postParams;

@property (retain, nonatomic) NSMutableData *imageData;
@property (retain, nonatomic) NSURLConnection *imageConnection;

- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)shareButtonAction:(id)sender;
- (void)publishStory;

- (void) showLoadingView;
- (void) hideLoadingView;

@end

NSString *const kPlaceholderPostMessage = @"Say something about this...";

@implementation FacebookFeedViewController

@synthesize postMessageTextView,postImageView,postNameLabel,postCaptionLabel,postDescriptionLabel;
@synthesize postParams = _postParams;
@synthesize imageConnection = _imageConnection;
@synthesize imageData = _imageData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        NSString *remoteURLRoot = [NSString stringWithFormat:@"http://%@/item_files/general", [SystemUtils getDownloadServerName]];

        _postParams =
        [[NSMutableDictionary alloc] initWithObjectsAndKeys:
         [SystemUtils getSystemInfo:@"kFacebookFeedLink"], @"link",
         [remoteURLRoot stringByAppendingPathComponent:@"icon-175x175.png"], @"picture",
         [SystemUtils getLocalizedString:@"GameName"], @"name",
         [SystemUtils getSystemInfo:@"kFacebookFeedCaption"], @"caption",
         [SystemUtils getSystemInfo:@"kFacebookFeedDescription"], @"description",
         nil];
        
    }
    return self;
}

-(void)dealloc
{
    self.postMessageTextView = nil;
    self.postImageView = nil;
    self.postNameLabel = nil;
    self.postCaptionLabel = nil;
    self.postDescriptionLabel = nil;
    
    self.postParams = nil;
    self.imageData = nil;
    self.imageConnection = nil;
    
    if(m_loadingView) [m_loadingView release];
    
    [super dealloc];
}

- (void)resetPostMessage
{
    self.postMessageTextView.text = kPlaceholderPostMessage;
    self.postMessageTextView.textColor = [UIColor lightGrayColor];
}

- (void) setParameters:(NSDictionary *)pams
{
    [_postParams addEntriesFromDictionary:pams];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // Show placeholder text
    [self resetPostMessage];
    self.postMessageTextView.delegate = self;
    
    // Set up the post information, hard-coded for this sample
    self.postNameLabel.text = [self.postParams objectForKey:@"name"];
    self.postCaptionLabel.text = [self.postParams
                                  objectForKey:@"caption"];
    [self.postCaptionLabel sizeToFit];
    self.postDescriptionLabel.text = [self.postParams
                                      objectForKey:@"description"];
    [self.postDescriptionLabel sizeToFit];
    
    NSString *imageFile = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Icon@2x.png"];
    self.postImageView.image = [UIImage imageWithContentsOfFile:imageFile];
    /*
    // Kick off loading of image data asynchronously so as not
    // to block the UI.
    _imageData = [[NSMutableData alloc] init];
    NSURLRequest *imageRequest = [NSURLRequest
                                  requestWithURL:
                                  [NSURL URLWithString:
                                   [self.postParams objectForKey:@"picture"]]];
    _imageConnection = [[NSURLConnection alloc] initWithRequest:
                            imageRequest delegate:self];
     */
    [self sizeToFitOrientation:YES];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // Clear the message text when the user starts editing
    if ([textView.text isEqualToString:kPlaceholderPostMessage]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    // Reset to placeholder text if the user is done
    // editing and no message has been entered.
    if ([textView.text isEqualToString:@""]) {
        [self resetPostMessage];
    }
}

/*
 * A simple way to dismiss the message text view:
 * whenever the user clicks outside the view.
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *) event
{
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.postMessageTextView isFirstResponder] &&
        (self.postMessageTextView != touch.view))
    {
        [self.postMessageTextView resignFirstResponder];
    }
}


- (void)connection:(NSURLConnection*)connection
    didReceiveData:(NSData*)data{
    [self.imageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    // Load the image
    self.postImageView.image = [UIImage imageWithData:
                                [NSData dataWithData:self.imageData]];
    self.imageConnection = nil;
    self.imageData = nil;
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error{
    self.imageConnection = nil;
    self.imageData = nil;
}

- (IBAction)cancelButtonAction:(id)sender {
    [self hideLoadingView];
    if([[SystemUtils getiOSVersion] compare:@"5.0"]>=0) {
        [[self presentingViewController]
            dismissModalViewControllerAnimated:NO];
    }
    else {
        [[self parentViewController]
         dismissModalViewControllerAnimated:NO];
    }
}

- (void)publishStory
{
    [FBRequestConnection
     startWithGraphPath:@"me/feed"
     parameters:self.postParams
     HTTPMethod:@"POST"
     completionHandler:^(FBRequestConnection *connection,
                         id result,
                         NSError *error) {
         NSString *alertText;
         if (error) {
             alertText = [NSString stringWithFormat:
                          @"error: domain = %@, code = %d",
                          error.domain, error.code];
             // Show the result in an alert
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Result"
                                                             message:alertText
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK!"
                                                   otherButtonTitles:nil];
             [alert show];
             [alert release];
         } else {
             // send prize
             [[FacebookHelper helper] showFacebookFeedPrize];
         }
         [self cancelButtonAction:nil];
     }];
}

- (IBAction)shareButtonAction:(id)sender {
    
    [self showLoadingView];
    
    // Hide keyboard if showing when button clicked
    if ([self.postMessageTextView isFirstResponder]) {
        [self.postMessageTextView resignFirstResponder];
    }
    // Add user message parameter if user filled it in
    if (![self.postMessageTextView.text
          isEqualToString:kPlaceholderPostMessage] &&
        ![self.postMessageTextView.text isEqualToString:@""]) {
        [self.postParams setObject:self.postMessageTextView.text
                            forKey:@"message"];
    }
    
    // Ask for publish_actions permissions in context
    if ([FBSession.activeSession.permissions
         indexOfObject:@"publish_actions"] == NSNotFound) {
        // No permissions found in session, ask for it
        [FBSession.activeSession
         reauthorizeWithPublishPermissions:
         [NSArray arrayWithObject:@"publish_actions"]
         defaultAudience:FBSessionDefaultAudienceFriends
         completionHandler:^(FBSession *session, NSError *error) {
             if (!error) {
                 // If permissions granted, publish the story
                 [self publishStory];
             }
             else {
                 // show alert
                 [self cancelButtonAction:nil];
             }
         }];
    } else {
        // If permissions present, publish the story
        [self publishStory];
    }
}

- (void) alertView:(UIAlertView *)alertView
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if([[SystemUtils getiOSVersion] compare:@"5.0"]>=0) {
    [[self presentingViewController]
     dismissModalViewControllerAnimated:YES];
    }
    else {
        [[self parentViewController]
         dismissModalViewControllerAnimated:YES];
    }
}


- (void)sizeToFitOrientation:(BOOL)transform {
    // CGRect r1 = self.view.frame;
    CGRect r2 = self.postCaptionLabel.frame;
    CGRect r3 = self.postDescriptionLabel.frame;
    
    r2.size.width = 320-r2.origin.x-9;
    r3.size.width = 320-r3.origin.x-9;
    self.postCaptionLabel.frame = r2;
    self.postDescriptionLabel.frame = r3;
    
	/*
    if (transform) {
		self.view.transform = CGAffineTransformIdentity;
	}
	
	self.privateOrientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
    CGRect frame =[UIScreen mainScreen].applicationFrame;
	CGPoint center = CGPointMake(
								 frame.origin.x + ceil(frame.size.width/2),
								 frame.origin.y + ceil(frame.size.height/2));
    
	self.view.center = center;
	
	if (transform) {
		self.view.transform = [self transformForOrientation];
	}
     */
}


- (void) showLoadingView
{
	m_loadingView = [[SmInGameLoadingView alloc] init];
    [self.view addSubview:m_loadingView];
    [m_loadingView setSize:self.view.frame.size];
}

- (void) hideLoadingView
{
    if(m_loadingView) {
        [(UIView *)m_loadingView removeFromSuperview];
        [m_loadingView release];
        m_loadingView = nil;
    }
}

@end
