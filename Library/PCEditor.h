/* 
 * PCEditor.h created by probert on 2002-01-29 20:37:28 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#ifndef _PCEDITOR_H_
#define _PCEDITOR_H_

#include <AppKit/AppKit.h>

@class PCEditorView;
@class PCProjectEditor;

@interface PCEditor : NSObject
{
  NSScrollView    *_extScrollView;
  PCEditorView    *_extEditorView;
  NSScrollView    *_intScrollView;
  PCEditorView    *_intEditorView;
  NSTextStorage   *_storage;
  NSMutableString *_path;
  NSString        *_category;
  NSWindow        *_window;

  BOOL            _isEdited;
  BOOL            _isWindowed;
}

- (id)initWithPath:(NSString *)file
          category:(NSString *)category;
- (void)dealloc;
- (void)show;

- (void)setWindowed:(BOOL)yn;
- (BOOL)isWindowed;

- (NSWindow *)editorWindow;
- (PCEditorView *)editorView;
- (NSView *)componentView;
- (NSString *)category;
- (NSString *)path;
- (void)setPath:(NSString *)path;
- (BOOL)isEdited;
- (void)setIsEdited:(BOOL)yn;

- (BOOL)saveFileIfNeeded;
- (BOOL)saveFile;
- (BOOL)saveFileTo:(NSString *)path;
- (BOOL)revertFileToSaved;
- (BOOL)closeFile:(id)sender;

// Delegates
- (BOOL)editorShouldClose;

- (BOOL)windowShouldClose:(id)sender;
/*- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (void)windowDidResignKey:(NSNotification *)aNotification;*/

- (void)textDidChange:(NSNotification *)aNotification;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

@end

@interface PCEditor (UInterface)

- (void)_createWindow;
- (void)_createInternalView;
- (PCEditorView *)_createEditorViewWithFrame:(NSRect)fr;

@end

@interface NSObject (PCEditorDelegate)

- (void)editorDidClose:(id)sender;
- (void)setBrowserPath:(NSString *)file category:(NSString *)category;

@end

#endif // _PCEDITOR_H_

