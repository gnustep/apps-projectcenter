/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

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

#import <ProjectCenter/PCDefines.h>
#import <ProjectCenter/PCFileManager.h>
#import <ProjectCenter/PCProjectManager.h>
#import <ProjectCenter/PCBundleManager.h>

#import <ProjectCenter/PCProject.h>
#import <ProjectCenter/PCProjectWindow.h>
#import <ProjectCenter/PCProjectBrowser.h>
#import <ProjectCenter/PCProjectEditor.h>

#import <ProjectCenter/PCLogController.h>

NSString *PCEditorDidChangeFileNameNotification = 
          @"PCEditorDidChangeFileNameNotification";

NSString *PCEditorWillOpenNotification = @"PCEditorWillOpenNotification";
NSString *PCEditorDidOpenNotification = @"PCEditorDidOpenNotification";
NSString *PCEditorWillCloseNotification = @"PCEditorWillCloseNotification";
NSString *PCEditorDidCloseNotification = @"PCEditorDidCloseNotification";

NSString *PCEditorWillChangeNotification = @"PCEditorWillChangeNotification";
NSString *PCEditorDidChangeNotification = @"PCEditorDidChangeNotification";
NSString *PCEditorWillSaveNotification = @"PCEditorWillSaveNotification";
NSString *PCEditorDidSaveNotification = @"PCEditorDidSaveNotification";
NSString *PCEditorWillRevertNotification = @"PCEditorWillRevertNotification";
NSString *PCEditorDidRevertNotification = @"PCEditorDidRevertNotification";

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
  [componentView setTitlePosition:NSNoTitle];
  [componentView setBorderType:NSNoBorder];
  [componentView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [componentView setContentViewMargins:NSMakeSize(0.0,0.0)];

  frame = NSMakeRect (0, 0, 562, 40);
  scrollView = [[NSScrollView alloc] initWithFrame:frame];
  [scrollView setHasHorizontalScroller:NO];
  [scrollView setHasVerticalScroller:YES];
  [scrollView setBorderType:NSBezelBorder];
  [scrollView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];

  // This is a placeholder!
  frame = [[scrollView contentView] frame];
  textView =   [[NSTextView alloc] initWithFrame:frame];
  [textView setMinSize:NSMakeSize (0, 0)];
  [textView setMaxSize:NSMakeSize(1e7, 1e7)];
  [textView setRichText:NO];
  [textView setEditable:NO];
  [textView setSelectable:YES];
  [textView setVerticallyResizable:YES];
  [textView setHorizontallyResizable:NO];
  [textView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
  [[textView textContainer] setWidthTracksTextView:YES];
  [scrollView setDocumentView:textView];
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
// ==== Initialisation
// ===========================================================================

- (id)initWithProject:(PCProject *)aProject
{
  PCBundleManager *bundleManager;
  NSAssert(aProject, @"No project specified!");

  if ((self = [super init]))
    {
      PCLogStatus(self, @"[init]");
      project = aProject;
      componentView  = nil;
      editorsDict = [[NSMutableDictionary alloc] init];

      // Bundles
      bundleManager = [[project projectManager] bundleManager];
      
      // Editor bundles
      editorBundlesInfo = [[bundleManager infoForBundlesOfType:@"editor"] copy];

      // Parser bundles
      parserBundlesInfo = [[bundleManager infoForBundlesOfType:@"parser"] copy];
      
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
#endif
  NSLog (@"PCProjectEditor: dealloc");

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if (componentView)
    {
      RELEASE(scrollView);
      RELEASE(componentView);
    }

  RELEASE(editorBundlesInfo);
  RELEASE(parserBundlesInfo);
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

- (NSDictionary *)infoTableForBundleType:(NSString *)type
			     andFileType:(NSString *)extension
{
  NSDictionary *bundlesInfo = nil;
  NSEnumerator *enumerator = nil;
  NSString     *bundlePathKey = nil;
  NSDictionary *infoTable = nil;

  if ([type isEqualToString:@"editor"])
    {
      bundlesInfo = editorBundlesInfo;
    }
  else
    {
      bundlesInfo = parserBundlesInfo;
    }

  enumerator = [[bundlesInfo allKeys] objectEnumerator];
  while ((bundlePathKey = [enumerator nextObject]))
    {
      infoTable = [bundlesInfo objectForKey:bundlePathKey];
      if ([[infoTable objectForKey:@"FileTypes"] containsObject:extension])
	{
	  break;
	}
      else
	{
	  infoTable = nil;
	}
    }

  return infoTable;
}

- (NSString *)classNameForBundleType:(NSString*)type 
			     andFile:(NSString *)file
{
  NSString     *fileExtension = [file pathExtension];
  NSDictionary *infoTable = nil;
  NSString     *className = nil;

  infoTable = [self infoTableForBundleType:type andFileType:fileExtension];
  className = [infoTable objectForKey:@"PrincipalClassName"];

  if (className == nil && [type isEqualToString:@"editor"])
    {
      className = [NSString stringWithString:@"PCEditor"];
    }

  return className;
}

// TODO: Should it be editor or parser?
- (BOOL)editorProvidesBrowserItemsForItem:(NSString *)item
{
  NSString     *file = [[project projectBrowser] nameOfSelectedFile];
  NSDictionary *infoTable = nil;

  // File selected and editor should already be loaded
  if (file != nil)
    {
      if ([[item substringToIndex:1] isEqualToString:@"@"])
	{
	  return YES;
	}
    }

  // Category selected
  infoTable = [self infoTableForBundleType:@"editor" 
			       andFileType:[item pathExtension]];

  if ([[infoTable objectForKey:@"ProvidesBrowserItems"] isEqualToString:@"YES"])
    {
      return YES;
    }
  
  return NO;
}

- (id<CodeEditor>)editorForFile:(NSString *)fileName key:(NSString *)key
{
  NSString *filePath = nil;

  filePath = [project pathForFile:fileName forKey:key];

  return [editorsDict objectForKey:filePath];
}

// categoryPath:
// 1. "/Classes/Class.m/- init"
// 2. "/Subprojects/Project/Classes/Class.m/- init"
// 3. "/Library/gnustep-gui"
- (id<CodeEditor>)openEditorForCategoryPath:(NSString *)categoryPath
			       windowed:(BOOL)windowed
{
  NSArray        *pathArray = [categoryPath pathComponents];
  PCProject      *activeProject = [[project projectManager] activeProject];
  NSString       *category = [[project projectBrowser] nameOfSelectedCategory];
  NSString       *categoryKey = [activeProject keyForCategory:category];
  NSString       *fileName = nil;
  NSString       *filePath = nil;
  NSFileManager  *fm = [NSFileManager defaultManager];
  BOOL           isDir;
  BOOL           editable = YES;
  id<CodeEditor> editor;
  NSString       *pathLastObject = nil;
  NSString       *firstSymbol = nil;

  fileName = [[[[project projectBrowser] pathFromSelectedCategory] 
    pathComponents] objectAtIndex:2];
  filePath = [activeProject pathForFile:fileName forKey:categoryKey];

/*  NSLog(@"PCPE: fileName: %@ filePath: %@ project: %@", 
	fileName, filePath, [activeProject projectName]);*/

  // Determine if file not exist or file is directory
  if (![fm fileExistsAtPath:filePath isDirectory:&isDir] || isDir)
    {
      return nil;
    }

  // Determine if file is text file
  if (![[PCFileManager defaultManager] isTextFile:filePath])
    {
      return nil;
    }

  // Determine if file should be opened for read only
  if (![project isEditableFile:fileName])
    {
      editable = NO;
    }
  
//  NSLog(@"fileName: %@ > %@", fileName, listEntry);

  editor = [self openEditorForFile:filePath 
		      categoryPath:categoryPath
			  editable:editable
			  windowed:windowed];
  if (!editor)
    {
      NSLog(@"We don't have editor for file: %@", fileName);
    }
		      
  pathLastObject = [pathArray lastObject];
/*  NSLog(@"pathArray: c: %i %@", [pathArray count], pathArray);
  NSLog(@"pathArray: lastObject %@", [pathArray lastObject]);
  NSLog(@"lastObject[1]: %@", 
  [pathLastObject substringWithRange:NSMakeRange(0,1)]);*/

  pathLastObject = [pathArray lastObject];
  firstSymbol = [pathLastObject substringToIndex:1];
  if ([pathLastObject isEqualToString:@"/"]) // file selected
    {
      [[project projectBrowser] reloadLastColumnAndNotify:NO]; 
    }
  else if ([firstSymbol isEqualToString:@"@"])
    {
    }
  else if ([firstSymbol isEqualToString:@"-"]
	   || [firstSymbol isEqualToString:@"+"])
    {
      [editor scrollToMethodName:pathLastObject];
    }

  return editor;
}

- (id<CodeEditor>)openEditorForFile:(NSString *)path
		       categoryPath:(NSString *)categoryPath
			   editable:(BOOL)editable
			   windowed:(BOOL)windowed
{
//  NSUserDefaults  *ud = [NSUserDefaults standardUserDefaults];
//  NSString        *ed = [ud objectForKey:Editor];
  PCBundleManager *bundleManager = [[project projectManager] bundleManager];
  NSString        *editorClassName = nil;
  NSString        *parserClassName = nil;
  id<CodeEditor>  editor;
  id<CodeParser>  parser;

  NSLog(@"PCPE: categoryPath: \"%@\"", categoryPath);

  // TODO: Include external editor code into editor bundle?
/*  if (![ed isEqualToString:@"ProjectCenter"])
    {
      [editor initExternalEditor:ed withPath:path projectEditor:self];
      return editor;
    }*/

  if (!(editor = [editorsDict objectForKey:path]))
    {
      // Editor
      editorClassName = [self classNameForBundleType:@"editor"
					     andFile:[path lastPathComponent]];
      editor = [bundleManager objectForClassName:editorClassName
	  			    withProtocol:@protocol(CodeEditor)
				    inBundleType:@"editor"];
      if (!editor)
	{
	  return nil;
	}

      // Parser
      parserClassName = [self classNameForBundleType:@"parser"
					     andFile:[path lastPathComponent]];
      if (parserClassName != nil)
	{
	  NSLog(@"PCPE: parser: %@", parserClassName);
	  parser = [bundleManager objectForClassName:parserClassName
	      				withProtocol:@protocol(CodeParser)
	    				inBundleType:@"parser"];
	  [editor setParser:parser];
	  RELEASE(parser);
	}

      [editor openFileAtPath:path 
		categoryPath:categoryPath
	       projectEditor:self
		    editable:editable];

      [editorsDict setObject:editor forKey:path];
      RELEASE(editor);
    }

  [editor setCategoryPath:categoryPath];
  [editor setWindowed:windowed];

  [self orderFrontEditorForFile:path];

  return editor;
}

- (void)orderFrontEditorForFile:(NSString *)path
{
  id<CodeEditor> editor = [editorsDict objectForKey:path];

  if (!editor)
    {
      return;
    }

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

- (void)setActiveEditor:(id<CodeEditor>)anEditor
{
  if (anEditor != activeEditor)
    {
      activeEditor = anEditor;
    }
}

- (id<CodeEditor>)activeEditor
{
  return activeEditor;
}

- (NSArray *)allEditors
{
  return [editorsDict allValues];
}

- (void)closeActiveEditor:(id)sender
{
  if (!activeEditor)
    {
      return;
    }

  [activeEditor closeFile:self save:YES];
}

- (void)closeEditorForFile:(NSString *)file
{
  id<CodeEditor> editor;

  if ([editorsDict count] > 0 && (editor = [editorsDict objectForKey:file]))
    {
      [editor closeFile:self save:YES];
      [editorsDict removeObjectForKey:file];
    }
}

// Called by PCProject. After that retainCount goes down and [self dealloc]
// called by autorelease mechanism
- (BOOL)closeAllEditors
{
  NSEnumerator   *enumerator = [editorsDict keyEnumerator];
  id<CodeEditor> editor;
  NSString       *key = nil;
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

  // Stop parser. It releases self.
  // TODO: There should be a few parsers.
/*  [aParser stop];
  [parserConnection release];*/

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
  NSEnumerator   *enumerator = [editorsDict keyEnumerator];
  id<CodeEditor> editor;
  NSString       *key;
  BOOL           ret = YES;

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
  id<CodeEditor> editor = [self activeEditor];

  if (editor != nil)
    {
      return [editor saveFileIfNeeded];
    }

  return NO;
}

- (BOOL)saveFileAs:(NSString *)file
{
  id<CodeEditor> editor = [self activeEditor];

  if (editor != nil)
    {
      BOOL     res;
      BOOL     iw = [editor isWindowed];
      NSString *categoryPath = [editor categoryPath];
      
      res = [editor saveFileTo:file];
      [editor closeFile:self save:NO];

      [self openEditorForFile:file 
		 categoryPath:categoryPath
		     editable:YES
		     windowed:iw];

      return res;
    }

  return NO;
}

- (BOOL)saveFileTo:(NSString *)file
{
  id<CodeEditor> editor = [self activeEditor];

  if (editor != nil)
    {
      return [editor saveFileTo:file];
    }

  return NO;
}

- (BOOL)revertFileToSaved
{
  id<CodeEditor> editor = [self activeEditor];

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
//  id<CodeEditor> editor = [aNotif object];
  id editor = [aNotif object];

  // It is not our editor
  if ([editor projectEditor] != self)
    {
      return;
    }
  
  [editorsDict removeObjectForKey:[editor path]];

  if ([editorsDict count])
    {
      NSString       *lastEditorKey = [[editorsDict allKeys] lastObject];
      id<CodeEditor> lastEditor = [editorsDict objectForKey:lastEditorKey];

      lastEditorKey = [[editorsDict allKeys] lastObject];
      [componentView setContentView:[lastEditor componentView]];
      [[project projectWindow] makeFirstResponder:[lastEditor editorView]];
    }
  else
    {
      PCProjectBrowser *browser = [project projectBrowser];
      
      [componentView setContentView:scrollView];
      [[project projectWindow] makeFirstResponder:scrollView];

      [browser setPath:[browser pathToSelectedCategory]];
      [self setActiveEditor:nil];
    }
}

- (void)editorDidBecomeActive:(NSNotification *)aNotif
{
  id<CodeEditor> editor = [aNotif object];
  NSString       *categoryPath = nil;

  if ([editor projectEditor] != self)
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
  // Clearing activeEditor blocks the ability to get some information from
  // loaded and visible but not active editor
/*  PCEditor *editor = [aNotif object];
  
  if ([editor projectEditor] != self)
    {
      return;
    }

  [self setActiveEditor:nil];*/
}

- (void)editorDidChangeFileName:(NSNotification *)aNotif
{
  NSDictionary   *_editorDict = [aNotif object];
  id<CodeEditor> _editor = [_editorDict objectForKey:@"Editor"];
  NSString       *_oldFileName = nil;
  NSString       *_newFileName = nil;

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

