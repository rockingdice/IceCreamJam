//
//  InAppStore.m
//  iPetHotel
//
//  Created by LEON on 11-6-7.
//  Copyright 2011 topgame. All rights reserved.
// d

#import "SNSLogType.h"
#import "InAppStore.h"
#import "NetworkHelper.h"
#import "SystemUtils.h"
//#import "GameConfig.h"
#import "SBJson.h"
#import "ASINetworkQueue.h"
#import "StringUtils.h"
#import "GameDataDelegate.h"
#import "StatSendOperation.h"
#ifdef SNS_ENABLE_ADX
#import "AdxHelper.h"
#endif

static InAppStore *_store = nil;

@implementation InAppStore

@synthesize marketProducts;
@synthesize storeStatus;
@synthesize promoteIapIDs;
@synthesize normalIapIDs;
@synthesize delegate;
@synthesize downloadOK, paymentPending, isRestoring;
@synthesize iapCoinName,iapLeafName;

+ (InAppStore *)store
{
	@synchronized(self)
    {
        if (_store == NULL)
		{
			_store = [[self alloc] init];
		}
    }
	
    return(_store);
}


+(id)alloc
{	
	@synchronized([InAppStore class])
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
		delegate = nil;
		self.storeStatus = AppStoreStatusNone;
		// [self requestProductData];
		productInfoList = nil;
		promoteInfoList = nil;
		downloadOK = NO; paymentPending = NO; isVerifyServerOK = YES;
        m_simulateIAPItem = nil; isRestoring = NO;
		
		iapKeyPrefix = [[SystemUtils getSystemInfo:kIapItemPrefix] retain];
		iapCoinName  = [[SystemUtils getSystemInfo:@"kIapCoinName"] retain];
		iapLeafName  = [[SystemUtils getSystemInfo:@"kIapLeafName"] retain];
        iapPromotionName = [SystemUtils getSystemInfo:@"kIapPromotionName"];
        if(!iapPromotionName) iapPromotionName = @"Promo";
        [iapPromotionName retain];
        
        hasLeaf = NO;
        if(iapLeafName && [iapLeafName length]>0 && ![iapLeafName isEqualToString:iapCoinName])
            hasLeaf = YES;
        
        int i = 0;
        for(i=0;i<kIAPCoinCount;i++)
        {
            coinPriceList[i] = 0;
            leafPriceList[i] = 0;
            coinPackageList[i] = 0;
            leafPackageList[i] = 0;
        }
        
        NSArray *iapItemList = [SystemUtils getSystemInfo:@"kIapItemList"];
        if(iapItemList!=nil && [iapItemList count]>0) {
            // 通过iapItemList建立IAP列表
            NSMutableArray *arr2 = [NSMutableArray arrayWithCapacity:[iapItemList count]];
            for(NSString *itemName in iapItemList) {
                [arr2 addObject:[iapKeyPrefix stringByAppendingString:itemName]];
            }
            self.normalIapIDs = arr2;
        }
        else {
            // 通过coinName和leafName建立IAP列表
            int startPrice = [[SystemUtils getGlobalSetting:@"kMinIAPPrice"] intValue];
            
            NSString *priceList = [SystemUtils getSystemInfo:@"kIapCoinPriceList"];
            if(!priceList) priceList = @"1,5,10,20,50,100";
            NSArray *arr = [priceList componentsSeparatedByString:@","];
            i = 0;
            NSMutableArray *arr2 = [NSMutableArray arrayWithCapacity:kIAPCoinCount*2];
            for(NSString *price in arr)
            {
                if(i==0) {
                    if(startPrice==2 && [price intValue]==1) price = @"2";
                }
                i++;
                [arr2 addObject:[NSString stringWithFormat:@"%@%@%@",iapKeyPrefix, iapCoinName, price]];
            }
            
            if(hasLeaf)
            {
                NSString *priceList2 = [SystemUtils getSystemInfo:@"kIapLeafPackageList"];
                if(!priceList2) priceList2 = priceList;
                arr = [priceList componentsSeparatedByString:@","];
                i = 0;
                for(NSString *price in arr)
                {
                    if(i==0) {
                        if(startPrice==2 && [price intValue]==1) price = @"2";
                    }
                    i++;
                    [arr2 addObject:[NSString stringWithFormat:@"%@%@%@",iapKeyPrefix, iapLeafName, price]];
                }
            }
            self.normalIapIDs = arr2;
        }
        
        /*
             [NSArray arrayWithObjects:
						[NSString stringWithFormat:@"%@%@%i",iapKeyPrefix, iapCoinName, 1],
						[NSString stringWithFormat:@"%@%@%i",iapKeyPrefix, iapCoinName, 5],
						[NSString stringWithFormat:@"%@%@%i",iapKeyPrefix, iapCoinName, 10],
						[NSString stringWithFormat:@"%@%@%i",iapKeyPrefix, iapCoinName, 20],
						[NSString stringWithFormat:@"%@%@%i",iapKeyPrefix, iapCoinName, 50],
						[NSString stringWithFormat:@"%@%@%i",iapKeyPrefix, iapCoinName, 100],
						[NSString stringWithFormat:@"%@%@%i",iapKeyPrefix, iapLeafName, 1],
						[NSString stringWithFormat:@"%@%@%i",iapKeyPrefix, iapLeafName, 5],
						[NSString stringWithFormat:@"%@%@%i",iapKeyPrefix, iapLeafName, 10],
						[NSString stringWithFormat:@"%@%@%i",iapKeyPrefix, iapLeafName, 20],
						[NSString stringWithFormat:@"%@%@%i",iapKeyPrefix, iapLeafName, 50],
						[NSString stringWithFormat:@"%@%@%i",iapKeyPrefix, iapLeafName, 100],
						nil];
         */
		
		[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
		[self setDefaultProductList];
	}
	return self;
}

- (void) clearPendingPaymentInfo
{
    if(pendingVerifyTransaction) {
        [pendingVerifyTransaction release];
        pendingVerifyTransaction = nil;
    }
    if(pendingPaymentInfo) { 
        [pendingPaymentInfo release];
        pendingPaymentInfo = nil;
    }
    pendingTransactionStatus = kPendingTransactionStatusNone;
}

-(void)dealloc
{
	self.marketProducts = nil;
	self.normalIapIDs = nil;
	self.promoteIapIDs = nil;
	if(productInfoList) [productInfoList release];
	if(promoteInfoList) [promoteInfoList release];
    if(promotionIAPConfig) [promotionIAPConfig release];
    
    [iapKeyPrefix release]; 
    [iapCoinName release];
    [iapLeafName release];
    [iapPromotionName release];
    
    [self clearPendingPaymentInfo];
	/*
	if (delegate) {
		[(NSObject *)delegate release];
	}
	 */
	[super dealloc];
}


- (NSString *) getCachePath
{
	return [[SystemUtils getDocumentRootPath] stringByAppendingPathComponent:@"iapinfo.plist"];
}



