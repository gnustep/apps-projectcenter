/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2002-2004 Free Software Foundation

   Authors: Philippe C.D. Robert
            Serg Stoyan

   This file is part of GNUstep.

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include "PCDefines.h"
#include "PCProjectWindow.h"
#include "PCProjectBrowser.h"
#include "PCProjectEditor.h"
#include "PCEditor.h"
#include "PCEditorView.h"

#include "PCLogController.h"

NSString *PCEditorDidChangeFileNameNotification = 
          @"PCEditorDidChangeFileNameNotification";
	  
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
  NSString       *editor = [ud objectForKey:Editor];

  if (![editor isEqualToString:@"ProjectCenter"])
    {
      NSArray        *ea = [editor componentsSeparatedByString:@" "];
      NSString       *app = [ea objectAtIndex: 0];

      if ([[app pathExtension] isEqualToString:@"app"])
	{
	  BOOL ret = [[NSWorkspace sharedWorkspace] openFile:path 
	                                     withApplication:app];

	  if (ret == NO)
	    {
	      PCLogError(self, @"Could not open %@ using %@", path, app);
	    }

	  return nil;
	}

      editor = [[PCEditor alloc] initExternalEditor:editor 
	                                   withPath:path
				      projectEditor:self];
    }
  else
    {
      PCEditor *editor;

      editor = [[PCEditor alloc] initWithPath:path 
	                         categoryPath:nil
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
      PCLogStatus(self, @"[init]");
      project = aProject;
      componentView  = nil;
      editorsDict = [[NSMutableDictionary alloc] init];
      
      [[NSNotificationCenter defaultCenter]
	addObserver:self 
	   selector:@selector(editorDidOpen:)
	       name:PCEditorDidOpenNotification
	     object:nil];

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

      [[NSNotificationCenter defaultCenter]
	addObserver:self 
	   selector:@selector(editorDidChangeFileName:)
	       name:PCEditorDidChangeFileNameNotification
	     object:nil];
    }

  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog (@"PCProjectEditor: dealloc");
#endif

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if (componentView)
    {
      RELEASE(scrollView);
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

- (PCProject *)project
{
  return project;
}

// ===========================================================================
// ==== Project and Editor handling
// ===========================================================================

- (PCEditor *)editorForFile:(NSString *)path
               categoryPath:(NSString *)categoryPath
	           windowed:(BOOL)yn
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString       *ed = [ud objectForKey:Editor];
  PCEditor       *editor;

  if (![ed isEqualToString:@"ProjectCenter"])
    {
      editor = [[PCEditor alloc] initExternalEditor:ed
	                                   withPath:path
	                              projectEditor:self];
      return editor;
    }

  if (!(editor = [editorsDict objectForKey:path]))
    {
      editor = [[PCEditor alloc] initWithPath:path 
	                         categoryPath:categoryPath
	                        projectEditor:self];
//      [componentView setContentView:[editor componentView]];
//      [[project projectWindow] makeFirstResponder:[editor editorView]];

      [editorsDict setObject:editor forKey:path];
      RELEASE(editor);
    }

  [editor setWindowed:yn];

  [self orderFrontEditorForFile:path];

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
      [[project projectWindow] setCustomContentView:componentView];
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
  [activeEditor closeFile:self save:YES];
}

- (void)closeEditorForFile:(NSString *)file
{
  PCEditor *editor = nil;

//  editor = [editorsDict objectForKey:file];
  if ([editorsDict count] > 0 && (editor = [editorsDict objectForKey:file]))
    {
      [editor closeFile:self save:YES];
      [editorsDict removeObjectForKey:file];
    }
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

  // TODO: Order panel with list of changed files
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
      NSString *categoryPath = [editor categoryPath];
      
      res = [editor saveFileTo:file];
      [editor closeFile:self save:NO];

      [self editorForFile:file categoryPath:categoryPath windowed:iw];

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

- (void)editorDidOpen:(NSNotification *)aNotif
{
/*  PCEditor         *editor = [aNotif object];
  PCProjectBrowser *browser = [project projectBrowser];
  NSString         *path = [browser path];
  
  // Active editor is set after PCEditorDidBecomeActiveNotification will be
  // sent, but we should do it here for loading list of classes into browser.
  [self setActiveEditor:editor];
  [browser reloadLastColumnAndNotify:NO];
  [browser setPath:path];*/
}

- (void)editorDidClose:(NSNotification *)aNotif
{
  PCEditor *editor = [aNotif object];

  // It is not our editor
  if ([editor projectEditor] != self)
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
    }
  else
    {
      PCProjectBrowser *browser = [project projectBrowser];
      NSString         *path = [browser path];
      
      [componentView setContentView:scrollView];
      [[project projectWindow] makeFirstResponder:scrollView];

      [browser setPath:[path stringByDeletingLastPathComponent]];
    }
}

- (void)editorDidBecomeActive:(NSNotification *)aNotif
{
  PCEditor *editor = [aNotif object];
  NSString *categoryPath = nil;

  if ([editor projectEditor] != self || activeEditor == editor)
    {
      return;
    }

  categoryPath = [editor categoryPath];

  [self setActiveEditor:editor];

  if (categoryPath)
    {
      [[project projectBrowser] setPath:categoryPath];
    }
}

- (void)editorDidResignActive:(NSNotification *)aNotif
{
  PCEditor *editor = [aNotif object];
  
  if ([editor projectEditor] != self)
    {
      return;
    }

  [self setActiveEditor:nil];
}

- (void)editorDidChangeFileName:(NSNotification *)aNotif
{
  NSDictionary *_editorDict = [aNotif object];
  PCEditor     *_editor = [_editorDict objectForKey:@"Editor"];
  NSString     *_oldFileName = nil;
  NSString     *_newFileName = nil;

  if ([_editor projectEditor] != self)
    {
      return;
    }
    
  _oldFileName = [_editorDict objectForKey:@"OldFile"];
  _newFileName = [_editorDict objectForKey:@"NewFile"];
  
  [editorsDict removeObjectForKey:_oldFileName];
  [editorsDict setObject:_editor forKey:_newFileName];
}

@end

