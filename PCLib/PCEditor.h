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
}

- (id)initWithPath:(NSString*)file;
- (void)dealloc;

- (void)setDelegate:(id)aDelegate;
- (id)delegate;

- (NSWindow *)editorWindow;

- (void)show;
- (void)close;

- (void)windowWillClose:(NSNotification *)aNotif;

@end

#endif // _PCEDITOR_H_

