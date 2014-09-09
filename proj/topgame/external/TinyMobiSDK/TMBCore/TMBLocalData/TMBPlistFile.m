//
//  TMBPlistFile.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-17.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import "TMBPlistFile.h"

#import "TMBLog.h"

@implementation TMBPlistFile

+(NSString *)getFile: (NSString *)fileName
{
    if([fileName length] < 1){
        return nil;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    if (!documentsDirectory) {
        [TMBLog log:@"PLIST" :@"Documents directory not found!"];
        return nil;
    }else {
        NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
        //[TMBLog log:@"PLIST" :appFile];
        return appFile;
    }
}

+(BOOL) saveData: (NSDictionary *) data InFile: (NSString *)fileName
{
    NSString *appFile = [self getFile:fileName];
    if(appFile == nil){
        return FALSE;
    }else {
        NSFileManager *fileManage = [NSFileManager defaultManager]; 
        if(![fileManage fileExistsAtPath:appFile]){
            [fileManage createFileAtPath:appFile contents:nil attributes:nil];
        }
        return [data writeToFile:appFile atomically:YES];
    }
}

+(NSDictionary *) readDataInFile: (NSString *)fileName
{
    NSString *appFile = [self getFile:fileName];
    if(appFile == nil){
        return nil;
    }else {
        if([[NSFileManager defaultManager] fileExistsAtPath:appFile]){
            return [NSDictionary dictionaryWithContentsOfFile:appFile];
        }else{
            return nil;
        }
    }
}

@end
