//
//  SNSAlertView.h
//  TapCar
//
//  Created by Jie Yang on 12/13/11.
//  Copyright (c) 2011 topgame.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "smPopupWindowBase.h"

/*
 SNSAlertView *alert = [[SNSAlertView alloc] initWithTitle:@"你好啊"
    message:@"test content~!~!~!"
    delegate:self
    cancelButtonTitle:@"取消"
    otherButtonTitle:@"确定", nil];
 //如果直接弹出的话：
 [alert show];
 //如果在队列中弹出的话：
 [[smPopupWindowQueue createQueue] pushToQueue:alert timeOut:0];
 SNSWebWindow *web = [[SNSWebWindow alloc] initWithUrl:@"http://www.ifindu.cn/"
 title:@"测试网页"
 closeButtonTitle:@"关闭"];
 //直接弹出：
 [web showHard];
 //队列弹出
 [[smPopupWindowQueue createQueue] pushToQueue:web timeOut:0];
 
 */

@class SNSAlertView;

@protocol SNSAlertViewDelegate <NSObject>

@required

@optional
- (void)snsAlertView:(SNSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@interface SNSAlertView : smPopupWindowBase {
	
@private
	id<SNSAlertViewDelegate>			m_alertDelegate;
	IBOutlet UILabel *					m_title;
	IBOutlet UITextView *				m_content;
	IBOutlet UIButton *					m_cancelButton;
	
	NSString *							m_tempTitle;
	NSString *							m_tempContent;
	NSString *							m_tempCancelButton;
	NSString *							m_otherButton;
	
	va_list								m_args;
	
	NSUInteger							m_tag;
    NSUInteger                          m_buttonIndex;
}

@property (nonatomic, assign) id<SNSAlertViewDelegate> alertDelegate;
@property (nonatomic, retain) IBOutlet UILabel *alertTitle;
@property (nonatomic, retain) IBOutlet UITextView *alertContent;
@property (nonatomic, retain) IBOutlet UIButton *alertCancelButton;
@property (nonatomic, assign) NSUInteger tag;
@property (nonatomic, assign) BOOL showInQueue;

- (id) initWithTitle:(NSString *)title message:(NSString *)message delegate:(id<SNSAlertViewDelegate>)delegates cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitle:(NSString *)otherButtonTitle, ... NS_REQUIRES_NIL_TERMINATION;

@end
