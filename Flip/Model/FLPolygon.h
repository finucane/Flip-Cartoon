//
//  FLPolygon.h
//  Flip
//
//  Created by Finucane on 6/3/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FLPath.h"


@interface FLPolygon : FLPath

@property (nonatomic) int32_t colorIndex;

-(void)incrementColorIndex;
-(UIColor*)color;
-(void)drawContext:(CGContextRef) context type:(FLDrawType)drawType;
-(FLStroke*)cloneToShape:(FLShape*)shape;

@end
