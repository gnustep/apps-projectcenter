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

    componentView = [[NSBox alloc] initWithFrame:NSMakeRect(-1,-1,562,248)];
    [componentView setTitlePosition:NSNoTitle];
    [componentView setBorderType:NSNoBorder];
    [componentView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [componentView setContentViewMargins: NSMakeSize(0.0,0.0)];

    frame = NSMakeRect(20,16,240,16);
    methods = [[NSPopUpButton alloc] initWithFrame:frame];
    [methods addItemWithTitle:@"No Method"];
    [methods setPullsDown:YES];
    [methods setTarget:self];
    [methods setAction:@selector(pullDownSelected:)];
    [componentView addSubview:methods];
    RELEASE(methods);

    frame = NSMakeRect (-1,32,562,40);
    scrollView = [[NSScrollView alloc] initWithFrame:frame];
    [scrollView setHasHorizontalScroller: YES];
    [scrollView setHasVerticalScroller: YES];
    [scrollView setBorderType: NSBezelBorder];
    [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

    // This is a placeholder!
    frame = [[scrollView contentView] frame];
    etv = [[NSTextView alloc] initWithFrame:frame];
    [etv setMinSize: NSMakeSize (0, 0)];
    [etv setMaxSize:NSMakeSize(1e7, 1e7)];
    [etv setRichText:NO];
    [etv setEditable:NO];
    [etv setSelectable:YES];
    [etv setVerticallyResizable:YES];
    [etv setHorizontallyResizable:NO];
    [etv setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    [[etv textContainer] setWidthTracksTextView:YES];
    [scrollView setDocumentView:etv];
    RELEASE(etv);

    frame.size = NSMakeSize([scrollView contentSize].width,1e7);
    [[etv textContainer] setContainerSize:frame.size];

    [componentView addSubview:scrollView];
    RELEASE(scrollView);

    [componentView sizeToFit];
}

@end

@implementation PCProjectEditor

- (id)initWithProject:(PCProject *)aProject
{
    NSAssert(aProject,@"No project specified!");

    if((self = [super init]))
    {
        currentProject = aProject;
	componentView  = nil;
    }
    return self;
}

- (void)dealloc
{
    if( componentView ) RELEASE(componentView);

    [super dealloc];
}

- (NSView *)componentView
{
    if (componentView == nil) 
    {
	[self _createComponentView];
    }

    return componentView;
}

- (void)setEditorView:(PCEditorView *)ev
{
    NSRect frame;

    editor = ev;
    [scrollView setDocumentView:editor];

    frame = [[scrollView contentView] frame];
    frame.size = NSMakeSize([scrollView contentSize].width,1e7);
    [[editor textContainer] setContainerSize:frame.size];

    [editor setNeedsDisplay:YES];
}

- (PCEditorView *)editorView
{
    return editor;
}

@end
