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

#include "PCProject.h"

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

extern NSString *PCEditorWillOpenNotification;
extern NSString *PCEditorDidOpenNotification;
extern NSString *PCEditorWillCloseNotification;
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

