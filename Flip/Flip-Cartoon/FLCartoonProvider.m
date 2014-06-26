//
//  FLCartoonProvider.m
//  Flip
//
//  Created by Finucane on 6/17/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//


#import "NSError+Additions.h"
#import "FLCartoonProvider.h"
#import "insist.h"

@implementation FLCartoonProvider

/*
  initialize an FLCartoonProvider. a tmp filename is created to be used to write a cartoon video.
 
  size - size of video frame in pixels
  cartoon - a cartoon to render to video
  error - set if there's an error
  block - cartoon provider block for progress indication.
 
  returns a new FLCartoonProvider or nil on error.
*/
-(instancetype)initWithSize:(CGSize)size
                    cartoon:(FLCartoon*)cartoon
                      error:(NSError*__autoreleasing*)error
                      block:(FLCartoonProviderBlock)aBlock
{
  insist (cartoon && error && aBlock);
  
  /*init w/ a don't-care url as the placeholder*/
  if ((self = [super initWithPlaceholderItem:[NSURL fileURLWithPath:@"/"]]))
  {
    if (!(cartoonWriter = [[FLCartoonWriter alloc] initWithSize:size cartoon:cartoon error:error]))
      return nil;

    insist (cartoonWriter);
    block = aBlock;
  }
  return self;
}

/*
  return an NSURL for the a video file written by cartoonWriter.
  this method is being called on an NSOperationQueue not on the
  main thread. progress indication is given through the block
*/
- (id)item
{
  /*write the cartoon as a video to disk, passing on progress information to caller*/
  NSError*error;
  BOOL written = [cartoonWriter writeWithError:&error block:^(float progress){
    block (NO, progress, nil);
  }];
  
  /*
   we are done writing, tell caller what happened. for caller, error being non-nil means failure.
   and coming from writeWithError it should be set, but just be sure that we have something.
   */
  if (!written && !error)
    error = [NSError errorWithCode:0 description:NSLocalizedString(@"Internal Error", nil)];
  
  block (YES, 1.0, error);
  return cartoonWriter.url;
}



@end
