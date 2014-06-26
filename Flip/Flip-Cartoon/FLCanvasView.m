//
//  FLCanvasView.m
//  Flip
//
//  Created by Finucane on 5/30/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLCanvasView.h"
#import "FLCoreData.h"
#import "FLAppDelegate.h"

#import "insist.h"

#define TOUCH_RADIUS [self viewDimensionToCartoonDimension:10]
static CGFloat const FRAME_MARGIN_PIXELS = 50;
static CGFloat const MINIMUM_SCALE = 1.0;
static CGFloat const MAXIMUM_SCALE = 3.0;
static float const MAX_PAN_VELOCITY = 400;

@implementation FLCanvasView

- (id)initWithCoder:(NSCoder*)decoder
{
  if ((self = [super initWithCoder:decoder]))
  {
    self = [self initWithFrame:self.frame];
  }
  return self;
  
}
- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    fixedScale = pinchScale = 1.0;
    origin = CGPointMake (0, 0);
    
    /*start at no state. this is to trap programmer errors*/
    state = FLCanvasStateNone;
    
    /*
     set up gestures. we make all the gesture recognizers we need and enable/disable them
     depending on what state the view is in.
     */
    [self setMultipleTouchEnabled:YES];
    singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector (tapped:)];
    insist (singleTapRecognizer);
    
    doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector (tapped:)];
    insist (doubleTapRecognizer);
    doubleTapRecognizer.numberOfTapsRequired = 2;
    
    panRecognizer = [[DFPanGestureRecognizer alloc] initWithTarget:self action:@selector (panned:)];
    insist (panRecognizer);
    panRecognizer.maximumNumberOfTouches = 1;
    
    pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector (pinched:)];
    insist (pinchRecognizer);
    
    rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector (swiped:)];
    insist (rightSwipeRecognizer);
    rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    rightSwipeRecognizer.numberOfTouchesRequired = 1;
    
    leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector (swiped:)];
    insist (leftSwipeRecognizer);
    leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    leftSwipeRecognizer.numberOfTouchesRequired = 1;
    
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    [leftSwipeRecognizer requireGestureRecognizerToFail:panRecognizer];
    [rightSwipeRecognizer requireGestureRecognizerToFail:panRecognizer];
    
    
    [self addGestureRecognizer:singleTapRecognizer];
    [self addGestureRecognizer:doubleTapRecognizer];
    [self addGestureRecognizer:panRecognizer];
    [self addGestureRecognizer:pinchRecognizer];
    [self addGestureRecognizer:leftSwipeRecognizer];
    [self addGestureRecognizer:rightSwipeRecognizer];
    
    /*make the mutable string to do key input to*/
    keyInputString = [[NSMutableString alloc] init];
    insist (keyInputString);
    
    /*make sure rotation triggers a redraw*/
    self.contentMode = UIViewContentModeRedraw;

    layerIsDirty = YES;
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  if (layerRef)
  {
    CGLayerRelease (layerRef);
    layerRef = nil;
  }
  
  [self moveFrame:CGPointMake (0, 0)];
  layerIsDirty = YES;
}

-(void)dealloc
{
  if (layerRef)
    CGLayerRelease (layerRef);
}
-(void)updateSelectedText
{
  insist (selectedText);
  selectedText.text = [NSString stringWithString:keyInputString];
  [selectedText recomputeFontSize];
  [self setNeedsDisplay];
}
/*
 UIKeyInput methods. return key is done button, so if we are inserting "\n",
 hide keyboard instead.
 */
