/* 
 * PCProjectEditor.m created by probert on 2002-02-10 09:27:09 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#include "PCDefines.h"
#include "PCProject.h"
#include "PCProjectWindow.h"
#include "PCProjectBrowser.h"
#include "PCProjectEditor.h"
#include "PCEditor.h"
#include "PCEditorView.h"
#include "ProjectComponent.h"

@interface PCProjectEditor (CreateUI)

- (void) _createComponentView;

@end

@implementation PCProjectEditor (CreateUI)

- (void) _createComponentView
{
  NSRect     frame;
  NSTextView *textView;

  frame = NSMakeRect(0,0,562,248);
  componentView = [[NSBox alloc] initWithFrame:frame];
  [componentView setTitlePosition: NSNoTitle];
  [componentView setBorderType: NSNoBorder];
  [componentView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [componentView setContentViewMargins: NSMakeSize(0.0,0.0)];

  frame = NSMakeRect (0, 0, 562, 40);
  scrollView = [[NSScrollView alloc] initWithFrame:frame];
  [scrollView setHasHorizontalScroller: NO];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setBorderType: NSBezelBorder];
  [scrollView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];

  // This is a placeholder!
  frame = [[scrollView contentView] frame];
  textView =   [[NSTextView alloc] initWithFrame:frame];
  [textView setMinSize: NSMakeSize (0, 0)];
  [textView setMaxSize: NSMakeSize(1e7, 1e7)];
  [textView setRichText: NO];
  [textView setEditable: NO];
  [textView setSelectable: YES];
  [textView setVerticallyResizable: YES];
  [textView setHorizontallyResizable: NO];
  [textView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
  [[textView textContainer] setWidthTracksTextView: YES];
  [scrollView setDocumentView: textView];
  RELEASE(textView);

  frame.size = NSMakeSize([scrollView contentSize].width,1e7);
  [[textView textContainer] setContainerSize:frame.size];

  [componentView addSubview:scrollView];
  RELEASE(scrollView);

  [componentView sizeToFit];
}

@end

@implementation PCProjectEditor
// ===========================================================================
// ==== Class Methods
// ===========================================================================

+ (void)openFileInEditor:(NSString *)path
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    if([[ud objectForKey:ExternalEditor] isEqualToString:@"YES"])
    {
        NSTask         *editorTask;
	NSMutableArray *args;
	NSString       *editor = [ud objectForKey:Editor];
	NSString       *app;
	NSArray        *ea = [editor componentsSeparatedByString: @" "];

	args = [NSMutableArray arrayWithArray:ea];
	app = [args objectAtIndex: 0];

	if( [[app pathExtension] isEqualToString:@"app"] )
	{
	    BOOL ret = [[NSWorkspace sharedWorkspace] openFile:path 
	                                       withApplication:app];

	    if( ret == NO )
	    {
	        NSLog(@"Could not open %@ using %@",path,app);
	    }

            return;
	}

	editorTask = [[NSTask alloc] init];

	[editorTask setLaunchPath:app];
	[args removeObjectAtIndex: 0];
	[args addObject:path];

	[editorTask setArguments:args];

	AUTORELEASE( editorTask );
	[editorTask launch];
    }
    else
    {
        PCEditor *editor;

	editor = [[PCEditor alloc] initWithPath:path];
	[editor setDelegate:self];
	[editor show];
    }
}

// ===========================================================================
// ==== Initialisation
// ===========================================================================

- (id)initWithProject: (PCProject *)aProject
{
  NSAssert(aProject, @"No project specified!");

  if((self = [super init]))
    {
      project = aProject;
      componentView  = nil;
      editorsDict = [[NSMutableDictionary alloc] init];
    }
  return self;
}

- (void) dealloc
{
  if (componentView)
    {
      RELEASE(componentView);
    }

  [editorsDict removeAllObjects];
  RELEASE( editorsDict );

  [super dealloc];
}

- (NSView *)emptyEditorView
{
  if (componentView == nil) 
    {
      [self _createComponentView];
    }

  return componentView;
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

  editorView = ev;

  [scrollView setDocumentView:editorView];

  frame = [[scrollView contentView] frame];
  frame.size = NSMakeSize([scrollView contentSize].width,1e7);
  [editorView setFrame:frame];
  [editorView sizeToFit];
}

- (PCEditorView *) editorView
{
  return editorView;
}

// ===========================================================================
// ==== Project and Editor handling
// ===========================================================================

- (PCEditor *)internalEditorForFile:(NSString *)path
{
  PCEditor *editor;

  if ((editor = [editorsDict objectForKey:path]))
    {
      return editor;
    }
  else
    {
      editor = [[PCEditor alloc] initWithPath:path];

      [editor setDelegate:self];

      [editorsDict setObject:editor forKey:path];
      //RELEASE(editor);

      return editor;
    }
}

- (PCEditor *)editorForFile:(NSString *)path
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    if([[ud objectForKey:ExternalEditor] isEqualToString:@"YES"])
    {
/*        [self openFileInEditor:path];*/
	return nil;
    }
    else
    {
        return [self internalEditorForFile:path];
    }
}

