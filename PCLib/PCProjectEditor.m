/* 
 * PCProjectEditor.m created by probert on 2002-02-10 09:27:09 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#import "PCProjectEditor.h"
#import "PCEditorView.h"

@interface PCProjectEditor (CreateUI)

- (void)_createComponentView;

@end

@implementation PCProjectEditor (CreateUI)

- (void)_createComponentView
{
    NSPopUpButton *methods;
    NSRect frame;
    NSTextView *etv;

    frame = NSMakeRect(0,0,562,248);
    _componentView = [[NSBox alloc] initWithFrame:frame];
    [_componentView setTitlePosition: NSNoTitle];
    [_componentView setBorderType: NSNoBorder];
    [_componentView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [_componentView setContentViewMargins: NSMakeSize(0.0,0.0)];

    frame = NSMakeRect(20,16,240,16);
    methods = [[NSPopUpButton alloc] initWithFrame:frame];
    [methods addItemWithTitle:@"No Method"];
    [methods setPullsDown:YES];
    [methods setTarget:self];
    [methods setAction:@selector(pullDownSelected:)];
    [_componentView addSubview:methods];
    RELEASE(methods);

    frame = NSMakeRect (0,32,562,40);
    _scrollView = [[NSScrollView alloc] initWithFrame:frame];
    [_scrollView setHasHorizontalScroller: YES];
    [_scrollView setHasVerticalScroller: YES];
    [_scrollView setBorderType: NSBezelBorder];
    [_scrollView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];

    // This is a placeholder!
    frame = [[_scrollView contentView] frame];
    etv =   [[NSTextView alloc] initWithFrame:frame];
    [etv setMinSize: NSMakeSize (0, 0)];
    [etv setMaxSize: NSMakeSize(1e7, 1e7)];
    [etv setRichText: NO];
    [etv setEditable: NO];
    [etv setSelectable: YES];
    [etv setVerticallyResizable: YES];
    [etv setHorizontallyResizable: NO];
    [etv setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
    [[etv textContainer] setWidthTracksTextView: YES];
    [_scrollView setDocumentView: etv];
    RELEASE(etv);

    frame.size = NSMakeSize([_scrollView contentSize].width,1e7);
    [[etv textContainer] setContainerSize:frame.size];

    [_componentView addSubview:_scrollView];
    RELEASE(_scrollView);

    [_componentView sizeToFit];
}

@end

@implementation PCProjectEditor

- (id)initWithProject:(PCProject *)aProject
{
    NSAssert(aProject,@"No project specified!");

    if((self = [super init]))
    {
        _currentProject = aProject;
	_componentView  = nil;
    }
    return self;
}

- (void)dealloc
{
    if( _componentView ) RELEASE(_componentView);

    [super dealloc];
}

- (NSView *)componentView
{
    if (_componentView == nil) 
    {
	[self _createComponentView];
    }

    return _componentView;
}

- (void)setEditorView:(PCEditorView *)ev
{
    NSRect frame;

    _editorView = ev;

    [_scrollView setDocumentView:_editorView];

    frame = [[_scrollView contentView] frame];
    frame.size = NSMakeSize([_scrollView contentSize].width,1e7);
    [_editorView setFrame:frame];
    [_editorView sizeToFit];
}

- (PCEditorView *)editorView
{
    return _editorView;
}

@end

