/*
 * @name: AdXTracking.m
 *
 * @created: 2013-04-12
 * @author: Paul Hayton, Ad-X Ltd
 * @copyright: Copyright 2011-2013 Ad-X Ltd All rights reserved
 * @description: Ad-X iOS SDK
 */

#define DEBUG 1
//#define UNITY_SDK

#if defined(DEBUG) && DEBUG
#define AdXLog(FORMAT, ...)	NSLog(FORMAT , __VA_ARGS__)
#else
#define AdXLog(FORMAT, ...)
#endif

// Imports
#import "AdXTracking.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <net/if_dl.h>
#include <ifaddrs.h>
#include <sys/xattr.h>
#import <CommonCrypto/CommonDigest.h>
#import <AdSupport/ASIdentifierManager.h>
#import <StoreKit/StoreKit.h>
#import <iAd/iAd.h>

#if __has_feature(objc_arc)
#define mrc_autorelease self
#define mrc_release self
#define mrc_retain self
#else
#define mrc_autorelease autorelease
#define mrc_release release
#define mrc_retain retain
#endif

#ifndef SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#endif

#pragma mark - NSDictionary additions

@interface NSDictionary (BVJSONString)
-(NSString*) jsonString;
@end

@implementation NSDictionary (BVJSONString)

-(NSString*) jsonString {
    NSError *error;
    NSData *jsonData = nil;
    
    if(NSClassFromString(@"NSJSONSerialization"))
        jsonData = [NSJSONSerialization dataWithJSONObject:self options:(NSJSONWritingOptions)0 error:&error];
    
    if (!jsonData) {
        return @"{}";
    } else {
        return [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] mrc_autorelease];
    }
}
@end

#pragma mark - NSDArray additions
@interface NSArray (BVJSONString)
- (NSString *)jsonString;
@end
@implementation NSArray (BVJSONString)
-(NSString*) jsonString {
    NSError *error;
    NSData *jsonData = nil;
    
    if(NSClassFromString(@"NSJSONSerialization"))
        jsonData = [NSJSONSerialization dataWithJSONObject:self options:(NSJSONWritingOptions)0 error:&error];
    
    if (! jsonData) {
        return @"[]";
    } else {
        return [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] mrc_autorelease];
    }
}
@end

#pragma mark - SDK Interface
@interface AdXTracking ()
@property (nonatomic, retain) NSString* UserAgent;
@property (nonatomic, retain) NSString* IDFV;
@property (nonatomic, retain) NSString* currentElement;
@property (nonatomic, retain) NSString* advertisingIdentifier;
@property (nonatomic, retain) NSMutableDictionary* dict;
@property (nonatomic, retain) NSMutableArray* productArray;
@property (nonatomic, retain) NSDate* connectionStartTime;
@property (nonatomic, retain) UIWebView* uAwebView;
@property (nonatomic, retain) NSMutableString* referral;
@property (nonatomic, retain) NSMutableString* clickID;
@property (nonatomic, retain) ASIdentifierManager* identifierManager;
@property (nonatomic, retain) NSString* attributionID;
@property (nonatomic, retain) NSString* serverIP;
@property (nonatomic, retain) NSString* serverIP_Q;
@property int seencount;
@property BOOL advertisingTrackingEnabled;
@property (nonatomic) BOOL OptOut;
@property (nonatomic) BOOL hasASIdentifierManager;
@property (nonatomic, retain) NSOperationQueue* networkQueue;
@property int iAd;
@end

@implementation AdXTracking

#if !__has_feature(objc_arc)
@synthesize ClientId, URLScheme, AppleId, BundleID, CountryCode, Is_upgrade, UserAgent, IDFV, advertisingIdentifier, attributionID, OptOut, seencount, referral, clickID, connectionStartTime, advertisingTrackingEnabled, hasASIdentifierManager, dict, productArray, uAwebView, currentElement, serverIP, serverIP_Q;
#endif

#pragma mark - SDK Internal Contstants

#define IFT_ETHER 0x6
#define ADX_SDK_VERSION @"4.2.6"

#define ADX_SERVER @"https://apps.ad-x.co.uk"
#define ADX_QSERVER @"http://apps.ad-x.co.uk"
//#define SERVER @"http://162.13.23.209"
//#define QSERVER @"http://162.13.23.209"
#define ADX_TESTSERVER @"https://testing.ad-x.co.uk"

#define ADX_CONNECTION_TIMEOUT 4.0

#define ADX_UNAVALABLE_INFORMATION_STRING @"UNAVAILABLE"
#define ADX_ANONYMOUS_USER_STRING @"ANON"

static NSString *ADXsParserLock = @"ParserLock";

#pragma mark - SDK Implementation

- (id)init {
    self = [super init];
    if (self) {
        self.Is_upgrade = FALSE;
        self.currentElement = nil;
        self.BundleID = nil;
        self.connectionStartTime = nil;
        self.advertisingIdentifier = @"";
        self.uAwebView = nil;
        self.referral  = nil;
        self.clickID = nil;
        self.UserAgent = nil;
        self.OptOut = NO;
        self.seencount = -1;
        self.advertisingTrackingEnabled = NO;
        self.CountryCode = @"";
        self.iAd = 0;
        self.dict = [[[NSMutableDictionary alloc] init] mrc_autorelease];
        self.productArray = [[[NSMutableArray alloc] init] mrc_autorelease];
        self.networkQueue = [[[NSOperationQueue alloc] init] mrc_autorelease];
        self.IDFV = @"";
        self.serverIP = ADX_SERVER;
        self.serverIP_Q = ADX_QSERVER;
        
        Class advm = NSClassFromString(@"ASIdentifierManager");
        self.hasASIdentifierManager = advm != Nil;
        
        if (advm) {
            self.identifierManager = [advm sharedManager];
            self.advertisingTrackingEnabled = self.identifierManager.advertisingTrackingEnabled;
            self.advertisingIdentifier = self.identifierManager.advertisingIdentifier.UUIDString; // Use setter to retain
            
            NSUUID *uuid = [[UIDevice currentDevice] identifierForVendor];
            if (uuid != nil)
                self.IDFV = [uuid UUIDString];
        }
	}
    return self;
}