-(void)deleteBackward
{
  insist (keyInputString);
  insist (selectedText);
  
  if (keyInputString.length)
  {
    [keyInputString deleteCharactersInRange:NSMakeRange(keyInputString.length - 1, 1)];
    [self updateSelectedText];
  }
}
- (BOOL)hasText
{
  insist (keyInputString);
  insist (selectedText);
  
  return keyInputString.length > 0;
}
- (void)insertText:(NSString*)text
{
  [App.coreData.undo beginUndoGrouping];
  
  FLCartoon*cartoon = App.coreData.currentCartoon;
  
  insist (selectedText);
  insist (text);
  insist (text.length == 1);
  if ([text isEqualToString:@"\n"])
  {
    [self resignFirstResponder];
  }
  else
  {
    [keyInputString appendString:text];
    [self updateSelectedText];
    
    if ([keyInputString isEqualToString:@"testapp1"]) //complex scenes, many of them
    {
      [cartoon addTestScenes1];
      [self setNeedsDisplay];
    }
    else if ([keyInputString isEqualToString:@"testapp2"]) //simple scenes, many of them
    {
      [cartoon addTestScenes2];
      [self setNeedsDisplay];
    }
    else if ([keyInputString isEqualToString:@"testapp3"]) //complex scenes, few of them
    {
      [cartoon addTestScenes3];
      [self setNeedsDisplay];
    }
    else if ([keyInputString isEqualToString:@"testapp4"]) //complex scenes, few of them, followed by lots of clones of last scene
    {
      [cartoon addTestScenes4];
      [self setNeedsDisplay];
    }
  }
  [App.coreData.undo endUndoGrouping];
}

/*
 override UIResponder method to enable keyboard
 
 */
- (BOOL)canBecomeFirstResponder
{
  return YES;
}
/*
 UITextInputTraits
 */
-(UIReturnKeyType) returnKeyType
{
  return UIReturnKeyDone;
}
/*
 convert a point in the view's coordinate system to one in the cartoon's
 system. the difference is from scaling and where the origin is
 
 point - point in UIView coordinate system
 
 returns: point in cartoon coordinate system
 */
-(CGPoint)viewPointToCartoonPoint:(CGPoint)point
{
  insist (self.scale);
  
  CGPoint p;
  p.x = point.x / self.scale - origin.x;
  p.y = point.y / self.scale - origin.y;
  
  return p;
}
/*
 inverse of cartoonPointToViewPoint
 */
-(CGPoint)cartoonPointToViewPoint:(CGPoint)point
{
  insist (self.scale);
  
  CGPoint p;
  p.x = (point.x + origin.x) * self.scale;
  p.y = (point.y + origin.y) * self.scale;
  
  return p;
}

-(CGFloat)viewDimensionToCartoonDimension:(CGFloat)d
{
  insist (self.scale);
  return d / self.scale;
}
-(CGFloat)cartoonDimensionToViewDimension:(CGFloat)d
{
  insist (self.scale);
  return d * self.scale;
}
/*
 return scale. this is the real-time scale while doing a pinch, or it's
 the current scale (when pinchScale goes back to 1.0, and fixedScale
 was changed to the end result of the last pinch.
 */

-(CGFloat)scale
{
  return fixedScale * pinchScale;
}

/*
 return cartoon frame dimensions, in view units, which is as big as the view is in landscape mode
 */
-(CGSize) frameSize
{
  CGSize size = self.frame.size;
  if (size.width < size.height)
  {
    CGFloat t = size.width;
    size.width = size.height;
    size.height = t;
  }
  return size;
}
/*
 move the frame by delta, but constraining it so that no more than FRAME_MARGIN_PIXELS
 are visible outside any edge of the cartoon. sets layerIsDirty.
 
 delta - amount to move frame, in cartoon units.
 */

-(void)moveFrame:(CGPoint)delta
{
  origin.x += delta.x;
  origin.y += delta.y;
  
  CGSize viewSize = self.frame.size;
  CGSize frameSize = self.frameSize;
  CGPoint corner = [self viewPointToCartoonPoint:CGPointMake(viewSize.width - FRAME_MARGIN_PIXELS, viewSize.height - FRAME_MARGIN_PIXELS)];
  
  if (corner.x > frameSize.width)
    origin.x += (corner.x - frameSize.width);
  if (corner.y > frameSize.height)
    origin.y += (corner.y - frameSize.height);
  
  corner = [self viewPointToCartoonPoint:CGPointMake (FRAME_MARGIN_PIXELS, FRAME_MARGIN_PIXELS)];
  
  
  if (corner.x < 0)
    origin.x += corner.x;
  if (corner.y < 0)
    origin.y += corner.y;
  
  layerIsDirty = YES;
  
}
/*
 update pinchScale moving origin so the cartoon is still centered
 
 this works by figuring out what the visible center was before the
 new scale, in cartoon coordinates, then finding out what the
 visible center should be after the new zoom (with no origin changes),
 then computing the difference and finally shifting the origin by
 that difference.
 
 this method also enforces minimum scale. and sets layerIsDirty.
 
 scale - the pinch scale
 */
