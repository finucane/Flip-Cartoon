//
//  FLCoreData.m
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLAppDelegate.h"
#import "FLCoreData.h"
#import "UIAlertView+Additions.h"
#import "insist.h"
#import "NSManagedObjectModel+KCOrderedAccessorFix.h"

NSInteger const kFLCoreDataMaxLineThickness = 10; //only enforced in the ui

static NSString*const STATE_ENTITY_NAME = @"State";
static NSString*const POINT_ENTITY_NAME = @"Point";
static NSString*const PATH_ENTITY_NAME = @"Path";
static NSString*const POLYGON_ENTITY_NAME = @"Polygon";
static NSString*const TEXT_ENTITY_NAME = @"Text";
static NSString*const SHAPE_ENTITY_NAME = @"Shape";
static NSString*const SCENE_ENTITY_NAME = @"Scene";
static NSString*const CARTOON_ENTITY_NAME = @"Cartoon";
static NSString*const CARTOON_INDEX_NAME = @"index";
static NSString*const SYSTEM_FONT_NAME = @"iOS Default"; //this name will appear in the ui


@implementation FLCoreData

/*
 Set up core data.
 
 appName - the name of the app, used to form the .xcdatamodeld and .sqlite filenames. i.e. "Flip".
 error - set to an error if there something bad happened
 
 returns nil on error, in which case error is set.
 */

-(id)initWithAppName:(NSString*)appName error:(NSError*__autoreleasing*)error
{
  insist (appName && error);
  *error = nil;
  
  if ((self = [super init]))
  {
    /*create managed object model with contents of *.momd, making new *.momd file if it doesn't exist*/
    NSURL*modelURL = [[NSBundle mainBundle] URLForResource:appName withExtension:@"momd"];
    mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    insist (mom);
    
    /*fix core data bug*/
    [mom kc_generateOrderedSetAccessors];
    
    /*create persistent store coordinator*/
    coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    /*add sqlite database to coordinator*/
    NSURL*documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL*storeURL = [documentsURL URLByAppendingPathComponent:[NSString stringWithFormat: @"%@%@", appName, @".sqlite"]];
    
    /*
     if we can't add the persistent store it generally means the data model has been changed making it
     incompatible with the underlying db. this should never happen in real life, but it happens
     all the time in development, so deal with it. the simplest fix is to just remove the underlying database.
     */
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:error])
    {
      /*alert the user*/
      [UIAlertView showAlertWithTitle:NSLocalizedString (@"Persistent Store Error", nil)
                              message:NSLocalizedString (@"Couldn't load saved data. Probably because the data model has changed. Saved data will be deleted.", nil)];
      
      /*throw away all the user's data*/
      [[NSFileManager defaultManager]removeItemAtURL:storeURL error:nil];
      
      /*try again. no way to recover from this now*/
      if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:error])
        return nil;
    }
    
    /*create the managed object context. make sure it uses our own undoManager*/
    moc = [[NSManagedObjectContext alloc] init];
    insist (moc);
    
    [moc setPersistentStoreCoordinator:coordinator];
    
    /*fetch the state entity, if it exists, otherwise create one.*/
    NSFetchRequest*request = [[NSFetchRequest alloc] init];
    insist (request);
    request.entity = [NSEntityDescription entityForName:STATE_ENTITY_NAME inManagedObjectContext:moc];
    NSArray*entities = [moc executeFetchRequest:request error:error];
    if (!entities)
      return nil;
    
    if (entities.count)
    {
      insist (entities.count == 1);
      state = entities [0];
    }
    else
    {
      state = [NSEntityDescription insertNewObjectForEntityForName:STATE_ENTITY_NAME inManagedObjectContext:moc];
      insist (state);
    }
    
    /*set up the top level fetch request, which gets us a list of all cartoons, sorted by index*/
    cartoonsRequest = [[NSFetchRequest alloc] init];
    insist (cartoonsRequest);
    cartoonsRequest.entity = [NSEntityDescription entityForName:CARTOON_ENTITY_NAME inManagedObjectContext:moc];
    [cartoonsRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:CARTOON_INDEX_NAME ascending:YES]]];
    
    /*
     get initial list of cartoons. at the very least we care about the length of this list,
     so that when we make new cartoon, we can set its index number correctly. but the main
     memory management in this app is to have a list of cartoons, all of which are faulted
     except the current cartoon.
     */
    if (![self refreshCartoonsWithError:error])
      return nil;
    
    insist (cartoons && cartoons.count > 0);
    
    /*finally, set up undo*/
    undo = [[FLUndo alloc] initWithMoc:moc];
    insist (undo);
    
    return self;
  }
  return nil;
}

