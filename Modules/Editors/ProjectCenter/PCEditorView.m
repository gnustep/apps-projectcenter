/*
    PCEditorView.m

    Implementation of the PCEditorView class for the
    ProjectManager application.

    Copyright (C) 2005-2021 Free Software Foundation
      Saso Kiselkov
      Serg Stoyan
      Riccardo Mottola

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
    Foundation, Inc., 31 Milk Street #960789 Boston, MA 02196 USA
*/

#import "PCEditorView.h"

#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSArchiver.h>
#import <Foundation/NSFileManager.h>

#import <AppKit/PSOperators.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSLayoutManager.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSParagraphStyle.h>
#import <AppKit/NSScrollView.h>

#import <ctype.h>

#import <ProjectCenter/PCProjectManager.h>

#import "PCEditor.h"
#import "SyntaxHighlighter.h"
#import "LineJumper.h"
#import "Modules/Preferences/EditorFSC/PCEditorFSCPrefs.h"

#define SYNTAX_HL_DELAY 0.05
#define EDITOR_TAB_WIDTH 2

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
static int ComputeIndentingOffset(NSString * string, NSUInteger start)
{
  SEL sel = @selector(characterAtIndex:);
  unichar (* charAtIndex)(NSString *, SEL, unsigned int) =
    (unichar (*)(NSString *, SEL, unsigned int))
    [string methodForSelector: sel];
  unichar c;
  int firstCharOffset = -1;
  int offset;
  int startOffsetFromLineStart = -1;

  if ([string length] == 0 || start == 0)
    {
      return 0;
    }
  if (start > [string length])
    {
      start = [string length];
    }

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

  return firstCharOffset >= 0 ? firstCharOffset : 0;

/*  if (firstCharOffset >= 0)
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
    }*/
}

@interface PCEditorView (Private)

- (void)insertSpaceFillAlignedAtTabsOfSize:(unsigned int)tabSize;
- (void)performIndentation;
- (NSUInteger)editorTabWidth;
- (NSUInteger)editorIndentWidth;
- (BOOL)editorUsesTabs;
- (void)loadIndentSettingsIfNeeded;
- (NSString *)clangFormatPathForFilePath:(NSString *)filePath;
- (void)loadIndentSettingsFromClangFormatAtPath:(NSString *)path;
- (NSString *)indentStringForColumnCount:(NSUInteger)columns;
- (NSInteger)leadingWhitespaceLengthOfLineAtIndex:(NSInteger)index
                                       forString:(NSString *)string;
- (NSInteger)indentForLineAtIndex:(NSInteger)index
                        forString:(NSString *)string;
- (NSInteger)indentAfterNewlineAtIndex:(NSInteger)index
                             forString:(NSString *)string;
- (BOOL)lineBeforeIndexIsControlStatement:(NSInteger)index
                                forString:(NSString *)string;
- (NSInteger)lineStartIndexForIndex:(NSInteger)index forString:(NSString *)string;
- (NSInteger)lineEndIndexForIndex:(NSInteger)index forString:(NSString *)string;
- (void)shiftSelectedLinesForward:(BOOL)forward;
- (NSUInteger)indexByMovingSelectionEdge:(NSUInteger)index
                               direction:(NSInteger)direction
                                inString:(NSString *)string;
- (NSRange)selectionRangeWithAnchor:(NSUInteger)anchor
                              point:(NSUInteger)point;
- (NSUInteger)movementOriginForSelection;
- (NSUInteger)movementEndForSelection;
- (void)setSelectionWithAnchor:(NSUInteger)anchor
                         point:(NSUInteger)point;

@end

@implementation PCEditorView (Private)

- (NSUInteger)editorTabWidth
{
  [self loadIndentSettingsIfNeeded];

  return editorTabWidth;
}

- (NSUInteger)editorIndentWidth
{
  [self loadIndentSettingsIfNeeded];

  return editorIndentWidth;
}

- (BOOL)editorUsesTabs
{
  [self loadIndentSettingsIfNeeded];

  return editorUsesTabs;
}

- (void)loadIndentSettingsIfNeeded
{
  NSString *filePath;
  NSString *clangFormatPath;

  if (editorIndentSettingsLoaded)
    {
      return;
    }

  editorIndentSettingsLoaded = YES;
  editorIndentWidth = EDITOR_TAB_WIDTH;
  editorTabWidth = EDITOR_TAB_WIDTH;
  editorUsesTabs = NO;

  filePath = [editor filePath];
  if (filePath == nil)
    {
      return;
    }

  clangFormatPath = [self clangFormatPathForFilePath:filePath];
  if (clangFormatPath != nil)
    {
      [self loadIndentSettingsFromClangFormatAtPath:clangFormatPath];
    }
}

