//
//  smPopupWindowQueueDelegate.h
//  DreamTrain
//
//  Created by XU LE on 11-12-9.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol smPopupWindowQueueDelegate <NSObject>

@optional

//队列需要实现此协议，当窗口关闭时，继续列队下一个窗口
- (void) winWasClose;

// 检查目前是否可以显示
- (BOOL) isReadyToShow;

@end
