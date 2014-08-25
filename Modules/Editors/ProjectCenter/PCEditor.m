/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2002-2010 Free Software Foundation

   Authors: Philippe C.D. Robert
            Serg Stoyan
	    Riccardo Mottola

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

#import "PCEditor.h"
#import "PCEditorView.h"

@implementation PCEditor (UInterface)

- (void)_createWindow
{
  unsigned int style;
  NSRect       rect;
  float        windowWidth;

//  PCLogInfo(self, @"[_createWindow]");

  style = NSTitledWindowMask
        | NSClosableWindowMask
        | NSMiniaturizableWindowMask
        | NSResizableWindowMask;


  windowWidth = [[NSFont userFixedPitchFontOfSize:0.0] widthOfString:@"A"];
  windowWidth *= 80;
  windowWidth += 35;
  rect = NSMakeRect(0,0,windowWidth,320);

  _window = [[NSWindow alloc] initWithContentRect:rect
					styleMask:style
					  backing:NSBackingStoreBuffered
					    defer:YES];
  [_window setReleasedWhenClosed:NO];
  [_window setMinSize:NSMakeSize(512,320)];
  [_window setDelegate:self];
  [_window center];
  rect = [[_window contentView] frame];
  
  // Scroll view
  _extScrollView = [[NSScrollView alloc] initWithFrame:rect];
  [_extScrollView setHasHorizontalScroller:NO];
  [_extScrollView setHasVerticalScroller:YES];
  [_extScrollView setAutoresizingMask:
    (NSViewWidthSizable|NSViewHeightSizable)];
  rect = [[_extScrollView contentView] frame];

  // Text view
  _extEditorView = [self _createEditorViewWithFrame:rect];

  // Include editor view
  [_extScrollView setDocumentView:_extEditorView];
  [_extEditorView setNeedsDisplay:YES];
  RELEASE(_extEditorView);

  // Include scroll view
  [_window setContentView:_extScrollView];
  [_window makeFirstResponder:_extEditorView];
  RELEASE(_extScrollView);

  // Honor "edited" state
  [_window setDocumentEdited:_isEdited];
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
  PCEditorView    *ev = nil;
  NSTextContainer *tc = nil;
  NSLayoutManager *lm = nil;

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
  [ev setBackgroundColor:textBackground];
  [ev setTextColor:textColor];
  [ev setEditor:self];
  if (_highlightSyntax)
    {
      [ev createSyntaxHighlighterForFileType:[_path pathExtension]];
    }

  [ev setMinSize:NSMakeSize(0, 0)];
  [ev setMaxSize:NSMakeSize(1e7, 1e7)];
  [ev setRichText:YES];
  [ev setUsesFindPanel: YES];
  [ev setVerticallyResizable:YES];
  [ev setHorizontallyResizable:NO];
  [ev setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [ev setTextContainerInset:NSMakeSize(5, 5)];
  [[ev textContainer] setWidthTracksTextView:YES];

  [[ev textContainer] setContainerSize:NSMakeSize(fr.size.width, 1e7)];

  [ev setEditable:_isEditable];

  // Activate undo
  [ev setAllowsUndo: YES];

  [[NSNotificationCenter defaultCenter]
    addObserver:self 
       selector:@selector(textDidChange:)
	   name:NSTextDidChangeNotification
	 object:ev];

  return ev;
}

@end

@implementation PCEditor

// ===========================================================================
// ==== Initialization
// ===========================================================================

- (id)init
{
  if ((self = [super init]))
    {
      _extScrollView = nil;
      _extEditorView = nil;
      _intScrollView = nil;
      _intEditorView = nil;
      _storage = nil;
      _categoryPath = nil;
      _window = nil;

      _isEdited = NO;
      _isWindowed = NO;
      _isExternal = YES;

      _highlightSyntax = YES;

      ASSIGN(defaultFont, [PCEditorView defaultEditorFont]);
      ASSIGN(highlightFont, [PCEditorView defaultEditorFont]);
      ASSIGN(highlightColor, [NSColor greenColor]);
      ASSIGN(textColor, [NSColor blackColor]);
      ASSIGN(backgroundColor, [NSColor whiteColor]);
      ASSIGN(readOnlyColor, [NSColor lightGrayColor]);
      
      previousFGColor = nil;
      previousBGColor = nil;
      previousFont = nil;

      isCharacterHighlit = NO;
      highlited_chars[0] = -1;
      highlited_chars[1] = -1;

      undoManager = [[NSUndoManager alloc] init];
    }

  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog(@"PCEditor: %@ dealloc", [_path lastPathComponent]);
#endif

  [_extEditorView setEditor: nil];
  [_window setDelegate: nil];


  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_window close];

  // _window is setReleasedWhenClosed:YES
  RELEASE(_path);
  RELEASE(_categoryPath);
  RELEASE(_intScrollView);
  RELEASE(_storage);
  RELEASE(_window);

//  RELEASE(parserClasses);
  RELEASE(parserMethods);
  RELEASE(aParser);

  RELEASE(defaultFont);
  RELEASE(highlightFont);
  RELEASE(textColor);
  RELEASE(backgroundColor);
  RELEASE(readOnlyColor);

  RELEASE(undoManager);

  [super dealloc];
}