#if !__has_feature(objc_arc)
- (void)dealloc
{
	[super dealloc];
}
#endif

#pragma mark Basic events

- (void)sendEvent:(NSString*)event withData:(NSString*)data {
    [self performSelectorInBackground:@selector(reportAppEventToAdX:) withObject:@[event, data]];
}

- (void)sendEvent:(NSString*)event withData:(NSString*)data andCurrency:(NSString*)currency {
    [self performSelectorInBackground:@selector(reportAppEventToAdX:) withObject:@[event, data, currency]];
}

- (void)sendEvent:(NSString*)event withData:(NSString*)data andCurrency:(NSString*)currency andCustomData:(NSString*)custom {
    [self performSelectorInBackground:@selector(reportAppEventToAdX:) withObject:@[event, data, currency, custom]];
}

#pragma mark InApp purshase event
- (void)sendAndValidateSaleEvent:(SKPaymentTransaction*)transaction withValue:(NSString*)data andCurrency:(NSString*)currency andCustomData:(NSString*)custom {
    
    [self performSelectorInBackground:@selector(reportAppEventToAdX:) withObject:@[@"Sale", data, currency, custom,
                                                                                   [NSNumber numberWithInt:(int)transaction.transactionState],
                                                                                   transaction.transactionReceipt,
                                                                                   transaction.transactionIdentifier]];
}

#pragma mark Extended events

- (void)sendExtendedEvent:(int)key {
    NSArray *event_types = [NSArray arrayWithObjects:  @"vh",@"vs",@"vp",@"vl",@"vb",@"vc",@"lc", nil];
    
    // Check Key is valid
    if (key < 0 || key >= [event_types count]) return;
    
    // Set the event type
    [self.dict setValue:[event_types objectAtIndex:key] forKey:@"e"];
    if ([self.productArray count]>0) {
        [self.dict setValue:self.productArray forKey:@"p"];
    }
    
    [self performSelectorInBackground:@selector(reportExtendedEventToAdX:) withObject:[self.dict jsonString]];
    // Clear the dictionary ready for another event.
}

- (void)sendExtendedEventOfName:(NSString*)name {
    
    // Set the event type
    [self.dict setValue:name forKey:@"e"];
    if ([self.productArray count]>0) {
        [self.dict setValue:self.productArray forKey:@"p"];
    }
    
    [self performSelectorInBackground:@selector(reportExtendedEventToAdX:) withObject:[self.dict jsonString]];
    // Clear the dictionary ready for another event.
    [self.dict removeAllObjects];
    [self.productArray removeAllObjects];
    
}


- (void)startNewEvent {
    [self.dict removeAllObjects];
    [self.productArray removeAllObjects];
}


- (void)setEventParameter:(int)key withValue:(id)value {
    NSArray *parameters = [NSArray arrayWithObjects:  @"a",@"ci",@"p",@"kw",@"p",@"pr",@"q",@"din",@"dout",@"nc", @"id",@"sid",@"did",@"l",nil];
    
    // Check Key is valid
    if (key < 0 || key >= [parameters count]) return;
    
    [self.dict setValue:value forKey:[parameters objectAtIndex:key]];
}

- (void)setEventParameterOfName:(NSString*)name withValue:(id)value; {
    [self.dict setValue:value forKey:name];
}

- (void)addProductToList:(NSString*)product {
    
    [self.productArray addObject:product];
}

- (void)addProductToList:(NSString*)product ofPrice:(float)price forQuantity:(int)quantity {
    
    NSMutableDictionary *minidict = [[NSMutableDictionary alloc] init];
    
    NSNumber *q = [NSNumber numberWithInt:quantity];
    NSNumber *p = [NSNumber numberWithFloat:price];
    
    [minidict setObject:product forKey:@"i"];
    [minidict setObject:p forKey:@"pr"];
    [minidict setObject:q forKey:@"q"];
    
    [self.productArray addObject:minidict];
    [minidict mrc_release];
}


#pragma mark Traking

- (NSString*)getReferral {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"Ad-X.url"];
}
- (NSString*)getDLReferral {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"Ad-X.DLReferral"];
}

- (int)isFirstInstall {
    if (self.seencount > 0) return 0;
    if (self.seencount < 0) return -1;
    return 1;
}
- (NSString*)getTransactionID {
    return self.clickID;
}

