//
//  ProgressWindow.m
//  Colorme
//
//  Created by xiawei on 11-3-31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SnsLoadingView.h"
#import "SystemUtils.h"
#import "UIImage-Extension.h"

@implementation SnsLoadingView

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
		BOOL IsIpad = [SystemUtils isiPad];
		UIView* view = [[UIView alloc] initWithFrame:frame];
		indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		
		[self loadImageViewList];
		[self addSubview:view];
		[view autorelease];
		
        hideLoadingHint = [[SystemUtils getSystemInfo:@"kHideLoadingHint"] intValue];
        if(hideLoadingHint==1) return self;
		/*
		//assume that the image is loaded in landscape mode from disk
		UIImage * bgImage = [UIImage imageNamed: @"Default.png"];
		
		if([SystemUtils getGameOrientation] == UIDeviceOrientationLandscapeRight)
		{
			NSLog(@"%s: rotate image with 90 degree", __func__);
			bgImage = [bgImage imageRotatedByDegrees:-90.0f];
			
			//UIImage * image = [[UIImage alloc] initWithCGImage: bgImage.CGImage
			//												 scale: 1.0
			//										   orientation: UIImageOrientationLeft];
			// bgImage = [image autorelease];
		}
		 */
        
		int indicatorPosX = kLoadingViewIndicatorSubPosition.x;
        int indicatorPosY = kLoadingViewIndicatorSubPosition.y;
        if(IsIpad) {
            indicatorPosX = kLoadingViewIndicatorSubPositionPad.x;
            indicatorPosY = kLoadingViewIndicatorSubPositionPad.y;
        }
        
        NSString *posStr = [SystemUtils getSystemInfo:@"kLoadingIndicatorOffset"];
		if(IsIpad) {
            NSString *str = [SystemUtils getSystemInfo:@"kLoadingIndicatorOffsetiPad"];
            if(str!=nil) posStr = str;
        }
        if([SystemUtils isiPhone5Screen]) {
            NSString *str = [SystemUtils getSystemInfo:@"kLoadingIndicatorOffsetiPhone5"];
            if(str!=nil) posStr = str;
        }
        if(posStr!=nil && [posStr length]>0) {
            NSArray *arr = [posStr componentsSeparatedByString:@","];
            if([arr count]>1) {
                indicatorPosX = [[arr objectAtIndex:0] intValue];
                indicatorPosY = [[arr objectAtIndex:1] intValue];
            }
        }
        
        indicator.frame = CGRectMake(frame.size.width/2-indicatorPosX, frame.size.height/2+indicatorPosY, 30, 30);
		
		
		[view addSubview:indicator];
		[indicator release];
		
		UILabel* tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, indicator.frame.origin.y+indicator.frame.size.height - 15, frame.size.width, 50)];
		tipLabel.font = [UIFont fontWithName:@"Arial" size:16];	
		tipLabel.textColor = [UIColor colorWithRed:255.0/255.0 green:210.0/255.0 blue:210.0/255.0 alpha:1.0];
		tipLabel.textAlignment = UITextAlignmentCenter;
		tipLabel.tag = 101;
		tipLabel.text = [SystemUtils getLocalizedString:@"Checking Network Status"];
		tipLabel.backgroundColor = [UIColor clearColor];
		[self addSubview:tipLabel];
		
		[tipLabel release];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(onSetLoadingText:) 
													 name:kNotificationSetLoadingScreenText
												   object:nil];
		
    }
    return self;
}
- (void) show
{
   // self.windowLevel = UIWindowLevelAlert;
    [indicator startAnimating];
    self.hidden = false;
	// [[CCDirector sharedDirector].openGLView.window makeKeyAndVisible];
    // [self makeKeyAndVisible];
}

- (void) hide
{
    self.hidden = true;
	// [[CCDirector sharedDirector].openGLView.window resignKeyWindow];
    // [self resignKeyWindow];
    [indicator stopAnimating];
	[self removeFromSuperview];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) loadImageViewList
{
	NSArray *imageList = [SystemUtils getSystemInfo:@"kLoadingImageList"];
    if([SystemUtils isiPad]) {
        NSArray *arr2 = [SystemUtils getSystemInfo:@"kLoadingImageListiPad"];
        if(arr2!=nil) imageList = arr2;
    }
	if(!imageList) return;
	
	BOOL isIpad = [SystemUtils isiPad];
    BOOL isiPhone5 = [SystemUtils isiPhone5Screen];
    BOOL isRetina = [SystemUtils isRetina];
    SNSLog(@"isiPhone5:%i",isiPhone5);
	imageViewList = [[NSMutableArray alloc] init];
	
    NSString *aniPrefix = @"animation";
    int aniLen = [aniPrefix length];
    
	for(NSString *file in imageList)
	{
		if([file isEqualToString:@"animation"])
		{
			[self loadAnimationView];
			continue;
		}
        
        if([file length]>aniLen && [aniPrefix isEqualToString:[file substringToIndex:aniLen]])
        {
            [self loadAdvAnimationView:file];
            continue;
        }
        NSString *oldFile = file;
		if(isIpad) {
            BOOL useiPad3 = NO;
            if(isRetina) {
                // 测试iPad3: -ipad3@2x
                NSString *file2 = [file stringByAppendingString:@"-ipad3"];
                UIImage *testimg = [UIImage imageNamed:file2];
                if(testimg) {
                    file = file2; useiPad3 = YES;
                }
            }
            if(!useiPad3)
                file = [file stringByAppendingString:@"@2x"];
        }
        else if(isiPhone5) file = [file stringByAppendingString:@"-568h"];
		UIImage *img = [UIImage imageNamed:file];
        if(!img && (isIpad || isiPhone5)) {
            file = oldFile;
            img = [UIImage imageNamed:file];
        }
		if(!img) continue;
		UIImageView *iv = [[UIImageView alloc] initWithImage:img];
		// set position
		// if(isIpad) {
		int px = (self.frame.size.width - img.size.width) / 2;
		int py = (self.frame.size.height - img.size.height) / 2;
		iv.frame = CGRectMake(px, py, iv.frame.size.width, iv.frame.size.height);
		// }
		[self addSubview:iv];
		[imageViewList addObject:iv];
		[iv release];
	}
	
}