// --- Protocol
- (void)setParser:(id)parser
{
//  NSLog(@"RC aParser:%i parser:%i", 
//	[aParser retainCount], [parser retainCount]);
  ASSIGN(aParser, parser);
//  NSLog(@"RC aParser:%i parser:%i", 
//	[aParser retainCount], [parser retainCount]);
}

- (id)openFileAtPath:(NSString *)filePath
       editorManager:(id)editorManager
	    editable:(BOOL)editable
{
  NSString            *text;
  NSAttributedString  *attributedString = [NSAttributedString alloc];
  NSMutableDictionary *attributes = [NSMutableDictionary new];
  NSFont              *font;

  // Inform about future file opening
  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCEditorWillOpenNotification
		  object:self];

  _editorManager = editorManager;
  _path = [filePath copy];
  _isEditable = editable;

  // Prepare
  font = [NSFont userFixedPitchFontOfSize:0.0];
  if (editable)
    {
      textBackground = backgroundColor;
    }
  else
    {
      textBackground = readOnlyColor;
    }

  [attributes setObject:font forKey:NSFontAttributeName];
  [attributes setObject:textBackground forKey:NSBackgroundColorAttributeName];

  text  = [NSString stringWithContentsOfFile:_path];
  attributedString = [attributedString initWithString:text attributes:attributes];

  _storage = [[NSTextStorage alloc] init];
  [_storage setAttributedString:attributedString];
  RELEASE(attributedString);

//  [self _createInternalView];
/*  if (categoryPath) // category == nil if we're non project editor
    {
      NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

      if (![[ud objectForKey:SeparateEditor] isEqualToString:@"YES"])
	{
	  [self _createInternalView];
	}
    }*/

  // File open was finished
  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCEditorDidOpenNotification
		  object:self];

  return self;
}

- (id)openExternalEditor:(NSString *)editor
	 	withPath:(NSString *)file
	   editorManager:(id)aDelegate
{
  NSTask         *editorTask = nil;
  NSArray        *ea = nil;
  NSMutableArray *args = nil;
  NSString       *app = nil;

  if (!(self = [super init]))
    {
      return nil;
    }

  _editorManager = aDelegate;
  _path = [file copy];

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
// --- Protocol End

- (void)externalEditorDidClose:(NSNotification *)aNotif
{
  NSString *path = [[[aNotif object] arguments] lastObject];

  if (![path isEqualToString:_path])
    {
      NSLog(@"external editor task terminated");
      return;
    }
    
  NSLog(@"Our Editor task terminated");

  // Inform about closing
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCEditorDidCloseNotification
                  object:self];
}

// ===========================================================================
// ==== CodeEditor protocol
// ===========================================================================

// --- Accessor methods

- (id)editorManager
{
  return _editorManager;
}

- (NSWindow *)editorWindow
{
  return _window;
}

- (NSView *)editorView 
{
  if (!_intScrollView)
    {
      [self _createInternalView];
    }
  return _intEditorView;
}

