//
//  CConfigFIle.h
//  iPetHotel
//
//  Created by wei xia on 11-5-27.
//  Copyright 2011 snsgame. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CSVFileRead : NSObject {

}


+(NSMutableDictionary*)readFile:(NSString*)fileName;
//按文件字段的排列顺序返回指定字段值的数组
+(NSMutableArray*)readFile:(NSString*)fileName fieldName:(NSString*)fieldName;
//得到包含所有行数据字符串的数组
+(NSMutableArray*)getRowArrayWithFile:(NSString*)fileName;
//得到字段数据
+(NSDictionary*) getDataForDic:(NSMutableDictionary*)dic GID:(NSString*)gid;


@end
