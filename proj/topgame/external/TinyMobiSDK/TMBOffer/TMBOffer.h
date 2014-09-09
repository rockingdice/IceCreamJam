//
//  TMBOffer.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-9.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import "TMBBaseClass.h"

@interface TMBOffer : TMBBaseClass

-(NSArray *)offer;

-(BOOL)finish:(NSString *)offerIds;

@end