- (NSMutableDictionary *)getDefaultProductInfo:(NSString *)ID
{
    if(!ID) return nil;
	NSDictionary *info = [self getProductPrice:ID];
	NSString *title = @"";
	int count = [[info objectForKey:@"count"] intValue];
	int leaf = 0; int coin = 0; 
	int type = [[info objectForKey:@"type"] intValue]; 
    NSString *itemName = [info objectForKey:@"itemName"];
	if(type==1) {
		coin = count;
	}
	else if(type==2) {
		leaf = count;
	}
    else if(type==3) {
        
    }
    else {
        
    }
    BOOL isCoin = (type==1);
	double price = 0; 
    NSString *decPrice = @""; 
    NSString *coinName1 = [SystemUtils getLocalizedString:@"CoinName1"];
    NSString *coinName2 = [SystemUtils getLocalizedString:@"CoinName2"];
    coinName1 = [StringUtils getCapitalizeWord:[StringUtils getPluralFormOfWord:coinName1]];
    coinName2 = [StringUtils getCapitalizeWord:[StringUtils getPluralFormOfWord:coinName2]];
	if(count == 1) {
		price = 0.99f; decPrice = @"0.99";
		if(isCoin) {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Chunk of %@"], coinName1];
		}
		else {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Chunk of %@"], coinName2];
		}
	}
	else if(count==2) {
		price = 1.99f; decPrice = @"1.99";
		if(isCoin) {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Lump of %@"], coinName1];
		}
		else {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Lump of %@"], coinName2];
		}
	}
	else if(count==5) {
		price = 4.99f; decPrice = @"4.99";
		if(isCoin) {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Wad of %@"], coinName1];
		}
		else {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Wad of %@"], coinName2];
		}
	}
	else if(count==10) {
		price = 9.99; decPrice = @"9.99";
		if(isCoin) {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Bundle of %@"], coinName1];
		}
		else {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Bundle of %@"], coinName2];
		}
	}
	else if(count==20) {
		price = 19.99f; decPrice = @"19.99";
		if(isCoin) {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Heap of %@"], coinName1];
		}
		else {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Heap of %@"], coinName2];
		}
	}
	else if(count==25) {
		price = 24.99f; decPrice = @"24.99";
		if(isCoin) {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Heap of %@"], coinName1];
		}
		else {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Heap of %@"], coinName2];
		}
	}
	else if(count==50) {
		price = 49.99; decPrice = @"49.99";
		if(isCoin) {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Barrel of %@"], coinName1];
		}
		else {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Barrel of %@"], coinName2];
		}
	}
	else if(count==100) {
		price = 99.99; decPrice = @"99.99";
		if(isCoin) {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Crate of %@"], coinName1];
		}
		else {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Crate of %@"], coinName2];
		}
	}
	else {
		price = 0.99f+count-1; decPrice = [NSString stringWithFormat:@"%i.99",count-1];
		if(isCoin) {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Heap of %@"], coinName1];
		}
		else {
			title = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Heap of %@"], coinName2];
		}
	}
#ifdef GAME_NAME_LOVE100
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if([bundleID isEqualToString:@"com.playdino.love100"]) {
        if(isCoin) {
            if(count==1) title = @"少量金币";
            if(count==5) title = @"一些金币";
            if(count==10) title = @"一束金币";
            if(count==20) title = @"一堆金币";
            if(count==50) title = @"一桶金币";
            if(count==100) title = @"一箱金币";
        }
        else {
            if(count==1) title = @"少量钻石";
            if(count==5) title = @"一些钻石";
            if(count==10) title = @"一束钻石";
            if(count==20) title = @"一堆钻石";
            if(count==50) title = @"一桶钻石";
            if(count==100) title = @"一箱钻石";
        }
    }
#endif
	// if(leaf>0) leaf = [self getIAPLeafCount:leaf];
	
	// NSDecimalNumber *decPrice = [[NSDecimalNumber alloc] initWithDouble:price];
	// [decPrice autorelease];
    // NSString *decPrice = [NSString stringWithFormat:@"%.2lf",price];
    
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	[dict autorelease];
	[dict setObject:title forKey:@"Title"];
	[dict setObject:@"" forKey:@"Desc"];
	[dict setObject:decPrice forKey:@"Price"];
	[dict setObject:decPrice forKey:@"OriginalPrice"];
	[dict setObject:ID forKey:@"ID"];
	[dict setObject:@"$" forKey:@"CurrencySymbol"];
	[dict setObject:@"USD" forKey:@"CurrencyCode"];
	[dict setObject:[NSNumber numberWithInt:0] forKey:@"discount"];
	[dict setObject:[NSNumber numberWithInt:coin] forKey:iapCoinName];
	[dict setObject:[NSNumber numberWithInt:leaf] forKey:iapLeafName];
	return dict;
}

- (void) setDefaultProductList
{
	if(productInfoList!=nil) return;
    /*
	// load from cache
	NSString *filePath = [self getCachePath];
	NSFileManager *mgr = [NSFileManager defaultManager];
	if([mgr fileExistsAtPath:filePath])
	{
		productInfoList = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
	}
	if(productInfoList && [productInfoList count]==0) {
		[productInfoList release]; productInfoList = nil; 
	}
	if(productInfoList) {
		NSLog(@"load productInfoList from cache file %@ ok", filePath);
		return;
	}
     */
	// init with default value
	productInfoList = [[NSMutableArray alloc] init];
	for(int i=0;i<[normalIapIDs count];i++)
	{
		[productInfoList addObject:[self getDefaultProductInfo:[normalIapIDs objectAtIndex:i]]];
	}
}

// 获取当前有效的产品ID
- (void)resetProductIDs
{
	// self.normalIapIDs = normalIDs;
	// self.promoteIapIDs = promoteIDs;
}