- (NSString *)clangFormatPathForFilePath:(NSString *)filePath
{
  NSFileManager *fm;
  NSString *directory;

  fm = [NSFileManager defaultManager];
  directory = [filePath stringByDeletingLastPathComponent];
  while ([directory length] > 0)
    {
      NSString *candidate;
      NSString *parent;

      candidate = [directory stringByAppendingPathComponent:@".clang-format"];
      if ([fm isReadableFileAtPath:candidate])
	{
	  return candidate;
	}

      parent = [directory stringByDeletingLastPathComponent];
      if ([parent isEqualToString:directory])
	{
	  break;
	}
      directory = parent;
    }

  return nil;
}

- (void)loadIndentSettingsFromClangFormatAtPath:(NSString *)path
{
  NSString *contents;
  NSArray *lines;
  NSEnumerator *e;
  NSString *line;

  contents = [NSString stringWithContentsOfFile:path];
  if (contents == nil)
    {
      return;
    }

  lines = [contents componentsSeparatedByString:@"\n"];
  e = [lines objectEnumerator];
  while ((line = [e nextObject]) != nil)
    {
      NSRange commentRange;
      NSRange separatorRange;
      NSString *key;
      NSString *value;
      NSInteger number;

      commentRange = [line rangeOfString:@"#"];
      if (commentRange.location != NSNotFound)
	{
	  line = [line substringToIndex:commentRange.location];
	}

      separatorRange = [line rangeOfString:@":"];
      if (separatorRange.location == NSNotFound)
	{
	  continue;
	}

      key = [[line substringToIndex:separatorRange.location]
	      stringByTrimmingCharactersInSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      value = [[line substringFromIndex:NSMaxRange(separatorRange)]
		stringByTrimmingCharactersInSet:
		  [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      if ([value hasPrefix:@"\""] && [value hasSuffix:@"\""]
	  && [value length] >= 2)
	{
	  value = [value substringWithRange:NSMakeRange(1, [value length] - 2)];
	}

      number = [value integerValue];
      if ([key isEqualToString:@"IndentWidth"] && number > 0)
	{
	  editorIndentWidth = number;
	}
      else if ([key isEqualToString:@"TabWidth"] && number > 0)
	{
	  editorTabWidth = number;
	}
      else if ([key isEqualToString:@"UseTab"])
	{
	  editorUsesTabs =
	    !([value caseInsensitiveCompare:@"Never"] == NSOrderedSame
	      || [value caseInsensitiveCompare:@"false"] == NSOrderedSame
	      || [value caseInsensitiveCompare:@"No"] == NSOrderedSame);
	}
    }
}

- (NSString *)indentStringForColumnCount:(NSUInteger)columns
{
  NSMutableString *indentString;
  NSUInteger tabWidth;

  indentString = [NSMutableString string];
  tabWidth = [self editorTabWidth];
  if (tabWidth == 0)
    {
      tabWidth = EDITOR_TAB_WIDTH;
    }

  if ([self editorUsesTabs])
    {
      while (columns >= tabWidth)
	{
	  [indentString appendString:@"\t"];
	  columns -= tabWidth;
	}
    }
  while (columns > 0)
    {
      [indentString appendString:@" "];
      columns--;
    }

  return indentString;
}

- (NSInteger)leadingWhitespaceLengthOfLineAtIndex:(NSInteger)index
                                       forString:(NSString *)string
{
  NSInteger line_start;
  NSInteger offset;
  NSInteger string_length;

  line_start = [self lineStartIndexForIndex:index forString:string];
  string_length = [string length];

  for (offset = line_start; offset < string_length; offset++)
    {
      unichar c = [string characterAtIndex:offset];

      if (c == '\n' || !isspace(c))
	{
	  break;
	}
    }

  return offset - line_start;
}

- (NSInteger)indentForLineAtIndex:(NSInteger)index
                        forString:(NSString *)string
{
  NSInteger offset;
  NSInteger brace_level = 0;
  NSInteger string_length = [string length];

  if (string_length == 0)
    {
      return 0;
    }

  if (index <= 0)
    {
      return 0;
    }

  if (index > string_length)
    {
      index = string_length;
    }

  for (offset = index - 1; offset >= 0; offset--)
    {
      unichar c = [string characterAtIndex:offset];

      if (c == '}')
	{
	  brace_level++;
	}
      else if (c == '{')
	{
	  if (brace_level == 0)
	    {
	      NSInteger indent;
	      NSInteger line_start;
	      NSInteger cur_line_start;

	      indent = [self leadingWhitespaceLengthOfLineAtIndex:offset
							forString:string];
	      line_start = [self lineStartIndexForIndex:offset
					     forString:string];
	      cur_line_start = [self lineStartIndexForIndex:index
						 forString:string];

	      if (line_start == cur_line_start)
		{
		  return indent;
		}

	      return indent + [self editorIndentWidth];
	    }
	  else
	    {
	      brace_level--;
	    }
	}
    }

  return ComputeIndentingOffset(string, index);
}

- (NSInteger)indentAfterNewlineAtIndex:(NSInteger)index
                             forString:(NSString *)string
{
  NSInteger offset;

  offset = [self indentForLineAtIndex:index forString:string];
  if (index > 0 && index <= [string length]
      && [string characterAtIndex:index - 1] == '{')
    {
      offset += [self editorIndentWidth];
    }
  else if ([self lineBeforeIndexIsControlStatement:index forString:string])
    {
      offset += [self editorIndentWidth];
    }

  return offset;
}

- (BOOL)lineBeforeIndexIsControlStatement:(NSInteger)index
                                forString:(NSString *)string
{
  NSArray *keywords;
  NSInteger line_start;
  NSInteger line_end;
  NSInteger string_length;
  NSInteger target_index;
  NSString *line;
  NSString *keyword;
  NSEnumerator *e;

  string_length = [string length];
  if (string_length == 0 || index <= 0)
    {
      return NO;
    }

  if (index > string_length)
    {
      index = string_length;
    }

  target_index = index - 1;
  if (target_index < 0)
    {
      return NO;
    }

  line_start = [self lineStartIndexForIndex:target_index forString:string];
  line_end = [self lineEndIndexForIndex:target_index forString:string];
  if (index < line_end)
    {
      line_end = index;
    }
  if (line_end <= line_start)
    {
      return NO;
    }

  line = [[string substringWithRange:NSMakeRange(line_start,
						line_end - line_start)]
	   stringByTrimmingCharactersInSet:
	     [NSCharacterSet whitespaceCharacterSet]];
  if ([line length] == 0 || [line hasSuffix:@";"] || [line hasSuffix:@"{"])
    {
      return NO;
    }

  keywords = [NSArray arrayWithObjects:@"if", @"else", @"while", @"for",
				      @"switch", @"do", @"@try", @"@catch",
				      @"@finally", @"@synchronized", nil];
  e = [keywords objectEnumerator];
  while ((keyword = [e nextObject]) != nil)
    {
      NSUInteger length = [keyword length];

      if ([line isEqualToString:keyword])
	{
	  return YES;
	}
      if ([line hasPrefix:[keyword stringByAppendingString:@" "]])
	{
	  return YES;
	}
      if ([line length] > length
	  && [line hasPrefix:keyword]
	  && [line characterAtIndex:length] == '(')
	{
	  return YES;
	}
    }

  return NO;
}

- (void)shiftSelectedLinesForward:(BOOL)forward
{
  NSString *string;
  NSRange selected_range;
  NSUInteger line_start;
  NSUInteger line_end;
  NSUInteger contents_end;
  NSUInteger edit_end_index;
  NSRange edit_range;
  NSMutableString *replacement;
  NSUInteger cursor;
  NSUInteger tab_width;

  selected_range = [self selectedRange];
  if (selected_range.length == 0)
    {
      if (forward)
	{
	  string = [self string];
	  if ([string length] == 0)
	    {
	      [self insertSpaceFillAlignedAtTabsOfSize:[self editorTabWidth]];
	    }
	  else
	    {
	      [self performIndentation];
	    }
	}
      return;
    }

  string = [self string];
  if ([string length] == 0)
    {
      return;
    }

  [string getLineStart:&line_start
		   end:NULL
	   contentsEnd:NULL
	      forRange:NSMakeRange(selected_range.location, 0)];

  edit_end_index = NSMaxRange(selected_range);
  if (edit_end_index > selected_range.location
      && edit_end_index <= [string length]
      && [string characterAtIndex:edit_end_index - 1] == '\n')
    {
      edit_end_index--;
    }
  if (edit_end_index > [string length])
    {
      edit_end_index = [string length];
    }

  [string getLineStart:NULL
		   end:&line_end
	   contentsEnd:NULL
	      forRange:NSMakeRange(edit_end_index, 0)];
  edit_range = NSMakeRange(line_start, line_end - line_start);
  replacement = [[NSMutableString alloc]
		  initWithCapacity:edit_range.length + [self editorIndentWidth]];
  tab_width = [self editorIndentWidth];

  cursor = line_start;
  while (cursor < line_end)
    {
      NSUInteger next_line_start;
      NSUInteger line_length;

      [string getLineStart:NULL
		       end:&next_line_start
	       contentsEnd:&contents_end
		  forRange:NSMakeRange(cursor, 0)];
      if (next_line_start <= cursor)
	{
	  break;
	}
      line_length = next_line_start - cursor;

      if (forward)
	{
	  [replacement appendString:[self indentStringForColumnCount:tab_width]];
	  [replacement appendString:
			 [string substringWithRange:NSMakeRange(cursor,
							       line_length)]];
	}
      else
	{
	  NSUInteger remove_count;

	  remove_count = 0;
	  if (cursor < contents_end
	      && [string characterAtIndex:cursor] == '\t')
	    {
	      remove_count = 1;
	    }
	  else
	    {
	      while (remove_count < tab_width
		     && cursor + remove_count < contents_end
		     && [string characterAtIndex:cursor + remove_count] == ' ')
		{
		  remove_count++;
		}
	    }

	  [replacement appendString:
			 [string substringWithRange:
				   NSMakeRange(cursor + remove_count,
					       line_length - remove_count)]];
	}

      cursor = next_line_start;
    }

  if ([self shouldChangeTextInRange:edit_range replacementString:replacement])
    {
      [[self textStorage] replaceCharactersInRange:edit_range
					withString:replacement];
      [self setSelectedRange:NSMakeRange(line_start, [replacement length])];
    }

  [replacement release];
}

- (NSUInteger)indexByMovingSelectionEdge:(NSUInteger)index
                               direction:(NSInteger)direction
                                inString:(NSString *)string
{
  NSUInteger string_length;
  NSUInteger line_start;
  NSUInteger line_end;
  NSUInteger target_line_start;
  NSUInteger target_contents_end;
  NSUInteger column;

  string_length = [string length];
  if (string_length == 0)
    {
      return 0;
    }

  if (index > string_length)
    {
      index = string_length;
    }

  [string getLineStart:&line_start
		   end:&line_end
	   contentsEnd:NULL
	      forRange:NSMakeRange(index, 0)];
  column = index - line_start;

  if (direction < 0)
    {
      if (line_start == 0)
	{
	  return index;
	}

      [string getLineStart:&target_line_start
		       end:NULL
	       contentsEnd:&target_contents_end
		  forRange:NSMakeRange(line_start - 1, 0)];
    }
  else
    {
      if (line_end >= string_length)
	{
	  return index;
	}

      [string getLineStart:&target_line_start
		       end:NULL
	       contentsEnd:&target_contents_end
		  forRange:NSMakeRange(line_end, 0)];
    }

  if (column > target_contents_end - target_line_start)
    {
      column = target_contents_end - target_line_start;
    }

  return target_line_start + column;
}

- (NSRange)selectionRangeWithAnchor:(NSUInteger)anchor
                              point:(NSUInteger)point
{
  if (point < anchor)
    {
      return NSMakeRange(point, anchor - point);
    }

  return NSMakeRange(anchor, point - anchor);
}

- (NSUInteger)movementOriginForSelection
{
  NSRange range = [self selectedRange];

  if ([self selectionAffinity] == NSSelectionAffinityUpstream)
    {
      return range.location;
    }

  return NSMaxRange(range);
}

- (NSUInteger)movementEndForSelection
{
  NSRange range = [self selectedRange];

  if ([self selectionAffinity] == NSSelectionAffinityDownstream)
    {
      return range.location;
    }

  return NSMaxRange(range);
}

- (void)setSelectionWithAnchor:(NSUInteger)anchor
                         point:(NSUInteger)point
{
  NSSelectionAffinity affinity;
  NSRange range;

  range = [self selectionRangeWithAnchor:anchor point:point];
  affinity = (anchor < point)
    ? NSSelectionAffinityDownstream
    : NSSelectionAffinityUpstream;

  [self setSelectedRange:range affinity:affinity stillSelecting:YES];
  [self scrollRangeToVisible:NSMakeRange(point, 0)];
}

/**
 * Makes the receiver insert as many spaces at the current insertion
 * location as are required to reach the nearest tab-character boundary.
 *
 * @argument tabSize Specifies how many spaces represent one tab.
 */
- (void)insertSpaceFillAlignedAtTabsOfSize:(unsigned int)tabSize
{
  char buf[tabSize];
  NSString * string = [self string];
  unsigned int lineLength;
  unsigned int tabWidth;
  SEL sel = @selector(characterAtIndex:);
  unichar (* charAtIndex)(NSString*, SEL, unsigned int) =
    (unichar (*)(NSString*, SEL, unsigned int))
    [string methodForSelector: sel];
  int i;
  int skip;

  tabWidth = [self editorTabWidth];
  if (tabWidth == 0)
    {
      tabWidth = EDITOR_TAB_WIDTH;
    }

  // computes the column width of the current line
  for (i = [self selectedRange].location - 1;
       i >= 0 && charAtIndex(string, sel, i) != '\n';
       i--)
    {
    }
  for (i++, lineLength = 0;
       i < [self selectedRange].location;
       i++)
    {
      if (charAtIndex(string, sel, i) == '\t')
	{
	  lineLength += tabWidth - (lineLength % tabWidth);
	}
      else
	{
	  lineLength++;
	}
    }

  skip = tabSize - (lineLength % tabSize);
  if (skip == 0)
    {
      skip = tabSize;
    }

  if ([self editorUsesTabs] && skip == tabSize)
    {
      [super insertText:@"\t"];
    }
  else
    {
      memset(buf, ' ', skip);
      [super insertText: [NSString stringWithCString: buf length: skip]];
    }
}

// Go backward to first '\n' char or start of file
- (NSInteger)lineStartIndexForIndex:(NSInteger)index forString:(NSString *)string
{
  NSInteger line_start;
  NSInteger string_length = [string length];

  if (string_length == 0)
    {
      return 0;
    }
  if (index >= string_length)
    {
      index = string_length - 1;
    }
  if (index < 0)
    {
      return 0;
    }

  // Get line start index moving from index backwards
  for (line_start = index;line_start > 0;line_start--)
    {
      if ([string characterAtIndex:line_start] == '\n' &&
	  line_start != index)
	{
	  line_start++;
	  break;
	}
    }

  return line_start > index ? index : line_start;
}

- (NSInteger)lineEndIndexForIndex:(NSInteger)index forString:(NSString *)string
{
  NSInteger line_end;
  NSInteger string_length = [string length];

  if (string_length == 0)
    {
      return 0;
    }
  if (index >= string_length)
    {
      index = string_length - 1;
    }
  if (index < 0)
    {
      return 0;
    }

  // Get line start index moving from index backwards
  for (line_end = index;line_end < string_length;line_end++)
    {
      if ([string characterAtIndex:line_end] == '\n')
	{
	  break;
	}
    }

  return line_end < string_length ? line_end : string_length;
}

- (NSInteger)previousLineStartIndexForIndex:(NSInteger)index forString:(NSString *)string
{
  NSInteger cur_line_start;
  NSInteger prev_line_start;

  cur_line_start = [self lineStartIndexForIndex:index forString:string];
  if (cur_line_start == 0)
    {
      return 0;
    }
  prev_line_start = [self lineStartIndexForIndex:cur_line_start-1
 				       forString:string];

  return prev_line_start;
}

- (NSInteger)nextLineStartIndexForIndex:(NSInteger)index forString:(NSString *)string
{
  NSInteger cur_line_end;
  NSInteger next_line_start;
  NSInteger string_length = [string length];

  cur_line_end = [self lineEndIndexForIndex:index forString:string];
  next_line_start = cur_line_end + 1;

  if (next_line_start < string_length)
    {
      return next_line_start;
    }
  else
    {
      return string_length;
    }
}

- (unichar)firstCharOfLineForIndex:(NSInteger)index forString:(NSString *)string
{
  NSInteger line_start = [self lineStartIndexForIndex:index forString:string];
  NSInteger i;
  unichar c;
  NSInteger string_length = [string length];

  c = 0;
  if (string_length == 0 || line_start >= string_length)
    {
      return c;
    }
  // Get leading whitespaces range
  for (i = line_start; i < string_length; i++)
    {
      c = [string characterAtIndex:i];
      if (c == '\n' || !isspace(c))
	{
	  break;
	}
    }

  return c;
}

- (unichar)firstCharOfPrevLineForIndex:(NSInteger)index forString:(NSString *)string
{
  NSInteger line_start = [self previousLineStartIndexForIndex:index 
						   forString:string];

  return [self firstCharOfLineForIndex:line_start forString:string];
}

- (void)performIndentation
{
  NSString  *string = [self string];
  NSInteger location;
  NSInteger line_start;
  NSInteger offset;
  NSInteger string_length;
  unichar   c, clfc;
  NSRange   wsRange = NSMakeRange(0, 0);
  NSMutableString *indentString;
  NSCharacterSet  *wsCharSet = [NSCharacterSet whitespaceCharacterSet];
  NSInteger tabWidth;
//  int point;

  location = [self selectedRange].location;
  string_length = [string length];
  tabWidth = [self editorIndentWidth];

//  point = [self nextLineStartIndexForIndex:location forString:string];
//  [self setSelectedRange:NSMakeRange(point, 0)];

  clfc = [self firstCharOfLineForIndex:location forString:string];

  // Get leading whitespaces range
  line_start = [self lineStartIndexForIndex:location forString:string];
  for (offset = line_start; offset < string_length; offset++)
    {
      c = [string characterAtIndex:offset];
      if (c == '\n' || ![wsCharSet characterIsMember:c])
	{
	  wsRange = NSMakeRange(line_start, offset-line_start);
	  break;
	}
    }
  if (offset >= string_length)
    {
      wsRange = NSMakeRange(line_start, string_length - line_start);
    }

  // Get indent
  line_start = [self previousLineStartIndexForIndex:location forString:string];
  for (offset = line_start; offset < string_length; offset++)
    {
      c = [string characterAtIndex:offset];
      if (c == '\n' || ![wsCharSet characterIsMember:c])
	{
	  offset = offset - line_start;
	  break;
	}
    }
  if (string_length == 0 || offset >= string_length)
    {
      offset = 0;
    }

  offset = [self indentForLineAtIndex:location forString:string];
  if (clfc == '}')
    {
      offset -= tabWidth;
    }
  else if (clfc == '{'
	   && [self lineBeforeIndexIsControlStatement:location
					   forString:string])
    {
      offset += tabWidth;
    }

  if (offset < 0)
    {
      offset = 0;
    }

  // Get offset from BOL of previous line
//  offset = ComputeIndentingOffset([self string], line_start-1);
  // Replace current line whitespaces with new ones
  indentString = [[self indentStringForColumnCount:offset] mutableCopy];

  if ([self shouldChangeTextInRange:wsRange
		  replacementString:indentString])
    [[self textStorage] replaceCharactersInRange:wsRange 
				      withString:indentString];

/*  if (location > line_start + offset)
    {
      point = location - offset;
    }
  else
    {
      point = location;
    }
  [self setSelectedRange:NSMakeRange(point, 0)];*/

  [indentString release];
}

@end

@implementation PCEditorView

- (void)_updateScrollViewNotifications
{
  NSScrollView *scrollView;
  NSClipView *clipView;

  [[NSNotificationCenter defaultCenter] removeObserver:self
						  name:NSViewBoundsDidChangeNotification
						object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
						  name:NSViewFrameDidChangeNotification
						object:self];

  scrollView = [self enclosingScrollView];
  clipView = [scrollView contentView];
  if (clipView != nil)
    {
      [clipView setPostsBoundsChangedNotifications:YES];
      [self setPostsFrameChangedNotifications:YES];
      [[NSNotificationCenter defaultCenter]
	addObserver:self
	   selector:@selector(invalidateVisibleText:)
	       name:NSViewBoundsDidChangeNotification
	     object:clipView];
      [[NSNotificationCenter defaultCenter]
	addObserver:self
	   selector:@selector(invalidateVisibleText:)
	       name:NSViewFrameDidChangeNotification
	     object:self];
    }
}

- (void)viewDidMoveToSuperview
{
  [super viewDidMoveToSuperview];
  [self _updateScrollViewNotifications];
}

+ (NSFont *)defaultEditorFont
{
  NSFont         *font = nil;

  font = [NSFont userFixedPitchFontOfSize:0];
  return font;
}

+ (NSFont *)defaultEditorBoldFont
{
  NSFont *font = [self defaultEditorFont];

  return [[NSFontManager sharedFontManager] convertFont:font
                                            toHaveTrait:NSBoldFontMask];
}

+ (NSFont *)defaultEditorItalicFont
{
  NSFont *font = [self defaultEditorFont];

  return [[NSFontManager sharedFontManager] convertFont:font
                                            toHaveTrait:NSItalicFontMask];
}

+ (NSFont *)defaultEditorBoldItalicFont
{
  NSFont *font = [self defaultEditorFont];

  return [[NSFontManager sharedFontManager] convertFont:font
                                            toHaveTrait:NSBoldFontMask |
                                                        NSItalicFontMask];
}

- (NSFont *)editorFont
{
  id <PCPreferences> prefs;
  NSString          *fontName;
  CGFloat            fontSize;
  NSFont            *font = nil;

  prefs = [[[editor editorManager] projectManager] prefController];

  fontName = [prefs stringForKey:EditorTextFont];
  fontSize = [prefs floatForKey:EditorTextFontSize];

  font = [NSFont fontWithName:fontName size:fontSize];
  if (font == nil)
    font = [NSFont userFixedPitchFontOfSize:0]; 

  return font;
}

- (NSFont *)editorBoldFont
{
  NSFont *font = [self editorFont];

  return [[NSFontManager sharedFontManager] convertFont:font
                                            toHaveTrait:NSBoldFontMask];
}

- (NSFont *)editorItalicFont
{
  NSFont *font = [self editorFont];

  return [[NSFontManager sharedFontManager] convertFont:font
                                            toHaveTrait:NSItalicFontMask];
}

- (NSFont *)editorBoldItalicFont
{
  NSFont *font = [self editorFont];

  return [[NSFontManager sharedFontManager] convertFont:font
                                            toHaveTrait:NSBoldFontMask |
                                                        NSItalicFontMask];
}

- (CGFloat)editorCharacterWidth
{
  CGFloat width;

  width = [[self editorFont] widthOfString:@"8"];
  if (width <= 0.0)
    {
      width = [[NSFont userFixedPitchFontOfSize:0.0] widthOfString:@"8"];
    }
  if (width <= 0.0)
    {
      width = 8.0;
    }

  return width;
}

- (NSParagraphStyle *)editorParagraphStyle
{
  NSMutableParagraphStyle *style;

  style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy]
            autorelease];
  [style setTabStops:[NSArray array]];
  [style setDefaultTabInterval:[self editorCharacterWidth] *
                                [self editorTabWidth]];

  return style;
}

- (void)updateEditorParagraphStyle
{
  NSParagraphStyle *style;
  NSMutableDictionary *typingAttributes;
  NSTextStorage *storage;
  NSUInteger length;

  style = [self editorParagraphStyle];
  [self setDefaultParagraphStyle:style];

  typingAttributes = [[[self typingAttributes] mutableCopy] autorelease];
  if (typingAttributes == nil)
    {
      typingAttributes = [NSMutableDictionary dictionary];
    }
  [typingAttributes setObject:style forKey:NSParagraphStyleAttributeName];
  [self setTypingAttributes:typingAttributes];

  storage = [self textStorage];
  length = [storage length];
  if (length > 0)
    {
      [storage addAttribute:NSParagraphStyleAttributeName
                      value:style
                      range:NSMakeRange(0, length)];
    }
}

// ---
- (BOOL)becomeFirstResponder
{
  return [editor becomeFirstResponder:self];
}

- (BOOL)resignFirstResponder
{
  return [editor resignFirstResponder:self];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
  return YES;
}
// ---

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  TEST_RELEASE(highlighter);

  [super dealloc];
}

