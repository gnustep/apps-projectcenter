/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2000-2004 Free Software Foundation

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
#include "PCFileManager.h"
#include "PCFileCreator.h"
#include "PCProjectManager.h"
#include "PCProject.h"
#include "PCProjectBrowser.h"
#include "PCServer.h"

#include "PCLogController.h"

@implementation PCFileManager

// ===========================================================================
// ==== Class methods
// ===========================================================================

static PCFileManager *_mgr = nil;

+ (PCFileManager *)fileManager
{
  if (!_mgr)
    {
      _mgr = [[PCFileManager alloc] init];
    }

  return AUTORELEASE(_mgr);
}

// ===========================================================================
// ==== Init and free
// ===========================================================================

- (id)initWithProjectManager:(PCProjectManager *)aProjectManager
{
  if ((self = [super init])) 
    {
      projectManager = aProjectManager;
      creators = [[PCFileCreator sharedCreator] creatorDictionary];
      RETAIN(creators);
    }
  return self;
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog (@"PCFileManager: dealloc");
#endif

  RELEASE(creators);
  RELEASE(newFilePanel);
  
  [super dealloc];
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
//  [openPanel setDelegate:self];
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

- (void)createFile
{
  NSString     *path = nil;
  NSString     *fileName = [nfNameField stringValue];
  NSString     *fileType = [nfTypePB titleOfSelectedItem];
  NSDictionary *theCreator = [creators objectForKey:fileType];
  NSString     *key = [theCreator objectForKey:@"ProjectKey"];

  PCLogInfo(self, @"[createFile] %@", fileName);

  path = [projectManager fileManager:self 
                      willCreateFile:fileName
		             withKey:key];

  PCLogInfo(self, @"creating file at %@", path);

  // Create file
  if (path) 
    {
      NSDictionary  *newFiles = nil;
      PCFileCreator *creator = nil;
      PCProject     *project = [projectManager activeProject];
      NSEnumerator  *enumerator;
      NSString      *aFile;

      creator = [theCreator objectForKey:@"Creator"];
      if (!creator) 
	{
	  NSRunAlertPanel(@"Attention!",
			  @"Could not create %@. The creator is missing!",
			  @"OK",nil,nil,fileName);
	  return;
	}

      // Do it finally...
      newFiles = [creator createFileOfType:fileType path:path project:project];

      // Key: name of file
      enumerator = [[newFiles allKeys] objectEnumerator]; 
      while ((aFile = [enumerator nextObject])) 
	{
	  fileType = [newFiles objectForKey:aFile];
	  theCreator = [creators objectForKey:fileType];
	  key = [theCreator objectForKey:@"ProjectKey"];
	   
	  [projectManager fileManager:self didCreateFile:aFile withKey:key];
	}
    }
}

@end

@implementation PCFileManager (UInterface)

// -- "New File in Project" Panel
- (void)showNewFilePanel
{
  if (!newFilePanel)
    {
      if ([NSBundle loadNibNamed:@"NewFile" owner:self] == NO)
	{
	  PCLogError(self, @"error loading NewFile NIB!");
	  return;
	}
      [newFilePanel setFrameAutosaveName:@"NewFile"];
      if (![newFilePanel setFrameUsingName: @"NewFile"])
    	{
	  [newFilePanel center];
	}
      [newFilePanel center];
      [nfImage setImage:[NSApp applicationIconImage]];
      [nfTypePB setRefusesFirstResponder:YES];
      [nfTypePB removeAllItems];
      [nfTypePB addItemsWithTitles:
	[[creators allKeys] 
	  sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
      [nfTypePB selectItemAtIndex:0];
      [nfCancleButton setRefusesFirstResponder:YES];
      [nfCreateButton setRefusesFirstResponder:YES];
    }

  [self newFilePopupChanged:nfTypePB];

  [newFilePanel makeKeyAndOrderFront:self];
  [nfNameField setStringValue:@""];
  [newFilePanel makeFirstResponder:nfNameField];
}

- (void)closeNewFilePanel:(id)sender
{
  [newFilePanel orderOut:self];
}

- (void)createFile:(id)sender
{
  [self createFile];
  [self closeNewFilePanel:self];
}

- (void)newFilePopupChanged:(id)sender
{
  NSString     *type = [sender titleOfSelectedItem];
  NSDictionary *creator = [creators objectForKey:type];

  if (type)
    {
      [nfDescriptionTV setString:[creator objectForKey:@"TypeDescription"]];
    }
}

- (void)controlTextDidChange:(NSNotification *)aNotif
{
  if ([aNotif object] != nfNameField)
    {
      return;
    }

  // TODO: Add check for valid file names
  if ([[nfNameField stringValue] length] > 0)
    {
      [nfCreateButton setEnabled:YES];
    }
  else
    {
      [nfCreateButton setEnabled:NO];
    }
}

// --- "Add Files..." panel
- (void)_createAddFilesPanel
{
  if (addFilesPanel == nil)
    {
      NSRect    fr = NSMakeRect(20,30,160,21);
      PCProject *project = [projectManager activeProject];

      // File type popup
      fileTypePopup = [[NSPopUpButton alloc] initWithFrame:fr pullsDown:NO];
      [fileTypePopup setRefusesFirstResponder:YES];
      [fileTypePopup setAutoenablesItems:NO];
      [fileTypePopup setTarget:self];
      [fileTypePopup setAction:@selector(filesForAddPopupClicked:)];
      [fileTypePopup addItemsWithTitles:[project rootCategories]];
      [fileTypePopup selectItemAtIndex:0];

      fileTypeAccessaryView = [[NSBox alloc] init];
      [fileTypeAccessaryView setTitle:@"File Types"];
      [fileTypeAccessaryView setTitlePosition:NSAtTop];
      [fileTypeAccessaryView setBorderType:NSGrooveBorder];
      [fileTypeAccessaryView addSubview:fileTypePopup];
      [fileTypeAccessaryView sizeToFit];
      [fileTypeAccessaryView setAutoresizingMask:NSViewMinXMargin 
	                                         | NSViewMaxXMargin];
      RELEASE(fileTypePopup);

      // Panel
      addFilesPanel = [NSOpenPanel openPanel];
      [addFilesPanel setAllowsMultipleSelection:YES];
      [addFilesPanel setDelegate:self];
      [addFilesPanel setAccessoryView:fileTypeAccessaryView];

      RELEASE(fileTypeAccessaryView);
    }
}

- (NSMutableArray *)filesForAdd
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString       *lastOpenDir = [ud objectForKey:@"LastOpenDirectory"];
  PCProject      *project = [projectManager rootActiveProject];
  NSString       *selectedCategory = nil;
  int            retval;

  [self _createAddFilesPanel];
  selectedCategory = [[project projectBrowser] nameOfSelectedCategory];
  if ([selectedCategory isEqualToString:@"Subprojects"])
    {
      [addFilesPanel setCanChooseFiles:NO];
      [addFilesPanel setCanChooseDirectories:YES];
    }
  else if ([selectedCategory isEqualToString:@"Other Resources"])
    {
      [addFilesPanel setCanChooseFiles:YES];
      [addFilesPanel setCanChooseDirectories:YES];
    }
  else
    {
      [addFilesPanel setCanChooseFiles:YES];
      [addFilesPanel setCanChooseDirectories:NO];
    }
  [fileTypePopup selectItemWithTitle:selectedCategory];

  [self filesForAddPopupClicked:self];

  if (!lastOpenDir)
    {
      lastOpenDir = NSHomeDirectory();
    }

  retval = [addFilesPanel runModalForDirectory:lastOpenDir
                                          file:nil
					 types:nil];
  if (retval == NSOKButton) 
    {
      [ud setObject:[addFilesPanel directory] forKey:@"LastOpenDirectory"];
      return [[addFilesPanel filenames] mutableCopy];
    }

  return nil;
}

- (void)filesForAddPopupClicked:(id)sender
{
  NSString  *fileType = [fileTypePopup titleOfSelectedItem];

  [addFilesPanel setTitle:[NSString stringWithFormat:@"Add %@",fileType]];

  if ([fileType isEqualToString:@"Interfaces"])
    {
      [addFilesPanel setCanChooseDirectories:YES];
    }
  
  [addFilesPanel display];
}

// ============================================================================
// ==== NSOpenPanel and NSSavePanel delegate
// ============================================================================

// If file name already in project -- don't show it! 
- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  PCProject     *project = [projectManager activeProject];
  NSArray       *fileTypes = nil;
  NSString      *fileType = nil;
  NSString      *categoryKey = nil;
  BOOL          isDir;

  if (sender != addFilesPanel)
    {
      // This is not "Add Files" panel (Open... or Save...)
      return YES;
    }
    
  // Directories must be shown
  if ([fileManager fileExistsAtPath:filename isDirectory:&isDir] && isDir)
    {
      return YES;
    }

  if (!(fileType = [fileTypePopup titleOfSelectedItem]))
    {
      PCLogWarning(self, @"Selected File type is nil!");
      return YES;
    }
  
  categoryKey = [project keyForCategory:fileType];

  fileTypes = [project fileTypesForCategoryKey:categoryKey];
  if (fileTypes == nil)
    {
      PCLogWarning(self, 
		   @"Project file types is nil! Category: %@", categoryKey);
      return YES;
    }

  if (fileTypes && [fileTypes containsObject:[filename pathExtension]])
    {
      NSString *filePath;
      NSString *projectPath;

      filePath = [[filename stringByDeletingLastPathComponent]
	          stringByResolvingSymlinksInPath];
      projectPath = [[project projectPath] stringByResolvingSymlinksInPath];

      if ([filePath isEqualToString:projectPath])
	{
	  return NO;
	}
      return YES;
    }

  return NO;
}

// Test if we should accept file name selected or entered
- (BOOL)panel:(id)sender isValidFilename:(NSString *)filename
{
  if ([[sender className] isEqualToString:@"NSOpenPanel"])
    {
      ;
    }
  else if ([[sender className] isEqualToString:@"NSSavePanel"])
    {
      ;
    }
    
  return YES;
}

@end

