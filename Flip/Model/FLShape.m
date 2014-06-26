//
//  FLShape.m
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLShape.h"
#import "FLStroke.h"
#import "FLScene.h"
#import "FLPoint.h"
#import "geometry.h"
#import "FLAppDelegate.h"
#import "insist.h"

static const CGFloat TOUCH_SIZE = 44;

/*
 graphics with origin at lower left, not upper left like iOS...
 */
@implementation FLShape

@dynamic bbx;
@dynamic bby;
@dynamic bbh;
@dynamic bbw;
@dynamic alpha;
@dynamic strokes;
@dynamic scenes;
@dynamic originalScene;
@dynamic originalShape;
@dynamic clonedShape;
@dynamic cartoon;

-(void)fault
{
  for (FLManagedObject*o in self.strokes)
  {
    if (![o isFault])
      [o fault];
  }
  [self.managedObjectContext refreshObject:self mergeChanges:NO];
}

/*
 if a circle intersects a stroke, return stroke. take into account alpha: an
 invisible shape can't intersect anything.
 
 point - center of circle
 radius - radius of circle
 
 returns: stroke if hit, nil otherwise
 */
-(FLStroke*)strokeForPoint:(CGPoint)point radius:(CGFloat)radius
{
  insist (radius > 0);
  
  if (self.alpha == 0)
    return nil;
  
  for (FLStroke*stroke in [self.strokes reverseObjectEnumerator])
  {
    if ([stroke hitsPoint:point radius:radius])
      return stroke;
  }
  return nil;
}

/*
 if a line segment intersects a stroke, return stroke. take into account alpha: an
 invisible shape can't intersect anything.
 
 a - start of line segment
 b - end of line segment
 
 returns: stroke if hit, nil otherwise
 */
-(FLStroke*)strokeForLineFrom:(CGPoint)a to:(CGPoint)b
{
  if (self.alpha == 0)
    return nil;
  
  for (FLStroke*stroke in [self.strokes reverseObjectEnumerator])
  {
    if ([stroke hitsLine:a to:b])
      return stroke;
  }
  return nil;
}

/*
 return true if the shape was originaly created in scene
 */

-(BOOL)isOriginalInScene:(FLScene*)scene
{
  insist (scene);
  return self.originalScene == scene;
}

/*
 make a copy of shape and add it to scene, marking it as cloned.
 self is already in scene, after it is cloned, self is removed
 from scene. this removal is done inside this method to make it
 more like a replacement. in the normal way of removing a shape,
 the shape is removed from all subsequent scenes.
 
 scene - scene to add new shape to
 stroke - (optional) if non-nil is original stroke and becomes corresponding stroke in clone
 
 returns : new shape which is a clone of self
 */
-(FLShape*)cloneToScene:(FLScene*)scene stroke:(FLStroke*__autoreleasing*)stroke
{
  insist (scene);
  insist (![self isOriginalInScene:scene]);
  insist ([scene.shapes containsObject:self]);
  
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  /*make new shape, not connected to anything*/
  FLShape*shape = [coreData newShape];
  insist (shape);
  
  /*initialize new shape w/ contents of self*/
  shape.bbx = self.bbx;
  shape.bby = self.bby;
  shape.bbh = self.bbh;
  shape.bbw = self.bbw;
  shape.alpha = self.alpha;
  
  /*copy all the strokes, maintaining the original order of strokes and points*/
  for (FLStroke*oldStroke in self.strokes)
  {
    @autoreleasepool
    {
      FLStroke*newStroke = [oldStroke cloneToShape:shape];
      insist (newStroke);
      
      /*
       remember the new stroke that corresponds to old stroke, this
       is used for when cloning is caused by a stroke erase, the calling
       code needs to erase the new stroke.
       */
      if (stroke && *stroke == oldStroke)
        *stroke = newStroke;
    }
  }
  
  shape.originalScene = scene;
  shape.originalShape = self;
  shape.cartoon = scene.cartoon;
  
  /*replace self with new shape in scene. this maintains the order which is used in currentShape*/
  NSUInteger index = [scene.shapes indexOfObject:self];
  insist (index >= 0 && index < scene.shapes.count);
  [scene replaceObjectInShapesAtIndex:index withObject:shape];
  
  insist ([scene.shapes containsObject:shape]);
  
  return shape;
}

/*
  make self's originalScene the next scene after its existing originalScene, if any.
 
  return true if were able to set a new originalScene. false means we are going
  to be deleted from core data. (and probably should be immediately, rather than
  relying on the culling code.
*/
-(BOOL)resetOriginalScene
{
  FLCartoon*cartoon = self.originalScene.cartoon;
  insist (cartoon);
  
  /*
   find the first scene that the clonedShape appears in after our original scene.
   if we're not in any more scenes there won't be any, which isn't a problem
   because we'll be deleted before we save (in the culling code).
   */
  NSUInteger sceneIndex = [cartoon.scenes indexOfObject:self.originalScene] + 1;
  for (;sceneIndex < cartoon.scenes.count; sceneIndex++)
  {
    FLScene*scene = cartoon.scenes [sceneIndex];
    if ([scene.shapes containsObject:self])
    {
      self.originalScene = cartoon.scenes [sceneIndex];
      return YES;
    }
  }
  return NO;
}
/*
  make clonedShape original
 */
