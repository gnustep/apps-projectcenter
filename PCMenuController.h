/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

   Author: Philippe C.D. Robert <phr@3dkit.org>

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

#ifndef _PCMENUCONTROLLER_H
#define _PCMENUCONTROLLER_H

#include <AppKit/AppKit.h>

@class PCProjectManager;
@class PCFileManager;
@class PCAppController;

@interface PCMenuController : NSObject
{
  PCProjectManager *projectManager;
  PCFileManager	   *fileManager;
  PCAppController  *appController;
  
  NSBox	*projectTypeAccessaryView;
  id    projectTypePopup;

  BOOL  editorIsKey;
}

//============================================================================
//==== Init and free
//============================================================================

- (id)init;
- (void)dealloc;

- (void)setAppController:(id)anObject;
- (void)setFileManager:(id)anObject;
- (void)setProjectManager:(id)anObject;

//============================================================================
//==== Menu stuff
//============================================================================

- (void)addProjectTypeNamed:(NSString *)name;

// Info
- (void)showInfoPanel:(id)sender;
- (void)showPrefWindow:(id)sender;

// Project
- (void)projectOpen:(id)sender;
- (void)projectNew:(id)sender;
- (void)projectSave:(id)sender;
- (void)projectSaveAs:(id)sender;
- (void)projectAddFiles:(id)sender;
- (void)projectSaveFiles:(id)sender;
- (void)projectRemoveFiles:(id)sender;
- (void)projectRevertToSaved:(id)sender;
- (void)projectClose:(id)sender;

// Subproject
- (void)subprojectNew:(id)sender;
- (void)subprojectAdd:(id)sender;
- (void)subprojectRemove:(id)sender;

// File
- (void)fileNew:(id)sender;
- (void)fileOpen:(id)sender;
- (void)fileSave:(id)sender;
- (void)fileSaveAs:(id)sender;
- (void)fileSaveTo:(id)sender;
- (void)fileRevertToSaved:(id)sender;
- (void)fileRename:(id)sender;
- (void)fileClose:(id)sender;

// Edit
- (void)findShowPanel:(id)sender;
- (void)findNext:(id)sender;
- (void)findPrevious:(id)sender;

// Tools
- (void)showInspector:(id)sender;
- (void)showEditorPanel:(id)sender;
- (void)showRunPanel:(id)sender;
- (void)showBuildPanel:(id)sender;
- (void)runTarget:(id)sender;

//============================================================================
//==== Delegate stuff
//============================================================================

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;

- (void)editorDidResignKey:(NSNotification *)aNotification;
- (void)editorDidBecomeKey:(NSNotification *)aNotification;

@end

#endif
