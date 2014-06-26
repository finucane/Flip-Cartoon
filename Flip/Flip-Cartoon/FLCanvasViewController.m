//
//  FLCanvasViewController.m
//  Flip
//
//  Created by Finucane on 5/27/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLActivityProgressViewController.h"
#import "FLCartoonProvider.h"
#import "FLCanvasViewController.h"
#import "FLAppDelegate.h"
#import "UIButton+Additions.h"
#import "UIAlertView+Additions.h"
#import "UIView+AutoLayout.h"
#import "UIColor+Additions.h"
#import "insist.h"

static const NSTimeInterval SCENE_CHANGE_DURATION = 0.25;
static const NSTimeInterval AD_BANNER_DURATION = 1.0; //make it as annoying as possible
static const uint32_t TOUCHED_BUTTON_COLOR = 0x007affff;
static const float BOTTOM_BUTTON_WIDTH = 32.0;

//#define SCREENSHOTS 1

@implementation FLCanvasViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  /*tint revolve button*/
  [flipButton setNormalColor:[UIColor blackColor] selectedColor:[UIColor colorWithRGBA:TOUCHED_BUTTON_COLOR]];
  
  [self refreshSceneLabel];
  [self updateFrameSlider];
  
  /*set up buttons. set tint colors and autolayout*/
  insist (penButton && polygonButton && eraserButton && fingerButton);
  insist (undoButton && textButton && videoButton && shareButton);
  NSArray*toggleButtons = @[penButton, polygonButton, textButton, eraserButton, fingerButton, videoButton];
  
  /*this is going to be kept around for enable/disable during playing*/
  bottomButtons = @[penButton, polygonButton, textButton, eraserButton,
                    fingerButton, videoButton, undoButton, addSceneButton, shareButton, deleteSceneButton];
  
  /*tell the toggle buttons who they are to eachother*/
  for (DFButton*button in toggleButtons)
    button.buttons = toggleButtons;
  
  for (DFButton*button in bottomButtons)
    [button setNormalColor:[UIColor blackColor] selectedColor:[UIColor colorWithRGBA:TOUCHED_BUTTON_COLOR]];
  
  
  [bottomButtons autoDistributeViewsAlongAxis:ALAxisHorizontal withFixedSize:BOTTOM_BUTTON_WIDTH alignment:NSLayoutFormatAlignAllCenterY];
  
  /*make the initial tool the pen tool.*/
  [self toolButtonTouched:penButton];
  [penButton press]; //make the toggle happen programatically
  
  /*initially hide the iAd banner. it's set up to be visible in the storyboard.*/
  adBannerIsHidden = NO;
  [self setAdBannerHidden:YES animated:NO];
  
  /*
    if the user has already disabled ads, make sure we never show any. we're looking at this here,
    rather than at the AppDelegate level, because we need the adBannerView to be loaded from the
    storyboard before we can do any of this. it would be slightly cleaner to do this at a higher
    level.
   */
  
#ifdef SCREENSHOTS
  [self killAds];
#endif
  if (App.purchases.adsDisabled)
    [self killAds];
  else
  {
    /*
     get notified whenever the in-app purchase state changes, so we can disable ads as soon
     as that purchase is made.
     */
    [[NSNotificationCenter defaultCenter] addObserverForName:kFLPurchasesNotification
                                                      object:App.purchases
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification*n) {
                                                    
                                                    if (App.purchases.adsDisabled)
                                                    {
                                                      [self killAds];
                                                      
                                                      /*no reason to keep listening*/
                                                      [[NSNotificationCenter defaultCenter] removeObserver:self name:kFLPurchasesNotification object:nil];
                                                    }
                                                  }];
  }
}

/*
 for simplicty, redraw the canvasview whenever we appear.
 this refreshes the drawing after we come back from
 the cartoon detail view stuff, for instance, and may
 have changed line widths or fonts etc. Also clear the
 undo stack.
 
 */
