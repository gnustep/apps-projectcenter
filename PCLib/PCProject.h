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

#import <AppKit/AppKit.h>

#import "ProjectBuilder.h"

#ifndef IMAGE
#define IMAGE(X) [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:(X)]] autorelease]
#endif

#define BUILD_ARGS_KEY      @"BuildArgsKey"
#define BUILD_HOST_KEY      @"BuildHostKey"

#define TARGET_MAKE         @"Make"
#define TARGET_MAKE_DEBUG   @"MakeDebug"
#define TARGET_MAKE_PROFILE @"MakeProfile"
#define TARGET_MAKE_INSTALL @"MakeInstall"
#define TARGET_MAKE_CLEAN   @"MakeClean"

#define TOUCHED_NOTHING		(0)
#define TOUCHED_EVERYTHING	(1 << 0)
#define TOUCHED_PROJECT_NAME	(1 << 1)
#define TOUCHED_LANGUAGE	(1 << 2)
#define TOUCHED_PROJECT_TYPE	(1 << 3)
#define TOUCHED_INSTALL_DIR	(1 << 4)
#define TOUCHED_ICON_NAMES	(1 << 5)
#define TOUCHED_FILES		(1 << 6)
#define TOUCHED_MAINNIB		(1 << 7)
#define TOUCHED_PRINCIPALCLASS	(1 << 8)
#define TOUCHED_TARGETS		(1 << 9)
#define TOUCHED_PB_PROJECT	(1 << 10)
#define TOUCHED_SYST_EXT	(1 << 11)
#define TOUCHED_EXTENSION	(1 << 12)
#define TOUCHED_PATHS		(1 << 13)

typedef int PCProjInfoBits;

//=============================================================================
// ==== Project keys
//=============================================================================

static NSString * const PCClasses = @"CLASS_FILES";
static NSString * const PCHeaders = @"HEADER_FILES";
static NSString * const PCOtherSources = @"OTHER_SOURCES";
static NSString * const PCOtherResources = @"OTHER_RESOURCES";
static NSString * const PCSupportingFiles = @"SUPPORTING_FILES";
static NSString * const PCDocuFiles = @"DOCU_FILES";
static NSString * const PCSubprojects = @"SUBPROJECTS";
static NSString * const PCGModels = @"INTERFACES";
static NSString * const PCImages = @"IMAGES";
static NSString * const PCLibraries = @"LIBRARIES";
static NSString * const PCCompilerOptions = @"COMPILEROPTIONS";
static NSString * const PCProjectName = @"PROJECT_NAME";
static NSString * const PCProjType = @"PROJECT_TYPE";
static NSString * const PCPrincipalClass = @"PRINCIPAL_CLASS";
static NSString * const PCAppIcon = @"APPLICATIONICON";
static NSString * const PCAppClass = @"APPCLASS";
static NSString * const PCToolIcon = @"TOOLICON";
static NSString * const PCProjectBuilderClass = @"PROJECT_BUILDER";
static NSString * const PCMainGModelFile = @"MAININTERFACE";
static NSString * const PCPackageName = @"PACKAGE_NAME";
static NSString * const PCLibraryVar = @"LIBRARY_VAR";

@class PCProjectBuilder;
@class PCProjectDebugger;

@interface PCProject : NSObject
{
    id projectWindow;
    id delegate;
    id projectManager;
    id browserController;

    PCProjectBuilder *projectBuilder;
    PCProjectDebugger *projectDebugger;
    NSBox *box;

    id projectAttributeInspectorView;
    NSTextField *installPathField;
    NSTextField *toolField;
    NSTextField *ccOptField;
    NSTextField *ldOptField;

    id projectProjectInspectorView;
    NSTextField *projectTypeField;

    id projectFileInspectorView;
    NSTextField *fileNameField;
    NSButton *changeFileNameButton;
    
    id buildTargetPanel;
    id buildTargetHostField;
    id buildTargetArgsField;
    
    NSString *projectName;
    NSString *projectPath;
    NSMutableDictionary *projectDict;

