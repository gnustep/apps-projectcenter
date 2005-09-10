/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2005 Free Software Foundation

   Authors: Serg Stoyan

   This file is part of GNUstep.

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include <Foundation/Foundation.h>

#include "PCObjCParser.h"
#include "PCProjectEditor.h"
#include "PCEditor.h"

static int keepRunningFlag;

NSString *PCParserDidParseFileNotification = 
          @"PCParserDidParseFileNotification";
	  
@implementation PCObjCParser

+ (void)connectWithPorts:(NSArray *)portArray
{
  NSAutoreleasePool *pool;
  PCObjCParser      *serverObject;
  NSConnection      *serverConnection;

  // setup own autorelease pool
  pool = [[NSAutoreleasePool alloc] init];

  // Create connection to SessionWindow client
  serverConnection = [NSConnection
    connectionWithReceivePort:[portArray objectAtIndex:0]
                     sendPort:[portArray objectAtIndex:1]];

  // Send PCObjCParser instance to PCProjectEditor via setServer method.
  // setServer retains serverObject
  serverObject = [[PCObjCParser alloc] initWithConnection:serverConnection];
  [(PCProjectEditor *)[serverConnection rootProxy] setServer:serverObject];
  [serverObject release];

  NSLog (@"PCObjCParser: waiting for messages");

  // Waiting for messages
  // akind of [[NSRunLoop currentRunLoop] run];
  while (keepRunningFlag && [[NSRunLoop currentRunLoop]
         runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);

  NSLog (@"PCObjCParser: thread exiting...");

  [pool release];
}

- (id)initWithConnection:(NSConnection *)conn
{
  NSArray *attrObjs = nil;
  NSArray *attrKeys = nil;
  
  self = [super init];

  // Default font
  defaultFont = RETAIN([NSFont userFixedPitchFontOfSize:12.0]);

  // Normal text attributes
  attrObjs = [NSArray arrayWithObjects:
    defaultFont,
    [NSColor blackColor],
    nil];
  attrKeys = [NSArray arrayWithObjects:
    NSFontAttributeName,
    NSForegroundColorAttributeName, 
    nil];
  normalAttrs = [[NSDictionary alloc] initWithObjects:attrObjs
                                              forKeys:attrKeys];

  // Comment attributes
  attrObjs = [NSArray arrayWithObjects:
    defaultFont,
    CALIBRATED_COL(0.0,0.0,1.0,1.0),
    nil];
  attrKeys = [NSArray arrayWithObjects:
    NSFontAttributeName,
    NSForegroundColorAttributeName, 
    nil];
  commentAttrs = [[NSDictionary alloc] initWithObjects:attrObjs
                                               forKeys:attrKeys];

  // Keyword attributes
  attrObjs = [NSArray arrayWithObjects:
    defaultFont,
    CALIBRATED_COL(0.62,0.12,0.94,1.0),
    nil];
  attrKeys = [NSArray arrayWithObjects:
    NSFontAttributeName,
    NSForegroundColorAttributeName, 
    nil];
  keywordAttrs = [[NSDictionary alloc] initWithObjects:attrObjs
                                               forKeys:attrKeys];

  // String attributes
  attrObjs = [NSArray arrayWithObjects:
    defaultFont,
    CALIBRATED_COL(0.8,0.0,0.0,1.0),
    nil];
  attrKeys = [NSArray arrayWithObjects:
    NSFontAttributeName,
    NSForegroundColorAttributeName, 
    nil];
  stringAttrs = [[NSDictionary alloc] initWithObjects:attrObjs
                                              forKeys:attrKeys];

  // Error attributes
  attrObjs = [NSArray arrayWithObjects:
    defaultFont,
    [NSColor whiteColor],
    CALIBRATED_COL(1.0,0.0,0.0,1.0),
    nil];
  attrKeys = [NSArray arrayWithObjects:
    NSFontAttributeName,
    NSForegroundColorAttributeName, 
    NSBackgroundColorAttributeName, 
    nil];
  errorAttrs = [[NSDictionary alloc] initWithObjects:attrObjs
                                             forKeys:attrKeys];

  // Charsets
  charset = [NSCharacterSet 
    characterSetWithCharactersInString:@"/*([])-+@#{}\":"];
  whiteCharset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  newLineCS = [NSCharacterSet characterSetWithCharactersInString:@"\n;"];
  methodDefCS = [NSCharacterSet characterSetWithCharactersInString:@";{"];

  // Keywords
  keywords = [NSArray arrayWithObjects:
    @"@class",
    @"@selector",
    @"@interface",
    @"@implementation",
    @"@end",
    @"@protocol",
    @"#import",
    @"#include",
    @"#define",
    @"#ifdef",
    @"#ifndef",
    @"#if defined",
    @"#else",
    @"#elif",
    @"#endif",
    @"#pragma",
    @"#warning",
    nil];

  fileText = nil;
  scanner = nil;
  chars = NULL;
  as = nil;

  // Connection
  clientObject = (id)[conn rootProxy];
  keepRunningFlag = 1;

  return self;
}

- (void)stop
{
  RELEASE(commentAttrs);
  RELEASE(keywordAttrs);
  RELEASE(stringAttrs);
  RELEASE(errorAttrs);
  RELEASE(defaultFont);

  keepRunningFlag = 0;
}

- (oneway void)parseFileAtPath:(NSString *)path forEditor:(PCEditor *)editor
{
  unsigned  location = 0;
  NSString  *stopChar = nil;
  NSString  *nextChar = nil;
  NSString  *ks = nil;   // Keyword start
  unsigned  ksIndex = 0; // Index of keyword start

  NSLog(@"parseFile: start");

  // fileText is object to parse, as - object to paste into NSTextView
  fileText = [[NSString alloc] initWithContentsOfFile:path];
  as = [[NSMutableAttributedString alloc] initWithString:fileText 
                                              attributes:normalAttrs];

  scanner = [[NSScanner alloc] initWithString:fileText];

  while (1)
    {
      [scanner scanUpToCharactersFromSet:charset intoString:chars];
      location = [scanner scanLocation];

      if ([scanner isAtEnd])
	{
	  break;
	}

      stopChar = [fileText substringWithRange:NSMakeRange(location,1)];
      nextChar = [fileText substringWithRange:NSMakeRange(location+1,1)];

      if (([stopChar isEqualToString:@"/"] 
	  && [nextChar isEqualToString:@"*"]) && ks == nil)
	{// Start of comment "/*"
//	  NSLog(@"%@ \"/*\" Comment", stopChar);
	  ksIndex = location;
    	  ks = [NSString stringWithString:@"/*"];
	  location++;
	}
      else if ([stopChar isEqualToString:@"*"] 
	       && [nextChar isEqualToString:@"/"] && ks != nil)
	{ // End of comment "*/"
	  if ([ks isEqualToString:@"/*"])
	    {
//    	      NSLog(@"%@ \"*/\" Comment %@", stopChar, ks);
	      location += 2;
	      [as setAttributes:commentAttrs
		          range:NSMakeRange(ksIndex, location-ksIndex)];
	      ks = nil;
	    }
	  else
	    { // Unmatched comment close. Mark "*/" with error background color
	    }
	}
      else if (([stopChar isEqualToString:@"/"] 
	       && [nextChar isEqualToString:@"/"]) && ks == nil)
	{// "//" Comment
//	  NSLog(@"%@ \"//\"Comment", stopChar);
	  ksIndex = location;
	  [scanner setScanLocation:location+1];
	  [scanner scanUpToCharactersFromSet:newLineCS intoString:chars];
	  location = [scanner scanLocation];

	  [as setAttributes:commentAttrs
	              range:NSMakeRange(ksIndex, location-ksIndex)];
	}
      else if ([stopChar isEqualToString:@"\\"])
	{// Shield of next character. Next character should be skipped.
	  location += 2;
	}
      else if ([stopChar isEqualToString:@"\""])
	{// String
//	  NSLog(@"%@ String", stopChar);
	}
// -------------------------------------------------------- KEYWORDS ---------
      else if ([stopChar isEqualToString:@"@"] && ks == nil)
	{// ObjC keyword
//	  NSLog(@"%@ Keyword", stopChar);
	  ksIndex = location;

	  [scanner scanUpToCharactersFromSet:whiteCharset intoString:chars];
	  location = [scanner scanLocation];

	  ks = [fileText 
	    substringWithRange:NSMakeRange(ksIndex,location-ksIndex)];
	  if ([keywords containsObject:ks])
	    {
    	      [as setAttributes:keywordAttrs
		          range:NSMakeRange(ksIndex, location-ksIndex)];

	      if ([ks isEqualToString:@"@interface"] 
		  || [ks isEqualToString:@"@implementation"])
		{
		  [scanner scanUpToCharactersFromSet:newLineCS
		                          intoString:chars];
		  location = [scanner scanLocation];
		  ks = [fileText 
		    substringWithRange:NSMakeRange(ksIndex,location-ksIndex)];
		  classDefinition = RETAIN([self classNameFromString:ks]);
		  [editor addClassName:classDefinition
		             withRange:NSMakeRange(ksIndex,location-ksIndex)];
		}
	      else if ([ks isEqualToString:@"@end"])
		{
		  RELEASE(classDefinition);
		  classDefinition = nil;
		}
	    }
	  else
	    {// Unknown keyword. Mark with error background color
	    }
	  location++;
	  [scanner setScanLocation:location];
	  ks = nil;
	}
      else if ([stopChar isEqualToString:@"#"] && ks == nil)
	{// Preprocessor keyword
	}
// -------------------------------------------------------- METHODS ----------
      else if (([stopChar isEqualToString:@"-"] 
	       || [stopChar isEqualToString:@"+"]) && ks == nil)
	{// Method definition
//	  NSLog(@"%@ Method", stopChar);
	  NSRange  range;
	  
	  range = NSMakeRange(location-1,1);
	  if ([[fileText substringWithRange:range] isEqualToString:@"\n"])
	    {
	      methodStartIndex = location;

	      [scanner scanUpToCharactersFromSet:methodDefCS intoString:chars];
	      location = [scanner scanLocation];
	      stopChar = [fileText substringWithRange:NSMakeRange(location,1)];
	      // At this point scanner stops at "{" or ";"

	      range = NSMakeRange(methodStartIndex,location - methodStartIndex);
	      methodDefinition = [fileText substringWithRange:range];
	      methodDefinition = [self methodNameFromString:methodDefinition];

	      if ([stopChar isEqualToString:@";"])
		{ // Method definition in header file
		  [editor addMethodWithDefinition:methodDefinition
     		                         andRange:range
				         forClass:classDefinition];
		  methodStartIndex = 0;
		  methodDefinition = nil;
		}
	    }
	}
      else if ([stopChar isEqualToString:@"}"] && methodStartIndex != 0)
	{// End of method or function
//	  NSLog(@"%@ End of method or function", stopChar);
	  NSRange range;

	  range = NSMakeRange(methodStartIndex, location - methodStartIndex);
	  [editor addMethodWithDefinition:methodDefinition
  		                 andRange:range
				 forClass:classDefinition];
	  methodStartIndex = 0;
	  methodDefinition = nil;
	}
      else if ([stopChar isEqualToString:@":"])
	{// Method argument or label
//	  NSLog(@"%@ Method argument or label", stopChar);
	}
      else if ([stopChar isEqualToString:@"("] && ks == nil)
	{// Begin of method type or function definition
//	  NSLog(@"%@ Begin of method type or function definition", stopChar);
	}
      else if ([stopChar isEqualToString:@")"] && [ks isEqualToString:@"("])
	{// End of method type or function definition
//	  NSLog(@"%@ End of method type or function definition", stopChar);
	}
      [scanner setScanLocation:location+1];
    }

  // Paste to TextView
  // Use here notification because NSText* lacks thread safety?
  NSLog(@"Paste to TextView %@", [path lastPathComponent]);

  NSArray      *objects = [NSArray arrayWithObjects:as, path, nil];
  NSArray      *keys = [NSArray arrayWithObjects:@"Text", @"Path", nil];
  NSDictionary *dict = nil;
  

  dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCParserDidParseFileNotification
                  object:self
		userInfo:dict];

  // Cleanup
  RELEASE(scanner);
  scanner = nil;
  RELEASE(fileText);
  fileText = nil;
  RELEASE(as);
  as = nil;

  NSLog(@"parseFile: end");
}

