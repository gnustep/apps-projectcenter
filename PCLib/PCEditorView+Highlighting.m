/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

   Author: Philippe C.D. Robert <phr@3dkit.org>

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

   $Id$
*/

#import "PCEditorView+Highlighting.h"

#define SCANLOC [scanner scanLocation]

@implementation PCEditorView (Highlighting)

static NSColor *commentColor = nil;
static NSColor *keywordColor = nil;
static NSColor *cppCommentColor = nil;
static NSColor *stringColor = nil;
static NSColor *cStringColor = nil;
static NSFont *editorFont = nil;

+ (void)initialize
{
    static BOOL initialised = NO;

    if( !initialised )
    {
        initialised = YES;

#define CALIBRATED_COL(r, g, b, a) RETAIN([NSColor colorWithCalibratedRed:r green:g blue:b alpha:a]);
	commentColor = CALIBRATED_COL(0.0,0.5,0.0,1.0);
	keywordColor = CALIBRATED_COL(0.0,0.5,0.0,1.0);
	cppCommentColor = CALIBRATED_COL(0.8,0.0,0.0,1.0);
	stringColor = CALIBRATED_COL(0.0,0.0,0.8,1.0);
	cStringColor = CALIBRATED_COL(0.0,0.0,0.8,1.0);
	editorFont = RETAIN([NSFont userFixedPitchFontOfSize:12]);
#undef CALIBRATED_COL
    }

    [super initialize];
}

- (void)colouriseStrings
{
  BOOL foundRange;
  id aDict = [NSDictionary dictionaryWithObjectsAndKeys:
			     stringColor, NSForegroundColorAttributeName,
			   @"StringConstantCodeType", @"PCCodeTypeAttributeName", nil ];

  [scanner setScanLocation:0];
  
  while( ![scanner isAtEnd] )  {
    foundRange = NO;

    [scanner scanUpToString:@"\"" intoString:NULL];
    range.location = SCANLOC;
    [scanner scanString:@"\"" intoString:NULL];
      
    if( ![scanner isAtEnd] &&
	range.location > 0 &&
	[[_textStorage string] characterAtIndex:(SCANLOC - 2)] == '@' ) {
      range.location -= 1;
    }

    while( ![scanner isAtEnd] ) {
      [scanner scanUpToString:@"\"" intoString:NULL];
      [scanner scanString:@"\"" intoString:NULL];
      
      // If there is no escape char before then we are done..
      
      if( [[scanner string] characterAtIndex:(SCANLOC - 2)] != '\\' ||
	  [[scanner string] characterAtIndex:(SCANLOC - 3)] == '\\' ) {
	range.length = SCANLOC - range.location;
	foundRange = YES;
	break;
      }      
    }

    if( foundRange ) {
      NS_DURING
	[_textStorage addAttributes:aDict range:range];
      NS_HANDLER
	NSLog(@"<%@ %x> raised (-scanForStrings):\n%@",[self class],self,[localException description]);
      NS_ENDHANDLER
    }
  }
}

- (void)colouriseCharStrings
{
  NSRange tmpRange;
  BOOL foundRange;
  id aDict = [NSDictionary dictionaryWithObjectsAndKeys:
			     cStringColor,NSForegroundColorAttributeName,
			   @"StringConstantCodeType", @"PCCodeTypeAttributeName", nil ];
  
  [scanner setScanLocation:0];

  while( ![scanner isAtEnd] ) {
    foundRange = NO;
    [scanner scanUpToString:@"'" intoString:NULL];
    range.location = SCANLOC;
    [scanner scanString:@"'" intoString:NULL];
      
    while( ![scanner isAtEnd] ) {
      [scanner scanUpToString:@"'" intoString:NULL];
      [scanner scanString:@"'" intoString:NULL];
      
      // No escape => we are done! (ugly hack...)	  
      if( [[scanner string] characterAtIndex:(SCANLOC - 2)] != '\\' ||
	  [[scanner string] characterAtIndex:(SCANLOC - 3)] == '\\' ) {

	range.length = SCANLOC - range.location;

	// Ranges are not longer than 8 chars! (ugly hack...)	
	if( range.length > 8 ) {
	  [scanner setScanLocation:SCANLOC - 1];
	}
	else {
	  foundRange = YES;
	}
	break;
      }  
    }

    if( foundRange ) {
      NS_DURING
	[_textStorage addAttributes:aDict range:range];
      NS_HANDLER
	NSLog(@"<%@ %x> raised (-colouriseCharStrings):\n%@",[self class],self,[localException description]);
      NS_ENDHANDLER
    }
  }
}