#ifdef UNITY_SDK
- (NSString*) adXGetBundleID {
    if (self.BundleID && [self.BundleID length] > 0)
        return [self.BundleID stringByAppendingFormat:@".iOS"];
    return [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"] stringByAppendingFormat:@".iOS"];
}
#else
- (NSString*)adXGetBundleID {
    if (self.BundleID != NULL && [self.BundleID length] > 0)
        return self.BundleID;
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
}
#endif

- (NSString*) getAdXDeviceIDForEvents {
    
    NSString *isu;
    
    if (self.hasASIdentifierManager)
	{
        // As this is not just conversion tracking, we need to check whether we're allowed to use the advertisingIdentifier
        if (self.advertisingTrackingEnabled)
            isu = self.advertisingIdentifier;
        else
            isu = @"ANON";
	}
    else {
        // We're not running on iOS 6. Use the Old Device ID for now.
        isu = [self getOldDID];
    }
    
    return isu;
}


/*
 * Record if this is an upgrade. Writes to Userdefaults on first call. Then uses that value on subsequent calls.
 */
- (void)isUpgrade:(BOOL)isUpgrade {
    NSNumber *isAnUpgrade = [[NSUserDefaults standardUserDefaults] objectForKey:@"Ad-X.isUpgrade"];
    if (isAnUpgrade == NULL)
	{
        [[NSUserDefaults standardUserDefaults] setObject:@(isUpgrade) forKey:@"Ad-X.isUpgrade"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.Is_upgrade = isUpgrade;
	}
    else
        self.Is_upgrade = [isAnUpgrade boolValue];
}



#pragma mark QA
- (void) useQAServerUntilYear:(int) year month:(int)month day:(int)day {
    
    NSDateComponents *comps = [[[NSDateComponents alloc] init] mrc_autorelease];
    [comps setDay:day];
    [comps setMonth:month];
    [comps setYear:year];
    if ([[[NSCalendar currentCalendar] dateFromComponents:comps] compare:[[NSDate date] dateByAddingTimeInterval:1209600]]==NSOrderedDescending) {
        // Don't accept a date more than 2 weeks in future.
        return;
    }
    if ([[[NSCalendar currentCalendar] dateFromComponents:comps] compare:[NSDate date]]==NSOrderedDescending) {
        self.serverIP = ADX_TESTSERVER;
        self.serverIP_Q = ADX_TESTSERVER;
    }
    
}

#pragma mark Device Info

//Both Mac Address and Odin are not accessible anymore since iOS 7.0
//We provide a dumy implementation for Apps that do not target versions < 7.0
#if (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0)
- (NSString *) macAddress
{
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0.0")){
        return ADX_UNAVALABLE_INFORMATION_STRING;
    }
    
    char* macAddressString = (char*)malloc(18);
    
    BOOL  success;
    struct ifaddrs * addrs;
    struct ifaddrs * cursor;
    const unsigned char* base;
    
    success = getifaddrs(&addrs) == 0;
    if (success) {
        cursor = addrs;
        while (cursor != 0) {
            if (cursor->ifa_addr->sa_family == AF_LINK) {
                struct sockaddr *ifa_addr = cursor->ifa_addr;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-align"
                struct sockaddr_dl *dlAddr = (struct sockaddr_dl *)ifa_addr;
#pragma clang diagnostic pop
                if ( dlAddr->sdl_type == IFT_ETHER && strcmp("en0",  cursor->ifa_name) == 0 ) {
                    base = (const unsigned char*) &dlAddr->sdl_data[dlAddr->sdl_nlen];
                    strcpy(macAddressString, "");
                    for (NSInteger i = 0; i < dlAddr->sdl_alen; i++) {
                        if (i != 0) {
                            strcat(macAddressString, ":");
                        }
                        char partialAddr[3];
                        sprintf(partialAddr, "%02X", base[i]);
                        strcat(macAddressString, partialAddr);
                    }
                }
            }
            cursor = cursor->ifa_next;
        }
        
        freeifaddrs(addrs);
    }
    
    NSString* macAddress= [[[NSString alloc] initWithCString:macAddressString
                                                    encoding:NSMacOSRomanStringEncoding] mrc_autorelease];
    free(macAddressString);
    
    return macAddress;
}

- (NSString *) odin1
{
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0.0")){
        return ADX_UNAVALABLE_INFORMATION_STRING;
    }
    
    char* macAddressString = (char*)malloc(18);
    
    BOOL  success;
    struct ifaddrs * addrs;
    struct ifaddrs * cursor;
    const unsigned char* base = NULL;
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    success = getifaddrs(&addrs) == 0;
    if (success) {
        cursor = addrs;
        while (cursor != 0) {
            if ( cursor->ifa_addr->sa_family == AF_LINK) {
                struct sockaddr *ifa_addr = cursor->ifa_addr;
                
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-align"
                struct sockaddr_dl *dlAddr = (struct sockaddr_dl *)ifa_addr;
#pragma clang diagnostic pop
                
                if ( dlAddr->sdl_type == IFT_ETHER && strcmp("en0",  cursor->ifa_name) == 0 ) {
                    base = (const unsigned char*) &dlAddr->sdl_data[dlAddr->sdl_nlen];
                    strcpy(macAddressString, "");
                    for (NSInteger i = 0; i < dlAddr->sdl_alen; i++) {
                        if (i != 0) {
                            strcat(macAddressString, ":");
                        }
                        char partialAddr[3];
                        sprintf(partialAddr, "%02X", base[i]);
                        strcat(macAddressString, partialAddr);
                    }
                }
            }
            cursor = cursor->ifa_next;
        }
        
        // Check for success
        if (base != NULL) {
            uint8_t digest[CC_SHA1_DIGEST_LENGTH];
            CC_SHA1(base, 6, digest);
            
            for(NSInteger i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
                [output appendFormat:@"%02x", digest[i]];
		} else {
            [output setString:@""];
        }
        
        freeifaddrs(addrs);
    }
    
    free(macAddressString);
    return output;
}

#else

- (NSString *) macAddress
{
    return ADX_UNAVALABLE_INFORMATION_STRING;
}

- (NSString *) odin1
{
    return ADX_UNAVALABLE_INFORMATION_STRING;
}

#endif

- (NSString*)getOldDID
{
    return [self odin1];
}


#pragma mark - Internal

- (void)reportAppOpenToAdXNow {
    [self reportAppOpenToAdX:true];
}


- (void)reportAppOpenToAdX:(bool)now {
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // we're in a new thread here, so we need our own autorelease pool
    @autoreleasepool { // we're in a new thread here, so we need our own autorelease pool
        NSString *isu;
        // Have we already reported an app open?
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                            NSUserDomainMask, YES) objectAtIndex:0];
        NSString *appOpenPath = [documentsDirectory stringByAppendingPathComponent:@"adx_app_open"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        /*
         * Dont report app open until we've got the referral information.
         */
        NSString *deviceKeyPath = [documentsDirectory stringByAppendingPathComponent:@"Ad-X.DeviceKeyFound"];
        if(!now && ![fileManager fileExistsAtPath:deviceKeyPath])
        {
            return;
        }
        
        if(![fileManager fileExistsAtPath:appOpenPath]) {
            // Not yet reported -- report now
            NSString *appname    = [self adXGetBundleID];
            NSString *appversion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];

            if (self.hasASIdentifierManager) {
                isu = self.advertisingIdentifier;
            }
            else {
                // We're not running on iOS >= 6. Use the Old Device ID for now.
                isu = [self getOldDID];
            }
            
            NSString *old_id   = [self getOldDID];
            NSString *macAddress = [self macAddress];
            
            NSString *appOpenEndpoint = [NSString stringWithFormat:@"%@/atrk/iOSapp?isu=%@&app_id=%@&app_name=%@&app_version=%@&clientid=%@&tag_version=%@&macAddress=%@&oldDID=%@&idfv=%@&ate=%d&country=%@",
                                         self.serverIP, isu, self.AppleId, appname, appversion, self.ClientId, ADX_SDK_VERSION, macAddress, old_id, self.IDFV, self.advertisingTrackingEnabled, self.CountryCode];
            
            
            AdXLog(@"GET %@",appOpenEndpoint);
            
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:appOpenEndpoint]];
            
            [NSURLConnection sendAsynchronousRequest:request queue:self.networkQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                NSString *respStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                AdXLog(@"HTTP response %d %@",(int)[(NSHTTPURLResponse *)response statusCode],respStr);
                [respStr mrc_release];
                if((!connectionError) && ([(NSHTTPURLResponse *)response statusCode] == 200) ) {
                    [self parseResponse:data];
                }
            }];
            
        }
    }
    
    NSNotification *n = [NSNotification notificationWithName:@"AdXDone" object:self];
    [[NSNotificationCenter defaultCenter] postNotification:n];
}


