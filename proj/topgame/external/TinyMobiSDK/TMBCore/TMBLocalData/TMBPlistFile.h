//
//  TMBPlistFile.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-17.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

@interface TMBPlistFile : NSObject

+(BOOL) saveData: (NSDictionary *) data InFile: (NSString *)fileName;

+(NSDictionary *) readDataInFile: (NSString *)fileName;

@end
