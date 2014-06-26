//
//  FLStroke.h
//  Flip
//
//  Created by Finucane on 6/8/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FLManagedObject.h"

@class FLShape;


typedef enum FLDrawType : NSUInteger
{
  FLDrawNormal,
  FLDrawSelected,
  FLDrawGhost
}FLDrawType;


@interface FLStroke : FLManagedObject

@property (nonatomic, retain) FLShape *shape;

+(UIColor*)normalColor;
+(UIColor*)selectedColor;
+(UIColor*)ghostColor;
-(UIColor*)colorForType:(FLDrawType)type;
-(CGColorRef)cgColorForType:(FLDrawType)type;

-(BOOL)hitsPoint:(CGPoint)point radius:(CGFloat)radius;
-(BOOL)hitsLine:(CGPoint)a to:(CGPoint)b;
+(BOOL)updateBB:(CGRect*)bb withPoint:(CGPoint)point;
+(BOOL)updateBB:(CGRect*)bb withRect:(CGRect)rect;
-(BOOL)updateBB:(CGRect*)bb;
-(void)moveBy:(CGFloat)dx dy:(CGFloat)dy;
-(FLStroke*)cloneToShape:(FLShape*)shape;
-(CGPoint)largestYPoint;
-(void)drawContext:(CGContextRef) context type:(FLDrawType)drawType;
-(BOOL)isPolygon;
-(BOOL)isText;

@end
