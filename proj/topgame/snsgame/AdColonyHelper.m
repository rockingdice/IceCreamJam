//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//

#import "AdColonyHelper.h"
#import "SystemUtils.h"
#import "SNSAlertView.h"
#import "StringUtils.h"

static AdColonyHelper *_adColonyHelper = nil;

@implementation AdColonyHelper

@synthesize prizeGold;

+(AdColonyHelper *)helper
{
	@synchronized(self) {
		if(!_adColonyHelper) {
			_adColonyHelper = [[AdColonyHelper alloc] init];
		}
	}
	return _adColonyHelper;
}

-(id)init
{
	
	self = [super init];
	if(self != nil) {
		isSessionInitialized = NO; m_bShowHint = NO;
		prizeGold = 120; hasVideo = NO;
	}
	// A notification method must be set to retrieve the points.
	// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getUpdatedPoints:) name:TJC_TAP_POINTS_RESPONSE_NOTIFICATION object:nil];
	return self;
}

-(void)dealloc
{
	// if(pendingActions) [pendingActions release];
	// [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) setPrizeGold:(int)gold
{
	if(gold<10) gold = 10;
	prizeGold = gold;
}

-(void) initSession
{
	if(isSessionInitialized) return;
	isSessionInitialized = YES;
	
	[AdColony initAdColonyWithDelegate:self];	
}


-(BOOL) showOffers:(BOOL)showHint
{
	if(!isSessionInitialized) [self initSession];
	m_bShowHint = showHint;
	
	if(![[SystemUtils getGameDataDelegate] isTutorialFinished]) {
		[self showNoOfferHint];
		return NO;
	}
	
	int slot = 1;
	if(![AdColony virtualCurrencyAwardAvailableForSlot:slot]) { 
		//notify the user in your popup that the V4VC cap has been hit for today
		// no offers now
		[self showNoOfferHint];
		return NO;
	}
	if(!hasVideo) {
		[self showNoOfferHint];
		return NO;
	}
	//NSString* currencyName = [AdColony getVirtualCurrencyNameForSlot:slot]; 
	//int currencyAmount = [AdColony getVirtualCurrencyRewardAmountForSlot:slot];
	//[AdColony playVideoAdForSlot:1];
	[AdColony playVideoAdForSlot:slot withDelegate:self
				withV4VCPrePopup:NO andV4VCPostPopup:NO];
	return YES;
}

- (void) showNoOfferHint
{
	if(m_bShowHint) {
        SNSAlertView *av = [[SNSAlertView alloc] 
                            initWithTitle:[SystemUtils getLocalizedString:@"No Ad Available"]
                            message:[SystemUtils getLocalizedString:@"No ad is available now, please try again later."]
                            delegate:nil
                            cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                            otherButtonTitle: nil];
        
        av.tag = kTagAlertNone;
        [av showHard];
        [av release];
	}
	
}

#pragma mark AdColonyDelegate

-(NSString*)adColonyApplicationID{
	// if([SystemUtils isiPad] return @"app4e8aeb3e328b3";
	return [SystemUtils getSystemInfo:kAdColonyAppID]; // @"app4e8ae936df80b";
}

//use the zone numbers provided by adcolony.com
-(NSDictionary*)adColonyAdZoneNumberAssociation{ 
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[SystemUtils getSystemInfo:kAdColonyZoneID], [NSNumber numberWithInt:1], //video zone 1 
			// @"z4dc1bd434abc9", [NSNumber numberWithInt:2], //video zone 2 
			nil];
}