- (NSMutableDictionary *)parseProductDetail:(SKProduct *)p
{
	if(!p) return nil;
	
	// int promotionRate = [SystemUtils getPromotionRate];
	// NSLog(@"%s: rate:%i", __func__, promotionRate);
	
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	[dict autorelease];
	NSString *title = [SystemUtils getLocalizedString:p.localizedTitle];
	if([title isEqualToString:p.localizedTitle]) {
		if([[title substringFromIndex:[title length]-1] isEqualToString:@" "])
		{
			title = [SystemUtils getLocalizedString:[title substringToIndex:[title length]-1]];
		}
	}
	[dict setObject:title forKey:@"Title"];
	if(p.localizedDescription) [dict setObject:p.localizedDescription forKey:@"Desc"];
    NSString *price = [NSString stringWithFormat:@"%@",p.price];
	[dict setObject:price forKey:@"Price"];
	[dict setObject:price forKey:@"OriginalPrice"];
	[dict setObject:p.productIdentifier forKey:@"ID"];
	[dict setObject:[p.priceLocale objectForKey:NSLocaleCurrencySymbol] forKey:@"CurrencySymbol"];
	[dict setObject:[p.priceLocale objectForKey:NSLocaleCurrencyCode] forKey:@"CurrencyCode"];
	// ID，Coin，Leaf，Rate，Price，Name，OriginalPrice, discount
	[dict setObject:[NSNumber numberWithInt:0] forKey:@"discount"];
	[dict setObject:p.productIdentifier forKey:@"priceKey"];
	
	NSCharacterSet *sep = [NSCharacterSet characterSetWithCharactersInString:@"."];
	NSArray *arr = [p.productIdentifier componentsSeparatedByCharactersInSet:sep];
	if([arr count]>=4) {
		// calculate leaf and coin
		[dict setObject:[NSNumber numberWithInt:0] forKey:iapCoinName];
		[dict setObject:[NSNumber numberWithInt:0] forKey:iapLeafName];
        [dict setObject:[NSNumber numberWithInt:0] forKey:iapPromotionName];
		NSString *key = [arr objectAtIndex:3];
        [dict setValue:key forKey:@"shortID"];
		// NSCharacterSet *sep2 = [NSCharacterSet characterSetWithCharactersInString:@"_"];
		// NSArray *arr2 = [key componentsSeparatedByCharactersInSet:sep2];
		// key = [arr2 objectAtIndex:0];
		
		NSString *coinType = nil;  int count = 0;
		if([key length]>[iapCoinName length]) {
			coinType = [key substringToIndex:[iapCoinName length]];
			if([coinType isEqualToString:iapCoinName]) 
			{
				count = [[key substringFromIndex:[iapCoinName length]] intValue];
            }
            if(count>0) {
				[dict setObject:[NSNumber numberWithInt:count] forKey:iapCoinName];
			}
			else 
				coinType = nil;
		}
		if(!coinType && [key length]>[iapLeafName length]) {
			coinType = [key substringToIndex:[iapLeafName length]];
			if([coinType isEqualToString:iapLeafName]) 
			{
				count = [[key substringFromIndex:[iapLeafName length]] intValue];
            }
            if(count>0) {
				// count = [self getIAPLeafCount:count];
				[dict setObject:[NSNumber numberWithInt:count] forKey:iapLeafName];
				
				SNSLog(@"%s: id:%@ leaf:%i", __func__, p.productIdentifier, count);
			}
			else 
				coinType = nil;
		}
		if(coinType==nil && [key length]>[iapPromotionName length]) {
			coinType = [key substringToIndex:[iapPromotionName length]];
			if([coinType isEqualToString:iapPromotionName]) 
			{
				count = [[key substringFromIndex:[iapPromotionName length]] intValue];
            }
            if(count>0) {
				// count = [self getIAPLeafCount:count];
				[dict setObject:[NSNumber numberWithInt:count] forKey:iapPromotionName];
				
				SNSLog(@"%s: id:%@ promo:%i", __func__, p.productIdentifier, count);
			}
			else 
				coinType = nil;
		}
        
        if(coinType==nil) {
            int i = [key length]-1;
            while(i>=0) {
                char ch = [key characterAtIndex:i];
                if(ch>'9' || ch<'0') break;
                i--;
            }
            int count = [[key substringFromIndex:i+1] intValue];
            coinType = [key substringToIndex:i+1];
            [dict setObject:[NSNumber numberWithInt:count] forKey:coinType];
            [dict setObject:coinType forKey:@"itemName"];
        }
	}
	
	return dict;
}

- (void) loadPromotionIAPList
{
    if(promoteIapIDs != nil) return;
    // check promotion item list
    NSDictionary *dict = [SystemUtils getSystemInfo:kRemoteConfigFileDict];
    if(!(dict && [dict isKindOfClass:[NSDictionary class]])) return;
    
    NSString *file = [dict objectForKey:@"PromotionIAPList"];
    if(!file) return;
    file = [[SystemUtils getItemRootPath] stringByAppendingPathComponent:file];
    if(![[NSFileManager defaultManager] fileExistsAtPath:file]) return;
    
    NSString *text = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    if(text && [text length]>50 && [text characterAtIndex:0]=='|') 
        text = [SystemUtils stripHashFromSaveData:text];
    if(!text) return;
    NSArray *arr = [text JSONValue];
    if(!arr || ![arr isKindOfClass:[NSArray class]] || [arr count]==0) return;
    
    promotionIAPConfig = [[NSMutableDictionary alloc] initWithCapacity:[arr count]];
    NSMutableArray *arr2 = [[NSMutableArray alloc] initWithCapacity:[arr count]];
    for(NSDictionary *dict in arr)
    {
        if(![dict isKindOfClass:[NSDictionary class]]) continue;
        NSString *ID = [dict objectForKey:@"ID"];
        [promotionIAPConfig setObject:dict forKey:ID];
        [arr2 addObject:[iapKeyPrefix stringByAppendingFormat:@"%@%@", iapPromotionName, ID]];
    }
    
    SNSLog(@"iapconfig:%@\npromotionIDs:%@",arr,arr2);
    
    self.promoteIapIDs = arr2; [arr2 release];
}

// 获得促销专用IAP的奖励信息
- (NSDictionary *)getPromotionIAPInfo:(int)price
{
    if(!promotionIAPConfig) [self loadPromotionIAPList];
    if(!promotionIAPConfig || [promotionIAPConfig count]==0) return nil;
    NSString *ID = [NSString stringWithFormat:@"%i", price];
    return [promotionIAPConfig objectForKey:ID];
}

- (void) requestProductData
{
	if(downloadOK) return;
    isRestoring = NO;
	/*
	if(![NetworkHelper helper].connectedToInternet) {
		self.storeStatus = AppStoreStatusNotReady;
		return;
	}
	 */
	SNSLog(@"%s",__FUNCTION__);
    int now = [SystemUtils getCurrentTime];
    
	if(self.storeStatus == AppStoreStatusLoading && lastLoadingTime>now-10) return;
    lastLoadingTime = now;
	self.storeStatus = AppStoreStatusLoading;
    
    [self loadPromotionIAPList];
    
	//request apple for the products
	//[self displayPleaseWait];
	[self resetProductIDs];
	NSMutableSet *ids = [[NSMutableSet alloc] initWithArray:normalIapIDs];
	if(promoteIapIDs != nil)
		[ids addObjectsFromArray:promoteIapIDs];
	SNSLog(@"iap ids:%@", ids);
	SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:ids];
	request.delegate = self;
	[request start];
	if(req != nil) [req release];
	req = request;
	requestIDs = ids;
}