    NSDictionary *rootCategories; // Needs to be initialised by subclasses!
    NSMutableDictionary *buildOptions;
}

//=============================================================================
// ==== Init and free
//=============================================================================

- (id)init;
- (id)initWithProjectDictionary:(NSDictionary *)dict path:(NSString *)path;

- (void)dealloc;

//=============================================================================
// ==== Accessor methods
//=============================================================================

- (id)browserController;
- (NSString *)selectedRootCategory;

- (NSArray *)fileExtensionsForCategory:(NSString *)key;

- (void)setProjectName:(NSString *)aName;
- (NSString *)projectName;
- (NSWindow *)projectWindow;

- (Class)principalClass;

//=============================================================================
// ==== Delegate and manager
//=============================================================================

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (void)setProjectBuilder:(id<ProjectBuilder>)aBuilder;
- (id<ProjectBuilder>)projectBuilder;

//=============================================================================
// ==== To be overriden!
//=============================================================================

- (BOOL)writeMakefile;
    // Writes the PC.project file to disc. Subclasses need to call this before doing sth else!

- (BOOL)isValidDictionary:(NSDictionary *)aDict;

- (NSArray *)sourceFileKeys;
- (NSArray *)resourceFileKeys;
- (NSArray *)otherKeys;
- (NSArray *)buildTargets;

- (NSString *)projectDescription;
    // Returns a string describing the project type

- (BOOL)isExecutable;
    // Returns NO by default.

//=============================================================================
// ==== File Handling
//=============================================================================

- (void)browserDidSelectFileNamed:(NSString *)fileName;

- (BOOL)doesAcceptFile:(NSString *)file forKey:(NSString *)key;
    // Returns YES if type is a valid key and file is not contained in the project already

- (void)addFile:(NSString *)file forKey:(NSString *)key;
- (void)addFile:(NSString *)file forKey:(NSString *)key copy:(BOOL)yn;

- (void)removeFile:(NSString *)file forKey:(NSString *)key;
- (BOOL)removeSelectedFilePermanently:(BOOL)yn;
- (void)renameFile:(NSString *)aFile;

- (BOOL)assignProjectDict:(NSDictionary *)aDict;
- (NSDictionary *)projectDict;

- (void)setProjectPath:(NSString *)aPath;
- (NSString *)projectPath;

- (NSDictionary *)rootCategories;

- (BOOL)save;
- (BOOL)saveAt:(NSString *)projPath;

- (BOOL)saveFileNamed:(NSString *)file;
- (BOOL)saveAllFiles;
- (BOOL)saveAllFilesIfNeeded;
    // Saves all the files that need to be saved.

//=============================================================================
// ==== Subprojects
//=============================================================================

- (NSArray *)subprojects;
- (void)addSubproject:(PCProject *)aSubproject;
- (PCProject *)superProject;
- (PCProject *)rootProject;
- (void)newSubprojectNamed:(NSString *)aName;
- (void)removeSubproject:(PCProject *)aSubproject;

- (BOOL)isSubProject;

//=============================================================================
// ==== Project Handling
//=============================================================================

- (void)updateValuesFromProjectDict;

@end

@interface PCProject (ProjectBuilding)

- (void)topButtonsPressed:(id)sender;
- (void)showBuildView:(id)sender;
- (void)showRunView:(id)sender;

- (void)showInspector:(id)sender;

- (id)updatedAttributeView;
- (id)updatedProjectView;
- (id)updatedFilesView;

- (void)showBuildTargetPanel:(id)sender;
- (void)setHost:(id)sender;
- (void)setArguments:(id)sender;

- (NSDictionary *)buildOptions;

@end

@interface PCProject (ProjectKeyPaths)

- (NSArray *)contentAtKeyPath:(NSString *)keyPath;
- (BOOL)hasChildrenAtKeyPath:(NSString *)keyPath;
- (NSString *)projectKeyForKeyPath:(NSString *)kp;

@end

@interface PCProject (ProjectWindowDelegate)

- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (void)windowDidBecomeMain:(NSNotification *)aNotification;
- (void)windowWillClose:(NSNotification *)aNotification;

@end
