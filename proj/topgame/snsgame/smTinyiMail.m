//
//  smTinyiMail.m
//  DreamTrain
//
//  Created by Jie Yang on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "smTinyiMail.h"
#import "SystemUtils.h"
#import "SNSAlertView.h"
// #import "SocialModuleUtils.h"
#import "SnsServerHelper.h"
#import "TinyiMailHelper.h"
#import "StringUtils.h"
#import "ASIFormDataRequest.h"
#import "SBJson.h"

@implementation smTinyiMail
@synthesize title;
@synthesize brainText;
@synthesize descriptionText;
@synthesize congratulateText;
@synthesize email,friendCode;
@synthesize sendOrBackButton;
@synthesize verificationButton,verifyFriendCodeButton,skipFriendCodeButton;
@synthesize step = m_step;

- (id)initWithStep:(int)step {
	UIDeviceOrientation orientation = [SystemUtils getGameOrientation];
	NSString *nibName = nil;
	if ([SystemUtils isiPad]) {
		if (orientation == UIDeviceOrientationPortrait) {
			nibName = @"smTinyiMail_pad_portrait";
		} else {
			nibName = @"smTinyiMail_pad";
		}
	} else {
		if (orientation == UIDeviceOrientationPortrait) {
			nibName = @"smTinyiMail_portrait";
		} else {
			nibName = @"smTinyiMail";
		}
	}
	self = [super initWithNibName:nibName bundle:nil];
	if (self) {
		m_step = step; 
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        m_verifyRequest = nil;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	//设置界面参数
	int awardNum = [TinyiMailHelper helper].iVerifyPrizeLeaf;
    NSString *coinName = [SystemUtils getLocalizedString:@"CoinName2"];
    NSString *awardInfo = [StringUtils getTextOfNum:awardNum Word:coinName];
    
	NSString *temail = [[TinyiMailHelper helper] getTinyiMailObject:@"email"];
    self.email.placeholder = [SystemUtils getLocalizedString:@"Please enter your email"];
    if(temail && [temail length]>5) {
        self.email.text = temail;
    }

    NSString *fcode = [SystemUtils getNSDefaultObject:@"kFriendCode"];
    if(fcode) friendCode.text = fcode;
    friendCode.placeholder = [SystemUtils getLocalizedString:@"The invitation code from your friend"];
    [verifyFriendCodeButton setTitle:[SystemUtils getLocalizedString:@"Verify"] forState:UIControlStateNormal];
    [skipFriendCodeButton setTitle:[SystemUtils getLocalizedString:@"No Code"] forState:UIControlStateNormal];
       
    if(m_step<=3) {
        self.title.text = [SystemUtils getLocalizedString:@"Mailing List Subscription"];
        
        [self.verificationButton setTitle:[SystemUtils getLocalizedString:@"Send Verification Email"] forState:UIControlStateNormal];
        self.brainText.text = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Bonus: %@"], awardInfo];
        self.congratulateText.text = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Great! You've got %@ for subscribing to the mail list."], awardInfo];
    }
    if(m_step==4 || m_step==5) {
        self.title.text = [SystemUtils getLocalizedString:@"Invite Friends"];
        
        [self.verificationButton setTitle:[SystemUtils getLocalizedString:@"Send Invitation Email"] forState:UIControlStateNormal];
        self.brainText.text = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Bonus: %@"], awardInfo];
        // self.congratulateText.text = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Great! You've got %@ for subscribing to the mail list."], awardInfo];
        
    }
	//跳转到相应步骤
	[self toStep];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	self.title = nil;
	self.brainText = nil;
	self.descriptionText = nil;
	self.congratulateText = nil;
	self.email = nil;
	self.sendOrBackButton = nil;
	self.verificationButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc
{
    if(m_verifyRequest) [m_verifyRequest release];
    self.friendCode = nil; self.verificationButton = nil; self.skipFriendCodeButton = nil;
	self.title = nil;
	self.brainText = nil;
	self.descriptionText = nil;
	self.congratulateText = nil;
	self.email = nil;
	self.sendOrBackButton = nil;
	self.verificationButton = nil;
	[super dealloc];
}

- (void) didDialogClose {
    [[TinyiMailHelper helper] closeiMailPopupBox];
    [SystemUtils setNSDefaultObject:friendCode.text forKey:@"kFriendCode"];
	[super didDialogClose];
	if (self.delegate && [self.delegate respondsToSelector:@selector(winWasClose)]) {
		[delegate winWasClose];
	}
}

#pragma mark - overwrite father function

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

- (IBAction)closeKeyBoard
{
	[self.email resignFirstResponder];
	if ([SystemUtils getGameOrientation] == UIDeviceOrientationPortrait) return;
	CGPoint moveToPosition = [SystemUtils isiPad]?CGPointMake(174, 353):CGPointMake(90, 144);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3f];
	[UIView setAnimationDelegate:self];
	self.email.frame = CGRectMake(moveToPosition.x, moveToPosition.y, self.email.frame.size.width, self.email.frame.size.height);
    friendCode.frame = CGRectMake(moveToPosition.x, moveToPosition.y, self.email.frame.size.width, self.email.frame.size.height);

	[UIView commitAnimations];
}

#pragma mark - IBAction function

- (IBAction)moveInputBox {
	if ([SystemUtils getGameOrientation] == UIDeviceOrientationPortrait) return;
	CGPoint moveToPosition = [SystemUtils isiPad]?CGPointMake(174, 288):CGPointMake(96, 64);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3f];
	[UIView setAnimationDelegate:self];
	self.email.frame = CGRectMake(moveToPosition.x, moveToPosition.y, self.email.frame.size.width, self.email.frame.size.height);
    friendCode.frame = CGRectMake(moveToPosition.x, moveToPosition.y, self.email.frame.size.width, self.email.frame.size.height);
	[UIView commitAnimations];
}