#pragma mark SKProductsRequest delegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	SNSLog(@"%s: prodCount:%i invalid IDs:%@",__FUNCTION__, [response.products count], response.invalidProductIdentifiers);
	
	//[self removePleaseWait];
	self.storeStatus = AppStoreStatusReady;
	refreshTime = [SystemUtils getCurrentTime];
	
	NSArray *products = response.products;
	if([products count]==0) return;
	
	downloadOK = YES;
	
	if(productInfoList) [productInfoList release];
	productInfoList = [[NSMutableArray alloc] init];
	if(promoteInfoList) [promoteInfoList release];
	promoteInfoList = [[NSMutableArray alloc] init];
	
	NSMutableArray *coinInfoList = [[NSMutableArray alloc] init];
	NSMutableArray *leafInfoList = [[NSMutableArray alloc] init];
	
	NSMutableDictionary *origPriceInfo = [[NSMutableDictionary alloc] init];
	
	for (SKProduct *prod in products)
	{
		if (prod)
		{
			/*
			NSLog(@"Product title: %@" , prod.localizedTitle);
			NSLog(@"Product description: %@" , prod.localizedDescription);
			NSLog(@"Product price: %@" , prod.price);
			NSLog(@"Product id: %@" , prod.productIdentifier);
			NSLog(@"currency: %@ code:%@", [prod.priceLocale objectForKey:NSLocaleCurrencySymbol], [prod.priceLocale objectForKey:NSLocaleCurrencyCode]);
			 */
			// Add to productInfoList
			NSMutableDictionary *info = [self parseProductDetail:prod];
            if([[info objectForKey:iapPromotionName] intValue]>0) {
                [promoteInfoList addObject:info];
            }
			else if([[info objectForKey:@"discount"] intValue]==0) {
				
				if([[info objectForKey:iapCoinName] intValue]>0) 
					[coinInfoList addObject:info];
				else
					[leafInfoList addObject:info];
				
				if([info objectForKey:@"priceKey"]) 
					[origPriceInfo setObject:[info objectForKey:@"Price"] forKey:[info objectForKey:@"priceKey"]];
			}
		}
	}
	
	int i = 0, j = 0;
	// resort
    if([coinInfoList count]>0) {
        for(i=0;i<[coinInfoList count]-1;i++)
        {
            NSMutableDictionary *info = [coinInfoList objectAtIndex:i];
            int coin = [[info objectForKey:iapCoinName] intValue];
            for(j=i+1;j<[coinInfoList count];j++)
            {
                NSMutableDictionary *info2 = [coinInfoList objectAtIndex:j];
                int coin2 = [[info2 objectForKey:iapCoinName] intValue];
                if(coin > coin2) {
                    // switch
                    [info retain]; [info2 retain];
                    [coinInfoList removeObjectAtIndex:i];
                    [coinInfoList insertObject:info2 atIndex:i];
                    [coinInfoList removeObjectAtIndex:j];
                    [coinInfoList insertObject:info atIndex:j];
                    [info release]; [info2 release];
                    info = info2; coin = coin2;
                }
            }
        }
    }
    
	if([leafInfoList count]>0) {
        for(i=0;i<[leafInfoList count]-1;i++)
        {
            NSMutableDictionary *info = [leafInfoList objectAtIndex:i];
            int coin = [[info objectForKey:iapLeafName] intValue];
            for(j=i+1;j<[leafInfoList count];j++)
            {
                NSMutableDictionary *info2 = [leafInfoList objectAtIndex:j];
                int coin2 = [[info2 objectForKey:iapLeafName] intValue];
                if(coin > coin2) {
                    // switch
                    [info retain]; [info2 retain];
                    [leafInfoList removeObjectAtIndex:i];
                    [leafInfoList insertObject:info2 atIndex:i];
                    [leafInfoList removeObjectAtIndex:j];
                    [leafInfoList insertObject:info atIndex:j];
                    [info release]; [info2 release];
                    info = info2; coin = coin2;
                }
            }
        }
	}
    // 按照systemconfig.plist中的顺序排序
    NSArray *iapIDList = [SystemUtils getSystemInfo:@"kIapItemList"];
    if(iapIDList!=nil &&[iapIDList count]>0) {
        for (NSString *iapID in iapIDList) {
            BOOL found = NO;
            for(NSMutableDictionary *info in coinInfoList) {
                if([iapID isEqualToString:[info objectForKey:@"shortID"]]) {
                    [productInfoList addObject:info];
                    [coinInfoList removeObject:info];
                    found = YES;
                    break;
                }
            }
            if(found) continue;
            for(NSMutableDictionary *info in leafInfoList) {
                if([iapID isEqualToString:[info objectForKey:@"shortID"]]) {
                    [productInfoList addObject:info];
                    [leafInfoList removeObject:info];
                    found = YES;
                    break;
                }
            }
            
        }
    }
	[productInfoList addObjectsFromArray:coinInfoList];
	[productInfoList addObjectsFromArray:leafInfoList];
	[coinInfoList release]; [leafInfoList release];
	
	// get original price
	for(i=0;i<[promoteInfoList count];i++)
	{
		NSMutableDictionary *info = [promoteInfoList objectAtIndex:i];
		NSNumber *origPrice = [origPriceInfo objectForKey:[info objectForKey:@"priceKey"]];
		if(origPrice) [info setObject:origPrice forKey:@"OriginalPrice"];
	}
	[origPriceInfo release];
#ifdef DEBUG
	NSLog(@"productInfoList: %@\npromoteInfoList:%@", productInfoList, promoteInfoList);
#endif
	// save to cache product info
	NSString *cacheFile = [self getCachePath];
	[productInfoList writeToFile:cacheFile atomically:YES];
	
	self.marketProducts = products;
	// [request release];
	[req release];
	req = nil; 
	[requestIDs release]; requestIDs = nil;
	// show promoted notice
	[SystemUtils showPromoteNotice];
	// buy a item
	// [self buyAppStoreItem:@"com.playdino.PetInn.Leaf1" amount:1 withDelegate:nil];
    
    isVerifyServerOK = YES;
    [self verifySavedPendingTransaction];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
	SNSLog(@"%s: error:%@", __FUNCTION__, error);
	self.storeStatus = AppStoreStatusNotReady;
	[req release];
	req = nil; 
	[requestIDs release]; requestIDs = nil;
}

#pragma mark -


