/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2000-2002 Free Software Foundation

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

#include "PCDefines.h"
#include "PCFileManager.h"
#include "PCFileCreator.h"
#include "PCProjectManager.h"
#include "PCProject.h"
#include "PCServer.h"

#include "PCFileManager+UInterface.h"

@implementation PCFileManager

//============================================================================
// ==== Class methods
//============================================================================

static PCFileManager *_mgr = nil;

+ (PCFileManager *)fileManager
{
  if (!_mgr)
    {
      _mgr = [[PCFileManager alloc] init];
    }

  return _mgr;
}

//============================================================================
// ==== Init and free
//============================================================================

- (id)initWithProjectManager:(PCProjectManager *)aProjectManager
{
  if ((self = [super init])) 
    {
      projectManager = aProjectManager;
      creators = [[NSMutableDictionary alloc] init];
      typeDescr = [[NSMutableDictionary alloc] init];
      [self _initUI];
      [self registerCreators];
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

- (NSMutableArray *)filesForOpenOfType:(NSArray *)types
                              multiple:(BOOL)yn
			         title:(NSString *)title
			       accView:(NSView *)accessoryView
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString       *lastOpenDir = [ud objectForKey:@"LastOpenDirectory"];
  NSOpenPanel    *openPanel = nil;
  int            retval;

  openPanel = [NSOpenPanel openPanel];
  [openPanel setAllowsMultipleSelection:yn];
  [openPanel setCanChooseFiles:YES];
  [openPanel setCanChooseDirectories:NO];
  [openPanel setDelegate:self];
  [openPanel setTitle:title];
  [openPanel setAccessoryView:accessoryView];

  if (!lastOpenDir)
    {
      lastOpenDir = NSHomeDirectory();
    }

  retval = [openPanel runModalForDirectory:lastOpenDir file:nil types:types];
  if (retval == NSOKButton) 
    {
      [ud setObject:[openPanel directory] forKey:@"LastOpenDirectory"];
      return [[[openPanel filenames] mutableCopy] autorelease];
    }

  return nil;
}

- (NSString *)fileForSaveOfType:(NSArray *)types
		          title:(NSString *)title
		        accView:(NSView *)accessoryView
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString       *lastOpenDir = [ud objectForKey:@"LastOpenDirectory"];
  NSSavePanel    *savePanel = nil;
  int            retval;

  savePanel = [NSSavePanel savePanel];
  [savePanel setDelegate:self];
  [savePanel setTitle:title];
//  [savePanel setAccessoryView:nil];
  [savePanel setAccessoryView:accessoryView];

  if (!lastOpenDir)
    {
      lastOpenDir = NSHomeDirectory();
    }

  retval = [savePanel runModalForDirectory:lastOpenDir file:nil];
  if (retval == NSOKButton) 
    {
      [ud setObject:[savePanel directory] forKey:@"LastOpenDirectory"];
      return [[[savePanel filename] mutableCopy] autorelease];
    }

  return nil;
}

- (BOOL)copyFiles:(NSArray *)files intoDirectory:(NSString *)directory
{
  NSEnumerator *enumerator;
  NSString     *file = nil;
  NSString     *fileName = nil;
  NSString     *path = nil;

  if (!files)
    {
      return NO;
    }

  enumerator = [files objectEnumerator];
  while ((file = [enumerator nextObject]))
    {
      NSFileManager *fm = [NSFileManager defaultManager];

      fileName = [file lastPathComponent];
      path = [directory stringByAppendingPathComponent:fileName];

      if (![fm fileExistsAtPath:path]) 
	{
	  if (![fm copyPath:file toPath:path handler:nil])
	    {
	      return NO;
	    }
	}
    }

  return YES;
}

- (BOOL)removeFiles:(NSArray *)files fromDirectory:(NSString *)directory
{
  NSEnumerator  *filesEnum = nil;
  NSString      *file = nil;
  NSString      *path = nil;
  NSFileManager *fm = [NSFileManager defaultManager];

  if (!files)
    {
      return NO;
    }

  filesEnum = [files objectEnumerator];
  while ((file = [filesEnum nextObject]))
    {
      path = [directory stringByAppendingPathComponent:file];
      if (![fm removeFileAtPath:path handler:nil])
	{
	  return NO;
	}
    }
  return YES;
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

  if( k ) 
    {
#ifdef GNUSTEP_BASE_VERSION
      [descrView setText:[typeDescr objectForKey:k]];
#else
      [descrView setString:[typeDescr objectForKey:k]];
#endif
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
  NSLog(@"<%@ %x>: creating file at %@", [self class], self, path);
#endif //DEBUG

  // Create file
  if (path) 
    {
      NSDictionary  *newFiles;
      PCFileCreator *creator = [[creators objectForKey:fileType] objectForKey:@"Creator"];
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
	  while ((aFile = [enumerator nextObject])) 
	    {
	      NSString *theType = [newFiles objectForKey:aFile];
	      NSString *theKey = [[creators objectForKey:theType] objectForKey:@"ProjectKey"];

	      [delegate fileManager:self didCreateFile:aFile withKey:theKey];
	    }
	}
    }
}

- (void)registerCreators
{
  NSDictionary *dict = [[PCFileCreator sharedCreator] creatorDictionary];
  NSEnumerator *enumerator = [dict keyEnumerator];
  id           type;

  while ((type = [enumerator nextObject])) 
    {
      NSDictionary *cd = [dict objectForKey:type];
      id           creator = [cd objectForKey:@"Creator"];

      if (!creator) 
	{
	  [NSException raise:@"FileManagerGenericException" 
	    format:@"The target does not conform to the FileCreator protocol!"];
	  return;
	}

      if ([creators objectForKey:type]) 
	{
	  [NSException raise:@"FileManagerGenericException" 
	    format:@"There is already a creator registered for this type!"];
	  return;
	}

      // Register the creator!
      [creators setObject:[dict objectForKey:type] forKey:type];
      [fileTypePopup addItemWithTitle:type];

      if ([cd objectForKey:@"TypeDescription"])
	{
	  [typeDescr setObject:[cd objectForKey:@"TypeDescription"] forKey:type];
	}
  }
}

@end