- (IBAction)sendOrBackButtonClick:(id)sender
{
	if (m_step == 1) {
		//关闭键盘并将email筐移动到原始位置
		[self closeKeyBoard];
		//验证email正确性
		if ([email.text isEqualToString:@""] || ![[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"] evaluateWithObject:email.text]) {
			SNSAlertView *alert = [[SNSAlertView alloc] initWithTitle:[SystemUtils getLocalizedString:@"Invalid Email"]
															  message:[SystemUtils getLocalizedString:@"Email is empty or improperly formatted email!"] 
															 delegate:nil 
													cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"] 
													 otherButtonTitle:nil];
			[alert showHard];
			[alert release];
		} else {
            // save email
            [[TinyiMailHelper helper] setTinyiMailObject:email.text forKey:@"email"];
            [self nextStep];
            [[TinyiMailHelper helper] reloadServerStatus];
		}
	} else if (m_step == 2 || m_step==5) {
		//返回第一步并做一些清理操作（可能需要）
		
		//后退一步
		[self previousStep];
	}
}

- (void)toNextStep
{
	//临时函数，请删除
	[[SnsServerHelper helper] onHideInGameLoadingView:nil];
	//前进一步
	[self nextStep];
}

- (IBAction)verificationButtonClick:(id)sender
{
    if(m_step==2) {
        // 弹出发送邮件窗口
        /*
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(onComposeEmailFinished:) 
                                                     name:kNotificationComposeEmailFinish
                                                   object:nil];
         */
        [[TinyiMailHelper helper] writeVerifyEmail];
        [self closeDialog];
    }
    if(m_step==5) {
        [[TinyiMailHelper helper] writeInvitationEmail];
        [self closeDialog];
    }
}

#pragma mark - step function

- (void)toStep
{
	self.email.hidden = YES;
	self.sendOrBackButton.hidden = YES;
	self.verificationButton.hidden = YES;
	self.congratulateText.hidden = YES;
    friendCode.hidden = YES;
	int awardNum = [TinyiMailHelper helper].iVerifyPrizeLeaf;
    NSString *coinName = [SystemUtils getLocalizedString:@"CoinName2"];
    NSString *awardInfo = [StringUtils getTextOfNum:awardNum Word:coinName];
	verifyFriendCodeButton.hidden = YES; skipFriendCodeButton.hidden = YES;
	switch (m_step) {
		case 1:
			self.email.hidden = NO;
			self.sendOrBackButton.hidden = NO;
			self.descriptionText.text = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Subscribe to the %@ mailing list for all the latest updates, news, bonuses and gifts!"], [SystemUtils getLocalizedString:@"GameName"]];
            [self.sendOrBackButton setTitle:[SystemUtils getLocalizedString:@"Subscribe"] forState:UIControlStateNormal];
			break;
		case 2: 
        {
            BOOL isSent = ([[SystemUtils getNSDefaultObject:@"kSendVerifyEmailTime"] intValue] > [SystemUtils getCurrentTime]);
            if(isSent) {
                self.verificationButton.hidden = YES;
                self.sendOrBackButton.hidden = YES;
                self.congratulateText.hidden = NO;
                self.congratulateText.text = [SystemUtils getLocalizedString:@"Verification email is sent. Waiting for response."];
            }
            else {
                self.verificationButton.hidden = NO;
                self.sendOrBackButton.hidden = NO;
                self.congratulateText.hidden = YES;
                // self.congratulateText.text = [SystemUtils getLocalizedString:@"Verification email is sent. Waiting for response."];
            }
            self.descriptionText.text = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Note: depending on the network condition, sometimes it needs a day to receive your verification email, please be patient. Once we get your email, you'll get %@ as bonus!"], awardInfo];
            [self.sendOrBackButton setTitle:[SystemUtils getLocalizedString:@"Modify"] forState:UIControlStateNormal];
        }
			break;
		case 3:
			self.verificationButton.hidden = YES;
			self.sendOrBackButton.hidden = YES;
			self.congratulateText.hidden = NO;
            self.congratulateText.text = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Great! You've got %@ for subscribing to the mail list."], awardInfo];
			self.descriptionText.text = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Thanks for subscribing to %@ mail list, we'll send you the updates, news, bonus, festival gifts at the very fist time!"], [SystemUtils getLocalizedString:@"GameName"]];
			break;
		case 4:
			self.sendOrBackButton.hidden = YES;
            self.friendCode.hidden = NO;
            verifyFriendCodeButton.hidden = NO; skipFriendCodeButton.hidden = NO; 
            self.title.text = [SystemUtils getLocalizedString:@"Invitation Code"];
			self.descriptionText.text = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Type in the invitation code you received from your friend. You'll get %@ as bonus after verification."], awardInfo];
			break;
		case 5: 
        {
			self.verificationButton.hidden = NO;
            self.title.text = [SystemUtils getLocalizedString:@"Invite Friends"];
			self.descriptionText.text = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Invite friends to join %@, you'll earn %@ for each successful invitation."], [SystemUtils getLocalizedString:@"GameName"], awardInfo];
            [self.verificationButton setTitle:[SystemUtils getLocalizedString:@"Send Invitation Email"] forState:UIControlStateNormal];
            if([[TinyiMailHelper helper] hasFriendCode]) {
                sendOrBackButton.hidden = YES;
            }
            else {
                sendOrBackButton.hidden = NO;
                [self.sendOrBackButton setTitle:[SystemUtils getLocalizedString:@"I'm Invited"] forState:UIControlStateNormal];
            }
        }
			break;
		default:
			self.email.hidden = NO;
			self.sendOrBackButton.hidden = NO;
			break;
	}
}

- (void)nextStep
{
	if (m_step < 3 || m_step==4) {
		m_step++;
		[self toStep];
	}
}

- (void)previousStep
{
	if (m_step==2 || m_step==3 || m_step==5) {
		m_step--;
		[self toStep];
	}
}

//点击验证邀请码按钮之后的回调函数
- (IBAction)verifyFriendCodeButtonClick:(id)sender
{
    NSString *fcode = friendCode.text;
    // 后台验证此邀请码
    [SystemUtils showInGameLoadingView];

    NSString *userID = [[TinyiMailHelper helper] getTinyiMailObject:@"uid"];
    NSString *appID = [SystemUtils getSystemInfo:@"kTinyiMailAppID"];
	NSString *country = [SystemUtils getCountryCode];
    // 签名验证方式：sig=md5(appID+"dfwe234gdgit8"+time)
	int timestamp = [SystemUtils getCurrentDeviceTime];
	NSString *time = [NSString stringWithFormat:@"%i",timestamp];
	NSString *secret = [NSString stringWithFormat:@"%@%@%@", userID, kTinyiMailSecretKey, time];
	// sig＝md5(UDID+"-"+time+"-"+userID+"-"+clientVer+"-"+key)
	NSString *sig = [StringUtils stringByHashingStringWithMD5:secret];
	NSString *isTestUser = @"0";
#ifdef DEBUG
	isTestUser = @"1";
#endif
    
	// loading system status
	NSString *api = [NSString stringWithFormat:@"http://%@/api/verifyInviteCode.php", [SystemUtils getSystemInfo:@"kTinyiMailHost"]];
	SNSLog(@"%s api:%@", __FUNCTION__, api);
	NSURL *url = [NSURL URLWithString:api];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	
	[request setRequestMethod:@"POST"];
	[request addPostValue:appID forKey:@"appID"];
	[request addPostValue:fcode forKey:@"code"];
	[request addPostValue:userID forKey:@"userID"];
	[request addPostValue:sig  forKey:@"sig"];
	[request addPostValue:country forKey:@"country"];
	[request addPostValue:@"0" forKey:@"osType"];
	[request addPostValue:time forKey:@"time"];
	[request addPostValue:isTestUser forKey:@"isTestUser"];
	[request buildPostBody];
	
	[request setDelegate:self];
	[request setTimeOutSeconds:5.0f];
	[request startAsynchronous];
	SNSLog(@"method: %@ post data: %s",[request requestMethod], [request postBody].bytes);
	m_verifyRequest = [request retain];
    
}

// type:1-success, -1-invalid code, -2-network error, try again, -3-you've already set friendCode
- (void) verifyFriendCodeResult:(int)type
{
    [SystemUtils hideInGameLoadingView];
    [m_verifyRequest release]; m_verifyRequest = nil;
    if(type == 1) {
        // success, give prize
        int awardNum = [TinyiMailHelper helper].iVerifyPrizeLeaf;
        NSString *coinName = [SystemUtils getLocalizedString:@"CoinName2"];
        NSString *awardInfo = [StringUtils getTextOfNum:awardNum Word:coinName];
        
        [SystemUtils addGameResource:awardNum ofType:kGameResourceTypeLeaf];
        
        NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Great! The invitation code is valid, you just got %@ as bonus!"], awardInfo];
        SNSAlertView *av = [[SNSAlertView alloc] 
                            initWithTitle:[SystemUtils getLocalizedString: @"Verification Success"]
                            message:mesg
                            delegate:nil
                            cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                            otherButtonTitle: nil];
        
        av.tag = kTagAlertNone;
        // [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
        [av showHard];
        [av release];
        [self nextStep];
    }
    if(type == -1 || type==-2) {
        // -1: invalid code
        // -2: network error, try again
        NSString *mesg = nil;
        if(type==-1) mesg = [SystemUtils getLocalizedString: @"This invitation code is invalid, please check."];
        if(type==-2) mesg = [SystemUtils getLocalizedString: @"The verification service is not available temporarily because of bad network status. Please try again later."];
        SNSAlertView *av = [[SNSAlertView alloc] 
                            initWithTitle:[SystemUtils getLocalizedString: @"Verification Failed"]
                            message:mesg
                            delegate:nil
                            cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                            otherButtonTitle: nil];
        
        av.tag = kTagAlertNone;
        // [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
        [av showHard];
        [av release];
    }
    if(type == -3) {
        // you've already set friendCode, can't get prize again
        [self nextStep];
    }
}

//点击忽略邀请码按钮之后的回调函数
- (IBAction)skipFriendCodeButtonClick:(id)sender
{
    [SystemUtils setNSDefaultObject:@"1" forKey:@"kInviteCodeSkip"];
    [self nextStep];
}

// 完成发送邮件
-(void) onComposeEmailFinished:(NSNotification *)note
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationComposeEmailFinish object:nil];
    int res = 0;
    if(note.userInfo) res = [[note.userInfo objectForKey:@"result"] intValue];
    if(res == 1)
    {
        // 显示验证提示
        // [[TinyiMailHelper helper] showSentHint];
        [self showSentHint];
    }
}