- (BOOL) buyAppStoreItem:(NSString*)itemID amount:(int)amount withDelegate:(id<InAppStoreDelegate>)del
{
    isRestoring = NO;
#ifdef DEBUG
    // if([itemID isEqualToString:@"com.topgame.PetHome2.Coin2"])
    //    itemID = @"com.topgame.PetHome2.Promo5";
#endif
	if(delegate) {
        SNSLog(@"delegate exists");
		// request pending
		UIAlertView *aw = [[UIAlertView alloc] initWithTitle:[SystemUtils getLocalizedString:@"Transaction Pending"] 
													 message:[SystemUtils getLocalizedString:@"Another transaction is pending, please try again later."]
													delegate:nil 
										   cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"] 
										   otherButtonTitles:nil];
		[aw show];
		[aw release];
		return NO;
	}
	/*
	if (![NetworkHelper helper].connectedToInternet)
	{
		UIAlertView *aw = [[UIAlertView alloc] initWithTitle:[SystemUtils getLocalizedString:@"Network Required"]
													 message:[SystemUtils getLocalizedString:@"You must be connected to the Internet to make purchases."]
													delegate:nil 
										   cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
										   otherButtonTitles:nil];
		[aw show];
		[aw release];
		return NO;
	}
     */
	
	if (![SKPaymentQueue canMakePayments])
	{
		// Warn the user that purchases are disabled.
		UIAlertView *aw = [[UIAlertView alloc] initWithTitle:[SystemUtils getLocalizedString:@"In App purchasing is disabled"]
													 message:[SystemUtils getLocalizedString:@"Please check your device restrictions and settings."]
													delegate:nil 
										   cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
										   otherButtonTitles:nil];
		[aw show];
		[aw release];
		return NO;
	}	
	else if ([SKPaymentQueue defaultQueue].transactions.count > 0)
	{
		UIAlertView *aw = [[UIAlertView alloc] initWithTitle:[SystemUtils getLocalizedString:@"Transaction Pending"]
													 message:[SystemUtils getLocalizedString:@"Another transaction is pending, please try again later."]
													delegate:nil 
										   cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
										   otherButtonTitles:nil];
		[aw show];
		[aw release];
        SNSLog(@"another transaction pending");
		return NO;
	}
	
	SKProduct *product = nil;
	
	for (SKProduct *curProduct in marketProducts)
	{
		if ([curProduct.productIdentifier isEqualToString:itemID])
		{
			product = curProduct;
			break;
		}
	}
	
#ifdef DEBUG
#ifdef SNS_SIMULATE_BUY_IAP
    m_simulateIAPItem = [itemID retain];
    [self performSelector:@selector(simulateBuyIAPItem) withObject:nil afterDelay:3.0f];
    delegate = del;
    return  YES;
#endif
#endif
    
	if (product)
	{
		//SKMutablePayment *payment = [SKMutablePayment paymentWithProductIdentifier:itemID];
		SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
		payment.quantity = amount;//amount; // number of "items" that user wishes to purchase.
		[[SKPaymentQueue defaultQueue] addPayment:payment];
		// [self displayPleaseWait];
		paymentPending = YES;
        if(delegate==nil) [SystemUtils showInGameLoadingView];
	}
	else 
	{
		UIAlertView *aw = [[UIAlertView alloc] initWithTitle:[SystemUtils getLocalizedString:@"Downloading Products"]
													 message:[SystemUtils getLocalizedString:@"The application is downloading IAP products in background, please try again later."]
													delegate:nil 
										   cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
										   otherButtonTitles:nil];
        SNSLog(@"product not found:%@", itemID);
		[del transactionCancelled];  //出错取消交易
		[aw show];
		[aw release];
		
		// self.marketProducts = nil;
		[self requestProductData]; //repeat the cycle and hope it comes back with valid products
		return NO;
	}
	delegate = del;
	return YES;
	
}


- (void) restoreIAP:(id<InAppStoreDelegate>)del
{
    if(!downloadOK) {
		UIAlertView *aw = [[UIAlertView alloc] initWithTitle:[SystemUtils getLocalizedString:@"Downloading Products"]
													 message:[SystemUtils getLocalizedString:@"The application is downloading IAP products in background, please try again later."]
													delegate:nil
										   cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
										   otherButtonTitles:nil];
        // SNSLog(@"product not found:%@", itemID);
		[aw show];
		[aw release];
        if(del) {
            NSObject<InAppStoreDelegate> *del2 = del;
            [del2 performSelector:@selector(transactionCancelled) withObject:nil afterDelay:1.0f];  //出错取消交易
        }
        return;
    }
    isRestoring = YES;
    delegate = del;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    if(del==nil) [SystemUtils showInGameLoadingView];
}

- (void) transactionFinished:(NSDictionary *)info
{
    if(pendingVerifyTransaction) {
        [[SKPaymentQueue defaultQueue] finishTransaction: pendingVerifyTransaction];
        [pendingVerifyTransaction release];
        pendingVerifyTransaction = nil;
    }
	if(delegate) {
		[delegate transactionFinished:info];
		delegate = nil;
	}
    else {
        [SystemUtils hideInGameLoadingView];
    }
    [self clearPendingPaymentInfo];
    
    if(isVerifyServerOK)
        [self verifySavedPendingTransaction];
}

#pragma mark SKPaymentTransactionObserver

// Sent when all transactions from the user's purchase history have successfully been added back to the queue.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    int restoreCount = [[queue transactions] count];
    if (restoreCount == 0) {
        //show no purchases before warning
        NSString *mesg = [SystemUtils getLocalizedString:@"Sorry, no previous purchases could be restored."];
        [SystemUtils showPaymentFailNotice:mesg];
        if (delegate) {
            [delegate transactionCancelled];
            delegate = NULL;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    if(transactions==nil || [transactions count]==0) {
        SNSLog(@"no transactions found.");
        if(isRestoring) {
            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:@"You haven't purchased any non-consumable products yet.",@"mesg", nil];
            [SystemUtils showCustomNotice:info];
            isRestoring = NO;
        }
        return;
    }
    BOOL showRestoreHint = NO;
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                // [self restoreTransaction:transaction];
                [self completeTransaction:transaction];
                if (delegate) {
                    //TODO: add restore info for different purchases.
                    [delegate restoreFinished:nil]; 
                }
                showRestoreHint = YES;
            default:
                break;
        }
    }
    if(isRestoring) {
        if(showRestoreHint) {
            // show restore hint
            NSString *mesg = [SystemUtils getLocalizedString:@"Purchases have been successfully restored!"];
            [SystemUtils showPaymentNotice:mesg];
        }
        if (delegate) {
            delegate = NULL;
        }
    }
}
 

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    // test error.code, if it equals SKErrorPaymentCancelled it's been cancelled
    if (delegate) {
        [delegate transactionCancelled];
        delegate = nil;
    }
    // if (error.code == SKErrorPaymentCancelled) {
    // }
}

- (void) removeSavedPendingTransaction:(NSString *)tid
{
    NSMutableArray *arr2 = nil; NSArray *arr = nil;
    int i=0;
    arr = [SystemUtils getNSDefaultObject:@"kSNSPendingReceipt"];
    if(arr && [arr isKindOfClass:[NSArray class]]) {
        arr2 = [NSMutableArray arrayWithArray:arr];
    }
    if(arr2) {
#ifdef DEBUG
        SNSLog(@"arr2:%@",arr2);
#endif
        [arr2 retain];
        i = 0;
        while(i<[arr2 count]) {
            NSDictionary *dict = [arr2 objectAtIndex:i];
            NSString *tid2 = [dict objectForKey:@"tid"];
            if(tid2 && [tid isEqualToString:tid2]) {
                [arr2 removeObjectAtIndex:i];
            }
            else {
                i++;
            }
        }
        // save transaction for later verify
        [SystemUtils setNSDefaultObject:arr2 forKey:@"kSNSPendingReceipt"];
        [arr2 release];
    }
    
    arr2 = nil;
    arr = [SystemUtils getGlobalSetting:@"kSNSPendingReceipt"];
    if(arr && [arr isKindOfClass:[NSArray class]]) {
        arr2 = [NSMutableArray arrayWithArray:arr];
    }
    if(arr2) {
#ifdef DEBUG
        SNSLog(@"arr2:%@",arr2);
#endif
        [arr2 retain];
        i = 0;
        while(i<[arr2 count]) {
            NSDictionary *dict = [arr2 objectAtIndex:i];
            NSString *tid2 = [dict objectForKey:@"tid"];
            if(tid2 && [tid isEqualToString:tid2]) {
                [arr2 removeObjectAtIndex:i];
            }
            else {
                i++;
            }
        }
        // save transaction for later verify
        [SystemUtils setGlobalSetting:arr2 forKey:@"kSNSPendingReceipt"];
        [arr2 release];
    }
    
}

