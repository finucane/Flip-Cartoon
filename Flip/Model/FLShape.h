//
//  FLShape.h
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FLManagedObject.h"
#import "FLStroke.h"
#import "FLCartoon.h"

@class FLScene, FLCartoon;

@interface FLShape : FLManagedObject

@property (nonatomic) float bbx;
@property (nonatomic) float bby;
@property (nonatomic) float bbh;
@property (nonatomic) float bbw;
@property (nonatomic) float alpha;
@property (nonatomic, retain) NSOrderedSet *strokes;
@property (nonatomic, retain) NSSet *scenes;
@property (nonatomic, retain) FLScene *originalScene;
@property (nonatomic, retain) FLShape *originalShape;
@property (nonatomic, retain) FLShape *clonedShape;
@property (nonatomic, retain) FLCartoon *cartoon;

-(FLStroke*)strokeForPoint:(CGPoint)point radius:(CGFloat)radius;
-(FLStroke*)strokeForLineFrom:(CGPoint)a to:(CGPoint)b;
-(BOOL)isOriginalInScene:(FLScene*)scene;
-(FLShape*)cloneToScene:(FLScene*)scene stroke:(FLStroke*__autoreleasing*)stroke;
-(BOOL)resetOriginalScene;
-(void)makeCloneOriginal;
-(void)removeStartingAtScene:(FLScene*)scene;
-(void)moveBy:(CGFloat)dx dy:(CGFloat)dy;
-(CGRect)bbRect;
-(CGRect)sloppyBBRect;
-(void)updateBB;
-(void)updateBBWithPoint:(CGPoint)point;
-(void)updateBBWithRect:(CGPoint)rect;
-(void)drawContext:(CGContextRef) context scene:(FLScene*)scene drawGhosts:(BOOL)drawGhosts type:(FLDrawType)drawType;

@end

@interface FLShape (CoreDataGeneratedAccessors)

- (void)insertObject:(FLStroke *)value inStrokesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromStrokesAtIndex:(NSUInteger)idx;
- (void)insertStrokes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeStrokesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInStrokesAtIndex:(NSUInteger)idx withObject:(FLScene *)value;
- (void)replaceStrokesAtIndexes:(NSIndexSet *)indexes withStrokes:(NSArray *)values;
- (void)addStrokesObject:(FLStroke *)value;
- (void)removeStrokesObject:(FLStroke *)value;
- (void)addStrokes:(NSOrderedSet *)values;
- (void)removeStrokes:(NSOrderedSet *)values;

- (void)addScenesObject:(FLScene *)value;
- (void)removeScenesObject:(FLScene *)value;
- (void)addScenes:(NSSet *)values;
- (void)removeScenes:(NSSet *)values;


@end
