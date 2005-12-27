/*
    PCEditorView.m

    Implementation of the PCEditorView class for the
    ProjectManager application.

    Copyright (C) 2005  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import "PCEditorView.h"

#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSArchiver.h>

#import <AppKit/PSOperators.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSLayoutManager.h>
#import <AppKit/NSFont.h>

#import <ctype.h>

#import "PCEditor.h"
#import "SyntaxHighlighter.h"

static inline float
my_abs(float aValue)
{
  if (aValue >= 0)
    {
      return aValue;
    }
  else
    {
      return -aValue;
    }
}

/**
 * Computes the indenting offset of the last line before the passed
 * start offset containg text in the passed string, e.g.
 *
 * ComputeIndentingOffset(@"  Hello World", 12) = 2
 * ComputeIndentingOffset(@"    Try this one out\n"
 *                        @"      ", 27) = 4
 *
 * @argument string The string in which to do the computation.
 * @argument start The start offset from which to start looking backwards.
 * @return The ammount of spaces the last line containing text is offset
 *      from it's start.
 */
static int ComputeIndentingOffset(NSString * string, unsigned int start)
{
  SEL sel = @selector(characterAtIndex:);
  unichar (* charAtIndex)(NSString *, SEL, unsigned int) =
    (unichar (*)(NSString *, SEL, unsigned int))
    [string methodForSelector: sel];
  unichar c;
  int firstCharOffset = -1;
  int offset;
  int startOffsetFromLineStart = -1;

  for (offset = start - 1; offset >= 0; offset--)
    {
      c = charAtIndex(string, sel, offset);

      if (c == '\n')
        {
          if (startOffsetFromLineStart < 0)
            {
              startOffsetFromLineStart = start - offset - 1;
            }

          if (firstCharOffset >= 0)
            {
              firstCharOffset = firstCharOffset - offset - 1;
              break;
            }
        }
      else if (!isspace(c))
        {
          firstCharOffset = offset;
        }
    }

  if (firstCharOffset >= 0)
    {
      // if the indenting of the current line is lower than the indenting
      // of the previous actual line, we return the lower indenting
      if (startOffsetFromLineStart >= 0 &&
        startOffsetFromLineStart < firstCharOffset)
        {
          return startOffsetFromLineStart;
        }
      // otherwise we return the actual indenting, so that any excess
      // space is trimmed and the lines are aligned according the last
      // indenting level
      else
        {
          return firstCharOffset;
        }
    }
   else
    {
      return 0;
    }
}

@interface PCEditorView (Private)

- (void) insertSpaceFillAlignedAtTabsOfSize: (unsigned int) tabSize;

@end

@implementation PCEditorView (Private)

/**
 * Makes the receiver insert as many spaces at the current insertion
 * location as are required to reach the nearest tab-character boundary.
 *
 * @argument tabSize Specifies how many spaces represent one tab.
 */
- (void) insertSpaceFillAlignedAtTabsOfSize: (unsigned int) tabSize
{
  char buf[tabSize];
  NSString * string = [self string];
  unsigned int lineLength;
  SEL sel = @selector(characterAtIndex:);
  unichar (* charAtIndex)(NSString*, SEL, unsigned int) =
    (unichar (*)(NSString*, SEL, unsigned int))
    [string methodForSelector: sel];
  int i;
  int skip;

  // computes the length of the current line
  for (i = [self selectedRange].location - 1, lineLength = 0;
       i >= 0;
       i--, lineLength++)
    {
      if (charAtIndex(string, sel, i) == '\n')
        {
          break;
        }
    }

  skip = tabSize - (lineLength % tabSize);
  if (skip == 0)
    {
      skip = tabSize;
    }

  memset(buf, ' ', skip);
  [super insertText: [NSString stringWithCString: buf length: skip]];
}

@end

@implementation PCEditorView

+ (NSFont *) defaultEditorFont
{
  NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
  NSString * fontName;
  float fontSize;
  NSFont * font = nil;

  fontName = [df objectForKey:@"EditorFont"];
  fontSize = [df floatForKey:@"EditorFontSize"];

  if (fontName != nil)
    {
      font = [NSFont fontWithName: fontName size: fontSize];
    }
  if (font == nil)
    {
      font = [NSFont userFixedPitchFontOfSize: fontSize];
    }

  return font;
}

+ (NSFont *) defaultEditorBoldFont
{
  NSFont * font = [self defaultEditorFont];

  return [[NSFontManager sharedFontManager] convertFont: font
                                            toHaveTrait: NSBoldFontMask];
}

