//
//  FLCoreData.h
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLPoint.h"
#import "FLPath.h"
#import "FLText.h"
#import "FLShape.h"
#import "FLScene.h"
#import "FLCartoon.h"
#import "FLState.h"
#import "FLPolygon.h"
#import "FLUndo.h"

extern NSInteger const kFLCoreDataMaxLineThickness;

@interface FLCoreData : NSObject
{
  @private
  NSManagedObjectContext*moc;
  NSManagedObjectModel*mom;
  NSPersistentStoreCoordinator*coordinator;
  NSFetchRequest*cartoonsRequest;
  NSArray*cartoons;
  FLState*state;
  FLUndo*undo;
}

-(id)initWithAppName:(NSString*)appName error:(NSError*__autoreleasing*)error;
-(NSManagedObjectContext*)newMoc;
-(BOOL)saveWithError:(NSError*__autoreleasing*)error;
-(FLPoint*)newPointForPath:(FLPath*)path point:(CGPoint)point;
-(FLPath*)newPathForShape:(FLShape*)shape;
-(FLPolygon*)newPolygonForShape:(FLShape*)shape;
-(FLText*)newTextForShape:(FLShape*)shape;
-(FLShape*)newShape;
-(FLShape*)newShapeForScene:(FLScene*)scene;
-(FLScene*)newSceneForCartoon:(FLCartoon*)cartoon;
-(FLScene*)newScene;
-(FLCartoon*)newCartoonWithError:(NSError*__autoreleasing*)error;
-(BOOL)deleteCartoon:(FLCartoon*)cartoon withError:(NSError*__autoreleasing*)error;
-(void)deleteScene:(FLScene*)scene;
-(NSArray*)cartoons;
-(FLCartoon*)currentCartoon;
-(BOOL)setCurrentCartoon:(FLCartoon*)cartoon withError:(NSError*__autoreleasing*)error;
-(FLState*)state;
-(NSString*)systemFontName;
-(UIFont*)fontForName:(NSString*)fontName size:(CGFloat)size;
-(FLUndo*)undo;

@end
