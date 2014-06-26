//
//  FLPurchases.m
//  Flip
//
//  Created by Finucane on 6/20/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "FLPurchases.h"
#import "UIAlertView+Additions.h"
#import "insist.h"

/*
 FLPurchases ecapsulates in app purchases. it's designed to run on the main thread.
 This matters because it does a lot of asynchronous network stuff with apple
 and wouldn't be consistent if accessed from another thread.
*/
NSString*const kFLPurchasesNotification = @"com.finucane.FlipCartoon.FLPurchasesNotification";
NSInteger const kFLPurchasesFrameLimit = 100;

static NSString*const PRODUCT_IDS = @"product_ids";
static NSString*const UNLIMITED_CARTOONS_KEY = @"com.finucane.FlipCartoon.UnlimitedCartoons";
static NSString*const UNLIMTED_FRAMES_KEY = @"com.finucane.FlipCartoon.UnlimitedFrames";
static NSString*const DISABLE_ADS_KEY = @"com.finucane.FlipCartoon.DisableAds";

@implementation FLPurchases

/*
 return a new FLPurchases. When it's created it knows the list of product ids the app has
 embedded in its bundle and has started to watch the payment transaction queue. but it
 might not have any products (fetchProducts: has to start that happening).
*/
-(instancetype)init
{
  if ((self = [super init]))
  {
    /*get the list of product ids we support from the app bundle.*/
    productIDs = [NSArray arrayWithContentsOfURL:[[NSBundle mainBundle] URLForResource:PRODUCT_IDS withExtension:@"plist"]];
    insist (productIDs);
    
    /*
     for simplicty we are using user defaults to remember what the user's bought. we're using core data to persist
     settings anyway. make a default for each product id w/ a default value of NO meaning "not bought"
     */
    
    NSUserDefaults*defaults = [NSUserDefaults standardUserDefaults];
    insist (defaults);
    NSMutableDictionary*dictionary = [[NSMutableDictionary alloc]init];
    
    for (NSString*key in productIDs)
      [dictionary setObject:@(FL_PURCHASES_NOT_PURCHASED) forKey:key];
    
    [defaults registerDefaults:dictionary];
        
    /*start watching the payment transaction queue*/
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
  }
  return self;
}

/*
 fetch the list of SKProducts from apple, using our product ids.
 we'll get the list back asynchronously.
 */
-(void)fetchProducts
{
  /*if the user cannot make payments, never even bother with the store.*/
  if (![SKPaymentQueue canMakePayments])
    return;
  
  insist (!productsRequest);
  
  /*make a products request and start it.*/
  productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIDs]];
  insist (productsRequest);
  productsRequest.delegate = self;
  [productsRequest start];
}


#pragma mark - SKProductsRequestDelegate
/*
 SKProductsRequestDelegate callback for the request coming back.
 save the valid product ids.
 
 if there are invalid product ids throw up an alert, but only for development builds.
 it can be a normal case in a shipped app if we remove a product from the store.
 */
-(void)productsRequest:(SKProductsRequest*)request didReceiveResponse:(SKProductsResponse*)response
{
  insist (request == productsRequest);
  insist (response);
  
  /*save the list of products*/
  products = response.products;
  
#if DEBUG
  /*report any errors*/
  
  if (response.invalidProductIdentifiers.count)
  {
    NSMutableString*mutable = [[NSMutableString alloc] init];
    insist (mutable);
    
    for (NSString*s in response.invalidProductIdentifiers)
      [mutable appendFormat:@"%@,", s];
    
    [UIAlertView showAlertWithTitle:@"Invalid Product ID" format:@"product id(s): %@", mutable];
  }
  
  /*don't need to hang onto this anymore*/
  productsRequest = nil;
  
#endif
}

/*
  translate an error to a meaningful localized message. not that great
  because we don't translate the product id to something pretty but
  good enough. to do this right is not straightforward because
  localizedErrorFromTransaction is being called from the paymenttransaction
  observer which can happen at any time, even before we've got a product list
  from apple. with that list we'd get the localized name for the product, by
  finding what matches the product id. moreover the observer call might be
  happening on a different thread. it's not worth the complexity right now.
 
  transaction - the transcation that failed
 
  returns - a localized message explaining what happened.
*/
-(NSString*)localizedErrorFromTransaction:(SKPaymentTransaction*)transaction
{
  NSMutableString*mutable = [[NSMutableString alloc] init];
  insist (mutable);
  
  NSString*pid = transaction.payment.productIdentifier;
  
  [mutable appendFormat:@"%@: %@. ", NSLocalizedString(@"Product Identifier", nil), pid];
  
  switch (transaction.error.code)
  {
    case SKErrorClientInvalid:
      [mutable appendString:NSLocalizedString(@"The client was invalid.", nil)];
      break;
    case SKErrorPaymentCancelled:
      [mutable appendString:NSLocalizedString(@"The payment was cancelled.", nil)];
      break;
    case SKErrorPaymentInvalid:
      [mutable appendString:NSLocalizedString(@"The payment was invalid.", nil)];
      break;
    case SKErrorPaymentNotAllowed:
      [mutable appendString:NSLocalizedString(@"The payment was not allowed.", nil)];
      break;
    case SKErrorStoreProductNotAvailable:
      [mutable appendString:NSLocalizedString(@"The product was not available.", nil)];
      break;
    case SKErrorUnknown:
    default:
      [mutable appendString:NSLocalizedString(@"Something bad happened.", nil)];
      break;
  }
  return mutable;
}

