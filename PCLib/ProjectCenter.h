/*
   GNUstep ProjectCenter - http://www.projectcenter.ch

   Copyright (C) 2000 Philippe C.D. Robert

   Author: Philippe C.D. Robert <phr@projectcenter.ch>

   This file is part of ProjectCenter.

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

#define PC_EXTERN	extern
#define PRIVATE_EXTERN	__private_extern__

#define BUNDLE_PATH	@"/LocalDeveloper/ProjectCenter/Bundles"

#define Editor				@"Editor"
#define Debugger			@"Debugger"
#define Compiler			@"Compiler"
#define PromtOnClean			@"PromtOnClean"
#define PromtOnQuit			@"PromtOnQuit"
#define AutoSave			@"UAutoSaveRL"
#define RemoveBackup			@"RemoveBackup"
#define AutoSavePeriod			@"AutoSavePeriod"
#define RootBuildDirectory		@"RootBuildDirectory"
#define DeleteCacheWhenQuitting		@"DeleteBuildCacheWhenQuitting"
#define BundlePaths			@"BundlePaths"
#define SuccessSound			@"SuccessSound"
#define FailureSound			@"FailureSound"
#define ExternalEditor                  @"ExternalEditor"

#define PCAppDidInitNotification	@"PCAppDidInit"
#define PCAppWillTerminateNotification	@"PCAppWillTerminate"

#define NIB_NOT_FOUND_EXCEPTION		@"NibNotFoundException"
#define UNKNOWN_PROJECT_TYPE_EXCEPTION	@"UnknownProjectTypeException"
#define NOT_A_PROJECT_TYPE_EXCEPTION	@"NoProjectTypeCreatorException"
#define PROJECT_CREATION_EXCEPTION	@"ProjectCreationException"
#define PROJECT_OPEN_FAILED_EXCEPTION	@"ProjectOpenFailedException"
#define PROJECT_SAVE_FAILED_EXCEPTION	@"ProjectSaveFailedException"
#define BUNDLE_MANAGER_EXCEPTION	@"BundleManagerException"

#import "PCBundleLoader.h"
#import "PCDataSource.h"
#import "PCProjectManager.h"
#import "PCServer.h"
#import "PCProject.h"
#import "PCProjectBuilder.h"
#import "PCProjectDebugger.h"
#import "PCFileManager.h"
#import "PCBrowserController.h"
#import "ProjectDebugger.h"
#import "ProjectEditor.h"
#import "ProjectType.h"
#import "Server.h"
#import "PreferenceController.h"
#import "ProjectBuilder.h"
#import "FileCreator.h"
#import "PCEditorView.h"




