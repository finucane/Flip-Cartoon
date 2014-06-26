//
//  FLPoint.h
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FLManagedObject.h"

@class FLPath;

@interface FLPoint : FLManagedObject

@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic, retain) FLPath *path;
-(CGPoint)cgPoint;
-(BOOL)equalsPoint:(FLPoint*)point;
@end
