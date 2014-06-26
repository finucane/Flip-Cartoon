//
//  FLManagedObject.m
//  Flip
//
//  Created by Finucane on 5/30/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

/*
 abstract base class to implement recursive faulting.
 see https://developer.apple.com/library/ios/documentation/cocoa/Conceptual/CoreData/Articles/cdMemory.html
 
 all subclasses have to implement their own fault: which if there are no relationships is just a call to
 the moc's refreshObject:mergeChanges: on self with mergeChanges NO.
 
 but for subclasses with logical parent-child relations (a path has many points), the recursion goes down that
 direction. this logic holds for scenes. scenes have many shapes but shapes can be in many scenes
 (many-to-many relationship). the recursion will go from scene to shape because that's the logical parent-child
 direction in the graph (scenes contain shapes).
 
 for one-to-one relationships we don't care. we happen to have none that matter in terms of memory management.
 
 its implemented this way (no shared code in the base-class and not as a protocol) to make it less error-prone.
 */

#import "FLManagedObject.h"
#import "insist.h"

@implementation FLManagedObject

-(void)fault
{
  insist (0);
}
@end