- (NSView *)componentView
{
  if (!_intScrollView)
    {
      [self _createInternalView];
    }
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

- (NSImage *)fileIcon
{
  NSString *fileExtension = [[_path lastPathComponent] uppercaseString];
  NSString *imageName = nil;
  NSString *imagePath = nil;
  NSBundle *bundle = nil;
  NSImage  *image = nil;

  fileExtension = [[[_path lastPathComponent] pathExtension] uppercaseString];
  if (_isEdited)
    {
      imageName = [NSString stringWithFormat:@"File%@H", fileExtension];
    }
  else
    {
      imageName = [NSString stringWithFormat:@"File%@", fileExtension];
    }

  bundle = [NSBundle bundleForClass:NSClassFromString(@"PCEditor")];
  imagePath = [bundle pathForResource:imageName ofType:@"tiff"];

  image = [[NSImage alloc] initWithContentsOfFile:imagePath];

  return AUTORELEASE(image);
}

- (NSArray *)_methodsForClass:(NSString *)className
{
  NSEnumerator   *enumerator;
  NSDictionary   *method;
  NSDictionary   *class;
  NSMutableArray *items = [NSMutableArray array];
  NSRange        classRange;
  NSRange        methodRange;

  ASSIGN(parserClasses, [aParser classNames]);
  ASSIGN(parserMethods, [aParser methodNames]);

  enumerator = [parserClasses objectEnumerator];
  while ((class = [enumerator nextObject]))
    {
      if ([[class objectForKey:@"ClassName"] isEqualToString:className])
      {
	classRange = NSRangeFromString([class objectForKey:@"ClassBodyRange"]);
	break;
      }
    }

  methodRange = NSMakeRange(0, 0);
  enumerator = [parserMethods objectEnumerator];
  while ((method = [enumerator nextObject]))
    {
      //      NSLog(@"Method> %@", method);
      methodRange = NSRangeFromString([method objectForKey:@"MethodBodyRange"]);
      if (NSIntersectionRange(classRange, methodRange).length != 0)
	{
	  [items addObject:[method objectForKey:@"MethodName"]];
	}
    }

  return items;
}

- (NSArray *)browserItemsForItem:(NSString *)item
{
  NSEnumerator   *enumerator;
//  NSDictionary   *method;
  NSDictionary   *class;
  NSMutableArray *items = [NSMutableArray array];
  
  NSLog(@"PCEditor: asked for browser items for: %@", item);

  [aParser setString:[_storage string]];

  // If item is .m or .h file show class list
  if ([[item pathExtension] isEqualToString:@"m"]
      || [[item pathExtension] isEqualToString:@"h"])
    {
      ASSIGN(parserClasses, [aParser classNames]);

      enumerator = [parserClasses objectEnumerator];
      while ((class = [enumerator nextObject]))
	{
	  NSLog(@"Class> %@", class);
	  [items addObject:[class objectForKey:@"ClassName"]];
	}
    }

  // If item starts with "@" show method list
  if ([[item substringToIndex:1] isEqualToString:@"@"])
    {
/*      ASSIGN(parserMethods, [aParser methodNames]);

      enumerator = [parserMethods objectEnumerator];
      while ((method = [enumerator nextObject]))
	{
	  //      NSLog(@"Method> %@", method);
	  [items addObject:[method objectForKey:@"MethodName"]];
	}*/
      return [self _methodsForClass:item];
    }

  return items;
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

// --- Object managment

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
  BOOL saved = NO;

  if (_isEdited == NO)
    {
      return YES;
    }
    
  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCEditorWillSaveNotification
		  object:self];

  // Send the notification to Gorm...
  if([[_path pathExtension] isEqual: @"h"])
    {
      [[NSDistributedNotificationCenter defaultCenter]
	postNotificationName: @"GormParseClassNotification"
	object: _path];
    }

  saved = [[_storage string] writeToFile:_path atomically:YES];
 
  if (saved == YES)
    {
      [self setIsEdited:NO];
      [[NSNotificationCenter defaultCenter]
	postNotificationName:PCEditorDidSaveNotification
	  	      object:self];
    }
  else
    {
      NSRunAlertPanel(@"Save File",
		      @"Couldn't save file '%@'!",
		      @"OK", nil, nil, [_path lastPathComponent]);
    }

  return saved;
}

