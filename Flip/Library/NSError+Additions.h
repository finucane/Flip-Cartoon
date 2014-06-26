//
//  NSError+Additions.h
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (Additions)

extern NSString*const kNSErrorOtherDomain;

+(NSError*)errorWithCode:(int)code description:(NSString*)description;
+(NSError*)errorWithCode:(int)code format:(NSString*)format, ...;
+(NSError*)errorWithCode:(int)code error:(NSError*)error format:(NSString*)format, ...;

@end
