/* 
 * PCDefines.h created by probert on 2002-02-02 20:47:54 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#ifndef _PCDEFINES_H_
#define _PCDEFINES_H_

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
#define TabBehaviour                    @"TabBehaviour"
#define SeparateBuilder			@"SeparateBuilder"
#define SeparateLauncher		@"SeparateLauncher"
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

#endif

#endif // _PCDEFINES_H_

