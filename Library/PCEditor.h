/* 
 * PCEditor.h created by probert on 2002-01-29 20:37:28 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
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