+ (NSFont *) defaultEditorItalicFont
{
  NSFont * font = [self defaultEditorFont];

  return [[NSFontManager sharedFontManager] convertFont: font
                                            toHaveTrait: NSItalicFontMask];
}

+ (NSFont *) defaultEditorBoldItalicFont
{
  NSFont * font = [self defaultEditorFont];

  return [[NSFontManager sharedFontManager] convertFont: font
                                            toHaveTrait: NSBoldFontMask |
                                                         NSItalicFontMask];
}

// ---
- (BOOL)becomeFirstResponder
{
  return [editor becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
  return [editor resignFirstResponder];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
  return YES;
}
// ---

- (void) dealloc
{
  TEST_RELEASE(highlighter);

  [super dealloc];
}

- (void)setEditor:(PCEditor *)anEditor
{
  ASSIGN(editor, anEditor);
}

- (void) awakeFromNib
{
/*  NSData * data;
  NSUserDefaults * df = [NSUserDefaults standardUserDefaults];

  drawCrosshairs = [df boolForKey: @"DrawCrosshairs"];
  if (drawCrosshairs)
    {
      if ((data = [df dataForKey: @"CrosshairColor"]) == nil ||
        (crosshairColor = [NSUnarchiver unarchiveObjectWithData: data]) == nil)
        {
          crosshairColor = [NSColor lightGrayColor];
        }
      [crosshairColor retain];
    }

  guides = [NSMutableArray new];*/
}

- (void)drawRect:(NSRect)r
{
  NSEnumerator *e;
  NSRange      drawnRange;

  drawnRange = [[self layoutManager] 
    glyphRangeForBoundingRect:r
	      inTextContainer:[self textContainer]];
  [highlighter highlightRange:drawnRange];

  [super drawRect: r];
}

- (void)createSyntaxHighlighterForFileType:(NSString *)fileType
{
  ASSIGN(highlighter, [[[SyntaxHighlighter alloc]
    initWithFileType: fileType textStorage: [self textStorage]]
    autorelease]);
//  [highlighter highlightRange: NSMakeRange(0, [[self string] length])];
}

- (void)insertText:text
{
  if ([text isKindOfClass: [NSString class]])
    {
      NSString * string = text;

      if ([string isEqualToString: @"\n"])
        {
          if ([[NSUserDefaults standardUserDefaults]
            boolForKey: @"ReturnDoesAutoindent"])
            {
              int offset = ComputeIndentingOffset([self string],
                [self selectedRange].location);
              char * buf;

              buf = (char *) malloc((offset + 2) * sizeof(unichar));
              buf[0] = '\n';
              memset(&buf[1], ' ', offset);
              buf[offset+1] = '\0';

              [super insertText: [NSString stringWithCString: buf]];
              free(buf);
            }
          else
            {
              [super insertText: text];
            }
        }
      else if ([string isEqualToString: @"\t"])
        {
          switch ([[NSUserDefaults standardUserDefaults]
            integerForKey: @"TabConversion"])
            {
            case 0:  // no conversion
              [super insertText: text];
              break;
            case 1:  // 2 spaces
              [super insertText: @"  "];
              break;
            case 2:  // 4 spaces
              [super insertText: @"    "];
              break;
            case 3:  // 8 spaces
              [super insertText: @"        "];
              break;
            case 4:  // aligned to tab boundaries of 2 spaces long tabs
              [self insertSpaceFillAlignedAtTabsOfSize: 2];
              break;
            case 5:  // aligned to tab boundaries of 4 spaces long tabs
              [self insertSpaceFillAlignedAtTabsOfSize: 4];
              break;
            case 6:  // aligned to tab boundaries of 8 spaces long tabs
              [self insertSpaceFillAlignedAtTabsOfSize: 8];
              break; 
            }
        }
      else
        {
          [super insertText: text];
        }
    }
  else
    {
      [super insertText: text];
    }
}

/* This extra change tracking is required in order to inform the document
 * that the text is changing _before_ it actually changes. This is required
 * so that the document can un-highlight any highlit characters before the
 * change occurs and after the change recompute any new highlighting.
 */
- (void)keyDown:(NSEvent *)ev
{
//  [editorDocument editorTextViewWillPressKey: self];
  [super keyDown:ev];
//  [editorDocument editorTextViewDidPressKey: self];
}

- (void)paste:sender
{
//  [editorDocument editorTextViewWillPressKey: self];
  [super paste:sender];
//  [editorDocument editorTextViewDidPressKey: self];
}

- (void)mouseDown:(NSEvent *)ev
{
  [super mouseDown:ev];
}

- (NSRect)selectionRect
{
  return _insertionPointRect;
}

@end
