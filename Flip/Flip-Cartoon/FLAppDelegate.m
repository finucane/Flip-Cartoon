//
//  FLAppDelegate.m
//  Flip
//
//  Created by Finucane on 5/27/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLAppDelegate.h"
#import "UIAlertView+Additions.h"
#import "UIColor+Additions.h"
#import "insist.h"

static NSString*const NAVIGATION_CONTROLLER_ID = @"NavigationController";
static NSString*const APP_NAME = @"Flip"; //not product name

@implementation FLAppDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
  insist (self.window);
  insist (self.window.rootViewController);
  insist ([self.window.rootViewController isKindOfClass:[FLCanvasViewController class]]);
  
  // self.window.tintColor = [UIColor blackColor];
  
  /*get the DrawingViewController which is the initial view controller loaded from the storyboard*/
  drawingViewController = (FLCanvasViewController*) self.window.rootViewController;
  drawingViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  isShowingDrawingViewController = YES;
  
  /*set up core data*/
  NSError*error;
  coreData = [[FLCoreData alloc] initWithAppName:APP_NAME error:&error];
  
  //error 1570 means some required attributes were nil on save
  insist (coreData);
  
  /*asynchronously get the list of in-app purchases*/
  purchases = [[FLPurchases alloc] init];
  insist (purchases);
  [purchases fetchProducts];
  
  return YES;
}

/*
 the only automatic things this app does is play cartoons and render cartoons.
 cancelling the render is not too hard, cancelling a playing cartoon is
 not worth the complexity.
 */
-(void)applicationWillResignActive:(UIApplication*)application
{
  
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
  insist (coreData);
  NSError*error;
  [coreData saveWithError:&error];
}

- (void)applicationWillTerminate:(UIApplication*)application
{
  insist (coreData);
  NSError*error;
  [coreData saveWithError:&error];
}

/*
 Accessor for coreData object
 
 returns coreData object
 */
-(FLCoreData*)coreData
{
  return coreData;
}

/*
 return current scene in app. there is always one, since there's always a current cartoon, and
 cartoons are not allowed to be empty. this method spares having to type this boilerplate
 code more than once.
 */
-(FLScene*)currentScene
{
  insist (coreData);
  FLCartoon*cartoon = coreData.currentCartoon;
  insist (cartoon);
  FLScene*scene = cartoon.currentScene;
  insist (scene);
  return scene;
}

/*
 Toggle the app between its 2 topmost viewControllers
 */
-(void)flipViewControllers
{
  insist (drawingViewController);
  
  /*if we are going to flip to the navigation controller...*/
  if (isShowingDrawingViewController)
  {
    /*..and it's not loaded yet, load it*/
    if (!navigationController)
    {
      navigationController = [[drawingViewController storyboard] instantiateViewControllerWithIdentifier:NAVIGATION_CONTROLLER_ID];
      insist (navigationController);
      
      navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    }
    
    [drawingViewController presentViewController:navigationController animated:YES completion:nil];
  }
  else
  {
    [navigationController dismissViewControllerAnimated:YES completion:nil];
  }
  isShowingDrawingViewController = !isShowingDrawingViewController;
}

-(UIStoryboard*)storyboard
{
  return self.window.rootViewController.storyboard;
}
-(FLPurchases*)purchases
{
  return purchases;
}


@end
