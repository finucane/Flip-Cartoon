//
//  FLCartoonWriter.m
//  Flip
//
//  Created by Finucane on 6/16/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "UIAlertView+Additions.h"
#import "NSError+Additions.h"
#import "FLAppDelegate.h"
#import "FLCartoonWriter.h"
#import "insist.h"

/*
 FLCartoonWriter is a class that lets a cartoon write to a video file.
 Most of its state is AVAssetWriter stuff and a separate NSManagedObjectContext used
 to access an FLCartoon on a background queue.
 */
@implementation FLCartoonWriter

/*
 create a tmp file url, suitable for writing a movie to. we use the name of the cartoon as the filename
 because the name appears when you send the movie as an attachment.
 */
-(NSURL*)tmpURLForCartoon:(FLCartoon*)cartoon
{
  insist (cartoon);
  
  /*make a filename that's not harmful for the file system. only 100% whitespace and "/" is illegal.
   the cartoon name is already constrained to be non empty, but deal with that possibility here anyway.
   */
  NSString*filename = cartoon.title;
  
  filename = [filename stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  [filename stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
  
  if (filename.length == 0)
    filename = NSLocalizedString (@"Untitled", nil);
  
  filename = [NSString stringWithFormat:@"%@%@", filename, @".mov"];
  NSString*path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
  insist (path);
  return [NSURL fileURLWithPath:path];
}

/*
 acessor for url
 */
-(NSURL*)url
{
  return url;
}

/*
 clever thing from stack overflow
 */
int round_up (int num, int factor)
{
  return num + factor - 1 - (num - 1) % factor;
}

/*
 initialize an FLCartoonWriter.
 
 size - size of frame
 cartoon - cartoon to render
 error - set if error
 
 return nil on error
 */

-(instancetype)initWithSize:(CGSize)size cartoon:(FLCartoon*)cartoon error:(NSError*__autoreleasing*)error
{
  insist (cartoon && error);
  
  if ((self = [super init]))
  {
    cartoonID = cartoon.objectID;
    insist (cartoonID);
    
    /*get framesPerSecond which we use for rendering and also to determine progress*/
    framesPerSecond = cartoon.framesPerSecond;
    insist (framesPerSecond > 0);
    
    /*sizes have to be multiples of 16 for rendering to work on devices so round up a bit if necessary*/
    int width = round_up (size.width, 16);
    int height = round_up (size.height, 16);
    insist (width % 16 == 0);
    insist (height % 16 == 0);
    
    /*get a tmp file url for cartoon.*/
    url = [self tmpURLForCartoon:cartoon];
    insist (url);
    
    /*make sure there's no existing file. if there is, appendPixelBuffer fails*/
    [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    
    writer = [[AVAssetWriter alloc] initWithURL:url fileType:AVFileTypeQuickTimeMovie error:error];
    if (!writer)
      return nil;
    
    writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                     outputSettings:@{AVVideoCodecKey : AVVideoCodecH264,
                                                                      AVVideoWidthKey: @(width),
                                                                      AVVideoHeightKey : @(height)}];
    
    NSDictionary*attributes = @{(NSString*)kCVPixelBufferPixelFormatTypeKey :  @(kCVPixelFormatType_32ARGB),
                                (NSString*)kCVPixelBufferWidthKey: @(width),
                                (NSString*)kCVPixelBufferHeightKey: @(height)};
    
    adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:attributes];
    insist (adaptor);
    
    [writer addInput:writerInput];
    writerInput.expectsMediaDataInRealTime = YES;
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
  }
  return self;
}

/*
 writing the cartoon to a movie on disk. block is called periodically to
 give progress information, and it's called at the end when the writing is done.
 
 */
-(BOOL)writeWithError:(NSError*__autoreleasing*)error block:(FLCartoonWriterBlock)block;
{
  insist (cartoonID && block);
  insist (framesPerSecond > 0);
  
  /*
   make a new queue because requestMediaDataWhenReadyOnQueue needs one and
   dispatch_get_current_queue () is deprecated.
   */
  dispatch_queue_t queue = dispatch_queue_create("writeWithError", 0);
  insist (queue);
  
  /*make a semaphore to wait for completion of everything with.*/
  dispatch_semaphore_t semaphore = dispatch_semaphore_create (0);
  insist (semaphore);
  
  __block BOOL failed = YES; //unless we succeed
  __block NSError*ourError;
  
  dispatch_async (queue, ^{
    
    __block uint32_t sceneIndex = 0;
    
    [writerInput requestMediaDataWhenReadyOnQueue:queue usingBlock:^{
      
      while (writerInput.isReadyForMoreMediaData)
      {
        @autoreleasepool
        {
          /*
           create a new moc each time. mocs don't actually free memory until they are destroyed. no matter how hard you
           try (faulting, resetting, turning cache off with sensitivityInterval). fortunately they aren't expensive.
           */
          NSManagedObjectContext*moc = [App.coreData newMoc];
          insist (moc);
          
          FLCartoon*cartoon = (FLCartoon*)[moc existingObjectWithID:cartoonID error:&ourError];
          
          if (!cartoon || !cartoon.scenes.count)
          {
            [moc reset];
            return;
          }
          
          /*get 0..1 value representing progress in the write*/
          float progress = (float)sceneIndex / (float)cartoon.scenes.count;
          
          /*tell caller we've made progress*/
          block (progress);
          
          /*get a pixel buffer from the adaptor's pool. once we write to it and append it to the adaptor then
           we free it. the adaptor returns it to its pool once it's finished with it.*/
          
          CVPixelBufferRef pixelBuffer = 0;
          CVReturn r = CVPixelBufferPoolCreatePixelBuffer (0, adaptor.pixelBufferPool, &pixelBuffer);
          if (r != kCVReturnSuccess)
          {
            if (pixelBuffer)
            {
              CVBufferRelease (pixelBuffer);
              pixelBuffer = 0;
            }
            ourError = [NSError errorWithCode:r description:NSLocalizedString (@"Couldn't allocate pixel buffer.", nil)];
            [writerInput markAsFinished];
            [moc reset];
            return;
          }
          
          /*make a graphics context from the pixelBuffer*/
          CVPixelBufferLockBaseAddress (pixelBuffer, 0);
          CGContextRef context = [self cgContextFromPixelBuffer:pixelBuffer];
          
          /*this probably should never fail since it doesn't allocate a lot of data*/
          if (!context)
          {
            CVBufferRelease (pixelBuffer);
            [writerInput markAsFinished];
            ourError = [NSError errorWithCode:r description:NSLocalizedString (@"Couldn't create GC from pixel buffer.", nil)];
            [moc reset];
            return;
          }
          
          /*draw the next frame to the context*/
          uint32_t width = (uint32_t)CVPixelBufferGetWidth (pixelBuffer);
          uint32_t height = (uint32_t)CVPixelBufferGetHeight (pixelBuffer);
          [cartoon drawScene:sceneIndex context:context width:width height:height];
          
          CVPixelBufferUnlockBaseAddress (pixelBuffer, 0);
          
          /*make the timestamp for the current frame*/
          CMTime presentTime = CMTimeMake (sceneIndex, framesPerSecond);
          
          /*add the buffer to the adaptor*/
          if (![adaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentTime])
          {
            /*"If the operation is unsuccessful, writing the asset has failed. You must not call finishWriting."*/
            CVBufferRelease (pixelBuffer);
            CGContextRelease (context);
            ourError = [NSError errorWithCode:0 description:NSLocalizedString (@"Couldn't append pixel buffer.", nil)];
            [moc reset];
            return;
          }
          
          CVBufferRelease (pixelBuffer);
          CGContextRelease (context);
          
          /*if we have no more frames to write, we are done*/
          if (sceneIndex == cartoon.scenes.count - 1)
          {
            /*we need to call endSessionAtSourceTime, otherwise finishWritingWithCompletionHandler hangs*/
            presentTime = CMTimeMake (sceneIndex + 1, framesPerSecond);
            [writer endSessionAtSourceTime:presentTime];
            [writerInput markAsFinished];
            failed = NO;
            [moc reset];

            /*it may take a while to clean up, when we're done we'll stop waiting at the end of the top level method*/
            [writer finishWritingWithCompletionHandler:^{
              
              dispatch_semaphore_signal (semaphore);
            }];
            return;
          }
          /*advance to next frame*/
          sceneIndex++;
          [moc reset];
          moc = nil;
        }
      }}];
  });
  
  /*wait until the writing is done*/
  dispatch_semaphore_wait (semaphore, DISPATCH_TIME_FOREVER);
  *error = ourError;
  return !failed;
}



/*
 use the underlying byte data from pixelBuffer to create a CGContextRef suitable
 for a cartoon to draw into
 
 pixelBuffer - a pixelBuffer
 
 returns a CGContextRef
 */

-(CGContextRef) cgContextFromPixelBuffer:(CVPixelBufferRef) pixelBuffer
{
  insist (pixelBuffer);
  uint32_t width = (uint32_t)CVPixelBufferGetWidth (pixelBuffer);
  uint32_t height = (uint32_t)CVPixelBufferGetHeight (pixelBuffer);
  
  insist (width % 16 == 0);
  insist (height % 16 == 0);
  
  void *pxdata = CVPixelBufferGetBaseAddress(pixelBuffer);
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(pxdata, width, height, 8, 4*width, colorSpace, (CGBitmapInfo) kCGImageAlphaPremultipliedFirst);
  CGColorSpaceRelease (colorSpace);
  CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0,height);
  CGContextConcatCTM (context, flipVertical);
  
  return context;
}



@end
