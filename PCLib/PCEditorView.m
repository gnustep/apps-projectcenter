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

#import "PCEditorView.h"
#import "PCEditor.h"
#import "PCEditorView+Highlighting.h"

@implementation PCEditorView

static BOOL shouldHighlight = NO;
static int  _tabFlags       = PCTab4Sp;

+ (void)setTabBehaviour:(int)tabFlags
{
    _tabFlags = tabFlags;
}

+ (int)tabBehaviour
{
    return _tabFlags;
}

+ (void)setShouldHighlight:(BOOL)yn
{
    shouldHighlight = yn;
}

+ (BOOL)shouldHighlight
{
    return shouldHighlight;
}

- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer*)tc
{
  if ((self = [super initWithFrame:frameRect textContainer:tc])) 
  {
    shouldHighlight = NO;

    _keywords = [[NSArray alloc] initWithObjects:@"@class",
                                                 @"@selector",
						 @"#import",
						 @"#include",
						 @"#ifndef",
						 @"#if defined",
						 @"#define",
						 @"#endif",
						 @"#pragma",
						 @"#warning",
						 @"@interface",
						 @"@implementation",
						 @"@end",
						 @"@protocol",
						 nil];
  }
  return self;
}

- (void)dealloc
{
  if (scanner) 
  {
    [scanner release];
  }
  [_keywords release];

  [super dealloc];
}

- (void)setEditor:(PCEditor *)anEditor
{
    editor = anEditor;
}

- (void)setString:(NSString *)aString
{
    [scanner autorelease];
    scanner = [[NSScanner alloc] initWithString:aString];

    [super setString:aString];

    if( shouldHighlight )
    {
	[self highlightText];
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)insertText:(id)aString
{
    NSRange txtRange = NSMakeRange(0, [[self textStorage] length]);

    [super insertText:aString];

    if( shouldHighlight )
    {
	[[self textStorage] invalidateAttributesInRange:txtRange];
	[self highlightTextInRange:txtRange];
    }
}

- (void)highlightText
{
    NSRange txtRange = NSMakeRange(0, [[self textStorage] length]);

    [self highlightTextInRange:txtRange];
}

- (void)highlightTextInRange:(NSRange)txtRange
{
  //NSDictionary *aDict;
  NSArray      *keywords;

/*
  aDict = [NSDictionary dictionaryWithObjectsAndKeys:
			  editorFont, NSFontAttributeName,
			@"UnknownCodeType", @"PCCodeTypeAttributeName",
			nil];
*/

  [_textStorage beginEditing];  
  [_textStorage setAttributes:nil range:txtRange];
  
  // Scan the CodeType first...

  [self colouriseKeywords:_keywords];
  [self colouriseStrings];
  [self colouriseCharStrings];
  [self colouriseComments];
  [self colouriseCPPComments];

  /*
   * BIG HACK!
   */
  
  NS_DURING
    [_textStorage endEditing];
  NS_HANDLER
    NSLog(@"Excpetion: %@",[localException description]);
  NS_ENDHANDLER

  [self setNeedsDisplay:YES];
}

- (void)keyDown:(NSEvent *)anEvent
{
    /*
    NSString *chars = [anEvent charactersIgnoringModifiers];
    int modifiers = [anEvent modifierFlags];

    if(([chars lossyCString][0] == 's') && (modifiers & NSCommandKeyMask))
    {
	[editor saveFile];
	return;
    }
    */

    if( [[anEvent characters] isEqualToString:@"\t"] )
    {
        switch( _tabFlags )
	{
	    case PCTabTab:
	        [self insertText: @"\t"];
	        break;
	    case PCTab2Sp:
	        [self insertText: @"  "];
	        break;
	    case PCTab4Sp:
	        [self insertText: @"    "];
	        break;
	    case PCTab8Sp:
	        [self insertText: @"        "];
	        break;
            default:
	        break;
	}
    }
    else
    {
	[super keyDown:anEvent];
    }
}

@end
