//
//  DailyAwards.h
//  DreamTrain
//
//  Created by Jie Yang on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "smPopupWindowBase.h"

@interface smPopupWindowDailyAwards : smPopupWindowBase {
	
@private
	NSMutableDictionary *			m_setting;
	
	CGFloat							m_routeDuration;
	CGFloat							m_stopRadius;
	CGFloat							m_runRadius;
	CGFloat							m_randomAngle;
	CGFloat							m_playButtonAlpha;
	CGFloat							m_playButtonScale;
	
	BOOL							m_isNeedStop;
	NSDictionary *					m_todayBonus;
}

@property (nonatomic, retain) NSDictionary *setting;
@property (nonatomic, retain) IBOutlet UIView *roulette;
@property (nonatomic, retain) IBOutlet UIImageView *dayBackground;
@property (nonatomic, retain) IBOutlet UIImageView *dayNumText;
@property (nonatomic, retain) IBOutlet UIView *dayAwardOk;
@property (nonatomic, retain) IBOutlet UIView *tomorrowAward;
@property (nonatomic, retain) IBOutlet UIControl *awardAlertView;
@property (nonatomic, retain) IBOutlet UIView *bodyView;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet UIImageView *alertIcon;
@property (nonatomic, retain) IBOutlet UILabel *alertTitle;
@property (nonatomic, retain) IBOutlet UILabel *alertValue;
@property (nonatomic, retain) IBOutlet UIButton *closeButton;

- (id) initWithSetting:(NSDictionary *)settings;
//移动奖励内容到指定位置
- (void) drawAllObject;
//设置playButton的闪光效果
- (void) sharpRouletteButton;
//绘制轮盘内容的函数
- (void) drawRoulette;
//旋转轮盘的按钮点击事件
- (IBAction) rotateRoulette:(id)sender;
//显示获得的奖励提示框
- (void) showAwardAlertView;
//关闭奖励提示窗口
- (IBAction)closeAwardAlertView:(id)sender;
//开始旋转的动画函数
- (void) rotateStart;
//设置旋转时间的函数
- (void) subRotateDuration;
//停止到setting传回来的位置
- (void) stopAtSettingIndex;
//给玩家奖励
- (void) awardToUser;

//辅助计算函数
- (CGFloat) autoLength:(CGFloat)length;
- (CGRect) autoFrame:(CGRect)rect;
- (CGPoint) autoPoint:(CGPoint)point;

@end
