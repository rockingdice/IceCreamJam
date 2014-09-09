//
//  DailyAwards.m
//  DreamTrain
//
//  Created by Jie Yang on 12/19/11.
//  Copyright (c) 2011 topgame.com. All rights reserved.
//
#import "SNSLogType.h"
#import "smPopupWindowDailyAwards.h"
#import "smPopupWindowAction.h"
#import "SystemUtils.h"
#ifndef MODE_COCOS2D_X
#import "cocos2d.h"
#endif

@implementation smPopupWindowDailyAwards
@synthesize setting = m_setting;
@synthesize roulette;
@synthesize dayBackground;
@synthesize dayNumText;
@synthesize dayAwardOk;
@synthesize tomorrowAward;
@synthesize awardAlertView;
@synthesize bodyView;
@synthesize playButton;
@synthesize alertIcon, alertTitle, alertValue;
@synthesize closeButton;

const float radius = 139.5f; //轮盘内物品半径
const float maxDuration = 0.3f; //最大旋转间隔时间
const float minDuration = 0.1f; //最小旋转间隔时间
const float attenuation = 0.01f; //旋转衰减量

- (id) initWithSetting:(NSDictionary *)settings
{
	UIDeviceOrientation orientation = [SystemUtils getGameOrientation];
	NSString *nibName = nil;
	if (orientation == UIDeviceOrientationPortrait) {
		if ([SystemUtils isiPad]) {
			nibName = @"smPopupWindowDailyAwards_pad_portrait";
		} else {
			nibName = @"smPopupWindowDailyAwards_portrait";
		}
	} else {
		if ([SystemUtils isiPad]) {
			nibName = @"smPopupWindowDailyAwards_pad";
		} else {
			nibName = @"smPopupWindowDailyAwards";
		}
	}
	self = [super initWithNibName:nibName bundle:nil];
	if (self) {
//		if (settings == nil) {
//			self.setting = [NSMutableDictionary dictionary];
//			NSArray *rouletteData = [NSArray arrayWithObjects:
//									 [NSDictionary dictionaryWithObjectsAndKeys:@"cash", @"type", @"1", @"value", nil], 
//									 [NSDictionary dictionaryWithObjectsAndKeys:@"coin", @"type", @"100", @"value", nil], 
//									 [NSDictionary dictionaryWithObjectsAndKeys:@"level", @"type", @"2000", @"value", nil], 
//									 [NSDictionary dictionaryWithObjectsAndKeys:@"coin", @"type", @"1000", @"value", nil], 
//									 [NSDictionary dictionaryWithObjectsAndKeys:@"cash", @"type", @"3", @"value", nil], 
//									 [NSDictionary dictionaryWithObjectsAndKeys:@"coin", @"type", @"200", @"value", nil], 
//									 [NSDictionary dictionaryWithObjectsAndKeys:@"cash", @"type", @"5", @"value", nil], 
//									 [NSDictionary dictionaryWithObjectsAndKeys:@"level", @"type", @"500", @"value", nil], 
//									 nil];
//			[self.setting setValue:rouletteData forKey:@"rouletteData"];
//			NSArray *awardData = [NSArray arrayWithObjects:
//								  [NSDictionary dictionaryWithObjectsAndKeys:@"coin", @"type", @"100", @"value", nil],
//								  [NSDictionary dictionaryWithObjectsAndKeys:@"coin", @"type", @"300", @"value", nil],
//								  [NSDictionary dictionaryWithObjectsAndKeys:@"roulette", @"type", @"1", @"value", nil],
//								  [NSDictionary dictionaryWithObjectsAndKeys:@"coin", @"type", @"500", @"value", nil],
//								  [NSDictionary dictionaryWithObjectsAndKeys:@"roulette", @"type", @"1", @"value", nil],
//								  nil];
//			[self.setting setValue:awardData forKey:@"awardData"];
//			[self.setting setValue:[NSNumber numberWithInt:6] forKey:@"stopIndex"];
//			[self.setting setValue:[NSNumber numberWithInt:3] forKey:@"dayNum"];
//		} else {
		self.setting = settings;
		SNSLog(@"setting description:%@", [self.setting description]);
		//}
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
    // Do any additional setup after loading the view from its nib.
#ifndef MODE_COCOS2D_X
	[[CCDirector sharedDirector] pause];
#endif
	//绘制轮盘内的物品
	[self drawRoulette];
	[self drawAllObject];
    [SystemUtils setInterruptMode:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.setting = nil;
	self.roulette = nil;
    self.awardAlertView = nil;
	self.dayBackground = nil;
	self.dayNumText = nil;
	self.dayAwardOk = nil;
	self.tomorrowAward = nil;
	self.bodyView = nil;
	self.playButton = nil;
	self.alertIcon = nil;
	self.alertTitle = nil;
	self.alertValue = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) dealloc {
    self.setting = nil;
	self.roulette = nil;
    self.awardAlertView = nil;
	self.dayBackground = nil;
	self.dayNumText = nil;
	self.dayAwardOk = nil;
	self.tomorrowAward = nil;
	self.bodyView = nil;
	self.playButton = nil;
	self.alertIcon = nil;
	self.alertTitle = nil;
	self.alertValue = nil;
	self.closeButton = nil;
	[super dealloc];
}

- (void) didDialogClose {
	[super didDialogClose];
#ifndef MODE_COCOS2D_X
	[[CCDirector sharedDirector] resume];
#endif
	if (self.delegate && [self.delegate respondsToSelector:@selector(winWasClose)]) {
		[delegate winWasClose];
	}
}

#pragma mark - draw award content

- (void) drawAllObject
{
	// 根据设备方向设置相关参数
	UIDeviceOrientation orientation = [SystemUtils getGameOrientation];
	int startLength = 23;
	int bodyItemWidth = 85;
	int iconXPosition = 30;
	if (orientation == UIDeviceOrientationPortrait) {
		startLength = 31;
		bodyItemWidth = 66;
		iconXPosition = 18;
	}
	
	//设置play按钮默认不可点击
	self.playButton.enabled = NO;
	//判断系统语言，如果是英文那么移动天数到合适位置
	if ([[SystemUtils getCurrentLanguage] isEqualToString:@"en"]) {
		self.dayNumText.frame = CGRectMake([self autoLength:([SystemUtils isiPad]?334:319)], self.dayNumText.frame.origin.y, self.dayNumText.frame.size.width, self.dayNumText.frame.size.height);
		// 竖屏移动一下
		if (orientation == UIDeviceOrientationPortrait) {
			self.dayNumText.frame = CGRectMake([self autoLength:([SystemUtils isiPad]?266:210)], self.dayNumText.frame.origin.y, self.dayNumText.frame.size.width, self.dayNumText.frame.size.height);
			self.dayBackground.frame = CGRectMake(0, 0, ([SystemUtils isiPad]?768:320), ([SystemUtils isiPad]?96:46));
		}
	}
#ifdef ANIMAL_STORY_KO
    self.dayNumText.frame = CGRectMake([self autoLength:([SystemUtils isiPad]?154:139)], self.dayNumText.frame.origin.y, self.dayNumText.frame.size.width, self.dayNumText.frame.size.height);
#endif 
	//获得连续登陆的天数
	int dayNum = [[self.setting objectForKey:@"dayNum"] intValue];
    if(dayNum==0) dayNum = 5;
	if (orientation == UIDeviceOrientationPortrait) {
		dayNum = dayNum%4;
		if (dayNum == 0) dayNum = 4;
	}
	//修改顶部的天数文字
	self.dayNumText.image = [UIImage imageNamed:[NSString stringWithFormat:@"DA%d.png", dayNum]];
	//移动今日奖励位置
	self.dayAwardOk.frame = CGRectMake([self autoLength:startLength + bodyItemWidth * (dayNum-1)], self.dayAwardOk.frame.origin.y, self.dayAwardOk.frame.size.width, self.dayAwardOk.frame.size.height);
	
	//移动明日奖励位置
	self.tomorrowAward.frame = CGRectMake([self autoLength:startLength + bodyItemWidth * (dayNum%5)], self.tomorrowAward.frame.origin.y, self.tomorrowAward.frame.size.width, self.tomorrowAward.frame.size.height);
	
	//判断玩轮盘的按钮是否可以点击
	NSMutableArray *awardData = [NSMutableArray arrayWithArray:[self.setting objectForKey:@"awardData"]];
	if (orientation == UIDeviceOrientationPortrait) {
		[awardData removeObjectAtIndex:1];
	}
	if ([[[awardData objectAtIndex:(dayNum-1)] objectForKey:@"type"] isEqualToString:@"roulette"]) {
		self.playButton.enabled = YES;
		m_todayBonus = [[self.setting objectForKey:@"rouletteData"] objectAtIndex:[[self.setting objectForKey:@"stopIndex"] intValue]];
		if ([[m_todayBonus objectForKey:@"type"] isEqualToString:@"coin"]) {
			self.alertIcon.image = [UIImage imageNamed:@"wqRunLoginYB.png"];
		} else if ([[m_todayBonus objectForKey:@"type"] isEqualToString:@"cash"]) {
			self.alertIcon.image = [UIImage imageNamed:@"wqRunLoginLeafage.png"];
		} else {
			self.alertIcon.image = [UIImage imageNamed:@"wqRunLoginXP.png"];
		}
		self.alertTitle.text = SNSLocal(@"SM_DAILY_BONUS_TITLE", @"*获得奖励");
		self.alertValue.text = [NSString stringWithFormat:@"X%d", [[m_todayBonus objectForKey:@"value"] intValue]];
		//禁用关闭按钮先，转完了再启用
		self.closeButton.enabled = NO;
		// 设置play按钮的闪光效果
		[self sharpRouletteButton];
	} else {
		//否则直接提示获得的奖励
		m_todayBonus = [[self.setting objectForKey:@"awardData"] objectAtIndex:(dayNum -1)];
		if ([[m_todayBonus objectForKey:@"type"] isEqualToString:@"coin"]) {
			self.alertIcon.image = [UIImage imageNamed:@"wqRunLoginYB.png"];
		} else if ([[m_todayBonus objectForKey:@"type"] isEqualToString:@"cash"]) {
			self.alertIcon.image = [UIImage imageNamed:@"wqRunLoginLeafage.png"];
		}
		self.alertTitle.text = SNSLocal(@"SM_DAILY_BONUS_TITLE", @"*获得奖励");
		self.alertValue.text = [NSString stringWithFormat:@"X%d", [[m_todayBonus objectForKey:@"value"] intValue]];
		//[self showAwardAlertView];
		[self awardToUser];
	}
	
	//根据数据绘制每个格子里的内容
	for (int i = 0; i < [awardData count]; i++) {
		NSDictionary *item = [awardData objectAtIndex:i];
		UIView *awardBox = [[UIView alloc] initWithFrame:CGRectMake([self autoLength:startLength + bodyItemWidth * (i % 5)], self.dayAwardOk.frame.origin.y, self.dayAwardOk.frame.size.width, self.dayAwardOk.frame.size.height)];
		
		UIImageView *awardIcon = [[UIImageView alloc] initWithFrame:[self autoFrame:CGRectMake(iconXPosition, 30, 32, 32)]];
		if ([[item objectForKey:@"type"] isEqualToString:@"cash"]) {
			awardIcon.image = [UIImage imageNamed:@"wqRunLoginLeafage.png"];
		} else if ([[item objectForKey:@"type"] isEqualToString:@"coin"]) {
			awardIcon.image = [UIImage imageNamed:@"wqRunLoginYB.png"];
		} else {
			awardIcon.image = [UIImage imageNamed:@"wqRunLoginRoulette.png"];
		}
		[awardBox addSubview:awardIcon];
		[awardIcon release];
		
		//if (![[item objectForKey:@"type"] isEqualToString:@"roulette"]) {
		UILabel *awardValue = [[UILabel alloc] initWithFrame:CGRectMake(0, [self autoLength:60.0f], self.dayAwardOk.frame.size.width, [self autoLength:20.0f])];
			awardValue.text = [NSString stringWithFormat:@"X%d", [[item objectForKey:@"value"] intValue]];
			awardValue.textAlignment = UITextAlignmentCenter;
			awardValue.font = [UIFont fontWithName:@"Arial" size:[self autoLength:12.0f]];
			awardValue.backgroundColor = [UIColor clearColor];
			[awardBox addSubview:awardValue];
			[awardValue release];
		//}
		
		[self.bodyView addSubview:awardBox];
		[awardBox release];
	}
	
	[self.bodyView bringSubviewToFront:self.dayAwardOk];
}

- (void) sharpRouletteButton
{
	if (!self.playButton.enabled && m_playButtonAlpha == 1.0f){
		return;
	}
	if (m_playButtonAlpha == 0) {
		m_playButtonAlpha = 1.0f;
		m_playButtonScale = 1.0f;
	} else if (m_playButtonAlpha >= 1.0f) {
		m_playButtonAlpha = 0.3f;
		m_playButtonScale = 0.9f;
	} else if (m_playButtonAlpha <= 0.3f) {
		m_playButtonAlpha = 1.0f;
		m_playButtonScale = 1.1f;
	}
	// 如果在动画过程中点了按钮，那么改为最终状态并再执行一次
	if (!self.playButton.enabled){
		m_playButtonAlpha = 1.0f;
		self.playButton.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
	}
	
	[UIView beginAnimations:@"sharpRoulette" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[UIView setAnimationDuration:0.8f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(sharpRouletteButton)];
	self.playButton.alpha = m_playButtonAlpha;
	self.playButton.transform = CGAffineTransformMakeScale(m_playButtonScale, m_playButtonScale);
	[UIView commitAnimations];
}

#pragma mark - draw roulette function

- (void) drawRoulette
{
	NSArray *data = [self.setting objectForKey:@"rouletteData"];
	int i = 0;
	for (NSDictionary *item in data) {
		//计算角度
		CGFloat radian = ((i * 45.0f) + 22.5f) * M_PI / 180;
		//计算每个物品应该在圆周的位置
		CGPoint position = [self autoPoint:CGPointMake(189.0f + (radius * cosf(radian)), 189.0f + (radius * sinf(radian)))];
		
		UIView *subItem = [[UIView alloc] initWithFrame:CGRectMake(position.x, position.y, [self autoLength:100.0f], [self autoLength:100.0f])];
		subItem.center = position;
		subItem.backgroundColor = [UIColor clearColor];
		
		UIImageView *cashOrCoin = [[UIImageView alloc] init];
		cashOrCoin.frame = [self autoFrame:CGRectMake(10, 30, 32, 32)];
		if ([[item objectForKey:@"type"] isEqualToString:@"coin"]) {
			cashOrCoin.image = [UIImage imageNamed:@"wqRunLoginYB.png"];
		} else if ([[item objectForKey:@"type"] isEqualToString:@"cash"]) {
			cashOrCoin.image = [UIImage imageNamed:@"wqRunLoginLeafage.png"];
		} else {
			cashOrCoin.image = [UIImage imageNamed:@"wqRunLoginXP.png"];
		}
		[subItem addSubview:cashOrCoin];
		[cashOrCoin release];
		
		UILabel *itemText = [[UILabel alloc] init];
		itemText.font = [UIFont fontWithName:@"Arial" size:[self autoLength:12.0f]];
		itemText.frame = [self autoFrame:CGRectMake(45, 40, 60, 20)];
		itemText.backgroundColor = [UIColor clearColor];
		itemText.text = [NSString stringWithFormat:@"X%d", [[item objectForKey:@"value"] intValue]];
		[subItem addSubview:itemText];
		[itemText release];
		
		//重新纠正每个轮盘内物品的角度（弧度制）
		radian = ((i * 45.0f) + 22.5f - 90.0f) * M_PI / 180;
		
		subItem.transform = CGAffineTransformMakeRotation(radian);
		[self.roulette addSubview:subItem];
		[subItem release];
		
		++i;
	}
}

#pragma mark - IBAction methods

- (IBAction)rotateRoulette:(id)sender
{
	if ([sender isKindOfClass:[UIButton class]]) {
		((UIButton *)sender).enabled = NO;
	}
	m_routeDuration = maxDuration;
	m_isNeedStop = NO;
	m_randomAngle = arc4random() % 40 + 5;
	[self rotateStart];
}

- (IBAction)closeAwardAlertView:(id)sender
{
	self.awardAlertView.hidden = YES;
	[self awardToUser];
	//启用关闭按钮
	self.closeButton.enabled = YES;
	// [self closeDialog];
}

- (void) showAwardAlertView
{
	self.awardAlertView.hidden = NO;
}

#pragma mark - rotateRoulette animation function

- (void) rotateStart
{
	[self subRotateDuration];
	if (m_routeDuration > maxDuration) {
		m_stopRadius = m_runRadius;
		[self stopAtSettingIndex];
		return;
	}
	m_runRadius += 45.0f * M_PI / 180;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[UIView setAnimationDuration:m_routeDuration];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(rotateStart)];
	roulette.transform = CGAffineTransformMakeRotation(m_runRadius);
	[UIView commitAnimations];
}

- (void) subRotateDuration
{
	SNSLog(@"route duration:%f", m_routeDuration);
	if (m_isNeedStop) {
		m_routeDuration += (attenuation + 0.2f);
		return;
	}
	if (m_routeDuration > minDuration) {
		m_routeDuration -= (attenuation + 0.2f);
		if (m_routeDuration <= minDuration) {
			//达到最高转动速度之后等待一定时间之后再开始减速（看起来比较合理）
			[self performSelector:@selector(stopRotate) withObject:nil afterDelay:3.0f];
		}
		
	}
}

- (void) stopRotate
{
	m_isNeedStop = YES;
}

- (void) stopAtSettingIndex
{
	int itemNum = [[self.setting objectForKey:@"stopIndex"] intValue];
	//因为本身格子位置与角度之前的偏差，所以处理偏差值
	if (itemNum < 2) {
		itemNum = abs(itemNum - 1);
	} else {
		itemNum = 7 + (2 - itemNum);
	}
	//计算最后应该停在哪个弧度
	CGFloat stopRadius = ((itemNum * 45.0f + m_randomAngle) * M_PI / 180) + (2 * M_PI * ((int)(m_runRadius / (2 * M_PI))));
    
    while(m_stopRadius > stopRadius) {
        stopRadius += 2 * M_PI;
    }
	
	m_routeDuration += (attenuation + 0.1f);
	
	//如果停止转动的位置大于最后需要转到的位置那么继续旋转
	SNSLog(@"now:%f -- stop:%f", m_stopRadius, stopRadius);
	if (stopRadius - m_stopRadius > (45.0f * M_PI / 180)) {
		m_stopRadius += (45.0f * M_PI / 180);
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationCurve:UIViewAnimationCurveLinear];
		[UIView setAnimationDuration:m_routeDuration];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(stopAtSettingIndex)];
		roulette.transform = CGAffineTransformMakeRotation(m_stopRadius);
		[UIView commitAnimations];
		return;
	}
	m_routeDuration -= attenuation;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:m_routeDuration];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(rotateSuccess)];
	roulette.transform = CGAffineTransformMakeRotation(stopRadius);
	[UIView commitAnimations];
}

