//
//  smTinyiMail.h
//  DreamTrain
//
//  Created by Jie Yang on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "smPopupWindowBase.h"
#import "SNSAlertView.h"
#import "ASIHTTPRequestDelegate.h"

/*
 note:
 //显示的时候这样调用
 // step:1为未输入email状态 2为输入email等待验证 3为点击了验证之后的提示, 4-输入邀请码界面，5－邀请好友界面
 smTinyiMail *imail = [[smTinyiMail alloc] initWithStep:1];
 [imail showHard];
 [imail release];
 */

@interface smTinyiMail : smPopupWindowBase <SNSAlertViewDelegate,ASIHTTPRequestDelegate> {

@private
	int						m_step;
    id    m_verifyRequest;
}

@property (nonatomic, retain) IBOutlet UILabel *title;
@property (nonatomic, retain) IBOutlet UILabel *brainText;
@property (nonatomic, retain) IBOutlet UILabel *descriptionText;
@property (nonatomic, retain) IBOutlet UILabel *congratulateText;
@property (nonatomic, retain) IBOutlet UITextField *email;
@property (nonatomic, retain) IBOutlet UITextField *friendCode;
@property (nonatomic, retain) IBOutlet UIButton *sendOrBackButton;
@property (nonatomic, retain) IBOutlet UIButton *verificationButton;
@property (nonatomic, retain) IBOutlet UIButton *verifyFriendCodeButton;
@property (nonatomic, retain) IBOutlet UIButton *skipFriendCodeButton;
@property (nonatomic, readonly) int step;


- (id)initWithStep:(int)step;
//移动email筐体到合适的位置
- (IBAction)moveInputBox;
//点击订阅或返回修改按钮之后的回调函数
- (IBAction)sendOrBackButtonClick:(id)sender;
//点击验证邮箱按钮之后的回调函数
- (IBAction)verificationButtonClick:(id)sender;
//移驾到m_step
- (void)toStep;
//向上一步
- (void)previousStep;
//向下一步
- (void)nextStep;

// 完成发送邮件
-(void) onComposeEmailFinished:(NSNotification *)note;
// 显示发送完邮件的提示
-(void) showSentHint;

//点击验证邀请码按钮之后的回调函数
- (IBAction)verifyFriendCodeButtonClick:(id)sender;
//点击忽略邀请码按钮之后的回调函数
- (IBAction)skipFriendCodeButtonClick:(id)sender;

@end
