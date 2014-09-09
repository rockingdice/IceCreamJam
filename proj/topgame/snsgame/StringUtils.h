//
//  StringUtils.h
//  WanyaClient
//
//  Created by LEON on 11-6-5.
//  Copyright 2011 FreeApper.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>


@interface StringUtils : NSObject {

}

// 转换mysql可以存储的字符串：对于非ASCII字符，采用base64存储
+(NSString *)convertToMysqlString:(NSString *)input;
+(NSString *)convertFromMysqlString:(NSString *)input;

+(NSString *)stringByUrlEncodingString:(NSString *)input;
+(NSString *)stringByUrlDecodingString:(NSString *)input;

+(NSString *)stringByHashingDataWithSHA1:(NSData *)input;
+(NSString *)stringByHashingStringWithSHA1:(NSString *)input;

+(NSString *)stringByHashingDataWithMD5:(NSData *)input;
+(NSString *)stringByHashingStringWithMD5:(NSString *)input;
// 转换字符串为日期，支持的格式2010-02-01 16:20:30
+(NSDate *)convertStringToDate:(NSString *)str;
// 转换日期为字符串
+(NSString *)convertDateToString:(NSDate*)date;
// 转换日期为字符串，按格式来, yyyy-mm-dd HH:MM:SS
+(NSString *)convertDateToString:(NSDate*)date withFormat:(NSString *)fmt;

// 获得一个名词的复数形式
+ (NSString *)getPluralFormOfWord:(NSString *)word;
// 获得数量＋名词组合文字
+ (NSString *)getTextOfNum:(int)num Word:(NSString *)word;
// 获得英文首字母大写词语
+ (NSString *)getCapitalizeWord:(NSString *)word;

// 解析query参数为一个Dictionary：p1=v1&p2=v2&p3=v3 => {"p1":"v1","p2":"v2","p3":"v3"}
+ (NSDictionary *)parseURLQueryStringToDictionary:(NSString *)query;

+ (NSDictionary*)parseURLParams:(NSString *)query;

// 返回NSData的16进制字节形式
+ (NSString*)hexRepresentationOfNSData:(NSData *)data;

// 检查一个数组里是否包含某个字符串
+ (BOOL) stringArrayExists:(NSArray *)arr keyword:(NSString *)key;

// JSON转换
+ (id) convertJSONStringToObject:(NSString *)str;
+ (NSString *)convertObjectToJSONString:(id)obj;

// B64转换
+ (NSString *) convertDataToBase64String:(NSData *)data;
+ (NSData *) convertBase64StringToData:(NSString *)str;

// tripleDES
+ (NSString *) TripleDES:(NSString *)plainText encryptOrDecrypt:(CCOperation)encryptOrDecrypt encryptOrDecryptKey:(const char *)encryptOrDecryptKey;

@end

@interface Base64 : NSObject {
	
}
+ (void) initialize;
+ (NSString*) encode:(const uint8_t*) input length:(NSInteger) length;
+ (NSString*) encode:(NSData*) rawBytes;
+ (NSData*) decode:(const char*) string length:(NSInteger) inputLength;
+ (NSData*) decode:(NSString*) string;
@end