-(void) showSentHint
{
	[[TinyiMailHelper helper] performSelector:@selector(startCheckStatus:) withObject:nil afterDelay:300.0f];
	SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:[SystemUtils getLocalizedString: @"Email Sent OK"]
                        message:[SystemUtils getLocalizedString: @"You've sent out the verification email. Once our mail system verifies your message, you'll get the bonus automatically. This may needs one day, please be patient!"]
                        delegate:self
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertNone;
    // [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
    [av showHard];
    [av release];
}

#pragma mark - SNSAlertView delegate

- (void) snsAlertView:(SNSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	//点击确认之后关闭自己
	[self closeDialog];
}

#pragma mark -


#pragma mark ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
	SNSLog(@"%s status code:%i",__FUNCTION__, request.responseStatusCode);
	// response
	int status = request.responseStatusCode;
	if(status>=400) {
		[self verifyFriendCodeResult:-2];
		return;
	}
	// NSString *response = [request responseString];
	NSData *jsonData = [request responseData];
	if(!jsonData || [jsonData length]==0) {
		SNSLog(@"Empty response");
		[self verifyFriendCodeResult:-2];
		return;
	}
	// [request responseData];
	// NSString *jsonString = @"yourJSONHere";
	// NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	NSError *error = nil;
	NSString *jsonString = [[NSString alloc] initWithBytes:jsonData.bytes length:jsonData.length encoding:NSUTF8StringEncoding];
	[jsonString autorelease];
	NSDictionary *dictionary = [jsonString JSONValue]; 
	if(!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
		SNSLog(@"deserialize error:%@\ncontent:%s", error, jsonData.bytes);
		[self verifyFriendCodeResult:-2];
		return;
	}
    // check uid
    if(![dictionary objectForKey:@"userID"]) {
		SNSLog(@"invalid response: %@", jsonString);
		[self verifyFriendCodeResult:-2];
		return;
    }
    NSString *userID = [NSString stringWithFormat:@"%@", [dictionary objectForKey:@"userID"]];
    if([userID isEqualToString:@"0"] || [userID length]==0) 
    {
		SNSLog(@"invalid response: %@", jsonString);
		[self verifyFriendCodeResult:-2];
		return;
    }
    SNSLog(@"resp:%@",dictionary);
    
    int result = [[dictionary objectForKey:@"result"] intValue];
    if(result == -3 || result==1) {
        [[TinyiMailHelper helper] setTinyiMailObject:[dictionary objectForKey:@"friendCode"] forKey:@"friendCode"];
    }
    [self verifyFriendCodeResult:result];
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	SNSLog(@"%s - error: %@", __FUNCTION__, error);
	[self verifyFriendCodeResult:-2];
}

#pragma mark -



@end