/* 
 * Project ProjectCenter
 */

#ifndef _PCProject_ComponentHandling_h_
#define _PCProject_ComponentHandling_h_

#include <Foundation/Foundation.h>

// HACK!
#include "PCProject.h"

@interface PCProject (ComponentHandling)

- (void)showEditorView:(id)sender;

- (void)runSelectedTarget:(id)sender;

- (NSDictionary *)buildOptions;

- (BOOL)isEditorActive;

@end

#endif