- (void)reportAppEventToAdX:(NSArray *)eventAndDataReference {
    
    @autoreleasepool { // we're in a new thread here, so we need our own autorelease pool
        // Have we already reported an app open?
        self.referral = [[[NSMutableString alloc] init] mrc_autorelease];
        
        NSString *appname    = [self adXGetBundleID];
        
        NSString *event = [eventAndDataReference objectAtIndex:0];
        NSString *data  = [eventAndDataReference objectAtIndex:1];
        NSString *currency = ([eventAndDataReference count] > 2) ? [eventAndDataReference objectAtIndex:2] : @"";
        NSString *extraData = ([eventAndDataReference count] > 3) ? [eventAndDataReference objectAtIndex:3] : @"";
        NSNumber *transactionState = ([eventAndDataReference count] > 4) ? [eventAndDataReference objectAtIndex:4] : @"";
        NSData   *transactionReceiptData = ([eventAndDataReference count] > 5) ? [eventAndDataReference objectAtIndex:5] : @"";
        NSString *transactionId = ([eventAndDataReference count] > 6) ? [eventAndDataReference objectAtIndex:6] : @"";
        
        
        NSString *isu;
        if (self.hasASIdentifierManager)
        {
            // As this is not just conversion tracking, we need to check whether we're allowed to use the advertisingIdentifier
            if (self.advertisingTrackingEnabled)
                isu = self.advertisingIdentifier;
            else
                isu = ADX_ANONYMOUS_USER_STRING;
        }
        else {
            // We're not running on iOS 6. Use the Old Device ID for now.
            isu = [self getOldDID];
        }
        NSString *old_id   = [self getOldDID];
        NSString *macAddress = [self macAddress];
        NSString *deviceType = [self urlEncode:[UIDevice currentDevice].model];
        NSString *iOSVersion = [self urlEncode:[[UIDevice currentDevice] systemVersion]];
        
        
        // If no tracking enabled, anonymise the Device
        NSURLRequest *request;
        NSString *appOpenEndpoint;
        
        if ([eventAndDataReference count] <= 4) {
            appOpenEndpoint = [NSString stringWithFormat:@"%@/API/event/%@/%@/%@/%@/%@/%@?macAddress=%@&oldDID=%@&dev=%@&os=%@&extraData=%@&idfv=%@",
                               self.serverIP, self.ClientId, isu, appname, event, data, currency, macAddress, old_id,deviceType,iOSVersion,extraData,self.IDFV];
            request = [NSURLRequest requestWithURL:[NSURL URLWithString:appOpenEndpoint]];
        } else {
            appOpenEndpoint = [NSString stringWithFormat:@"%@/API/event/%@/%@/%@/Sale/%@/%@?macAddress=%@&oldDID=%@&dev=%@&os=%@&extraData=%@&idfv=%@&tstate=%d&transid=%@",
                               self.serverIP, self.ClientId, isu, appname, data, currency, macAddress, old_id,deviceType,iOSVersion,extraData,self.IDFV,[transactionState intValue],transactionId];
            
            NSMutableURLRequest *mtblrequest = [[[NSMutableURLRequest alloc] init] mrc_autorelease];
            [mtblrequest setURL:[NSURL URLWithString:appOpenEndpoint]];
            [mtblrequest setHTTPMethod:@"POST"];
            [mtblrequest setHTTPBody:transactionReceiptData];
            request = mtblrequest;
        }
        
        AdXLog(@"%@ %@",appOpenEndpoint, [request isKindOfClass:[NSMutableURLRequest class]] ? @"POST" : @"GET");
        
        [NSURLConnection sendAsynchronousRequest:request queue:self.networkQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSString *respStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            AdXLog(@"HTTP response %d %@",(int)[(NSHTTPURLResponse *)response statusCode],respStr);
            [respStr mrc_release];
            if((!connectionError) && ([(NSHTTPURLResponse *)response statusCode] == 200) ) {
                [self parseResponse:data];
            }
        }];
    }
}