- (void)setEditor:(NSObject <CodeEditor> *)anEditor
{
  editor = (PCEditor *)anEditor;
}

- (NSObject <CodeEditor> *)editor
{
  return editor;
}

- (void)drawRect:(NSRect)r
{
  if (highlighter)
    {
      NSRange drawnRange;
      NSValue *timerInfo;

      drawnRange = [[self layoutManager] 
	glyphRangeForBoundingRect:r inTextContainer:[self textContainer]];
      drawnRange = [[self layoutManager] characterRangeForGlyphRange:drawnRange
                                                    actualGlyphRange:NULL];

      timerInfo = [NSValue valueWithRange:drawnRange];

      if (nil != hlTimer)
	{
	  [hlTimer invalidate];
	  hlTimer = nil;
	}

      hlTimer = [NSTimer scheduledTimerWithTimeInterval:SYNTAX_HL_DELAY
						 target:self
					       selector:@selector(highlightRangeFromTimer:)
					       userInfo:timerInfo
						repeats:NO];
    }

  [super drawRect:r];
}

- (void)invalidateVisibleText:(NSNotification *)notification
{
  [self setNeedsDisplayInRect:[self visibleRect]];
}

- (void)highlightRangeFromTimer:(NSTimer *)t
{
  NSRange range;

  range = [(NSValue *)[t userInfo] rangeValue];
  hlTimer = nil;
  [highlighter highlightRange:range];
}

