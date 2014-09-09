//
//  HelloWorldLayer.h
//  iPetHotel
//
//  Created by wei xia on 11-5-17.
//  Copyright snsgame 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// HelloWorld Layer
@interface AdOfferScene : CCLayer
{
}

// returns a Scene that contains the HelloWorld as the only child
+(id) scene;

- (void) initSceneUI;

- (void) onBtnClose:(id)sender;

- (void) onShowTapjoyOffer:(id)sender;
- (void) onShowFlurryOffer:(id)sender;
- (void) onShowFlurryVideo:(id)sender;
- (void) onShowAdColonyVideo:(id)sender;


@end
