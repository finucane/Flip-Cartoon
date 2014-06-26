//
//  FLPath.m
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLAppDelegate.h"
#import "FLPath.h"
#import "FLPoint.h"
#import "FLShape.h"
#import "FLPolygon.h"
#import "geometry.h"
#import "insist.h"

@implementation FLPath

@dynamic points;

-(void)fault
{
  for (FLManagedObject*o in self.points)
  {
    if (![o isFault])
      [o fault];
  }
  [self.managedObjectContext refreshObject:self mergeChanges:NO];
}

/*
 draw path to graphics context
 
 bounds - bounds of view (for transformations if we have to draw text)
 context - context to draw to
 scale - scale
*/
-(void)drawContext:(CGContextRef) context type:(FLDrawType)drawType
{
  insist (self.points.count); //no empty paths
  
  CGContextSaveGState(context);
  
  CGContextBeginPath (context);
  
  FLPoint*point = self.points [0];
  CGContextMoveToPoint (context, point.x, point.y);
  
  for (int i = 1; i < self.points.count; i++)
  {
    point = self.points [i];
    CGContextAddLineToPoint (context, point.x, point.y);
  }

  CGContextSetStrokeColorWithColor (context, [self cgColorForType:drawType]);
  CGContextStrokePath(context);//closes path
  CGContextRestoreGState(context);
}

/*
 return the largest "y" coordinate of the path
 */
-(CGPoint)largestYPoint
{
  insist (self.points.count);
  CGPoint p = CGPointMake (0, -1e6);
  
  for (FLPoint*point in self.points)
  {
    if (point.y > p.y)
      p = point.cgPoint;
  }
  return p;
}

/*
 return YES if a circle intersects self.
 
 point - center of circle
 radius - radius of circle
 
 returns: stroke if hit, nil otherwise
 */

-(BOOL)hitsPoint:(CGPoint)point radius:(CGFloat)radius
{
  for (unsigned i = 0; i < self.points.count - 1; i++)
  {
    FLPoint*a = self.points [i];
    FLPoint*b = self.points [i+1];
  
    if (g_line_and_circle_intersect (a.cgPoint, b.cgPoint, point, radius))
      return YES;
  }
  return NO;
}

/*
 return true if a line segment intersects a stroke.
 
 a - start of line segment
 b - end of line segment
 
 returns: stroke if hit, nil otherwise
*/

-(BOOL)hitsLine:(CGPoint)a to:(CGPoint)b
{
  for (unsigned i = 0; i < self.points.count - 1; i++)
  {
    CGPoint pa = [self.points [i] cgPoint];
    CGPoint pb = [self.points [i+1] cgPoint];
    
    if (g_lines_intersect(pa, pb, a, b))
      return YES;
  }
  return NO;
}

/*
  move self by dx, dy
 
  dx - amount in x direction to move
  dy - amount in y direction to move
*/
-(void)moveBy:(CGFloat)dx dy:(CGFloat)dy
{
  for (FLPoint*point in self.points)
  {
    point.x += dx;
    point.y += dy;
  }
}
/*
  update the bb so that it contains self
 
  return YES if the bb changed.
*/
-(BOOL)updateBB:(CGRect*)bb
{
  BOOL changed = NO;
  for (FLPoint*point in self.points)
  {
    if ([FLStroke updateBB:bb withPoint:point.cgPoint])
      changed = YES;
  }
  return changed;
}

/*
  make a copy of self and add to shape
 
  returns new stroke
*/
-(FLStroke*)cloneToShape:(FLShape*)shape
{
  insist (shape);

  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  FLPath*newPath = [coreData newPathForShape:shape];
  insist (newPath);
  
  for (FLPoint*point in self.points)
    [coreData newPointForPath:newPath point:point.cgPoint];
  
  return newPath;
}

@end