- (BOOL)saveFileTo:(NSString *)path
{
  return [[_storage string] writeToFile:path atomically:YES];
}

- (BOOL)revertFileToSaved
{
  NSString           *text = [NSString stringWithContentsOfFile:_path];
  NSAttributedString *as = nil;
  NSDictionary       *at = nil;
  NSFont             *ft = nil;

  if (_isEdited == NO)
    {
      return YES;
    }

  if (NSAlertDefaultReturn !=
      NSRunAlertPanel(@"Revert",
		      @"%@ has been modified.  "
		      @"Are you sure you want to undo changes?",
		      @"Revert", @"Cancel", nil,
		      [_path lastPathComponent]))
      {
	return NO;
      }

  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCEditorWillRevertNotification
		  object:self];

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
  
  [[NSNotificationCenter defaultCenter]
    postNotificationName:PCEditorDidRevertNotification
		  object:self];
		  
  return YES;
}

// FIXME: Do we really need this method?
- (BOOL)closeFile:(id)sender save:(BOOL)save
{
  if (save == YES)
    {
      [self saveFileIfNeeded];
    }

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

- (BOOL)close:(id)sender
{
  if ([self editorShouldClose] == YES)
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
      int ret;

      if (_isWindowed && [_window isVisible])
	{
	  [_window makeKeyAndOrderFront:self];
	}

      ret = NSRunAlertPanel(@"Close File",
			    @"File %@ has been modified. Save?",
			    @"Save and Close", @"Don't save", @"Cancel", 
			    [_path lastPathComponent]);
      switch (ret)
	{
	case NSAlertDefaultReturn: // Save And Close
	  if ([self saveFile] == NO)
	    {
	      return NO;
	    }
	  break;

	case NSAlertAlternateReturn: // Don't save
	  break;

	case NSAlertOtherReturn: // Cancel
	  return NO;
	  break;
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
    	  return [self close:sender];
	}
    }

  return NO;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
/*  if ([[aNotification object] isEqual:_window] && [_window isVisible])
    {
      [_window makeFirstResponder:_extEditorView];
    }*/
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
/*  if ([[aNotification object] isEqual:_window] && [_window isVisible])
    {
      [_window makeFirstResponder:_extEditorView];
    }*/
  [self resignFirstResponder:_extEditorView];
}


- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
  return undoManager;
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
      if (_isEdited == NO)
	{
	  [[NSNotificationCenter defaultCenter]
	    postNotificationName:PCEditorWillChangeNotification
			  object:self];

	  [self setIsEdited:YES];
	  
	  [[NSNotificationCenter defaultCenter]
	    postNotificationName:PCEditorDidChangeNotification
			  object:self];
	}
    }
}

- (void)textViewDidChangeSelection:(NSNotification *)notification
{
  if (editorTextViewIsPressingKey == NO)
    {
      id object;

      object = [notification object];
      if (object == _intEditorView || object == _extEditorView)
	[self computeNewParenthesisNesting: object];
    }
}

- (void)editorTextViewWillPressKey:sender
{
  editorTextViewIsPressingKey = YES;
//  NSLog(@"Will pressing key");

  if (sender == _intEditorView || sender == _extEditorView)
    [self unhighlightCharacter: sender];
  else
    NSLog(@"PCEditor: unexpected sender");
}

- (void)editorTextViewDidPressKey:sender
{
//  NSLog(@"Did pressing key");
  if (sender == _intEditorView || sender == _extEditorView)
    [self computeNewParenthesisNesting: sender];
  else
    NSLog(@"PCEditor: unexpected sender");

  editorTextViewIsPressingKey = NO;
}

- (BOOL)becomeFirstResponder:(PCEditorView *)view
{
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCEditorDidBecomeActiveNotification
		  object:self];

  return YES;
}

- (BOOL)resignFirstResponder:(PCEditorView *)view
{
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCEditorDidResignActiveNotification
		  object:self];

  return YES;
}

// ===========================================================================
// ==== Parser and scrolling
// ===========================================================================

// === Scrolling

