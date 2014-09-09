//
//  BounsCollection.h
//  DreamTrain
//
//  Created by Jie Yang on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SNSLogType.h"
#import "smPopupWindowBase.h"
#import "PlayHavenSDK.h"

@interface smPopupWindowBonusCollection : smPopupWindowBase<PHPublisherContentRequestDelegate> {
	
@private
	NSString *						m_phToken;
    NSString *						m_phSecret;
    BOOL							m_showPlayHaven;
    PHNotificationView *			m_playHavenBadgeView;
	// SimpleAudioEngine *				m_audioEngine;
}

@property (nonatomic, retain) NSDictionary *setting;
@property (nonatomic, retain) IBOutlet UILabel *collectionTitle;
@property (nonatomic, retain) IBOutlet UIButton *playHavenIcon;
@property (nonatomic, retain) IBOutlet UILabel *bounsValue1;
@property (nonatomic, retain) IBOutlet UILabel *bounsValue2;
@property (nonatomic, retain) IBOutlet UILabel *bounsValue3;
@property (nonatomic, retain) IBOutlet UILabel *bounsValue4;
@property (nonatomic, retain) IBOutlet UILabel *bounsValue5;
@property (nonatomic, retain) IBOutlet UILabel *bounsValue6;
@property (nonatomic, retain) IBOutlet UILabel *bounsValue7;
@property (nonatomic, retain) IBOutlet UILabel *awardPopText;
@property (nonatomic, retain) IBOutlet UIButton *moreButton;
@property (nonatomic, retain) IBOutlet UIButton *tinyiMailButton;
@property (nonatomic, retain) IBOutlet UIView *leftView;
@property (nonatomic, retain) IBOutlet UIView *rightView;
@property (nonatomic, retain) IBOutlet UIView *awardPop;
@property (nonatomic, retain) IBOutlet UIImageView *giftBoxFaad;
@property (nonatomic, retain) IBOutlet UIImageView *giftBoxAllOffer;
@property (nonatomic, retain) IBOutlet UIImageView *videoImg;
@property (nonatomic, retain) IBOutlet UIImageView *videoCoinImg;
@property (nonatomic, retain) IBOutlet UIImageView *videoBellImg;

- (id) initBouns;

- (IBAction)clickBouns:(id)sender;
// 更多按钮点击事件
- (IBAction)clickMore:(id)sender;
// 点击左下角的Icon
- (IBAction)clickIcon:(id)sender;
// 点击tinyiMail
- (IBAction)clickTinyiMail:(id)sender;
// 点击礼盒按钮之后显示奖励气泡
- (void)playAwardAnimation:(CGPoint)position awardText:(NSString *)texts;
// 停止动画
- (void)endAnimation;

@end