-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  [App.coreData.undo reset];
  
  insist (canvasView);
  [self refreshSceneLabel];
  [self updateFrameSlider];
  [canvasView refresh];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

/*
 update the page label, making it reflect the current scene.
*/
-(void)refreshSceneLabel
{
  insist (sceneLabel);

  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  FLCartoon*cartoon = coreData.currentCartoon;
  insist (cartoon && cartoon.currentSceneIndex >= 0);
  insist (cartoon.currentSceneIndex < cartoon.scenes.count);

#ifdef SCREENSHOTS
  sceneLabel.text = @"";
  return;
#endif
  
  /*use 1-based scene numbering for the unwashed masses*/
  sceneLabel.text = [NSString stringWithFormat:@"%d/%lu", cartoon.currentSceneIndex + 1, (unsigned long)cartoon.scenes.count];
}

/*
 update frameSlider's range and value to whatever the current
 cartoon is.
 */
-(void)updateFrameSlider
{
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  FLCartoon*cartoon = coreData.currentCartoon;
  
  insist (cartoon && cartoon.currentSceneIndex >= 0);
  insist (cartoon.currentSceneIndex < cartoon.scenes.count);
  
  
  insist (frameSlider);
  frameSlider.maximumValue = cartoon.scenes.count - 1;
  frameSlider.value = cartoon.currentSceneIndex;
}

-(IBAction)flip:(id)sender
{
  [App flipViewControllers];
}
-(IBAction)toolButtonTouched:(id)sender
{
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  /*the tool buttons are tagged starting at 0 in
   the order shown in the case statement below...
   */
  
  insist (canvasView);
  
  switch ([sender tag])
  {
    case 0:
      playPauseButton.hidden = YES;
      frameSlider.hidden = YES;
      canvasView.state = FLCanvasStateDraw;
      break;
    case 1:
      playPauseButton.hidden = YES;
      frameSlider.hidden = YES;
      canvasView.state = FLCanvasStatePolygon;
      break;
    case 2:
      playPauseButton.hidden = YES;
      frameSlider.hidden = YES;
      canvasView.state = FLCanvasStateErase;
      break;
    case 3:
      playPauseButton.hidden = YES;
      frameSlider.hidden = YES;
      canvasView.state = FLCanvasStateFinger;
      break;
    case 4: //undo
      [coreData.undo undo];
      [canvasView refresh];
      break;
    case 5:
      playPauseButton.hidden = YES;
      frameSlider.hidden = YES;
      canvasView.state = FLCanvasStateText;
      break;
    case 6:
      playPauseButton.hidden = NO;
      frameSlider.hidden = NO;
      canvasView.state = FLCanvasStateVideo;
      break;
    case 7: 
      [self share];
      break;
    default:
      insist (0);
      break;
  }
}

/*
 present a UIActivityViewController to let the user share the current
 cartoon as a video.
 */
-(void)share
{
  
  /*if we are on an ipad and we touch the share button and there's already a popover, dismiss the popover*/
  if (sharePopover)
  {
    [sharePopover dismissPopoverAnimated:YES];
    sharePopover = nil;
    return;
  }
  
  __block UIWindow*window;
  __block FLActivityProgressViewController*vc;
  
  NSError*error;
  
  /*save any changes to persistent store*/
  if (![App.coreData saveWithError:&error])
  {
    [UIAlertView showError:error];
    return;
  }
  
  
  FLCartoonProvider*provider = [[FLCartoonProvider alloc]
                                initWithSize:canvasView.frameSize
                                cartoon:App.coreData.currentCartoon
                                error:&error block:^(BOOL done, float progress, NSError *error) {
                                  
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                    
                                    
                                    if (error)
                                    {
                                      [UIAlertView showError:error];
                                      [window resignKeyWindow];
                                      window.hidden = YES;
                                      window = nil;
                                      vc = nil;
                                      return;
                                    }
                                    if (done)
                                    {
                                      [window resignKeyWindow];
                                      // window.hidden = YES;
                                      window = nil;
                                      vc = nil;
                                    }
                                    else
                                    {
                                      if (!vc)
                                        vc = [FLActivityProgressViewController activityProgressWindow:&window];
                                      [vc setProgress:progress];
                                    }
                                  });
                                }];
  
  if (error)
  {
    [UIAlertView showError:error];
    return;
  }
  
  NSString*shareString = NSLocalizedString (@"Here is a cartoon I made with Flip Cartoon.", nil);
  
  UIActivityViewController*activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[shareString, provider] applicationActivities:nil];
  
  /*present the action sheet as a modal view or as a popover depending on if we are on a phone or an ipad*/
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    [self presentViewController:activityVC animated:YES completion:nil];
  }
  else
  {
    insist (!sharePopover);
    sharePopover = [[UIPopoverController alloc]initWithContentViewController:activityVC];
    insist (sharePopover);
    [sharePopover presentPopoverFromRect:shareButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
  }
}
/*
 add new scene after current scene, make it the current
 scene.
 */