- (void)createSyntaxHighlighterForFileType:(NSString *)fileType
{
  ASSIGN(highlighter, 
	 [[[SyntaxHighlighter alloc] initWithFileType:fileType
					  textStorage:[self textStorage]]
					  autorelease]);
  [highlighter setNormalFont: [self editorFont]];
  [highlighter setBoldFont: [self editorBoldFont]];
  [highlighter setItalicFont: [self editorItalicFont]];
  [highlighter setBoldItalicFont: [self editorBoldItalicFont]];
}

- (void) cancelOperation: (id)sender
{
  // ignore ESC char
}

- (void) insertNewline: (id)sender
{
  NSInteger location = [self selectedRange].location;
  int  offset = [self indentAfterNewlineAtIndex:location
                                      forString:[self string]];
  NSMutableString *replacement;

  replacement = [NSMutableString stringWithString:@"\n"];
  [replacement appendString:[self indentStringForColumnCount:offset]];
  [self insertText:replacement];
}

- (void) insertTab: (id)sender
{
  [self shiftSelectedLinesForward:YES];
}

- (void) insertBacktab: (id)sender
{
  [self shiftSelectedLinesForward:NO];
}

- (void)moveUpAndModifySelection:(id)sender
{
  NSString *string;
  NSUInteger anchor;
  NSUInteger point;

  string = [self string];
  anchor = [self movementEndForSelection];
  point = [self indexByMovingSelectionEdge:[self movementOriginForSelection]
				 direction:-1
				  inString:string];
  [self setSelectionWithAnchor:anchor point:point];
}