- (void) rotateSuccess {
	//旋转结束后延迟一段时间显示提示框
	[self performSelector:@selector(showAward) withObject:nil afterDelay:1.0f];
}

- (void) showAward {
	//NSLog(@"轮盘转完了！！！");
	[self showAwardAlertView];
}

- (void) awardToUser {
	if(m_todayBonus){
		if ([[m_todayBonus objectForKey:@"type"] isEqualToString:@"cash"]) {
			[smPopupWindowAction doAction:nil prizeCoin:0 prizeLeaf:[[m_todayBonus objectForKey:@"value"] intValue]];
		} else if ([[m_todayBonus objectForKey:@"type"] isEqualToString:@"coin"]) {
			[smPopupWindowAction doAction:nil prizeCoin:[[m_todayBonus objectForKey:@"value"] intValue] prizeLeaf:0];
		} else if ([[m_todayBonus objectForKey:@"type"] isEqualToString:@"level"]){
			[smPopupWindowAction doAction:nil withInfo:[NSDictionary dictionaryWithObjectsAndKeys:[m_todayBonus objectForKey:@"value"], @"prizeExp", nil]];
		}
	}
}

#pragma mark - helper function

- (CGFloat) autoLength:(CGFloat)length {
	if ([SystemUtils isiPad]) {
		return length * 2;
	}
	return length;
}

- (CGRect) autoFrame:(CGRect)rect {
	if ([SystemUtils isiPad]) {
		return CGRectMake(rect.origin.x * 2, rect.origin.y * 2, rect.size.width * 2, rect.size.height * 2);
	}
	return rect;
}

- (CGPoint) autoPoint:(CGPoint)point {
	if ([SystemUtils isiPad]) {
		return CGPointMake(point.x * 2, point.y * 2);
	}
	return point;
}

@end
