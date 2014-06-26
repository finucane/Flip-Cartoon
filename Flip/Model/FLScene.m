//
//  FLScene.m
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLAppDelegate.h"
#import "FLScene.h"
#import "FLCartoon.h"
#import "FLShape.h"
#import "FLPoint.h"
#import "FLCoreData.h"
#import "geometry.h"
#import "insist.h"

@implementation FLScene

@dynamic currentShapeIndex;
@dynamic cartoon;
@dynamic shapes;
@dynamic originalShapes;

-(void)fault
{
  for (FLManagedObject*o in self.shapes)
  {
    if (![o isFault])
      [o fault];
  }
  
  [self.managedObjectContext refreshObject:self mergeChanges:NO];
}

/*
  fault a scene and just the shapes that are unique to it
*/
-(void)faultUniqueShapes
{
  for (FLShape*shape in self.shapes)
  {
    if ([shape isFault])
      continue;
    
    if (shape.scenes.count == 1)
      [shape fault];
  }
  [self.managedObjectContext refreshObject:self mergeChanges:NO];
}
/*
 search scene for last stroke touched by a point of radius "radius".
 strokes are ordered in scenes by time of creation, and shapes are ordered
 in the scene also by time of creation. in this way we can use this
 method to pick the topmost stroke in a drawing where strokes overlap,
 as long as the drawing goes in the opposite order to the search.
 
 point - point
 radius - radius of point.
 
 returns: path hit by point or nil if none
*/
-(FLStroke*)strokeForPoint:(CGPoint)point radius:(CGFloat)radius
{
  insist (radius > 0);
  
  for (FLShape*shape in [self.shapes reverseObjectEnumerator])
  {
    if (YES || CGRectContainsPoint (shape.sloppyBBRect, point))
    {
      FLStroke*stroke = [shape strokeForPoint:point radius:radius];
      if (stroke)
        return stroke;
    }
  }
  return nil;
}

/*
 same as strokeForPoint:radius:shapeIndex but for a line segment instead of a circle
*/
-(FLStroke*)strokeForLineFrom:(CGPoint)a to:(CGPoint)b
{
  for (FLShape*shape in [self.shapes reverseObjectEnumerator])
  {
    FLStroke*stroke = [shape strokeForLineFrom:a to:b];
    if (stroke)
      return stroke;
  }
  return nil;
}

/*
  return the shape indicated by currentShapeIndex, nil if
  there's no current shape.
*/

-(FLShape*)currentShape
{
  if (self.currentShapeIndex < 0 || self.shapes.count == 0)
    return nil;
  
  insist (self.currentShapeIndex >= 0 && self.currentShapeIndex < self.shapes.count);
  return (self.shapes [self.currentShapeIndex]);
}

/*
  return index of shape in scene.
*/
-(NSUInteger)indexOfShape:(FLShape*)shape
{
  insist ([self.shapes containsObject:shape]);
  return [self.shapes indexOfObject:shape];
}

/*
  clone self and add it after self in its cartoons scene array.
 
  returns: new scene.
 
*/
-(FLScene*)cloneAfterSelf
{
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  insist (self.cartoon);
  
  /*
    make a new scene, either by adding to the end of scenes if self
    is the last scene, or by inserting it after self in the scenes
    order. this monkeying around is because "insert" cannot insert
    past the existing length of the ordered set.
   */
  FLScene*scene;
  int32_t sceneIndex = (int32_t)[self.cartoon indexOfScene:self];
  if (sceneIndex == self.cartoon.scenes.count - 1)
  {
    scene = [coreData newSceneForCartoon:self.cartoon];
    insist (scene);
  }
  else
  {
    scene = [coreData newScene];
    insist (scene);
    [self.cartoon insertScenes:@[scene] atIndexes:[[NSIndexSet alloc] initWithIndex:sceneIndex + 1]];
    insist (scene.cartoon == self.cartoon);
  }
  insist (scene && [self.cartoon.scenes containsObject:scene]);

  /*add references to shapes from self to new scene*/
  for (FLShape*shape in self.shapes)
    [scene addShapesObject:shape];
  
  return scene;
}

@end
