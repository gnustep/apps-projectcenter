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

#import <AppKit/AppKit.h>

#import "Server.h"
#import "PCProject.h"

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

@interface PCServer : NSObject <Server>
{
    NSMutableArray *clients;
    NSMutableDictionary *openDocuments;
}

//----------------------------------------------------------------------------
// Init and free
//----------------------------------------------------------------------------

- (id)init;
- (void)dealloc;

//----------------------------------------------------------------------------
// Miscellaneous
//----------------------------------------------------------------------------

- (void)fileShouldBeOpened:(NSNotification *)aNotif;

- (void)openFileInExternalEditor:(NSString *)file;
- (void)openFileInInternalEditor:(NSString *)file;

- (NSWindow *)editorForFile:(NSString *)aFile;
- (void)windowDidClose:(NSNotification *)aNotif;

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
