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

#ifndef _PCSERVER_H
#define _PCSERVER_H

#include <AppKit/AppKit.h>

#ifndef GNUSTEP_BASE_VERSION
@protocol Server;
#else
#include <ProjectCenter/Server.h>
#endif

extern NSString *PCProjectWillOpenNotification;
extern NSString *PCProjectDidOpenNotification;
extern NSString *PCProjectWillCloseNotification;
extern NSString *PCProjectDidCloseNotification;
extern NSString *PCProjectDidChangeNotification;
extern NSString *PCProjectWillSaveNotification;
extern NSString *PCProjectDidSaveNotification;
extern NSString *PCProjectSaveDidFailNotification;
extern NSString *PCProjectDidUpdateNotification;

extern NSString *PCFileAddedToProjectNotification;
extern NSString *PCFileRemovedFromProjectNotification;
extern NSString *PCFileWillOpenNotification;
extern NSString *PCFileDidOpenNotification;
extern NSString *PCFileWillCloseNotification;
extern NSString *PCFileDidCloseNotification;

extern NSString *PCFileDidChangeNotification;
extern NSString *PCFileWillSaveNotification;
extern NSString *PCFileDidSaveNotification;
extern NSString *PCFileSaveDidFailNotification;
extern NSString *PCFileWillRevertNotification;
extern NSString *PCFileDidRevertNotification;
extern NSString *PCFileDeletedNotification;
extern NSString *PCFileRenamedNotification;

extern NSString *PCProjectBuildWillBeginNotification;
extern NSString *PCProjectBuildDidBeginNotification;
extern NSString *PCProjectBuildDidSucceedNotification;
extern NSString *PCProjectBuildDidFailNotification;
extern NSString *PCProjectBuildDidStopNotification;

@class PCProject;

#ifndef GNUSTEP_BASE_VERSION
@protocol ProjectEditor;
@protocol ProjectDebugger;
@protocol PreferenceController;
#else
#include <ProjectCenter/PreferenceController.h>
#include <ProjectCenter/ProjectEditor.h>
#include <ProjectCenter/ProjectDebugger.h>
#endif

@interface PCServer : NSObject <Server>
{
    NSMutableArray *clients;
}

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init;
- (void)dealloc;

//----------------------------------------------------------------------------
// Server
//----------------------------------------------------------------------------

- (BOOL)registerProjectSubmenu:(NSMenu *)menu;
- (BOOL)registerFileSubmenu:(NSMenu *)menu;
- (BOOL)registerToolsSubmenu:(NSMenu *)menu;
- (BOOL)registerPrefController:(id<PreferenceController>)prefs;
- (BOOL)registerEditor:(id<ProjectEditor>)anEditor;
- (BOOL)registerDebugger:(id<ProjectDebugger>)aDebugger;

- (PCProject *)activeProject;
- (NSString*)pathToActiveProject;

- (id)activeFile;
- (NSString*)pathToActiveFile;

- (NSArray*)selectedFiles;
- (NSArray*)touchedFiles;
// Both methods return full paths!

- (BOOL)queryTouchedFiles;
     // Prompts user to save all files and projects with dirtied buffers.

- (BOOL)addFileAt:(NSString*)filePath toProject:(PCProject *)projectPath;
- (BOOL)removeFileFromProject:(NSString *)filePath;

- (void)connectionDidDie:(NSNotification *)notif;

@end

#endif
