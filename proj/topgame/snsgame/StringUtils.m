//
//  StringUtils.m
//  WanyaClient
//
//  Created by LEON on 11-6-5.
//  Copyright 2011 FreeApper.com. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

#import "StringUtils.h"
#import "NSString+Inflections.h"
#import "SystemUtils.h"
#import "SBJson.h"

@implementation StringUtils


// 转换mysql可以存储的字符串：对于非ASCII字符，采用base64存储
+(NSString *)convertToMysqlString:(NSString *)input
{
    if(input==nil || [input length]==0) return input;
    if([input length]==strlen([input UTF8String])) return input;
    const char *p = [input UTF8String];
    NSString *enc = [Base64 encode:p length:strlen(p)];
    return [NSString stringWithFormat:@"b64:%@",enc];
}
+(NSString *)convertFromMysqlString:(NSString *)input
{
    if(input==nil || [input length]<5) return input;
    NSString *prefix = [input substringToIndex:4];
    if(![prefix isEqualToString:@"b64:"]) return input;
    NSData *data = [Base64 decode:[input substringFromIndex:4]];
    NSString *st = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
    [st autorelease];
    return st;
}

+(NSString *)stringByUrlEncodingString:(NSString *)input
{
	if(!input) return nil;
	CFStringRef value = CFURLCreateStringByAddingPercentEscapes(
																kCFAllocatorDefault, 
																(CFStringRef) input,
																NULL,
																(CFStringRef) @"!*'();:@&=+$,/?%#[]",
																kCFStringEncodingUTF8);
	
	NSString *result = [NSString stringWithString:(NSString *)value];
	CFRelease(value);
	
	return result;
}