- (void) saveToPendingTransaction:(NSDictionary *)info
{
    SNSLog(@"info:%@",info);
    if(!info) return;
    NSMutableArray *arr2 = nil; NSArray *arr = nil;
    
    arr = [SystemUtils getNSDefaultObject:@"kSNSPendingReceipt"];
    if(arr && [arr isKindOfClass:[NSArray class]]) {
        arr2 = [NSMutableArray arrayWithArray:arr];
    }
    else {
        arr2 = [NSMutableArray arrayWithCapacity:1];
    }
    [arr2 retain]; [arr2 addObject:info];
    // save transaction for later verify
    [SystemUtils setNSDefaultObject:arr2 forKey:@"kSNSPendingReceipt"];
    [arr2 release];
    
    arr2 = nil;
    arr = [SystemUtils getGlobalSetting:@"kSNSPendingReceipt"];
    if(arr && [arr isKindOfClass:[NSArray class]]) {
        arr2 = [NSMutableArray arrayWithArray:arr];
    }
    else {
        arr2 = [NSMutableArray arrayWithCapacity:1];
    }
    [arr2 retain]; [arr2 addObject:info];
    // save transaction for later verify
    [SystemUtils setGlobalSetting:arr2 forKey:@"kSNSPendingReceipt"];
    [arr2 release];
}

- (void) completeTransaction: (SKPaymentTransaction *)transaction
{
	paymentPending = NO;
	SNSLog(@"%s - %@",__FUNCTION__, transaction);
    NSString *transactionID = transaction.transactionIdentifier;
    if([SystemUtils isIapTransactionUsed:transactionID] && transaction.transactionState==SKPaymentTransactionStatePurchased) {
        SNSLog(@"%@:this transaction already processed.", transactionID);
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
        if(delegate) {
            [delegate transactionCancelled]; delegate = nil;
        }
        return;
    }
#ifdef SNS_ENABLE_ADX
    SKProduct *product = nil;
    for (SKProduct *curProduct in marketProducts)
    {
        if ([curProduct.productIdentifier isEqualToString:transaction.payment.productIdentifier])
        {
            product = curProduct;
            break;
        }
    }
    if(product!=nil) {
        NSString *currency = [product.priceLocale objectForKey:NSLocaleCurrencyCode];
        [[AdxHelper helper] trackPurchase:[NSString stringWithFormat:@"%@",product.price] currency:currency withTransaction:transaction sandbox:0];
     }
#endif

	// Your application should implement these two methods.
    [self clearPendingPaymentInfo];
    pendingVerifyTransaction = [transaction retain];
    pendingTransactionStatus = kPendingTransactionStatusNone;
	
    NSString *iapID = transaction.payment.productIdentifier;
    int quantity = transaction.payment.quantity;
    
    NSDictionary *priceInfo = [self getProductPrice:iapID];
    // float price = [[priceInfo objectForKey:@"price"] floatValue]*100;
    int price2 = [[priceInfo objectForKey:@"priceUSD"] intValue]*100-1;
    
	NSString *receipt = [Base64 encode:transaction.transactionReceipt];     
	NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:receipt, @"receipt-data", nil];
	NSString *verifyPostData = [StringUtils convertObjectToJSONString:data];
    
    NSString *receiptBytes = [StringUtils hexRepresentationOfNSData:transaction.transactionReceipt];
    NSString *isRestore = @"0";
    if(transaction.transactionState == SKPaymentTransactionStateRestored) isRestore = @"1";
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:iapID, @"ID", transactionID, @"tid", [NSNumber numberWithInt:quantity], @"amount", [NSNumber numberWithInt:price2], @"price", verifyPostData, @"verifyPostData", receiptBytes, @"receiptData", isRestore, @"isRestore", nil];
    
    [self saveToPendingTransaction:userInfo];
    
    pendingPaymentInfo = [userInfo retain];
    
    SyncQueue* syncQueue = [SyncQueue syncQueue];
    PaymentSendOperation* saveOp = [[PaymentSendOperation alloc] initWithManager:syncQueue andDelegate:nil];
    saveOp.paymentInfo = pendingPaymentInfo;
    [syncQueue.operations addOperation:saveOp];
    [saveOp release];
    
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        // Optionally, display an error here.
        SNSLog(@"%s: error info: %@", __func__, transaction.error);
        // show alert info
        [SystemUtils showPaymentFailNotice:transaction.error.localizedDescription];
        // [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }
	if(delegate) {
		[delegate transactionCancelled]; delegate = nil;
	}
    else {
        [SystemUtils hideInGameLoadingView];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	paymentPending = NO;
}

#pragma mark -

#pragma mark Payment Verification

- (void) verifyPendingTransaction
{
    if(!pendingVerifyTransaction) return;
    [self verifyTransaction:pendingVerifyTransaction];
}

// verify receipt
- (void) verifyTransaction:(SKPaymentTransaction *)transaction
{
	// SKPayment *payment = [transaction payment];
	// NSString *itemId = [payment productIdentifier];
	// int amount = [payment quantity];
	// NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:itemId, @"itemId", [NSNumber numberWithInt:amount], @"amount", nil];
	
	NSURL *verifyURL = [NSURL URLWithString:VAILDATING_RECEIPTS_URL];
	ECPurchaseHTTPRequest *request = [[ECPurchaseHTTPRequest alloc] initWithURL:verifyURL];
	[request setProductIdentifier:transaction.payment.productIdentifier];
	[request setRequestMethod: @"POST"];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(didFinishVerifyTransaction:)];
	//[request setShouldRedirect: NO];
	[request addRequestHeader: @"Content-Type" value: @"application/json"];
	// request.userInfo = info;
	request.paymentTransaction = transaction;
	
	//NSString *recepit = [[NSString alloc] initWithData:transaction.transactionReceipt encoding:NSUTF8StringEncoding];
	NSString *recepit = [Base64 encode:transaction.transactionReceipt];
	NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:recepit, @"receipt-data", nil];
	NSString *jsonString = [data JSONRepresentation];
    request.m_receiptVerifyData = jsonString;
	[request appendPostData: [jsonString dataUsingEncoding: NSUTF8StringEncoding]];
	ASINetworkQueue *_networkQueue = [ASINetworkQueue queue];
	[_networkQueue addOperation: request];
	[_networkQueue go];
}

