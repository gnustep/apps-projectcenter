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

#ifndef _PCPROJECTMANAGER_H
#define _PCPROJECTMANAGER_H

#import <AppKit/AppKit.h>

#import "PCProject.h"
#import "ProjectBuilder.h"

@interface PCProjectManager : NSObject <ProjectBuilder>
{
  id			delegate;      // The PCAppController
  id			fileManager;

  id			inspector;
  id			inspectorView;
  id			inspectorPopup;
  
  NSMutableDictionary	*loadedProjects;
  PCProject 		*activeProject;
  
  NSString		*rootBuildPath;

  NSTimer		*saveTimer;

  @private
  BOOL _needsReleasing;
}

// ===========================================================================
// ==== Intialization & deallocation
// ===========================================================================

- (id)init;
- (void)dealloc;

// ===========================================================================
// ==== Delegate
// ===========================================================================

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

// ===========================================================================
// ==== Timer handling
// ===========================================================================

- (void)resetSaveTimer:(NSNotification *)notif;

// ===========================================================================
// ==== Project management
// ===========================================================================

- (NSMutableDictionary *)loadedProjects;
    // Returns all currently loaded projects. They are stored with their absolut paths as the keys.

- (PCProject *)activeProject;
    // Returns the currently active project

- (void)setActiveProject:(PCProject *)aProject;
    // Sets the new currently active project

- (void)saveAllProjectsIfNeeded;
    // Calls saveAllProjects if the preferences are setup accordingly.

- (void)saveAllProjects;
    // Saves all projects if needed.

- (NSString *)rootBuildPath;
    // Gets set while initialising!

// ===========================================================================
// ==== Project actions
// ===========================================================================

- (PCProject *)loadProjectAt:(NSString *)aPath;
    // Returns the loaded project if the builder class is known, nil else.

- (BOOL)openProjectAt:(NSString *)aPath;
    // Invokes loadProjectAt to load the project properly.

- (BOOL)createProjectOfType:(NSString *)projectType path:(NSString *)aPath;
    // projectType is exactly the name of the class to be invoked to create the project!

- (BOOL)saveProject;
   // Saves the current project

- (BOOL)saveProjectAs:(NSString *)projName;

- (void)inspectorPopupDidChange:(id)sender;

- (void)showInspectorForProject:(PCProject *)aProject;
    // Opens the inspector for aProject

- (void)saveFiles;
   // Saves all the edited files from the currently active project

- (void)revertToSaved;
   // Reverts the currently active project

- (BOOL)newSubproject;
- (BOOL)addSubprojectAt:(NSString *)path;
- (void)removeSubproject;

- (void)closeProject:(PCProject *)aProject;
- (void)closeProject;
   // Closes the currently active project

// ===========================================================================
// ==== File actions
// ===========================================================================

- (BOOL)openFile:(NSString *)path;

- (BOOL)saveFile;
- (BOOL)revertFile;
- (BOOL)renameFileTo:(NSString *)path;
- (BOOL)removeFilePermanently:(BOOL)yn;

@end

@interface  PCProjectManager (FileManagerDelegates)

- (NSString *)fileManager:(id)sender willCreateFile:(NSString *)aFile withKey:(NSString *)key;
    // Returns the full path if the type is valid, nil else.

- (void)fileManager:(id)sender didCreateFile:(NSString *)aFile withKey:(NSString *)key;
    // Adds the file to the project and updates the makefile!

- (id)fileManagerWillAddFiles:(id)sender;
    // Returns the active project

- (BOOL)fileManager:(id)sender shouldAddFile:(NSString *)file forKey:(NSString *)key;

- (void)fileManager:(id)sender didAddFile:(NSString *)file forKey:(NSString *)key;
    // Adds the file to the project and update the makefile!

@end

@interface NSObject (PCProjectManagerDelegates)

- (void)projectManager:(id)sender willCloseProject:(PCProject *)aProject;
- (void)projectManager:(id)sender didCloseProject:(PCProject *)aProject;
- (void)projectManager:(id)sender didOpenProject:(PCProject *)aProject;
- (BOOL)projectManager:(id)sender shouldOpenProject:(PCProject *)aProject;

@end

extern NSString *ActiveProjectDidChangeNotification;

#endif
