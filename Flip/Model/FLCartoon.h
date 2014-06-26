//
//  FLCartoon.h
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FLManagedObject.h"
#import "FLShape.h"

@class FLScene, FLShape;

@interface FLCartoon : FLManagedObject

/*we use indexes instead of object references to avoid many-to-many relationships.*/
@property (nonatomic) int32_t currentSceneIndex;
@property (nonatomic) int32_t index;
@property (nonatomic) int32_t framesPerSecond;
@property (nonatomic) int32_t lineThickness;

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSOrderedSet *scenes;
@property (nonatomic, retain) NSSet *shapes;
@property (nonatomic, retain) NSString * fontName;

-(FLScene*)currentScene;
-(NSUInteger)indexOfScene:(FLScene*)scene;
-(void)setCurrentScene:(int32_t)index faulting:(BOOL)fault;
-(void)cullShapes;
-(void)recomputeFontSizes;
-(void)addTestScenes1;
-(void)addTestScenes2;
-(void)addTestScenes3;
-(void)addTestScenes4;
-(void)drawScene:(uint32_t)sceneIndex context:(CGContextRef)context width:(uint32_t)width height:(uint32_t)height;
@end

@interface FLCartoon (CoreDataGeneratedAccessors)

- (void)insertObject:(FLScene *)value inScenesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromScenesAtIndex:(NSUInteger)idx;
- (void)insertScenes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeScenesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInScenesAtIndex:(NSUInteger)idx withObject:(FLScene *)value;
- (void)replaceScenesAtIndexes:(NSIndexSet *)indexes withScenes:(NSArray *)values;
- (void)addScenesObject:(FLScene *)value;
- (void)removeScenesObject:(FLScene *)value;
- (void)addScenes:(NSOrderedSet *)values;
- (void)removeScenes:(NSOrderedSet *)values;

- (void)addShapesObject:(FLShape *)value;
- (void)removeShapesObject:(FLShape *)value;
- (void)addShapes:(NSSet *)values;
- (void)removeShapes:(NSSet *)values;

@end
