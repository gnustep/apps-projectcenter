/* 
 * PCProject+ComponentHandling.m created by probert on 2002-02-10 09:50:56 +0000
 *
 * Project ProjectCenter
 *
 * Created with ProjectCenter - http://www.gnustep.org
 *
 * $Id$
 */

#import "PCProject+ComponentHandling.h"
#import "PCDefines.h"
#import "PCProject.h"
#import "ProjectComponent.h"
#import "PCProjectBuilder.h"
#import "PCProjectDebugger.h"
#import "PCProjectEditor.h"
#import "PCProjectManager.h"
#import "PCEditor.h"

@implementation PCProject (ComponentHandling)

- (void)topButtonsPressed:(id)sender
{
  switch ([[sender selectedCell] tag]) 
  {
  case BUILD_TAG:
    [self showBuildView:self];
    break;
  case SETTINGS_TAG:
    [self showInspector:self];
    break;
  case PREFS_TAG:
    [self showBuildTargetPanel:self];
    break;
  case LAUNCH_TAG:
    if ([self isExecutable]) {
	[self showRunView:self];
    }
    else {
      NSRunAlertPanel(@"Attention!",
                      @"This project is not executable!",
                      @"OK",nil,nil);
    }
    break;
  case EDITOR_TAG:
    [self showEditorView:self];
    break;
  default:
    break;
  }
}

- (void)showBuildView:(id)sender
{
  NSView *view = nil;

  [[NSNotificationCenter defaultCenter] postNotificationName:PCEditorDidResignKeyNotification object:self];

  editorIsActive = NO;

  if (!projectBuilder) {
    projectBuilder = [[PCProjectBuilder alloc] initWithProject:self];
  }

  view = [[projectBuilder componentView] retain];

  [box setContentView:view];
  [box sizeToFit];
  [box display];
}

- (void)showRunView:(id)sender
{
  NSView *view = nil;

  [[NSNotificationCenter defaultCenter] postNotificationName:PCEditorDidResignKeyNotification object:self];

  editorIsActive = NO;

  if (!projectDebugger) {
    projectDebugger = [[PCProjectDebugger alloc] initWithProject:self];
  }

  view = [[projectDebugger componentView] retain];

  [box setContentView:view];
  [box display];
}

- (void)showEditorView:(id)sender
{
  NSView *view = nil;

  [[NSNotificationCenter defaultCenter] postNotificationName:PCEditorDidBecomeKeyNotification object:self];

  editorIsActive = YES;

  if (!projectEditor) {
    projectEditor = [[PCProjectEditor alloc] initWithProject:self];
  }

  view = [[projectEditor componentView] retain];

  [box setContentView:view];
  [box display];
}

- (void)showInspector:(id)sender
{
    [projectManager showInspectorForProject:self];
}

- (void)runSelectedTarget:(id)sender
{
  if (!projectDebugger) {
    projectDebugger = [[PCProjectDebugger alloc] initWithProject:self];
  }

  [projectDebugger run:sender];
}

- (id)updatedAttributeView
{
    return projectAttributeInspectorView;
}

- (id)updatedProjectView
{
    return projectProjectInspectorView;
}

- (id)updatedFilesView
{
    return projectFileInspectorView;
}

- (void)showBuildTargetPanel:(id)sender
{
    if (![buildTargetPanel isVisible])
    {
        [buildTargetPanel center];
    }

    [buildTargetPanel makeKeyAndOrderFront:self];
}

- (void)setHost:(id)sender
{
    NSString *host = [buildTargetHostField stringValue];
    [buildOptions setObject:host forKey:BUILD_HOST_KEY];
}

- (void)setArguments:(id)sender
{
    NSString *args = [buildTargetArgsField stringValue];
    [buildOptions setObject:args forKey:BUILD_ARGS_KEY];
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

