//
//  RootViewController.h
//  BaseEmail
//
//  Created by wang on 11-8-10.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>


@interface SendEmailViewController : NSObject <MFMailComposeViewControllerDelegate> {
    id pMailView;
    BOOL isModelMode;
    BOOL useRootView;
    NSString *pMesgBody;
}

@property (assign,nonatomic) BOOL useRootView;

-(void)displayComposerSheet:(id)email withTitle:(NSString *)title andBody:(NSString *)body andAttachData:(NSData *)attachData withAttachFileName:(NSString *)attachFileName;

@end

