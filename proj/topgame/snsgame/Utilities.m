
#include <sys/sysctl.h>  
#import <mach/mach.h>
#import <mach/mach_host.h>

#import "Utilities.h"

#ifndef MODE_COCOS2D_X
static inline float bezierat( float a, float b, float c, float d, ccTime t )
{
	return (powf(1-t,3) * a + 
			3*t*(powf(1-t,2))*b + 
			3*powf(t,2)*(1-t)*c +
			powf(t,3)*d );
}
#endif

@interface Utilities (Private)
@end

@implementation Utilities


//在指定的两个值中返回一个值
+(int)getChooseNumber:(int)number1 number2:(int)number2{
	int rand = [Utilities getRandomNumber:1 max:2];
	
	if(rand==1){
		return number1;
	}else{
		return number2;
	}
}	

//返回 min 到 max 间的值（包括min和max）
+(int) getRandomNumber:(int)min max:(int)max{
	//srand((unsigned)time(0)); 
	int number = rand();
	number = number%(max-min+1);
	number = number+min;
	return number;
}

// returns a random number in the range 0 to (max - 1), excluding the number "except"
//返回   0到max-1 间的值， 但不包括except参数指定的值 
+(int) getRandomNumberExceptFor:(int)except maxRand:(int)max
{
	NSAssert(max > 1, @"getRandomNumberExceptFor requires maxRand > 1");
	int number;
	
	do
	{
		number = rand() % max;
	}
	while (number == except);	// in the rare case that we got the "except" number, simply try again
	
	return number;
}


//根据指定的时间秒数，返回时间字符串(00:00:00)
+(NSString*)getTimeString:(int)seconds{
	int hours = seconds/3600;
	seconds = seconds%3600;
	int minutes = seconds/60;
	seconds = seconds%60;
	
	NSString *strHours = [NSString stringWithFormat:@"%d",hours];
	if(hours<10){
		strHours = [NSString stringWithFormat:@"0%d",hours];
	}
	
	NSString *strMinutes = [NSString stringWithFormat:@"%d",minutes];
	if(minutes<10){
		strMinutes = [NSString stringWithFormat:@"0%d",minutes];
	}
	
	NSString *strSeconds = [NSString stringWithFormat:@"%d",seconds];
	if(seconds<10){
		strSeconds = [NSString stringWithFormat:@"0%d",seconds];
	}
	
	return [NSString stringWithFormat:@"%@:%@:%@",strHours,strMinutes,strSeconds];
}
//根据指定的时间秒数，返回时间字符串(00:00)  小时:分钟  如果不足一小时返回  分钟：秒
+(NSString*)getTimeHoursString:(int)seconds{
	int hours = seconds/3600;
	seconds = seconds%3600;
	int minutes = seconds/60;
	seconds = seconds%60;
	
	NSString *strHours = [NSString stringWithFormat:@"%d",hours];
	if(hours<10){
		strHours = [NSString stringWithFormat:@"0%d",hours];
	}
	
	NSString *strMinutes = [NSString stringWithFormat:@"%d",minutes];
	if(minutes<10){
		strMinutes = [NSString stringWithFormat:@"0%d",minutes];
	}
	
	NSString *strSeconds = [NSString stringWithFormat:@"%d",seconds];
	if(seconds<10){
		strSeconds = [NSString stringWithFormat:@"0%d",seconds];
	}
	
	if(hours>0){
		return [NSString stringWithFormat:@"%@:%@",strHours,strMinutes];
	}
	
	return [NSString stringWithFormat:@"%@:%@",strMinutes,strSeconds];
	
}


+(tTimeType)getTime:(int)seconds{
	tTimeType t;
	t.hour = seconds/3600;
	seconds = seconds%3600;
	t.minute = seconds/60;
	t.second = seconds%60;
	
	return t;
}
#ifndef MODE_COCOS2D_X
// helpful to remove only specific textures from the CCTextureCache
// this is only supposed to be called during dealloc!
+(void) removeChildrenAndPurgeUncachedTextures:(CCNode*)cleanupNode
{
	NSMutableArray* textures = [[NSMutableArray alloc] initWithCapacity:10];
	
	for (CCNode* node in cleanupNode.children)
	{
		if (![node isKindOfClass:[CCNode class]])
		{
			continue;
		}
		
		// look for the node tag
		if (node.tag == kDontCacheTexture)
		{
			if ([node isKindOfClass:[CCSprite class]])
			{
				CCSprite* s = (CCSprite*)node;
				[textures addObject:[s texture]];
			}
			else
			{
				NSAssert(nil, @"removeChildrenAndPurgeUncachedTextures - kDontCacheTexture tag used on unsupported class type");
			}
		}
	}
	
	// remove all the children so we can safely remove the unused textures
	[cleanupNode removeAllChildrenWithCleanup:YES];
	
	for (CCTexture2D* texture in textures)
	{
		[[CCTextureCache sharedTextureCache] removeTexture:texture];
	}
	
	[textures removeAllObjects];
	[textures release];
}
#endif

