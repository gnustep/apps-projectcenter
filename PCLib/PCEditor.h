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

#import <AppKit/AppKit.h>

@class PCEditorView;

@interface PCEditor : NSObject
{
    PCEditorView *view;
    NSWindow     *window;
    NSMutableString *path;

    id delegate;

    BOOL isEmbedded;
}

- (id)initWithPath:(NSString*)file;
- (void)dealloc;

- (void)setDelegate:(id)aDelegate;
- (id)delegate;

- (void)setEmbedded:(BOOL)yn;
- (BOOL)isEmbedded;

- (NSWindow *)editorWindow;
- (NSString *)path;

- (void)show;
- (void)close;

- (BOOL)saveFile;
- (BOOL)revertFile;

- (void)windowWillClose:(NSNotification *)aNotif;

@end

@interface NSObject (PCEditorDelegate )

- (void)editorDidClose:(id)sender;

@end

#endif // _PCEDITOR_H_

