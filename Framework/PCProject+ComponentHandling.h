/* 
 * Project ProjectCenter
 */

#ifndef _PCProject_ComponentHandling_h_
#define _PCProject_ComponentHandling_h_

#include <Foundation/Foundation.h>

// HACK!
#include "PCProject.h"

@interface PCProject (ComponentHandling)

//- (void)showBuildView:(id)sender;
//- (void)showRunView:(id)sender;
- (void)showEditorView:(id)sender;
- (void)showInspector:(id)sender;

- (void)runSelectedTarget:(id)sender;

- (NSDictionary *)buildOptions;

- (BOOL)isEditorActive;

@end

#endif

