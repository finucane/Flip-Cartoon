//
//  SKProduct+Additions.h
//  Flip
//
//  Created by Finucane on 6/20/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <StoreKit/StoreKit.h>

@interface SKProduct (Additions)
-(NSString*)formattedPriceInUserCurrency;
@end
