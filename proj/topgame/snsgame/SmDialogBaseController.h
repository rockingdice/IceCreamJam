//
//  smBaseViewController.h
//  temp
//
//  Created by yang jie on 14/07/2011.
//  Copyright 2011 com.snsgame. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SocialConfig.h"

@interface SmDialogBaseController : UIViewController {
	
@private
    UIDeviceOrientation     privateOrientation;
	UIScrollView*           modalBackgroundView;
	int                     showType;
}

@property (nonatomic, assign) UIDeviceOrientation privateOrientation;
@property (nonatomic, assign) BOOL loadOver;
@property (nonatomic, assign) BOOL isInWindow; //判断是否从window上弹出窗体，默认为NO
@property (nonatomic, assign) BOOL isNeedBackground; //判断是否构建遮罩背景，默认为YES

- (BOOL)IsDeviceIPad;
- (void)addObservers;
- (void)removeObservers;
- (void)sizeToFitOrientation:(BOOL)transform;
- (CGAffineTransform)transformForOrientation;

//加载弹出框
- (void)constructDialog;
//硬生生显示窗体
- (void)showHard;
//从下往上弹出窗体
- (void)persentModuleUp;
//落下弹出框
- (void)persentModule;
//显示弹出框(pop)
- (void)show;

- (void) dialogCleanAnimationStop;

//关闭弹出框
- (IBAction)closeDialog;
//pop关闭动画
- (void)closePop;
//persent关闭动画
- (void)closePersent;
//窗体加载完之后执行的函数
- (void)dialogLoadOver;
//相当于viewDidUnload,请在子类中重写该方法
- (void)didDialogClose;
//关闭自己的键盘
- (IBAction)closeKeyBoard;
//因为这个类比较基础，所以应该即使不引用SystemUtils也可以使用，自己写这个方法
- (id)getRootViewController;

@end
