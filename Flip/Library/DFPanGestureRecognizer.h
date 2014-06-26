//
//  DFPanGestureRecognizer.h
//  Flip
//
//  Created by Finucane on 6/6/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DFPanGestureRecognizer : UIPanGestureRecognizer <UIGestureRecognizerDelegate>
{
	@private
  CGPoint touchesBeganPoint;
  CGPoint maxVelocity;
}
-(instancetype)initWithTarget:(id)target action:(SEL)action;
-(CGPoint)touchesBeganPoint;
-(void)setMaxVelocity:(CGPoint)maxVelocity;
@end