// 对存储在global.dat中的支付信息进行验证
- (void) verifySavedPendingTransaction
{
    NSMutableArray *arr = [SystemUtils getGlobalSetting:@"kSNSPendingReceipt"];
    if(arr && [arr isKindOfClass:[NSArray class]] && [arr count]>0) {
        pendingPaymentInfo = [[arr objectAtIndex:0] retain];
        SyncQueue* syncQueue = [SyncQueue syncQueue];
        PaymentSendOperation* saveOp = [[PaymentSendOperation alloc] initWithManager:syncQueue andDelegate:nil];
        saveOp.paymentInfo = pendingPaymentInfo;
        [syncQueue.operations addOperation:saveOp];
        [saveOp release];
    }
}

- (void) releaseRequest:(ECPurchaseHTTPRequest *)request
{
	if(request) {
        [request release]; request = nil;
    }
    
}

- (void) showLocalVerifyFailHint:(NSString *)hint
{
    NSDictionary *info2 = [NSDictionary dictionaryWithObjectsAndKeys:pendingPaymentInfo, @"paymentInfo", hint, @"errorHint", nil];
    [SystemUtils showInvalidTransactionAlert:info2];    
}

- (void) acceptPendingTransaction
{
    isVerifyServerOK = NO;
    // 简单的本地检查
    NSString *tid = [pendingPaymentInfo objectForKey:@"tid"];
    for (int i=0; i<[tid length]; i++) {
        unichar ch = [tid characterAtIndex:i];
        if(ch<'0' || ch>'9') {
            [self showLocalVerifyFailHint:[NSString stringWithFormat:@"Invalid tid:%@",tid]];
            return;
        }
    }
    if([tid length]<13) {
        [self showLocalVerifyFailHint:[NSString stringWithFormat:@"Invalid tid length:%@",tid]];
        return;
    }
    
    NSString *product_id  = [pendingPaymentInfo objectForKey:@"ID"];
    
    
    NSString *quantity = [NSString stringWithFormat:@"%@", [pendingPaymentInfo objectForKey:@"amount"]];
    NSDictionary *receipt = [NSDictionary dictionaryWithObjectsAndKeys:
                             tid, @"transaction_id",
                             quantity, @"quantity",
                             product_id, @"product_id",
                             nil];
    [self acceptPendingTransactionResponse:receipt];
}
- (void) requestCancel:(ASIHTTPRequest *)request
{
    [self acceptPendingTransaction];
	[self releaseRequest:(ECPurchaseHTTPRequest *)request];
}

- (void) acceptPendingTransactionResponse:(NSDictionary *)receipt
{
    
    NSString *transactionID = [receipt objectForKey:@"transaction_id"];
    
    if([SystemUtils isIapTransactionUsed:transactionID]) {
        [self transactionFinished:nil];
        return;
    }
    [SystemUtils addIapTransactionID:transactionID];
    
    NSString *productIdentifier = [receipt objectForKey: @"product_id"];
    NSString *quantity = [NSString stringWithFormat:@"%@",[receipt objectForKey:@"quantity"]];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:productIdentifier, @"itemId", transactionID, @"tid", quantity, @"amount", nil];
    int isRestore = [[pendingPaymentInfo objectForKey:@"isRestore"] intValue];
    if(isRestore==1) {
        [SystemUtils setNSDefaultObject:productIdentifier forKey:@"restoreIapID"];
    }
    // save to history
    [[NSNotificationCenter defaultCenter] postNotificationName:kInAppStoreItemBoughtNotification object:nil userInfo:userInfo];
    // Remove the transaction from the payment queue.
    [self transactionFinished:userInfo];
}

