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
*/

#include "PCFileManager+UInterface.h"
#include "PCDefines.h"

#include <AppKit/AppKit.h>

@implementation PCFileManager (UInterface)

// -- "New File in Project" Panel
- (void)showNewFilePanel
{
  if (!newFilePanel)
    {
      if ([NSBundle loadNibNamed:@"NewFile" owner:self] == NO)
	{
	  NSLog(@"PCFileManager: error loading NewFile NIB!");
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
  NSString *type = [sender titleOfSelectedItem];

  if (type)
    {
      [nfDescriptionTV setString:
	[[creators objectForKey:type] objectForKey:@"TypeDescription"]];
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
      [addFilesPanel setCanChooseFiles:YES];
      [addFilesPanel setCanChooseDirectories:NO];
      [addFilesPanel setDelegate:self];
      [addFilesPanel setAccessoryView:fileTypeAccessaryView];
    }
}

- (NSMutableArray *)filesForAdd
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString       *lastOpenDir = [ud objectForKey:@"LastOpenDirectory"];
  int            retval;
  PCProject      *project = [projectManager activeProject];

  [self _createAddFilesPanel];

  [fileTypePopup selectItemWithTitle:[project selectedRootCategory]];

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
      return [[[addFilesPanel filenames] mutableCopy] autorelease];
    }

  return nil;
}

- (void)filesForAddPopupClicked:(id)sender
{
  NSString  *fileType = [fileTypePopup titleOfSelectedItem];

  [addFilesPanel setTitle:[NSString stringWithFormat:@"Add %@",fileType]];
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

//  NSLog(@"Panel should show %@", filename);
  if ([fileManager fileExistsAtPath:filename isDirectory:&isDir] && isDir)
    {
      return YES;
    }

  if (sender != addFilesPanel)
    {
      NSLog(@"Sender is not our panel!");
      return YES;
    }
    
  if (!(fileType = [fileTypePopup titleOfSelectedItem]))
    {
      NSLog(@"Selected File type is nil!");
      return YES;
    }
  
  categoryKey = [project keyForCategory:fileType];

  fileTypes = [project fileTypesForCategoryKey:categoryKey];
  if (fileTypes == nil)
    {
      NSLog(@"Project file types is nil! Category: %@", categoryKey);
      return YES;
    }

//  NSLog(@"%@ : %@", fileTypes, [filename pathExtension]);
  if (fileTypes && [fileTypes containsObject:[filename pathExtension]])
    {
      NSString *filePath;
      NSString *projectPath;

      filePath = [[filename stringByDeletingLastPathComponent]
	          stringByResolvingSymlinksInPath];
      projectPath = [[project projectPath] stringByResolvingSymlinksInPath];

//      NSLog(@"Path: %@ | Project path: %@", filePath, projectPath);
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

