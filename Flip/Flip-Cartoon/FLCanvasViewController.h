//
//  FLCanvasViewController.h
//  Flip
//
//  Created by Finucane on 5/27/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import "FLCanvasView.h"
#import "DFButton.h"
#import "FLCartoonWriter.h"

@interface FLCanvasViewController : UIViewController <FLCanvasViewDelegate, ADBannerViewDelegate>
{
  @private
  IBOutlet DFButton*flipButton;
  IBOutlet DFButton*addSceneButton;
  IBOutlet DFButton*deleteSceneButton;
  IBOutlet DFButton*playPauseButton;
  
  IBOutlet DFButton*penButton;
  IBOutlet DFButton*polygonButton;
  IBOutlet DFButton*eraserButton;
  IBOutlet DFButton*fingerButton;
  IBOutlet DFButton*undoButton;
  IBOutlet DFButton*textButton;
  IBOutlet DFButton*videoButton;
  IBOutlet DFButton*shareButton;
  IBOutlet UISlider*frameSlider;
  
  IBOutlet UILabel*sceneLabel;
  IBOutlet FLCanvasView*canvasView;
  NSTimer*playTimer;
  NSArray*bottomButtons;
  
  UIPopoverController*sharePopover;
  IBOutlet NSLayoutConstraint*adBannerVerticalSpaceConstraint;
  IBOutlet ADBannerView*adBannerView;
  BOOL adBannerIsHidden;
}
-(IBAction)flip:(id)sender;
-(IBAction)toolButtonTouched:(id)sender;
-(IBAction)addScene:(id)sender;
-(IBAction)deleteScene:(id)sender;
-(IBAction)playPause:(id)sender;
-(IBAction)frameSlider:(id)sender;
-(void)killAds;

@end
