/*
   GNUstep ProjectCenter - http://www.gnustep.org

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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#ifndef _PCProjectEditor_h_
#define _PCProjectEditor_h_

#include <Foundation/Foundation.h>

#include "PCProject.h"

@class PCProject;
@class PCEditor;
@class PCEditorView;

@class NSBox;
@class NSView;
@class NSScrollView;

@interface PCProjectEditor : NSObject
{
  PCProject           *project;
  NSBox               *componentView;
  NSScrollView        *scrollView;

  NSMutableDictionary *editorsDict;
  PCEditor            *activeEditor;
}

// ===========================================================================
// ==== Class Methods
// ===========================================================================

+ (PCEditor *)openFileInEditor:(NSString *)path;
 
// ===========================================================================
// ==== Initialisation
// ===========================================================================

- (id)initWithProject:(PCProject *)aProject;
- (void)dealloc;
- (NSView *)componentView;
- (PCProject *)project;

// ===========================================================================
// ==== Project and Editor handling
// ===========================================================================

- (PCEditor *)editorForFile:(NSString *)path
               categoryPath:(NSString *)categoryPath
	           windowed:(BOOL)yn;
- (void)orderFrontEditorForFile:(NSString *)path;
- (PCEditor *)activeEditor;
- (void)setActiveEditor:(PCEditor *)anEditor;
- (NSArray *)allEditors;
- (void)closeActiveEditor:(id)sender;
- (void)closeEditorForFile:(NSString *)file;
- (BOOL)closeAllEditors;

// ===========================================================================
// ==== File handling
// ===========================================================================

- (BOOL)saveEditedFiles:(NSArray *)files;
- (BOOL)saveAllFiles;
- (BOOL)saveFile;
- (BOOL)saveFileAs:(NSString *)file;
- (BOOL)saveFileTo:(NSString *)file;
- (BOOL)revertFileToSaved;

// ===========================================================================
// ==== Delegate
// ===========================================================================

- (void)editorDidClose:(id)sender;
- (void)editorDidBecomeActive:(NSNotification *)aNotif;
- (void)editorDidResignActive:(NSNotification *)aNotif;

@end

extern NSString *PCEditorDidChangeFileNameNotification;

extern NSString *PCEditorDidOpenNotification;
extern NSString *PCEditorDidCloseNotification;

extern NSString *PCEditorDidBecomeActiveNotification;
extern NSString *PCEditorDidResignActiveNotification;

/*extern NSString *PCEditorDidChangeNotification;
extern NSString *PCEditorWillSaveNotification;
extern NSString *PCEditorDidSaveNotification;
extern NSString *PCEditorSaveDidFailNotification;
extern NSString *PCEditorWillRevertNotification;
extern NSString *PCEditorDidRevertNotification;
extern NSString *PCEditorDeletedNotification;
extern NSString *PCEditorRenamedNotification;*/

#endif 