- (void)fileStructureItemSelected:(NSString *)item
{
  NSString *firstSymbol;

  NSLog(@"[PCEditor] selected file structure item: %@", item);

  firstSymbol = [item substringToIndex:1];
  if ([firstSymbol isEqualToString:@"@"])      // class selected
    {
      [self scrollToClassName:item];
    }
  else if ([firstSymbol isEqualToString:@"-"]  // method selected
	|| [firstSymbol isEqualToString:@"+"])
    {
      [self scrollToMethodName:item];
    }
}

- (void)scrollToClassName:(NSString *)className
{
  NSEnumerator   *enumerator = nil;
  NSDictionary   *class = nil;
  NSRange        classNameRange;

  NSLog(@"SCROLL to class: \"%@\"", className);

  classNameRange = NSMakeRange(0, 0);
  enumerator = [parserClasses objectEnumerator];
  while ((class = [enumerator nextObject]))
    {
      if ([[class objectForKey:@"ClassName"] isEqualToString:className])
	{
	  classNameRange = 
	    NSRangeFromString([class objectForKey:@"ClassNameRange"]);
	  break;
	}
    }

  NSLog(@"classNameRange: %@", NSStringFromRange(classNameRange));
  if (classNameRange.length != 0)
    {
      [_intEditorView setSelectedRange:classNameRange];
      [_intEditorView scrollRangeToVisible:classNameRange];
    }
}

- (void)scrollToMethodName:(NSString *)methodName
{
  NSEnumerator   *enumerator = nil;
  NSDictionary   *method = nil;
  NSRange        methodNameRange;

  NSLog(@"SCROLL to method: \"%@\"", methodName);

  methodNameRange = NSMakeRange(0, 0);
  enumerator = [parserMethods objectEnumerator];
  while ((method = [enumerator nextObject]))
    {
      if ([[method objectForKey:@"MethodName"] isEqualToString:methodName])
	{
	  methodNameRange = 
	    NSRangeFromString([method objectForKey:@"MethodNameRange"]);
	  break;
	}
    }

  NSLog(@"methodNameRange: %@", NSStringFromRange(methodNameRange));
  if (methodNameRange.length != 0)
    {
      [_intEditorView setSelectedRange:methodNameRange];
      [_intEditorView scrollRangeToVisible:methodNameRange];
    }
}

- (void)scrollToLineNumber:(NSUInteger)lineNumber
{
  [_intEditorView goToLineNumber:lineNumber];
  [_extEditorView goToLineNumber:lineNumber];
}

@end

// ===========================================================================
// ==== Menu actions
// ===========================================================================
@implementation PCEditor (Menu)

- (void)pipeOutputOfCommand:(NSString *)command
{
  NSTask * task;
  NSPipe * inPipe, * outPipe;
  NSString * inString, * outString;
  NSFileHandle * inputHandle;

  inString = [[_intEditorView string] substringWithRange:
    [_intEditorView selectedRange]];
  inPipe = [NSPipe pipe];
  outPipe = [NSPipe pipe];

  task = [[NSTask new] autorelease];

  [task setLaunchPath: @"/bin/sh"];
  [task setArguments: [NSArray arrayWithObjects: @"-c", command, nil]];
  [task setStandardInput: inPipe];
  [task setStandardOutput: outPipe];
  [task setStandardError: outPipe];

  inputHandle = [inPipe fileHandleForWriting];

  [task launch];
  [inputHandle writeData: [inString
    dataUsingEncoding: NSUTF8StringEncoding]];
  [inputHandle closeFile];
  [task waitUntilExit];
  outString = [[[NSString alloc]
    initWithData: [[outPipe fileHandleForReading] availableData]
        encoding: NSUTF8StringEncoding]
    autorelease];
  if ([task terminationStatus] != 0)
    {
      if (NSRunAlertPanel(_(@"Error running command"),
        _(@"The command returned with a non-zero exit status"
          @" -- aborting pipe.\n"
          @"Do you want to see the command's output?\n"),
        _(@"No"), _(@"Yes"), nil) == NSAlertAlternateReturn)
        {
          NSRunAlertPanel(_(@"The command's output"),
            outString, nil, nil, nil);
        }
    }
  else
    {
      [_intEditorView replaceCharactersInRange:[_intEditorView selectedRange]
                              withString:outString];
      [self textDidChange: nil];
    }
}

