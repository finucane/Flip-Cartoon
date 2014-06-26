//
//  SKProduct+Additions.m
//  Flip
//
//  Created by Finucane on 6/20/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "SKProduct+Additions.h"

@implementation SKProduct (Additions)

/*
  return a product price formatted to the user's currency, not necessarily the phone's
  locale setting.
*/
-(NSString*)formattedPriceInUserCurrency
{
  NSNumberFormatter*numberFormatter = [[NSNumberFormatter alloc] init];
  [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
  [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
  [numberFormatter setLocale:self.priceLocale];
  return [numberFormatter stringFromNumber:self.price];
}
@end
