//
//  TapCar
//
//  Created by XU LE on 12-1-3.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#import "PlayHavenHelper.h"
#import "SystemUtils.h"
#import "PlayHavenSDK.h"
#import "SNSAlertView.h"
#import "smPopupWindowQueue.h"

@implementation PlayHavenHelper

static PlayHavenHelper *_gPlayHavenHelper = nil;

+ (PlayHavenHelper *) helper
{
    if(!_gPlayHavenHelper) {
        _gPlayHavenHelper = [[PlayHavenHelper alloc] init];
    }
    return _gPlayHavenHelper;
}

- (id) init
{
    self = [super init];
    if(self) {
        isInitialized = NO;
        isEnabled = NO;
        hasOffer  = NO;
        offerRequest = nil;
        hasFeatureApp = NO; featureRequest = nil;
    }
    return self;
}

- (void) dealloc
{
    SNSReleaseObj(m_phSecret);
    SNSReleaseObj(m_phToken);
    if(offerRequest!=nil) {
        [offerRequest release]; offerRequest = nil;
    }
    if(featureRequest!=nil) {
        [featureRequest release]; featureRequest = nil;
    }
    [super dealloc];
}

- (void) initSession
{
    if(isInitialized) return;
    isInitialized = YES;
    
    NSString *phToken = [SystemUtils getGlobalSetting:@"kPlayHavenToken"];
    NSString *phSecret = [SystemUtils getGlobalSetting:@"kPlayHavenSecret"];
    if(phToken==nil || phSecret==nil || [phToken length]<3 || [phSecret length]<3) {
        phToken = [SystemUtils getSystemInfo:@"kPlayHavenToken"];
        phSecret = [SystemUtils getSystemInfo:@"kPlayHavenSecret"];
    }
    if(phToken && phSecret && [phToken length]>10 && [phSecret length]>10) {
        [[PHPublisherOpenRequest requestForApp:phToken secret:phSecret] send];
        isEnabled = YES;
        m_phToken  = [phToken retain];
        m_phSecret = [phSecret retain];
        
        [self loadOffer]; [self loadFeaturedApp];
    }
}

- (void) loadOffer
{
    hasOffer = NO;
    PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:m_phToken secret:m_phSecret placement:@"more_games" delegate:self];
    [request preload];
    if(offerRequest !=nil ) [offerRequest release];
    offerRequest = [request retain];
}

- (void) loadFeaturedApp
{
    hasFeatureApp = NO;
    PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:m_phToken secret:m_phSecret placement:@"game_launch" delegate:self];
    [request preload];
    if(featureRequest !=nil ) [featureRequest release];
    featureRequest = [request retain];
}

- (BOOL) showOffer:(BOOL)showNoOfferHint
{
    if(!isInitialized) 
        [self initSession];
    SNSLog(@"isEnabled:%i interruptMode:%i hasOffer:%i", isEnabled, [SystemUtils getInterruptMode], hasOffer);
    if(!isEnabled || ![SystemUtils getInterruptMode]) {
        if(showNoOfferHint) {
            // TODO: show no offer hint
            SNSAlertView *av = [[SNSAlertView alloc] 
                                initWithTitle:[SystemUtils getLocalizedString: @"No Offer Now"]
                                message:[SystemUtils getLocalizedString: @"There's no free offer now, please try again later!"]
                                delegate:nil
                                cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                                otherButtonTitle: nil];
            
            av.tag = kTagAlertNone;
            [av showHard];
            [av release];
        }
        return NO;
    }
    if(!hasOffer) return NO;
    
    [offerRequest send];
    return YES;
}

- (BOOL) showFeaturedApp
{
    if(!isInitialized)
        [self initSession];
    if(!isEnabled || ![SystemUtils getInterruptMode]) return NO;
    if(!hasFeatureApp) return NO;
    
    [featureRequest send];
    return YES;
}


#pragma mark PHPublisherContentRequestDelegate


/**
 * A request is being sent to the API. Only sent for the first content unit
 * for a given request
 *
 * @param request
 *   The request
 **/
- (void)requestWillGetContent:(PHPublisherContentRequest *)request
{
    
}

/**
 * A response containing a valid content unit was received from the API. Only
 * sent for the first content unit for a given request
 *
 * @param request
 *   The request
 **/
- (void)requestDidGetContent:(PHPublisherContentRequest *)request
{
    if(request==offerRequest)
        hasOffer = YES;
    if(request==featureRequest)
        hasFeatureApp = YES;
    SNSLog(@"hasOffer:%d hasFeatureApp:%d", hasOffer, hasFeatureApp);
}

/**
 * The first content unit in the session is about to be shown
 *
 * @param request
 *   The request
 *
 * @param content
 *   The content
 **/
- (void)request:(PHPublisherContentRequest *)request contentWillDisplay:(PHContent *)content
{
    [SystemUtils setInterruptMode:NO];
    
}

/**
 * The first content unit in the session has been displayed
 *
 * @param request
 *   The request
 *
 * @param content
 *   The content
 **/
- (void)request:(PHPublisherContentRequest *)request contentDidDisplay:(PHContent *)content
{
    
}


/**
 * The last content unit in the session has been dismissed. The \c type argument will
 * specify a specific \c PHPublisherContentDismissType
 *
 * @param request
 *   The request
 *
 * @param type
 *   The type
 **/
- (void)request:(PHPublisherContentRequest *)request contentDidDismissWithType:(PHPublisherContentDismissType *)type
{
    [SystemUtils setInterruptMode:YES];
    if(request==offerRequest)
        [self loadOffer];
    if(request==featureRequest)
        [self loadFeaturedApp];
}

#pragma mark - Content customization methods
/**
 * Customization delegate. Replace the default native close button image with
 * a custom image for the given button state. Images should be smaller than
 * 40x40 (screen coordinates)
 *
 * @param request
 *   The request
 *
 * @param state
 *   The UIControlState state
 *
 * @param content
 *   The content
 *
 * @return
 *   A custom close button image
 **/
// - (UIImage *)request:(PHPublisherContentRequest *)request closeButtonImageForControlState:(UIControlState)state content:(PHContent *)content;

/**
 * Customization delegate. Replace the default border color with a different
 * color for dialog-type content units.
 *
 * @param request
 *   The request
 *
 * @param content
 *   The content
 *
 * @return
 *   A new color for the border
 **/
// - (UIColor *)request:(PHPublisherContentRequest *)request borderColorForContent:(PHContent *)content;

#pragma mark - Reward unlocking methods
/**
 * A content unit delivers the reward specified in PHReward. Please consult
 * "Unlocking rewards with the SDK" in README.mdown for more information on
 * how to implement this delegate method.
 *
 * @param request
 *   The request
 *
 * @param content
 *   The content
 **/
// - (void)request:(PHPublisherContentRequest *)request unlockedReward:(PHReward *)reward;

#pragma mark - Purchase unlocking methods
/**
 * A content unit is initiating an IAP transaction. Please consult
 * "Triggering in-app purchases" in README.mdown for more information on
 * how to implement this delegate method.
 *
 * @param request
 *   The request
 *
 * @param purchase
 *   The purchase
 **/
// - (void)request:(PHPublisherContentRequest *)request makePurchase:(PHPurchase *)purchase;

#pragma mark -


@end
