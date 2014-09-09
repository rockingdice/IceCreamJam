

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@class ASIdentifierManager;

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_4_0
#error "ADX Tracking is not supporting Apps Running versions of IOS lesser than 4.0"
#endif

@interface AdXTracking : NSObject <NSXMLParserDelegate, UIWebViewDelegate> {

}

@property (nonatomic, retain) NSString* URLScheme;
@property (nonatomic, retain) NSString* ClientId;
@property (nonatomic, retain) NSString* AppleId;
@property (nonatomic, retain) NSString* BundleID;
@property (nonatomic, retain) NSString* CountryCode;
@property BOOL Is_upgrade;

- (void)reportAppOpenToAdXNow;
- (void)reportAppOpenToAdX:(bool)now;

/*
 Retargeting Events Constants.
 */

#define ADX_EVENT_HOMEPAGE 0
#define ADX_EVENT_SEARCH 1
#define ADX_EVENT_PRODUCTVIEW 2
#define ADX_EVENT_LISTINGVIEW 3
#define ADX_EVENT_VIEWCART 4
#define ADX_EVENT_CONFIRMATION 5
#define ADX_EVENT_LEVEL 6

#define ADX_CUSTOMERID 1   // ci
#define ADX_PRODUCT 2      // i
#define ADX_KEYWORD 3      // kw

#define ADX_PRODUCT_LIST 4  // p
#define ADX_PRICE_LIST 5   // pr
#define ADX_QUANTITY_LIST 6 // q

#define ADX_START_DATE 7   // din
#define ADX_END_DATE 8     // dout
#define ADX_NEWCUSTOMER 9   // nc
#define ADX_TRANSACTION_ID 10  // transaction ID

#define ADX_SOURCE_ID 11       // source ID
#define ADX_DESTINATION_ID 12  // destination ID

#define ADX_LEVEL 13 // Level achieved.

#define ADX_PARAMETER_INT 14   // A general Int
#define ADX_PARAMETER_STRING 15   // A general Int
#define ADX_PARAMETER_FLOAT 16   // A general Int
#define ADX_PARAMETER_DATE 17   // A general Int


- (void)sendEvent:(NSString*)event withData:(NSString*)data;
    
- (void)sendEvent:(NSString*)event withData:(NSString*)data andCurrency:(NSString*)currency;

- (void)sendEvent:(NSString*)event withData:(NSString*)data andCurrency:(NSString*)currency andCustomData:(NSString*)custom;

- (void)setEventParameter:(int)key withValue:(id)value;
- (void)setEventParameterOfName:(NSString*)name withValue:(id)value;

- (void)startNewEvent;
- (void)addProductToList:(NSString*)product;
- (void)addProductToList:(NSString*)product ofPrice:(float)price forQuantity:(int)quantity;

- (void)sendExtendedEvent:(int)key;
- (void)sendExtendedEventOfName:(NSString*)name;

- (void)sendAndValidateSaleEvent:(SKPaymentTransaction*)transaction withValue:(NSString*)data andCurrency:(NSString*)currency andCustomData:(NSString*)custom;

- (void)reportAppEventToAdX:(NSArray *)eventAndDataReference;

- (void)reportAppOpen;

- (BOOL)handleOpenURL:(NSURL *)url;

- (BOOL)parseResponse:(NSData*)data;

- (BOOL)recentSwish;

- (NSString *) odin1;

- (NSString *) macAddress;

- (void)isUpgrade:(BOOL)isUpgrade;

- (NSString*) getReferral;

- (NSString*) getDLReferral;

- (NSString*) getAdXDeviceIDForEvents;

- (int)isFirstInstall;

- (NSString*) getTransactionID;

- (void) useQAServerUntilYear:(int) year month:(int)month day:(int)day;

@end