/*
 create a new moc, suitable for as a temporary scratchpad.
 
 the returned moc does not have an undo manager attached to it so we don't
 have to worry about memory usage if, for instance, we're using it to render a
 video.

 in trying to make these mocs not memory hogs when stressed it's basically
 impossible. even if you clear all of the changes made to them, either by faulting
 all of their objects or throwing them all away with reset: they do not free memory you actually destroy them. even if you turn caching off with setStalenessInterval:
 
 the postive side is it's not expensive to create mocs.
 
*/
-(NSManagedObjectContext*)newMoc
{
  /*create the managed object context*/
  NSManagedObjectContext*m = [[NSManagedObjectContext alloc] init];
  insist (m);
  [m setPersistentStoreCoordinator:coordinator];
  insist (!m.undoManager);
  return m;
}

/*
 save changes made in context to persistent store.
 
 error - set to the error, if there is one.
 
 returns NO on error.
 */

-(BOOL)saveWithError:(NSError*__autoreleasing*)error
{
  [self.currentCartoon cullShapes];
  insist (moc);
  insist (error);
  
  if (![moc save:error])
  {
    NSLog (@"error is %@", *error);
    return NO;
  }
  return YES;
}

/*
 make sure the cartoons array is up to date. this includes making sure
 that there is always at least one cartoon (an empty one is created if
 necessary.) this method is called internally when the app starts up
 and whenever we add or delete a caroon.
 
 this method also faults all cartoons by releasing them all and fetching them
 again. (this is overkill but harmless.)
 
 error - set if there's an error
 
 returns NO if error.
 */
-(BOOL)refreshCartoonsWithError:(NSError*__autoreleasing*)error
{
  insist (error);
  
  /*update cartoons list*/
  if (![self saveWithError:error])
    return NO;
  
  if (!(cartoons = [moc executeFetchRequest:cartoonsRequest error:error]))
    return NO;
  
  /*if there are no cartoons, make one.*/
  if (cartoons.count == 0)
  {
    FLCartoon*cartoon = [self newCartoonWithError:error];
    if (!cartoon)
      return NO;
    
    insist (cartoons.count == 1 && cartoons [0] == cartoon);
  }
  
  /*make sure we have a currentCartoon*/
  if (!state.currentCartoon)
    state.currentCartoon = cartoons [0];
  
  return YES;
}

/*
 add a new point to the moc, add it to path, update path's shape's bb.
 if the point is the same as the previous last point in the path then
 no new point is created. there's never any reason to allow 2 identical
 points in a row.
 
 path - path to new add point to
 point - point
 
 returns: new point, or nil if none was created.
 */
-(FLPoint*)newPointForPath:(FLPath*)path point:(CGPoint)cgPoint
{
  insist (path);
  insist (path.shape);
  
  /*disallow same points in a row*/
  FLPoint*lastPoint = [path.points lastObject];
  
  if (lastPoint && lastPoint.x == cgPoint.x && lastPoint.y == cgPoint.y)
    return nil;
  
  FLPoint*point = [NSEntityDescription insertNewObjectForEntityForName:POINT_ENTITY_NAME inManagedObjectContext:moc];
  insist (point);
  point.x = cgPoint.x;
  point.y = cgPoint.y;
  [path addPointsObject:point];
  [path.shape updateBBWithPoint:cgPoint];
  return point;
}

-(FLPath*)newPathForShape:(FLShape*)shape
{
  insist (shape);
  FLPath*path = [NSEntityDescription insertNewObjectForEntityForName:PATH_ENTITY_NAME inManagedObjectContext:moc];
  insist (path);
  
  [shape addStrokesObject:path];
  return path;
}
-(FLPolygon*)newPolygonForShape:(FLShape*)shape
{
  insist (shape);
  FLPolygon*polygon = [NSEntityDescription insertNewObjectForEntityForName:POLYGON_ENTITY_NAME inManagedObjectContext:moc];
  insist (polygon);
  
  [shape addStrokesObject:polygon];
  return polygon;
}