-(void)didFinishVerifyTransaction:(ECPurchaseHTTPRequest *)request
{
	paymentPending = NO;
    
	NSData *jsonData = [request responseData];
	if(!jsonData || [jsonData length]==0) {
        [self requestCancel:request];
        return;
	}
	NSString *jsonString = [[NSString alloc] initWithBytes:jsonData.bytes length:jsonData.length encoding:NSUTF8StringEncoding];
	[jsonString autorelease];
	NSDictionary* dictInfo = [jsonString JSONValue];
	if(!dictInfo || ![dictInfo isKindOfClass:[NSDictionary class]])
	{
        [self requestCancel:request];
		return;
	}
	
	SNSLog(@"%s: response info:%@", __FUNCTION__, dictInfo);
	NSString *status = [dictInfo objectForKey: @"status"];
    NSDictionary *receipt = [dictInfo objectForKey: @"receipt"];
    NSString *prodID = [pendingPaymentInfo objectForKey:@"ID"];
	if (status && [status intValue] == 0 && receipt!=nil
        && [prodID isEqualToString:[receipt objectForKey:@"product_id"]]) {
        [self acceptPendingTransactionResponse:receipt];
        [self releaseRequest:request];
        return;
	}
    else {
        if([status intValue]==21002) {
            NSDictionary *info2 = [NSDictionary dictionaryWithObjectsAndKeys:dictInfo, @"resp", pendingPaymentInfo, @"request", nil];
            [SystemUtils showInvalidTransactionAlert:info2];
        }
        
        [self removeSavedPendingTransaction:[pendingPaymentInfo objectForKey:@"tid"]];
        // Mark this user as hacker
        [SystemUtils setGlobalSetting:@"100" forKey:kHackTime];
        
        SNSLog(@"invalid transaction: %@", dictInfo);
        [self transactionFinished:nil];
        [self releaseRequest:(ECPurchaseHTTPRequest *)request];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
#ifdef DEBUG
	NSError *error = [request error];
	NSLog(@"%s - error: %@", __FUNCTION__, error);
#endif
    [self requestCancel:request];
}

#pragma mark -


// 获取产品列表：ID，Coin，Leaf，Rate，Price，Name，OriginalPrice
-(NSArray *)getProductList
{
	/*
	if([SystemUtils isPromotionReady]) {
		if(promoteInfoList && [promoteInfoList count]>0) return promoteInfoList;
	}
	else {
		BOOL isWeekend = NO;
		int weekday = [SystemUtils getCurrentWeekDay];
		if(weekday==1 || weekday==7) isWeekend = YES;
		if(isWeekend && promoteInfoList && [promoteInfoList count]>0) {
			NSLog(@"%s: weekend promotion weekday=%i", __FUNCTION__, weekday);
			return promoteInfoList;
		}
	}
	 */
    if(!downloadOK) [self requestProductData];
	return productInfoList;
}

-(NSArray *)getCountDownPromotions
{
	return nil;
	/*
	NSMutableArray *arr = [[NSMutableArray alloc] init];
	for(int i=0;i<[promoteInfoList count];i++)
	{
		NSDictionary *info = [promoteInfoList objectAtIndex:i];
		NSString *ID = [info objectForKey:@"ID"];
		NSRange rang = [ID rangeOfString:@"Leaf10."];
		if(rang.location != NSNotFound) [arr addObject:info];
	}
	for(int i=0;i<[promoteInfoList count];i++)
	{
		NSDictionary *info = [promoteInfoList objectAtIndex:i];
		NSString *ID = [info objectForKey:@"ID"];
		NSRange rang = [ID rangeOfString:@"Leaf20."];
		if(rang.location != NSNotFound) [arr addObject:info];
	}
	for(int i=0;i<[promoteInfoList count];i++)
	{
		NSDictionary *info = [promoteInfoList objectAtIndex:i];
		NSString *ID = [info objectForKey:@"ID"];
		NSRange rang = [ID rangeOfString:@"Leaf50."];
		if(rang.location != NSNotFound) [arr addObject:info];
	}
	if([arr count] == 0) {
		[arr release]; return nil;
	}
	return arr;
	 */
}

// 获取产品信息
-(NSDictionary *)getProductInfo:(NSString *)ID
{
	NSDictionary *info2 = nil;
	/*
	for(info2 in promoteInfoList)
	{
		if(!info2) continue;
		if([ID isEqualToString:[info2 objectForKey:@"ID"]]) return info2;
	}
	 */
	for(info2 in productInfoList)
	{
		if(!info2) continue;
		if([ID isEqualToString:[info2 objectForKey:@"ID"]]) return info2;
	}
	return nil;
}

// 获取产品价格，带符号的，比如¥20,$100
- (NSString *)getProductPriceWithSymbol:(NSString *)ID
{
    NSDictionary *info = [self getProductInfo:ID];
    if(info==nil) return @"N/A";
    NSString *symbol = [info objectForKey:@"CurrencySymbol"];
    NSString *price = [info objectForKey:@"Price"];
    if([symbol length]==3) symbol = [symbol substringFromIndex:2];
    return [symbol stringByAppendingString:price];
}

- (int) getCoinPrice:(int) coins
{
    /*
    for(int i=0;i<kIAPCoinCount;i++)
    {
        if(coinPackageList[i] == coins) return coinPriceList[i];
        if(coinPackageList[i] == 0) break;
    }
     */
    return coins;
}
- (int) getLeafPrice:(int) coins
{
    /*
    for(int i=0;i<kIAPCoinCount;i++)
    {
        if(leafPackageList[i] == coins) return leafPriceList[i];
        if(leafPackageList[i] == 0) break;
    }
     */
    return coins;
}

-(NSDictionary *)getProductPrice:(NSString *)ID
{

	NSArray *arr = [ID componentsSeparatedByString:@"."];
	if([arr count]<4) return nil;
	int discount = 0;
	// BOOL isCoin = NO;
    NSDictionary *iapItemPriceDict = [SystemUtils getSystemInfo:@"kIapItemPriceDict"];
    int type = 0;
    int count = 0;
    NSString *itemName = @"";
	NSString *key = [arr objectAtIndex:3];
	if([key length]>[iapCoinName length] && [iapCoinName isEqualToString:[key substringToIndex:[iapCoinName length]]])
	{
        if(iapItemPriceDict) {
            count = [[iapItemPriceDict objectForKey:key] intValue];
        }
        if(count==0) {
            count = [[key substringFromIndex:[iapCoinName length]] intValue];
        }
        // count = [self getCoinPrice:count];
		// isCoin = YES;
        type = 1;
	}
	else if([iapLeafName length]>0 && [key length]>[iapLeafName length] && [iapLeafName isEqualToString:[key substringToIndex:[iapLeafName length]]])
	{
        if(iapItemPriceDict) {
            count = [[iapItemPriceDict objectForKey:key] intValue];
        }
        if(count==0)
            count = [[key substringFromIndex:[iapLeafName length]] intValue];
        // count = [self getLeafPrice:count];
        type = 2;
	}
	else if([key length]>[iapPromotionName length] && [iapPromotionName isEqualToString:[key substringToIndex:[iapPromotionName length]]])
	{
        if(iapItemPriceDict) {
            count = [[iapItemPriceDict objectForKey:key] intValue];
        }
        if(count==0)
            count = [[key substringFromIndex:[iapPromotionName length]] intValue];
        // count = [self getLeafPrice:count];
        type = 3;
	}
    else {
        if(iapItemPriceDict) {
            count = [[iapItemPriceDict objectForKey:key] intValue];
        }
        int i = [key length]-1;
        while(i>=0) {
            char ch = [key characterAtIndex:i];
            if(ch>'9' || ch<'0') break;
            i--;
        }
        if(count==0)
            count = [[key substringFromIndex:i+1] intValue];
        itemName = [key substringToIndex:i+1];
        type = 4;
    }
	// double price = count;
	// price -= 0.01f;
    NSString *priceStr = [NSString stringWithFormat:@"%d.99", count-1];
	return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:type], @"type", 
            [NSNumber numberWithInt:count], @"count", 
			[NSNumber numberWithInt:discount], @"discount", 
            itemName, @"itemName", // coin
            key, @"itemID", // coin10
            [NSNumber numberWithInt:count], @"priceUSD",
            priceStr, @"price", nil];
}


// 获得购买的叶子数量
- (int) getIAPLeafCount:(int)price
{
    if([SystemUtils getGameDataDelegate]) 
    {
        return [[SystemUtils getGameDataDelegate] getIAPLeafCount:price];
    }
	//      1 5   10  20 50  100
	// 钻石;10;61;127;280;710;1520
	int leaf = 0;
	if(price<1) leaf = 0;
	else if(price==1) leaf = 10;
	else if(price==2) leaf = 20;
	else if(price<10) leaf = 61;
	else if(price<20) leaf = 127;
	else if(price<50) leaf = 280;
	else if(price<100) leaf = 710;
	else leaf = 1520;
	int promotionRate = [SystemUtils getPromotionRate];
	if(promotionRate > 0) {
		leaf = leaf * (10+promotionRate)/10;
	}
	return leaf;
}

// 检查某个IAP是否已经下载
- (BOOL) isIAPItemDownloaded:(NSString *)itemID
{
    if(!marketProducts) return NO;
	for (SKProduct *curProduct in marketProducts)
	{
		if ([curProduct.productIdentifier isEqualToString:itemID])
		{
			return YES;
		}
	}
    return NO;
}

// 模拟购买某个IAP
- (void) simulateBuyIAPItem
{
    if(m_simulateIAPItem==nil) return;
    NSString *productIdentifier = m_simulateIAPItem;
    NSString *quantity = @"1";
    NSString *tid = [NSString stringWithFormat:@"simulate_%@", m_simulateIAPItem];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:productIdentifier, @"itemId", tid, @"tid", quantity, @"amount", nil];
    // save to history
    [[NSNotificationCenter defaultCenter] postNotificationName:kInAppStoreItemBoughtNotification object:nil userInfo:userInfo];
    // Remove the transaction from the payment queue.
    [self transactionFinished:userInfo];
    [m_simulateIAPItem release]; m_simulateIAPItem = nil;
}


@end


/***********************************
 ECPurchaseHTTPRequest
 ***********************************/
@implementation ECPurchaseHTTPRequest
@synthesize productIdentifier = _productIdentifier;
@synthesize paymentTransaction, m_receiptVerifyData;

- (void) dealloc
{
	self.paymentTransaction = nil;
    self.productIdentifier = nil;
    self.m_receiptVerifyData = nil;
	[super dealloc];
}
@end

