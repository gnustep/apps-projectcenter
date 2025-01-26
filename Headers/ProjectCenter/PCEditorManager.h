/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2002-2004 Free Software Foundation

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
   Software Foundation, Inc., 31 Milk Street #960789 Boston, MA 02196 USA.
*/

#ifndef _PCEditorManager_h_
#define _PCEditorManager_h_

#import <Foundation/Foundation.h>

#import <Protocols/CodeEditor.h>
#import <Protocols/CodeParser.h>

@class PCProjectManager;

@interface PCEditorManager : NSObject
{
  PCProjectManager    *_projectManager;
  NSMutableDictionary *_editorsDict;
  id<CodeEditor>      _activeEditor;

  NSString            *editorName;
}

// ===========================================================================
// ==== Initialisation
// ===========================================================================

- (id)init;
- (void)dealloc;
- (PCProjectManager *)projectManager;
- (void)setProjectManager:(PCProjectManager *)aProjectManager;
- (void)loadPreferences:(NSNotification *)aNotification;

// ===========================================================================
// ==== Project and Editor handling
// ===========================================================================

// Returns nil if editor is not opened
- (id<CodeEditor>)editorForFile:(NSString *)filePath;

- (id<CodeEditor>)openEditorForFile:(NSString *)path
		           editable:(BOOL)editable
	                   windowed:(BOOL)windowed;
		       
- (void)orderFrontEditorForFile:(NSString *)path;
- (id<CodeEditor>)activeEditor;
- (void)setActiveEditor:(id<CodeEditor>)anEditor;
- (NSArray *)allEditors;
- (void)closeActiveEditor:(id)sender;
- (void)closeEditorForFile:(NSString *)file;
- (void)gotoFile: (NSString *)fileName atLine: (NSUInteger)line;

- (NSArray *)modifiedFiles;
- (BOOL)hasModifiedFiles;
- (BOOL)reviewUnsaved:(NSArray *)modifiedFiles;
- (BOOL)closeAllEditors;

// ===========================================================================
// ==== File handling
// ===========================================================================

- (BOOL)saveAllFiles;
- (BOOL)saveFile;
- (BOOL)saveFileAs:(NSString *)file;
- (BOOL)saveFileTo:(NSString *)file;
- (BOOL)revertFileToSaved;

// ===========================================================================
// ==== Delegate
// ===========================================================================

- (void)editorDidOpen:(NSNotification *)aNotif;
- (void)editorDidClose:(NSNotification *)aNotif;
- (void)editorDidBecomeActive:(NSNotification *)aNotif;
- (void)editorDidResignActive:(NSNotification *)aNotif;
- (void)editorDidChangeFileName:(NSNotification *)aNotif;

@end

extern NSString *PCEditorDidChangeFileNameNotification;

extern NSString *PCEditorWillOpenNotification;
extern NSString *PCEditorDidOpenNotification;
extern NSString *PCEditorWillCloseNotification;
extern NSString *PCEditorDidCloseNotification;

extern NSString *PCEditorWillChangeNotification;
extern NSString *PCEditorDidChangeNotification;
extern NSString *PCEditorWillSaveNotification;
extern NSString *PCEditorDidSaveNotification;
extern NSString *PCEditorWillRevertNotification;
extern NSString *PCEditorDidRevertNotification;

extern NSString *PCEditorDidBecomeActiveNotification;
extern NSString *PCEditorDidResignActiveNotification;

/*
extern NSString *PCEditorSaveDidFailNotification;
*/

#endif 

