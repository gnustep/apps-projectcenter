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
#include "PCProjectEditor.h"
#include "PCEditor.h"
#include "PCEditorView.h"

#include "PCLogController.h"

@implementation PCEditor (UInterface)

- (void)_createWindow
{
  unsigned int style;
  NSRect       rect;
  float        windowWidth;

  PCLogInfo(self, @"[_createWindow]");

  style = NSTitledWindowMask
        | NSClosableWindowMask
        | NSMiniaturizableWindowMask
        | NSResizableWindowMask;
	
  windowWidth = [[NSFont userFixedPitchFontOfSize:0.0] widthOfString:@"A"];
  windowWidth *= 80;
  windowWidth += 35+80;
  rect = NSMakeRect(100,100,windowWidth,320);

  _window = [[NSWindow alloc] initWithContentRect:rect
                                        styleMask:style
                                          backing:NSBackingStoreBuffered
                                            defer:YES];
  [_window setReleasedWhenClosed:YES];
  [_window setMinSize:NSMakeSize(512,320)];
  [_window setDelegate:self];
  rect = [[_window contentView] frame];
  
  // Scroll view
  _extScrollView = [[NSScrollView alloc] initWithFrame:rect];
  [_extScrollView setHasHorizontalScroller:NO];
  [_extScrollView setHasVerticalScroller:YES];
  [_extScrollView setAutoresizingMask:
    (NSViewWidthSizable|NSViewHeightSizable)];
  rect = [[_extScrollView contentView] frame];

  // Editor view
  _extEditorView = [self _createEditorViewWithFrame:rect];

  // Include editor view
  [_extScrollView setDocumentView:_extEditorView];
  [_extEditorView setNeedsDisplay:YES];
  RELEASE(_extEditorView);

  // Include scroll view
  [_window setContentView:_extScrollView];
  [_window makeFirstResponder:_extEditorView];
  RELEASE(_extScrollView);
}

- (void)_createInternalView
{
  NSRect rect = NSMakeRect(0,0,512,320);

  // Scroll view
  _intScrollView = [[NSScrollView alloc] initWithFrame:rect];
  [_intScrollView setHasHorizontalScroller:NO];
  [_intScrollView setHasVerticalScroller:YES];
  [_intScrollView setBorderType:NSBezelBorder];
  [_intScrollView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
  rect = [[_intScrollView contentView] frame];

  // Text view
  _intEditorView = [self _createEditorViewWithFrame:rect];

  /*
   * Setting up ext view / scroll view / window
   */
  [_intScrollView setDocumentView:_intEditorView];
  [_intEditorView setNeedsDisplay:YES];
  RELEASE(_intEditorView);
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

  ev = [[PCEditorView alloc] initWithFrame:fr textContainer:tc];
  [ev setEditor:self];

  [ev setMinSize:NSMakeSize(  0,   0)];
  [ev setMaxSize:NSMakeSize(1e7, 1e7)];
  [ev setRichText:YES];
  [ev setEditable:YES];
  [ev setVerticallyResizable:YES];
  [ev setHorizontallyResizable:NO];
  [ev setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [ev setTextContainerInset:NSMakeSize( 5, 5)];
  [[ev textContainer] setWidthTracksTextView:YES];

  [[ev textContainer] setContainerSize:NSMakeSize(fr.size.width, 1e7)];

  return AUTORELEASE(ev);
}

@end

@implementation PCEditor

// ===========================================================================
// ==== Initialization
// ===========================================================================

- (id)initWithPath:(NSString *)file
      categoryPath:(NSString *)categoryPath
     projectEditor:(PCProjectEditor *)aProjectEditor
{
  if ((self = [super init]))
    {
      NSString            *t;
      NSAttributedString *as;
      NSDictionary       *at;
      NSFont             *ft;

      projectEditor = aProjectEditor;
      _isEdited = NO;
      _isWindowed = NO;
      _window = nil;
      _path = [file copy];
      _categoryPath = [categoryPath copy];

      ft = [NSFont userFixedPitchFontOfSize:0.0];
      at = [NSDictionary dictionaryWithObject:ft forKey:NSFontAttributeName];
      t  = [NSString stringWithContentsOfFile:file];
      as = [[NSAttributedString alloc] initWithString:t attributes:at];

      _storage = [[NSTextStorage alloc] init];
      [_storage setAttributedString:as];
      RELEASE(as);

      if (categoryPath) // category == nil if we're non project editor
	{
	  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

	  if (![[ud objectForKey:SeparateEditor] isEqualToString:@"YES"])
	    {
	      [self _createInternalView];
    	      [[NSNotificationCenter defaultCenter]
     		addObserver:self 
	           selector:@selector(textDidChange:)
	               name:NSTextDidChangeNotification
	             object:_intEditorView];
	    }
	}

      [[NSNotificationCenter defaultCenter]
	addObserver:self 
	   selector:@selector(textDidChange:)
	       name:NSTextDidChangeNotification
	     object:_extEditorView];

      // Inform about file opening
      [[NSNotificationCenter defaultCenter]
	postNotificationName:PCEditorDidOpenNotification
	              object:self];
    }

  return self;
}

- (id)initExternalEditor:(NSString *)editor
                withPath:(NSString *)file
           projectEditor:(PCProjectEditor *)aProjectEditor
{
  NSTask         *editorTask = nil;
  NSArray        *ea = nil;
  NSMutableArray *args = nil;
  NSString       *app = nil;

  if (!(self = [super init]))
    {
      return nil;
    }

  projectEditor = aProjectEditor;
  _extScrollView = nil;
  _extEditorView = nil;
  _intScrollView = nil;
  _intEditorView = nil;
  _storage = nil;
  _path = [file copy];
  _categoryPath = nil;
  _window = nil;

  _isEdited = NO;
  _isWindowed = NO;
  _isExternal = YES;

  // Task
  ea = [editor componentsSeparatedByString:@" "];
  args = [NSMutableArray arrayWithArray:ea];
  app = [ea objectAtIndex:0];

  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector (externalEditorDidClose:)
           name:NSTaskDidTerminateNotification
         object:nil];

  editorTask = [[NSTask alloc] init];
  [editorTask setLaunchPath:app];
  [args removeObjectAtIndex:0];
  [args addObject:file];
  [editorTask setArguments:args];
  
  [editorTask launch];
//  AUTORELEASE(editorTask);

  // Inform about file opening
  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCEditorDidOpenNotification
                  object:self];

  return self;
}

