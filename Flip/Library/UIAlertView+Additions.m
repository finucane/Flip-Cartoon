//
//  UIAlertView+Additions.m
//  Flip
//
//  Created by Finucane on 5/29/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "UIAlertView+Additions.h"
#import "insist.h"

@implementation UIAlertView (Additions)


+(void)showAlertWithTitle:(NSString*)title format:(NSString*)format,...
{
  va_list args;
  va_start(args, format);
  NSString*message = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  
  [UIAlertView showAlertWithTitle:title message:message];
}

+(void)showAlertWithTitle:(NSString*)title message:(NSString*)message
{
  UIAlertView*alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:NSLocalizedString (@"OK", nil) otherButtonTitles:nil];
  insist (alertView);
  [alertView show];
}

+(void)showError:(NSError*)error
{
  
  NSString*s = [[NSString alloc] initWithFormat:@"%@ %ld %@", error.domain, (long)error.code, error.description];
  UIAlertView*alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString (@"Internal Error", nil) message:s
                                                    delegate:nil
                                           cancelButtonTitle:NSLocalizedString (@"OK", nil)
                                           otherButtonTitles:nil];
  insist (alertView);
  [alertView show];
}

@end
