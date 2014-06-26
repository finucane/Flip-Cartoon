//
//  FLCartoon.m
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLAppDelegate.h"
#import "FLCartoon.h"
#import "FLScene.h"
#import "FLText.h"
#import "insist.h"

@implementation FLCartoon

@dynamic currentSceneIndex, fontName;
@dynamic index, title, scenes, framesPerSecond, lineThickness;
@dynamic shapes;

/*
  cull shapes that aren't in any scenes, or that have no strokes
  a better idea would probably have been to just never keep dead
  shapes around. but the motivation for this was to be able to
  undo shape deletion. and as long as we make sure we call this
  before attempting to save core data, it's maybe not so horrible.
*/
-(void)cullShapes
{
  NSMutableArray*deadShapes = [[NSMutableArray alloc] init];
  for (FLShape*shape in self.shapes)
  {
    /*don't drag in shapes from persistent store to look at them*/
    if ([shape isFault])
      continue;
    
    if (shape.scenes.count == 0 || shape.strokes.count == 0)
    {
      [deadShapes addObject:shape];
    }
  }
  
  for (FLShape*shape in deadShapes)
  {
    NSArray*scenes = [shape.scenes allObjects];
    for (FLScene*scene in scenes)
      [scene removeShapesObject:shape];
    
    [self removeShapesObject:shape];
    [self.managedObjectContext deleteObject:shape];
  }
}

-(void)fault
{
  [self cullShapes];
  
  for (FLManagedObject*o in self.scenes)
  {
    if (![o isFault])
      [o fault];
  }
  
  [self.managedObjectContext refreshObject:self mergeChanges:NO];
}

/*
 return current scene.
 */
-(FLScene*)currentScene
{
  insist (self.scenes.count);
  insist (self.currentSceneIndex >= 0 && self.currentSceneIndex < self.scenes.count);
  return self.scenes [self.currentSceneIndex];
}

/*
 return index of scene in cartoon
 */
-(NSUInteger)indexOfScene:(FLScene*)scene
{
  insist ([self.scenes containsObject:scene]);
  return [self.scenes indexOfObject:scene];
}

/*
 change the current scene, optionally faulting the previous one, if any

 index - new currentScene index
 fault - true if the previous scene should be faulted
*/
-(void)setCurrentScene:(int32_t)index faulting:(BOOL)fault
{
  NSError*error;
  
  FLScene*previousScene = self.currentScene;
  self.currentSceneIndex = index;

  if (fault && previousScene != self.currentScene)
  {
    [App.coreData saveWithError:&error];
    [previousScene faultUniqueShapes];
  }
}

/*
 recompute font sizes for all texts. this is called
 when the cartoon's font size changes.
 */

-(void)recomputeFontSizes
{
  for (FLShape*shape in self.shapes)
  {
    for (FLStroke*stroke in shape.strokes)
    {
      if (stroke.isText)
        [(FLText*)stroke recomputeFontSize];
    }
  }
}

/*
 add lots of scenes each containing lots of shapes to cartoon.
 this is to stress the app as part of testing.
 */

#define MAX_COORDINATE 500
#define MAX_STRING 60
#define RAND_COORDINATE() ((float)arc4random_uniform (MAX_COORDINATE))
#define RAND_POINT CGPointMake (RAND_COORDINATE (),RAND_COORDINATE ())

-(NSString*)randString
{
  int len = arc4random_uniform (MAX_STRING) + 1;
  NSMutableString*s = [NSMutableString stringWithCapacity:len];
  insist (s);
  
  for (int i = 0; i < len; i++)
    [s appendFormat:@"%C", (unichar) ('A' + arc4random_uniform ('z'-'A'))];
  return s;
}

-(void)addTestScenes1
{
  [self addTestNumScenes:100 numShapes:10 numStrokes:30 numPoints:120];
}
-(void)addTestScenes2
{
  [self addTestNumScenes:1001 numShapes:1 numStrokes:1 numPoints:2];
}
-(void)addTestScenes3
{
  [self addTestNumScenes:3 numShapes:100 numStrokes:30 numPoints:120];
}

-(void)addTestScenes4
{
  [self addTestNumScenes:3 numShapes:100 numStrokes:30 numPoints:120];
  
  for (int i = 0; i < 100; i++)
    [(FLScene*)[self.scenes lastObject] cloneAfterSelf];
}

-(void)addTestNumScenes:(int)numScenes numShapes:(int)numShapes numStrokes:(int)numStrokes numPoints:(int)numPoints
{
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  NSError*error;
  
  /*turn undo off to avoid crazy memory usage*/
  coreData.undo.enabled = NO;
  
  for (int i = 0; i < numScenes; i++)
  {
    @autoreleasepool
    {
      FLScene*scene = [coreData newSceneForCartoon:self];
      insist (scene);
      
      for (int j = 0; j < numShapes; j++)
      {
        FLShape*shape = [coreData newShapeForScene:scene];
        insist (shape);
        
        @autoreleasepool
        {
          for (int k = 0; k < numStrokes; k++)
          {
            
            FLPath*path = [coreData newPathForShape:shape];
            insist (path);
            
            for (int m = 0; m < numPoints; m++)
            {
              [coreData newPointForPath:path point:RAND_POINT];
            }
          }
          
          for (int k = 0; k < numStrokes; k++)
          {
            
            FLPath*path = [coreData newPolygonForShape:shape];
            insist (path);
            
            for (int m = 0; m < numPoints; m++)
            {
              [coreData newPointForPath:path point:RAND_POINT];
            }
          }
          for (int k = 0; k < numStrokes; k++)
          {
            FLText*text = [coreData newTextForShape:shape];
            insist (text);
            
            [text setWithPoint:RAND_POINT b:RAND_POINT];
            text.text = [self randString];
            [text recomputeFontSize];
            
          }
        }
        
        [coreData saveWithError:&error];
        [shape fault];
      }
      [coreData saveWithError:&error];
      [scene fault];
    }
  }
  coreData.undo.enabled = YES;
}

/*
 draw current scene of cartoon into context. this is used for rendering to video
 
 scene - scene index to draw
 context - a graphics context
 width - width of frame
 height - height of frame
 
 returns nothing
 */

-(void)drawScene:(uint32_t)sceneIndex context:(CGContextRef)context width:(uint32_t)width height:(uint32_t)height
{
  insist (context);
  insist (sceneIndex < self.scenes.count);
  
  FLScene*scene = self.scenes [sceneIndex];
  insist (scene);
  
  /*paint context white*/
  CGContextSetFillColorWithColor (context, [UIColor whiteColor].CGColor);
  CGContextFillRect (context, CGRectMake(0, 0, width, height));
  
  CGContextSetAllowsAntialiasing (context, YES);
  CGContextSetShouldAntialias (context, YES);
  
  CGContextSetLineWidth (context, self.lineThickness);
  
  for (FLShape*shape in scene.shapes)
  {
    @autoreleasepool
    {
      [shape drawContext:context scene:scene drawGhosts:NO type:FLDrawNormal];
    }
  }
  
}

@end