- (void)externalEditorDidClose:(NSNotification *)aNotif
{
  NSString *path = [[[aNotif object] arguments] lastObject];

  if (![path isEqualToString:_path])
    {
      PCLogError(self, @"external editor task terminated");
      return;
    }
    
  PCLogStatus(self, @"Our Editor task terminated");

  // Inform about closing
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCEditorDidCloseNotification
                  object:self];
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog(@"PCEditor: dealloc");
#endif

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  // _window is setReleasedWhenClosed:YES
  RELEASE(_path);
  RELEASE(_categoryPath);
  RELEASE(_intScrollView);

  [super dealloc];
}

- (void)show
{
  if (_isWindowed)
    {
      [_window makeKeyAndOrderFront:nil];
    }
}

- (void)setWindowed:(BOOL)yn
{
  if ( (yn && _isWindowed) || (!yn && !_isWindowed) )
    {
      return;
    }

  if (yn && !_isWindowed)
    {
      [self _createWindow];
      [_window setTitle:[NSString stringWithFormat: @"%@",
      [_path stringByAbbreviatingWithTildeInPath]]];
    }
  else if (!yn && _isWindowed)
    {
      [_window close];
    }

  _isWindowed = yn;
}

- (BOOL)isWindowed
{
  return _isWindowed;
}

// ===========================================================================
// ==== Accessor methods
// ===========================================================================

- (PCProjectEditor *)projectEditor
{
  return projectEditor;
}

- (NSWindow *)editorWindow
{
  return _window;
}

- (PCEditorView *)editorView 
{
  return _intEditorView;
}

- (NSView *)componentView
{
  return _intScrollView;
}

- (NSString *)path
{
  return _path;
}

- (void)setPath:(NSString *)path
{
  NSMutableDictionary *notifDict = [[NSMutableDictionary dictionary] retain];

  // Prepare notification object
  [notifDict setObject:self forKey:@"Editor"];
  [notifDict setObject:_path forKey:@"OldFile"];
  [notifDict setObject:path forKey:@"NewFile"];

  // Set path
  [_path autorelease];
  _path = [path copy];

  // Post notification
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCEditorDidChangeFileNameNotification
                  object:notifDict];

  [notifDict autorelease];
}

