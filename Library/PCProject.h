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

#ifndef _PCProject_h_
#define _PCProject_h_

#include <AppKit/AppKit.h>

#include "PCProjectManager.h"

@class PCProjectManager;
@class PCProjectWindow;
@class PCProjectBrowser;
@class PCProjectLoadedFiles;

@class PCProjectInspector;
@class PCProjectBuilder;
@class PCProjectLauncher;
@class PCProjectEditor;

/*#ifndef GNUSTEP_BASE_VERSION
@protocol ProjectBuilder;
#else
#include <ProjectCenter/ProjectBuilder.h>
#endif*/

extern NSString *PCProjectDictDidChangeNotification;
extern NSString *PCProjectDictDidSaveNotification;

@interface PCProject : NSObject
{
  PCProjectManager     *projectManager; 
  PCProjectWindow      *projectWindow;
  PCProjectBrowser     *projectBrowser;
  PCProjectLoadedFiles *projectLoadedFiles;
  PCProjectEditor      *projectEditor;
  PCProjectBuilder     *projectBuilder;
  PCProjectLauncher    *projectLauncher;

  NSMutableDictionary  *projectDict;
  NSString             *projectName;
  NSString             *projectPath;

  NSArray              *rootKeys;       // e.g. CLASS_FILES
  NSArray              *rootCategories; // e.g. Classes
  NSDictionary         *rootEntries;    // Initialised by subclasses

  NSMutableDictionary  *buildOptions;

  PCProject            *activeSubproject;

  // Subproject
  NSMutableArray       *loadedSubprojects;
  BOOL                 isSubproject;
  PCProject            *rootProject;
  PCProject            *superProject;
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
- (PCProjectLoadedFiles *)projectLoadedFiles;
- (PCProjectBuilder *)projectBuilder;
- (PCProjectLauncher *)projectLauncher;
- (PCProjectEditor *)projectEditor;

- (void)setProjectDictObject:(id)object forKey:(NSString *)key notify:(BOOL)yn;
- (NSString *)projectName;
- (void)setProjectName:(NSString *)aName;
- (BOOL)isProjectChanged;

// ===========================================================================
// ==== Can be overriden
// ===========================================================================

// Project Attributes Inspector
- (NSView *)projectAttributesView;

- (Class)builderClass;
- (NSString *)projectDescription; // Project type
- (BOOL)isExecutable;
- (NSString *)execToolName;
- (BOOL)canHavePublicHeaders;
- (NSArray *)publicHeaders;
- (void)setHeaderFile:(NSString *)file public:(BOOL)yn;
- (void)setLocalizableFile:(NSString *)file public:(BOOL)yn;

- (NSArray *)buildTargets;
// Files placed into /
- (NSArray *)sourceFileKeys;
// Files placed into /Resources or /Language.lproj
- (NSArray *)resourceFileKeys;
- (NSArray *)otherKeys;
- (NSArray *)allowableSubprojectTypes;
- (NSArray *)localizableKeys;

- (BOOL)isEditableCategory:(NSString *)category;
- (NSArray *)fileTypesForCategoryKey:(NSString *)key;
- (NSString *)categoryKeyForFileType:(NSString *)type;
- (NSString *)dirForCategoryKey:(NSString *)key;
- (NSString *)complementaryTypeForType:(NSString *)type;

// Subclasses need to call this before their customised implementation!
- (BOOL)writeMakefile;

// ============================================================================
// ==== File Handling
// ============================================================================

// Remove path from "file" and handle special cases like libraries
- (NSString *)projectFileFromFile:(NSString *)file forKey:(NSString *)type;

// Returns YES if type is a valid key and file is not contained in the 
// project already
- (BOOL)doesAcceptFile:(NSString *)file forKey:(NSString *)key;

- (BOOL)addAndCopyFiles:(NSArray *)files forKey:(NSString *)key;
- (void)addFiles:(NSArray *)files forKey:(NSString *)key notify:(BOOL)yn;
- (BOOL)removeFiles:(NSArray *)files forKey:(NSString *)key notify:(BOOL)yn;
- (BOOL)renameFile:(NSString *)fromFile toFile:(NSString *)toFile;

// ============================================================================
// ==== Project handling
// ============================================================================

- (BOOL)assignProjectDict:(NSDictionary *)aDict;
- (NSDictionary *)projectDict;

- (void)setProjectPath:(NSString *)aPath;
- (NSString *)projectPath;

- (NSArray *)rootKeys;
- (NSArray *)rootCategories;
- (NSDictionary *)rootEntries;
- (NSString *)keyForCategory:(NSString *)category;
- (NSString *)categoryForKey:(NSString *)key;

- (BOOL)save;

- (BOOL)isValidDictionary:(NSDictionary *)aDict;
- (void)updateProjectDict;

// Validates the project dictionary and inserts missing keys if needed. It
// calls isValidDictionary to validate.
- (void)validateProjectDict;

// ============================================================================
// ==== Subprojects
// ============================================================================

- (NSArray *)loadedSubprojects;
- (PCProject *)activeSubproject;

- (BOOL)isSubproject;
- (void)setIsSubproject:(BOOL)yn;
- (PCProject *)superProject;
- (void)setSuperProject:(PCProject *)project;

- (PCProject *)subprojectWithName:(NSString *)name;

- (void)addSubproject:(PCProject *)aSubproject;
- (void)addSubprojectWithName:(NSString *)name;
- (BOOL)removeSubproject:(PCProject *)aSubproject;
- (BOOL)removeSubprojectWithName:(NSString *)subprojectName;

@end

@interface PCProject (CategoryPaths)

- (NSArray *)contentAtCategoryPath:(NSString *)categoryPath;
- (BOOL)hasChildrenAtCategoryPath:(NSString *)keyPath;

- (NSString *)rootCategoryForCategoryPath:(NSString *)categoryPath;
//- (NSString *)categoryForCategoryPath:(NSString *)categoryPath;
- (NSString *)keyForRootCategoryInCategoryPath:(NSString *)categoryPath;
//- (NSString *)keyForCategoryPath:(NSString *)categoryPath;

@end

#endif