-(void)updatePinchScaleAndCenter:(CGFloat)newPinchScale
{
  CGSize size = self.bounds.size;
  CGFloat s1 = self.scale;
  CGFloat s2 = fixedScale * newPinchScale;
  
  /*if the new scale's going to be too small, don't update pinchScale etc*/
  
  if (s2 < MINIMUM_SCALE || s2 > MAXIMUM_SCALE)
    return;
  
  CGPoint c1, c2;
  c1.x = size.width / 2 / s1 + origin.x;
  c1.y = size.height / 2 / s1 + origin.y;
  c2.x = size.width / 2 / s2 + origin.x;
  c2.y = size.height / 2 / s2 + origin.y;
  
  [self moveFrame:CGPointMake(c2.x-c1.x, c2.y-c1.y)];
  
  pinchScale = newPinchScale;
}

/*
 wrapper to change current shape, including setting no current shape at all.
 sets layerIsDirty so that we redraw the static part of the scene.
 
 index - new current shape for current scene, -1 if none
 
 returns:  new current shape index.
 */
-(int32_t)setCurrentShapeIndex:(int32_t)index
{
  FLCartoon*cartoon = App.coreData.currentCartoon;
  FLScene*scene = cartoon.currentScene;
  insist (scene);
  
  scene.currentShapeIndex = index;
  
  if (index < 0)
  {
    selectedText = nil;
    [self resignFirstResponder];
  }
  layerIsDirty = YES;
  [self setNeedsDisplay];
  
  return index;
}
/*
 action for tap gesture recognizers.
 
 in polygon mode double tap polgon cycles color
 in finger mode on single tap selects shape.
 in erase mode on single tap erases selected path if any
 in erase mode on double tap erases selected shape if any
 */
- (void)tapped:(UIGestureRecognizer*)recognizer
{
  FLCartoon*cartoon = App.coreData.currentCartoon;
  
  insist (self.canvasViewDelegate && recognizer);
  insist (recognizer == singleTapRecognizer || recognizer == doubleTapRecognizer);
  insist (cartoon);
  
  BOOL isSingleTap = recognizer == singleTapRecognizer;
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  /*see if we touched anything*/
  touchPoint = [recognizer locationInView:self];
  CGPoint cartoonPoint = [self viewPointToCartoonPoint:touchPoint];
  
  FLScene*scene = cartoon.currentScene;
  insist (scene);
  
  [coreData.undo beginUndoGrouping];
  
  switch (state)
  {
    case FLCanvasStatePolygon:
      if (!isSingleTap)
      {
        FLStroke*stroke = [cartoon.currentScene strokeForPoint:cartoonPoint radius:TOUCH_RADIUS];
        
        if (stroke && stroke.isPolygon)
        {
          //bad, bad, bad
          [(FLPolygon*)stroke incrementColorIndex];
          if (stroke.shape != scene.currentShape)
            layerIsDirty = YES;
          [self setNeedsDisplay];
        }
      }
      break;
    case FLCanvasStateFinger:
    {
      FLStroke*stroke = [cartoon.currentScene strokeForPoint:cartoonPoint radius:TOUCH_RADIUS];
      
      /*if we hit a new shape, change the current shape and if it's a double tap make topmost shape*/
      if (stroke)
      {
        if (!isSingleTap)
        {
          [scene removeShapesObject:stroke.shape];
          [scene addShapesObject:stroke.shape];
          [self setNeedsDisplay];
          layerIsDirty = YES;
        }
        if (stroke.shape != scene.currentShape)
        {
          layerIsDirty = YES;
          self.currentShapeIndex = (int32_t)[scene indexOfShape:stroke.shape];
          [self setNeedsDisplay];
        }
      }
      else
      {
        /*
         we hit nothing. unselect any current shape. the way new (empty) shapes are created
         is when dragging and there's no current shape, so being able to unselect a shape
         is necessary
         */
        self.currentShapeIndex = -1;
      }
    }
      //double tap means nothing in finger mode
      break;
    case FLCanvasStateErase:
    {
      FLStroke*stroke = [scene strokeForPoint:cartoonPoint radius:TOUCH_RADIUS];
      
      /*if we hit a shape, delete path or entire shape depending on tap count*/
      if (stroke)
      {
        [self eraseStroke:stroke eraseShape:!isSingleTap];
        
      }
      break;
    }
    case FLCanvasStateText:
    {
      /*
       if we hit a text, then set that text as the selected text, set keyInputString to its text
       and make sure the keyboard is visible. if we hit a non-text or nothing at all do nothing,
       the selected stuff doesn't change so the user knows his touch was ineffectual.
       */
      
      FLStroke*stroke = [cartoon.currentScene strokeForPoint:cartoonPoint radius:TOUCH_RADIUS];
      
      if (stroke && stroke.isText)
      {
        /*set currentShape to shape of text if it's not already*/
        if (stroke.shape != scene.currentShape)
          self.currentShapeIndex = (int32_t)[scene indexOfShape:stroke.shape];
        
        /*
         set selected text and the keyInput string, using the empty string if poly
         doesn't have a text string.
         */
        selectedText = (FLText*)stroke;
        
        insist (keyInputString);
        [keyInputString setString:selectedText.text ? selectedText.text : @""];
        [self becomeFirstResponder];
      }
      else
      {
        /*
         we hit nothing. unselect any current shape. the way new (empty) shapes are created
         is when dragging and there's no current shape, so being able to unselect a shape
         is necessary
         */
        self.currentShapeIndex = -1;
      }
      [self setNeedsDisplay];
    }
      break;
    default:
      break;
  }
  [coreData.undo endUndoGrouping];
}

