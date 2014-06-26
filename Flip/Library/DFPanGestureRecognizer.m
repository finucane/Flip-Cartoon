//
//  DFPanGestureRecognizer.m
//  Flip
//
//  Created by Finucane on 6/6/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "DFPanGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

/*
  subclass of UIPanGestureRecognizer that records the actual initial start point rather
  than the point where the gesture was determinted to be a pan. this subclass also
  disallows pans that are too fast in the horizontal direction so that swipes (fast)
  and pans (slow) can co-exist.
 
  forcing a 2 finger swipe is just evil
*/

@implementation DFPanGestureRecognizer


-(instancetype)initWithTarget:(id)target action:(SEL)action
{
  if ((self = [super initWithTarget:target action:action]))
  {
    self.delegate = self;
  }
  return self;
}

/*
 set maxVelocity
 
 maxVelocity - a maximum velocity to allow for the gesture to be accepted. 0 in either
 direction means any velocity is allowed. the sign of the x & y values is ignored.

*/
-(void)setMaxVelocity:(CGPoint)aMaxVelocity
{
  maxVelocity = aMaxVelocity;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  [super touchesBegan:touches withEvent:event];
  UITouch*touch = [touches anyObject];
  touchesBeganPoint = [touch locationInView:self.view];
}

-(CGPoint)touchesBeganPoint
{
  return touchesBeganPoint;
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
  CGPoint velocity = [self velocityInView:self.view];
  
  if (maxVelocity.x && fabs (velocity.x) > fabs (maxVelocity.x))
    return NO;
  if (maxVelocity.y && fabs (velocity.y) > fabs (maxVelocity.y))
    return NO;
  
  return YES;
}
@end