- (NSString *)classNameFromString:(NSString *)string
{
  NSMutableArray *lineComps = nil;
  NSString       *className = nil;

  // ClassName : SuperClassName <Protocol>
  // ClassName (Category)
  // ClassName(Category)
  // ClassName( Category)
  // ClassName(Category )
  // ClassName ( Category )
  // ClassName (Category )
  // ClassName ( Category)

  lineComps = [[string componentsSeparatedByString:@" "] mutableCopy];
  [lineComps removeObjectAtIndex:0];
  className = [lineComps componentsJoinedByString:@""];
  RELEASE(lineComps);

  className = [NSString stringWithFormat:@"@%@", className];

  return className;
}

- (NSString *)methodNameFromString:(NSString *)string
{
  NSMutableArray *lineComps = nil;
  NSString       *methodName = nil;

  // Remove tabs
  lineComps = [[string componentsSeparatedByString:@"\t"] mutableCopy];
  methodName = [lineComps componentsJoinedByString:@""];
  RELEASE(lineComps);

  // Remove new line symbols
  lineComps = [[methodName componentsSeparatedByString:@"\n"] mutableCopy];
  methodName = [lineComps componentsJoinedByString:@""];
  RELEASE(lineComps);

  // Remove text after ":"
/*  lineComps = [[methodName componentsSeparatedByString:@":"] mutableCopy];
  for (unsigned i = 1; i < [lineComps count];)
    {
      if (i)
	[lineComps removeObjectAtIndex:i];
      else
	i++;
    }*/
  
  // Remove spaces
  lineComps = [[methodName componentsSeparatedByString:@" "] mutableCopy];
  methodName = [lineComps componentsJoinedByString:@""];
  RELEASE(lineComps);

  return methodName;
}

@end
