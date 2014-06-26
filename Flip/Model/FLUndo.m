//
//  FLUndo.m
//  Flip
//
//  Created by Finucane on 6/23/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLUndo.h"
#import "insist.h"

/*
 FLUndo handles dealing with Core Data adding its own undo events to its undo manager. To make our own
 undo work, we need to keep track of the undo groups that core data creates while we are away from
 the event loop. When we want to do an undo, we roll back as many other undo groups that were created
 by Core Data between our own calls to begin/end undo group, and then we roll back one of our own undo
 groups.
 
 the implementation assumes (and asserts) that we ourselves never nest undo groups. In that simple case
 it's easy to keep track of the count of other undo groups being created between our own events. (which
 in practice are going to be made based on entire gesture life cycles. A count is kept of how many undo
 groups have been created. Every time we create our own undo group, we keep track of what the undo group
 count was at that time. When it's time to do an undo, we look at the saved undo group counts for our most
 recent 2 undoGroups, and undoNestedGroup the difference. If no one but us were adding groups, that difference
 would be 1 each time, but ...
 
 There is a race condition or two here. What happens if Core Data has created a group after our last group and
 then we undo? When exactly do we get notified about new groups being created?
 
 Since what Core Data is actually doing to our undoManager is not documented we can't do better than our best
 effort. NSUndoManager throws consistency exceptions in its entry points, and we make sure we wrap those in try/catch
 blocks. That should make the guesswork we had to do stable, because the catch blocks reset the undo state.
 
 This class is meant to work closely with an NSManagerObject context, mainly to make sure that
 processPendingChanges is called. It does not strongly reference its moc ivar. The references go like
 this where == is a strong reference:
 
 FLCoreData <======= moc <====== undoManager
 FLCoreData <======= FLUndo <------- moc
 
 we know it is safe to call [undoManger undo] directly rather than [moc undo] because NSManagedObjectContext
 doesn't expose undoNestedGroup, which is nonsense.
 
 */

static const NSUInteger MAX_LEVELS_OF_UNDOS = 20;

@implementation FLUndo

/*
  initialize a FLUndo. moc's undo manager is set to the FLUndo's internal undo manager.
 
  moc - a moc
 
  returns an FLUndo
*/

-(instancetype)initWithMoc:(NSManagedObjectContext*)aMoc
{
  insist (aMoc);
  if ((self = [super init]))
  {
    moc = aMoc;
    
    NSUndoManager*undoManager = [[NSUndoManager alloc] init];
    insist (undoManager);
    undoManager.groupsByEvent = YES; //default, only a fool disables this
    undoManager.levelsOfUndo = MAX_LEVELS_OF_UNDOS; //hardcoded because memory is scarce anyway
    
    /*set up a global group count and last-seen-by-us group count stack*/
    lastGroupCount = 0;
    groupCounts = [[NSMutableArray alloc] init];
    
    /*register to be notified whenever groups are added*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCloseGroup:) name:NSUndoManagerDidCloseUndoGroupNotification object:moc.undoManager];
    
    /*let the moc have its way with our undoManager*/
    moc.undoManager = undoManager;
    isOpen = NO; //sanity checking
  }
  return self;
}

/*
  make sure we are disconnected from the notification center when we are freed.
*/
-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
  the handler for NSUndoManagerDidCloseUndoGroupNotification. it keeps
  track of how many undo groups have been made.
*/
-(void)didCloseGroup:(NSNotification*)notification
{
  insist (notification);
  
  /*
    we only care about our own undoManager. UIKit is going to have its own
    undo manager, for instance to deal with the cartoon title text field
    in the settings part of the app.
  */
  if (notification.object == moc.undoManager)
  {
    groupCount++;
  }
}

-(void)beginUndoGrouping
{
  insist (!isOpen);
  isOpen = YES;
  
  [moc processPendingChanges];
  [moc.undoManager beginUndoGrouping];
}

-(void)endUndoGrouping
{
  insist (isOpen);
  isOpen = NO;
  
  [groupCounts addObject:@(groupCount - lastGroupCount)];
  lastGroupCount = groupCount;
  
  [moc processPendingChanges];
  [moc.undoManager endUndoGrouping];
}

-(void)undo
{
  if (groupCounts.count == 0)
    return;
  
  [moc processPendingChanges];
  
  int numGroups = (int)[(NSNumber*)[groupCounts lastObject] unsignedIntegerValue];
  [groupCounts removeLastObject];
  
  @try
  {
    for (int i = 0; i < numGroups; i++)
      [moc.undoManager undoNestedGroup];
  }
  @catch (NSException*e)
  {
    [self reset];
  }
}
-(void)reset
{
  [groupCounts removeAllObjects];
  lastGroupCount = 0;
  [moc processPendingChanges];
  [moc.undoManager removeAllActions];
}

/*
 turn undo registration on or off. we only use this in the code
 that generates large test scenes because it's too complicated
 to try and only enable undo when we are doing our own thing
 in the event loop (during gestures).
 
 on - true if undo registration should be enabled.
 */
-(void)setEnabled:(BOOL)on
{
  [moc processPendingChanges];
  
  @try
  {
    if (on)
      [moc.undoManager enableUndoRegistration];
    else
      [moc.undoManager disableUndoRegistration];
  }
  @catch (NSException*e)
  {
    
  }
}

/*
  debugging method to dump undoStack. if we leave it in,
  apple will reject it. they must have a tool that detects
  valueForKey being called w/ underscored keys on their own
  classes. if not statically than at least when they run
  the app.
*/
#if 0
-(void)dump
{
	@try
	{
		id stack = [moc.undoManager valueForKey:@"_undoStack"];
    NSLog (@"stack is class:%@", [[stack class] description]);
		NSLog (@"(%d entries) %@", [stack count], [stack description]);
	}
	@catch (NSException*e)
	{
	}
}
#endif

@end
