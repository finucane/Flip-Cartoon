//
//  FLActivityProgressViewController.m
//  Flip
//
//  Created by Finucane on 6/18/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLAppDelegate.h"
#import "FLActivityProgressViewController.h"
#import "insist.h"

static NSString*const ACTIVITY_PROGRESS_ID = @"ActivityProgressView";

@implementation FLActivityProgressViewController

/*
  create a transparent window containing an FLActivityProgressViewController and
  overlay it on top of the screen.
 
  the caller should hold onto "window" to keep it alive and to dismiss it, which
  will free the view controller as well.
*/


+(FLActivityProgressViewController*)activityProgressWindow:(UIWindow*__autoreleasing*)window
{
  insist (window);
  *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  insist (*window);
  
  FLActivityProgressViewController*vc = [App.storyboard instantiateViewControllerWithIdentifier:ACTIVITY_PROGRESS_ID];
  insist (vc);
  
  [*window setWindowLevel:UIWindowLevelAlert];
  [*window setRootViewController:vc];
  [*window makeKeyAndVisible];
  return vc;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  insist (progressView);
  progressView.progress = 0.0;
}

/*
  set the progress view's progress value, clamping to be within
  the 0..1 range.
 
  progress - a progress value meaning a fraction of 1.0 = finished.

*/
-(void)setProgress:(float)progress
{
  insist (progressView);
  if (progress < 0.0)
    progress = 0.0;
  else if (progress > 1.0)
    progress = 1.0;
  
  progressView.progress = progress;
}
@end
