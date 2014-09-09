//
//  SNSPromotionViewController.h
//  MovieSlots
//
//  Created by Leon Qiu on 4/21/14.
//
//

#import <UIKit/UIKit.h>

#define RESERVE_NOTICE_ID_RATE_HINT   -100

@interface SNSPromotionViewController : UIViewController
{
    
}

@property (nonatomic,assign)  BOOL  isPortrait;
@property (nonatomic, retain) NSDictionary *noticeInfo;
@property (nonatomic, retain) IBOutlet UIImageView *imgBG;
@property (nonatomic, retain) IBOutlet UIImageView *imgNew;
@property (nonatomic, retain) IBOutlet UIImageView *imgInfo;
@property (nonatomic, retain) IBOutlet UILabel     *labelInfo;
@property (nonatomic, retain) IBOutlet UIButton    *btnClose;
@property (nonatomic, retain) IBOutlet UIButton    *btnOK;
@property (nonatomic, retain) IBOutlet UIButton    *btnNext;
@property (nonatomic, retain) IBOutlet UIButton    *btnPrev;

// 创建并显示公告
+ (SNSPromotionViewController *) createAndShow;
// 是否正在显示
+ (BOOL) isShowing;
// 关闭通知
+ (void) closePromotionView;
// 添加通知
+ (void) addNotice:(NSDictionary *)notice;
// 添加文字通知
+ (void) addMessageNotice:(NSString *)mesg withAction:(NSString *)action;
// 存储通知
+ (void) saveNoticeList;
// 加载通知
+ (void) loadNoticeList;
// 获得新通知数量
+ (int) getNewNoticeCount;
// 获得有效通知数量
+ (int) getNoticeCount;

- (IBAction) onClick:(UIButton *)btn;
- (IBAction) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;


@end
