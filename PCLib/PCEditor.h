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
  PCEditorView    *_iView; // internal (embedded) view
  PCEditorView    *_eView; // external (window) view
  NSTextStorage   *_storage;
  NSWindow        *_window;
  NSMutableString *_path;

  id   _delegate;

  BOOL _isEdited;
}

- (id)initWithPath:(NSString*)file;
- (void)dealloc;

- (void)setDelegate:(id)aDelegate;
- (id)delegate;

- (PCEditorView *)internalView;
- (PCEditorView *)externalView;
- (NSWindow *)editorWindow;
- (NSString *)path;
- (void)setPath:(NSString *)path;
- (BOOL)isEdited;
- (void)setIsEdited:(BOOL)yn;

- (void)showInProjectEditor:(PCProjectEditor *)pe;
- (void)show;
- (BOOL)saveFileIfNeeded;
- (BOOL)saveFile;
- (BOOL)saveFileAs:(NSString *)path;
- (BOOL)saveFileTo:(NSString *)path;
- (BOOL)revertFileToSaved;
- (BOOL)closeFile:(id)sender;

// Delegates
- (BOOL)editorShouldClose;

- (BOOL)windowShouldClose:(id)sender;
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (void)windowDidResignKey:(NSNotification *)aNotification;

- (void)textDidChange:(NSNotification *)aNotification;

@end

@interface NSObject (PCEditorDelegate)

- (void)editorDidClose:(id)sender;

@end

extern NSString *PCEditorDidBecomeKeyNotification;
extern NSString *PCEditorDidResignKeyNotification;

#endif // _PCEDITOR_H_

