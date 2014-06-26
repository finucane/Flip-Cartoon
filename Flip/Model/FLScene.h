//
//  FLScene.h
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FLManagedObject.h"
#import "FLPath.h"

@class FLCartoon, FLShape;

@interface FLScene : FLManagedObject

/*
  we use an index instead of an object reference here, to avoid a many-to-many relationship.
  this might be dumb because because it's confusing and error-prone.
*/

@property (nonatomic) int32_t currentShapeIndex; //< 0 means no current shape
@property (nonatomic, retain) FLCartoon *cartoon;
@property (nonatomic, retain) NSOrderedSet *shapes;
@property (nonatomic, retain) NSSet *originalShapes;

-(FLStroke*)strokeForPoint:(CGPoint)point radius:(CGFloat)radius;
-(FLStroke*)strokeForLineFrom:(CGPoint)a to:(CGPoint)b;
-(FLShape*)currentShape;
-(NSUInteger)indexOfShape:(FLShape*)shape;
-(FLScene*)cloneAfterSelf;
-(void)faultUniqueShapes;

@end


@interface FLScene (CoreDataGeneratedAccessors)

- (void)insertObject:(FLShape *)value inShapesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromShapesAtIndex:(NSUInteger)idx;
- (void)insertShapes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeShapesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInShapesAtIndex:(NSUInteger)idx withObject:(FLShape *)value;
- (void)replaceShapesAtIndexes:(NSIndexSet *)indexes withShapes:(NSArray *)values;
- (void)addShapesObject:(FLShape *)value;
- (void)removeShapesObject:(FLShape *)value;
- (void)addShapes:(NSOrderedSet *)values;
- (void)removeShapes:(NSOrderedSet *)values;
- (void)addOriginalShapesObject:(FLShape *)value;
- (void)removeOriginalShapesObject:(FLShape *)value;
- (void)addOriginalShapes:(NSSet *)values;
- (void)removeOriginalShapes:(NSSet *)values;
@end