/*
 this happens twice, in drag erase and touch erase, so it's
 its own method.
 */
-(void)eraseStroke:(FLStroke*)stroke eraseShape:(BOOL)eraseShape
{
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  FLCartoon*cartoon = coreData.currentCartoon;
  insist (cartoon);
  
  FLScene*scene = cartoon.currentScene;
  insist (scene);
  
  insist (stroke);
  
  FLShape*shape = stroke.shape;
  insist (shape);
  
  /*if we're erasing part of a shape that's not selected, it's being drawn
   in layerRect, so mark the rect as needing to be redrawn.
   */
  BOOL wasCurrentShape = shape == scene.currentShape;
  if (!wasCurrentShape)
    layerIsDirty = YES;
  
  /*if the shape was original, clone it, since we are modifying it*/
  if (![shape isOriginalInScene:scene])
  {
    shape = [shape cloneToScene:scene stroke:&stroke];
    insist (shape && stroke);
  }
  insist ([shape isOriginalInScene:scene]);
  
  /*
   remove path, and if the shape has no more paths, and was currrentShape, unset currentShape.
   the shape will remain invisible and not selectable and be culled later, it's too hard to
   cull it and deal with undo. making a new shape, starting w/ a path, erasing the 1 path, and
   adding another path really ends up creating a new shape after the 1st shape was invisible.
   
   if the shape still has paths, make sure it is the selected shape. this is so that the shape
   is redrawn with ghosts.
   */
  [shape removeStrokesObject:stroke];
  [shape.managedObjectContext deleteObject:stroke];
  
  if (!eraseShape)
  {
    if (shape.strokes.count == 0 && shape == scene.currentShape)
      self.currentShapeIndex = -1;
    else if (!wasCurrentShape)
      self.currentShapeIndex = (int32_t)[scene indexOfShape:shape];
  }
  else
  {
    [shape removeStartingAtScene:scene];
    
    /*if we deleted current shape, unset currentShape*/
    if (shape == scene.currentShape)
      self.currentShapeIndex = -1;
    
  }
  [self setNeedsDisplay];
  
}
/*
 action for pan gesture recognizer. add point to path if we are drawing a path,
 move shape if we are moving a shape, erase a path if we erased through a path,
 otherwise pan the view. wrap the drawing and shape moving events inside an
 undoGroup so that undo undoes the whole operation.
 
 the mode logic goes like this:
 
 if we are in draw or polygon mode and there is a current shape, start adding a new path to that shape.
 if we are in draw or polygon mode and there is no current shape, make a new shape, and start adding a path.
 if we are in finger mode and the initial touch hits a shape, start moving the shape.
 if we are in finger mode and the initial touch hits nothing, start panning.
 if we are in erase mode and we dragged across a path, remove the path. (just tapping down isn't enough here).
 */

