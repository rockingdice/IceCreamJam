//
//  NetworkHelper.m
//  iPetHotel
//
//  Created by LEON on 11-6-7.
//  Copyright 2011 PlayDino. All rights reserved.
//

#import "NetworkHelper.h"
#import "SystemUtils.h"

static NetworkHelper *_helper = nil;

@implementation NetworkHelper
 
@synthesize connectedToInternet,connectedToHost;

+(NetworkHelper *)helper
{
	@synchronized(self)
    {
        if (_helper == NULL)
		{
			_helper = [[self alloc] init];
		}
    }
	return _helper;
}

+(id)alloc
{	
	@synchronized([NetworkHelper class])
	{ 
		return [super alloc];
	}
	
	return nil;
}

-(id) init
{
	self = [super init];
	if(self != nil) {
		// init here
		connectedToInternet = NO; connectedToHost = NO;
		[self checkNetworkStatus];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    if(internetReach) [internetReach release];
    if(hostReach) [hostReach release];
    
                   
    [super dealloc];
}

-(void) checkNetworkStatus
{
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector: @selector(reachabilityChanged:) 
												 name: kReachabilityChangedNotification 
											   object: nil];
	
    internetReach = [[Reachability reachabilityForInternetConnection] retain];
    [internetReach startNotifier];
	NSString *country = [SystemUtils getCountryCode];
	NSString *host = @"www.google.com";
	if([country isEqualToString:@"CN"]) host = @"www.baidu.com";
    // Change the host name here to change the server your monitoring
	hostReach = [[Reachability reachabilityWithHostName: host] retain];
	[hostReach startNotifier];
}

- (void) reachabilityChanged: (NSNotification* )note
{
	NetworkStatus netStatus = [internetReach currentReachabilityStatus];
	BOOL old = connectedToInternet;
	connectedToInternet = (netStatus != NotReachable);
	if(old != connectedToInternet) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kNetworkHelperNetworkStatusChanged object:nil];
	}
	SNSLog(@"connectedToInternet:%i", connectedToInternet);
    
    NetworkStatus hostStatus = [hostReach currentReachabilityStatus];
    if(hostStatus != NotReachable) connectedToHost = YES;
    else connectedToHost = NO;
	// [self performSelectorOnMainThread:@selector(updateNetworkStatus) withObject:self waitUntilDone:NO];
	// [hostReach release]; hostReach = nil;
}

+(BOOL) isConnected
{ 
	return [self helper].connectedToInternet;
}

- (BOOL) connectedToInternet
{
	// return NO;
	return connectedToInternet;
}	

@end
