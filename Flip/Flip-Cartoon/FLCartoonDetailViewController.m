//
//  FLCartoonDetailViewController.m
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLCartoonDetailViewController.h"
#import "UIAlertView+Additions.h"
#import "FLAppDelegate.h"
#import "insist.h"


@implementation FLCartoonDetailViewController

/*
 this vc is not kept around after it's popped off the navigation stack,
 so we initialize it in viewDidLoad, not viewWillAppear. viewWillAppear
 isn't that good a place to initialize in anyway since it's called
 when it appears because something was popped off the stack in front of it.
 */
- (void)viewDidLoad
{
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  [super viewDidLoad];
  
  insist (self.cartoon);
  insist (self.tableView);
  
  fontNames = [[NSMutableArray alloc] init];
  insist (fontNames);
  
  insist (self.cartoon.fontName);
  
  /*
   add a placeholder name for whatever the system default is,
   which is not listed when we use UIFont familyNames
   */
  [fontNames addObject:[coreData systemFontName]];
  
  /*collect all the font names.*/
  for (NSString*family in [UIFont familyNames])
  {
    for (NSString*name in [UIFont fontNamesForFamilyName:family])
    {
      [fontNames addObject:name];
    }
  }
  
  /*set the range of the slider in code because doing it in IB is hard to maintain*/
  insist (lineThicknessSlider);
  lineThicknessSlider.maximumValue = kFLCoreDataMaxLineThickness;
}

/*
 before view appears select the current fontName in the picker view
 */
-(void)viewWillAppear:(BOOL)animated
{
  [self setUI];
}

/*
 load the UI w/ contents from the cartoon. this is used in viewWillAppear (not viewDidLoad because
 the picker isn't ready to be selected then), and for undo.
 */
-(void)setUI
{
  insist (fontNames);
  insist (self.cartoon);
  insist (self.cartoon.fontName);
  insist (fontPicker);
  
  cartoonTitle.text = self.cartoon.title;
  
  NSInteger selectedRow = [fontNames indexOfObject:self.cartoon.fontName];
  insist (selectedRow >= 0 && selectedRow < fontNames.count);
  [fontPicker selectRow:selectedRow inComponent:0 animated:NO];
  
  insist (lineThicknessSlider);
  lineThicknessSlider.value = self.cartoon.lineThickness;
  lineThicknessLabel.text = [NSString stringWithFormat:@"%d", self.cartoon.lineThickness];
  framesPerSecondSlider.value = self.cartoon.framesPerSecond;
  framesPerSecondLabel.text = [NSString stringWithFormat:@"%d", self.cartoon.framesPerSecond];
}

/*
 save changes to cartoon. for simplicity do this even if nothing changed:
 setting the cartoon attributes to what they already were is not going
 to stress the persistent store.
 */
-(void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  /*if we are being popped off the navigation stack, save changes*/
  if (![self.navigationController.viewControllers containsObject:self])
  {
    insist (self.cartoon);
    
    NSString*newTitle = [cartoonTitle.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    /*
     if there's no title, don't change the attribute. demonstrate our ability
     to use localized strings by putting up an alert.
     */
    if (!newTitle.length)
    {
      /*alert the user*/
      [UIAlertView showAlertWithTitle:NSLocalizedString(@"Empty Cartoon", nil)
                              message:NSLocalizedString(@"Can't set cartoon title to the empty string. It was left unchanged.", nil)];
    }
    else
    {
      self.cartoon.title = newTitle;
      [self.tableView reloadData];
    }
    
    NSInteger fontIndex = [fontPicker selectedRowInComponent:0];
    insist (fontIndex >= 0 && fontIndex < fontNames.count);
    
    /*
     if the font name changed, set the cartoon's font name and also recompute
     font sizes in the cartoon
     */
    if (![self.cartoon.fontName isEqualToString: fontNames [fontIndex]])
    {
      self.cartoon.fontName = fontNames [fontIndex];
      [self.cartoon recomputeFontSizes];
    }
    
    self.cartoon.lineThickness = (int32_t)lineThicknessSlider.value;
    self.cartoon.framesPerSecond = (int32_t)framesPerSecondSlider.value;
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  [textField resignFirstResponder];
  
  return YES;
}

-(IBAction)undo:(id)sender
{
  [self setUI];
}
-(IBAction)framesPerSecond:(id)sender
{
  insist (sender == framesPerSecondSlider);
  framesPerSecondLabel.text = [NSString stringWithFormat:@"%d", (int)framesPerSecondSlider.value];
}
-(IBAction)lineThickness:(id)sender
{
  insist (sender == lineThicknessSlider);
  lineThicknessLabel.text = [NSString stringWithFormat:@"%d", (int)lineThicknessSlider.value];
}
/*
 font UIPickerView datasource & delegate
 */

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
  insist (pickerView == fontPicker);
  return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
  insist (pickerView == fontPicker);
  insist (fontNames);
  return fontNames.count;
}

/*
 return a view for each row so we can format each row's font to match the corresponding font.
 attributedTitleForRow: doesn't work for this.
 
 */
-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
  insist (pickerView == fontPicker);
  insist (component == 0);
  insist (fontNames && fontNames.count);
  insist (row >= 0 && row < fontNames.count);
  
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  CGFloat size = [UIFont labelFontSize];
  UIFont*font = [coreData fontForName:fontNames [row] size:size];
  insist (font);
  
  NSAttributedString*s = [[NSAttributedString alloc] initWithString:fontNames [row] attributes:@{NSFontAttributeName:font}];
  insist (s);
  
  /*make a label if we don't have one to re-use*/
  if (view == nil)
    view = [[UILabel alloc] init];
  
  insist ([view isKindOfClass:[UILabel class]]);
  UILabel*label = (UILabel*)view;
  
  label.attributedText = s;
  label.textAlignment = NSTextAlignmentCenter;
  
  return label;
}

@end
