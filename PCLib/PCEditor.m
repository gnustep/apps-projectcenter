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

NSString *PCEditorDidBecomeKeyNotification=@"PCEditorDidBecomeKeyNotification";
NSString *PCEditorDidResignKeyNotification=@"PCEditorDidResignKeyNotification";

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

  rect = [[window contentView] frame];
  rect.origin.x = -1;
  rect.origin.y = -1;
  rect.size.width += 2;

  scrollView = [[NSScrollView alloc] initWithFrame:rect];

  rect.origin.x = 0;
  rect.origin.y = 0;
  rect.size.height -= 24;
  rect.size.width -= 4;

  view = [[PCEditorView alloc] initWithFrame:rect];
  [view setEditor:self];

  [view setMinSize: NSMakeSize (0, 0)];
  [view setMaxSize:NSMakeSize(1e7, 1e7)];
  [view setRichText:NO];
  [view setEditable:YES];
  [view setSelectable:YES];
  [view setVerticallyResizable:YES];
  [view setHorizontallyResizable:NO];
  [view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [view setBackgroundColor:[NSColor whiteColor]];
  [[view textContainer] setWidthTracksTextView:YES];

  [scrollView setDocumentView:view];
  RELEASE(view);

  rect.size = NSMakeSize([scrollView contentSize].width,1e7);
  [[view textContainer] setContainerSize:rect.size];

  [scrollView setHasHorizontalScroller: YES];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setBorderType: NSBezelBorder];
  [scrollView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

  [window setContentView:scrollView];
  [window setDelegate:self];
  [window makeFirstResponder:view];

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

	[[NSNotificationCenter defaultCenter] addObserver:self 
	                                      selector:@selector(textDidChange:)
				              name:NSTextDidChangeNotification
				              object:view];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    RELEASE(window);
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

- (NSString *)path
{
    return path;
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
    if( isEmbedded == NO && [window isDocumentEdited] )
    {
        BOOL ret;

        [window makeKeyAndOrderFront:self];

	ret = NSRunAlertPanel(@"Edited File!",
	                      @"Should the file be saved before closing?",
			      @"Yes",@"No",nil);

	if( ret == YES )
	{
	    ret = [self saveFile];

	    if( ret == NO )
	    {
	        NSRunAlertPanel(@"Save Failed!",
		                @"Could not save file '%@'!",
				@"OK",nil,nil,path);
	    }
	}

        [window setDocumentEdited:NO];
    }
    else if( isEmbedded )
    {
    }

    if( delegate && [delegate respondsToSelector:@selector(editorDidClose:)] )
    {
        [delegate editorDidClose:self];
    }
}

- (BOOL)saveFile
{
    if( isEmbedded == NO )
    {
	[window setDocumentEdited:NO];
    }

    return [[view text] writeToFile:path atomically:YES];
}

- (BOOL)revertFile
{
    NSString *text = [NSString stringWithContentsOfFile:path];

    [view setText:text];

    if( isEmbedded == NO )
    {
	[window setDocumentEdited:NO];
    }
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    if( [[aNotification object] isEqual:window] )
    {
        [self close];
    }
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
    if( [[aNotification object] isEqual:window] )
    {
	[[NSNotificationCenter defaultCenter] postNotificationName:PCEditorDidBecomeKeyNotification object:self];
    }
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
    if( [[aNotification object] isEqual:window] )
    {
	[[NSNotificationCenter defaultCenter] postNotificationName:PCEditorDidResignKeyNotification object:self];
    }
}

- (void)textDidChange:(NSNotification *)aNotification
{
    [window setDocumentEdited:YES];
}

@end
