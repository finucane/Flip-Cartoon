//
//  FLPurchases.h
//  Flip
//
//  Created by Finucane on 6/20/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

extern NSString*const kFLPurchasesNotification;
extern NSInteger const kFLPurchasesFrameLimit;

typedef enum
{
  FL_PURCHASES_NOT_PURCHASED = 0,
  FL_PURCHASES_REQUEST_SENT,
  FL_PURCHASES_PURCHASING,
  FL_PURCHASES_PURCHASED,
  FL_PURCHASES_FAILED
}FLPurchasesState;

@interface FLPurchases : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
  @private
  NSArray*productIDs;
  NSArray*products;
  SKProductsRequest*productsRequest;
}

-(instancetype)init;
-(void)fetchProducts;
-(NSArray*)products;
-(void)buy:(SKProduct*)product;
-(void)restore;
-(FLPurchasesState)stateForProductID:(NSString*)productID;
-(BOOL)adsDisabled;
-(BOOL)unlimitedFrames;
-(BOOL)unlimitedCartoons;
@end