+(NSString *)stringByUrlDecodingString:(NSString *)input
{
    input = [input stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    return [input stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

/**
 * A function for parsing URL parameters.
 */
+ (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSRange r = [pair rangeOfString:@"="];
        if(r.location==NSNotFound) continue;
        NSString *key = [pair substringToIndex:r.location];
        NSString *val =
        [self stringByUrlDecodingString:[pair substringFromIndex:r.location+1]];
        
        [params setObject:val forKey:key];
    }
    [params autorelease];
    return params;
}

+(NSString *)stringByHashingDataWithSHA1:(NSData *)input
{
	if(!input) return nil;
	
	uint8_t digest[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(input.bytes, input.length, digest);
	
	NSData *digestData = [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
	
	const uint8_t *bytes = digestData.bytes;
	NSMutableString *result = [NSMutableString stringWithCapacity:2 * digestData.length];
	
	for (int i = 0; i < digestData.length; i++)
		[result appendFormat:@"%02x", bytes[i]];
	
	return result;
}

+(NSString *)stringByHashingStringWithSHA1:(NSString *)input
{
	if(!input) return nil;
	NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
	return [self stringByHashingDataWithSHA1:data];
}


+(NSString *)stringByHashingDataWithMD5:(NSData *)input
{
	if(!input) return nil;
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	// const char *src = [input bytes];
	CC_MD5([input bytes], [input length], digest);
	NSString *sig = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
					 digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7],
					 digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]];	
	return sig;
}

+(NSString *)stringByHashingStringWithMD5:(NSString *)input
{
	if(!input) return nil;
	NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
	return [self stringByHashingDataWithMD5:data];
}


+(NSDate *)convertStringToDate:(NSString *)str
{
    if(!str) return nil;
	NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-: "];
	NSArray *arr = [str componentsSeparatedByCharactersInSet:set];
	if(arr && [arr count]>=3)
	{
		int num = [arr count];
		NSString *str = nil; //[arr objectAtIndex:0];
		int year = 0;
		int mon = 1;
		int day = 1;
		int hour = 0; int min = 0; int sec = 0;
		int offset = 0; int val = 0;
		for(int i=0;i<num;i++)
		{
			str = [arr objectAtIndex:i];
			if([str length]==0) continue;
			if([str length]==2 && [str characterAtIndex:0]=='0') val = [str characterAtIndex:1]-'0';
			else val = [str intValue]; 
			if(offset==0) year = val;
			if(offset==1) mon = val;
			if(offset==2) day = val;
			if(offset==3) hour = val;
			if(offset==4) min = val;
			if(offset==5) sec = val;
			offset++;
		}
		if(year<1900) {
			if(year>70) year += 1900;
			else if(year<50) year += 2000;
		}
		
		NSCalendar *gregorian = [[NSCalendar alloc]
								 initWithCalendarIdentifier:NSGregorianCalendar];
		NSDateComponents *dateComp = [[NSDateComponents alloc] init];
		[dateComp setYear:year];
		[dateComp setMonth:mon];
		[dateComp setDay:day];
		[dateComp setMinute:min];
		[dateComp setSecond:sec];
		[dateComp setHour:hour];
		NSDate *dt = [gregorian dateFromComponents:dateComp];
		[dateComp autorelease]; [gregorian autorelease];
		return dt;
	}
	return nil;
}

// 转换日期为字符串
+(NSString *)convertDateToString:(NSDate*)date
{
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
	
	NSDateComponents *comp =
    [gregorian components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:date];
	NSString *mesg = [NSString stringWithFormat:@"%i-%i-%i %i:%i:%i", [comp year], [comp month], [comp day], [comp hour], [comp minute], [comp second]];
	[gregorian release];
	return mesg;
}

// 转换日期为字符串，按格式来, yyyy-mm-dd HH:MM:SS
+(NSString *)convertDateToString:(NSDate*)date withFormat:(NSString *)fmt
{
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
	
	NSDateComponents *comp =
    [gregorian components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:date];
	NSMutableString *result = [NSMutableString stringWithString:fmt];
	// year
	NSRange rang = [result rangeOfString:@"yyyy"];
	if(rang.location!=NSNotFound) [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"%i", [comp year]]];
	rang = [result rangeOfString:@"yy"];
	if(rang.location!=NSNotFound) [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"%i", [comp year]]];
	rang = [result rangeOfString:@"mm"];
	if(rang.location!=NSNotFound) {
		int val = [comp month];
		if(val<10) [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"0%i", val]];
		else [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"%i", val]];
	}
	else {
		rang = [result rangeOfString:@"m"];
		if(rang.location!=NSNotFound) [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"%i", [comp month]]];
	}
	rang = [result rangeOfString:@"dd"];
	if(rang.location!=NSNotFound) {
		int val = [comp day];
		if(val<10) [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"0%i", val]];
		else [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"%i", val]];
	}
	else {
		rang = [result rangeOfString:@"d"];
		if(rang.location!=NSNotFound) [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"%i", [comp day]]];
	}
	rang = [result rangeOfString:@"HH"];
	if(rang.location!=NSNotFound) {
		int val = [comp hour];
		if(val<10) [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"0%i", val]];
		else [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"%i", val]];
	}
	else {
		rang = [result rangeOfString:@"H"];
		if(rang.location!=NSNotFound) [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"%i", [comp hour]]];
	}
	rang = [result rangeOfString:@"MM"];
	if(rang.location!=NSNotFound) {
		int val = [comp minute];
		if(val<10) [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"0%i", val]];
		else [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"%i", val]];
	}
	else {
		rang = [result rangeOfString:@"M"];
		if(rang.location!=NSNotFound) [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"%i", [comp minute]]];
	}
	rang = [result rangeOfString:@"SS"];
	if(rang.location!=NSNotFound) {
		int val = [comp second];
		if(val<10) [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"0%i", val]];
		else [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"%i", val]];
	}
	else {
		rang = [result rangeOfString:@"S"];
		if(rang.location!=NSNotFound) [result replaceCharactersInRange:rang withString:[NSString stringWithFormat:@"%i", [comp second]]];
	}
	
	[gregorian release];
	return result;
}


// 获得一个名词的复数形式
+ (NSString *)getPluralFormOfWord:(NSString *)word
{
    if(!word) return nil;
    for(uint i=0;i<[word length];i++)
    {
        unichar ch = [word characterAtIndex:i];
        if(ch != ' ' && !(ch>='a' && ch<='z') && !(ch>='A' && ch<='Z')) return word;
    }
    return [word pluralize];
    /*
    NSString *lang = [SystemUtils getCurrentLanguage];
    if([lang isEqualToString:@"zh-Hans"] || [lang isEqualToString:@"zh-Hant"] || [lang isEqualToString:@"ko"] || [lang isEqualToString:@"ja"])
        return word;
    if([lang hasPrefix:@"en"])
        return [word pluralize];
    return word;
     */
}

