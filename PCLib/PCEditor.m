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

@end

@implementation PCEditor (InitUI)

- (void)_initUI
{
  NSScrollView *scrollView;
  NSLayoutManager *lm;
  NSTextContainer *tc;
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

  // Now the text editing stuff
  storage = [[NSTextStorage alloc] init];
  
  lm = [[NSLayoutManager alloc] init];

  rect.origin.x = 0;
  rect.origin.y = 0;
  rect.size.height -= 24;
  rect.size.width -= 4;

  tc = [[NSTextContainer alloc] initWithContainerSize:rect.size];
  [lm addTextContainer:tc];
  RELEASE(tc);

  [storage addLayoutManager:lm];
  RELEASE(lm);

  iView = [[PCEditorView alloc] initWithFrame:rect
                                textContainer:tc];
  [iView setEditor:self];

  [iView setMinSize:NSMakeSize (0, 0)];
  [iView setMaxSize:NSMakeSize(1e7, 1e7)];
  [iView setRichText:YES];
  [iView setUsesFontPanel:YES];
  [iView setEditable:YES];
  [iView setSelectable:YES];
  [iView setVerticallyResizable:YES];
  [iView setHorizontallyResizable:NO];
  [iView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [iView setBackgroundColor:[NSColor whiteColor]];
  [[iView textContainer] setWidthTracksTextView:YES];

  lm = [[NSLayoutManager alloc] init];

  tc = [[NSTextContainer alloc] initWithContainerSize:rect.size];
  [lm addTextContainer:tc];
  RELEASE(tc);

  [storage addLayoutManager:lm];
  RELEASE(lm);

  eView = [[PCEditorView alloc] initWithFrame:rect
                                textContainer:tc];
  [eView setEditor:self];

  [eView setMinSize: NSMakeSize (0, 0)];
  [eView setMaxSize:NSMakeSize(1e7, 1e7)];
  [eView setRichText:YES];
  [eView setUsesFontPanel:YES];
  [eView setEditable:YES];
  [eView setSelectable:YES];
  [eView setVerticallyResizable:YES];
  [eView setHorizontallyResizable:NO];
  [eView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [eView setBackgroundColor:[NSColor whiteColor]];
  [[eView textContainer] setWidthTracksTextView:YES];

  [scrollView setDocumentView:eView];
  RELEASE(eView);

  rect.size = NSMakeSize([scrollView contentSize].width,1e7);
  [[eView textContainer] setContainerSize:rect.size];

  [scrollView setHasHorizontalScroller: YES];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setBorderType: NSBezelBorder];
  [scrollView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

  [window setContentView:scrollView];
  [window setDelegate:self];
  [window makeFirstResponder:eView];

  RELEASE(scrollView);
}

@end

@implementation PCEditor

- (id)initWithPath:(NSString*)file
{
    if((self = [super init]))
    {
        NSString *t = [NSString stringWithContentsOfFile:file];
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:t];

	isEdited = NO;
	path = [file copy];

        [self _initUI];

	[window setTitle:file];
	[storage setAttributedString:as];
	RELEASE(as);

	[iView setNeedsDisplay:YES];
	[eView setNeedsDisplay:YES];

	[[NSNotificationCenter defaultCenter] addObserver:self 
	                                      selector:@selector(textDidChange:)
				              name:NSTextDidChangeNotification
				              object:eView];

	[[NSNotificationCenter defaultCenter] addObserver:self 
	                                      selector:@selector(textDidChange:)
				              name:NSTextDidChangeNotification
				              object:iView];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    RELEASE(window);
    RELEASE(path);

    RELEASE(iView);
    RELEASE(storage);

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

- (void)setIsEdited:(BOOL)yn
{
    [window setDocumentEdited:yn];
    isEdited = yn;
}

- (void)showInProjectEditor:(PCProjectEditor *)pe
{
    [pe setEditorView:iView];
}

- (void)show
{
    [window makeKeyAndOrderFront:self];
}

- (void)close
{
    if( isEdited )
    {
        BOOL ret;

        if( [window isVisible] )
	{
	    [window makeKeyAndOrderFront:self];
	}

	ret = NSRunAlertPanel(@"Edited File!",
	                      @"Should '%@' be saved before closing?",
			      @"Yes",@"No",nil,path);

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

        [self setIsEdited:NO];
    }

    if( delegate && [delegate respondsToSelector:@selector(editorDidClose:)] )
    {
        [delegate editorDidClose:self];
    }
}

- (BOOL)saveFileIfNeeded
{
    if( isEdited )
    {
        return [self saveFile];
    }

    return YES;
}

- (BOOL)saveFile
{
    [self setIsEdited:NO];

    // Operate on the text storage!
    return [[storage string] writeToFile:path atomically:YES];
}

- (BOOL)revertFile
{
    NSString *text = [NSString stringWithContentsOfFile:path];
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:text];

    [self setIsEdited:NO];

    // Operate on the text storage!
    [storage setAttributedString:as];
    RELEASE(as);

    [iView setNeedsDisplay:YES];
    [eView setNeedsDisplay:YES];
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
    [self setIsEdited:YES];
}

@end
