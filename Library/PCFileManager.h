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

#ifndef _PCFileManager_h
#define _PCFileManager_h

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

@class PCProject;
@class PCProjectManager;

@interface PCFileManager : NSObject
{
  PCProjectManager *projectManager;
  id               newFileWindow;
//  id               fileTypePopup;
  id               newFileName;
  id               descrView;

  id delegate;                    // PCProjectManager

  NSMutableDictionary *creators;
  NSMutableDictionary *typeDescr;

  NSOpenPanel      *addFilesPanel;
  NSBox	           *fileTypeAccessaryView;
  NSPopUpButton    *fileTypePopup;
}

//==============================================================================
// ==== Class methods
//==============================================================================

+ (PCFileManager *)fileManager;

//==============================================================================
// ==== Init and free
//==============================================================================

- (id)initWithProjectManager:(PCProjectManager *)aProjectManager;
- (void)dealloc;

- (void)awakeFromNib;

// ===========================================================================
// ==== Delegate
// ===========================================================================

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

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

// Return NO if coping of any file failed
- (BOOL)copyFiles:(NSArray *)files intoDirectory:(NSString *)directory;

// Return NO if removing of any file failed
- (BOOL)removeFiles:(NSArray *)files fromDirectory:(NSString *)directory;

- (void)showNewFileWindow;
- (void)buttonsPressed:(id)sender;
- (void)popupChanged:(id)sender;

- (void)createFile;

- (void)registerCreators;

@end

@interface  NSObject (FileManagerDelegates)

// Returns the correct, full path - or nil!
- (NSString *)fileManager:(id)sender
           willCreateFile:(NSString *)aFile
	          withKey:(NSString *)key;

- (void)fileManager:(id)sender
      didCreateFile:(NSString *)aFile
            withKey:(NSString *)key;
@end

#endif
