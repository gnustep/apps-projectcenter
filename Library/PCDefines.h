/* 
 * PCDefines.h created by probert on 2002-02-02 20:47:54 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#ifndef _PCDefines_h_
#define _PCDefines_h_

#define PC_EXTERN       extern
#define PRIVATE_EXTERN  __private_extern__

#define Editor                          @"Editor"
#define PDebugger                       @"Debugger"
#define Compiler                        @"Compiler"
#define PromptOnClean                   @"PromtOnClean"
#define PromptOnQuit                    @"PromtOnQuit"
#define SaveOnQuit                      @"SaveOnQuit"
#define AutoSave                        @"AutoSave"
#define KeepBackup                      @"KeepBackup"
#define AutoSavePeriod                  @"AutoSavePeriod"
#define RootBuildDirectory              @"RootBuildDirectory"
#define DeleteCacheWhenQuitting         @"DeleteBuildCacheWhenQuitting"
#define BundlePaths                     @"BundlePaths"
#define SuccessSound                    @"SuccessSound"
#define FailureSound                    @"FailureSound"
#define ExternalEditor                  @"ExternalEditor"
#define ExternalDebugger                @"ExternalDebugger"
#define TabBehaviour                    @"TabBehaviour"
#define SeparateBuilder			@"SeparateBuilder"
#define SeparateLauncher		@"SeparateLauncher"
#define SeparateHistory                 @"SeparateHistory"
#define SeparateEditor			@"SeparateEditor"

#define PCAppDidInitNotification        @"PCAppDidInit"
#define PCAppWillTerminateNotification  @"PCAppWillTerminate"

#define NIB_NOT_FOUND_EXCEPTION         @"NibNotFoundException"
#define UNKNOWN_PROJECT_TYPE_EXCEPTION  @"UnknownProjectTypeException"
#define NOT_A_PROJECT_TYPE_EXCEPTION    @"NoProjectTypeCreatorException"
#define PROJECT_CREATION_EXCEPTION      @"ProjectCreationException"
#define PROJECT_OPEN_FAILED_EXCEPTION   @"ProjectOpenFailedException"
#define PROJECT_SAVE_FAILED_EXCEPTION   @"ProjectSaveFailedException"
#define BUNDLE_MANAGER_EXCEPTION        @"BundleManagerException"

//=============================================================================
// ==== MacOS X portability defines
//=============================================================================
#ifndef GNUSTEP_BASE_VERSION

#define RETAIN(object)          [object retain]
#define RELEASE(object)         [object release]
#define AUTORELEASE(object)     [object autorelease]
#define TEST_RELEASE(object)    ({ if (object) [object release]; })
#define ASSIGN(object,value)    ({\
id __value = (id)(value); \
id __object = (id)(object); \
if (__value != __object) \
  { \
    if (__value != nil) \
      { \
        [__value retain]; \
      } \
    object = __value; \
    if (__object != nil) \
      { \
        [__object release]; \
      } \
  } \
})
#define DESTROY(object) ({ \
  if (object) \
    { \
      id __o = object; \
      object = nil; \
      [__o release]; \
    } \
})

#define NSLocalizedString(key, comment) \
  [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]

#define _(X) NSLocalizedString (X, @"")

#endif // GNUSTEP_BASE_VERSION

//
// ==== From PCProject.h
//
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

#define BUILD_TAG     0
#define LAUNCH_TAG    1
#define EDITOR_TAG    2
#define FILES_TAG     3
#define FIND_TAG      4
#define INSPECTOR_TAG 5

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

#include <Foundation/Foundation.h>

static NSString * const PCClasses              = @"CLASS_FILES";
static NSString * const PCHeaders              = @"HEADER_FILES";
static NSString * const PCOtherSources         = @"OTHER_SOURCES";
static NSString * const PCInterfaces           = @"INTERFACES";
static NSString * const PCImages               = @"IMAGES";
static NSString * const PCOtherResources       = @"OTHER_RESOURCES";
static NSString * const PCSubprojects          = @"SUBPROJECTS";
static NSString * const PCDocuFiles            = @"DOCU_FILES";
static NSString * const PCSupportingFiles      = @"SUPPORTING_FILES";
static NSString * const PCLibraries            = @"LIBRARIES";
static NSString * const PCNonProject           = @"NON_PROJECT_FILES";
static NSString * const PCGSMarkupFiles	       = @"INTERFACES";

static NSString * const PCAppIcon              = @"APPLICATIONICON";
static NSString * const PCBuildTool            = @"BUILDTOOL";
static NSString * const PCCompilerOptions      = @"COMPILEROPTIONS";
static NSString * const PCPreprocessorOptions  = @"CPPOPTIONS";
static NSString * const PCCreationDate         = @"CREATION_DATE";
static NSString * const PCInstallDir           = @"INSTALLDIR";
static NSString * const PCLinkerOptions        = @"LINKEROPTIONS";
static NSString * const PCLastEditing          = @"LAST_EDITING";
static NSString * const PCMainInterfaceFile    = @"MAININTERFACE";
static NSString * const PCObjCCompilerOptions  = @"OBJC_COMPILEROPTIONS";
static NSString * const PCPrincipalClass       = @"PRINCIPAL_CLASS";
static NSString * const PCAuthors              = @"PROJECT_AUTHORS";
static NSString * const PCCopyright            = @"PROJECT_COPYRIGHT";
static NSString * const PCCopyrightDescription = @"PROJECT_COPYRIGHT_DESC";
static NSString * const PCProjectCreator       = @"PROJECT_CREATOR";
static NSString * const PCDescription          = @"PROJECT_DESCRIPTION";
static NSString * const PCDocumentExtensions   = @"PROJECT_DOCUMENTEXTENSIONS";
static NSString * const PCGroup                = @"PROJECT_GROUP";
static NSString * const PCProjectMaintainer    = @"PROJECT_MAINTAINER";
static NSString * const PCProjectName          = @"PROJECT_NAME";
static NSString * const PCRelease              = @"PROJECT_RELEASE";
static NSString * const PCSource               = @"PROJECT_SOURCE";
static NSString * const PCSummary              = @"PROJECT_SUMMARY";
static NSString * const PCProjectType          = @"PROJECT_TYPE";
static NSString * const PCVersion              = @"PROJECT_VERSION";
static NSString * const PCURL                  = @"PROJECT_URL";
static NSString * const PCSearchHeaders        = @"SEARCH_HEADER_DIRS";
static NSString * const PCSearchLibs           = @"SEARCH_LIB_DIRS";

static NSString * const PCToolIcon             = @"TOOLICON";
static NSString * const PCProjectBuilderClass  = @"PROJECT_BUILDER"; // Will be removed
static NSString * const PCPackageName          = @"PACKAGE_NAME";
static NSString * const PCLibraryVar           = @"LIBRARY_VAR";

#endif // _PCDEFINES_H_