- (void)reportExtendedEventToAdX:(NSString *)payload {
    //	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // we're in a new thread here, so we need our own autorelease pool
    @autoreleasepool { // we're in a new thread here, so we need our own autorelease pool
        // Have we already reported an app open?
        self.referral = [[[NSMutableString alloc] init] mrc_autorelease];
        
        NSString *appname    = [self adXGetBundleID];
        NSString *poststring = [[NSString alloc] initWithFormat:@"payload=%@", payload ];
        NSString *deviceType = [self urlEncode:[UIDevice currentDevice].model];
        NSString *iOSVersion = [self urlEncode:[[UIDevice currentDevice] systemVersion]];
        
        NSString *isu;
        if (self.hasASIdentifierManager)
        {
            // As this is not just conversion tracking, we need to check whether we're allowed to use the advertisingIdentifier
            if (self.advertisingTrackingEnabled)
                isu = self.advertisingIdentifier;
            else
                isu = ADX_ANONYMOUS_USER_STRING;
        }
        else {
            // We're not running on iOS 6. Use the Old Device ID for now.
            isu = [self getOldDID];
        }
        
        // If no tracking enabled, anonymise the Device
        
        NSString *appOpenEndpoint = [NSString stringWithFormat:@"%@/API/RetargetEvent/%@/%@/%@?event=adx_v3&platform=ios&dev=%@&os=%@&idfv=%@",
                                     self.serverIP, self.ClientId, isu, appname, deviceType,iOSVersion,self.IDFV];
        
        AdXLog(@"POST %@",appOpenEndpoint);
        NSData *postData = [poststring dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        [poststring mrc_release];
        NSString *postLength = [NSString stringWithFormat:@"%d",(int)[postData length]];
        NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] mrc_autorelease];
        [request setURL:[NSURL URLWithString:appOpenEndpoint]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Current-Type"];
        [request setHTTPBody:postData];
        
        [NSURLConnection sendAsynchronousRequest:request queue:self.networkQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSString *respStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            AdXLog(@"HTTP response %d %@",(int)[(NSHTTPURLResponse *)response statusCode],respStr);
            [respStr mrc_release];
            if((!connectionError) && ([(NSHTTPURLResponse *)response statusCode] == 200) ) {
                [self parseResponse:data ];
            }
        }];
        
    }
}


- (void)reportAppOpen{
    
    // See if we have the user-agent already stored.
    NSString *s = [[NSUserDefaults standardUserDefaults] objectForKey:@"Ad-X.UserAgent"];
    
    // Get the Facebook ID now in main thread (not thread safe so can't be done in background).
    UIPasteboard *pb = [UIPasteboard
                        pasteboardWithName:@"fb_app_attribution"
                        create:NO];
    self.attributionID = (pb) ? pb.string : @"";
    
    if (s != NULL) {
        
        self.UserAgent = s;
        
        // We have the user agent already so send the data to Ad-X. Otherwise this will happen when the user agent is available in shouldStartLoadWithRequest.
        [self performSelectorInBackground:@selector(doReportAppOpen) withObject:nil];
        
    } else {
        // Now create a webview; we'll read the user-agent in shouldStartLoadWithRequest and continue from there.
        self.uAwebView = [[[UIWebView alloc] init] mrc_autorelease];
        [self.uAwebView setDelegate:self];
        [self.uAwebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]]];
    }
}

- (void)checkForiAdConversion {

#ifdef __IPHONE_7_1
    // Only available from 7.1 upwards
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare: @"7.1" options:NSNumericSearch] != NSOrderedAscending) {
        
        // Get a reference to the shared ADClient object instance
        ADClient * sharedInstance = [ADClient sharedClient];
        // Check to see if we were installed as the result of an iAd campaign
        [sharedInstance determineAppInstallationAttributionWithCompletionHandler:^(BOOL appInstallationWasAttributedToiAd) {
            if (appInstallationWasAttributedToiAd == YES) {
                self.iAd = 1;
            } else {
                self.iAd = 0;
            }
            // Continue and send to Ad-X
            [self performSelectorInBackground:@selector(doReportAppOpen) withObject:nil];
        }];
    } else {
        [self performSelectorInBackground:@selector(doReportAppOpen) withObject:nil];
    }
