//
//  InAppStore.h
//  iPetHotel
//  
//
//  Created by LEON on 11-6-7.
//  Copyright 2011 topgame. All rights reserved.
//
/*
 
 验证流程： 
 completeTransaction:
  -> PaymentSendOperation，自己的服务器端验证
     |-> 成功, acceptPendingTransactionResponse:
     |   |-> postNotificationName，发送消息，在 [SnsServerHelper onReceivePayment:] 中处理
     |    -> transactionFinished
      -> 失败,直接连苹果服务器验证 verifyPendingTransaction
          -> didFinishVerifyTransaction
              -> acceptPendingTransactionResponse
                  |-> postNotificationName
                   -> transactionFinished
 
 每次用户成功购买一个产品后，会调用[delegate transactionFinished:info]方法，参数info是一个Dictionary，
 itemId是产品ID，amount是数量。
 用法说明：
 获取产品列表：[InAppStore store].marketProducts;
 购买一个产品：
	// delegate需要实现InAppStoreDelegate协议
	BOOL res = [[InAppStore store] buyAppStoreItem:@"itemID" amount:1 withDelegate:self];
    if(res) {
		// 显示等候交易提示
	}
    else {
		// 发送请求失败，原因已经在弹出信息提示中说明
	}
 
 */

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "InAppStoreDelegate.h"
#import "ASIHTTPRequest.h"

#define kStoreItemLeaf1 @"com.playdino.PetInn.Leaf1"
#define kStoreItemLeaf5 @"com.playdino.PetInn.Leaf5"
#define kStoreItemGold1000 @"com.playdino.PetInn.Gold1000"
#define kStoreItemGold5000 @"com.playdino.PetInn.Gold5000"

#define kPendingTransactionStatusNone   0
#define kPendingTransactionStatusValid  1
#define kPendingTransactionStatusInvalid  -1

#define kInAppStoreItemBoughtNotification @"kInAppStoreItemBoughtNotification"

#ifdef DEBUG
#define VAILDATING_RECEIPTS_URL @"https://sandbox.itunes.apple.com/verifyReceipt"
#else
#define VAILDATING_RECEIPTS_URL @"https://buy.itunes.apple.com/verifyReceipt"
#endif

typedef enum  {
	AppStoreStatusNone = 0,
	AppStoreStatusLoading = 1,
	AppStoreStatusReady,
	AppStoreStatusNotReady,
} AppStoreStatus;

/***********************************
 ECPurchaseHTTPRequest
 ***********************************/
@interface ECPurchaseHTTPRequest:ASIHTTPRequest{
	NSString *_productIdentifier;
	SKPaymentTransaction *paymentTransaction;
	// NSDictionary *userInfo;
    NSString *m_receiptVerifyData;
}
@property(nonatomic,retain) NSString *productIdentifier;
@property(nonatomic,retain) NSString *m_receiptVerifyData;
@property(nonatomic, retain) SKPaymentTransaction *paymentTransaction;
// @property(nonatomic, retain) NSDictionary *userInfo;
@end

#define  kIAPCoinCount 6

@interface InAppStore : NSObject<SKProductsRequestDelegate,SKPaymentTransactionObserver> {
	NSArray *marketProducts;
	AppStoreStatus storeStatus;
	id<InAppStoreDelegate> delegate;
	SKProductsRequest *req;
	NSArray *normalIapIDs;
	NSArray *promoteIapIDs;
	int     refreshTime;
	BOOL    downloadOK;
	NSMutableSet *requestIDs;
	NSMutableArray *productInfoList;
	NSMutableArray *promoteInfoList;
	BOOL    paymentPending;
	
	NSString *iapKeyPrefix;
	NSString *iapCoinName;
	NSString *iapLeafName;
    NSString *iapPromotionName;
    BOOL     hasLeaf;
    
    SKPaymentTransaction  *pendingVerifyTransaction;
    int       pendingTransactionStatus; // 0-pending, 1-valid, -1 - invalid
    int       lastLoadingTime;
    NSDictionary  *pendingPaymentInfo;
    
    int     coinPackageList[kIAPCoinCount];
    int     coinPriceList[kIAPCoinCount];
    int     leafPackageList[kIAPCoinCount];
    int     leafPriceList[kIAPCoinCount];
    
    NSMutableDictionary *promotionIAPConfig;
    NSString *m_simulateIAPItem;
    BOOL    isVerifyServerOK;
    
}

@property (nonatomic,retain) NSArray * marketProducts;
@property (nonatomic,retain) NSArray * normalIapIDs;
@property (nonatomic,retain) NSArray * promoteIapIDs;
@property (nonatomic, assign) AppStoreStatus storeStatus;
@property (nonatomic, assign) BOOL downloadOK;
@property (nonatomic, assign) BOOL paymentPending;
@property  (nonatomic, retain) 	NSString *iapCoinName;
@property  (nonatomic, retain) NSString *iapLeafName;
@property (nonatomic, assign) BOOL isRestoring;

// @property (nonatomic, assign) int isPendingTransactionValid;

//add by yangjie
@property (nonatomic, assign) id <InAppStoreDelegate> delegate;


+(InAppStore *)store;
- (void) setDefaultProductList;
- (NSString *) getCachePath;
- (void) requestProductData;
// 发起购买请求，返回YES表示发送成功，返回NO表示发送不成功
- (BOOL) buyAppStoreItem:(NSString*)itemID amount:(int)amount withDelegate:(id<InAppStoreDelegate>)del ;
- (void) restoreIAP:(id<InAppStoreDelegate>)del;
- (void) completeTransaction: (SKPaymentTransaction *)transaction;
- (void) restoreTransaction: (SKPaymentTransaction *)transaction;
- (void) failedTransaction: (SKPaymentTransaction *)transaction;
- (void) transactionFinished:(NSDictionary *)info;

- (void) verifyPendingTransaction;
// verify receipt
- (void) verifyTransaction:(SKPaymentTransaction *)transaction;
- (void) didFinishVerifyTransaction:(ECPurchaseHTTPRequest *)request;
- (void) acceptPendingTransactionResponse:(NSDictionary *)receipt;

// 获取产品列表：ID，Title, Desc, Price, OriginalPrice, CurrencySymbol($), CurrencyCode(USD), discount(0/20/40/60/80/70), Leaf(1/5/10/20/50/100), Coin(1/5/10/20/50/100)
- (NSArray *)getProductList;
// 获取促销产品列表
- (NSArray *)getCountDownPromotions;
// 获取产品信息
- (NSDictionary *)getProductInfo:(NSString *)ID;
// 获取产品奖励内容：type：（coin／leaf），count
- (NSDictionary *)getProductPrice:(NSString *)ID;
// 获得购买的叶子数量
- (int) getIAPLeafCount:(int)price;
// 获取产品价格，带符号的，比如¥20,$100
- (NSString *)getProductPriceWithSymbol:(NSString *)ID;

// 获得促销专用IAP的奖励信息
- (NSDictionary *)getPromotionIAPInfo:(int)price;

// 检查某个IAP是否已经下载
- (BOOL) isIAPItemDownloaded:(NSString *)itemID;

// 模拟购买某个IAP
- (void) simulateBuyIAPItem;
// 对存储在global.dat中的支付信息进行验证
- (void) verifySavedPendingTransaction;
- (void) removeSavedPendingTransaction:(NSString *)tid;

@end
