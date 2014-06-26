//
//  FLPoint.m
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLPoint.h"
#import "FLPath.h"


@implementation FLPoint

@dynamic x;
@dynamic y;
@dynamic path;

-(void)fault
{
  [self.managedObjectContext refreshObject:self mergeChanges:NO];
}

-(CGPoint)cgPoint
{
  return CGPointMake (self.x, self.y);
}
-(BOOL)equalsPoint:(FLPoint*)point
{
  return self.x == point.x && self.y == point.y;
}
@end