- (void)findNext:sender
{
//  [[TextFinder sharedInstance] findNext:self];
}

- (void)findPrevious:sender
{
//  [[TextFinder sharedInstance] findPrevious:self];
}

- (void)jumpToSelection:sender
{
  [_intEditorView scrollRangeToVisible:[_intEditorView selectedRange]];
}

@end

// ===========================================================================
// ==== Parenthesis highlighting
// ===========================================================================

/**
 * Checks whether a character is a delimiter.
 *
 * This function checks whether `character' is a delimiter character,
 * (i.e. one of "(", ")", "[", "]", "{", "}") and returns YES if it
 * is and NO if it isn't. Additionaly, if `character' is a delimiter,
 * `oppositeDelimiter' is set to a string denoting it's opposite
 * delimiter and `searchBackwards' is set to YES if the opposite
 * delimiter is located before the checked delimiter character, or
 * to NO if it is located after the delimiter character.
 */
static inline BOOL CheckDelimiter(unichar character,
                                  unichar * oppositeDelimiter,
                                  BOOL * searchBackwards)
{
  if (character == '(')
    {
      *oppositeDelimiter = ')';
      *searchBackwards = NO;

      return YES;
    }
  else if (character == ')')
    {
      *oppositeDelimiter = '(';
      *searchBackwards = YES;

      return YES;
    }
  else if (character == '[')
    {
      *oppositeDelimiter = ']';
      *searchBackwards = NO;

      return YES;
    }
  else if (character == ']')
    {
      *oppositeDelimiter = '[';
      *searchBackwards = YES;

      return YES;
    }
  else if (character == '{')
    {
      *oppositeDelimiter = '}';
      *searchBackwards = NO;

      return YES;
    }
  else if (character == '}')
    {
      *oppositeDelimiter = '{';
      *searchBackwards = YES;

      return YES;
    }
  else
    {
      return NO;
    }
}

/**
 * Attempts to find a delimiter in a certain string around a certain location.
 *
 * Attempts to locate `delimiter' in `string', starting at
 * location `startLocation' a searching forwards (backwards if
 * searchBackwards = YES) at most 1000 characters. The argument
 * `oppositeDelimiter' denotes what is considered to be the opposite
 * delimiter of the one being search for, so that nested delimiters
 * are ignored correctly.
 *
 * @return The location of the delimiter if it is found, or NSNotFound
 *      if it isn't.
 */
NSUInteger FindDelimiterInString(NSString * string,
                                 unichar delimiter,
                                 unichar oppositeDelimiter,
                                 NSUInteger startLocation,
                                 BOOL searchBackwards)
{
  NSUInteger i;
  NSUInteger length;
  unichar (*charAtIndex)(id, SEL, NSUInteger);
  SEL sel = @selector(characterAtIndex:);
  int nesting = 1;

  charAtIndex = (unichar (*)(id, SEL, NSUInteger)) [string
    methodForSelector: sel];

  if (searchBackwards)
    {
      if (startLocation < 1000)
        length = startLocation;
      else
        length = 1000;

      for (i=1; i <= length; i++)
        {
          unichar c;

          c = charAtIndex(string, sel, startLocation - i);
          if (c == delimiter)
            nesting--;
          else if (c == oppositeDelimiter)
            nesting++;

          if (nesting == 0)
            break;
        }

      if (i > length)
        return NSNotFound;
      else
        return startLocation - i;
    }
  else
    {
      if ([string length] < startLocation + 1000)
        length = [string length] - startLocation;
      else
        length = 1000;

      for (i=1; i < length; i++)
        {
          unichar c;

          c = charAtIndex(string, sel, startLocation + i);
          if (c == delimiter)
            nesting--;
          else if (c == oppositeDelimiter)
            nesting++;

          if (nesting == 0)
            break;
        }

      if (i == length)
        return NSNotFound;
      else
        return startLocation + i;
    }
}

@implementation PCEditor (Parenthesis)

