//
//  TMBAdStore.m
//  TMBDemo
//
//  Created by 高 峰 on 13-3-5.
//
//

#import "TMBAdStore.h"
#import "TMBLog.h"
#import "TMBNetWork.h"

#ifdef __IPHONE_6_0
#import <StoreKit/StoreKit.h>

static TMBBaseAd *_sharedAd = nil;

@interface TMBAdStore () <SKStoreProductViewControllerDelegate>
@end
#endif

@implementation TMBAdStore

+ (TMBBaseAd *) sharedAd
{
    if(!_sharedAd)
	{
        TMBBaseAd *adObj = [[self alloc] init];
        _sharedAd = adObj;
	}
	return _sharedAd;
}

#ifdef __IPHONE_6_0

- (BOOL) isShow
{
    return adView && [(UIViewController *)adView isViewLoaded];
}

- (void) storeShow
{
    if (NSClassFromString(@"SKStoreProductViewController")) {
        [self setAdView:[[[NSClassFromString(@"SKStoreProductViewController") alloc] init]autorelease]];
        [self.adView setDelegate:self];
        [TMBLog log:@"AD" :[NSString stringWithFormat:@"%@ %@", [self class], @"SHOW"]];
        [self setFatherViewController:nil];
        
        if ([self.fvc respondsToSelector:@selector(isBeingDismissed)]) {
            if ([self.fvc performSelector:@selector(isBeingDismissed)] || [self.fvc performSelector:@selector(isMovingFromParentViewController)]) {
                [self performSelector:@selector(show) withObject:nil afterDelay:1];
                return;
            }
        }
        if ([self.fvc respondsToSelector:@selector(presentViewController:animated:completion:)]) {
            [self.fvc presentViewController:(UIViewController *)self.adView animated:NO completion:^(void){
                return;
            }];
        }else{
            [self.fvc presentModalViewController:(UIViewController *)self.adView animated:NO];
        }
    }
}

- (void) storeLoad:(NSURL *)url
{
    if (url) {
        // 改为全部在浏览器打开
        [[UIApplication sharedApplication] openURL:url]; return;
        
        NSString *appID = @"";
        NSString *host = [[url host] lowercaseString];
        if([host isEqualToString:@"itunes.apple.com"] || [host isEqualToString:@"itunes.com"]
           || [host isEqualToString:@"phobos.apple.com"]){
            // try to find the appstore ID
            NSString *idStr = @"";
            NSRange r = [[url query] rangeOfString:@"id="];
            if(r.location != NSNotFound){
                idStr = [url query];
            }else{
                r = [[url path] rangeOfString:@"/id"];
                if(r.location != NSNotFound) {
                    idStr = [url path];
                }
            }
            if ([idStr length] > 0) {
                char buf[21];
                int i=0;
                int offset = r.location+r.length;
                char ch = [idStr characterAtIndex:offset];
                while (ch>='0' && ch<='9') {
                    buf[i++] = ch;
                    offset++;
                    if(offset>=[idStr length] || i>=20) break;
                    ch = [idStr characterAtIndex:offset];
                }
                if(i>0) {
                    buf[i] = '\0';
                    appID = [NSString stringWithCString:buf encoding:NSASCIIStringEncoding];
                }
            }
        }
        if ([appID length] > 0) {
            if (!adView || ![(UIViewController *)adView isViewLoaded]) {
                [self storeShow];
            }
            if (adView && [adView isKindOfClass:[SKStoreProductViewController class]]) {
                NSDictionary *productParameters = @{SKStoreProductParameterITunesItemIdentifier : appID};
                [(SKStoreProductViewController *)adView loadProductWithParameters:productParameters completionBlock:^(BOOL result, NSError *error) {
                    if (!result) {
                        [TMBLog log:@"STORE ERROR" :[NSString stringWithFormat:@"%@,%@,%@", error, appID, url]];
                    }
                }];
            }else{
               [[UIApplication sharedApplication] openURL:url]; 
            }
        }else{
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (void) showRealUrl:(NSURL *)serverUrl
{
    NSString *infostr = [NSString stringWithContentsOfURL:serverUrl encoding:NSUTF8StringEncoding error:nil];
    [TMBLog log:@"REAL INSTALL URL" :infostr];
    if (infostr && [infostr length]>0) {
        NSDictionary *info = [TMBNetWork decodeServerJsonResult:infostr];
        if (info && [info valueForKey:@"url"]) {
            [self storeLoad:[NSURL URLWithString:[info valueForKey:@"url"]]];
        }
    }
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [self close];
}

- (void) show
{
    
    if (adArgs && [adArgs valueForKey:@"url"]!=[NSNull null]) {
        NSString *link = [adArgs valueForKey:@"url"];
        NSURL *url = [NSURL URLWithString:link];
        //tinymobi link
        if ([link rangeOfString:[TMBNetWork host]].location != NSNotFound) {
            [self storeShow];
            [self performSelector:@selector(showRealUrl:) withObject:url afterDelay:1];
        }else{
            [self storeLoad:url];
        }
    }
    
}

#else

- (BOOL) isShow
{
    return FALSE;
}

- (void) show
{
    
    if (adArgs && [adArgs valueForKey:@"url"]!=[NSNull null]) {
        NSString *link = [adArgs valueForKey:@"url"];
        NSURL *url = [NSURL URLWithString:link];
        [[UIApplication sharedApplication] openURL:url];
    }
    
}

#endif

- (void) close
{
    if (adView) {
        [adView dismissViewControllerAnimated:NO completion:^(void){
            return;
        }];
    }
}

- (BOOL) isReady
{
    return TRUE;
}

@end
