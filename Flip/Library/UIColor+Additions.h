//
//  UIColor+Additions.h
//  Flip
//
//  Created by Finucane on 5/29/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Additions)
+(UIColor*)colorWithRGBA:(int32_t)hex;
-(int32_t)rgbValue;
@end