#else
    [self performSelectorInBackground:@selector(doReportAppOpen) withObject:nil];
#endif
}

- (void)doReportAppOpen
{
    @autoreleasepool { // we're in a new thread here, so we need our own autorelease pool
        NSString *isu;
        self.referral = [[[NSMutableString alloc] init] mrc_autorelease];
        self.clickID  = [[[NSMutableString alloc] init] mrc_autorelease];
        
        // We've done the swish, just report the App open to Ad-X.
        NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:@"Ad-X.SwishDone"];
        if ((n != NULL) && [n boolValue] == true)
        {
            [self reportAppOpenToAdX:TRUE];
            return;
        }
        
        if ([self recentSwish]) return;
        
        
        // Record the time we're starting so we can decide is a swish is ok.
        if (self.connectionStartTime) self.connectionStartTime = nil;
        self.connectionStartTime = [[[NSDate alloc] init] mrc_autorelease];
        
        NSString *appname    = [self adXGetBundleID];
        NSString *macAddress = [self macAddress];
        
        NSString *old_id   = [self getOldDID];
        NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        
        if (self.hasASIdentifierManager)
        {
            isu      = self.advertisingIdentifier;
        }
        else
        {
            // We're not running on iOS 6. Use the Old Device ID and save it so we can migrate later.
            isu = [self getOldDID];
            [[NSUserDefaults standardUserDefaults] setObject:isu forKey:@"Ad-X.UDID"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        NSString *encodedUAgent = [self urlEncode:self.UserAgent];
        NSString *deviceType = [self urlEncode:[UIDevice currentDevice].model];
        NSString *iOSVersion = [self urlEncode:[[UIDevice currentDevice] systemVersion]];
        
        NSString *appOpenEndpoint = [NSString stringWithFormat:@"%@/atrk/iOSAppOpen?isu=%@&clientID=%@&app_name=%@&app_id=%@&tag_version=%@&macAddress=%@&uagent=%@&version=%@&upgrade=%d&fb=%@&oldDID=%@&dev=%@&os=%@&idfv=%@&ate=%d&optout=%d&country=%@&iAd=%d",
                                     self.serverIP_Q, isu, self.ClientId, appname, self.AppleId, ADX_SDK_VERSION, macAddress, encodedUAgent,version,self.Is_upgrade,self.attributionID,old_id,deviceType,iOSVersion,self.IDFV,self.advertisingTrackingEnabled,self.OptOut,self.CountryCode,self.iAd];
        
        
        AdXLog(@"GET %@",appOpenEndpoint);
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:appOpenEndpoint]];
    
        [NSURLConnection sendAsynchronousRequest:request queue:self.networkQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSString *respStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ;
            AdXLog(@"HTTP response %d %@",(int)[(NSHTTPURLResponse *)response statusCode],respStr);
            [respStr mrc_release];
            if((!connectionError) && ([(NSHTTPURLResponse *)response statusCode] == 200) ) {
                [self parseResponse:data];
            }else {
                NSNotification *n = [NSNotification notificationWithName:@"AdXDone" object:self];
                [[NSNotificationCenter defaultCenter] postNotification:n];
            }
        }];
        
    }
    
}

#pragma mark Swish implementation

- (BOOL)doSwish
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																		NSUserDomainMask, YES) objectAtIndex:0];
    NSString *deviceKeyPath = [documentsDirectory stringByAppendingPathComponent:@"Ad-X.DeviceKeyFound"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // If we've got the referral don't do it again.
    if([fileManager fileExistsAtPath:deviceKeyPath])
        return TRUE;
	
    if ([self recentSwish]) return TRUE;
    NSInteger attempts = [self swishAttempts];
    if (attempts > 3) return TRUE;
	
    NSInteger newattempts;
    if (attempts == 0) newattempts = 1;
    else               newattempts = attempts+1;
	
	
    NSString *appname    = [self adXGetBundleID];
    NSString *odin1      = [self odin1];
	
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/atrk/Rconv.php?tag=%@&appid=%@&adxid=%@&idfa=%@&country=%@",self.serverIP,self.URLScheme, appname, odin1, self.advertisingIdentifier,self.CountryCode]];
    
    if ([self connectedToNetwork])
    {
        // Save the time and number of attempts.
        [[NSUserDefaults standardUserDefaults] setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"Ad-X.DeviceKeyInProgress"];
        [[NSUserDefaults standardUserDefaults] setObject:@(newattempts) forKey:@"Ad-X.SwishAttempts"];
        [[NSUserDefaults standardUserDefaults] synchronize];
		
        if (![[UIApplication sharedApplication] openURL:url]) {
            AdXLog(@"%@%@",@"Failed to open url:",[url description]);
        }
        return TRUE;
    }
    return TRUE;
}

- (BOOL)recentSwish
{
    NSNumber *deviceKeyInProgress = [[NSUserDefaults standardUserDefaults] objectForKey:@"Ad-X.DeviceKeyInProgress"];
    // If we started a swich already within the last 5 minutes, don't repeat...
    if (deviceKeyInProgress != nil && [deviceKeyInProgress longValue]+300 > [[NSDate date] timeIntervalSince1970])
        return TRUE;
    return FALSE;
}

