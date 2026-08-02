/*
   GNUstep ProjectCenter - line number ruler for the editor.
*/

#import "PCLineNumberRulerView.h"
#import "PCEditorView.h"
#import "PCEditor.h"

#import <ProjectCenter/PCProject.h>
#import <ProjectCenter/PCProjectManager.h>

@implementation PCLineNumberRulerView

- (id)initWithScrollView:(NSScrollView *)scrollView textView:(PCEditorView *)textView
{
  if ((self = [super initWithScrollView:scrollView
                            orientation:NSVerticalRuler]) != nil)
    {
      NSFont *font;

      _textView = textView;
      font = [NSFont userFixedPitchFontOfSize:10.0];
      _attributes = [[NSDictionary alloc]
        initWithObjectsAndKeys:
          font, NSFontAttributeName,
          [NSColor darkGrayColor], NSForegroundColorAttributeName,
          nil];
      _breakpoints = [[NSMutableSet alloc] init];

      [self setClientView:textView];
      [self setRuleThickness:40.0];
      [self _loadBreakpoints];

      [[[scrollView contentView] superview] setPostsFrameChangedNotifications:YES];
      [[scrollView contentView] setPostsBoundsChangedNotifications:YES];
      [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(invalidateLineNumbers:)
               name:NSViewBoundsDidChangeNotification
             object:[scrollView contentView]];
      [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(invalidateLineNumbers:)
               name:NSTextDidChangeNotification
             object:textView];
      [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(breakpointDidChange:)
               name:PCProjectBreakpointNotification
             object:nil];
    }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_attributes release];
  [_breakpoints release];
  [super dealloc];
}

- (NSString *)_filePath
{
  id editor;

  editor = [_textView editor];
  if (editor != nil && [editor respondsToSelector:@selector(path)])
    {
      return [editor path];
    }

  return nil;
}

- (PCProject *)_project
{
  id editor;
  id editorManager;

  editor = [_textView editor];
  if (editor != nil && [editor respondsToSelector:@selector(editorManager)])
    {
      editorManager = [editor editorManager];
      if (editorManager != nil &&
	  [editorManager respondsToSelector:@selector(projectManager)])
	{
	  return [[editorManager projectManager] activeProject];
	}
    }

  return nil;
}

- (void)_loadBreakpoints
{
  NSArray *items;
  NSString *path;
  PCProject *project;
  NSEnumerator *e;
  NSDictionary *dict;

  path = [self _filePath];
  project = [self _project];
  if (path == nil || project == nil)
    {
      return;
    }

  items = [project breakpoints];
  e = [items objectEnumerator];
  while ((dict = [e nextObject]) != nil)
    {
      if ([[project absolutePathForBreakpointFile:[dict objectForKey:@"File"]]
	    isEqualToString:path])
        {
          NSNumber *line = [dict objectForKey:@"Line"];
          if (line != nil)
            {
              [_breakpoints addObject:line];
            }
        }
    }
}

- (void)_setStoredBreakpointAtLine:(NSUInteger)line enabled:(BOOL)enabled
{
  NSString *path;
  PCProject *project;

  path = [self _filePath];
  project = [self _project];
  if (path == nil || project == nil || line == 0)
    {
      return;
    }

  [project setBreakpointForFile:path line:line enabled:enabled];
}

- (NSUInteger)_lineNumberForCharacterIndex:(NSUInteger)index
{
  NSString *string;
  NSUInteger i;
  NSUInteger lineNumber;
  NSUInteger length;

  string = [_textView string];
  length = [string length];
  if (index > length)
    {
      index = length;
    }

  lineNumber = 1;
  for (i = 0; i < index; i++)
    {
      if ([string characterAtIndex:i] == '\n')
        {
          lineNumber++;
        }
    }

  return lineNumber;
}

- (NSUInteger)_lineCount
{
  NSString *string;
  NSUInteger i;
  NSUInteger count;

  string = [_textView string];
  count = 1;
  for (i = 0; i < [string length]; i++)
    {
      if ([string characterAtIndex:i] == '\n')
        {
          count++;
        }
    }

  return count;
}

- (void)_updateRuleThickness
{
  NSUInteger lineCount;
  NSUInteger digits;
  CGFloat width;

  lineCount = [self _lineCount];
  digits = 1;
  while (lineCount >= 10)
    {
      digits++;
      lineCount /= 10;
    }

  width = 16.0 + digits * [[NSFont userFixedPitchFontOfSize:10.0] widthOfString:@"8"];
  if (width < 40.0)
    {
      width = 40.0;
    }

  if ([self ruleThickness] != width)
    {
      [self setRuleThickness:width];
    }
}

- (void)invalidateLineNumbers:(NSNotification *)notification
{
  [self _updateRuleThickness];
  [self setNeedsDisplay:YES];
}