// 获得数量＋名词组合文字
+ (NSString *)getTextOfNum:(int)num Word:(NSString *)word
{
    NSString *lang = [SystemUtils getCurrentLanguage];
    if([lang isEqualToString:@"zh-Hans"] || [lang isEqualToString:@"zh-Hant"] || [lang isEqualToString:@"ko"] || [lang isEqualToString:@"ja"])
        return [NSString stringWithFormat:@"%i%@", num, word];
    if(num==0 || num==1 || num==-1) 
        return [NSString stringWithFormat:@"%i %@", num, word];
    return [NSString stringWithFormat:@"%i %@", num, [word pluralize]];
}

// 获得英文首字母大写词语
+ (NSString *)getCapitalizeWord:(NSString *)word
{
    return [word capitalize];
}


// 解析query参数为一个Dictionary：p1=v1&p2=v2&p3=v3 => {"p1":"v1","p2":"v2","p3":"v3"}
+ (NSDictionary *)parseURLQueryStringToDictionary:(NSString *)query
{
    if(query==nil) return nil;
    // NSString *url=@"http://www.arijasoft.com/givemesomthing.php?a=3434&b=435edsf&c=500";
    // NSArray *comp1 = [url componentsSeparatedByString:@"?"];
    // NSString *query = [comp1 lastObject];
    /*
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *queryElements = [query componentsSeparatedByString:@"&"];
    for (NSString *element in queryElements) {
        NSArray *keyVal = [element componentsSeparatedByString:@"="];
        if (keyVal.count > 1) {
            NSString *variableKey = [keyVal objectAtIndex:0];
            NSString *value = [keyVal objectAtIndex:1];
            [dict setValue:value forKey:variableKey];
        }
    }
    return dict;
     */
    return [self parseURLParams:query];
}


+ (NSString*)hexRepresentationOfNSData:(NSData *)data
{
    NSUInteger capacity = [data length] * 2;
    NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *dataBuffer = [data bytes];
    NSInteger i;
    for (i=0; i<[data length]; ++i) {
        [stringBuffer appendFormat:@"%02x", (NSUInteger)dataBuffer[i]];
    }
    return stringBuffer;
}

// 检查一个数组里是否包含某个字符串
+ (BOOL) stringArrayExists:(NSArray *)arr keyword:(NSString *)key
{
    if(arr==nil || key==nil) return false;
    for(NSString *k in arr) {
        if(k!=nil && [k isKindOfClass:[NSString class]] && [k isEqualToString:key]) return YES;
    }
    return false;
}

+ (id) convertJSONStringToObject:(NSString *)str
{
    if(str==nil || [str length]==0) return nil;
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    id obj = [parser objectWithString:str];
    // [obj autorelease];
    [parser release];
    return obj;
}
+ (NSString *)convertObjectToJSONString:(id)obj
{
    if(obj==nil) return nil;
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];
    NSString *str = [writer stringWithObject:obj];
    // [str autorelease];
    [writer release];
    return str;
}

+ (NSString *) convertDataToBase64String:(NSData *)data
{
    return [Base64 encode:data];
}
+ (NSData *) convertBase64StringToData:(NSString *)str
{
    return [Base64 decode:str];
}

#pragma mark encryption/decryption

