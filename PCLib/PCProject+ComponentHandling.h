/* 
 * PCProject+ComponentHandling.h created by probert on 2002-02-10 09:51:00 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#ifndef _PCPROJECT_COMPONENTHANDLING_H_
#define _PCPROJECT_COMPONENTHANDLING_H_

#import <Foundation/Foundation.h>

// HACK!
#import "PCProject.h"

@interface PCProject (ComponentHandling)

- (void)topButtonsPressed:(id)sender;
- (void)showBuildView:(id)sender;
- (void)showRunView:(id)sender;
- (void)showEditorView:(id)sender;

- (void)runSelectedTarget:(id)sender;

- (void)showInspector:(id)sender;

- (id)updatedAttributeView;
- (id)updatedProjectView;
- (id)updatedFilesView;

- (void)showBuildTargetPanel:(id)sender;
- (void)setHost:(id)sender;
- (void)setArguments:(id)sender;

- (NSDictionary *)buildOptions;

- (BOOL)isEditorActive;

@end

#endif // _PCPROJECT_COMPONENTHANDLING_H_