-(IBAction)addScene:(id)sender
{
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  FLCartoon*cartoon = coreData.currentCartoon;
  insist (cartoon);
  FLScene*scene = cartoon.currentScene;
  insist (scene);
  
  /*if the user hasn't purchased unlimted frames he can't add more than the limit*/
  if (cartoon.scenes.count >= kFLPurchasesFrameLimit && !App.purchases.unlimitedFrames)
  {
    [UIAlertView showAlertWithTitle:NSLocalizedString (@"Frame Limit", nil)
                             format:NSLocalizedString (@"You have reached your limit of %d frames. Use In-App Purchases to remove this limit.", nil), (int)kFLPurchasesFrameLimit];
    return;
  }
  
  /*insert clone of current scene after current scene*/
  FLScene*newScene = [scene cloneAfterSelf];
  insist (newScene);
  insist ([cartoon.scenes containsObject:newScene]);
  insist ([cartoon indexOfScene:newScene] == cartoon.currentSceneIndex + 1);
  
  /*set currentScene to be the clone*/
  [self changeCurrentSceneIndex:cartoon.currentSceneIndex + 1 slideRight:NO];
  
  /*don't remember undos across scenes*/
  [coreData.undo reset];
}

/*
 delete current scene
 */
-(IBAction)deleteScene:(id)sender
{
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  FLScene*scene = App.currentScene;
  insist (scene);
  FLCartoon*cartoon = coreData.currentCartoon;
  insist (cartoon);
  
  [coreData deleteScene:scene];
  
  /*set currentScene to the same, sliding in a leftover scene from the left*/
  [self changeCurrentSceneIndex:cartoon.currentSceneIndex slideRight:NO];
  
  /*don't remember undos across scenes*/
  [coreData.undo reset];
}

/*
 FLCanvasViewDelegate method. advance to previous scene, if any.
 
 canvasView - the canvasView.
 */
-(void)canvasViewSwipedRight:(FLCanvasView*)aCanvasView
{
  insist (aCanvasView == canvasView);
  
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  FLCartoon*cartoon = coreData.currentCartoon;
  
  insist (cartoon && cartoon.currentSceneIndex >= 0);
  insist (cartoon.currentSceneIndex < cartoon.scenes.count);
  
  if (cartoon.currentSceneIndex > 0)
  {
    [self changeCurrentSceneIndex:cartoon.currentSceneIndex - 1 slideRight:YES];
    [coreData.undo reset];
  }
}

/*
 FLCanvasViewDelegate method. advance to next scene, if any.
 
 canvasView - the canvasView.
 */
-(void)canvasViewSwipedLeft:(FLCanvasView*)aCanvasView
{
  insist (aCanvasView == canvasView);
  
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  FLCartoon*cartoon = coreData.currentCartoon;
  
  insist (cartoon && cartoon.currentSceneIndex >= 0);
  insist (cartoon.currentSceneIndex < cartoon.scenes.count);
  
  if (cartoon.currentSceneIndex < cartoon.scenes.count - 1)
  {
    [self changeCurrentSceneIndex:cartoon.currentSceneIndex + 1 slideRight:NO];
    [coreData.undo reset];
  }
}

