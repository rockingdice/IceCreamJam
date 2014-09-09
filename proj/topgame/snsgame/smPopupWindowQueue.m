//
//  smWindowQueue.m
//  iPetHotel
//
//  Created by yang jie on 20/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import "smPopupWindowQueue.h"
#import "smPopupWindowBase.h"
// #import "cocos2d.h"

@implementation smPopupWindowQueue
@synthesize queue, mainView;

static smPopupWindowQueue *sinleton = nil;

+ (id) createQueue {
    @synchronized(self) {
        if (sinleton == nil) {
            sinleton = [[self alloc] init];
        }
    }
    return sinleton;
}

- (id) init {
    self = [super init];
    if (self) {
        queueWasRun = NO;
        queue = [[NSMutableArray alloc] init];
    }
    return self; 
}

- (void) pushToQueue:(smPopupWindowBase *)theView
{
    theView.delegate = self;
	theView.timeOut = 0;
    [queue addObject:theView];
	[self showNextWindow];
}

- (void) pushToQueueWithDelay:(smPopupWindowBase *)theView
{
	[self pushToQueue:theView];
	[theView release];
}


// 添加窗口对象到窗口队列
- (void) pushToQueue:(smPopupWindowBase *)theView timeOut:(float)seconds {
    NSAssert([theView isKindOfClass:[smPopupWindowBase class]],@"theView must be a smWindowQueueBase subClass");
    //NSAssert((theView == nil),@"ViewController can not be nil");
	if(seconds<0.1f) [self pushToQueue:theView];
	else {
		[theView retain];
		[self performSelector:@selector(pushToQueueWithDelay:) withObject:theView afterDelay:seconds];
	}
}


- (void) winWasClose {
    //delete method
    [self removeFromQueue];
}

// 显示下一个窗口
- (void) showNextWindow {
	if(queueWasRun) return;
    if ([queue count] > 0) {
        if(![SystemUtils getInterruptMode]) {
            // 延迟5秒再显示
            [self performSelector:@selector(showNextWindow) withObject:nil afterDelay:5.0f];
            return;
        }
        int i = 0;
        while(i<[queue count]) {
            m_currentWindow = [queue objectAtIndex:i];
            if([m_currentWindow isReadyToShow]) break;
            i++;
        }
        if(i>=[queue count]) {
            // 所有的窗口都没有准备好，延迟5秒再说
            [self performSelector:@selector(showNextWindow) withObject:nil afterDelay:5.0f];
            return;
        }
		[m_currentWindow performSelectorOnMainThread:@selector(showHard) withObject:nil waitUntilDone:NO];
		queueWasRun = YES;
    }
}

// 显示下一个窗口, 保留以兼容旧代码
- (void) runAction {
	[self showNextWindow];
}

- (void)showObj {
	if(m_currentWindow) [m_currentWindow showHard];
}

- (void) removeFromQueue
{
    SNSLog(@"%s queue count:%i", __FUNCTION__, [queue count]);
	for(int i=0;i<[queue count];i++)
	{
		if (m_currentWindow == [queue objectAtIndex:i]) {
			[queue removeObjectAtIndex:i]; break;
		}
	}
	m_currentWindow = nil;
    queueWasRun = NO;
    //如果列队中还有没弹出的窗口，那么继续
	[self showNextWindow];
}

- (void) dealloc
{
	m_currentWindow = nil;
    self.queue = nil;
    self.mainView = nil;
	sinleton = nil;
    [super dealloc];
}

- (int)  queueCount
{
    return [queue count];
}

@end
