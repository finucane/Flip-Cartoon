//
//  FLState.m
//  Flip
//
//  Created by Finucane on 5/29/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLState.h"
#import "FLCartoon.h"


@implementation FLState

@dynamic currentCartoon;
-(void)fault
{
  [self.managedObjectContext refreshObject:self mergeChanges:NO];
}
@end
