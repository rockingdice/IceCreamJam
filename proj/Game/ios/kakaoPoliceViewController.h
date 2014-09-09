//
//  kakaoPoliceViewController.h
//  JellyMania
//
//  Created by lipeng on 14-7-13.
//
//

#import <UIKit/UIKit.h>

@interface kakaoPoliceViewController : UIViewController
{
    UIWebView * m_webView;
}

- (void)showWithURL:(NSString *)url;
@end