- (void)unhighlightCharacter: (NSTextView *)editorView
{
  int           i;
  NSTextStorage *textStorage = [editorView textStorage];

  [textStorage beginEditing];

//  if (isCharacterHighlit)
  for (i = 0; i < 2 && highlited_chars[i] != -1; i++)
    {
      NSRange       r = NSMakeRange(highlited_chars[i], 1);
//      NSRange       r = NSMakeRange(highlitCharacterLocation, i);


      isCharacterHighlit = NO;

      // restore the character's color and font attributes
      if (previousFont != nil)
        {
          [textStorage addAttribute:NSFontAttributeName
                              value:previousFont
                              range:r];
        }
      else
        {
          [textStorage removeAttribute:NSFontAttributeName range:r];
        }

      if (previousFGColor != nil)
        {
          [textStorage addAttribute:NSForegroundColorAttributeName
                              value:previousFGColor
                              range:r];
        }
      else
        {
          [textStorage removeAttribute:NSForegroundColorAttributeName
                                 range:r];
        }

      if (previousBGColor != nil)
        {
          [textStorage addAttribute:NSBackgroundColorAttributeName
                              value:previousBGColor
                              range:r];
        }
      else
        {
          [textStorage removeAttribute:NSBackgroundColorAttributeName
                                 range:r];
        }

      highlited_chars[i] = -1;
    }

  [textStorage endEditing];
}

- (void)highlightCharacterAt:(NSUInteger)location inEditor: (NSTextView *)editorView
{
  int i;

  for (i = 0; i < 2 && highlited_chars[i] != -1; i++) {};

//  if (isCharacterHighlit == NO)
  if (i < 2)
    {
      NSTextStorage *textStorage = [editorView textStorage];
      NSRange       r = NSMakeRange(location, 1);
      NSRange       tmp;

//      NSLog(@"highlight");

//      highlitCharacterLocation = location;
      highlited_chars[i] = location;

      isCharacterHighlit = YES;
      NSAssert(textStorage, @"textstorage can't be nil");
      [textStorage beginEditing];

      // store the previous character's attributes
      ASSIGN(previousFGColor,
        [textStorage attribute:NSForegroundColorAttributeName
                       atIndex:location
                effectiveRange:&tmp]);
      ASSIGN(previousBGColor,
        [textStorage attribute:NSBackgroundColorAttributeName
                       atIndex:location
                effectiveRange:&tmp]);
      ASSIGN(previousFont, [textStorage attribute:NSFontAttributeName
                                          atIndex:location
                                   effectiveRange:&tmp]);

      [textStorage addAttribute:NSFontAttributeName
                          value:highlightFont
                          range:r];
      [textStorage addAttribute:NSBackgroundColorAttributeName
                          value:highlightColor
                          range:r];
/*      [textStorage addAttribute:NSForegroundColorAttributeName
                          value:highlightColor
                          range:r];

      [textStorage removeAttribute:NSBackgroundColorAttributeName
                             range:r];*/

      [textStorage endEditing];
    }
}

- (void)computeNewParenthesisNesting: (NSTextView *)editorView
{
  NSRange  selectedRange;
  NSString *myString;

  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DontTrackNesting"])
    {
      return;
    }

  NSAssert(editorView, @"computeNewParenthesis: editorView is nil");
  selectedRange = [editorView selectedRange];

  // make sure we un-highlight a previously highlit delimiter
  [self unhighlightCharacter :editorView];

  // if we have a character at the selected location, check
  // to see if it is a delimiter character
  myString = [editorView string];
  if (selectedRange.length <= 1 && [myString length] > selectedRange.location)
    {
      unichar c;
      unichar oppositeDelimiter = 0;
      BOOL    searchBackwards = NO;

      c = [myString characterAtIndex:selectedRange.location];

      // if it is, search for the opposite delimiter in a range
      // of at most 1000 characters around it in either forward
      // or backward direction (depends on the kind of delimiter
      // we're searching for).
      if (CheckDelimiter(c, &oppositeDelimiter, &searchBackwards))
        {
          NSUInteger result;

          result = FindDelimiterInString(myString,
                                         oppositeDelimiter,
                                         c,
                                         selectedRange.location,
                                         searchBackwards);

          // and in case a delimiter is found, highlight it
          if (result != NSNotFound)
            {
              [self highlightCharacterAt:selectedRange.location inEditor:editorView];
              [self highlightCharacterAt:result inEditor:editorView];
            }
        }
    }
}

@end