/*
 enable or disable all of the main buttons on screen.
 this is used during playback, where only play/pause
 is enabled.
 
 enabled - true if the buttons should be enabled
 */
-(void)setButtonsEnabled:(BOOL)enabled
{
  insist (bottomButtons);
  
  for (UIButton*button in bottomButtons)
    button.enabled = enabled;
  
  flipButton.enabled = enabled;
}
/*
 action for the play/pause button. start or stop a timer that
 advances the cartoon from where it is at the frame rate until
 it reaches the end.
 
 for this button, selected means put it in the play state (where
 the icon show pause, since the button is acting as a toggle
 */
-(IBAction)playPause:(id)sender
{
  insist (sender == playPauseButton);
  playPauseButton.selected = !playPauseButton.selected;
  
  if (playPauseButton.selected)
  {
    /*get cartoon's frame rate*/
    FLCoreData*coreData = App.coreData;
    insist (coreData);
    
    [coreData.undo reset];
    
    FLCartoon*cartoon = coreData.currentCartoon;
    insist (cartoon && cartoon.currentSceneIndex >= 0);
    insist (cartoon.currentSceneIndex < cartoon.scenes.count);
    insist (cartoon.framesPerSecond > 0);
    
    /*if we are already at the last frame, reset to the first frame. this makes
     it easy to replay something w/out having to drag the frame slider back to
     the start
     */
    
    if (cartoon.currentSceneIndex == cartoon.scenes.count -1)
    {
      [cartoon setCurrentScene:0 faulting:YES];
      [self refreshSceneLabel];
      [self updateFrameSlider];
    }
    
    /*disable canvas while we are playing*/
    canvasView.userInteractionEnabled = NO;
    [self setButtonsEnabled:NO];
    
    playTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/cartoon.framesPerSecond target:self selector:@selector (playTimerFireMethod:) userInfo:nil repeats:YES];
    
    [playTimer fire];
  }
  else
  {
    /*turned play off, enable canvas events and cancel timer*/
    canvasView.userInteractionEnabled = YES;
    [self setButtonsEnabled:YES];
    
    if (playTimer)
    {
      [playTimer invalidate];
      playTimer = nil;
    }
  }
  
}

/*
 timer method to advance the cartoon one frame. if we've
 reached the end of the cartoon, toggle the play button back
 to play (it shows the pause icon when it's playing), and
 remove the timer from the run loop.
 
 timer - the timer
 */
-(void)playTimerFireMethod:(NSTimer*)timer
{
  insist (timer == playTimer);
  insist (playPauseButton && playPauseButton.selected);
  
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  FLCartoon*cartoon = coreData.currentCartoon;
  insist (cartoon && cartoon.currentSceneIndex >= 0);
  if (cartoon.currentSceneIndex == cartoon.scenes.count - 1)
  {
    [self setButtonsEnabled:YES];
    canvasView.userInteractionEnabled = YES;
    playPauseButton.selected = NO;
    [timer invalidate];
    playTimer = nil;
    return;
  }
  
  /*advance the scene, faulting the previous one to spare memory*/
  [cartoon setCurrentScene:cartoon.currentSceneIndex + 1 faulting:YES];
  
  [self refreshSceneLabel];
  [self updateFrameSlider];
  [canvasView refresh];
}

/*
 action for frame slider. updates the current scene.
 */
-(IBAction)frameSlider:(id)sender
{
  insist (sender == frameSlider);
  
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  FLCartoon*cartoon = coreData.currentCartoon;
  unsigned index = (unsigned)frameSlider.value;
  insist (index >= 0 && index < cartoon.scenes.count);
  cartoon.currentSceneIndex = index;
  [self refreshSceneLabel];
  [canvasView refresh];
}

