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
#include "ProjectComponent.h"
#include "PCProjectBuilder.h"
#include "PCProjectDebugger.h"
#include "PCProjectEditor.h"
#include "PCProjectManager.h"
#include "PCEditor.h"

@implementation PCProject (ComponentHandling)

- (void)showBuildView:(id)sender
{
  NSView *view = nil;
  BOOL   separate = NO;
  
  if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
              objectForKey: SeparateBuilder] isEqualToString: @"YES"])
    {
      separate = YES;
    }

  [[NSNotificationCenter defaultCenter] 
    postNotificationName: PCEditorDidResignKeyNotification
                  object: self];

  editorIsActive = NO;

  if (!projectBuilder)
    {
      projectBuilder = [[PCProjectBuilder alloc] initWithProject: self];
    }

  view = [[projectBuilder componentView] retain];

  if (separate)
    {
      NSPanel *panel;
      NSRect  panelFrame;

      panel = [projectBuilder createBuildPanel];
      panelFrame = [NSPanel contentRectForFrameRect: [panel frame]
                                          styleMask: [panel styleMask]];
      panelFrame.origin.x = 8;
      panelFrame.origin.y = -2;
      panelFrame.size.height += 2;
      panelFrame.size.width -= 16;
      [view setFrame: panelFrame];
     
      if ([box contentView] == view)
	{
	  [self showEditorView: self];
	}
      [[panel contentView] addSubview: view];
      [panel orderFront: nil];
    }
  else
    {
      NSPanel *panel = [projectBuilder buildPanel];

      if (panel)
	{
	  [panel close];
	}
      [box setContentView: view];
      [box display];
    }
  [projectBuilder setTooltips];
}

- (void)showRunView:(id)sender
{
  NSView *view = nil;
  BOOL   separate = NO;
  
  if ([self isExecutable] == NO)
  {
    NSRunAlertPanel(@"Attention!",
                    @"This project is not executable!",
                    @"OK",nil,nil);
    return;
  }

  if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
              objectForKey: SeparateLauncher] isEqualToString: @"YES"])
    {
      separate = YES;
    }

  [[NSNotificationCenter defaultCenter]
    postNotificationName: PCEditorDidResignKeyNotification
                  object: self];

  editorIsActive = NO;

  if (!projectDebugger)
    {
      projectDebugger = [[PCProjectDebugger alloc] initWithProject:self];
    }

  view = [[projectDebugger componentView] retain];

  if (separate)
    {
      NSPanel *panel = [projectDebugger createLaunchPanel];
      NSRect  frame = [NSPanel contentRectForFrameRect: [panel frame]
                                             styleMask: [panel styleMask]];

      frame.origin.x = 8;
      frame.origin.y = -2;
      frame.size.height += 2;
      frame.size.width -= 16;
      [view setFrame: frame];
     
      if ([box contentView] == view)
	{
	  [self showEditorView: self];
	}
      [[panel contentView] addSubview: view];
      [panel orderFront: nil];
    }
  else
    {
      NSPanel *panel = [projectDebugger launchPanel];

      if (panel)
	{
	  [panel close];
	}
      [box setContentView: view];
      [box display];
    }
  [projectDebugger setTooltips];
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

