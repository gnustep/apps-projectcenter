/*
   GNUstep ProjectCenter - http://www.gnustep.org

   Copyright (C) 2001 Free Software Foundation

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

#ifndef _PCPROJECT_H
#define _PCPROJECT_H

#import <AppKit/AppKit.h>

#ifndef IMAGE
#define IMAGE(X) [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:(X)]] autorelease]
#endif

//=============================================================================
// ==== DEFINES
//=============================================================================

#define BUILD_ARGS_KEY      @"BuildArgsKey"
#define BUILD_HOST_KEY      @"BuildHostKey"

#define TARGET_MAKE         @"Make"
#define TARGET_MAKE_DEBUG   @"MakeDebug"
#define TARGET_MAKE_PROFILE @"MakeProfile"
#define TARGET_MAKE_INSTALL @"MakeInstall"
#define TARGET_MAKE_CLEAN   @"MakeClean"
#define TARGET_MAKE_RPM     @"MakeRPM"

#define BUILD_TAG    0
#define SETTINGS_TAG 1
#define PREFS_TAG    2
#define LAUNCH_TAG   3
#define EDITOR_TAG   4

//=============================================================================
// ==== Not used yet
//=============================================================================

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

static NSString * const PCClasses             = @"CLASS_FILES";
static NSString * const PCHeaders             = @"HEADER_FILES";
static NSString * const PCOtherSources        = @"OTHER_SOURCES";
static NSString * const PCOtherResources      = @"OTHER_RESOURCES";
static NSString * const PCSupportingFiles     = @"SUPPORTING_FILES";
static NSString * const PCDocuFiles           = @"DOCU_FILES";
static NSString * const PCSubprojects         = @"SUBPROJECTS";
static NSString * const PCGModels             = @"INTERFACES";
static NSString * const PCImages              = @"IMAGES";
static NSString * const PCLibraries           = @"LIBRARIES";
static NSString * const PCCompilerOptions     = @"COMPILEROPTIONS";
static NSString * const PCLinkerOptions       = @"LINKEROPTIONS";
static NSString * const PCProjectName         = @"PROJECT_NAME";
static NSString * const PCProjType            = @"PROJECT_TYPE";
static NSString * const PCPrincipalClass      = @"PRINCIPAL_CLASS";
static NSString * const PCAppIcon             = @"APPLICATIONICON";
static NSString * const PCAppClass            = @"APPCLASS";
static NSString * const PCToolIcon            = @"TOOLICON";
static NSString * const PCProjectBuilderClass = @"PROJECT_BUILDER";
static NSString * const PCMainGModelFile      = @"MAININTERFACE";
static NSString * const PCPackageName         = @"PACKAGE_NAME";
static NSString * const PCLibraryVar          = @"LIBRARY_VAR";
static NSString * const PCVersion             = @"PROJECT_VERSION";
static NSString * const PCSummary             = @"PROJECT_SUMMARY";
static NSString * const PCDescription         = @"PROJECT_DESCRIPTION";
static NSString * const PCRelease             = @"PROJECT_RELEASE";
static NSString * const PCCopyright           = @"PROJECT_COPYRIGHT";
static NSString * const PCGroup               = @"PROJECT_GROUP";
static NSString * const PCSource              = @"PROJECT_SOURCE";
static NSString * const PCInstallDir          = @"INSTALLDIR";
static NSString * const PCBuildTool           = @"BUILDTOOL";

@class PCProjectBuilder;
@class PCProjectDebugger;
@class PCProjectEditor;
@class PCEditorController;

@protocol ProjectBuilder;

@interface PCProject : NSObject
{
    id projectWindow;
    id delegate;
    id projectManager;
    id browserController;
    id historyController;

    PCProjectBuilder   *projectBuilder;
    PCProjectDebugger  *projectDebugger;
    PCProjectEditor    *projectEditor;
    PCEditorController *editorController;
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

    BOOL editorIsActive;
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

- (PCEditorController*)editorController;

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

- (Class)builderClass;

- (BOOL)writeMakefile;
    // Subclasses need to call this before their customised implementation!

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

- (void)browserDidClickFile:(NSString *)fileName category:(NSString*)c;
- (void)browserDidDblClickFile:(NSString *)fileName category:(NSString*)c;

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

- (BOOL)saveFile;
- (BOOL)saveAllFiles;
- (BOOL)saveAllFilesIfNeeded;
    // Saves all the files that need to be saved.

- (BOOL)revertFile;

- (BOOL)writeSpecFile;

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
    // Updates all values in the inspector based on the current project dict

- (void)changeCommonProjectEntry:(id)sender;
    // Gets invoked upon UI interaction in the inspector

- (BOOL)isValidDictionary:(NSDictionary *)aDict;
- (void)updateProjectDict;

- (void)validateProjectDict;
    // Validates the project dictionary and inserts missing keys if needed. It
    // calls isValidDictionary to validate.

@end

@interface PCProject (ProjectKeyPaths)

- (NSArray *)contentAtKeyPath:(NSString *)keyPath;
- (BOOL)hasChildrenAtKeyPath:(NSString *)keyPath;
- (NSString *)projectKeyForKeyPath:(NSString *)kp;

@end

@interface PCProject (ProjectWindowDelegate)

- (void)windowDidResignKey:(NSNotification *)aNotification;
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (void)windowDidBecomeMain:(NSNotification *)aNotification;
- (void)windowWillClose:(NSNotification *)aNotification;

@end

#endif
