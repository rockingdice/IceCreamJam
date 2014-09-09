//
//  smBaseViewController.m
//  temp
//
//  Created by yang jie on 14/07/2011.
//  Copyright 2011 com.snsgame. All rights reserved.
//

#import "SmDialogBaseController.h"
// #import "cocos2d.h"

static CGFloat kTransitionDuration = 0.3f;

@implementation SmDialogBaseController
@synthesize privateOrientation, loadOver;
@synthesize isInWindow;
@synthesize isNeedBackground;

- (BOOL)IsDeviceIPad {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
#endif
    return NO;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.loadOver = NO;
        //默认不在window上边弹出窗体
        self.isInWindow = NO;
		//默认为显示遮罩背景
		self.isNeedBackground = YES;
		//注册一个观察者观察键盘关闭操作
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(closeKeyBoard) 
													 name:kSocialModuleKeyBoardNeedClose 
												   object:nil];
    }
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:kSocialModuleKeyBoardNeedClose 
												  object:nil];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSNSNotificationShowAlertView object:nil userInfo:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark - Operating Method

- (void)constructDialog {
	//[self load];
	//retain一下自己，以防止被提前释放
	[self retain];
	self.loadOver = NO;
	self.view.backgroundColor = [UIColor clearColor];
	[self sizeToFitOrientation:YES];
	
    SNSLog(@"isInWindow:%i", self.isInWindow);
    if (self.isInWindow) {
        UIWindow* window = [UIApplication sharedApplication].keyWindow;
        if (!window) {
            window = [[UIApplication sharedApplication].windows objectAtIndex:0];
        }
        //NSLog(@"win retaincount:%d", [window retainCount]);
        //NSLog(@"window.frame:%f -- %f -- %f -- %f", window.frame.origin.x, window.frame.origin.y, window.frame.size.width, window.frame.size.height);
		if (self.isNeedBackground && modalBackgroundView == nil) {
			modalBackgroundView = [[UIScrollView alloc] initWithFrame:window.frame];
			
			modalBackgroundView.backgroundColor = [UIColor blackColor];
			modalBackgroundView.alpha = 0.3f;
			[window addSubview:modalBackgroundView];
			[modalBackgroundView release];
		}
        
        //NSLog(@"%s - addSubview retainCount:%d", __FUNCTION__, [modalBackgroundView retainCount]);
        
        
        self.view.center = window.center;
        self.view.alpha = 1.0f;
        
        [window addSubview:self.view];
        [self addObservers];
    } else {
        CGRect winSize = [UIScreen mainScreen].bounds;
        CGPoint center = CGPointMake(winSize.size.width/2, winSize.size.height/2);
        if([[SystemUtils getSystemInfo:@"kRootViewFlipped"] intValue]==1) {
            int v = center.x; center.x = center.y; center.y = v;
            v = winSize.size.width; winSize.size.width = winSize.size.height; winSize.size.height = v;
        }
		if (self.isNeedBackground && modalBackgroundView == nil) {
			modalBackgroundView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, winSize.size.width, winSize.size.height)];
			
			modalBackgroundView.backgroundColor = [UIColor blackColor];
			modalBackgroundView.alpha = 0.3f;
			[((UIViewController *)[self getRootViewController]).view addSubview:modalBackgroundView];
			[modalBackgroundView release];
		}
        //NSLog(@"%s - addSubview retainCount:%d", __FUNCTION__, [modalBackgroundView retainCount]);
        
        self.view.center = center;
        self.view.alpha  = 1.0f;
        
        [((UIViewController *)[self getRootViewController]).view addSubview:self.view];
    }
}

- (void)showHard {
	[self constructDialog];
	showType = ShowTypeHard;
	[self dialogLoadOver];
}

