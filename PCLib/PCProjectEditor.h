/* 
 * PCProjectEditor.h created by probert on 2002-02-10 09:27:10 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#ifndef _PCPROJECTEDITOR_H_
#define _PCPROJECTEDITOR_H_

#import <Foundation/Foundation.h>
#import <ProjectCenter/ProjectComponent.h>

@class NSBox;
@class NSScrollView;
@class PCEditorView;

@interface PCProjectEditor : NSObject <ProjectComponent>
{
    NSBox        *_componentView;
    PCProject    *_currentProject;
    PCEditorView *_editorView;
    NSScrollView *_scrollView;
}

- (id)initWithProject:(PCProject *)aProject;
- (void)dealloc;

- (NSView *)componentView;

- (void)setEditorView:(PCEditorView *)ev;
- (PCEditorView *)editorView;

@end

#endif // _PCPROJECTEDITOR_H_

