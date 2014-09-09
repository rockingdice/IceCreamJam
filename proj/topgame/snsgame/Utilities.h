#import "SNSLogType.h"

#ifndef MODE_COCOS2D_X
#import "cocos2d.h"
#endif

#define COLOR(r,g,b)   [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

static const int kDontCacheTexture = -666;
struct tTimeType {
	int hour  ;  //小时
	int minute ; //分钟
	int second ; //秒
};
typedef struct tTimeType tTimeType;
@interface Utilities : NSObject
{
}
+(int)getChooseNumber:(int)number1 number2:(int)number2;
+(int) getRandomNumber:(int)min max:(int)max;
+(int) getRandomNumberExceptFor:(int)except maxRand:(int)max;
+(NSString*)getTimeString:(int)seconds;
+(NSString*)getTimeHoursString:(int)seconds;
+(tTimeType)getTime:(int)seconds;
#ifndef MODE_COCOS2D_X
+(void) removeChildrenAndPurgeUncachedTextures:(CCNode*)cleanupNode;
#endif

+(double) getAvailableBytes;
+(double) getAvailableKiloBytes;
+(double) getAvailableMegaBytes;
+ (UIImage *)imageWithScreenContents;
//根据 进度值返回指定贝塞尔曲线上的一点坐标
//startPos: 曲线起点
//config: 曲线控制点及终点
//progress: 进度  （0.0－1.0f）

#ifndef MODE_COCOS2D_X
+ (CGPoint) getBezieratPos:(CGPoint)startPos config:(ccBezierConfig)config progress:(float)progress;
#endif

/* less accurate than the above code
+(unsigned int) getFreeBytes;
+(double) getFreeKiloBytes;
+(double) getFreeMegaBytes;
 */

@end
