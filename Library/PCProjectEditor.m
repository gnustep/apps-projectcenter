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

NSString *PCEditorDidOpenNotification = 
          @"PCEditorDidOpenNotification";
NSString *PCEditorDidCloseNotification = 
          @"PCEditorDidCloseNotification";

NSString *PCEditorDidBecomeActiveNotification = 
          @"PCEditorDidBecomeActiveNotification";
NSString *PCEditorDidResignActiveNotification = 
          @"PCEditorDidResignActiveNotification";

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

  [componentView setContentView:scrollView];
//  RELEASE(scrollView);

  [componentView sizeToFit];
}

@end

@implementation PCProjectEditor
// ===========================================================================
// ==== Class Methods
// ===========================================================================

+ (PCEditor *)openFileInEditor:(NSString *)path
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  if ([[ud objectForKey:ExternalEditor] isEqualToString:@"YES"])
    {
      NSTask         *editorTask;
      NSMutableArray *args;
      NSString       *editor = [ud objectForKey:Editor];
      NSString       *app;
      NSArray        *ea = [editor componentsSeparatedByString: @" "];

      args = [NSMutableArray arrayWithArray:ea];
      app = [args objectAtIndex: 0];

      if ([[app pathExtension] isEqualToString:@"app"])
	{
	  BOOL ret = [[NSWorkspace sharedWorkspace] openFile:path 
	                                     withApplication:app];

	  if (ret == NO)
	    {
	      NSLog(@"Could not open %@ using %@",path,app);
	    }

	  return nil;
	}

      editorTask = [[NSTask alloc] init];

      [editorTask setLaunchPath:app];
      [args removeObjectAtIndex: 0];
      [args addObject:path];

      [editorTask setArguments:args];

      AUTORELEASE(editorTask);
      [editorTask launch];
    }
  else
    {
      PCEditor *editor;

      editor = [[PCEditor alloc] initWithPath:path 
	                             category:nil
				projectEditor:self];
      [editor setWindowed:YES];
      [editor show];

      return editor;
    }

  return nil;
}

// ===========================================================================
// ==== Initialisation
// ===========================================================================

- (id)initWithProject: (PCProject *)aProject
{
  NSAssert(aProject, @"No project specified!");

  if ((self = [super init]))
    {
      NSLog(@"PCProjectEditor: init");
      project = aProject;
      componentView  = nil;
      editorsDict = [[NSMutableDictionary alloc] init];
      
      [[NSNotificationCenter defaultCenter]
	addObserver:self 
	   selector:@selector(editorDidClose:)
	       name:PCEditorDidCloseNotification
	     object:nil];
	     
      [[NSNotificationCenter defaultCenter]
	addObserver:self 
	   selector:@selector(editorDidBecomeActive:)
	       name:PCEditorDidBecomeActiveNotification
	     object:nil];
	     
      [[NSNotificationCenter defaultCenter]
	addObserver:self 
	   selector:@selector(editorDidResignActive:)
	       name:PCEditorDidResignActiveNotification
	     object:nil];
    }

  return self;
}