-(void)adColonyVirtualCurrencyAwardedByZone:(NSString *)zone currencyName:(NSString *) name currencyAmount:(int)amount {
	//Update virtual currency balance by contacting the game server here 
	//NOTE: The currency award transaction will be complete at this point 
	//NOTE: This callback can be executed by AdColony at any time 
	//NOTE: This is the ideal place for an alert about the successful reward
	NSLog(@"%s: currency:%@ amount:%i", __func__, name, amount);
	
	NSString *mesg = nil;
	NSString *iapCoinName  = [SystemUtils getLocalizedString:@"CoinName1"];
	NSString *iapLeafName  = [SystemUtils getLocalizedString:@"CoinName2"];
	if([name isEqualToString:@"Gold"]) {
		
		if(amount<10) amount = amount * prizeGold;
		
		[SystemUtils addGameResource:amount ofType:kGameResourceTypeCoin];
		if(amount>1) iapCoinName = [StringUtils getPluralFormOfWord:iapCoinName];
		
		[SystemUtils logResourceChange:kLogTypeEarnCoin method:kLogMethodTypeFreeOffer itemID:@"adcolony" count:amount];
		
		// [[GameData gameData] addCoines:amount];
        // [[AudioPlayer sharedPlayer] playEffect:kEffect_Coins];
		// show message
		mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Great, you just got %1$d %2$@ for watching advertizement!"], amount, iapCoinName];
	}
	else if([name isEqualToString:@"Leaves"]) {
		
		[SystemUtils addGameResource:amount ofType:kGameResourceTypeLeaf];
		if(amount>1) iapLeafName = [StringUtils getPluralFormOfWord:iapLeafName];
		
		[SystemUtils logResourceChange:kLogTypeEarnLeaf method:kLogMethodTypeFreeOffer itemID:@"adcolony" count:amount];
		
		// [[GameData gameData] addTreats:amount];
        // [[AudioPlayer sharedPlayer] playEffect:kEffect_Coins];
		mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Great, you just got %1$d %2$@ for watching advertizement!"], amount, iapLeafName];
	}
	if(!mesg) return;
    SNSAlertView *av = [[SNSAlertView alloc] 
                        initWithTitle:[SystemUtils getLocalizedString:@"Finish Watching Ad"]
                        message:mesg
                        delegate:nil
                        cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                        otherButtonTitle: nil];
    
    av.tag = kTagAlertNone;
    [av showHard];
    [av release];
	
}


-(void)adColonyVirtualCurrencyNotAwardedByZone:(NSString *)zone currencyName:(NSString *)name currencyAmount:(int)amount reason:(NSString *)reason{
	//Update the user interface after calling virtualCurrencyAwardAvailable here
	// show error hint
}

- (void) adColonyNoVideoFillInZone:(NSString *)zone
{
	// no video now
	NSLog(@"%s",__func__);
	hasVideo = NO;
	// [self showNoOfferHint];
}

- (void) adColonyVideoAdsReadyInZone:(NSString *)zone
{
	// video is ready
	hasVideo = YES;
	NSLog(@"%s",__func__);
}

- (void) adColonyVideoAdsNotReadyInZone:(NSString *)zone
{
	// no video now
	NSLog(@"%s",__func__);
	hasVideo = NO;
	// [self showNoOfferHint];
}

#pragma mark -

#pragma mark AdColonyTakeoverAdDelegate

- (void) adColonyTakeoverBeganForZone:(NSString *)zone { 
	NSLog(@"AdColony video ad launched for zone %@", zone);
	//[[AudioPlayer sharedPlayer] pauseMusic];
	// [[CCDirector sharedDirector] pause];
	// [[SimpleAudioEngine sharedEngine] pauseBackgroundMusic];
	// [[AudioPlayer sharedPlayer] pauseMusic];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationPauseMusic object:nil userInfo:nil];
    
}

- (void) adColonyTakeoverEndedForZone:(NSString *)zone withVC:(BOOL)withVirtualCurrencyAward { 
	NSLog(@"AdColony video ad finished for zone %@", zone);
	//[[AudioPlayer sharedPlayer] resumeMusic];
	// [[CCDirector sharedDirector] resume];
	//[[AudioPlayer sharedPlayer] pauseMusic];
	//[[SimpleAudioEngine sharedEngine] resumeBackgroundMusic];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationResumeMusic object:nil userInfo:nil];
}

- (void) adColonyVideoAdNotServedForZone:(NSString *)zone { 
	NSLog(@"AdColony did not serve a video for zone %@", zone);
	[self showNoOfferHint];
}

#pragma mark -


@end
