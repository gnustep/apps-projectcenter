/*
   GNUstep ProjectCenter - character ruler for the editor.
*/

#import "PCCharacterRulerView.h"
#import "PCEditorView.h"

@implementation PCCharacterRulerView

- (id)initWithScrollView:(NSScrollView *)scrollView textView:(PCEditorView *)textView
{
  if ((self = [super initWithScrollView:scrollView
                            orientation:NSHorizontalRuler]) != nil)
    {
      NSFont *font;

      _textView = textView;
      font = [NSFont userFixedPitchFontOfSize:10.0];
      _attributes = [[NSDictionary alloc]
        initWithObjectsAndKeys:
          font, NSFontAttributeName,
          [NSColor darkGrayColor], NSForegroundColorAttributeName,
          nil];

      [self setClientView:textView];
      [self setRuleThickness:22.0];

      [[scrollView contentView] setPostsBoundsChangedNotifications:YES];
      [textView setPostsFrameChangedNotifications:YES];
      [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(invalidateCharacterRuler:)
               name:NSViewBoundsDidChangeNotification
             object:[scrollView contentView]];
      [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(invalidateCharacterRuler:)
               name:NSViewFrameDidChangeNotification
             object:textView];
      [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(invalidateCharacterRuler:)
               name:NSTextDidChangeNotification
             object:textView];
    }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  RELEASE(_attributes);
  [super dealloc];
}

- (CGFloat)_characterWidth
{
  CGFloat width;

  width = [[_textView editorFont] widthOfString:@"8"];
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

- (void)invalidateCharacterRuler:(NSNotification *)notification
{
  [self setNeedsDisplay:YES];
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)rect
{
  NSRect bounds;
  NSRect visibleRect;
  NSSize inset;
  CGFloat charWidth;
  CGFloat firstColumn;
  CGFloat lastColumn;
  NSUInteger column;
  NSUInteger startColumn;
  NSUInteger endColumn;
  CGFloat baseline;

  bounds = [self bounds];
  if (NSIsEmptyRect(bounds))
    {
      return;
    }

  [[NSColor controlBackgroundColor] set];
  NSRectFill(bounds);
  [[NSColor grayColor] set];
  NSRectFill(NSMakeRect(NSMinX(bounds), NSMinY(bounds), NSWidth(bounds), 1.0));

  charWidth = [self _characterWidth];
  inset = [_textView textContainerInset];
  visibleRect = [_textView visibleRect];

  firstColumn = floor((NSMinX(visibleRect) - inset.width) / charWidth);
  if (firstColumn < 0.0)
    {
      firstColumn = 0.0;
    }
  lastColumn = ceil((NSMaxX(visibleRect) - inset.width) / charWidth);

  startColumn = (NSUInteger)firstColumn;
  endColumn = (NSUInteger)lastColumn + 1;
  baseline = NSMinY(bounds) + 1.0;

  for (column = startColumn; column <= endColumn; column++)
    {
      CGFloat x;
      CGFloat tickHeight;

      x = inset.width + column * charWidth - NSMinX(visibleRect);
      if (x < NSMinX(bounds) - charWidth || x > NSMaxX(bounds) + charWidth)
        {
          continue;
        }

      if (column % 10 == 0)
        {
          NSString *label;
          NSSize labelSize;

          tickHeight = 9.0;
          if (column > 0)
            {
              label = [NSString stringWithFormat:@"%lu", (unsigned long)column];
              labelSize = [label sizeWithAttributes:_attributes];
              [label drawAtPoint:NSMakePoint(x - labelSize.width / 2.0,
                                             baseline + tickHeight)
                   withAttributes:_attributes];
            }
        }
      else if (column % 5 == 0)
        {
          tickHeight = 7.0;
        }
      else
        {
          tickHeight = 4.0;
        }

      [[NSColor grayColor] set];
      NSRectFill(NSMakeRect(floor(x), baseline, 1.0, tickHeight));
    }
}

- (void)drawRect:(NSRect)rect
{
  [self drawHashMarksAndLabelsInRect:rect];
}

@end