- (void)moveDownAndModifySelection:(id)sender
{
  NSString *string;
  NSUInteger anchor;
  NSUInteger point;

  string = [self string];
  anchor = [self movementEndForSelection];
  point = [self indexByMovingSelectionEdge:[self movementOriginForSelection]
				 direction:1
				  inString:string];
  [self setSelectionWithAnchor:anchor point:point];
}

- (void)moveBackwardAndModifySelection:(id)sender
{
  NSUInteger anchor;
  NSUInteger point;

  anchor = [self movementEndForSelection];
  point = [self movementOriginForSelection];
  if (point > 0)
    {
      point--;
    }

  [self setSelectionWithAnchor:anchor point:point];
}

- (void)moveForwardAndModifySelection:(id)sender
{
  NSUInteger anchor;
  NSUInteger point;
  NSUInteger length;

  anchor = [self movementEndForSelection];
  point = [self movementOriginForSelection];
  length = [[self string] length];
  if (point < length)
    {
      point++;
    }

  [self setSelectionWithAnchor:anchor point:point];
}

- (void)moveLeftAndModifySelection:(id)sender
{
  [self moveBackwardAndModifySelection:sender];
}

- (void)moveRightAndModifySelection:(id)sender
{
  [self moveForwardAndModifySelection:sender];
}

