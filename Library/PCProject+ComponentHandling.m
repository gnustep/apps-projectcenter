/* 
 * PCProject+ComponentHandling.m created by probert on 2002-02-10 09:50:56 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#include "PCProject+ComponentHandling.h"
#include "PCDefines.h"
#include "PCProject.h"
#include "PCProjectWindow.h"
#include "ProjectComponent.h"
#include "PCProjectInspector.h"
#include "PCProjectBuilder.h"
#include "PCProjectLauncher.h"
#include "PCProjectEditor.h"
#include "PCProjectManager.h"
#include "PCEditor.h"

@implementation PCProject (ComponentHandling)

- (void)showEditorView:(id)sender
{
  NSView *view = nil;

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PCEditorDidBecomeKeyNotification
                  object:self];

  editorIsActive = YES;

  if (!projectEditor)
    {
      projectEditor = [[PCProjectEditor alloc] initWithProject:self];
    }

  view = [[projectEditor componentView] retain];

  [projectWindow setCustomContentView:view];
}

//
- (void)runSelectedTarget:(id)sender
{
  if (!projectLauncher)
    {
      projectLauncher = [[PCProjectLauncher alloc] initWithProject:self];
    }

  [projectLauncher run:sender];
}

- (NSDictionary *)buildOptions
{
  return (NSDictionary *)buildOptions;
}

- (BOOL)isEditorActive
{
  return editorIsActive;
}

@end

