//
//  SNSWebWindow.h
//  TapCar
//
//  Created by Jie Yang on 12/13/11.
//  Copyright (c) 2011 topgame.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "smPopupWindowBase.h"

@interface SNSWebWindow : smPopupWindowBase {
	
@private
	NSString *				m_title;
	NSString *				m_closeButtonTitle;
	NSString *				m_webViewUrl;
}

@property (nonatomic, retain) IBOutlet UINavigationItem *titleContent;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *closeButton;
@property (nonatomic, retain) IBOutlet UIWebView *webView;

- (id) initWithUrl:(NSString *)url title:(NSString *)title closeButtonTitle:(NSString *)closeButtonTitle;

@end
