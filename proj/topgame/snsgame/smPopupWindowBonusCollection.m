//
//  BounsCollection.m
//  DreamTrain
//
//  Created by Jie Yang on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "smPopupWindowBonusCollection.h"

#ifndef MODE_COCOS2D_X
#import "SimpleAudioEngine.h"
#endif
#ifndef SNS_DISABLE_FLURRY_V1
#import "FlurryHelper.h"
#endif
#ifndef SNS_DISABLE_ADCOLONY
#import "AdColonyHelper.h"
#endif
#ifndef SNS_DISABLE_TAPJOY
#import "TapjoyHelper.h"
#endif
// #import "FAADNetworkHelper.h"
#import "PlayHavenSDK.h"
#import "PlayHavenHelper.h"
#import "TinyiMailHelper.h"
#import "smPopupWindowAction.h"
#ifndef SNS_DISABLE_GREYSTRIPE
#import "GreystripeHelper.h"
#endif
#ifdef SNS_ENABLE_LIMEI
#import "LiMeiHelper.h"
#endif
#ifdef SNS_ENABLE_TINYMOBI
#import "TinyMobiHelper.h"
#endif
#ifndef SNS_DISABLE_CHARTBOOST
#import "ChartBoostHelper.h"
#endif
#ifdef SNS_ENABLE_APPDRIVER
#import "AppDriverHelper.h"
#endif
#ifdef SNS_ENABLE_FLURRY_V2
#import "FlurryHelper2.h"
#endif

@implementation smPopupWindowBonusCollection
@synthesize setting;
@synthesize collectionTitle, playHavenIcon, moreButton, tinyiMailButton;
@synthesize bounsValue1, bounsValue2, bounsValue3, bounsValue4, bounsValue5, bounsValue6, bounsValue7, awardPopText;
@synthesize leftView, rightView, awardPop;
@synthesize giftBoxFaad, giftBoxAllOffer,videoImg,videoBellImg,videoCoinImg;