- (NSInteger)swishAttempts
{
    NSNumber *attempts = [[NSUserDefaults standardUserDefaults] objectForKey:@"Ad-X.SwishAttempts"];
    if (attempts != nil) return [attempts integerValue];
    return 0;
}


/**
 Ad-X third party is going out to Safari and Safari is starting our application through a URL.
 This mechanism is handled here.
 */
- (BOOL)handleOpenURL:(NSURL *)url
{
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																		NSUserDomainMask, YES) objectAtIndex:0];
    NSString *deviceKeyPath = [documentsDirectory stringByAppendingPathComponent:@"Ad-X.DeviceKeyFound"];
    
    //if (!url) {  return NO; }
    
    /* Retrieve the ADX UDID */
	/*    NSString *urlquery = [url absoluteString];
	 NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	 for (NSString *param in [urlquery componentsSeparatedByString:@"&"]) {
	 NSArray *elts = [param componentsSeparatedByString:@"="];
	 if([elts count] < 2) continue;
	 [params setObject:[elts objectAtIndex:1] forKey:[elts objectAtIndex:0]];
	 }
	 [params release];    */
    NSString *URLString = [url absoluteString];
    // Save the information to UserDefaults.
    [[NSUserDefaults standardUserDefaults] setObject:URLString forKey:@"Ad-X.adxurl"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    
    // Create a marker file to prevent us doing this each time.
	NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createFileAtPath:deviceKeyPath contents:nil attributes:nil]; // successful report, mark it as such
    [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:deviceKeyPath]];
    
    AdXLog(@"Got the URL as %@",URLString);
    [self performSelectorInBackground:@selector(reportAppOpenToAdXNow) withObject:nil];
    return YES;
}



#pragma mark Network helpers

- (NSString *)urlEncode:(NSString *)input {
    NSString *encoded =
    CFBridgingRelease(
                      CFURLCreateStringByAddingPercentEscapes(NULL,
                                                              (__bridge CFStringRef)input,
                                                              NULL,
                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                              kCFStringEncodingUTF8));
    
	return encoded;
}

- (BOOL) connectedToNetwork
{
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
	
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
	
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
	
    if (!didRetrieveFlags)
    {
        //printf("Error. Could not recover network reachability flags\n");
        return 0;
    }
	
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    BOOL nonWiFi = flags & kSCNetworkReachabilityFlagsTransientConnection;
    return ((isReachable && !needsConnection) || nonWiFi) ?
    (([[[NSURLConnection alloc] initWithRequest:[NSURLRequest
												 requestWithURL: [NSURL URLWithString:self.serverIP]
												 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0]
									   delegate:self] mrc_autorelease]) ? YES : NO) : NO;
}

#pragma mark Storage helpers

-(BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    
    const char* filePath = [[URL path] fileSystemRepresentation];
    const char* attrName = "com.apple.MobileBackup";
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED <= __IPHONE_5_1
    // only compile code if SDK target is 5.1 or lower
    if (&NSURLIsExcludedFromBackupKey == nil) {
        // iOS 5.0.1 and lower
        u_int8_t attrValue = 1;
        NSInteger result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
        return result == 0;
        
    }
#endif
    
    // First try and remove the extended attribute if it is present
    ssize_t result = getxattr(filePath, attrName, NULL, sizeof(u_int8_t), 0, 0);
    if (result != -1) {
        // The attribute exists, we need to remove it
        int removeResult = removexattr(filePath, attrName, 0);
        if (removeResult == 0) {
            NSLog(@"Removed extended attribute on file %@", URL);
        }
    }
    
    // Set the new key
    NSError *error = nil;
    [URL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&error];
    return error == nil;
}

#pragma mark Webview delegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    // Get the user agent from the request
    self.UserAgent = [request valueForHTTPHeaderField:@"User-Agent"];
    
    // Store the User agent
    [[NSUserDefaults standardUserDefaults] setObject:self.UserAgent forKey:@"Ad-X.UserAgent"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Now we've got the User agent continue with the connection to Ad-X.
    [self checkForiAdConversion];
    
	// Return no, we don't care about executing an actual request so cancel it.
    return NO;
}

#pragma mark XML parsing delegate

/*
 * Take the XML Puzzle String and parse it.
 */
