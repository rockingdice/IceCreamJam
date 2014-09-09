//
//  TMBJob.h
//  TMBDemo
//
//  Created by 高 峰 on 13-3-7.
//
//

@interface TMBJob : NSObject

+ (void) addJobQueueWithTarget:(id)target selectot:(SEL)sel object:(id)arg;

+ (void) addCacheQueueWithTarget:(id)target selectot:(SEL)sel object:(id)arg;

@end
