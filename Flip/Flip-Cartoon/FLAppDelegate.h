//
//  FLAppDelegate.h
//  Flip
//
//  Created by Finucane on 5/27/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLNavigationController.h"
#import "FLCanvasViewController.h"
#import "FLCoreData.h"
#import "FLPurchases.h"

@interface FLAppDelegate : UIResponder <UIApplicationDelegate>
{
  @private
  FLNavigationController*navigationController;
  FLCanvasViewController*drawingViewController;
  BOOL isShowingDrawingViewController;
  FLCoreData*coreData;
  FLPurchases*purchases;
}

/*has to be a property for IB/Storyboards to do their thing*/
@property (strong, nonatomic) UIWindow *window;

/*the topmost ui of the app is 2 view controllers that flip between each other. this method does that*/
-(void)flipViewControllers;
-(FLCoreData*)coreData;
-(FLScene*)currentScene;
-(UIStoryboard*)storyboard;
-(FLPurchases*)purchases;

/*
 macro to get at AppDelegate from anywhere, so the code can call methods like
 flipViewControllers globally. App is our 1 global variable.
*/

#define App ((FLAppDelegate*)[UIApplication sharedApplication].delegate)
@end
