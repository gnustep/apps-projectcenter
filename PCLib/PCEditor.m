
/* 
 * PCEditor.m created by probert on 2002-01-29 20:37:27 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#import "PCEditor.h"
#import "PCEditorView.h"
#import "PCProjectEditor.h"

NSString *PCEditorDidBecomeKeyNotification=@"PCEditorDidBecomeKeyNotification";
NSString *PCEditorDidResignKeyNotification=@"PCEditorDidResignKeyNotification";

@interface PCEditor (InitUI)

- (void)_initUI;
- (PCEditorView *)_createEditorViewWithFrame:(NSRect)fr;

@end

@implementation PCEditor (InitUI)

- (void)_initUI
{
  NSScrollView *scrollView;
  unsigned int style;
  NSRect       rect;

  /*
   * Creating shared text storage
   */

  _storage = [[NSTextStorage alloc] init];

  /*
   * Creating external view's window
   *
   * FIXME: this still is untested as I <d.ayers@inode.at>
   * haven't found the way to display the external window yet. :-(
   */

  style = NSTitledWindowMask
        | NSClosableWindowMask
        | NSMiniaturizableWindowMask
        | NSResizableWindowMask;
  rect = NSMakeRect(100,100,512,320);

  _window = [[NSWindow alloc] initWithContentRect:rect
                                        styleMask:style
                                        backing:NSBackingStoreBuffered
                                        defer:YES];
  [_window setReleasedWhenClosed:NO];
  [_window setMinSize:NSMakeSize(512,320)];
  rect = [[_window contentView] frame];

  /*
   * Creating external view's scroll view
   */

  scrollView = [[NSScrollView alloc] initWithFrame:rect];
  [scrollView setHasHorizontalScroller:  NO];
  [scrollView setHasVerticalScroller:   YES];
  [scrollView setBorderType:  NSBezelBorder];
  [scrollView setAutoresizingMask: (NSViewWidthSizable|NSViewHeightSizable)];
  rect = [[scrollView contentView] frame];

  /*
   * Creating external view
   */

  _eView = [self _createEditorViewWithFrame:rect];

  /*
   * Setting up external view / scroll view / window
   */

  [scrollView setDocumentView:_eView];
  [_window setContentView:scrollView];
  [_window setDelegate:self];
  [_window makeFirstResponder:_eView];
  RELEASE(scrollView);

  /*
   * Creating internal view
   *
   * The width is actually irrelavent here as the the PCProjectEditor
   * will reset it to the width of the content view if its scroll view.
   * The height should be large as this will be the height it will be
   * will be visible.
   */

  rect = NSMakeRect( 0, 0, 1e7, 1e7);
  _iView = [self _createEditorViewWithFrame:rect];
  RETAIN(_iView);
}

- (PCEditorView *)_createEditorViewWithFrame:(NSRect)fr
{
  PCEditorView    *ev;
  NSTextContainer *tc;
  NSLayoutManager *lm;

  /*
   * setting up the objects needed to manage the view but using the
   * shared textStorage.
   */

  lm = [[NSLayoutManager alloc] init];
  tc = [[NSTextContainer alloc] initWithContainerSize:fr.size];
  [lm addTextContainer:tc];
  RELEASE(tc);

  [_storage addLayoutManager:lm];
  RELEASE(lm);

  ev = [[PCEditorView alloc] initWithFrame:fr
                             textContainer:tc];
  [ev setEditor:self];

  [ev setMinSize: NSMakeSize(  0,   0)];
  [ev setMaxSize: NSMakeSize(1e7, 1e7)];
  [ev setRichText:                 YES];
  [ev setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
  [ev setVerticallyResizable:      YES];
  [ev setHorizontallyResizable:     NO];
  [ev setTextContainerInset:   NSMakeSize( 5, 5)];
  [[ev textContainer] setWidthTracksTextView:YES];

  return AUTORELEASE(ev);
}

@end

@implementation PCEditor

- (id)initWithPath:(NSString*)file
{
  if((self = [super init]))
  {
    NSString            *t;
    NSAttributedString *as;
    NSDictionary       *at;
    NSFont             *ft;

    ft = [NSFont userFixedPitchFontOfSize:0.0];
    at = [NSDictionary dictionaryWithObject:ft forKey:NSFontAttributeName];
    t  = [NSString stringWithContentsOfFile:file];
    as = [[NSAttributedString alloc] initWithString:t attributes:at];

    _isEdited = NO;
    _path = [file copy];

    [self _initUI];

    [_window setTitle:file];
    [_storage setAttributedString:as];
    RELEASE(as);

    [_iView setNeedsDisplay:YES];
    [_eView setNeedsDisplay:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(textDidChange:)
                                          name:NSTextDidChangeNotification
                                          object:_eView];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(textDidChange:)
                                          name:NSTextDidChangeNotification
                                          object:_iView];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  RELEASE(_window);
  RELEASE(_path);

  RELEASE(_iView);
  RELEASE(_storage);

  [super dealloc];
}

- (void)setDelegate:(id)aDelegate
{
  _delegate = aDelegate;
}

- (id)delegate
{
  return _delegate;
}

- (NSWindow *)editorWindow
{
  return _window;
}

- (NSString *)path
{
  return _path;
}

- (void)setIsEdited:(BOOL)yn
{
  [_window setDocumentEdited:yn];
  _isEdited = yn;
}

- (void)showInProjectEditor:(PCProjectEditor *)pe
{
  [pe setEditorView:_iView];
}

- (void)show
{
  [_window makeKeyAndOrderFront:self];
}

- (void)close
{
  if( _isEdited )
  {
    BOOL ret;

    if( [_window isVisible] )
    {
      [_window makeKeyAndOrderFront:self];
    }

    ret = NSRunAlertPanel(@"Edited File!",
                          @"Should '%@' be saved before closing?",
                          @"Yes",@"No",nil,_path);

    if( ret == YES )
    {
      ret = [self saveFile];

      if((ret == NO))
      {
        NSRunAlertPanel(@"Save Failed!",
                        @"Could not save file '%@'!",
                        @"OK",nil,nil,_path);
      }
    }

    [self setIsEdited:NO];
  }

  if( _delegate && [_delegate respondsToSelector:@selector(editorDidClose:)] )
  {
    [_delegate editorDidClose:self];
  }
}

- (BOOL)saveFileIfNeeded
{
  if((_isEdited))
  {
    return [self saveFile];
  }

  return YES;
}

- (BOOL)saveFile
{
  [self setIsEdited:NO];

  // Operate on the text storage!
  return [[_storage string] writeToFile:_path atomically:YES];
}

- (BOOL)revertFile
{
  NSString *text = [NSString stringWithContentsOfFile:_path];
  NSAttributedString *as = [[NSAttributedString alloc] initWithString:text];

  [self setIsEdited:NO];

  // Operate on the text storage!
  [_storage setAttributedString:as];
  RELEASE(as);

  [_iView setNeedsDisplay:YES];
  [_eView setNeedsDisplay:YES];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
  if( [[aNotification object] isEqual:_window] )
  {
    [self close];
  }
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
  if( [[aNotification object] isEqual:_window] )
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:PCEditorDidBecomeKeyNotification object:self];
  }
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
  if( [[aNotification object] isEqual:_window] )
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:PCEditorDidResignKeyNotification object:self];
  }
}

- (void)textDidChange:(NSNotification *)aNotification
{
  [self setIsEdited:YES];
}

@end