- (BOOL)parseResponse:(NSData*)data {
    
    
    @synchronized(ADXsParserLock)
    {
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
        // Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
        [parser setDelegate:self];
        // Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
        [parser setShouldProcessNamespaces:NO];
        [parser setShouldReportNamespacePrefixes:NO];
        [parser setShouldResolveExternalEntities:NO];
        
        
        [parser parse];
        
        NSError *parseError = [parser parserError];
        if (parseError) {
            [parser mrc_release];
            return FALSE;
        }
        
        [parser mrc_release];
    }
    return TRUE;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName) {
        elementName = qName;
    }
	
    if (self.currentElement)
    {
        self.currentElement = nil;
    }
	self.currentElement = elementName;
    
    // clearing value that will be updated
    if ([self.currentElement isEqualToString:@"Referral"]) {
        [self.referral setString:@""];
	}
    if ([self.currentElement isEqualToString:@"DLReferral"]) {
        [self.referral setString:@""];
	}
    if ([self.currentElement isEqualToString:@"Seencount"]) {
        self.seencount = 0;
	}
    if ([self.currentElement isEqualToString:@"ClickID"]) {
        [self.clickID setString:@""];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    
    if ([self.currentElement isEqualToString:@"Referral"])
	{
        AdXLog(@"Got Referral from server %@",self.referral);
        // Save the information to UserDefareportults.
        [[NSUserDefaults standardUserDefaults] setObject:self.referral forKey:@"Ad-X.url"];
        [[NSUserDefaults standardUserDefaults] synchronize];
	}
    else if ([self.currentElement isEqualToString:@"DLReferral"])
	{
        AdXLog(@"Got Referral from server %@",self.referral);
        // Save the information to UserDefareportults.
        [[NSUserDefaults standardUserDefaults] setObject:self.referral forKey:@"Ad-X.DLReferral"];
        [[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																		NSUserDomainMask, YES) objectAtIndex:0];
    NSString *appOpenPath = [documentsDirectory stringByAppendingPathComponent:@"adx_app_open"];
    
    if ([self.currentElement isEqualToString:@"Referral"]) {
        [self.referral appendString:string];
	}
    if ([self.currentElement isEqualToString:@"DLReferral"]) {
        [self.referral appendString:string];
	}
    if ([self.currentElement isEqualToString:@"Seencount"]) {
        self.seencount = [string intValue];
	}
    if ([self.currentElement isEqualToString:@"ClickID"]) {
        [self.clickID appendString:string];
	}
    if ([self.currentElement isEqualToString:@"Success"])
	{
        if ([string compare:@"true"] == NSOrderedSame || [string compare:@"stop"] == NSOrderedSame) {
            [fileManager createFileAtPath:appOpenPath contents:nil attributes:nil]; // successful report, mark it as such
		    [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:appOpenPath]];
        }
        // We've had a response back from an App Open - set swish to no if not already done.
        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"Ad-X.SwishDone"];
        [[NSUserDefaults standardUserDefaults] synchronize];
		
        AdXLog(@"Success is %@",string);
	}
    if ([self.currentElement isEqualToString:@"Swish"])
	{
        NSDate *secondDate = [NSDate date];
        NSTimeInterval interval = [secondDate timeIntervalSinceDate:self.connectionStartTime];
        if ([string compare:@"true"] == NSOrderedSame)
		{
            if (interval < ADX_CONNECTION_TIMEOUT) {
                AdXLog(@"Swish is a go - %f seconds",interval);
                [self doSwish];
			} else {
                AdXLog(@"Connection took %f seconds - defer",interval);
                NSNotification *n = [NSNotification notificationWithName:@"AdXDone" object:self];
                [[NSNotificationCenter defaultCenter] postNotification:n];
			}
		}
        else {
            // Swish is 'no' so record it.
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"Ad-X.SwishDone"];
            [[NSUserDefaults standardUserDefaults] synchronize];
			
            AdXLog(@"Ok - ready to send to Ad-X",nil);
            // Mark the swish information as found so we do send Open notifications.
            NSString *deviceKeyPath = [documentsDirectory stringByAppendingPathComponent:@"Ad-X.DeviceKeyFound"];
            [fileManager createFileAtPath:deviceKeyPath contents:nil attributes:nil]; // successful report, mark it as such
			[self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:deviceKeyPath]];
            
            NSNotification *n2 = [NSNotification notificationWithName:@"AdXDone" object:self];
            [[NSNotificationCenter defaultCenter] postNotification:n2];
		}
	}
	
}

#ifdef UNITY_SDK
static AdXTracking* trackerObject = nil;

// Converts C style string to NSString
NSString* AdXCreateNSString (const char* string)
{
	if (string)
		return [NSString stringWithUTF8String: string];
	else
		return [NSString stringWithUTF8String: ""];
}

// When native code plugin is implemented in .mm / .cpp file, then functions
// should be surrounded with extern "C" block to conform C function naming rules
extern "C" {
    
    void _reportAppOpen (const char* clientID, const char* iTunesID, const bool QA=false)
	{
		if (trackerObject == nil)
			trackerObject = [[AdXTracking alloc] init];
        
        if (QA) {
            trackerObject.serverIP = ADX_TESTSERVER;
            trackerObject.serverIP_Q = ADX_TESTSERVER;
            NSLog(@"WARNING : ONLY FOR USE ON QA BUILD");
            NSLog(@"WARNING : ONLY FOR USE ON QA BUILD");
            NSLog(@"WARNING : ONLY FOR USE ON QA BUILD");
        }
		[trackerObject setClientId:AdXCreateNSString(clientID)];
        [trackerObject setAppleId:AdXCreateNSString(iTunesID)];
        [trackerObject setURLScheme:@""];
        [trackerObject reportAppOpen];
    }
    
	void _SendEvent (const char* clientID, const char* eventname,const char* value, const char* currency, const bool QA=false)
	{
		if (trackerObject == nil)
			trackerObject = [[AdXTracking alloc] init];
        if (QA) {
            trackerObject.serverIP = ADX_TESTSERVER;
            trackerObject.serverIP_Q = ADX_TESTSERVER;
            NSLog(@"WARNING : ONLY FOR USE ON QA BUILD");
            NSLog(@"WARNING : ONLY FOR USE ON QA BUILD");
            NSLog(@"WARNING : ONLY FOR USE ON QA BUILD");
        }
		[trackerObject setClientId:AdXCreateNSString(clientID)];
        [trackerObject sendEvent:AdXCreateNSString(eventname) withData:AdXCreateNSString(value) andCurrency:AdXCreateNSString(currency)];
	}
	
}
#endif

@end