/*
 change the cartoon scene with animation. this is used for
 when the user swipes ahead or back, and it's used for adding
 and deleting.
 
 index - the new index.
 slideRight - yes if the animation slides right, no means left
 
 */


-(void)changeCurrentSceneIndex:(NSUInteger)index slideRight:(BOOL)slideRight
{
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  FLCartoon*cartoon = coreData.currentCartoon;
  
  /*find what distance and direction we need to hide the canvas view before we reveal it again*/
  CGFloat hidingDelta = slideRight ? -self.view.bounds.size.width : self.view.bounds.size.width;
  
  /*first take snapshot of current scene*/
  UIView*overlay = [canvasView snapshotViewAfterScreenUpdates:NO];
  if (overlay.superview)
    [overlay removeFromSuperview];
  
  /*put it on top of the canvas view*/
  //[canvasView addSubview:overlay];
  
  /*position the overlay so that it's on-screen on the correct side of the offscreen canvasView*/
  
  CGRect frame = overlay.frame;
  frame.origin.x += -hidingDelta;
  overlay.frame = frame;
  
  /*move the canvasView over to hide it*/
  frame = canvasView.frame;
  frame.origin.x += hidingDelta;
  canvasView.frame = frame;
  
  /*change cartoon's current scene, faulting the old one to save memory*/
  [cartoon setCurrentScene:(int32_t)index faulting:YES];
  
  [canvasView refresh];
  canvasView.userInteractionEnabled = NO;
  [self setButtonsEnabled:NO];
  
  [UIView animateWithDuration:SCENE_CHANGE_DURATION animations:^{
    
    CGRect canvasViewFrame = canvasView.frame;
    
    canvasViewFrame.origin.x += -hidingDelta;
    
    /*the actual animation*/
    canvasView.frame = canvasViewFrame;
    
  } completion:^(BOOL finished) {
    
    [self refreshSceneLabel];
    [self updateFrameSlider];
    [overlay removeFromSuperview];
    
    canvasView.userInteractionEnabled = YES;
    [self setButtonsEnabled:YES];
  }];
}

#pragma mark - iAd

/*
 hide or show the iAd banner
 
 hidden - true if the banner should be hidden.
 animated - true if the banner should be animated.
 */
-(void)setAdBannerHidden:(BOOL)hidden animated:(BOOL)animated
{
  /*
   if there's no banner view, it means ads have been turned off. let this
   method be a no-op in that case, even though this method is not really
   going to ever be called after ads are turned off.
   */
  if (!adBannerView)
    return;
  
  insist (adBannerVerticalSpaceConstraint);
  
  /*if we don't need to do anything, just return*/
  if (hidden == adBannerIsHidden)
    return;
  
  if (animated)
  {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:AD_BANNER_DURATION];
  }
  
  /*probably since we are using autolayout we can't slide the thing by messing w/ its frame*/
  adBannerVerticalSpaceConstraint.constant = hidden ? - adBannerView.frame.size.height : 0;
  adBannerView.hidden = hidden;
  [self.view setNeedsUpdateConstraints];
  [self.view layoutIfNeeded];
  
  if (animated)
  {
    [UIView commitAnimations];
  }
  adBannerIsHidden = hidden;
}

/*
 permanently kill iAd banners
 */
-(void)killAds
{
  if (!adBannerView)
    return;
  
  adBannerView.delegate = nil;
  [adBannerView removeFromSuperview];
  adBannerView = nil;
 }

/*
 ADBannerViewDelegate methods
 */
-(void)bannerView:(ADBannerView*)banner didFailToReceiveAdWithError:(NSError*)error
{
  [self setAdBannerHidden:YES animated:YES];
}
-(BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
  return YES;
}
-(void)bannerViewActionDidFinish:(ADBannerView*)banner
{
  insist (banner == adBannerView);
}
-(void)bannerViewDidLoadAd:(ADBannerView*)banner
{
  [self setAdBannerHidden:NO animated:YES];
}
- (void)bannerViewWillLoadAd:(ADBannerView*)banner
{
}
@end
