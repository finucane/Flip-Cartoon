//
//  UIButton+Additions.m
//  Flip
//
//  Created by Finucane on 6/5/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "UIButton+Additions.h"

@implementation UIButton (Additions)

/*
  programmatically set the image for the flipButton to render so it inherits a global tint
*/
-(void)setGlobalTint
{
  UIImage*image = [self.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [self setImage:image forState:UIControlStateNormal];
  [self setImage:image forState:UIControlStateHighlighted];
}
@end