-(FLText*)newTextForShape:(FLShape*)shape
{
  insist (shape);
  FLText*text = [NSEntityDescription insertNewObjectForEntityForName:TEXT_ENTITY_NAME inManagedObjectContext:moc];
  insist (text);
  text.text = @""; //can't set default empty string in xcode
  [shape addStrokesObject:text];
  return text;
}

/*
 add a new shape to the moc, but don't connect it to anything.
 
 returns: new shape.
 */
-(FLShape*)newShape
{
  return [NSEntityDescription insertNewObjectForEntityForName:SHAPE_ENTITY_NAME inManagedObjectContext:moc];
}


/*
 add a new shape to the moc, set up its relations to scene, which becomes its originalScene. the
 shape also gets added scene's cartoon's list of shapes, which is the list that has the cascade
 delete rule for shapes. that way when we actually remove a cartoon from the moc, all its shapes
 are removed too.
 
 scene - scene to new add shape to
 
 returns: new shape.
 */
-(FLShape*)newShapeForScene:(FLScene*)scene
{
  insist (scene && scene.cartoon);
  
  FLShape*shape = [self newShape];
  insist (shape);
  [shape addScenesObject:scene];
  shape.originalScene = scene;
  shape.cartoon = scene.cartoon;
  
  return shape;
}


/*
 make a new scene and add it to the end of cartoon's scene list.
 in practice this is probably going to only be used to make the first
 scene in a cartoon, since all other scenes are created by cloning
 from an existing one.
 
 cartoon - cartoon to add scene to
 returns: new scene, with its relations set up etc.
 
 */
-(FLScene*)newSceneForCartoon:(FLCartoon*)cartoon
{
  insist (cartoon);
  FLScene*scene = [self newScene];
  insist (scene);
  [cartoon addScenesObject:scene];
  return scene;
}

/*
 create a new scene, not attached to anything
 */
-(FLScene*)newScene
{
  FLScene*scene = [NSEntityDescription insertNewObjectForEntityForName:SCENE_ENTITY_NAME inManagedObjectContext:moc];
  insist (scene);
  return scene;
}

/*
 add a new cartoon to the moc, set its index, and refresh the cartoons list by saving the context and fetching
 the array again.
 
 error - set if there's an error saving the moc
 
 returns the new cartoon.
 */

-(FLCartoon*)newCartoonWithError:(NSError*__autoreleasing*)error
{
  insist (moc && cartoons);
  insist (error);
  
  FLCartoon*cartoon = [NSEntityDescription insertNewObjectForEntityForName:CARTOON_ENTITY_NAME inManagedObjectContext:moc];
  insist (cartoon);
  cartoon.index = (int32_t)cartoons.count;
  
  /*cartoons must have at least one scene*/
  FLScene*scene = [self newSceneForCartoon:cartoon];
  insist (scene);
  insist (cartoon.scenes.count);
  cartoon.currentSceneIndex = 0;
  
  /*set a default fontName*/
  cartoon.fontName = [self systemFontName];
  
  /*set a localized default title. it's not straightforward how to do this in the core data model file*/
  cartoon.title = NSLocalizedString (@"Untitled" , nil);
  
  /*update cartoons list, only do this after all of cartoons attributes are set*/
  if (![self refreshCartoonsWithError:error])
    return nil;
  
  insist (cartoon == [cartoons lastObject]);
  return cartoon;
}

/*
 delete a cartoon. remove it from core data entirely. the delete rules have been set up so that this
 deletes all of the cartoons data.
 
 error - set if there's an error
 
 returns NO if there was an error.
 
 */
-(BOOL)deleteCartoon:(FLCartoon*)cartoon withError:(NSError*__autoreleasing*)error
{
  insist (cartoons && cartoon);
  insist (moc);
  
  NSUInteger index = [cartoons indexOfObject:cartoon];
  insist (index >= 0 && index < cartoons.count);
  
  /*correct the indexes for all the cartoons after the one we are removing*/
  for (;index < cartoons.count; index++)
  {
    FLCartoon*c = cartoons [index];
    c.index--; //post increment works on properties
  }
  
  /*if we're deleting the state.currentCartoon...*/
  if (cartoon == state.currentCartoon)
  {
    state.currentCartoon = nil;
  }
  [moc deleteObject:cartoon];
  
  /*
   update cartoons list. this will make sure the deletion is saved, and also it will
   make sure we have an empty default cartoon if we deleted the last existing one.
   */
  return [self refreshCartoonsWithError:error];
}

