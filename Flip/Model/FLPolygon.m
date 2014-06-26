//
//  FLPolygon.m
//  Flip
//
//  Created by Finucane on 6/3/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLAppDelegate.h"
#import "FLPolygon.h"
#import "FLPoint.h"
#import "UIColor+Additions.h"
#import "insist.h"

/*
  for cleanness and simplicty polygons only have a few greyscale colors.
  colorInts is the table of those colors (white, light grey, dark grey, black.
*/

static const int32_t colorInts [] = {0xffffffff, 0xC2C2C2ff, 0x7D7D7Dff, 0x000000ff};
#define NUM_COLORS (sizeof (colorInts) / sizeof (*colorInts))

@implementation FLPolygon

@dynamic colorIndex;

-(UIColor*)color
{
  insist (self.colorIndex >= 0 && self.colorIndex < NUM_COLORS);
  return [UIColor colorWithRGBA:colorInts [self.colorIndex]];
}

/*
  increment colorIndex, modulo NUM_COLORS
*/
-(void)incrementColorIndex
{
  insist (NUM_COLORS);
  self.colorIndex = (self.colorIndex + 1) % NUM_COLORS;
}


/*
 make a copy of self and add to shape. even though
 this is mostly doing the same thing that FLPath:cloneToShape
 does (FLPolygon derives from FLPath) we can't just call super
 to do most of the common stuff because this method allocates
 the new object.
 
 returns new stroke
 */
-(FLStroke*)cloneToShape:(FLShape*)shape
{
  insist (shape);
  
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  FLPolygon*newPolygon = [coreData newPolygonForShape:shape];
  insist (newPolygon);
  
  for (FLPoint*point in self.points)
    [coreData newPointForPath:newPolygon point:point.cgPoint];
  
  newPolygon.colorIndex = self.colorIndex;
  return newPolygon;
}

/*
 draw polygon to graphics context

 bounds - bounds of view (for transformations if we have to draw text)
 context - context to draw to
 */
-(void)drawContext:(CGContextRef) context type:(FLDrawType)drawType
{
  insist (self.points.count); //no empty paths
  
  CGContextSaveGState (context);

  CGContextSetFillColorWithColor (context, self.color.CGColor);
  CGContextSetStrokeColorWithColor (context, [self cgColorForType:drawType]);

  CGContextBeginPath (context);
  
  FLPoint*point = self.points [0];
  CGContextMoveToPoint (context, point.x, point.y);
  
  for (int i = 1; i < self.points.count; i++)
  {
    point = self.points [i];
    CGContextAddLineToPoint (context, point.x, point.y);
  }

  if (drawType == FLDrawGhost)
  {
    CGContextDrawPath (context, kCGPathStroke);
  }
  else
  {
    CGContextDrawPath (context, kCGPathFillStroke);
  }
  
  CGContextRestoreGState (context);
}



@end
