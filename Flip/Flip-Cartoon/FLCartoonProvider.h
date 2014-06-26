//
//  FLCartoonProvider.h
//  Flip
//
//  Created by Finucane on 6/17/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLCartoon.h"
#import "FLCartoonWriter.h"

typedef void (^FLCartoonProviderBlock)(BOOL done, float progress, NSError*error);

@interface FLCartoonProvider : UIActivityItemProvider
{
  @private
  FLCartoonWriter*cartoonWriter;
  FLCartoonProviderBlock block;
}

-(instancetype)initWithSize:(CGSize)size cartoon:(FLCartoon*)cartoon error:(NSError*__autoreleasing*)error block:(FLCartoonProviderBlock)block;

@end