- (id) initBouns {
	UIDeviceOrientation orientation = [SystemUtils getGameOrientation];
	NSString *nibName = nil;
	if (orientation == UIDeviceOrientationPortrait) {
		nibName = @"smPopupWindowBonusCollection_portrait";
	} else {
		nibName = @"smPopupWindowBonusCollection";
	}
	self = [super initWithNibName:nibName bundle:nil];
    if (self) {
        // Custom initialization
		// m_audioEngine = [SimpleAudioEngine sharedEngine];
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
	self.collectionTitle.text = SNSLocal(@"UI_COLLECTION_TITLE", @"标题文字");
	self.bounsValue1.text = SNSLocal(@"UI_COLLECTION_BUTTON_TITLE_CASH1", @"Free");
	self.bounsValue2.text = SNSLocal(@"UI_COLLECTION_BUTTON_TITLE_CASH2", @"x10");
	self.bounsValue3.text = SNSLocal(@"UI_COLLECTION_BUTTON_TITLE_COIN1", @"Free");
	
    // self.bounsValue4.text = [NSString stringWithFormat:@"x%i", [FlurryHelper helper].videoPrizeGold];
    self.bounsValue4.text = [NSString stringWithFormat:@"x%i", [TinyiMailHelper helper].iVerifyPrizeLeaf];
    
#ifndef SNS_DISABLE_ADCOLONY
    self.bounsValue5.text = [NSString stringWithFormat:@"x%i", [AdColonyHelper helper].prizeGold];
#endif
	self.bounsValue6.text = SNSLocal(@"UI_COLLECTION_BUTTON_TITLE_GIFTBOX1", @"X100");
	self.bounsValue7.text = SNSLocal(@"UI_COLLECTION_BUTTON_TITLE_GIFTBOX2", @"X100");
    
    m_showPlayHaven = NO; m_playHavenBadgeView = nil;
    m_phToken  = [[SystemUtils getSystemInfo:kPlayHavenToken] retain];
    m_phSecret = [[SystemUtils getSystemInfo:kPlayHavenSecret] retain];
    if(m_phToken && m_phSecret && [m_phToken length]>10 && [m_phSecret length]>10)
        m_showPlayHaven = YES;
    if(m_showPlayHaven) {
        playHavenIcon.hidden = NO;
        PHNotificationView *notificationView = [[PHNotificationView alloc] initWithApp:m_phToken secret:m_phSecret placement:@"more_games"];
        [self.view addSubview:notificationView];
        [notificationView refresh];
        CGRect iconFrame = playHavenIcon.frame;
        notificationView.center = CGPointMake(iconFrame.origin.x+iconFrame.size.width, iconFrame.origin.y);
        m_playHavenBadgeView = notificationView;
    }
    else 
        playHavenIcon.hidden = YES;
    // [[FAADNetworkHelper helper] initSession];
    
//    if([TapjoyHelper helper].isWebModeEnabled)
//        moreButton.hidden = NO;
//    else {
        moreButton.hidden = YES;
		leftView.frame = CGRectMake(leftView.frame.origin.x, 87, leftView.frame.size.width, leftView.frame.size.height);
//	}
    
    tinyiMailButton.hidden = NO;
    /*
    if([[TinyiMailHelper helper] getTinyiMailStatus] != kTinyiMailStatusEmailVerified)
        tinyiMailButton.hidden = NO;
    else {
        tinyiMailButton.hidden = YES;
		rightView.frame = CGRectMake(rightView.frame.origin.x, 68, rightView.frame.size.width, rightView.frame.size.height);
	}
     */
	
	//判断按钮是否点击过
	if ([[SystemUtils getGlobalSetting:@"faadWasClick"] isEqualToString:@"1"]) {
		self.giftBoxFaad.image = [UIImage imageNamed:@"CollectionGiftBoxOpen.png"];
		self.bounsValue6.text = SNSLocal(@"UI_COLLECTION_BUTTON_TITLE_CASH1", @"Free");
	}
	
	if ([[SystemUtils getGlobalSetting:@"allOfferWasClick"] isEqualToString:@"1"]) {
		self.giftBoxAllOffer.image = [UIImage imageNamed:@"CollectionGiftBoxOpen.png"];
		self.bounsValue7.text = SNSLocal(@"UI_COLLECTION_BUTTON_TITLE_CASH1", @"Free");
	}
    
    [[PlayHavenHelper helper] initSession];
#ifndef SNS_DISABLE_TAPJOY
	[[TapjoyHelper helper] checkTapjoyPoints];
#endif
#ifndef SNS_DISABLE_FLURRY_V1
	[[FlurryHelper helper] getRewards];
#endif
    
    NSString *country = [SystemUtils getCountryCode];
    if([country isEqualToString:@"CN"] || [country isEqualToString:@"TW"] || [country isEqualToString:@"HK"])
    {
    
#ifdef SNS_ENABLE_LIMEI
    [[LiMeiHelper helper] checkPoints];
#endif

#ifdef SNS_ENABLE_APPDRIVER
    [[AppDriverHelper helper] checkPoints];
        videoImg.hidden = YES;
        videoCoinImg.hidden = YES;
        bounsValue5.text = @"Free";
#else
        videoBellImg.hidden = YES;
#endif

    }
    else {
        videoBellImg.hidden = YES;
    }
    
#ifndef SNS_DISABLE_CHARTBOOST
    [[ChartBoostHelper helper] loadCacheOffer];
#endif

#ifdef SNS_DISABLE_TINYMAIL
    [[TinyiMailHelper helper] startCheckStatus:NO];
#endif
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.setting = nil;
	self.collectionTitle = nil;
	self.bounsValue1 = nil;
	self.bounsValue2 = nil;
	self.bounsValue3 = nil;
	self.bounsValue4 = nil;
	self.bounsValue5 = nil;
	self.bounsValue6 = nil;
	self.bounsValue7 = nil;
	self.awardPopText = nil;
    self.playHavenIcon = nil;
	self.leftView = nil;
	self.rightView = nil;
	self.awardPop = nil;
	self.giftBoxFaad = nil;
	self.giftBoxAllOffer = nil;
    SNSReleaseObj(m_phToken);
    SNSReleaseObj(m_phSecret);
    SNSReleaseObj(m_playHavenBadgeView);
}

- (void) dealloc {
	self.setting = nil;
	self.collectionTitle = nil;
	self.bounsValue1 = nil;
	self.bounsValue2 = nil;
	self.bounsValue3 = nil;
	self.bounsValue4 = nil;
	self.bounsValue5 = nil;
	self.bounsValue6 = nil;
	self.bounsValue7 = nil;
	self.awardPopText = nil;
    self.playHavenIcon = nil;
	self.leftView = nil;
	self.rightView = nil;
	self.awardPop = nil;
	self.giftBoxFaad = nil;
	self.giftBoxAllOffer = nil;
    self.videoImg = nil;
    SNSReleaseObj(m_phToken);
    SNSReleaseObj(m_phSecret);
    SNSReleaseObj(m_playHavenBadgeView);
	[super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)closeBox {
    [super closeDialog];
}

- (void)didDialogClose {
	[super didDialogClose];
}

- (void)playAwardAnimation:(CGPoint)position awardText:(NSString *)texts
{
#ifndef MODE_COCOS2D_X
    [[SimpleAudioEngine sharedEngine] playEffect:@"coin.caf"];
#endif
	// [ playEffect:@"coin.caf"];
	self.awardPopText.text = texts;
	self.awardPop.frame = CGRectMake(position.x, position.y, self.awardPop.frame.size.width, self.awardPop.frame.size.height);
	self.awardPop.alpha = 1.0f;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[UIView setAnimationDuration:1.0f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(endAnimation)];
	self.awardPop.frame = CGRectMake(position.x, position.y - 80.0f, self.awardPop.frame.size.width, self.awardPop.frame.size.height);
	self.awardPop.alpha = 0.3f;
	[UIView commitAnimations];
}

- (void)endAnimation
{
	self.awardPop.alpha = 0.0f;
}

#pragma mark - IBAction function

- (IBAction)clickBouns:(id)sender {
    // int time = [SystemUtils getCurrentTime];
	if ([sender isKindOfClass:[UIButton class]]) {
		int tags = ((UIButton *)sender).tag;
		switch (tags) {
			case 1:
            {
#ifndef SNS_DISABLE_TAPJOY
                [TapjoyHelper showTapjoyOrLiMeiOffers];
#else
                [[FlurryHelper2 helper] showOffer];
#endif
            }
				break;
			case 2: {
                // flurry leaf
                [[FlurryHelper2 helper] showOffer];
                /*
                int userLevel = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel];
                int flurryLevel = [[SystemUtils getGlobalSetting:@"kiOSFlurryMinLevel"] intValue];
                if(userLevel < flurryLevel) 
                    [TapjoyHelper showOffers];
#ifndef SNS_DISABLE_FLURRY_V1
                else
                    [FlurryHelper showOffers:YES prizeType:1];
#endif
                 */
            }
				break;
			case 3: {
                [[FlurryHelper2 helper] showOffer];
                /*
                // flurry coin
                int userLevel = [[SystemUtils getGameDataDelegate] getGameResourceOfType:kGameResourceTypeLevel];
                int flurryLevel = [[SystemUtils getGlobalSetting:@"kiOSFlurryMinLevel"] intValue];
                if(userLevel < flurryLevel) 
                    [TapjoyHelper showOffers];
#ifndef SNS_DISABLE_FLURRY_V1
                else
                    [FlurryHelper showOffers:YES];
#endif
                 */
            }
				break;
			case 4:
                // flurry video
				// [FlurryHelper showVideoOffers:YES];
                // invite friends
            {
                TinyiMailHelper *helper = [TinyiMailHelper helper];
                BOOL showInviteCode = YES;
                if([helper hasFriendCode]) showInviteCode = NO;
                if(showInviteCode) {
                    int skipInviteCode = [[SystemUtils getNSDefaultObject:@"kInviteCodeSkip"] intValue];
                    if(skipInviteCode==1) showInviteCode = NO;
                }
                if(showInviteCode) {
                    [helper showEnterInviteCode:YES];
                }
                else {
                    [helper showInviteFriendsPopup:YES];
                }                
            }
				break;
			case 5:
#ifdef SNS_ENABLE_APPDRIVER
            {
                NSString *country = [SystemUtils getCountryCode];
                if([country isEqualToString:@"CN"] || [country isEqualToString:@"TW"] || [country isEqualToString:@"HK"])
                {
                    [[AppDriverHelper helper] showOffer];
                }
                else {
#ifndef SNS_DISABLE_ADCOLONY
                    // adcolony video
                    [[AdColonyHelper helper] showOffers:YES];
#endif
                }
            }
#else
#ifndef SNS_DISABLE_ADCOLONY
                // adcolony video
				[[AdColonyHelper helper] showOffers:YES];
#endif
#endif
				break;
			case 6:
			{
                if([[ChartBoostHelper helper] hasCachedOffer]) {
                    [[ChartBoostHelper helper] showChartBoostOffer];
                }
#ifndef SNS_DISABLE_FLURRY_V1
                else if([FlurryHelper hasRecommendation]) {
                    [FlurryHelper showRecommendation];
                }
#endif
                else {
                    // show tapjoy
#ifndef SNS_DISABLE_TAPJOY
                    [[TapjoyHelper helper] startGettingTapjoyFeaturedApp];
#endif
                }
                // [[TapjoyHelper helper] startGettingTapjoyFeaturedApp];
				//礼物盒子图标点击事件
				if (![[SystemUtils getGlobalSetting:@"faadWasClick"] isEqualToString:@"1"]) {
					CGPoint popPosition = CGPointMake(371, 132);
					if ([SystemUtils getGameOrientation] == UIDeviceOrientationPortrait) {
						popPosition = CGPointMake(26, 424);
					}
					[self playAwardAnimation:popPosition awardText:SNSLocal(@"UI_COLLECTION_BUTTON_TITLE_GIFTBOX1", @"X100")];
					[smPopupWindowAction doAction:nil prizeCoin:100 prizeLeaf:0];
				}
				self.giftBoxFaad.image = [UIImage imageNamed:@"CollectionGiftBoxOpen.png"];
				self.bounsValue6.text = SNSLocal(@"UI_COLLECTION_BUTTON_TITLE_CASH1", @"Free");;
				[SystemUtils setGlobalSetting:@"1" forKey:@"faadWasClick"];
			}
				break;
			case 7:
			{
#ifndef SNS_DISABLE_FLURRY_V1
                // Flurry video
                if(![SystemUtils checkFeature:kFeatureTinyMobi]) {
                    [FlurryHelper showVideoOffers:YES];
                    break;
                }
#endif
#ifdef SNS_ENABLE_TINYMOBI
                // [[TinyMobiConnect sharedTinyMobi] showAdWithType:TMB_AD_TINY_WALL On:nil];
                [[TinyMobiHelper helper] showOffer];
                // [[GreystripeHelper helper] showOffers:YES];
#else
                [SystemUtils showPopupOffer:0];
                // [FlurryHelper showVideoOffers:YES];
#endif
				if (![[SystemUtils getGlobalSetting:@"allOfferWasClick"] isEqualToString:@"1"]) {
					CGPoint popPosition = CGPointMake(371, 226);
					if ([SystemUtils getGameOrientation] == UIDeviceOrientationPortrait) {
						popPosition = CGPointMake(126, 424);
					}
					[self playAwardAnimation:popPosition awardText:SNSLocal(@"UI_COLLECTION_BUTTON_TITLE_GIFTBOX2", @"X100")];
					[smPopupWindowAction doAction:nil prizeCoin:100 prizeLeaf:0];
				}
                self.giftBoxAllOffer.image = [UIImage imageNamed:@"CollectionGiftBoxOpen.png"];
				self.bounsValue7.text = SNSLocal(@"UI_COLLECTION_BUTTON_TITLE_CASH1", @"Free");
				[SystemUtils setGlobalSetting:@"1" forKey:@"allOfferWasClick"];
			}
				break;
			default:
				break;
		}
	}
}

- (IBAction)clickMore:(id)sender {
	//点击more按钮的事件～
    SNSLog(@"clicked");
#ifndef SNS_DISABLE_TAPJOY
    if([TapjoyHelper helper].isWebModeEnabled) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.tapjoy.com/"]];
    }
    else {
        [TapjoyHelper showOffers];
    }
#endif
}

- (IBAction)clickIcon:(id)sender {
	//点击Icon的事件
    if(!m_showPlayHaven) return;
    if(m_playHavenBadgeView) {
        [m_playHavenBadgeView removeFromSuperview];
        SNSReleaseObj(m_playHavenBadgeView);
    }
    SNSLog(@"show more games");
    [[PlayHavenHelper helper] showOffer:YES];
}

// 点击tinyiMail
- (IBAction)clickTinyiMail:(id)sender
{
    TinyiMailHelper *helper = [TinyiMailHelper helper];
    [helper showiMailPopupBox:YES];
    if([helper getTinyiMailStatus] != kTinyiMailStatusEmailVerified)
        [helper startCheckStatus:YES];
}
@end
