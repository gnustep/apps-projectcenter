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

#ifndef _PCEditor_h_
#define _PCEditor_h_

#include <AppKit/AppKit.h>

@class PCProjectEditor;
@class PCEditorView;

@interface PCEditor : NSObject
{
  PCProjectEditor *projectEditor;

  NSScrollView    *_extScrollView;
  PCEditorView    *_extEditorView;
  NSScrollView    *_intScrollView;
  PCEditorView    *_intEditorView;
  NSTextStorage   *_storage;
  NSMutableString *_path;
  NSString        *_categoryPath;
  NSWindow        *_window;

  BOOL            _isEdited;
  BOOL            _isWindowed;
  BOOL            _isExternal;
}

// ===========================================================================
// ==== Initialization
// ===========================================================================
- (id)initWithPath:(NSString *)file
      categoryPath:(NSString *)categoryPath
     projectEditor:(PCProjectEditor *)projectEditor;
- (id)initExternalEditor:(NSString *)editor
                withPath:(NSString *)file
           projectEditor:(PCProjectEditor *)aProjectEditor;
- (void)dealloc;
- (void)show;

- (void)setWindowed:(BOOL)yn;
- (BOOL)isWindowed;

// ===========================================================================
// ==== Accessor methods
// ===========================================================================
- (PCProjectEditor *)projectEditor;
- (NSWindow *)editorWindow;
- (PCEditorView *)editorView;
- (NSView *)componentView;
- (NSString *)path;
- (void)setPath:(NSString *)path;
- (NSString *)categoryPath;
- (void)setCategoryPath:(NSString *)path;
- (BOOL)isEdited;
- (void)setIsEdited:(BOOL)yn;

// ===========================================================================
// ==== Object managment
// ===========================================================================
- (BOOL)saveFileIfNeeded;
- (BOOL)saveFile;
- (BOOL)saveFileTo:(NSString *)path;
- (BOOL)revertFileToSaved;
- (BOOL)closeFile:(id)sender save:(BOOL)save;

- (BOOL)editorShouldClose;

// ===========================================================================
// ==== Window delegate
// ===========================================================================
- (BOOL)windowShouldClose:(id)sender;
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (void)windowDidResignKey:(NSNotification *)aNotification;

// ===========================================================================
// ==== TextView (_intEditorView, _extEditorView) delegate
// ===========================================================================
- (void)textDidChange:(NSNotification *)aNotification;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

// ===========================================================================
// ==== Parser and scrolling
// ===========================================================================

- (NSArray *)listOfClasses;
- (NSArray *)listOfMethodsOfClass:(NSString *)className;
- (NSArray *)listOfDefines;
- (NSArray *)listOfVars;
- (void)scrollToClassName:(NSString *)className;
- (void)scrollToMethodName:(NSString *)className;
- (void)scrollToLineNumber:(int)line;

@end

@interface PCEditor (UInterface)

- (void)_createWindow;
- (void)_createInternalView;
- (PCEditorView *)_createEditorViewWithFrame:(NSRect)fr;

@end

/*@interface NSObject (PCEditorDelegate)

- (void)editorDidClose:(id)sender;
- (void)setBrowserPath:(NSString *)file category:(NSString *)category;

@end*/

#endif // _PCEDITOR_H_

