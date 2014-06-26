//
//  FLStroke.m
//  Flip
//
//  Created by Finucane on 6/8/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "UIColor+Additions.h"
#import "FLStroke.h"
#import "FLPolygon.h"
#import "FLText.h"
#import "insist.h"

/*
 FLStroke is an abstract class representing something that can be added to a shape.
 its subclasses are text, path and polygon (which is a kind of path.)
 
 FLStrokes compute bounding boxes and point/line hits (for implementing selection).
 
 finally FLStroke is a unit of "undo". practically, they are screen graphics that are drawn
 in one continuous gesture.
 */
@implementation FLStroke
@dynamic shape;

static UIColor*normalColor,*selectedColor,*ghostColor;

/*
 colors for strokes to use to draw themselves, depending on FLDrawType
 */
+(UIColor*)normalColor
{
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    normalColor = [UIColor blackColor];
  });
  return normalColor;
}
+(UIColor*)selectedColor
{
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    selectedColor = [UIColor redColor];
  });
  return selectedColor;
}
+(UIColor*)ghostColor
{
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    ghostColor = [UIColor lightGrayColor];
    //ghostColor = [UIColor colorWithRGBA:0xe9e9e9ff];
  });
  return ghostColor;
}

-(UIColor*)colorForType:(FLDrawType)type
{
  switch (type)
  {
    case FLDrawNormal:
      return [FLStroke normalColor];
    case FLDrawSelected:
      return [FLStroke selectedColor];
    case FLDrawGhost:
      return [FLStroke ghostColor];
    default:
      insist (0);
  }
  return nil;
}
-(CGColorRef)cgColorForType:(FLDrawType)type
{
  return [self colorForType:type].CGColor;
}

/*
 grow a bb so it contains point.
 
 point - new point
 
 returns: true if bb changed
 */

+(BOOL)updateBB:(CGRect*)bb withPoint:(CGPoint)point
{
  insist (bb);
  BOOL changed = NO;
  
  if (point.x < bb->origin.x) //grow left
  {
    if (bb->size.width < 0)
      bb->size.width = 0;
    else
      bb->size.width += (bb->origin.x - point.x);
    bb->origin.x = point.x;
    changed = YES;
  }
  else if (point.x > bb->origin.x + bb->size.width) //grow right
  {
    if (bb->size.width < 0)
    {
      bb->size.width = 0;
      bb->origin.x = point.x;
    }
    else
      bb->size.width += (point.x - (bb->origin.x + bb->size.width));
    changed = YES;
  }
  if (point.y < bb->origin.y) //grow down
  {
    if (bb->size.height < 0)
      bb->size.height = 0;
    else
      bb->size.height += (bb->origin.y - point.y);
    bb->origin.y = point.y;
    changed = YES;
  }
  else if (point.y > bb->origin.y + bb->size.height) //grow up
  {
    if (bb->size.height < 0)
    {
      bb->origin.y = point.y;
      bb->size.height = 0;
    }
    else
      bb->size.height += (point.y - (bb->origin.y + bb->size.height));
    changed = YES;
  }
  return changed;
}

+(BOOL)updateBB:(CGRect*)bb withRect:(CGRect)rect
{
  BOOL changed = NO;
  
  if ([FLStroke updateBB:bb withPoint:CGPointMake (rect.origin.x, rect.origin.y)])
    changed = YES;
  if ([FLStroke updateBB:bb withPoint:CGPointMake (rect.origin.x, rect.origin.y + rect.size.height)])
    changed = YES;
  if ([FLStroke updateBB:bb withPoint:CGPointMake (rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)])
    changed = YES;
  if ([FLStroke updateBB:bb withPoint:CGPointMake (rect.origin.x + rect.size.width, rect.origin.y)])
    changed = YES;
  
  return changed;
}

/*
 return true if point of radius radius hits self.
 
 subclasses should override
 */
-(BOOL)hitsPoint:(CGPoint)point radius:(CGFloat)radius
{
  insist (0);
  return NO;
}

/*
 return true if line segment interesects self.
 
 subclasses should override
 */
-(BOOL)hitsLine:(CGPoint)a to:(CGPoint)b
{
  insist (0);
  return NO;
}

/*
 move stroke by dx, dy
 
 subclasses should overried
 */
-(void)moveBy:(CGFloat)dx dy:(CGFloat)dy
{
  insist (0);
}
/*
 update bb to contain self.
 
 subclasses should override.
 */
-(BOOL)updateBB:(CGRect*)bb
{
  insist (0);
  return NO;
}

/*
 create a copy of self belonging to shape
 
 subclasses should override
 */

-(FLStroke*)cloneToShape:(FLShape*)shape
{
  insist (0);
  return nil;
}

/*
 return the largest "y" coordinate of the path
 
 subclasses should override
 */
-(CGPoint)largestYPoint
{
  insist (0);
  return CGPointMake (0, 0);
}
/*
 draw self to context
 
 context - context to draw to
 scale - scale (not used)
 
 subclasses should override
 */

-(void)drawContext:(CGContextRef) context type:(FLDrawType)drawType
{
  insist (0);
}
/*
 some ghetto introsepection methods,
 used as an expediency in our top level
 drawing code.
 */

-(BOOL)isPolygon
{
  return [self isKindOfClass:[FLPolygon class]];
}
-(BOOL)isText
{
  return [self isKindOfClass:[FLText class]];
}

@end
