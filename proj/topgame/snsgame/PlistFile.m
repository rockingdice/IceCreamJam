

#import "PlistFile.h"
#import "SystemUtils.h"
#import "SBJson.h"
#import "StringUtils.h"

#define kHashSalt @"xdwer232379we0()-23"

@implementation PlistFile

@synthesize isSelfVerify;

- (id) init 
{
    self = [super init];
    if(self) {
        isSelfVerify = NO;
    }
    return self;
}

- (id) initWithFile:(NSString*)filename
{
    self = [super init];
    if ( self ) {
        isSelfVerify = NO;
        [self initFile:filename];
    }
    return self;
}

//创建文件
-(void)initFile:(NSString*)fileName{
	if([fileName characterAtIndex:0] == '/') filePath = [fileName retain];
	else {
		//取当前应用程序路径
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		//@"record.plist"
		filePath = [[documentsDirectory stringByAppendingPathComponent:fileName] retain];		
		documentsDirectory = nil;
		paths = nil;
	}
	// NSMutableDictionary* dict_rank = nil;
	m_pData = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	// 检查文件是否有效
	BOOL valid = YES;
	if(![fileManager fileExistsAtPath:filePath]) valid = NO;
    /*
     // 不在这里做验证，改为在存档文件类里做验证
#ifndef DEBUG
	if(valid && ![SystemUtils checkFileDigest:filePath]) {
		valid = NO;
		[SystemUtils setSaveID:0];
	}
#endif
     */
	//无效就创建新文件
	if(valid){
        // 尝试以JSON格式读取
        NSString *str = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil ];
        NSDictionary *info = nil;
        if(str && isSelfVerify) {
            // verify str
            int len = [str length];
            if(len<32) len = 32;
            NSString *digest = [str substringFromIndex:len-32];
            NSString *str1 = [str substringToIndex:len-32];
            NSString *digest2 = [StringUtils stringByHashingStringWithMD5:[str1 stringByAppendingString:kHashSalt]];
            if([digest isEqualToString:digest2])
            {
                SNSLog(@"digest of %@ is ok", filePath);
                str = str1;
            }
            else {
                SNSLog(@"digest of %@ is invalid", filePath);
#ifdef DEBUG
                if([str1 characterAtIndex:[str1 length]-1]=='}')
                    str = str1;
#else
                str = nil;
#endif
            }
        }
        
        if(str) info = [str JSONValue];
        
        if(info && [info isKindOfClass:[NSDictionary class]]) {
            m_pData = [[NSMutableDictionary alloc] initWithDictionary:info];
        }
        if(!m_pData) {
            m_pData = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
            if(m_pData) [m_pData retain];
        }
		if(!m_pData) valid = NO;
	}
	if(!valid) {
		SNSLog(@"PlistFile not exist");
		m_pData = [[NSMutableDictionary alloc] init];
        [self saveToFile];
	}
	//NSLog(@"initFile::%@",filePath);
	fileManager = nil;
}
-(void)dealloc{
	if(filePath) [filePath release];
	if(m_pData) [m_pData release];
	[super dealloc];
}

-(void)addRecord:(NSString*)name value:(id)value{
	[self updateRecord:name value:value];
}

-(void)updateRecord:(NSString*)name value:(id)value{
	[m_pData setObject:value forKey:name];
    [self saveToFile];
}
-(void)deleteRecord:(NSString*)name{
	[m_pData removeObjectForKey:name];
    [self saveToFile];
}
-(id)getRecord:(NSString*)name{
	return [m_pData objectForKey:name];
}
// 保存到磁盘
-(BOOL) saveToFile
{
    NSString *strInfo = [m_pData JSONRepresentation];
    if(isSelfVerify) {
        NSString *digest = [StringUtils stringByHashingStringWithMD5:[strInfo stringByAppendingString:kHashSalt]];
        strInfo = [strInfo stringByAppendingString:digest];
    }
    return [strInfo writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    // return [m_pData writeToFile:filePath atomically:YES];
}
// 更新记录，但不保存到磁盘
-(void) setValue:(id)value forKey:(NSString *)key
{
    [m_pData setValue:value forKey:key];
}
// 获取数据字典
-(NSMutableDictionary *)getData
{
    return m_pData;
}

-(void) setVerifyMode:(BOOL)mode
{
    isSelfVerify = mode;
}

@end