- (void) loadAnimationView
{
	NSArray *imageList = [SystemUtils getSystemInfo:@"kLoadingAnimationList"];
	if(!imageList) return;
	BOOL isIpad = [SystemUtils isiPad];
    // BOOL isiPhone5 = [SystemUtils isiPhone5Screen];
	
	animationImageList = [[NSMutableArray alloc] init];
	
	UIImage * defImg = nil;
	for(NSString *file in imageList)
	{
		if(isIpad) file = [file stringByAppendingString:@"@2x"];
        // else if(isiPhone5) file = [file stringByAppendingString:@"-568h"];
		UIImage *img = [UIImage imageNamed:file];
		if(!img) continue;
		[animationImageList addObject:img];
		defImg = img;
	}
	double interval = [[SystemUtils getSystemInfo:@"kLoadingAnimationInterval"] doubleValue];
	if(interval < 0.1) interval = 1;
	UIImageView *iv = [[UIImageView alloc] initWithImage:defImg];
	iv.animationImages = animationImageList;
	iv.animationDuration = interval;
	// set position
	NSString *key = @"kLoadingAnimationPosiPod";
	if(isIpad) key = @"kLoadingAnimationPosiPad";
	NSString *str = [SystemUtils getSystemInfo:key];
	NSArray *arr = [str componentsSeparatedByString:@","];
	int px = 0, py = 0;
	px = [[arr objectAtIndex:0] intValue];
	if([arr count]>1) py = [[arr objectAtIndex:1] intValue];
	CGRect r = iv.frame;
	iv.frame = CGRectMake(px, py, r.size.width, r.size.height);
	[self addSubview:iv];
	[iv startAnimating];
	[iv release];
}

- (void) loadAdvAnimationView:(NSString *)aniName
{
    
    NSString *key = [aniName stringByAppendingFormat:@"Setting-%@", [SystemUtils getCurrentLanguage]];
    NSDictionary *info = [SystemUtils getSystemInfo:key];
    if(!info) {
        key = [aniName stringByAppendingString:@"Setting"];
        info = [SystemUtils getSystemInfo:key];
    }
    if(!info) return;
    
	NSArray *imageList = [info objectForKey:@"imageList"];
	if(!imageList || ![imageList isKindOfClass:[NSArray class]]) return;
	BOOL isIpad = [SystemUtils isiPad];
	
	animationImageList = [[NSMutableArray alloc] init];
	
	UIImage * defImg = nil;
	for(NSString *file in imageList)
	{
        NSString *oldFile = file;
		if(isIpad) file = [file stringByAppendingString:@"@2x"];
		UIImage *img = [UIImage imageNamed:file];
        if(!img && isIpad) {
            file = oldFile;
            img = [UIImage imageNamed:file];
        }
		if(!img) continue;
		[animationImageList addObject:img];
		defImg = img;
	}
	double interval = [[info objectForKey:@"interval"] doubleValue];
	if(interval < 0.1) interval = 1;
	UIImageView *iv = [[UIImageView alloc] initWithImage:defImg];
	iv.animationImages = animationImageList;
	iv.animationDuration = interval;
	// set position
	key = @"iPodPos";
	if(isIpad) key = @"iPadPos";
	NSString *str = [info objectForKey:key];
	NSArray *arr = [str componentsSeparatedByString:@","];
	int px = 0, py = 0;
	px = [[arr objectAtIndex:0] intValue];
	if([arr count]>1) py = [[arr objectAtIndex:1] intValue];
	CGRect r = iv.frame;
	iv.frame = CGRectMake(px, py, r.size.width, r.size.height);
	[self addSubview:iv];
	[iv startAnimating];
	[iv release];
    
}

- (void)dealloc {
	if(imageViewList) [imageViewList release];
	if(animationImageList) [animationImageList release];
	imageViewList = nil; animationImageList = nil;
	
    [super dealloc];
}

-(void)setTip:(NSString*)strTip{
	//NSLog(@"%s : %@", __FUNCTION__, strTip);
	UILabel* tipLabel = (UILabel*)[self viewWithTag:101];
    [tipLabel setTextColor:[UIColor grayColor]];
	tipLabel.text = strTip;
}

- (void) onSetLoadingText:(NSNotification *)note
{
	NSDictionary *info = note.userInfo;
	NSString* mesg = [info objectForKey:@"message"];
	[self setTip:mesg];
}

@end
