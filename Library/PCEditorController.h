/* 
 * PCEditorController.h created by probert on 2002-02-02 15:28:33 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#ifndef _PCEDITORCONTROLLER_H_
#define _PCEDITORCONTROLLER_H_

#include <Foundation/Foundation.h>

@class PCProject;
@class PCEditor;

@interface PCEditorController : NSObject
{
    PCProject           *project;
    NSMutableDictionary *editorDict;
}

// ===========================================================================
// ==== Class Methods
// ===========================================================================

+ (void)openFileInEditor:(NSString *)path;
 
// ===========================================================================
// ==== Initialisation
// ===========================================================================

- (id)init;
- (void)dealloc;

// ===========================================================================
// ==== Project and Editor handling
// ===========================================================================

- (void)setProject:(PCProject *)aProject;

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

#endif // _PCEDITORCONTROLLER_H_

