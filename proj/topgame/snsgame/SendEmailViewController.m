//
//  RootViewController.m
//  BaseEmail
//
//  Created by wang on 11-8-10.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

//
// RootViewController + iAd
// If you want to support iAd, use this class as the controller of your iAd
//

#import "SendEmailViewController.h"
#import "SystemUtils.h"

@implementation SendEmailViewController

@synthesize useRootView;

- (id) init
{
    self = [super init];
    if(self) {
        useRootView = NO;
    }
    return self;
}

- (void) dealloc
{
    if(pMailView) {
        [pMailView release]; pMailView = nil;
    }
    [super dealloc];
}

#pragma mark -
#pragma mark Compose Mail
// 发邮件的入口
-(void)displayComposerSheet:(id)email withTitle:(NSString *)subject andBody:(NSString *)body andAttachData:(NSData *)attachData withAttachFileName:(NSString *)attachFileName {
	
	//创建mailController句柄
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
	//默认标题
	[picker setSubject:subject];
	
    pMesgBody = [body retain];
	
	//默认接收人
    if(email && [email isKindOfClass:[NSString class]]) {
        NSArray *toRecipients = [NSArray arrayWithObject:email]; 
        [picker setToRecipients:toRecipients];
    }
    if(email && [email isKindOfClass:[NSArray class]]) {
        [picker setToRecipients:email];
    }
	//NSArray *ccRecipients = [NSArray arrayWithObjects:email, nil]; 
	//NSArray *bccRecipients = [NSArray arrayWithObject:email]; 
	
	//[picker setCcRecipients:ccRecipients];	
	//[picker setBccRecipients:bccRecipients];
	/*
	//默认附件
	NSString *path = [[NSBundle mainBundle] pathForResource:@"icon" ofType:@"png"];
	NSData *data = [NSData dataWithContentsOfFile:path];
	[picker addAttachmentData:data mimeType:@"image/png" fileName:@"attachFileName"]; 
	*/
	/*
	//默认内容
	NSString *emailBody = [SystemUtils getLocalizedString:@"eMailContent"];
	[picker setMessageBody:emailBody isHTML:NO];
	*/
    if([body rangeOfString:@"</"].location != NSNotFound 
       && [body rangeOfString:@">"].location != NSNotFound)
        [picker setMessageBody:body isHTML:YES];
    else 
        [picker setMessageBody:body isHTML:NO];
//	UIResponder *nextResponder = [[CCDirector sharedDirector].openGLView nextResponder];
//	if ([nextResponder isKindOfClass:[UIViewController class]]) {
//		[(UIViewController *)nextResponder presentModalViewController:picker animated:YES];
//	}
	CGSize winSize = [UIScreen mainScreen].applicationFrame.size; // [CCDirector sharedDirector].winSize;
	picker.view.backgroundColor = [UIColor grayColor];
	picker.view.frame = CGRectMake(0, 0, winSize.width, winSize.height);
    if(useRootView && [SystemUtils getRootViewController]) {
        if([[SystemUtils getiOSVersion] compare:@"5.0"]>=0)
            [[SystemUtils getRootViewController] presentViewController:picker animated:YES completion:^(void){}];
        else
            [[SystemUtils getRootViewController] presentModalViewController:picker animated:YES];
        isModelMode = YES;
    }
    else {
        UIWindow* window = [UIApplication sharedApplication].keyWindow;
        if (!window) {
            window = [[UIApplication sharedApplication].windows objectAtIndex:0];
        }
        
        // UIResponder *nextResponder = [[CCDirector sharedDirector].openGLView nextResponder];
        UIResponder *nextResponder = [[window.subviews objectAtIndex:0] nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            UIViewController *root = (UIViewController *)nextResponder;
            if([[SystemUtils getiOSVersion] compare:@"5.0"]>=0)
                [root presentViewController:picker animated:YES completion:^(void){}];
            else
                [root presentModalViewController:picker animated:YES];
            isModelMode = YES;
        }
        else {
            [window addSubview:picker.view];
            isModelMode = NO;
        }
    }
	//[[CCDirector sharedDirector].openGLView addSubview:picker.view];
    // pMailView = picker;
    /*
	UIWindow* window = [UIApplication sharedApplication].keyWindow;
	if (!window) {
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	}
     */
    // [window presentModelViewController:picker animated:YES];
    // [window addSubview:self.view];
    // [window addSubview:picker.view];
    [self retain];
	//[picker release];
}

//-(void)displayComposer {
//	NSLog(@"开始发送邮件");
//	[self displayComposerSheet];
//}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{ 
    int status = 0;
    
    if(result == MFMailComposeResultSent) status = 1;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:status], @"result", nil];
	// Notifies users about errors associated with the interface
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationComposeEmailFinish object:nil userInfo:userInfo];
    
	switch (result)
	{
		case MFMailComposeResultCancelled:
			break;
		case MFMailComposeResultSaved:
			break;
		case MFMailComposeResultSent:
			break;
		case MFMailComposeResultFailed:
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[SystemUtils getLocalizedString:@"Send Email Failed"]
															message:[SystemUtils getLocalizedString:@"Please check your email setting."]
														   delegate:nil 
												  cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
												  otherButtonTitles: nil];
			[alert show];
			[alert release];
		}
			break;
		default:
			break;
	}
	//注销controller
	
    //[controller.view removeFromSuperview];
    [controller.view endEditing:TRUE];
    if(isModelMode) {
        [controller dismissModalViewControllerAnimated:YES];
    }
    else {
        [controller.view removeFromSuperview];
    }
    if(pMailView) {
        [pMailView release]; pMailView = nil;
    }
    [pMesgBody release];
    [self release];
}


@end

