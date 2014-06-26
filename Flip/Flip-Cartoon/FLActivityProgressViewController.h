//
//  FLActivityProgressViewController.h
//  Flip
//
//  Created by Finucane on 6/18/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLActivityProgressViewController : UIViewController
{
  @private
  IBOutlet UIProgressView*progressView;
}

+(FLActivityProgressViewController*)activityProgressWindow:(UIWindow*__autoreleasing*)window;
-(void)setProgress:(float)progress;
@end