- (void)persentModuleUp {
	[self constructDialog];
	showType = ShowTypePersentUp;
	float originY = self.view.frame.origin.y;
	self.view.frame = CGRectMake(self.view.frame.origin.x, 1024 + self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration * 0.55f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(dialogLoadOver)];
	//smLog(@"%f", self.view.frame.origin.y);
	self.view.frame = CGRectMake(self.view.frame.origin.x, originY, self.view.frame.size.width, self.view.frame.size.height);
	[UIView commitAnimations];
}

- (void)persentModule {
	[self constructDialog];
	showType = ShowTypePersent;
	float originY = self.view.frame.origin.y;
	self.view.frame = CGRectMake(self.view.frame.origin.x, -self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration * 0.55f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(persentModule1AnimationStopped)];
	smLog(@"%f", self.view.frame.origin.y);
	self.view.frame = CGRectMake(self.view.frame.origin.x, originY, self.view.frame.size.width, self.view.frame.size.height);
	[UIView commitAnimations];
}

- (void)persentModule1AnimationStopped {
	//self.view.frame = CGRectMake(0, -self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration * 0.45f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(persentModule2AnimationStopped)];
	self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - 56, self.view.frame.size.width, self.view.frame.size.height);
	[UIView commitAnimations];
}

- (void)persentModule2AnimationStopped {
	//self.view.frame = CGRectMake(0, -self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration * 0.35f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(persentModule3AnimationStopped)];
	self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 56, self.view.frame.size.width, self.view.frame.size.height);
	[UIView commitAnimations];
}

- (void)persentModule3AnimationStopped {
	//self.view.frame = CGRectMake(0, -self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration * 0.35f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(persentModule4AnimationStopped)];
	self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - 20, self.view.frame.size.width, self.view.frame.size.height);
	[UIView commitAnimations];
}

- (void)persentModule4AnimationStopped {
	//self.view.frame = CGRectMake(0, -self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration * 0.15f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(dialogLoadOver)];
	self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 20, self.view.frame.size.width, self.view.frame.size.height);
	[UIView commitAnimations];
}

- (void)show {
	[self constructDialog];
	showType = ShowTypePopo;
	self.view.transform = CGAffineTransformScale([self transformForOrientation], 0.001f, 0.001f);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration * 0.45f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounce1AnimationStopped)];
	self.view.transform = CGAffineTransformScale([self transformForOrientation], 1.1f, 1.1f);
	[UIView commitAnimations];
}

- (void)bounce1AnimationStopped {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration * 0.35f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounce2AnimationStopped)];
	self.view.transform = CGAffineTransformScale([self transformForOrientation], 0.9f, 0.9f);
	[UIView commitAnimations];
}

- (void)bounce2AnimationStopped {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration * 0.25f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(dialogLoadOver)];
	self.view.transform = [self transformForOrientation];
	[UIView commitAnimations];
}

- (void)dialogLoadOver {
	self.loadOver = YES;
	//发送通知让所有自己的实例全部关闭键盘
	[[NSNotificationCenter defaultCenter] postNotificationName:kSocialModuleKeyBoardNeedClose object:nil];
}

- (IBAction)closeDialog {
	if (loadOver) {
		self.loadOver = NO;
		if (modalBackgroundView && [modalBackgroundView isKindOfClass:[UIScrollView class]] && modalBackgroundView.superview != nil) {
			[modalBackgroundView removeFromSuperview];
			modalBackgroundView = nil;
		}
		switch (showType) {
			case ShowTypePopo:
				[self closePop];
				break;
			case ShowTypePersent:
				[self closePersent];
				break;
			case ShowTypePersentUp:
				[self closePersent];
				break;
			case ShowTypeHard:
				[self dialogCleanAnimationStop];
				break;
			default:
				[self closePop];
				break;
		}
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:kSNSNotificationHideAlertView object:nil userInfo:nil];
}

- (void)closePop {
	self.view.transform = [self transformForOrientation];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration * 0.5f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounceCleanAnimation)];
	self.view.transform = CGAffineTransformScale([self transformForOrientation], 1.1, 1.1);
	[UIView commitAnimations];
}

