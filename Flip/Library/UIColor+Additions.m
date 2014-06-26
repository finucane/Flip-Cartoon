//
//  UIColor+Additions.m
//  Flip
//
//  Created by Finucane on 5/29/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "UIColor+Additions.h"
#import "insist.h"

@implementation UIColor (Additions)

+(UIColor*)colorWithRGBA:(int32_t)hex
{
  return [UIColor colorWithRed:((float)((hex & 0xff000000) >> 24))/255.0
                         green:((float)((hex & 0x00ff0000) >> 16))/255.0
                          blue:((float)((hex & 0x0000ff00) >>  8))/255.0
                         alpha:((float)((hex & 0x000000ff)      ))/255.0];
}
-(int32_t)rgbValue
{
  CGFloat r, g, b, a;
  
  BOOL _r = [self getRed:&r green:&g blue:&b alpha:&a];
  insist (_r);
  
  return
  (((int32_t)(a * 255))      ) |
  (((int32_t)(r * 255)) << 24) |
  (((int32_t)(g * 255)) << 16) |
  (((int32_t)(b * 255)) <<  8);
}
@end
