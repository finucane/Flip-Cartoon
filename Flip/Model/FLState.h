//
//  FLState.h
//  Flip
//
//  Created by Finucane on 5/29/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FLManagedObject.h"

@class FLCartoon;

@interface FLState : FLManagedObject
@property (nonatomic, retain) FLCartoon *currentCartoon;

@end