+ (NSString *) TripleDES:(NSString *)plainText encryptOrDecrypt:(CCOperation)encryptOrDecrypt encryptOrDecryptKey:(const char *)encryptOrDecryptKey
{
    
    const void *vplainText;
    size_t plainTextBufferSize;
    
    if (encryptOrDecrypt == kCCDecrypt)//解密
    {
        // NSData *EncryptData = [GTMBase64 decodeData:[plainText dataUsingEncoding:NSUTF8StringEncoding]];
        NSData *EncryptData = [StringUtils convertBase64StringToData:plainText];
        plainTextBufferSize = [EncryptData length];
        vplainText = [EncryptData bytes];
    }
    else //加密
    {
        NSData* data = [plainText dataUsingEncoding:NSUTF8StringEncoding];
        plainTextBufferSize = [data length];
        vplainText = (const void *)[data bytes];
    }
    
    CCCryptorStatus ccStatus;
    uint8_t *bufferPtr = NULL;
    size_t bufferPtrSize = 0;
    size_t movedBytes = 0;
    
    bufferPtrSize = (plainTextBufferSize + kCCBlockSize3DES) & ~(kCCBlockSize3DES - 1);
    bufferPtr = malloc( bufferPtrSize * sizeof(uint8_t));
    memset((void *)bufferPtr, 0x0, bufferPtrSize);
    // memset((void *) iv, 0x0, (size_t) sizeof(iv));
    
    const void *vkey = (const void *) encryptOrDecryptKey; // [encryptOrDecryptKey UTF8String];
    // NSString *initVec = @"init Vec";
    //const void *vinitVec = (const void *) [initVec UTF8String];
    //  Byte iv[] = {0x12, 0x34, 0x56, 0x78, 0x90, 0xAB, 0xCD, 0xEF};
    ccStatus = CCCrypt(encryptOrDecrypt,
                       kCCAlgorithm3DES,
                       kCCOptionPKCS7Padding | kCCOptionECBMode,
                       vkey,
                       kCCKeySize3DES,
                       nil,
                       vplainText,
                       plainTextBufferSize,
                       (void *)bufferPtr,
                       bufferPtrSize,
                       &movedBytes);
    
    NSString *result;
    
    if (encryptOrDecrypt == kCCDecrypt)
    {
        result = [[NSString alloc] initWithData:[NSData dataWithBytes:(const void *)bufferPtr
                                                               length:(NSUInteger)movedBytes]
                                       encoding:NSUTF8StringEncoding];
        [result autorelease];
    }
    else
    {
        NSData *myData = [NSData dataWithBytes:(const void *)bufferPtr length:(NSUInteger)movedBytes];
        result = [StringUtils convertDataToBase64String:myData]; // [GTMBase64 stringByEncodingData:myData];
    }
    
    return result;
}


@end



@implementation Base64
#define ArrayLength(x) (sizeof(x)/sizeof(*(x)))

static char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static char decodingTable[128];

static BOOL b64_initialized = NO;

+ (void) initialize {
    if(b64_initialized) return;
    b64_initialized = YES;
	if (self == [Base64 class]) {
		memset(decodingTable, 0, ArrayLength(decodingTable));
		for (NSInteger i = 0; i < ArrayLength(encodingTable); i++) {
			decodingTable[encodingTable[i]] = i;
		}
	}
}


+ (NSString*) encode:(const uint8_t*) input length:(NSInteger) length {
    [self initialize];
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
	
    for (NSInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++) {
            value <<= 8;
			
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
		
        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    encodingTable[(value >> 18) & 0x3F];
        output[index + 1] =                    encodingTable[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? encodingTable[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? encodingTable[(value >> 0)  & 0x3F] : '=';
    }
	
    return [[[NSString alloc] initWithData:data
                                  encoding:NSASCIIStringEncoding] autorelease];
}


+ (NSString*) encode:(NSData*) rawBytes {
    return [self encode:(const uint8_t*) rawBytes.bytes length:rawBytes.length];
}


+ (NSData*) decode:(const char*) string length:(NSInteger) inputLength {
    [self initialize];
	if ((string == NULL) || (inputLength % 4 != 0)) {
		return nil;
	}
	
	while (inputLength > 0 && string[inputLength - 1] == '=') {
		inputLength--;
	}
	
	NSInteger outputLength = inputLength * 3 / 4;
	NSMutableData* data = [NSMutableData dataWithLength:outputLength];
	uint8_t* output = data.mutableBytes;
	
	NSInteger inputPoint = 0;
	NSInteger outputPoint = 0;
	while (inputPoint < inputLength) {
		char i0 = string[inputPoint++];
		char i1 = string[inputPoint++];
		char i2 = inputPoint < inputLength ? string[inputPoint++] : 'A'; /* 'A' will decode to \0 */
		char i3 = inputPoint < inputLength ? string[inputPoint++] : 'A';
		
		output[outputPoint++] = (decodingTable[i0] << 2) | (decodingTable[i1] >> 4);
		if (outputPoint < outputLength) {
			output[outputPoint++] = ((decodingTable[i1] & 0xf) << 4) | (decodingTable[i2] >> 2);
		}
		if (outputPoint < outputLength) {
			output[outputPoint++] = ((decodingTable[i2] & 0x3) << 6) | decodingTable[i3];
		}
	}
	
	return data;
}


+ (NSData*) decode:(NSString*) string {
	return [self decode:[string cStringUsingEncoding:NSASCIIStringEncoding] length:string.length];
}

@end


