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

@interface PCEditor (InitUI)

- (void)_initUI;

@end

@implementation PCEditor (InitUI)

- (void)_initUI
{
  NSScrollView *scrollView;
  unsigned int style = NSTitledWindowMask
                       | NSClosableWindowMask
                       | NSMiniaturizableWindowMask
                       | NSResizableWindowMask;

  NSRect rect = NSMakeRect(100,100,512,320);

  window = [[NSWindow alloc] initWithContentRect:rect
                                       styleMask:style
                                       backing:NSBackingStoreBuffered
                                       defer:YES];

  [window setReleasedWhenClosed:NO];
  [window setMinSize:NSMakeSize(512,320)];

  view = [[PCEditorView alloc] initWithFrame:NSMakeRect(0,0,498,306)];

  [view setMinSize: NSMakeSize (0, 0)];
  [view setMaxSize:NSMakeSize(1e7, 1e7)];
  [view setRichText:NO];
  [view setEditable:YES];
  [view setSelectable:YES];
  [view setVerticallyResizable:YES];
  [view setHorizontallyResizable:NO];
  [view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [view setBackgroundColor:[NSColor whiteColor]];
  [[view textContainer] setContainerSize:
                              NSMakeSize ([view frame].size.width,1e7)];
  [[view textContainer] setWidthTracksTextView:YES];

  scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect (-1,-1,514,322)];
  [scrollView setDocumentView:view];

  [[view textContainer] setContainerSize:NSMakeSize([scrollView contentSize].width,1e7)];

  [scrollView setHasHorizontalScroller: YES];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setBorderType: NSBezelBorder];
  [scrollView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

  [window setContentView:scrollView];
  RELEASE(scrollView);
}

@end

@implementation PCEditor

- (id)initWithPath:(NSString*)file
{
    if((self = [super init]))
    {
        NSString *text = [NSString stringWithContentsOfFile:file];

        // Should take that from preferences!
	isEmbedded = NO;

        [self _initUI];

	[window setTitle:file];
        [view setText:text];

	path = [file copy];
    }
    return self;
}

- (void)dealloc
{
    RELEASE(window);
    RELEASE(view);
    RELEASE(path);

    [super dealloc];
}

- (void)setDelegate:(id)aDelegate
{
    delegate = aDelegate;
}

- (id)delegate
{
    return delegate;
}

- (NSWindow *)editorWindow
{
    return window;
}

- (void)setEmbedded:(BOOL)yn
{
    isEmbedded = yn;
}

- (BOOL)isEmbedded
{
    return isEmbedded;
}

- (void)show
{
    if( isEmbedded == NO )
    {
	[window makeKeyAndOrderFront:self];
    }
    else
    {
    }
}

- (void)close
{
    NSLog(@"Closing editor for file %@",path);
}

- (void)windowWillClose:(NSNotification *)aNotif
{
    if( [[aNotif object] isEqual:window] )
    {
    }
}

@end
