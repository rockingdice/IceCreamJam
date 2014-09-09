//
//  HelloWorldLayer.m
//  iPetHotel
//
//  Created by wei xia on 11-5-17.
//  Copyright snsgame 2011. All rights reserved.
//

// Import the interfaces
#import "AdOfferScene.h"
#import "CCBReader.h"
#import "CGameScene.h"
#import "TapjoyConnect.h"
#import "FlurryHelper.h"
#import "AudioPlayer.h"
#import "AdColonyHelper.h"

// HelloWorld implementation
@implementation AdOfferScene

+(id) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	AdOfferScene *layer = [AdOfferScene node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}
// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) {
		[self initSceneUI];
	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

- (void) initSceneUI
{
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	CCNode* myNode = [CCBReader nodeGraphFromFile:@"AdOfferScene.ccb" owner:self];
	[self addChild:myNode];
	if(size.width>320) {
		// iPad
		// CGSize mySize = myNode.contentSize;
		myNode.position = ccp((size.width-320)/2, (size.height-480)/2);
	}
	
	// add menu
	[CCMenuItemFont setFontName:@"Arial"];
	[CCMenuItemFont setFontSize:14];
	
	CCMenuItemFont *btnTapjoyOffer = [CCMenuItemFont itemFromString:[SystemUtils getLocalizedString:@"Free Leaves"] 
														target:self selector:@selector(onShowTapjoyOffer:)];
	CCMenuItemFont *btnFlurryOffer = [CCMenuItemFont itemFromString:[SystemUtils getLocalizedString:@"Free Coins"] 
														target:self selector:@selector(onShowFlurryOffer:)];
	CCMenuItemFont *btnFlurryVideo = [CCMenuItemFont itemFromString:[SystemUtils getLocalizedString:@"Watch Video for Coins"] 
														target:self selector:@selector(onShowFlurryVideo:)];
	CCMenuItemFont *btnAdColonyVideo = [CCMenuItemFont itemFromString:[SystemUtils getLocalizedString:@"Watch Video for Leaves"] 
															 target:self selector:@selector(onShowAdColonyVideo:)];
	
	
	btnTapjoyOffer.color = ccc3(74, 41, 28);
	btnFlurryOffer.color = ccc3(74, 41, 28);		
	btnFlurryVideo.color = ccc3(74, 41, 28);		
	btnAdColonyVideo.color = ccc3(74, 41, 28);		
	
	CCMenu* menu = [CCMenu menuWithItems:btnTapjoyOffer, btnFlurryOffer, btnFlurryVideo, btnAdColonyVideo, nil];
	[self addChild:menu];
	menu.position = ccp(0,0);
	
	// set position
	btnTapjoyOffer.position = ccp(size.width/2, size.height/2+30);
	btnFlurryOffer.position = ccp(size.width/2, size.height/2);
	btnFlurryVideo.position = ccp(size.width/2, size.height/2-30);
	btnAdColonyVideo.position = ccp(size.width/2, size.height/2-60);
	
	// init adColony
	[[AdColonyHelper helper] initSession];
}

- (void) onBtnClose:(id)sender
{
	[[CGameScene gameScene] backToGameScene];
	[[AudioPlayer sharedPlayer] playEffect:kEffect_Button];
	[self.parent removeChild:self cleanup:YES];
}

- (void) onShowTapjoyOffer:(id)sender
{
	[TapjoyConnect showOffers];
}

- (void) onShowFlurryOffer:(id)sender
{
	[FlurryHelper showOffers];
}

- (void) onShowFlurryVideo:(id)sender
{
	[FlurryHelper showVideoOffer];
}

- (void) onShowAdColonyVideo:(id)sender
{
	[[AdColonyHelper helper] showOffers];
}


@end