- (void)panned:(UIGestureRecognizer*)recognizer
{
  insist (self.canvasViewDelegate && recognizer && recognizer == panRecognizer);
  
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  FLCartoon*cartoon = coreData.currentCartoon;
  insist (cartoon);
  
  FLScene*scene = cartoon.currentScene;
  insist (scene);
  
  switch (recognizer.state)
  {
    case UIGestureRecognizerStateBegan:
      
      /*when the pan starts, remember start point. */
      touchPoint = previousPoint = [recognizer locationInView:self];
      previousTranslation = [panRecognizer translationInView:self];
      
      /*
       pan gesture recognizers give the touchPoint as the first point after enough movement
       was done to indicate a pan. not the point for the intitial touchesBegan. get that first point\
       */
      
      [coreData.undo beginUndoGrouping];
      
      CGPoint touchesBeganPoint = panRecognizer.touchesBeganPoint;
      
      /*drawing starts a new path ...*/
      if (state == FLCanvasStateDraw || state == FLCanvasStatePolygon || state == FLCanvasStateText)
      {
        /*if there is a current shape and it is an original, clone it.*/
        if (scene.currentShape && ![scene.currentShape isOriginalInScene:scene])
          [scene.currentShape cloneToScene:scene stroke:nil];
        
        /*if there's no currentShape make a new shape and set it as the current one*/
        if (!scene.currentShape)
        {
          FLShape*shape = [coreData newShapeForScene:scene];
          
          insist (shape);
          insist (scene.shapes.count && [scene.shapes lastObject] == shape);
          self.currentShapeIndex = (int32_t)scene.shapes.count - 1;
        }
        
        insist ([scene.currentShape isOriginalInScene:scene]);
        
        /*for states that add paths, add a new path ...*/
        if (state == FLCanvasStateDraw || state == FLCanvasStatePolygon)
        {
          /*add a new path to the shape*/
          FLPath*path = state == FLCanvasStateDraw ?
          [coreData newPathForShape:scene.currentShape] :
          [coreData newPolygonForShape:scene.currentShape];
          insist (path);
          
          FLPoint*p = [coreData newPointForPath:path point:[self viewPointToCartoonPoint:touchesBeganPoint]];
          insist (p);
          
          /*add the touch point to the path*/
          p = [coreData newPointForPath:path point:[self viewPointToCartoonPoint:touchPoint]];
          insist (p);
          
          panState = FLCanvasPanStateAddingPath;
        }
        else
        {
          insist (state == FLCanvasStateText);
          
          /*add a new text to shape*/
          FLText*text = [coreData newTextForShape:scene.currentShape];
          insist (text);
          
          /*set its initial dimensions, which will change as the user pans around. this may be a zero sized text initially*/
          textOrigin = [self viewPointToCartoonPoint:panRecognizer.touchesBeganPoint];
          [text setWithPoint:textOrigin b:[self viewPointToCartoonPoint:touchPoint]];
          
          selectedText = text;
          
          panState = FLCanvasPanStateSizingTextBox;
        }
        [self setNeedsDisplay];
      }
      else if (state == FLCanvasStateFinger)
      {
        /*if we hit a shape, start moving it. we set the currentShape to it, and set that we are in moving mode.*/
        FLStroke*stroke = [cartoon.currentScene strokeForPoint:[self viewPointToCartoonPoint:touchesBeganPoint]
                                                        radius:TOUCH_RADIUS];
        if (stroke)
        {
          FLShape*shape = stroke.shape;
          
          /*if we hit a non-current shape, we are changing something in layerRect*/
          if (shape != scene.currentShape)
            layerIsDirty = YES;
          
          /*if the shape was original, clone it, since we are modifying it*/
          if (![shape isOriginalInScene:scene])
          {
            shape = [shape cloneToScene:scene stroke:&stroke];
            insist (shape && stroke);
          }
          insist ([shape isOriginalInScene:scene]);
          
          /*if we hit a text's lower right corner go into text resize mode*/
          
          FLText*text = (FLText*)stroke;
          if (text.isText && [text lowerRightHitsPoint:[self viewPointToCartoonPoint:touchesBeganPoint] radius:TOUCH_RADIUS])
          {
            selectedText = text;
            textOrigin = CGPointMake (selectedText.x, selectedText.y);
            
            panState = FLCanvasPanStateSizingTextBox;
            
          }
          else
          {
            panState = FLCanvasPanStateMovingShape;
          }
          
          self.currentShapeIndex = (int32_t)[scene indexOfShape:shape];
          insist (scene.currentShape == shape);
          [self setNeedsDisplay];
        }
        else
          panState = FLCanvasPanStatePanningView;
      }
      else if (state == FLCanvasStateErase)
      {
        panState = FLCanvasPanStateErasing;
      }
      else
        panState = FLCanvasPanStateNone;
      break;
      
    case UIGestureRecognizerStateChanged:
    {
      /*
       when the pan moves, get the translation, which is an offset from the start of the gesture, compute
       the change in translation from the previous one and use that to move the shape.
       
       also get the new point.
       */
      CGPoint translation = [panRecognizer translationInView:self];
      CGPoint point;
      point.x = touchPoint.x + translation.x;
      point.y = touchPoint.y + translation.y;
      CGPoint delta;
      delta.x = [self viewDimensionToCartoonDimension:translation.x - previousTranslation.x];
      delta.y = [self viewDimensionToCartoonDimension:translation.y - previousTranslation.y];
      previousTranslation = translation;
      
      if (panState == FLCanvasPanStateAddingPath)
      {
        insist (scene.currentShape);
        insist ([scene.currentShape isOriginalInScene:scene]);
        
        /*we don't add identical points in a row*/
        FLPoint*p = [coreData newPointForPath:[scene.currentShape.strokes lastObject] point:[self viewPointToCartoonPoint:point]];
        if (p)
        {
          [self setNeedsDisplay];
        }
        
      }
      else if (panState == FLCanvasPanStateSizingTextBox)
      {
        insist (selectedText);
        
        /*update the text's dimensions*/
        [selectedText setWithPoint:textOrigin b:[self viewPointToCartoonPoint:point]];
        [selectedText recomputeFontSize];
        [self setNeedsDisplay];
      }
      else if (panState == FLCanvasPanStateMovingShape)
      {
        insist (scene.currentShape);
        insist ([scene.currentShape isOriginalInScene:scene]);
        [scene.currentShape moveBy:delta.x dy:delta.y];
        [self setNeedsDisplay];
      }
      else if (panState == FLCanvasPanStateErasing)
      {
        /*if we drag erased across a path, remove it.*/
        
        FLStroke*stroke = [cartoon.currentScene strokeForLineFrom:[self viewPointToCartoonPoint:previousPoint]
                                                               to:[self viewPointToCartoonPoint:touchPoint]];
        if (stroke)
          [self eraseStroke:stroke eraseShape:NO];
      }
      else if (panState == FLCanvasPanStatePanningView)
      {
        [self moveFrame:delta];
        [self setNeedsDisplay];
        
      }
      previousPoint = point;
      break;
    }
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateEnded:
      [coreData.undo endUndoGrouping];
      break;
    default:
      break;
  }
}

