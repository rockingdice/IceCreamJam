

#import <Foundation/Foundation.h>


@interface PlistFile : NSObject {
	//文件路径
	NSString* filePath;
	NSMutableDictionary *m_pData;
    
    // 是否自动添加验证标志，并在读取是验证是否有效
    BOOL  isSelfVerify;
}

@property(nonatomic,assign) BOOL isSelfVerify;

- (id) initWithFile:(NSString*)filename;

//创建文件
-(void)initFile:(NSString*)fileName;

//增加记录
-(void)addRecord:(NSString*)name value:(id)value;

//更新记录
-(void)updateRecord:(NSString*)name value:(id)value;

//删除记录
-(void)deleteRecord:(NSString*)name;

//获取记录
-(id)getRecord:(NSString*)name;

// 保存到磁盘
-(BOOL) saveToFile;
// 更新记录，但不保存到磁盘
-(void) setValue:(id)value forKey:(NSString *)key;
// 获取数据字典
-(NSMutableDictionary *)getData;

-(void) setVerifyMode:(BOOL)mode;


@end