- (void)breakpointDidChange:(NSNotification *)notification
{
  NSDictionary *info;
  NSString *path;
  NSNumber *line;
  NSNumber *enabled;

  info = [notification object];
  if (![info isKindOfClass:[NSDictionary class]])
    {
      return;
    }

  path = [info objectForKey:@"File"];
  line = [info objectForKey:@"Line"];
  enabled = [info objectForKey:@"Enabled"];
  if (path == nil || line == nil || ![path isEqualToString:[self _filePath]])
    {
      return;
    }

  if (enabled == nil || [enabled boolValue])
    {
      [_breakpoints addObject:line];
    }
  else
    {
      [_breakpoints removeObject:line];
    }

  [self setNeedsDisplay:YES];
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)rect
{
  NSLayoutManager *layoutManager;
  NSTextContainer *textContainer;
  NSString *string;
  NSRange glyphRange;
  NSRange charRange;
  NSUInteger glyphIndex;
  NSUInteger lineNumber;
  NSRect bounds;
  NSRect visibleRect;
  NSSize inset;
  NSRect containerVisibleRect;

  [self _updateRuleThickness];

  bounds = [self bounds];
  [[NSColor controlBackgroundColor] set];
  NSRectFill(bounds);
  [[NSColor grayColor] set];
  NSRectFill(NSMakeRect(NSMaxX(bounds) - 1.0, NSMinY(bounds), 1.0, NSHeight(bounds)));

  layoutManager = [_textView layoutManager];
  textContainer = [_textView textContainer];
  string = [_textView string];
  inset = [_textView textContainerInset];
  visibleRect = [_textView visibleRect];
  containerVisibleRect = visibleRect;
  containerVisibleRect.origin.x -= inset.width;
  containerVisibleRect.origin.y -= inset.height;

  glyphRange = [layoutManager glyphRangeForBoundingRect:containerVisibleRect
                                        inTextContainer:textContainer];
  charRange = [layoutManager characterRangeForGlyphRange:glyphRange
                                        actualGlyphRange:NULL];
  lineNumber = [self _lineNumberForCharacterIndex:charRange.location];

  for (glyphIndex = glyphRange.location;
       glyphIndex < NSMaxRange(glyphRange) && glyphIndex < [string length];
       glyphIndex++)
    {
      NSRect glyphRect;
      NSRange lineRange;
      NSString *label;
      NSSize labelSize;
      NSPoint point;
      CGFloat markerY;

      lineRange = [string lineRangeForRange:NSMakeRange(glyphIndex, 0)];
      if (glyphIndex != lineRange.location)
        {
          glyphIndex = NSMaxRange(lineRange) - 1;
          continue;
        }

      glyphRect = [layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)
                                           inTextContainer:textContainer];
      label = [NSString stringWithFormat:@"%lu", (unsigned long)lineNumber];
      labelSize = [label sizeWithAttributes:_attributes];
      point = NSMakePoint(NSMaxX(bounds) - labelSize.width - 5.0,
                          NSMinY(glyphRect) + inset.height - NSMinY(visibleRect));
      [label drawAtPoint:point withAttributes:_attributes];

      markerY = NSMinY(glyphRect) + inset.height - NSMinY(visibleRect);
      if ([_breakpoints containsObject:[NSNumber numberWithUnsignedInteger:lineNumber]])
        {
          NSRect markerRect;

          markerRect = NSMakeRect(5.0, markerY + 2.0, 8.0, 8.0);
          [[NSColor redColor] set];
          NSRectFill(markerRect);
          [[NSColor blackColor] set];
          NSFrameRect(markerRect);
        }

      lineNumber++;
    }
}

- (void)drawRect:(NSRect)rect
{
  [self drawHashMarksAndLabelsInRect:rect];
}

- (NSUInteger)_lineNumberForPoint:(NSPoint)point
{
  NSLayoutManager *layoutManager;
  NSTextContainer *textContainer;
  NSString *string;
  NSRect visibleRect;
  NSSize inset;
  NSPoint containerPoint;
  NSUInteger glyphIndex;
  NSRange charRange;

  string = [_textView string];
  if ([string length] == 0)
    {
      return 1;
    }

  layoutManager = [_textView layoutManager];
  textContainer = [_textView textContainer];
  visibleRect = [_textView visibleRect];
  inset = [_textView textContainerInset];
  containerPoint = NSMakePoint(0.0,
    NSMinY(visibleRect) + point.y - inset.height);

  glyphIndex = [layoutManager glyphIndexForPoint:containerPoint
                                 inTextContainer:textContainer];
  if (glyphIndex >= [string length])
    {
      glyphIndex = [string length] - 1;
    }

  charRange = [layoutManager characterRangeForGlyphRange:NSMakeRange(glyphIndex, 1)
                                        actualGlyphRange:NULL];
  return [self _lineNumberForCharacterIndex:charRange.location];
}

- (void)mouseDown:(NSEvent *)event
{
  NSPoint point;
  NSUInteger line;
  NSNumber *lineNumber;
  NSString *path;
  BOOL enabled;
  BOOL hasBreakpoint;

  point = [self convertPoint:[event locationInWindow] fromView:nil];
  line = [self _lineNumberForPoint:point];
  lineNumber = [NSNumber numberWithUnsignedInteger:line];
  path = [self _filePath];

  if (path == nil)
    {
      return;
    }

  hasBreakpoint = [_breakpoints containsObject:lineNumber];
  if (hasBreakpoint && point.x <= 18.0)
    {
      [_breakpoints removeObject:lineNumber];
      enabled = NO;
    }
  else if (!hasBreakpoint)
    {
      [_breakpoints addObject:lineNumber];
      enabled = YES;
    }
  else
    {
      return;
    }

  [self _setStoredBreakpointAtLine:line enabled:enabled];
  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCProjectBreakpointNotification
                  object:[NSDictionary dictionaryWithObjectsAndKeys:
                    path, @"File",
                    lineNumber, @"Line",
                    [NSNumber numberWithBool:enabled], @"Enabled",
                    nil]];

  [self setNeedsDisplay:YES];
}

@end
