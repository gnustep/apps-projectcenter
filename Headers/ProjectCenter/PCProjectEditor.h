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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#ifndef _PCProjectEditor_h_
#define _PCProjectEditor_h_

#include <Foundation/Foundation.h>

#include <Protocols/CodeEditor.h>
#include <Protocols/CodeParser.h>

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

  NSDictionary        *editorBundlesInfo;
  NSDictionary        *parserBundlesInfo;
  NSMutableDictionary *editorsDict;
  id<CodeEditor>      activeEditor;
  
  id<CodeParser>      aParser;
  NSConnection        *parserConnection;
}

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

- (BOOL)editorProvidesBrowserItemsForItem:(NSString *)item;

// Returns nil if editor is not opened
- (id<CodeEditor>)editorForFile:(NSString *)fileName key:(NSString *)key;

- (id<CodeEditor>)openEditorForCategoryPath:(NSString *)categoryPath
                                   windowed:(BOOL)windowed;

- (id<CodeEditor>)openEditorForFile:(NSString *)path
                       categoryPath:(NSString *)categoryPath
		           editable:(BOOL)editable
	                   windowed:(BOOL)windowed;
		       
- (void)orderFrontEditorForFile:(NSString *)path;
- (id<CodeEditor>)activeEditor;
- (void)setActiveEditor:(id<CodeEditor>)anEditor;
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

- (void)editorDidClose:(NSNotification *)aNotif;
- (void)editorDidBecomeActive:(NSNotification *)aNotif;
- (void)editorDidResignActive:(NSNotification *)aNotif;

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

