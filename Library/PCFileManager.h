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

#ifndef _PCFileManager_h
#define _PCFileManager_h

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

@class PCProject;
@class PCProjectManager;
@class PCAddFilesPanel;

@interface PCFileManager : NSObject
{
  PCProjectManager       *projectManager;
  id                     delegate;        // PCProjectManager

  NSDictionary           *creators;

  // New File in Project panel
  IBOutlet NSPanel       *newFilePanel;
  IBOutlet NSImageView   *nfImage;
  IBOutlet NSPopUpButton *nfTypePB;
  IBOutlet NSTextView    *nfDescriptionTV;
  IBOutlet NSTextField   *nfNameField;
  IBOutlet NSButton      *nfCancleButton;
  IBOutlet NSButton      *nfCreateButton;

  PCAddFilesPanel        *addFilesPanel;
}

//==============================================================================
// ==== Class methods
//==============================================================================

+ (PCFileManager *)defaultManager;

//==============================================================================
// ==== Init and free
//==============================================================================

- (id)initWithProjectManager:(PCProjectManager *)aProjectManager;
- (void)dealloc;

// ===========================================================================
// ==== File stuff
// ===========================================================================

// Shows NSOpenPanel and return selected files if any
- (NSMutableArray *)filesForOpenOfType:(NSArray *)types
                              multiple:(BOOL)yn
			         title:(NSString *)title
			       accView:(NSView *)accessoryView;
				
- (NSString *)fileForSaveOfType:(NSArray *)types
		          title:(NSString *)title
		        accView:(NSView *)accessoryView;

// Checks if directories in path exists and creates if not.
- (BOOL)createDirectoriesIfNeededAtPath:(NSString *)path;

// Create directories in toFile path if needed
- (BOOL)copyFile:(NSString *)file toFile:(NSString *)toFile;

// Calls copyFile:toFile:
- (BOOL)copyFile:(NSString *)file intoDirectory:(NSString *)directory;

// Calls copyFile:intoDirectory in cycle
- (BOOL)copyFiles:(NSArray *)files intoDirectory:(NSString *)directory;

// Return NO if removing of any file failed
- (BOOL)removeFiles:(NSArray *)files fromDirectory:(NSString *)directory;

- (void)createFile;

@end

@interface PCFileManager (UInterface)

- (void)showNewFilePanel;
- (void)closeNewFilePanel:(id)sender;
- (void)createFile:(id)sender;
- (void)newFilePopupChanged:(id)sender;

- (NSMutableArray *)filesForAddOfTypes:(NSArray*)fileTypes;

@end

#endif