/* This extra change tracking is required in order to inform the document
 * that the text is changing _before_ it actually changes. This is required
 * so that the document can un-highlight any highlit characters before the
 * change occurs and after the change recompute any new highlighting.
 */
- (void)keyDown:(NSEvent *)ev
{
  [editor editorTextViewWillPressKey:self];
  [super keyDown:ev];
  [editor editorTextViewDidPressKey:self];
}

- (void)paste:sender
{
  [editor editorTextViewWillPressKey:self];
  [super paste:sender];
  [editor editorTextViewDidPressKey:self];
}

- (void)mouseDown:(NSEvent *)ev
{
  [editor editorTextViewWillPressKey:self];
  [super mouseDown:ev];
  [editor editorTextViewDidPressKey:self];
}

- (NSRect)selectionRect
{
  return _insertionPointRect;
}

- (BOOL)usesFindPanel
{
  return YES;
}

- (void)performGoToLinePanelAction:(id)sender
{
  LineJumper *lj;

  lj = [LineJumper sharedInstance];
  [lj orderFrontLinePanel:self];
}

- (void)goToLineNumber:(NSUInteger)lineNumber
{
  NSUInteger   offset;
  NSUInteger   i;
  NSString     *line;
  NSEnumerator *e;
  NSArray      *lines;
  NSRange      range;

  lines = [[self string] componentsSeparatedByString: @"\n"];
  e = [lines objectEnumerator];

  for (offset = 0, i = 1;
       (line = [e nextObject]) != nil && i < lineNumber;
       i++, offset += [line length] + 1);

  if (line != nil)
    {
      range = NSMakeRange(offset, [line length]);
    }
  else
    {
      range = NSMakeRange([[self string] length], 0);
    }
  [self setSelectedRange:range];
  [self scrollRangeToVisible:range];
}

@end
