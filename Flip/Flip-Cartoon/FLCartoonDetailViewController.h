//
//  FLCartoonDetailViewController.h
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLCartoon.h"

@interface FLCartoonDetailViewController : UIViewController <UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
{
  @private
  NSMutableArray*fontNames;
  IBOutlet UITextField*cartoonTitle;
  IBOutlet UISlider*lineThicknessSlider;
  IBOutlet UISlider*framesPerSecondSlider;
  IBOutlet UILabel*lineThicknessLabel;
  IBOutlet UILabel*framesPerSecondLabel;
  IBOutlet UIPickerView*fontPicker;
}

@property (weak, nonatomic) FLCartoon*cartoon;
@property (weak, nonatomic) UITableView*tableView;

-(IBAction)undo:(id)sender;
-(IBAction)framesPerSecond:(id)sender;
-(IBAction)lineThickness:(id)sender;

@end
