//
//  ProgressWindow.h
//  Colorme
//
//  Created by xiawei on 11-3-31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SnsLoadingView : UIView {
	UIActivityIndicatorView*   indicator;
	NSMutableArray *imageViewList;
	NSMutableArray *animationImageList;
    int hideLoadingHint;
}

- (void) show;
- (void) hide;
- (void)setTip:(NSString*)strTip;

- (void) loadImageViewList;
- (void) loadAnimationView;
- (void) loadAdvAnimationView:(NSString *)aniName;

// + (BOOL) isLoadingSceneExist;

- (void) onSetLoadingText:(NSNotification *)note;

@end
