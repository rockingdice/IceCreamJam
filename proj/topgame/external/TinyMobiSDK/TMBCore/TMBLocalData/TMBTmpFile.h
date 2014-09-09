//
//  TMBTmpFile.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-17.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

@interface TMBTmpFile : NSObject

+(BOOL) saveData: (NSString *) data InFile: (NSString *)fileName;

+(NSString *) readDataInFile: (NSString *)fileName;

@end