-(void)makeCloneOriginal
{
  insist (self.originalScene);
  insist (self.clonedShape);
  insist (self.clonedShape.originalShape == self);

  FLCartoon*cartoon = self.originalScene.cartoon;
  insist (cartoon);
 
  if (self.clonedShape.originalScene == self.originalScene)
    [self.clonedShape resetOriginalScene];
  
  self.clonedShape.originalShape = nil;
  self.clonedShape = nil;
}

/*
 remove a shape from scene and subsequent scenes. if the shape is an original to a another shape,
 remove that shape's reference to it, making it original.
 
 we aren't deleting the shape from core data
 
 scene - scene to remove self from
 */
-(void)removeStartingAtScene:(FLScene*)scene
{
  insist (scene);
  insist (scene.cartoon);
  insist ([scene.cartoon.scenes containsObject:scene]);
  
  /*if another shape was cloned from us, make it an original*/
  if (self.clonedShape)
    [self makeCloneOriginal];
  
  /*remove shape from any scenes it may be in after and including 'scene'*/
  NSUInteger sceneIndex = [scene.cartoon.scenes indexOfObject:scene];
  for (NSUInteger i = sceneIndex; i < scene.cartoon.scenes.count; i++)
  {
    FLScene*s = scene.cartoon.scenes [i];
    
    /*remove the shape from scene 's' if it's there, also make
     sure that if it was the selected shape, unselect*/
    if ([s.shapes containsObject:self])
    {
      if (s.currentShape == self)
        s.currentShapeIndex = -1; //order matters here
      [s removeShapesObject:self];
    }
  }
}

/*
 move all the strokes and the bb by dx/dy.
 
 it's just plain simpler to move the data each time rather than
 keep around a translation, and for this program, we aren't moving
 a whole lot. so throw cpu at the problem.
 
 */

-(void)moveBy:(CGFloat)dx dy:(CGFloat)dy
{
  self.bbx += dx;
  self.bby += dy;
  
  for (FLStroke*stroke in self.strokes)
    [stroke moveBy:dx dy:dy];
}

-(CGRect)bbRect
{
  return CGRectMake (self.bbx, self.bby, self.bbw, self.bbh);
}
-(CGRect)sloppyBBRect
{
  return CGRectMake (self.bbx - TOUCH_SIZE, self.bby - TOUCH_SIZE, self.bbw + TOUCH_SIZE * 2, self.bbh + TOUCH_SIZE * 2);
}

/*
 recompute the bb. we have to call this any time we
 remove a point. it's inefficient but erasing is happening
 only when the user is touching stuff with his finger, which
 is orders of magnitude slower than the device.
 */
-(void)updateBB
{
  /*
   invalidate bb. we start the dimensions off negative.
   the 1st point that's seen makes the dimensions zero, and
   then after that the dimensions grow by doing differences on
   actual coordinates.
   
   this invalidation should also be the default values in the data model file.
   we could be extra careful and use wakeFromFetch and wakeFromInsert to always
   invalidate bb, but we're going to trust our data model defaults instead.
   this comes up because when we add the very first point to a brand new shape,
   updateBBWithPoint: is called but not updateBB.
   */
  CGRect bb = CGRectMake(0, 0, -1, -1);
  
  for (FLStroke*stroke in self.strokes)
    [stroke updateBB:&bb];
  
  /*copy the new bb out to our own ivars*/
  self.bbx = bb.origin.x;
  self.bby = bb.origin.y;
  self.bbw = bb.size.width;
  self.bbh = bb.size.height;
  
  insist (!self.strokes.count || (self.bbw >= 0 && self.bbh >= 0));
}

/*
 update bb so that it contains point.
 */
-(void)updateBBWithPoint:(CGPoint)point
{
  /*make rect from our bb data*/
  CGRect bb = CGRectMake (self.bbx, self.bby, self.bbw, self.bbh);
  
  /*
   update the rect to contain point, if it had to grow, copy
   back the rect info to our own ivars
   */
  if ([FLStroke updateBB:&bb withPoint:point])
  {
    self.bbx = bb.origin.x;
    self.bby = bb.origin.y;
    self.bbw = bb.size.width;
    self.bbh = bb.size.height;
  }
}

/*
 update the bb so that it contains rect.
 */
-(void)updateBBWithRect:(CGPoint)rect
{
  
}

/*
 draw self to context.
 
 bounds - bounds of view (for transformations if we have to draw text)
 context - graphics context
 */
-(void)drawContext:(CGContextRef) context scene:(FLScene*)scene drawGhosts:(BOOL)drawGhosts type:(FLDrawType)drawType
{
  insist (scene);
  insist (self.originalShape != self);
  
  if (drawGhosts && drawType != FLDrawGhost && self.originalShape && self.originalScene == scene)
  {
    CGContextSaveGState (context);
    CGContextSetLineWidth (context, 1.0);
    [self.originalShape drawContext:context scene:scene drawGhosts:drawGhosts type:FLDrawGhost];
    CGContextRestoreGState (context);
    
  }
  CGContextSaveGState (context);
  CGContextSetAlpha (context, self.alpha);
  
  /*draw nonfilled strokes*/
  for (FLStroke*stroke in self.strokes)
  {
    @autoreleasepool
    {
      [stroke drawContext:context type:drawType];
    }
  }
  
  CGContextRestoreGState (context);
}
@end