- (void)dealloc
{
  NSLog (@"PCProjectEditor: dealloc");

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if (componentView)
    {
      RELEASE(componentView);
    }

  [self closeAllEditors];
  RELEASE(editorsDict);

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


// ===========================================================================
// ==== Project and Editor handling
// ===========================================================================

- (PCEditor *)editorForFile:(NSString *)path
                   category:(NSString *)category
	           windowed:(BOOL)yn
{
  PCEditor *editor;

  if (!(editor = [editorsDict objectForKey:path]))
    {
      editor = [[PCEditor alloc] initWithPath:path 
	                             category:category
				projectEditor:self];

      [editorsDict setObject:editor forKey:path];
      RELEASE(editor);
    }

  [editor setWindowed:yn];
  
  [componentView setContentView:[editor componentView]];
  [[project projectWindow] makeFirstResponder:[editor editorView]];
  
  if (yn)
    {
      [editor show];
    }
  
  return editor;
}

- (void)orderFrontEditorForFile:(NSString *)path
{
  PCEditor *editor = [editorsDict objectForKey:path];
  
  if ([editor isWindowed])
    {
      [editor show];
    }
  else
    {
      [componentView setContentView:[editor componentView]];
      [[project projectWindow] makeFirstResponder:[editor editorView]];
    }
}

- (void)setActiveEditor:(PCEditor *)anEditor
{
  if (anEditor != activeEditor)
    {
      activeEditor = anEditor;
    }
}

- (PCEditor *)activeEditor
{
  return activeEditor;
}

- (NSArray *)allEditors
{
  return [editorsDict allValues];
}

- (void)closeActiveEditor:(id)sender
{
  [[self activeEditor] closeFile:self save:YES];
}

- (void)closeEditorForFile:(NSString *)file
{
  PCEditor *editor;

  editor = [editorsDict objectForKey:file];
  [editor closeFile:self save:YES];
  [editorsDict removeObjectForKey:file];
}

- (BOOL)closeAllEditors
{
  NSEnumerator   *enumerator = [editorsDict keyEnumerator];
  PCEditor       *editor;
  NSString       *key;
  NSMutableArray *editedFiles = [[NSMutableArray alloc] init];

  while ((key = [enumerator nextObject]))
    {
      editor = [editorsDict objectForKey:key];
      if ([editor isEdited])
	{
	  [editedFiles addObject:[key lastPathComponent]];
	}
      else
	{
	  [editor closeFile:self save:YES];
	}
    }

  // Order panel with list of changed files
  if ([editedFiles count])
    {
      if ([self saveEditedFiles:(NSArray *)editedFiles] == NO)
	{
	  return NO;
	}
    }

  [editorsDict removeAllObjects];

  return YES;
}

// ===========================================================================
// ==== File handling
// ===========================================================================

- (BOOL)saveEditedFiles:(NSArray *)files
{
  int ret;

  ret = NSRunAlertPanel(@"Alert",
			@"Project has modified files\n%@",
			@"Save and Close",@"Close",@"Don't close",
			files);
  switch (ret)
    {
    case NSAlertDefaultReturn:
      if ([self saveAllFiles] == NO)
	{
	  return NO;
	}
      break;

    case NSAlertAlternateReturn:
      // Close files without saving
      break;

    case NSAlertOtherReturn:
      return NO;
      break;
    }
    
  return YES;
}

- (BOOL)saveAllFiles
{
  NSEnumerator *enumerator = [editorsDict keyEnumerator];
  PCEditor     *editor;
  NSString     *key;
  BOOL          ret = YES;

  while ((key = [enumerator nextObject]))
    {
      editor = [editorsDict objectForKey:key];

      if ([editor saveFileIfNeeded] == NO)
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
      BOOL     res;
      BOOL     iw = [editor isWindowed];
      NSString *c = [editor category];
      
      res = [editor saveFileTo:file];
      [editor closeFile:self save:NO];

      [self editorForFile:file category:c windowed:iw];

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

// ===========================================================================
// ==== Notifications
// ===========================================================================

- (void)editorDidClose:(NSNotification *)aNotif
{
  PCEditor *editor = [aNotif object];

  NSLog(@"PCPE: editorDidClose");
  // It is not our editor
  if ([editorsDict objectForKey:[editor path]] != editor)
    {
      return;
    }
 
  [editorsDict removeObjectForKey:[editor path]];

  if ([editorsDict count])
    {
      NSString *lastEditorKey = [[editorsDict allKeys] lastObject];
      PCEditor *lastEditor = [editorsDict objectForKey:lastEditorKey];

      lastEditorKey = [[editorsDict allKeys] lastObject];
      [componentView setContentView:[lastEditor componentView]];
      [[project projectWindow] makeFirstResponder:[lastEditor editorView]];
      [self setActiveEditor:lastEditor];
    }
  else
    {
      [[project projectWindow] makeFirstResponder:scrollView];
      [componentView setContentView:scrollView];
      [self setActiveEditor:nil];
    }
}

- (void)editorDidBecomeActive:(NSNotification *)aNotif
{
  PCEditor *editor = [aNotif object];
  
  if ([editorsDict objectForKey:[editor path]] != editor)
    {
      return;
    }

  [self setActiveEditor:editor];

  if ([editor category])
    {
      [[project projectBrowser] 
	setPathForFile:[[editor path] lastPathComponent]
	      category:[editor category]];
    }
}

- (void)editorDidResignActive:(NSNotification *)aNotif
{
}

@end
