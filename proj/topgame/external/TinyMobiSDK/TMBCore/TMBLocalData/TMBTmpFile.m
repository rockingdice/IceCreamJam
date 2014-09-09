//
//  TMBTmpFile.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-17.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import "TMBTmpFile.h"

#import "TMBLog.h"

@implementation TMBTmpFile

+(NSString *)getFile: (NSString *)fileName
{
    if([fileName length] < 1){
        return nil;
    }
    //get tmp path
    NSString *homeDirectory = NSHomeDirectory();\
    NSString *tmpDirectory = [homeDirectory stringByAppendingPathComponent:@"tmp"];
    if (!tmpDirectory) {
        [TMBLog log:@"TMP" :@"Documents directory not found!"];
        return nil;
    }else {
        NSString *appFile = [tmpDirectory stringByAppendingPathComponent:fileName];
        return appFile;
    }
}

+(BOOL) saveData: (NSString *) data InFile: (NSString *)fileName
{
    NSString *appFile = [self getFile:fileName];
    if(appFile == nil){
        return FALSE;
    }else {
        NSFileManager *fileManage = [NSFileManager defaultManager]; 
        if(![fileManage fileExistsAtPath:appFile]){
            [fileManage createFileAtPath:appFile contents:nil attributes:nil];
        }
        return [data writeToFile:appFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

+(NSString *) readDataInFile: (NSString *)fileName
{
    NSString *appFile = [self getFile:fileName];
    if(appFile == nil){
        return nil;
    }else {
        if([[NSFileManager defaultManager] fileExistsAtPath:appFile]){
            return [NSString stringWithContentsOfFile:appFile encoding:NSUTF8StringEncoding error:nil];
        }else{
            return nil;
        }
    }
}

@end