/*
 when we pinch, update pinchScale, which is the real-time scale taking into account
 the current overall scale and what the pinch is doing.
 
 once the pinch is over, the overall scale is changed to be scale * pinchScale, and
 pinchScale is reset to 1.0.
 
 in doing the actual drawing the scale is: scale * pinchScale.
 
 */
- (void)pinched:(UIGestureRecognizer*)recognizer
{
  insist (self.canvasViewDelegate && recognizer && recognizer == pinchRecognizer);
  
  switch (recognizer.state)
  {
    case UIGestureRecognizerStateBegan:
      insist (pinchScale == 1);
      break;
    case UIGestureRecognizerStateChanged:
      [self updatePinchScaleAndCenter:pinchRecognizer.scale];
      [self setNeedsDisplay];
      break;
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateEnded:
      fixedScale *= pinchScale;
      pinchScale = 1.0;
    default:
      break;
  }
}
- (void)swiped:(UIGestureRecognizer*)recognizer
{
  insist (self.canvasViewDelegate && recognizer);
  if (recognizer == leftSwipeRecognizer)
    [self.canvasViewDelegate canvasViewSwipedLeft:self];
  else if (recognizer == rightSwipeRecognizer)
    [self.canvasViewDelegate canvasViewSwipedRight:self];
  else
  {
    insist (0);
  }
}

