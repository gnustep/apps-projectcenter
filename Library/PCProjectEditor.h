/* 
 * PCProjectEditor.h created by probert on 2002-02-10 09:27:10 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#ifndef _PCProjectEditor_h_
#define _PCProjectEditor_h_

#include <Foundation/Foundation.h>

@class PCProject;
@class PCEditor;
@class PCEditorView;

@class NSBox;
@class NSView;
@class NSScrollView;

#ifndef GNUSTEP_BASE_VERSION
@protocol ProjectComponent;
#else
#include <ProjectCenter/ProjectComponent.h>
#endif

@interface PCProjectEditor : NSObject <ProjectComponent>
{
  PCProject           *project;
  NSMutableDictionary *editorsDict;
  NSBox               *componentView;
  PCEditorView        *editorView;
  NSScrollView        *scrollView;
}

- (void)setEditorView:(PCEditorView *)ev;
- (PCEditorView *)editorView;

// ===========================================================================
// ==== Class Methods
// ===========================================================================

+ (void)openFileInEditor:(NSString *)path;
 
// ===========================================================================
// ==== Initialisation
// ===========================================================================

- (id)initWithProject:(PCProject *)aProject;
- (void)dealloc;
- (NSView *)emptyEditorView;
- (NSView *)componentView;

// ===========================================================================
// ==== Project and Editor handling
// ===========================================================================

- (PCEditor *)internalEditorForFile:(NSString *)path;
- (PCEditor *)editorForFile:(NSString *)path;
- (PCEditor *)activeEditor;
- (NSArray *)allEditors;
- (void)closeEditorForFile:(NSString *)file;
- (void)closeAllEditors;


// ===========================================================================
// ==== File handling
// ===========================================================================

- (BOOL)saveAllFiles;
- (BOOL)saveFile;
- (BOOL)saveFileAs:(NSString *)file;
- (BOOL)saveFileTo:(NSString *)file;
- (void)closeFile:(id)sender;
- (BOOL)revertFileToSaved;

// ===========================================================================
// ==== Delegate
// ===========================================================================

- (void)editorDidClose:(id)sender;
- (void)setBrowserPath:(NSString *)file category:(NSString *)category;

@end

#endif 

