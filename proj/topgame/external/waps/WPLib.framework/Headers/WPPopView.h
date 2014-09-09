#import <UIKit/UIKit.h>
#import "AppConnect.h"

@class WPWAdRequestHandler;

@interface WPPopView : UIView
{
    WPWAdRequestHandler *popAdViewObj_;
}
@property(nonatomic, retain) WPWAdRequestHandler *popAdViewObj_;

- (id)getPopViewWithController:(UIViewController *)controller;

- (void)loadPopWithVersion:(NSString *)popVersion;

- (void)closePop;

+ (WPPopView *)sharedWPPopView;


//- (id)getWindowAdView;

@end

@interface AppConnect(WPWAdView)

+ (void)initPop;

+ (id)showPop:(UIViewController *)controller;

+ (void)closePop;

@end