-(FLCanvasState)state
{
  return state;
}

/*
 setter for state. As a side-effect, updates which gesture recognizers are attached
 
 aState - new state for view
 */
-(void)setState:(FLCanvasState)aState
{
  insist (aState != FLCanvasStateNone);
  
  /*if we aren't changing anything, it's a no-op*/
  if (aState == state)
    return;
  
  /*
   basically, drawing modes disable tapping and swiping, swipe is enabled otherwise, double
   tap is disabled for text.
   
   finger mode can both pan and swipe and this is a potential conflict between moving
   the scene around or an object in the scene, and swiping to a different scene. the
   way around this is that pans take precedence over swipes, and fast pans are disallowed
   entirely.
   
   in the case where swipe is enabled we turn off the pan velocity test.
   */
  state = aState;
  switch (state)
  {
    case FLCanvasStateDraw:
      singleTapRecognizer.enabled = NO;
      doubleTapRecognizer.enabled = NO;
      panRecognizer.enabled = YES;
      pinchRecognizer.enabled = YES;
      leftSwipeRecognizer.enabled = NO;
      rightSwipeRecognizer.enabled = NO;
      panRecognizer.maxVelocity = CGPointMake (0, 0);
      break;
    case FLCanvasStatePolygon:
      singleTapRecognizer.enabled = NO;
      doubleTapRecognizer.enabled = YES;
      panRecognizer.enabled = YES;
      pinchRecognizer.enabled = YES;
      leftSwipeRecognizer.enabled = NO;
      rightSwipeRecognizer.enabled = NO;
      panRecognizer.maxVelocity = CGPointMake (0, 0);
      break;
    case FLCanvasStateFinger:
      singleTapRecognizer.enabled = YES;
      doubleTapRecognizer.enabled = YES;
      panRecognizer.enabled = YES;
      pinchRecognizer.enabled = YES;
      leftSwipeRecognizer.enabled = YES;
      rightSwipeRecognizer.enabled = YES;
      panRecognizer.maxVelocity = CGPointMake (MAX_PAN_VELOCITY, 0);
      break;
    case FLCanvasStateErase:
      singleTapRecognizer.enabled = YES;
      doubleTapRecognizer.enabled = YES;
      panRecognizer.enabled = YES;
      pinchRecognizer.enabled = YES;
      leftSwipeRecognizer.enabled = NO;
      rightSwipeRecognizer.enabled = NO;
      panRecognizer.maxVelocity = CGPointMake (0, 0);
      break;
    case FLCanvasStateText:
      singleTapRecognizer.enabled = YES;
      doubleTapRecognizer.enabled = NO;
      panRecognizer.enabled = YES;
      pinchRecognizer.enabled = YES;
      leftSwipeRecognizer.enabled = NO;
      rightSwipeRecognizer.enabled = NO;
      panRecognizer.maxVelocity = CGPointMake (0, 0);
      break;
    case FLCanvasStateVideo:
      singleTapRecognizer.enabled = YES;
      doubleTapRecognizer.enabled = NO;
      panRecognizer.enabled = NO;
      pinchRecognizer.enabled = NO;
      leftSwipeRecognizer.enabled = YES;
      rightSwipeRecognizer.enabled = YES;
      panRecognizer.maxVelocity = CGPointMake (MAX_PAN_VELOCITY, 0);
      break;
    default:
      insist (0);
      break;
  }
}


/*
 method to let callers tell the view to redraw.
 used when the cartoon scene index changes.
 
 this invalidates layerRef (the backing store for non selected shapes).
 */
-(void)refresh
{
  /*unselect everything.*/
  self.currentShapeIndex = -1;
  layerIsDirty = YES;
  [self setNeedsDisplay];
}

