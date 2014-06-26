//
//  FLUndo.h
//  Flip
//
//  Created by Finucane on 6/23/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FLUndo : NSObject
{
  @private
  NSUInteger groupCount;
  NSUInteger lastGroupCount;
  NSMutableArray*groupCounts;
  __weak NSManagedObjectContext*moc;
  BOOL isOpen;
}

-(instancetype)initWithMoc:(NSManagedObjectContext*)moc;
-(void)beginUndoGrouping;
-(void)endUndoGrouping;
-(void)undo;
-(void)reset;
-(void)setEnabled:(BOOL)on;
@end