- (PCEditor *)activeEditor
{
  NSEnumerator *enumerator = [editorsDict keyEnumerator];
  PCEditor     *editor;
  NSString     *key;
  NSWindow     *window;

  while (( key = [enumerator nextObject] ))
    {
      editor = [editorsDict objectForKey:key];
      window = [editor editorWindow];

      if (([window isVisible] && [window isKeyWindow])
	  || ([[editor internalView] superview]
	      && [[project projectWindow] isKeyWindow]))
	{
	  return editor;
	}
    }

  return nil;
}

- (NSArray *)allEditors
{
    return [editorsDict allValues];
}

- (void)closeEditorForFile:(NSString *)file
{
  PCEditor *editor;

  editor = [editorsDict objectForKey:file];
  [editor closeFile:self];
  [editorsDict removeObjectForKey:file];
}

- (void)closeAllEditors
{
  NSEnumerator *enumerator = [editorsDict keyEnumerator];
  PCEditor     *editor;
  NSString     *key;

  while ((key = [enumerator nextObject]))
    {
      editor = [editorsDict objectForKey:key];
      [editor closeFile:self];
    }
  [editorsDict removeAllObjects];
}

// ===========================================================================
// ==== File handling
// ===========================================================================

- (BOOL)saveAllFiles
{
    NSEnumerator *enumerator = [editorsDict keyEnumerator];
    PCEditor     *editor;
    NSString     *key;
    BOOL          ret = YES;

    while(( key = [enumerator nextObject] ))
    {
        editor = [editorsDict objectForKey:key];

	if( [editor saveFileIfNeeded] == NO )
	{
	    ret = NO;
	}
    }

    return ret;
}

- (BOOL)saveFile
{
  PCEditor *editor = [self activeEditor];

  if (editor != nil)
    {
      return [editor saveFileIfNeeded];
    }

  return NO;
}

- (BOOL)saveFileAs:(NSString *)file
{
  PCEditor *editor = [self activeEditor];

  if (editor != nil)
    {
      BOOL res;
      res = [editor saveFileTo:file];
      [editor closeFile:self];

      [[self internalEditorForFile:file]
	showInProjectEditor:[project projectEditor]];
      return res;
    }

  return NO;
}

- (BOOL)saveFileTo:(NSString *)file
{
  PCEditor *editor = [self activeEditor];

  if (editor != nil)
    {
      return [editor saveFileTo:file];
    }

  return NO;
}

- (BOOL)revertFileToSaved
{
  PCEditor *editor = [self activeEditor];

  if (editor != nil)
    {
      return [editor revertFileToSaved];
    }

  return NO;
}

- (void)closeFile:(id)sender
{
  [[self activeEditor] closeFile:self];
}

// ===========================================================================
// ==== Delegate
// ===========================================================================

- (void)editorDidClose:(id)sender
{
  PCEditor *editor = (PCEditor*)sender;
  
  [editorsDict removeObjectForKey:[editor path]];

  if ([editorsDict count])
    {
      editor = [editorsDict objectForKey: [[editorsDict allKeys] lastObject]];
      [editor showInProjectEditor: [project projectEditor]];
      [[project projectWindow] makeFirstResponder:[editor internalView]];
    }
  else
    {
      [[project projectEditor] setEditorView:nil];
//      [[project browserController] projectDictDidChange:nil];
    }
}

- (void)setBrowserPath:(NSString *)file category:(NSString *)category
{
  [[project projectBrowser] setPathForFile:file category:category];
}


@end

