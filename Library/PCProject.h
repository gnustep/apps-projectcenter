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

#ifndef _PCProject_h_
#define _PCProject_h_

#include <AppKit/AppKit.h>

@class PCProjectManager;
@class PCProjectWindow;
@class PCProjectBrowser;
@class PCProjectHistory;

@class PCProjectInspector;
@class PCProjectBuilder;
@class PCProjectLauncher;
@class PCProjectEditor;

#ifndef GNUSTEP_BASE_VERSION
@protocol ProjectBuilder;
#else
#include <ProjectCenter/ProjectBuilder.h>
#endif

extern NSString *PCProjectDictDidChangeNotification;
extern NSString *PCProjectDictDidSaveNotification;

@interface PCProject : NSObject
{
  PCProjectManager    *projectManager; 
  PCProjectWindow     *projectWindow;
  PCProjectBrowser    *projectBrowser;
  PCProjectHistory    *projectHistory;
  PCProjectEditor     *projectEditor;
  PCProjectBuilder    *projectBuilder;
  PCProjectLauncher   *projectLauncher;

  NSView              *builderContentView;
  NSView              *debuggerContentView;
 
  // For compatibility. Should be changed later
  NSView              *projectProjectInspectorView;
  //

  NSMutableDictionary *projectDict;
  NSString            *projectName;
  NSString            *projectPath;

  NSArray             *rootObjects;
  NSArray             *rootKeys;
  NSDictionary        *rootCategories; // Needs to be initialised by subclasses!
  NSMutableDictionary *buildOptions;

  BOOL                editorIsActive;
}

// ============================================================================
// ==== Init and free
// ============================================================================

- (id)init;
- (id)initWithProjectDictionary:(NSDictionary *)dict path:(NSString *)path;
- (PCProjectManager *)projectManager;
- (void)setProjectManager:(PCProjectManager *)aManager;
- (BOOL)close:(id)sender;
- (void)dealloc;
- (BOOL)saveProjectWindowsAndPanels;

// ============================================================================
// ==== Accessory methods
// ============================================================================

- (PCProjectManager *)projectManager;
- (PCProjectWindow *)projectWindow;
- (PCProjectBrowser *)projectBrowser;
- (PCProjectHistory *)projectHistory;
- (PCProjectBuilder *)projectBuilder;
- (PCProjectLauncher *)projectLauncher;
- (PCProjectEditor *)projectEditor;

- (void)setProjectDictObject:(id)object forKey:(NSString *)key;
- (NSString *)projectName;
- (void)setProjectName:(NSString *)aName;
- (BOOL)isProjectChanged;
- (NSString *)selectedRootCategory;

- (Class)principalClass;

// ===========================================================================
// ==== To be overriden!
// ===========================================================================

// TEMP! For compatibility with old PC*Project subclasses
- (void)updateValuesFromProjectDict;

- (NSView *)projectAttributesView;

- (Class)builderClass;

// Subclasses need to call this before their customised implementation!
- (BOOL)writeMakefile;

- (NSArray *)fileTypesForCategory:(NSString *)category;
- (NSString *)dirForCategory:(NSString *)category;

- (NSArray *)sourceFileKeys;
- (NSArray *)resourceFileKeys;
- (NSArray *)otherKeys;
- (NSArray *)buildTargets;

// Returns a string describing the project type
- (NSString *)projectDescription;

// Returns NO by default.
- (BOOL)isExecutable;
- (NSString *)execToolName;

// ============================================================================
// ==== File Handling
// ============================================================================

// Remove path from "file" and handle special cases like libraries
- (NSString *)projectFileFromFile:(NSString *)file forKey:(NSString *)type;

// Returns YES if type is a valid key and file is not contained in the 
// project already
- (BOOL)doesAcceptFile:(NSString *)file forKey:(NSString *)key;

- (BOOL)addAndCopyFiles:(NSArray *)files forKey:(NSString *)key;
- (void)addFiles:(NSArray *)files forKey:(NSString *)key;
- (BOOL)removeFiles:(NSArray *)files forKey:(NSString *)key;

- (void)renameFile:(NSString *)aFile;

// ============================================================================
// ==== Project handling
// ============================================================================

- (BOOL)assignProjectDict:(NSDictionary *)aDict;
- (NSDictionary *)projectDict;

- (void)setProjectPath:(NSString *)aPath;
- (NSString *)projectPath;

- (NSArray *)rootKeys;
- (NSDictionary *)rootCategories;
- (NSString *)keyForCategory:(NSString *)category;

- (BOOL)save;
- (BOOL)saveAt:(NSString *)projPath;

- (BOOL)writeSpecFile;

- (BOOL)isValidDictionary:(NSDictionary *)aDict;
- (void)updateProjectDict;

// Validates the project dictionary and inserts missing keys if needed. It
// calls isValidDictionary to validate.
- (void)validateProjectDict;

// ============================================================================
// ==== Subprojects
// ============================================================================

- (NSArray *)subprojects;
- (void)addSubproject:(PCProject *)aSubproject;
- (PCProject *)superProject;
- (PCProject *)rootProject;
- (void)newSubprojectNamed:(NSString *)aName;
- (void)removeSubproject:(PCProject *)aSubproject;

- (BOOL)isSubProject;

@end

@interface PCProject (ProjectKeyPaths)

- (NSArray *)contentAtKeyPath:(NSString *)keyPath;
- (BOOL)hasChildrenAtKeyPath:(NSString *)keyPath;
- (NSString *)projectKeyForKeyPath:(NSString *)kp;

@end

#endif