-(void)drawLayerRect:(CGRect)rect
{
  FLCartoon*cartoon = App.coreData.currentCartoon;
  insist (cartoon);
  
  /* if we haven't made a layerRef yet do it now. */
  if (!layerRef)
  {
    CGContextRef context = UIGraphicsGetCurrentContext ();
    
    /*get scale of pixels themselves (retina = 2)*/
    CGFloat scale = self.contentScaleFactor;
    CGRect bounds = CGRectMake(0, 0, self.bounds.size.width * scale, self.bounds.size.height * scale);
    CGLayerRef layer = CGLayerCreateWithContext (context, bounds.size, NULL);
    CGContextRef layerContext = CGLayerGetContext(layer);
    CGContextScaleCTM(layerContext, scale, scale);
    
    layerRef = CGLayerCreateWithContext (context, bounds.size, nil);
    insist (layerRef);
  }
  
  CGFloat scale = self.contentScaleFactor;
  rect = CGRectMake(0, 0, rect.size.width * scale, rect.size.height * scale);
  
  FLScene*scene = cartoon.currentScene;
  insist (scene);
  
  CGContextRef context = CGLayerGetContext (layerRef);
  
  CGContextSetAllowsAntialiasing (context, YES);
  CGContextSetShouldAntialias (context, YES);
  
  CGContextSaveGState (context);
  
  /*paint context gray*/
  CGContextSetFillColorWithColor (context, [UIColor whiteColor].CGColor);
  
  CGContextFillRect (context, rect);
  
  CGContextScaleCTM (context, scale * self.scale, scale * self.scale);
  CGContextTranslateCTM (context, origin.x, origin.y);
  
  /*draw the cartoon bounds in a rectangle w/ a dropshadow*/
  CGRect cartoonBounds;
  cartoonBounds.origin = CGPointMake(0, 0);
  cartoonBounds.size = [self frameSize];
  CGContextSetRGBFillColor (context, 1.0, 1.0, 1.0, 1.0);
  CGContextSetShadowWithColor(context, CGSizeMake(10, 10), 3.0, [UIColor grayColor].CGColor);
  
  CGContextFillRect (context, cartoonBounds);
  CGContextSetRGBStrokeColor(context, 0, 0, 0, 1.0);
  CGContextSetShadowWithColor(context, CGSizeMake(10, 10), 3.0, 0);
  CGContextStrokeRect (context, cartoonBounds);
  
  /*set the clip rect to be the cartoon bounds*/
  CGContextClipToRect (context, cartoonBounds);
  
  CGContextSetLineWidth (context, cartoon.lineThickness);
  
  for (FLShape*shape in cartoon.currentScene.shapes)
  {
    @autoreleasepool
    {
      if (shape != scene.currentShape)
        [shape drawContext:context scene:scene drawGhosts:NO type:FLDrawNormal];
    }
  }
  
  CGContextRestoreGState (context);
}

/*
 draw the current scene into the view
 */

- (void)drawRect:(CGRect)aRect
{
  FLCartoon*cartoon = App.coreData.currentCartoon;
  insist (cartoon);
  
  FLScene*scene = cartoon.currentScene;
  insist (scene);
  
  CGContextRef context = UIGraphicsGetCurrentContext ();
  
  if (layerIsDirty)
  {
    [self drawLayerRect:self.bounds];
    layerIsDirty = NO;
  }
  
  CGContextSetAllowsAntialiasing (context, NO);
  CGContextSetShouldAntialias (context, NO);
  
  /*draw the layer to the window*/
  CGContextDrawLayerInRect (context, self.bounds, layerRef);
  
  CGContextSetAllowsAntialiasing (context, YES);
  CGContextSetShouldAntialias (context, YES);
  
  CGContextSaveGState (context);
  CGContextScaleCTM (context, self.scale, self.scale);
  CGContextTranslateCTM (context, origin.x, origin.y);
  
  /*only draw w/in the cartoon's rectangle*/
  CGSize size = [self frameSize];
  CGRect rect = CGRectMake(0, 0, size.width, size.height);
  CGContextClipToRect(context, rect);
  
  CGContextSetLineWidth (context, cartoon.lineThickness);
  
  if (scene.currentShape)
  {
    [scene.currentShape drawContext:context scene:scene drawGhosts:YES type:FLDrawSelected];
  }
  
  CGContextRestoreGState (context);
}

@end
