//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import "GreystripeHelper.h"
#import "SystemUtils.h"
#import "GSAdEngine.h"
#import "SNSAlertView.h"
// #import "cocos2d.h"
// #import "ZFGuiLayer.h"
// #import "SimpleAudioEngine.h"
// #import "GameState.h"
// #import "ZFSoundIDs.h"


static GreystripeHelper *_adGreystripeHelper = nil;

@implementation GreystripeHelper


+(GreystripeHelper *)helper
{
	@synchronized(self) {
		if(!_adGreystripeHelper) {
			_adGreystripeHelper = [[GreystripeHelper alloc] init];
		}
	}
	return _adGreystripeHelper;
}

-(id)init
{
	
	if(self = [super init]) {
		isSessionInitialized = NO; m_bShowHint = NO; hasPopupOffer = NO; isShowingOffer = NO;
	}
	// A notification method must be set to retrieve the points.
	// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getUpdatedPoints:) name:TJC_TAP_POINTS_RESPONSE_NOTIFICATION object:nil];
	return self;
}

-(void)dealloc
{
    if(myAdView) {
        [myAdView release]; myAdView = nil;
    }
	// if(pendingActions) [pendingActions release];
	// [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(void) initSession
{
	if(isSessionInitialized) return;
	isSessionInitialized = YES;
	
    if([SystemUtils isiPad]) return;
    
	//Define two ad slots. Name them and give the sizes as one banner and one fullscreen.
	GSAdSlotDescription * slot1 = [GSAdSlotDescription descriptionWithSize:kGSAdSizeBanner name:@"bannerSlot"];
	GSAdSlotDescription * slot2 = [GSAdSlotDescription descriptionWithSize:kGSAdSizeIPhoneFullScreen name:@"fullscreenSlot"];
	
	//IMPORTANT: The application ID used here is for DEMO PURPOSES ONLY. You must register your application to receive your own unique AppID. 
	//YOU WILL NOT BE PAID FOR ANY IMPRESSIONS SHOWN USING THE DEMO APP ID.
	NSString *applicationID = [SystemUtils getSystemInfo:@"kGreystripeAppID"]; // @"08c9c763-9167-4d5e-886e-8af786ceff27";
	
	//Start the GSAdEngine with our slots.
	[GSAdEngine startupWithAppID:applicationID adSlotDescriptions:[NSArray arrayWithObjects:slot1, slot2, nil]];
	
	//Use the .version property to check that the latest SDK is included
	NSLog(@"GSAdEngine is loaded with version %@",GSAdEngine.version);
	
	//Initialize the banner AdView from the banner ad slot. 
	//Set this view controller as the delegate, and have the SDK refresh the ad after the default time interval of 5 sec.
	// myAdView = [[GSAdView adViewForSlotNamed:@"bannerSlot" delegate:self refreshInterval:kGSMinimumRefreshInterval] retain];
	
	//Set this view controller as the delegate for our fullscreen ad as well.
	[GSAdEngine setFullScreenDelegate:self forSlotNamed:@"fullscreenSlot"];
	
    
	// [AdColony initAdColonyWithDelegate:self];	
}


-(BOOL) showOffers:(BOOL)showHint
{
    if(![SystemUtils checkFeature:kFeatureGreystripe]) return NO;
    if([SystemUtils isiPad]) return NO;
    if(![SystemUtils getInterruptMode]) return NO;
	m_bShowHint = showHint;
	[self initSession];
	if (!hasPopupOffer || ![GSAdEngine isAdReadyForSlotNamed:@"fullscreenSlot"]) {
		//notify the user in your popup that the V4VC cap has been hit for today
		// no offers now
		[self showNoOfferHint];
		return NO;
	}
    [GSAdEngine displayFullScreenAdForSlotNamed:@"fullscreenSlot"];
    isShowingOffer = YES;
	return YES;
}

- (void) hideOffers
{
    if(isShowingOffer) {
        GSAdView *view = [GSAdView adViewForSlotNamed:@"fullscreenSlot" delegate:self];
        if(view) {
            SNSLog(@"hidding greystripe view %@", view);
            [view removeFromSuperview];
        }
    }
}

- (void) showNoOfferHint
{
	if(m_bShowHint) {
		SNSAlertView *alert = [[SNSAlertView alloc] 
                               initWithTitle:[SystemUtils getLocalizedString:@"No Video Now"] 
                               message:[SystemUtils getLocalizedString:@"No video is ready now, please try again later."] 
                               delegate:nil 
                               cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"] 
                               otherButtonTitle:nil];
                               /*
                                initWithTitle: [SystemUtils getLocalizedString:@"No Video Now"]
                                message:[SystemUtils getLocalizedString:@"No video is ready now, please try again later."]
                                delegate:nil 
                                cancelButtonTitle: [SystemUtils getLocalizedString:@"OK"]
                                otherButtonTitles:nil];
                                */
		[alert show];
		[alert release];
	}
	
}


#pragma mark GreyStripeDelegate

//Delegate method is called when an ad is ready to be displayed
- (void)greystripeAdReadyForSlotNamed:(NSString *)a_name
{
	NSLog(@"%s: Ad for slot named %@ is ready.", __func__, a_name);
	
	//Depending on which ad is ready, put the banner view into the view hiearchy, or enable the fullscreen ad button
	if ([a_name isEqual:@"fullscreenSlot"]) {
        // display it
        // [GSAdEngine displayFullScreenAdForSlotNamed:@"fullscreenSlot"];
        hasPopupOffer = YES;
	} else if ([a_name isEqual:@"bannerSlot"]) {
        // 
	}
} 


//Delegate methods for full screen or click-through open and close. This is the place to suspend/restart other app activity.
- (void)greystripeFullScreenDisplayWillOpen {
	NSLog(@"%s: Full screen ad is opening.", __func__);
}

- (void)greystripeFullScreenDisplayWillClose {
	NSLog(@"%s: Full screen ad is closing.", __func__);
    isShowingOffer = NO;
}

#pragma mark -

@end
