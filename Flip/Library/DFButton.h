//
//  DFButton.h
//  Flip
//
//  Created by Finucane on 6/10/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DFButton : UIButton
{
  @private
  NSArray*buttons;
}
-(void)setNormalColor:(UIColor*)normalColor selectedColor:(UIColor*)selectedColor;
-(void)setButtons:(NSArray*)buttons;
-(void)press;

@end
