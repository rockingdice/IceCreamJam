//
//  smWindowQueue.h
//  iPetHotel
//
//  Created by yang jie on 20/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import <Foundation/Foundation.h>

@class smPopupWindowBase;

@interface smPopupWindowQueue:NSObject {
    BOOL inAction, queueWasRun;
    smPopupWindowBase *m_currentWindow;
	NSMutableArray *queue;
}

@property (nonatomic, retain) NSMutableArray *queue;
@property (nonatomic, retain) UIView *mainView;

+ (id) createQueue;
- (void) pushToQueue:(smPopupWindowBase *)theView timeOut:(float)seconds;

- (void) showNextWindow;
- (void) runAction;
- (void) removeFromQueue;

- (void) showObj;
- (int)  queueCount;

// 当前显示的窗口关闭
- (void) winWasClose;
@end
