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

#import <Foundation/Foundation.h>

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

- (PCEditor *)editorForFile:(NSString *)path;
- (NSArray *)allEditors;

- (void)closeAllEditors;

- (void)editorDidClose:(id)sender;

// ===========================================================================
// ==== File handling
// ===========================================================================

- (BOOL)saveFile;
- (BOOL)revertFile;

@end

#endif // _PCEDITORCONTROLLER_H_

