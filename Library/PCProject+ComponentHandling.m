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

/*- (void)showBuildView:(id)sender
{
  BOOL    separate = NO;
  NSView  *view = nil;
  NSPanel *buildPanel = nil;
  
  if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
              objectForKey: SeparateBuilder] isEqualToString: @"YES"])
    {
      separate = YES;
    }

  view = [[self projectBuilder] componentView];
  buildPanel = [projectManager buildPanel];

  if (separate)
    {
      if ([projectWindow customContentView] == view)
	{
	  [self showEditorView:self];
	}
      [buildPanel orderFront: nil];
    }
  else
    {
      if (buildPanel)
	{
	  [buildPanel close];
	}
      [projectWindow setCustomContentView:view];
    }
  [projectBuilder setTooltips];
}*/

/*- (void)showRunView:(id)sender
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
      projectDebugger = [[PCProjectLauncher alloc] initWithProject:self];
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
     
      if ([projectWindow customContentView] == view)
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
      [projectWindow setCustomContentView: view];
    }
  [projectDebugger setTooltips];
}*/

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

- (void)showInspector:(id)sender
{
  [self createInspectors];
  [[[projectManager projectInspector] panel] makeKeyAndOrderFront:self];
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

