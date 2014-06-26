//
//  UIAlertView+Additions.h
//  Flip
//
//  Created by Finucane on 5/29/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (Additions)
+(void)showAlertWithTitle:(NSString*)title format:(NSString*)format,...;
+(void)showAlertWithTitle:(NSString*)title message:(NSString*)message;
+(void)showError:(NSError*)error;
@end
