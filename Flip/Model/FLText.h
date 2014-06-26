//
//  FLText.h
//  Flip
//
//  Created by Finucane on 6/8/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FLStroke.h"


@interface FLText : FLStroke

@property (nonatomic, retain) NSString * text;
@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float width;
@property (nonatomic) float height;
@property (nonatomic) float fontSize; //computed internally
@property (nonatomic) float outlineX, outlineY, outlineHeight, outlineWidth;

-(CGRect)outline;
-(void)setOutline:(CGRect)rect;

-(void)setWithPoint:(CGPoint)a b:(CGPoint)b;
-(BOOL)hitsPoint:(CGPoint)point radius:(CGFloat)radius;
-(BOOL)hitsLine:(CGPoint)a to:(CGPoint)b;
-(BOOL)lowerRightHitsPoint:(CGPoint)point radius:(CGFloat)radius;
-(void)moveBy:(CGFloat)dx dy:(CGFloat)dy;
-(BOOL)updateBB:(CGRect*)bb;
-(FLStroke*)cloneToShape:(FLShape*)shape;
-(CGPoint)largestYPoint;
-(void)recomputeFontSize;
-(void)drawContext:(CGContextRef) context type:(FLDrawType)drawType;
@end
