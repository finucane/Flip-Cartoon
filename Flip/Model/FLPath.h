//
//  FLPath.h
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FLManagedObject.h"
#import "FLStroke.h"

@class FLPoint, FLShape;

@interface FLPath : FLStroke

@property (nonatomic, retain) NSOrderedSet *points;
-(void)drawContext:(CGContextRef) context type:(FLDrawType)drawType;
-(CGPoint)largestYPoint;
-(BOOL)hitsPoint:(CGPoint)point radius:(CGFloat)radius;
-(BOOL)hitsLine:(CGPoint)a to:(CGPoint)b;
-(BOOL)updateBB:(CGRect*)bb;
-(FLStroke*)cloneToShape:(FLShape*)shape;
@end

@interface FLPath (CoreDataGeneratedAccessors)

- (void)insertObject:(FLPoint *)value inPointsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPointsAtIndex:(NSUInteger)idx;
- (void)insertPoints:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePointsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPointsAtIndex:(NSUInteger)idx withObject:(FLPoint *)value;
- (void)replacePointsAtIndexes:(NSIndexSet *)indexes withPoints:(NSArray *)values;
- (void)addPointsObject:(FLPoint *)value;
- (void)removePointsObject:(FLPoint *)value;
- (void)addPoints:(NSOrderedSet *)values;
- (void)removePoints:(NSOrderedSet *)values;
@end
