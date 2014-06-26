//
//  DFButton.m
//  Flip
//
//  Created by Finucane on 6/10/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "DFButton.h"
#import "UIImage+Additions.h"
#import "insist.h"

/*
  this class provides tinting and also radio button behavior on UIButton
*/
@implementation DFButton

- (void) awakeFromNib
{
  [super awakeFromNib];
  [self addTarget:self action:@selector (pressed:) forControlEvents:UIControlEventTouchUpInside];
}
- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    [self addTarget:self action:@selector (pressed:) forControlEvents:UIControlEventTouchUpInside];
  }
  return self;
}

/*
  set colors for the normal and selected images. we can't use the nice
  UIImageRenderingModeAlwaysTemplate for this because we have 2 colors.
  
  normalColor - color for normal state
  selectedColor - color for selected state
*/

-(void)setNormalColor:(UIColor*)normalColor selectedColor:(UIColor*)selectedColor
{
  [self setImage:[[self imageForState:UIControlStateNormal] imageWithTintColor:normalColor] forState:UIControlStateNormal];
  [self setImage:[[self imageForState:UIControlStateSelected] imageWithTintColor:selectedColor] forState:UIControlStateSelected];
  [self setImage:[self imageForState:UIControlStateSelected] forState:UIControlStateHighlighted];
}

/*
  set the list of buttons that self belongs to, in terms of only one button
  being allowed to be selected at a time.
 
  buttons - array of buttons (including self probably)
*/

-(void)setButtons:(NSArray*)someButtons
{
  buttons = someButtons;
}

/*
  action we install internally to implement radio button functionality
*/

-(void)pressed:(id)sender
{
  insist (sender == self);

  if (!buttons)
    return;
  
  for (UIButton*button in buttons)
      button.selected = NO;

  [super setSelected:YES];
}


/*
  make sure self is toggled on programatically
*/
-(void)press
{
  [self pressed: self];
}
@end
