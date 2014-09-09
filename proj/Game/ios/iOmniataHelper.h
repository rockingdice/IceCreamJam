//
//  iOmniataHelper.h
//  JellyMania
//
//  Created by lipeng on 14-5-29.
//
//

#import <Foundation/Foundation.h>
#import <iOmniataAPI/iOmniataAPI.h>
@interface iOmniataHelper : NSObject

+ (iOmniataHelper *) helper;
- (void)requestContent;
- (void)trackEvent:(NSDictionary *)dic;
- (void)trackPurchaseEvent:(double)amount currency_code:(NSString *)currency_code additional_params:(NSDictionary*)additional_params;
@end