- (void)colouriseComments
{
  NSRange tmpRange;
  BOOL foundRange;
  id anObject;
  id aDict = [NSDictionary dictionaryWithObjectsAndKeys:
			     commentColor,NSForegroundColorAttributeName,
			   @"CommentCodeType", @"PCCodeTypeAttributeName", 
			   nil ];

  [scanner setScanLocation:0];
  
  while( ![scanner isAtEnd] ) {
    foundRange = NO;
      
    while( ![scanner isAtEnd] ) {
      [scanner scanUpToString:@"/*" intoString:NULL];
      range.location = SCANLOC;
      [scanner scanString:@"/*" intoString:NULL];
      
      if(![scanner isAtEnd] &&
	 [[_textStorage attribute:@"PCCodeTypeAttributeName"
			atIndex:range.location
			effectiveRange:&tmpRange] isEqual:@"UnknownCodeType"]){
	foundRange = YES;
	break;
      }
    }  
 
    [scanner scanUpToString:@"*/" intoString:NULL];
    [scanner scanString:@"*/" intoString:NULL];
    range.length = SCANLOC - range.location;
    
    if( foundRange ) {
      NS_DURING
	/*
	 * BIG HACK!!!
	 */
	if (range.location == 0) {range.location = 1;range.length--;}
        [_textStorage addAttributes:aDict range:range];
      NS_HANDLER
	NSLog(@"<%@ %x> raised (-colouriseComments):\n%@",[self class],self,[localException description]);
      NS_ENDHANDLER
    }
  }
}

- (void)colouriseCPPComments
{
  NSRange tmpRange;
  BOOL foundRange;
  id anObject;
  id aDict = [NSDictionary dictionaryWithObjectsAndKeys:
			    cppCommentColor, NSForegroundColorAttributeName,
			   @"CommentCodeType", @"PCCodeTypeAttributeName", nil ];
  
  [scanner setScanLocation:0];
  
  while( ![scanner isAtEnd] ) {
    foundRange = NO;
    
    while( ![scanner isAtEnd] ) {
      [scanner scanUpToString:@"//" intoString:NULL];
      range.location = SCANLOC;
      [scanner scanString:@"//" intoString:NULL];
      
      if( ![scanner isAtEnd] &&
	  [[_textStorage attribute:@"PCCodeTypeAttributeName"
			 atIndex:range.location
			 effectiveRange:&tmpRange] isEqual:@"UnknownCodeType"]){
	foundRange = YES;
	break;
      }
    }
    
    [scanner scanUpToString:@"\n" intoString:NULL];
    [scanner scanString:@"\n" intoString:NULL];
    range.length = SCANLOC - range.location;
    
    if( foundRange ) {
      NS_DURING
	[_textStorage addAttributes:aDict range:range];
      NS_HANDLER
	NSLog(@"<%@ %x> raised (-colouriseCPPComments):\n%@",[self class],self,[localException description]);
      NS_ENDHANDLER
    }
  }
}

- (void)colouriseKeyword:(NSString *)keyword
{
  NSRange tmpRange;
  BOOL foundRange;
  id anObject;
  
  id keywordDict = [NSDictionary dictionaryWithObjectsAndKeys:
				   keywordColor,NSForegroundColorAttributeName,
				 @"KeywordCodeType", @"PCCodeTypeAttributeName", nil ];
  
  // First scan for docu style comments
  [scanner setScanLocation:0];
  
  while( ![scanner isAtEnd] ) {
    
    [scanner scanUpToString:keyword intoString:NULL];
    range.location = SCANLOC;
    
    if( ![scanner isAtEnd] &&
	[[_textStorage attribute:@"PCCodeTypeAttributeName"
		      atIndex:range.location
		      effectiveRange:&tmpRange] isEqual:@"UnknownCodeType"] ) {
      NS_DURING
	[_textStorage addAttributes:keywordDict range:NSMakeRange( range.location, [keyword length])];
      NS_HANDLER
	NSLog(@"<%@ %x> raised (-colouriseKeyword:):\n%@",[self class],self,[localException description]);
      NS_ENDHANDLER
    }
    [scanner scanString:keyword intoString:NULL];
  }
}

- (void)colouriseKeywords:(NSArray *)keywords
{
  NSEnumerator *enumerator = [keywords objectEnumerator];
  id object;

  while ((object = [enumerator nextObject])) {
    [self colouriseKeyword:object];
  }
}

@end
