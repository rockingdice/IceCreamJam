//
//  TMBCre.h
//  TMBDemo
//
//  Created by 高 峰 on 13-2-28.
//
//
    
#import "TMBBaseClass.h"
#import "TMBCreDelegate.h"

@interface TMBCre : TMBBaseClass
{
    id<TMBCreDelegate> creDelegate;
}
@property(nonatomic, assign) id<TMBCreDelegate> creDelegate;

- (void) run:(NSURL *)command;

@end