// original code from here: http://developers.enormego.com/view/iphone_sdk_available_memory
+(double) getAvailableBytes
{
	vm_statistics_data_t vmStats;
	mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
	kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
	
	if (kernReturn != KERN_SUCCESS)
	{
		return NSNotFound;
	}
	
	return (vm_page_size * vmStats.free_count);
}

+(double) getAvailableKiloBytes
{
	return [Utilities getAvailableBytes] / 1024.0;
}

+(double) getAvailableMegaBytes
{
	return [Utilities getAvailableKiloBytes] / 1024.0;
}


/* 
 this code seems to be less accurate than the above, it frequently reports more free memory
 the above code seems to be closer to the truth as it will show 3-4 free memory when
 receiving memory warnings compared to the code below where it triggers around 6-7 Mb supposedly free memory
 
// original code from here: http://adeem.me/blog/2009/04/01/get-the-amount-of-free-memory-available/
+(unsigned int) getFreeBytes
{
	mach_port_t host_port;
	mach_msg_type_number_t host_size;
	vm_size_t pagesize;
	host_port = mach_host_self();
	host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
	host_page_size(host_port, &pagesize);
	vm_statistics_data_t vm_stat;
	if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
	{
		NSLog(@"Failed to fetch vm statistics");
		return 0;
	}
	
	// Stats in bytes
	natural_t mem_free = vm_stat.free_count * pagesize;
	return (unsigned int)mem_free;
}

+(double) getFreeKiloBytes
{
	return (double)([Utilities getFreeBytes] / 1024.0);
}

+(double) getFreeMegaBytes
{
	return (double)([Utilities getFreeKiloBytes] / 1024.0);
}
*/
+ (UIImage *)imageWithScreenContents
{
	// 竖屏
    CGSize displaySize	= [UIScreen mainScreen].bounds.size;
    CGSize winSize = displaySize;
#ifndef MODE_COCOS2D_X
	displaySize	= [[CCDirector sharedDirector] winSize];
	winSize = [[CCDirector sharedDirector] winSizeInPixels];
#endif
	//Create buffer for pixels
	GLuint bufferLength = displaySize.width * displaySize.height * 4;
	GLubyte* buffer = (GLubyte*)malloc(bufferLength);
	
	// SHIKAKA : waiting for buffers to fill or else black picture or previous screenshot
	[NSThread sleepForTimeInterval:1];
	//Read Pixels from OpenGL
	glReadPixels(0, 0, displaySize.width, displaySize.height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
	//Make data provider with data.
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
	
	//Configure image
	int bitsPerComponent = 8;
	int bitsPerPixel = 32;
	int bytesPerRow = 4 * displaySize.width;
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	CGImageRef iref = CGImageCreate(displaySize.width, displaySize.height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
	
	uint32_t* pixels = (uint32_t*)malloc(bufferLength);
	CGContextRef context = CGBitmapContextCreate(pixels, winSize.width, winSize.height, 8, winSize.width * 4, CGImageGetColorSpace(iref), kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	
	CGContextTranslateCTM(context, 0, displaySize.height);
	CGContextScaleCTM(context, 1.0f, -1.0f);
	
	//CGContextRotateCTM(context, CC_DEGREES_TO_RADIANS(-90));
	//CGContextTranslateCTM(context, -displaySize.height, 0);
	
	CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, displaySize.width, displaySize.height), iref);
	CGImageRef imageRef = CGBitmapContextCreateImage(context);
	UIImage *outputImage = [[UIImage alloc] initWithCGImage:imageRef] ;
	
	//	[[NSNotificationCenter defaultCenter] postNotificationName:kImageNotification object:outputImage];
	
	//Dealloc
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGImageRelease(iref);
	CGColorSpaceRelease(colorSpaceRef);
	CGContextRelease(context);
	free(buffer);
	free(pixels);
	[outputImage autorelease];
    
	return outputImage;
	 
	 
}

#ifndef MODE_COCOS2D_X

//根据 进度值返回指定贝塞尔曲线上的一点坐标
//startPos: 曲线起点
//config: 曲线控制点及终点
//progress: 进度  （0.0－1.0f）
+(CGPoint)getBezieratPos:(CGPoint)startPos config:(ccBezierConfig)config progress:(float)progress{
	GLfloat t = progress;
	
	GLfloat x = powf(1 - t, 3) * startPos.x + 
	3.0f * powf(1 - t, 2) * t * config.controlPoint_1.x + 
	3.0f * (1 - t) * t * t * config.controlPoint_2.x + t * t * t * config.endPosition.x;
	
	GLfloat y = powf(1 - t, 3) * startPos.y + 
	3.0f * powf(1 - t, 2) * t * config.controlPoint_1.y + 
	3.0f * (1 - t) * t * t * config.controlPoint_2.y + t * t * t * config.endPosition.y;
	return ccp(x,y);
	
}

#endif

@end
