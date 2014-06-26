//
//  FLCartoonWriter.h
//  Flip
//
//  Created by Finucane on 6/16/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FLCartoon.h"

@class FLCartoonWriter;

typedef void (^FLCartoonWriterBlock)(float progress);

@interface FLCartoonWriter : NSObject
{
  @private
  AVAssetWriter*writer;
  AVAssetWriterInput*writerInput;
  AVAssetWriterInputPixelBufferAdaptor*adaptor;
  NSManagedObjectID*cartoonID;
  uint32_t framesPerSecond;
  NSURL*url;
}

-(instancetype)initWithSize:(CGSize)size cartoon:(FLCartoon*)cartoon error:(NSError*__autoreleasing*)error;
-(BOOL)writeWithError:(NSError*__autoreleasing*)error block:(FLCartoonWriterBlock)block;
-(NSURL*)url;
@end
