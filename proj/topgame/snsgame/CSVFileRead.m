//
//  CConfigFIle.m
//  iPetHotel
//
//  Created by wei xia on 11-5-27.
//  Copyright 2011 snsgame. All rights reserved.
//

#import "CSVFileRead.h"
#import "SystemUtils.h"

@implementation CSVFileRead

+(NSMutableDictionary*)readFile:(NSString*)fileName{
	NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"csv"];
    if(!path || [fileName characterAtIndex:0]=='/') path = fileName;
    SNSLog(@"%s: path:%@",__func__,path);
	NSString *contents = [[NSString alloc] initWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
	
	NSArray *contentsArray = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	NSInteger idx;    
	
	NSMutableArray* currentDataArray = [[NSMutableArray alloc] init];
	
	for (idx = 0; idx < contentsArray.count; idx++) {
		
		NSString* currentContent = [contentsArray objectAtIndex:idx];
		if([currentContent length]>0){
			[currentDataArray addObject:currentContent];
		}
	}
	NSString *sepChars = @",";
	
	NSArray* titleDataArr = [(NSString*)[currentDataArray objectAtIndex:0] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:sepChars]];  //数据的字段名称
    if([titleDataArr count]==1) {
        sepChars = @";";
        titleDataArr = [(NSString*)[currentDataArray objectAtIndex:0] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:sepChars]];
    }
    if([titleDataArr count]==1) {
        sepChars = @"\t";
        titleDataArr = [(NSString*)[currentDataArray objectAtIndex:0] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:sepChars]];
    }
    
	NSMutableArray* gameObjectArray = [[NSMutableArray alloc] init];
	NSMutableArray* gameKeyArray = [[NSMutableArray alloc] init];
	idx = 1;
	for(;idx<[currentDataArray count];idx++){
		NSArray* objectData = [(NSString*)[currentDataArray objectAtIndex:idx] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:sepChars]];
		NSMutableArray* newObjectData = [[NSMutableArray alloc] init];
		for(NSString* str in objectData){
			str = [str stringByReplacingOccurrencesOfString:@"`" withString:sepChars];  //把" ` "字符替换成" ，"字符
			[newObjectData addObject:str];
		}
		NSDictionary* dataDic = [NSDictionary dictionaryWithObjects:newObjectData forKeys:titleDataArr];
		[gameObjectArray addObject:dataDic];
		[gameKeyArray addObject:[newObjectData objectAtIndex:0]];
		
		[newObjectData release];
		newObjectData = nil;
		objectData = nil;
	}
	
	NSMutableDictionary* resultDict = [[NSMutableDictionary alloc] initWithObjects:gameObjectArray forKeys:gameKeyArray];
	
	[currentDataArray release];
	currentDataArray = nil;
	[contents release];
	contents = nil;
	[gameObjectArray release];
	gameObjectArray = nil;
	[gameKeyArray release];
	gameKeyArray = nil;
    [resultDict autorelease];
    
	return resultDict ;
}
//按文件字段的排列顺序返回指定字段值的数组
+(NSMutableArray*)readFile:(NSString*)fileName fieldName:(NSString*)fieldName{
	NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"csv"];
	
	NSString *contents = [[NSString alloc] initWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
	
	NSArray *contentsArray = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	NSInteger idx;    
	
	NSMutableArray* currentDataArray = [[NSMutableArray alloc] init];
	
	for (idx = 0; idx < contentsArray.count; idx++) {
		
		NSString* currentContent = [contentsArray objectAtIndex:idx];
		if([currentContent length]>0){
			[currentDataArray addObject:currentContent];
		}
	}
	
	
	NSArray* titleDataArr = [(NSString*)[currentDataArray objectAtIndex:0] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];  //数据的字段名称
	
	int valueIndx = -1;
	for(int i=0;i<[titleDataArr count];i++){
		NSString* title = [titleDataArr objectAtIndex:i];
		if([title isEqualToString:fieldName]){
			valueIndx = i;
			break;
		}
	}
	NSMutableArray* resultDataArray = nil;
	if(valueIndx>=0){
		idx = 1;
		resultDataArray = [[NSMutableArray alloc] init];
		for(;idx<[currentDataArray count];idx++){
			NSArray* objectData = [(NSString*)[currentDataArray objectAtIndex:idx] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
			NSMutableArray* newObjectData = [[NSMutableArray alloc] init];
			for(NSString* str in objectData){
				str = [str stringByReplacingOccurrencesOfString:@"`" withString:@","];  //把" ` "字符替换成" ，"字符
				[newObjectData addObject:str];
			}
			
			[resultDataArray addObject:[newObjectData objectAtIndex:valueIndx]];
			
			[newObjectData release];
			newObjectData = nil;
			objectData = nil;
		}
	}
	[currentDataArray release];
	currentDataArray = nil;
	[contents release];
	contents = nil;
    [resultDataArray autorelease];
	return resultDataArray;
}
//得到包含行数据的数组
+(NSMutableArray*)getRowArrayWithFile:(NSString*)fileName{
	NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"csv"];
	
	NSString *contents = [[NSString alloc] initWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
	
	NSArray *contentsArray = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	NSInteger idx;    
	
	NSMutableArray* currentDataArray = [[NSMutableArray alloc] init];
	
	for (idx = 0; idx < contentsArray.count; idx++) {
		
		NSString* currentContent = [contentsArray objectAtIndex:idx];
		if([currentContent length]>0){
			[currentDataArray addObject:currentContent];
		}
	}
	[contents release];
	contents = nil;
    [currentDataArray autorelease];
    
	return currentDataArray;
	
}

+(NSDictionary*) getDataForDic:(NSMutableDictionary*)dic GID:(NSString*)gid
{
	return ([dic objectForKey:gid]);
}

@end