/*
 delete scene from its cartoon. if this leaves the cartoon empty, create new empty scene.
 make currentScene index consistent.
 
 a scene's shapes are owned by the cartoon itself, and scene's delete rules just nullify
 its relationships.
 
 */
-(void)deleteScene:(FLScene*)scene
{
  FLCartoon*cartoon = scene.cartoon;
  insist (cartoon);
  
  NSUInteger index = [cartoon indexOfScene:scene];
  insist (index >= 0 && index < cartoon.scenes.count);
  
  /*
    make sure scene's shapes don't have any clones. also make
    sure that all shapes that occur in other scenes have a valid
    originalScene.
   */
  for (NSUInteger i = 0; i < scene.shapes.count; i++)
  {
    FLShape*shape = scene.shapes [i];
    if (shape.clonedShape)
      [shape makeCloneOriginal];
    
    if (shape.originalScene == scene)
      [shape resetOriginalScene];
  }
  /*
    remove scene reference and delete it. the shapes that were in scene
    are all removed from scene's shapes array by core data.
   */
  [cartoon removeScenesObject:scene];
  [moc deleteObject:scene];
  
  /*make sure there's always a scene, and also make sure currentScene index is valid.*/
  if (!cartoon.scenes.count)
  {
    [self newSceneForCartoon:cartoon];
    cartoon.currentSceneIndex = 0;
  }
  else if (cartoon.currentSceneIndex >= index)
    cartoon.currentSceneIndex--;
  
  if (cartoon.currentSceneIndex < 0)
    cartoon.currentSceneIndex = 0;
}


-(NSArray*)cartoons
{
  insist (cartoons);
  return cartoons;
}
/*
 The way we limit memory usage is to basically only hold 1 cartoon at a time in RAM.
 state.currentCartoon is that cartoon. it can be nil.
 */

-(FLCartoon*)currentCartoon
{
  return state.currentCartoon;
}

/*
 set current cartoon. this will fault the previous cartoon if any
 
 cartoon - cartoon to set as the current one
 error - set if error
 
 returns false if error
 */

-(BOOL)setCurrentCartoon:(FLCartoon*)cartoon withError:(NSError*__autoreleasing*)error
{
  insist (cartoon && error);
  
  /*if we aren't really changing the current cartoon do nothing*/
  if (state.currentCartoon == cartoon)
    return YES;
  
  /*if there was a previous state.currentCartoon, fault it*/
  if (state.currentCartoon)
  {
    /*we're going to fault the old cartoon to save memory so first save*/
    if (![self saveWithError:error])
      return NO;
    
    /*fault previous state.currentCartoon*/
    [state.currentCartoon fault];
    [moc refreshObject:state.currentCartoon mergeChanges:NO];
  }
  state.currentCartoon = cartoon;
  return YES;
}

/*
 accessor for state
 */
-(FLState*)state
{
  return state;
}

/*
 accessor for undo
*/
-(FLUndo*)undo
{
  return undo;
}


/*
 the list of fontnames ios provides with UIFont does not include the default
 system font. deal with that by treating the system font special, give it
 its own name and provide a way to create fonts with that name or the names
 that ios provides.
 */

/*
 return placeholder name for whatever the system font is
 */
-(NSString*)systemFontName
{
  return SYSTEM_FONT_NAME;
}
/*
 create a font. name can be a name from the UIFont list or SYSTEM_FONT_NAME
 */
-(UIFont*)fontForName:(NSString*)fontName size:(CGFloat)size
{
  insist (fontName && fontName.length);
  
  if ([fontName isEqualToString:SYSTEM_FONT_NAME])
    return [[UIFont preferredFontForTextStyle:UIFontTextStyleBody] fontWithSize:size];
  else
    return [UIFont fontWithName:fontName size:size];
}
@end