- (void)bounceCleanAnimation {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration * 0.75f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(dialogCleanAnimationStop)];
	self.view.transform = CGAffineTransformScale([self transformForOrientation], 0.1, 0.1);
	self.view.alpha = 0.001f;
	[UIView commitAnimations];
}

- (void)closePersent {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration * 0.75f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(persentCleanAnimation)];
	self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 66, self.view.frame.size.width, self.view.frame.size.height);
	[UIView commitAnimations];
}

- (void)persentCleanAnimation {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration * 0.35f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(dialogCleanAnimationStop)];
	self.view.frame = CGRectMake(self.view.frame.origin.x, -self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
	[UIView commitAnimations];
}

- (void)dialogCleanAnimationStop {
	//NSLog(@"%s - modalBackground:%@", __FUNCTION__, [modalBackgroundView description]);
	//NSLog(@"%s - retainCount:%d", __FUNCTION__, [modalBackgroundView retainCount]);
	
    if (self.isInWindow) {
        //清理所有观察者
        [self removeObservers];
    }
	
	//关闭主窗口
	if (self.view && [self.view isKindOfClass:[UIView class]] && self.view.superview != nil) {
		[self.view removeFromSuperview];
	}
	
	//执行关闭前方法
	[self didDialogClose];
	self.loadOver = YES;
	//释放自己
	[self release];
	// self = nil;
}

- (void)didDialogClose {
	//请在子类中重写，相当于viewdidunload
}

- (IBAction)closeKeyBoard {
	//smLog(@"keyBoardNeedClose!!!");
	//需要在子类中重写本方法
}

#pragma mark - Orientation Method

- (BOOL)shouldRotateToOrientation:(UIDeviceOrientation)orientation {
    if (self.isInWindow) {
        if (orientation == privateOrientation) {
            return NO;
        } else {
            return orientation == UIDeviceOrientationLandscapeLeft 
            || orientation == UIDeviceOrientationLandscapeRight
            || orientation == UIDeviceOrientationPortrait
            || orientation == UIDeviceOrientationPortraitUpsideDown;
        }
    } else {
       return NO; 
    }
}

- (CGAffineTransform)transformForOrientation {
    if (self.isInWindow) {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            return CGAffineTransformMakeRotation(M_PI * 1.5f);
        } else if (orientation == UIInterfaceOrientationLandscapeRight) {
            return CGAffineTransformMakeRotation(M_PI * 0.5f);
        } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            return CGAffineTransformMakeRotation(-M_PI);
        }
    }
    return CGAffineTransformIdentity;
}

- (void)sizeToFitOrientation:(BOOL)transform {
	if (transform) {
		self.view.transform = CGAffineTransformIdentity;
	}
	
	self.privateOrientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
    CGRect frame =[UIScreen mainScreen].applicationFrame;
	CGPoint center = CGPointMake(
								 frame.origin.x + ceil(frame.size.width/2),
								 frame.origin.y + ceil(frame.size.height/2));
    
	self.view.center = center;
	
	if (transform) {
		self.view.transform = [self transformForOrientation];
	}
}

- (void)deviceOrientationDidChange:(void*)object {
    UIDeviceOrientation orientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
    if ([self shouldRotateToOrientation:orientation]) {
        CGFloat duration = 0.6f;//[UIApplication sharedApplication].statusBarOrientationAnimationDuration;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        [self sizeToFitOrientation:YES];
        [UIView commitAnimations];
    }
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}

- (id)getRootViewController {
    return [SystemUtils getAbsoluteRootViewController];
    /*
	UIResponder *nextResponder = [[CCDirector sharedDirector].openGLView nextResponder];
	if ([nextResponder isKindOfClass:[UIViewController class]]) {
		return (UIViewController *)nextResponder;
	}
	return nil;
     */
}

@end
