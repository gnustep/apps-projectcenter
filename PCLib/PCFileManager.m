/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

   Author: Philippe C.D. Robert <probert@siggraph.org>

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

   $Id$
*/

#import "PCFileManager.h"
#import "PCDefines.h"
#import "PCProject.h"
#import "PCServer.h"
#import "FileCreator.h"

#import <AppKit/AppKit.h>

#if defined(GNUSTEP)
#import <AppKit/IMLoading.h>
#endif

@interface PCFileManager (CreateUI)

- (void)_initUI;

@end

@implementation PCFileManager (CreateUI)

- (void)_initUI
{
    NSView *_c_view;
    unsigned int style = NSTitledWindowMask 
		       | NSClosableWindowMask 
		       | NSMiniaturizableWindowMask;
    NSBox *box;
    NSRect _w_frame;
    NSMatrix* matrix;
    id button;
    NSButtonCell* buttonCell = [[[NSButtonCell alloc] init] autorelease];
    id textField;
    NSScrollView *scrollView;

    /*
     * the file creation window
     *
     */

    _w_frame = NSMakeRect(100,100,320,240);
    newFileWindow = [[NSWindow alloc] initWithContentRect:_w_frame
						styleMask:style
						backing:NSBackingStoreBuffered
						    defer:NO];
    [newFileWindow setMinSize:NSMakeSize(320,160)];
    [newFileWindow setTitle:@"New File..."];

    box = [[NSBox alloc] init];
    [box setFrame:NSMakeRect(16,172,288,56)];
    fileTypePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(32,2,216,20)
					       pullsDown:NO];
    [fileTypePopup setAutoresizingMask: (NSViewWidthSizable)];
    [fileTypePopup setTarget:self];
    [fileTypePopup setAction:@selector(popupChanged:)];
    [box setTitle:@"File Type"];
    [box setTitlePosition:NSAtTop];
    [box setBorderType:NSGrooveBorder];
    [box setAutoresizingMask: (NSViewWidthSizable | NSViewMinYMargin)];

    [box addSubview:fileTypePopup];
    RELEASE(fileTypePopup);

    _c_view = [newFileWindow contentView];

    _w_frame = NSMakeRect (16,96,288,68);
    scrollView = [[NSScrollView alloc] initWithFrame:_w_frame];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setHasVerticalScroller: YES];
    [scrollView setBorderType: NSBezelBorder];
    [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  
    // This is a placeholder!
    _w_frame = [[scrollView contentView] frame];
    descrView = [[NSTextView alloc] initWithFrame:_w_frame];
    [descrView setMinSize: NSMakeSize (0, 0)];
    [descrView setMaxSize:NSMakeSize(1e7, 1e7)];
    [descrView setRichText:NO];
    [descrView setEditable:NO];
    [descrView setSelectable:YES];
    [descrView setVerticallyResizable:YES];
    [descrView setHorizontallyResizable:NO];
    [descrView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    [[descrView textContainer] setWidthTracksTextView:YES];
    [scrollView setDocumentView:descrView];
    RELEASE(descrView);

    _w_frame.size = NSMakeSize([scrollView contentSize].width,1e7);
    [[descrView textContainer] setContainerSize:_w_frame.size];

    [_c_view addSubview:scrollView];
    RELEASE(scrollView);

    [_c_view addSubview:box];
    RELEASE(box);

    /*
     * Button matrix
     */

    _w_frame = NSMakeRect(188,16,116,24);
    matrix = [[NSMatrix alloc] initWithFrame: _w_frame
				        mode: NSHighlightModeMatrix
                                   prototype: buttonCell
                                numberOfRows: 1
                             numberOfColumns: 2];
    [matrix setSelectionByRect:YES];
    [matrix setAutoresizingMask: (NSViewMinXMargin | NSViewMaxYMargin)];
    [matrix setTarget:self];
    [matrix setAction:@selector(buttonsPressed:)];
    [matrix setIntercellSpacing: NSMakeSize(2,2)];
    [_c_view addSubview:matrix];
    RELEASE(matrix);

    button = [matrix cellAtRow:0 column:0];
    [button setTag:0];
    [button setStringValue:@"Cancel"];
    [button setBordered:YES];
    [button setButtonType:NSMomentaryPushButton];

    button = [matrix cellAtRow:0 column:1];
    [button setTag:1];
    [button setStringValue:@"OK"];
    [button setBordered:YES];
    [button setButtonType:NSMomentaryPushButton];

    /*
     * The name of the new file...
     */

    // Status message
    textField = [[NSTextField alloc] initWithFrame:NSMakeRect(16,56,48,21)];
    [textField setAlignment: NSLeftTextAlignment];
    [textField setBordered: NO];
    [textField setEditable: NO];
    [textField setBezeled: NO];
    [textField setDrawsBackground: NO];
    [textField setStringValue:@"Name:"];
    [textField setAutoresizingMask: (NSViewMaxXMargin | 
				   NSViewWidthSizable | 
				   NSViewMinYMargin)];
    [_c_view addSubview:textField];
    RELEASE(textField);

    // Target
    newFileName = [[NSTextField alloc] initWithFrame:NSMakeRect(56,56,248,21)];
    [newFileName setAlignment: NSLeftTextAlignment];
    [newFileName setBordered: YES];
    [newFileName setBezeled: YES];
    [newFileName setEditable: YES];
    [newFileName setDrawsBackground: YES];
    [newFileName setStringValue:@"NewFile"];
    [newFileName setAutoresizingMask: (NSViewWidthSizable | NSViewMinYMargin)];
    [_c_view addSubview:newFileName];
    RELEASE(newFileName);
}

@end

@implementation PCFileManager

//==============================================================================
// ==== Class methods
//==============================================================================

static PCFileManager *_mgr = nil;

+ (PCFileManager *)fileManager
{
  if (!_mgr) {
    _mgr = [[PCFileManager alloc] init];
  }
  return _mgr;
}

//==============================================================================
// ==== Init and free
//==============================================================================

- (id)init
{
    if ((self = [super init])) 
    {
       	creators = [[NSMutableDictionary alloc] init];
       	typeDescr = [[NSMutableDictionary alloc] init];

	[self _initUI];
    }
    return self;
}

- (void)dealloc
{
  RELEASE(creators);
  RELEASE(newFileWindow);
  RELEASE(typeDescr);
  
  [super dealloc];
}

- (void)awakeFromNib
{
  [fileTypePopup removeAllItems];
}

// ===========================================================================
// ==== Delegate
// ===========================================================================

- (id)delegate
{
  return delegate;
}

- (void)setDelegate:(id)aDelegate
{
  delegate = aDelegate;
}

// ===========================================================================
// ==== File stuff
// ===========================================================================

- (void)showAddFileWindow
{
  NSOpenPanel *openPanel;
  int retval;
  
  PCProject *project = nil;
  NSString *key = nil;
  NSString *title = nil;
  NSArray *types = nil;

  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  if (delegate && 
      [delegate respondsToSelector:@selector(fileManagerWillAddFiles:)]) 
  {

    if (!(project = [delegate fileManagerWillAddFiles:self])) 
    {
      return;
    }
  }

  key = [project selectedRootCategory];

  title = [[[project rootCategories] allKeysForObject:key] objectAtIndex:0];
  title = [NSString stringWithFormat:@"Add to %@...",title];

  types = [project fileExtensionsForCategory:key];

  openPanel = [NSOpenPanel openPanel];
  [openPanel setAllowsMultipleSelection:YES];
  [openPanel setCanChooseDirectories:NO];
  [openPanel setCanChooseFiles:YES];
  [openPanel setTitle:title];

  retval = [openPanel runModalForDirectory:[ud objectForKey:@"LastOpenDirectory"] file:nil types:types];

  if (retval == NSOKButton) 
  {
    NSEnumerator *enumerator;
    NSString *file;
    
    [ud setObject:[openPanel directory] forKey:@"LastOpenDirectory"];
    
    enumerator = [[openPanel filenames] objectEnumerator];
    while (file = [enumerator nextObject]) {
      NSString *otherKey;
      NSString *ext;
      BOOL ret = NO;
      NSString *fn;
      NSString *fileName;
      NSString *pth;

      if ([delegate fileManager:self shouldAddFile:file forKey:key]) 
      {
        NSFileManager *fm = [NSFileManager defaultManager];

	fileName = [file lastPathComponent];
	pth = [[project projectPath] stringByAppendingPathComponent:fileName];
	
	if (![key isEqualToString:PCLibraries]) 
        {
	  if (![fm fileExistsAtPath:pth]) 
          {
	    [fm copyPath:file toPath:pth handler:nil];
	  }
	}
	[project addFile:pth forKey:key];
      }

      if ([key isEqualToString:PCClasses]) 
      {
	otherKey = PCHeaders;
	ext = [NSString stringWithString:@"h"];

	fn = [file stringByDeletingPathExtension];
	fn = [fn stringByAppendingPathExtension:ext];

	if ([[NSFileManager defaultManager] fileExistsAtPath:fn]) 
        {
	  ret = NSRunAlertPanel(@"Adding Header?",
                                @"Should %@ be added to project %@ as well?",
                                @"Yes",@"No",nil,fn,[project projectName]);
	}
      }
      else if ([key isEqualToString:PCHeaders]) 
      {
	otherKey = PCClasses;
	ext = [NSString stringWithString:@"m"];

	fn = [file stringByDeletingPathExtension];
	fn = [fn stringByAppendingPathExtension:ext];

	if ([[NSFileManager defaultManager] fileExistsAtPath:fn]) 
        {
	  ret = NSRunAlertPanel(@"Adding Class?",
                                @"Should %@ be added to project %@ as well?",
                                @"Yes",@"No",nil,fn,[project projectName]);
	}
      }

      if (ret) 
      {
	if ([delegate fileManager:self shouldAddFile:fn forKey:otherKey]) 
        {
	  NSString *pp = [project projectPath];

	  fileName = [fn lastPathComponent];
	  pth = [pp stringByAppendingPathComponent:fileName];

          /* Only copy the file if it isn't already there */
	  if ([pth isEqual: fn] == NO)
	    [[NSFileManager defaultManager] copyPath:fn toPath:pth handler:nil];

	  [project addFile:pth forKey:otherKey];
	}
      }
    }
  }
}

- (void)showNewFileWindow
{
  [self popupChanged:fileTypePopup];

  [newFileWindow center];
  [newFileWindow makeKeyAndOrderFront:self];
}

- (void)buttonsPressed:(id)sender
{
  switch ([[sender selectedCell] tag]) 
  {
  case 0:
    break;
  case 1:
    [self createFile];
    break;
  }
  [newFileWindow orderOut:self];
  [newFileName setStringValue:@""];
}

- (void)popupChanged:(id)sender
{
    NSString *k = [sender titleOfSelectedItem];
    NSString *t = [typeDescr objectForKey:k];

    if( k )
    {
	[descrView setText:t];
    }
}

- (void)createFile
{
  NSString *path = nil;
  NSString *fileName = [newFileName stringValue];
  NSString *fileType = [fileTypePopup titleOfSelectedItem];
  NSString *key = [[creators objectForKey:fileType] objectForKey:@"ProjectKey"];
  
  if (delegate) 
  {
    path = [delegate fileManager:self willCreateFile:fileName withKey:key];
  }

#ifdef DEBUG  
  NSLog(@"<%@ %x>: creating file at %@",[self class],self,path);
#endif //DEBUG

  // Create file
  if (path) 
  {
    NSDictionary *newFiles;
    id<FileCreator> creator = [[creators objectForKey:fileType] objectForKey:@"Creator"];
    PCProject *p = [delegate activeProject];

    if (!creator) 
    {
      NSRunAlertPanel(@"Attention!",
                      @"Could not create %@. The creator is missing!",
                      @"OK",nil,nil,fileName);
      return;
    }
    
    // Do it finally...
    newFiles = [creator createFileOfType:fileType path:path project:p];
    if (delegate 
        && [delegate respondsToSelector:@selector(fileManager:didCreateFile:withKey:)]) 
    {
      NSEnumerator *enumerator;
      NSString *aFile;
      
      enumerator = [[newFiles allKeys] objectEnumerator]; // Key: name of file
      while (aFile = [enumerator nextObject]) 
      {
	NSString *theType = [newFiles objectForKey:aFile];
	NSString *theKey = [[creators objectForKey:theType] objectForKey:@"ProjectKey"];
	
	[delegate fileManager:self didCreateFile:aFile withKey:theKey];
      }
    }
  }
}

- (void)registerCreatorsWithObjectsAndKeys:(NSDictionary *)dict
{
  NSEnumerator *enumerator = [dict keyEnumerator];
  id type;

#ifdef DEBUG  
  NSLog(@"<%@ %x>: Registering creators...",[self class],self);
#endif //DEBUG

  while (type = [enumerator nextObject]) 
  {
    NSDictionary *cd = [dict objectForKey:type];
    id creator = [cd objectForKey:@"Creator"];
    
    if (![creator conformsToProtocol:@protocol(FileCreator)]) 
    {
      [NSException raise:@"FileManagerGenericException" 
            format:@"The target does not conform to the FileCreator protocol!"];
      return;
    }
    
    if ([creators objectForKey:type]) 
    {
      [NSException raise:@"FileManagerGenericException" 
                 format:@"There is alreay a creator registered for this type!"];
      return;
    }
    
    // Register the creator!
    [creators setObject:[dict objectForKey:type] forKey:type];
    [fileTypePopup addItemWithTitle:type];

    if( [cd objectForKey:@"TypeDescription"] )
    {
        [typeDescr setObject:[cd objectForKey:@"TypeDescription"] forKey:type];
    }
  }
}

@end



