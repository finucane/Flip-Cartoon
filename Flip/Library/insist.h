//
//  insist.h
//  Flip
//
//  Created by Finucane on 5/27/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//


/*
  easy to type macros for things that should never happen but have to be checked anyway. they can be handled
  in the main loop in a top level exception handler when we get around to it.
 */


#ifdef DEBUG

#define insist(e) if(!(e)) [NSException raise: @"assertion failed." format: @"%@:%d (%s)", [[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent], __LINE__, #e]

#else

#define insist(e)((void)(e))

#endif