- (NSString *)categoryPath
{
  return _categoryPath;
}

- (void)setCategoryPath:(NSString *)path
{
  [_categoryPath autorelease];
  _categoryPath = [path copy];
}

- (BOOL)isEdited
{
  return _isEdited;
}

- (void)setIsEdited:(BOOL)yn
{
  if (_window)
    {
      [_window setDocumentEdited:yn];
    }
  _isEdited = yn;
}

// ===========================================================================
// ==== Object managment
// ===========================================================================

- (BOOL)saveFileIfNeeded
{
  if ((_isEdited))
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

- (BOOL)saveFileTo:(NSString *)path
{
  // Operate on the text storage!
  return [[_storage string] writeToFile:path atomically:YES];
}

- (BOOL)revertFileToSaved
{
  NSString           *text = [NSString stringWithContentsOfFile:_path];
  NSAttributedString *as = nil;
  NSDictionary       *at = nil;
  NSFont             *ft = nil;

  // This is temporary
  ft = [NSFont userFixedPitchFontOfSize:0.0];
  at = [NSDictionary dictionaryWithObject:ft forKey:NSFontAttributeName];
  as = [[NSAttributedString alloc] initWithString:text attributes:at];

  [self setIsEdited:NO];

  // Operate on the text storage!
  [_storage setAttributedString:as];
  RELEASE(as);

  [_intEditorView setNeedsDisplay:YES];
  [_extEditorView setNeedsDisplay:YES];
  
  return YES;
}

- (BOOL)closeFile:(id)sender save:(BOOL)save
{
  NSLog(@"PCEditor: closeFile");

  if ((save == NO) || [self editorShouldClose])
    {
      // Close window first if visible
      if (_isWindowed && [_window isVisible] && (sender != _window))
	{
	  [_window close];
	}

      // Inform about closing
      [[NSNotificationCenter defaultCenter] 
	postNotificationName:PCEditorDidCloseNotification
	              object:self];

      return YES;
    }

  return NO;
}

- (BOOL)editorShouldClose
{
  if (_isEdited)
    {
      BOOL ret;

      if (_isWindowed && [_window isVisible])
	{
	  [_window makeKeyAndOrderFront:self];
	}

      ret = NSRunAlertPanel(@"Close File",
			    @"File %@ has been modified",
			    @"Save and Close", @"Don't save", @"Cancel", 
			    [_path lastPathComponent]);

      if (ret == YES)
	{
	  if ([self saveFile] == NO)
	    {
	      NSRunAlertPanel(@"Alert",
		    	      @"Error when saving file '%@'!",
		    	      @"OK", nil, nil, [_path lastPathComponent]);
	      return NO;
	    }
	  else
	    {
	      return YES;
	    }
	}
      else if (ret == NO) // Close but don't save
	{
	  return YES;
	}
      else               // Cancel closing
	{
	  return NO;
	}

      [self setIsEdited:NO];
    }

  return YES;
}

// ===========================================================================
// ==== Window delegate
// ===========================================================================

- (BOOL)windowShouldClose:(id)sender
{
  if ([sender isEqual:_window])
    {
      if (_intScrollView) 
	{
	  // Just close if this file also displayed in int view
	  _isWindowed = NO;
	  return YES;
	}
      else
	{
	  return [self closeFile:_window save:YES];
	}
    }

  return NO;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
  if ([[aNotification object] isEqual:_window] && [_window isVisible])
    {
      [_window makeFirstResponder:_extEditorView];
    }
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
  if ([[aNotification object] isEqual:_window] && [_window isVisible])
    {
      [_window makeFirstResponder:_window];
    }
}

// ===========================================================================
// ==== TextView (_intEditorView, _extEditorView) delegate
// ===========================================================================

- (void)textDidChange:(NSNotification *)aNotification
{
  id object = [aNotification object];


  if ([object isKindOfClass:[PCEditorView class]]
      && (object == _intEditorView || object == _extEditorView))
    {
      [self setIsEdited:YES];
    }
}

- (BOOL)becomeFirstResponder
{
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCEditorDidBecomeActiveNotification
                  object:self];

  return YES;
}

- (BOOL)resignFirstResponder
{
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCEditorDidResignActiveNotification
                  object:self];

  return YES;
}

@end

