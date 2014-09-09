#import "WPCallsWrapper.h"
#import "AppConnect.h"

@class WPNewPopView;
@class UIViewController;

@interface WPNewPopViewController : NSObject{
    WPNewPopView *_popH5;

}
@property(nonatomic, retain) WPNewPopView *popH5;

+ (void)initNewPop:(UIViewController *)controller;

+ (void)showNewPop:(UIViewController *)controller;

+ (void)closeNewPop;

- (void)removePopH5;

@end

@interface WPCallsWrapper (WPNewPopViewController)

- (void)initNewPop:(UIViewController *)controller;

- (void)showNewPop:(UIViewController *)controller;

- (void)closeNewPop;

@end


@interface AppConnect (WPNewPopViewController)

+ (void)initNewPop:(UIViewController *)controller;

+ (void)showNewPop:(UIViewController *)controller;

+ (void)closeNewPop;
@end
