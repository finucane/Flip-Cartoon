//
//  NSError+Additions.m
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "NSError+Additions.h"

@implementation NSError (Additions)

NSString*const kNSErrorOtherDomain = @"NSErrorOther";

+(NSError*)errorWithCode:(int)code description:(NSString*)description
{
  return [NSError errorWithDomain:kNSErrorOtherDomain code:code userInfo:@{NSLocalizedDescriptionKey:description}];
}

+(NSError*)errorWithCode:(int)code error:(NSError*)error format:(NSString*)format, ...
{
  va_list args;
  va_start(args, format);
  NSString*description = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  
  NSString*full = [NSString stringWithFormat:@"%@. Original error:%@", description, error.description];
  return [NSError errorWithCode:code description:full];
}

+(NSError*)errorWithCode:(int)code format:(NSString*)format, ...
{
  va_list args;
  va_start(args, format);
  NSString*description = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  return [NSError errorWithCode:code description:description];
}
@end