#pragma mark - SKPaymentTransactionObserver

-(void)paymentQueue:(SKPaymentQueue*)queue updatedTransactions:(NSArray*)transactions
{
  for (SKPaymentTransaction*transaction in transactions)
  {
    switch (transaction.transactionState)
    {
      case SKPaymentTransactionStateRestored:
      case SKPaymentTransactionStatePurchased:
        if ([productIDs containsObject:transaction.payment.productIdentifier])
        {
          [self setState:FL_PURCHASES_PURCHASED forProductID:transaction.payment.productIdentifier];
        }
        [queue finishTransaction:transaction];
        break;
      case SKPaymentTransactionStateFailed:
      {
        [queue finishTransaction:transaction];
        [self setState:FL_PURCHASES_FAILED forProductID:transaction.payment.productIdentifier];

        /*report the failure but don't assume we are on the main thread*/
        dispatch_async (dispatch_get_main_queue(), ^{
          
          [UIAlertView showAlertWithTitle:NSLocalizedString (@"In-App Purchase failed", nil)
                                  message:[self localizedErrorFromTransaction:transaction]];
        });
      }
      break;
      case SKPaymentTransactionStatePurchasing:
        [self setState:FL_PURCHASES_PURCHASING forProductID:transaction.payment.productIdentifier];
      default:
        break;
    }
  }

  /*
   notify whoever cares that overall in-app purchase state changed. In fact, FLPurchasesViewController
   uses the notification to update the status labels in its tableView of purchases, and FLCanvasViewController
   uses the notification to turn off banner ads once that's been purchased. Rather than, for instance,
   requiring the app to be restarted.
   */
  [[NSNotificationCenter defaultCenter] postNotificationName:kFLPurchasesNotification object:self userInfo:nil];
}

/*required but not used*/
- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray*)downloads
{
  
}


#pragma mark -

/*
 accessor for products. if it's non-nil it means we have some, a products
 request came back. if its non-nil but empty it means we're out of luck.
 */
-(NSArray*)products
{
  return products;
}

/*
 queue a request for a purchase a product, quantity one.
 
 product - a product
 */
-(void)buy:(SKProduct*)product
{
  @try
  {
    [[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:product]];
    [self setState:FL_PURCHASES_REQUEST_SENT forProductID:product.productIdentifier];
  }
  @catch (NSException*e)
  {
    [UIAlertView showAlertWithTitle:NSLocalizedString(@"Internal Error", nil) message:e.reason];
    return;
  }
}
/*
 restore any previously made purchases
*/
-(void)restore
{
  [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

/*
  accessor for product purchase state
 
  product - a product id
 
  returns - an FLPurchaseState.
*/
-(FLPurchasesState)stateForProductID:(NSString*)productID
{
  insist (productID && productID.length);
  
  if (![productIDs containsObject:productID])
    return FL_PURCHASES_NOT_PURCHASED;
  
  return (FLPurchasesState)[[NSUserDefaults standardUserDefaults] integerForKey:productID];
}

-(void)setState:(NSInteger)state forProductID:(NSString*)productID
{
  if (![productIDs containsObject:productID])
    return;
  
  [[NSUserDefaults standardUserDefaults] setInteger:state forKey:productID];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

/*
  accessors to determine what in app purchases have been purchased. up until this
  point everything in this file has been generic and driven by product_ids.plist
  and whatever we put up on apple's servers. but at some point the code itself
  needs to know what's actually been purchased so it can enable features. these
  methods map the state of products being purchased or not to what that means to the
  app logically.
*/

-(BOOL)adsDisabled
{
  insist ([productIDs containsObject:DISABLE_ADS_KEY]);
  return [self stateForProductID:DISABLE_ADS_KEY] == FL_PURCHASES_PURCHASED;
}
-(BOOL)unlimitedFrames
{
  insist ([productIDs containsObject:UNLIMTED_FRAMES_KEY]);
  return [self stateForProductID:UNLIMTED_FRAMES_KEY] == FL_PURCHASES_PURCHASED;
}
-(BOOL)unlimitedCartoons
{
  insist ([productIDs containsObject:UNLIMITED_CARTOONS_KEY]);
  return [self stateForProductID:UNLIMITED_CARTOONS_KEY] == FL_PURCHASES_PURCHASED;
}


@end
