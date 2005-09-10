/*
   GNUstep ProjectCenter - http://www.gnustep.org/experience/ProjectCenter.html

   Copyright (C) 2000-2004 Free Software Foundation

   Authors: Philippe C.D. Robert
            Serg Stoyan

   This file is part of GNUstep.

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include "PCDefines.h"
#include "PCSplitView.h"
#include "PCButton.h"

#include "PCProjectManager.h"
#include "PCProject.h"

#include "PCProjectWindow.h"
#include "PCProjectBrowser.h"
#include "PCProjectEditor.h"
#include "PCProjectBuilder.h"
#include "PCProjectLauncher.h"
#include "PCProjectLoadedFiles.h"
#include "PCProjectInspector.h"

#include "PCPrefController.h"
#include "PCLogController.h"

@implementation PCProjectWindow

// ============================================================================
// ==== Intialization & deallocation
// ============================================================================

- (void)_createCustomView
{
  customView = [[NSBox alloc] initWithFrame:NSMakeRect(-1,-1,562,252)];
  [customView setTitlePosition:NSNoTitle];
  [customView setBorderType:NSNoBorder];
  [customView setContentViewMargins:NSMakeSize(0.0,0.0)];
  [customView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];

  // Editor in the Box
  [customView setContentView:[[project projectEditor] componentView]];

  [h_split addSubview:customView];
  RELEASE(customView);
  [h_split adjustSubviews];
}

- (void)_initUI
{
  NSRect rect;
  NSView *browserView = nil;

  if (projectWindow != nil)
    {
      return;
    }

  if ([NSBundle loadNibNamed:@"ProjectWindow" owner:self] == NO)
    {
      PCLogError(self, @"error loading ProjectWindow NIB file!");
      return;
    }

  [buildButton setToolTip:@"Build"];
//  [buildButton setImage:IMAGE(@"Build")];

  [launchButton setToolTip:@"Launch/Debug"];
//  [launchButton setImage:IMAGE(@"Run")];
  if (![project isExecutable])
    {
      [launchButton setEnabled:NO];
    }

  [loadedFilesButton setToolTip:@"Loaded Files"];
//  [loadedFilesButton setImage:IMAGE(@"Files")];
  if ([self hasLoadedFilesView])
    {
      [loadedFilesButton setEnabled:NO];
    }

  [findButton setToolTip:@"Find"];
//  [findButton setImage:IMAGE(@"Find")];

  [inspectorButton setToolTip:@"Inspector"];
//  [inspectorButton setImage:IMAGE(@"Inspector")];

  [fileIcon setFileNameField:fileIconTitle];

  [statusLine setStringValue:@""];
    
  /*
   * Hosrizontal split view
   */
  rect = [[projectWindow contentView] frame];
  rect.size.height -= 62;
  rect.size.width -= 16;
  rect.origin.x += 8;
  rect.origin.y = -2;
  [h_split setDelegate:self];

  /*
   * Vertical split view
   */
  rect = [[projectWindow contentView] frame];
  if (h_split)
    {
      rect.size.height = 130;
    }
  v_split = [[PCSplitView alloc] initWithFrame:rect];
  [v_split setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [v_split setVertical:YES];

  /*
   * File Browser
   */
  browserView = [[project projectBrowser] view];
  [v_split addSubview:browserView];
  
  /*
   * LoadedFiles
   */
  if ([self hasLoadedFilesView])
    {
      [self showProjectLoadedFiles:self];
    }

  [h_split addSubview:v_split];
  RELEASE(v_split);

  /*
   * Custom view
   * View where non-separated Builder, Launcher, Editor goes.
   */ 
  if ([self hasCustomView])
    {
      [self _createCustomView];
    }
}

- (id)initWithProject:(PCProject *)owner 
{
  if ((self = [super init]))
    {
      NSDictionary *pcWindows;
      NSString     *windowFrame;

      project = owner;
      _isToolbarVisible = YES;
      _splitViewsRestored = NO;

      [self _initUI];
      [self setTitle];
      
      // Window
      [projectWindow setFrameAutosaveName: @"ProjectWindow"];

      pcWindows = [[project projectDict] objectForKey:@"PC_WINDOWS"];
      windowFrame = [pcWindows objectForKey:@"ProjectWindow"];
//      PCLogInfo(self, @"window frame %@", windowFrame);
      if (windowFrame != nil)
	{
	  PCLogStatus(self, @"PCProjectWindow: set frame from project");
	  [projectWindow setFrameFromString:windowFrame];
	}
      else if (![projectWindow setFrameUsingName: @"ProjectWindow"])
	{
	  [projectWindow center];
	}
	
      // Toolbar
      if ([[pcWindows objectForKey:@"ShowToolbar"] isEqualToString:@"NO"])
	{
	  [self toggleToolbar];
	}

      // Project dictionary
      [[NSNotificationCenter defaultCenter] 
	addObserver:self
	   selector:@selector(projectDictDidChange:)
	       name:PCProjectDictDidChangeNotification
	     object:nil];

      [[NSNotificationCenter defaultCenter] 
	addObserver:self
	   selector:@selector(projectDictDidSave:)
	       name:PCProjectDictDidSaveNotification
	     object:nil];

      // Active project changing
      [[NSNotificationCenter defaultCenter] 
	addObserver:self
	   selector:@selector(activeProjectDidChange:)
	       name:PCActiveProjectDidChangeNotification
	     object:nil];
	     
      // ProjectCenter preferences
      [[NSNotificationCenter defaultCenter] 
	addObserver:self
	   selector:@selector(preferencesDidChange:)
	       name:PCPreferencesDidChangeNotification
	     object:nil];
    }
  
  return self;
}

- (void)setTitle
{
  [projectWindow setTitle: [NSString stringWithFormat: @"%@ - %@", 
  [project projectName],
  [[project projectPath] stringByAbbreviatingWithTildeInPath]]];
}

- (void)dealloc
{
#ifdef DEVELOPMENT
  NSLog (@"PCProjectWindow: dealloc");
#endif

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}

// ============================================================================
// ==== Accessory methods
// ============================================================================

- (BOOL)hasCustomView
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  _hasCustomView = NO;
  
  if (![[ud objectForKey:SeparateEditor] isEqualToString:@"YES"]
      && [[ud objectForKey:Editor] isEqualToString:@"ProjectCenter"])
    {
      _hasCustomView = YES;
    }
  if (![[ud objectForKey:SeparateBuilder] isEqualToString:@"YES"])
    {
      _hasCustomView = YES;
    }
  if (![[ud objectForKey:SeparateLauncher] isEqualToString:@"YES"])
    {
      _hasCustomView = YES;
    }

  return _hasCustomView;
}

- (BOOL)hasLoadedFilesView
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  if (![[ud objectForKey:SeparateLoadedFiles] isEqualToString:@"YES"])
    {
      _hasLoadedFilesView = YES;
    }
  else
    {
      _hasLoadedFilesView = NO;
    }

  return _hasLoadedFilesView;
}

- (NSView *)customContentView
{
  return [customView contentView];
}

- (void)setCustomContentView:(NSView *)subview
{
  if (!customView)
    {
      return;
    }

  [customView setContentView:subview];
  [customView display];
}

- (void)setStatusLineText:(NSString *)text
{
  [statusLine setStringValue:text];
}

// ============================================================================
// ==== Actions
// ============================================================================

- (void)showProjectBuild:(id)sender
{
  NSView  *view = [[project projectBuilder] componentView];
  NSPanel *buildPanel = [[project projectManager] buildPanel];
  
  if ([[[PCPrefController sharedPCPreferences] objectForKey:SeparateBuilder]
      isEqualToString: @"YES"])
    {
      if ([customView contentView] == view)
	{
	  [self showProjectEditor:self];
	}
      [buildPanel orderFront:nil];
    }
  else
    {
      if ([buildPanel isVisible])
	{
	  [buildPanel close];
	}
      [self setCustomContentView:view];
    }
}

- (void)showProjectLaunch:(id)sender
{
  NSView  *view = nil;
  NSPanel *launchPanel = nil;

  view = [[project projectLauncher] componentView];
  launchPanel = [[project projectManager] launchPanel];

  if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
           objectForKey: SeparateLauncher] isEqualToString: @"YES"])
    {
      if ([customView contentView] == view)
	{
	  [self showProjectEditor:self];
	}
      [launchPanel orderFront: nil];
    }
  else
    {
      if ([launchPanel isVisible])
	{
	  [launchPanel close];
	}
      [self setCustomContentView:view];
    }
}

- (void)showProjectLoadedFiles:(id)sender
{
  NSPanel       *panel = [[project projectManager] loadedFilesPanel];
  NSScrollView  *componentView = [[project projectLoadedFiles] componentView];
      
//  PCLogInfo(self, @"showProjectLoadedFiles");

  if ([self hasLoadedFilesView])
    {
      if (panel && [panel isVisible])
	{
	  [panel close];
	}

      [componentView setBorderType:NSBezelBorder];
      [componentView setFrame:NSMakeRect(0,0,128,130)];
      [v_split addSubview:[[project projectLoadedFiles] componentView]];
      [v_split adjustSubviews];
    }
  else
    {
      [componentView setBorderType:NSNoBorder];
      [panel orderFront:nil];
      [v_split adjustSubviews];
    }
}

- (void)showProjectInspector:(id)sender
{
  [[project projectManager] showProjectInspector:sender];
}

- (void)showProjectEditor:(id)sender
{
  [self setCustomContentView:[[project projectEditor] componentView]];
  [self makeFirstResponder:firstResponder];
}

- (BOOL)isToolbarVisible
{
  return _isToolbarVisible;
}

- (void)toggleToolbar
{
  NSRect rect;
  NSView *cView = [projectWindow contentView];

  if (_isToolbarVisible)
    {
      RETAIN(toolbarView);
      [toolbarView removeFromSuperview];
      if (h_split)
	{
	  rect = [h_split frame];
	  rect.size.height += 48;

	  // Hack. NSBrowser resizes incorrectly without removing/adding
	  // from/to superview
	  RETAIN(h_split);
	  [h_split removeFromSuperview];
	  [h_split setFrame:rect];
	  [cView addSubview:h_split];
	  RELEASE(h_split);
	}
      else if (v_split)
	{
	  rect = [v_split frame];
	  rect.size.height += 48;

	  // Hack. See above
	  RETAIN(v_split);
	  [v_split removeFromSuperview];
	  [v_split setFrame:rect];
	  [cView addSubview:v_split];
	  RELEASE(v_split);
	}
      _isToolbarVisible = NO;
    }
  else
    {
      rect = [cView frame];
      rect.origin.x = 8;
      rect.origin.y = rect.size.height - 57;
      rect.size.width -= 16;
      rect.size.height = 48;
      [toolbarView setFrame:rect];

      [cView addSubview:toolbarView];
      RELEASE(toolbarView);
      if (h_split)
	{
	  rect = [h_split frame];
	  rect.size.height -= 48;

	  // Hack. See above
	  RETAIN(h_split);
	  [h_split removeFromSuperview];
	  [h_split setFrame:rect];
	  [cView addSubview:h_split];
	  RELEASE(h_split);
	}
      else if (v_split)
	{
	  rect = [v_split frame];
	  rect.size.height -= 48;

	  // Hack. See above
	  RETAIN(v_split);
	  [v_split removeFromSuperview];
	  [v_split setFrame:rect];
	  [cView addSubview:v_split];
	  RELEASE(v_split);
	}
      _isToolbarVisible = YES;
    }
}

// ============================================================================
// ==== Notifications
// ============================================================================

- (void)projectDictDidChange:(NSNotification *)aNotif
{
  NSDictionary *notifObject = [aNotif object];
  PCProject    *changedProject = [notifObject objectForKey:@"Project"];

  if (changedProject != project 
      && changedProject != [project activeSubproject])
    {
      return;
    }
    
  [self setTitle];

  // TODO: if window isn't visible and "edited" attribute set, after ordering
  // front window doesn't show broken close button. Fix it in GNUstep.
  // Workaround is in windowDidBecomeKey.
  [projectWindow setDocumentEdited:YES];
}

- (void)projectDictDidSave:(NSNotification *)aNotif
{
  PCProject *savedProject = [aNotif object];
  
  if (savedProject != project 
      && savedProject != [project activeSubproject]
      && [savedProject superProject] != [project activeSubproject])
    {
      return;
    }

  [projectWindow setDocumentEdited:NO];
}

- (void)activeProjectDidChange:(NSNotification *)aNotif 
{
/*  PCProject *activeProject = [aNotif object];
  
  if (activeProject != project 
      && activeProject != [project activeSubproject]
      && [activeProject superProject] != [project activeSubproject])
    {
      return;
    }

  [self makeKeyWindow];*/
}

- (void)preferencesDidChange:(NSNotification *)aNotif
{
  NSDictionary *prefsDict = [[aNotif object] preferencesDict];
 
  PCLogStatus(self, @"Preferences did change");
 
  //--- Add Custom view
  if ([self hasCustomView] && customView == nil)
    {
      [self _createCustomView];
    }

  // Project Builder
  if ([[prefsDict objectForKey:@"SeparateBuilder"] isEqualToString:@"YES"])
    {
      if ([[[project projectBuilder] componentView] superview])
	{
	  [self showProjectBuild:self];
	}
    }
  else
    {
      NSPanel *buildPanel = [[project projectManager] buildPanel];
      
      if ([buildPanel isVisible] == YES)
	{
	  [self showProjectBuild:self];
	}
    }

  // Project Launcher
  if ([[prefsDict objectForKey:@"SeparateLauncher"] isEqualToString:@"YES"])
    {
      if ([[[project projectLauncher] componentView] superview])
	{
	  [self showProjectLaunch:self];
	}
    }
  else
    {
      NSPanel *launchPanel = [[project projectManager] launchPanel];
      
      if ([launchPanel isVisible] == YES)
	{
	  [self showProjectLaunch:self];
	}
    }

  //--- Remove Custom view
  if (![self hasCustomView] && customView != nil)
    {
      [customView removeFromSuperview];
      [h_split adjustSubviews];
      customView = nil;
    }

  // Loaded Files view
  if ([self hasLoadedFilesView])
    {
      if ([[v_split subviews] count] == 1)
	{
	  [self showProjectLoadedFiles:self];
	}
      [loadedFilesButton setEnabled:NO];
    }
  else 
    {
      if ([[v_split subviews] count] == 2)
	{
	  [self showProjectLoadedFiles:self];
	}
      [loadedFilesButton setEnabled:YES];
    }
}

// ============================================================================
// ==== Window delegate
// ============================================================================

- (NSString *)stringWithSavedFrame
{
  return [projectWindow stringWithSavedFrame];
}

- (void)makeKeyAndOrderFront:(id)sender
{
//  PCLogInfo(self, @"makeKeyAndOrderFront sender: %@", [sender className]);
  [projectWindow makeKeyAndOrderFront:nil];
}

- (void)makeKeyWindow
{
  [projectWindow makeKeyWindow];
}

- (void)orderFront:(id)sender
{
  if (projectWindow)
    {
      [projectWindow orderFront:sender];
    }
}

- (void)center
{
  [projectWindow center];
}

// [NSWindow close] doesn't send windowShouldClose
- (void)close
{
  [projectWindow close];
}

- (void)performClose:(id)sender
{
  [projectWindow performClose:sender];
}

- (BOOL)isDocumentEdited 
{
  return [projectWindow isDocumentEdited];
}

- (BOOL)isKeyWindow
{
  return [projectWindow isKeyWindow];
}

- (BOOL)makeFirstResponder:(NSResponder *)aResponder
{
  firstResponder = aResponder;
  [projectWindow makeFirstResponder:firstResponder];

  return YES;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
  [projectWindow makeMainWindow];
//  [projectWindow makeFirstResponder:(NSResponder *)firstResponder];

/*  PCLogInfo(self, @"windowDidBecomeKey: activeSubproject %@",
	    [[project activeSubproject] projectName]);*/

  if ([[project projectManager] rootActiveProject] != project)
    {
      if ([project activeSubproject] != nil)
	{
	  [[project projectManager] 
	    setActiveProject:[project activeSubproject]];
	}
      else
	{
	  [[project projectManager] setActiveProject:project];
	}
    }


  // Workaround
  if ([projectWindow isDocumentEdited])
    {
      [projectWindow setDocumentEdited:NO];
      [projectWindow setDocumentEdited:YES];
    }
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
//  [projectWindow makeFirstResponder:nil];
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
}

- (BOOL)windowShouldClose:(id)sender
{
  return [project close:self];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
}

// ============================================================================
// ==== SplitView delegate
// ============================================================================

- (void)         splitView:(NSSplitView *)sender
 resizeSubviewsWithOldSize:(NSSize)oldSize
{
  NSDictionary *projectDict = [project projectDict];
  NSDictionary *windowsDict = [projectDict objectForKey:@"PC_WINDOWS"];
  NSSize       hSplitSize = [sender frame].size;
  NSRect       browserRect;
  NSRect       vSplitRect;
  NSRect       boxRect;

  // Use saved frame of ProjectBrowser only first time. Every time window is
  // resized use new size of subviews.
  if (_splitViewsRestored)
    {
      browserRect = [[[project projectBrowser] view] frame];
    }
  else
    {
      browserRect = 
	NSRectFromString([windowsDict objectForKey:@"ProjectBrowser"]);
    }

  // v_split resize
  vSplitRect = browserRect;
  if (vSplitRect.size.height > 0)
    {
      vSplitRect.size.width = hSplitSize.width;
    }
  else
    {
      vSplitRect.size.width = hSplitSize.width;
      vSplitRect.size.height = 100;
      vSplitRect.origin.x = 0;
      vSplitRect.origin.y = 0;
    }
  NSLog(@"v_split %@", NSStringFromRect(vSplitRect));
  [v_split setFrame:vSplitRect];

  // v_split subviews resize
  if ([self hasLoadedFilesView])
    {
      // browser
      NSLog(@"browser %@", NSStringFromRect(browserRect));
      [[[project projectBrowser] view] setFrame:browserRect];

      // loaded files
      boxRect.origin.x = browserRect.size.width + [v_split dividerThickness];
      boxRect.origin.y = 0;
      boxRect.size.width = [v_split frame].size.width - boxRect.origin.x;
      boxRect.size.height = [v_split frame].size.height;
      NSLog(@"loadedFiles %@", NSStringFromRect(boxRect));
      [[[project projectLoadedFiles] componentView] setFrame:boxRect];
    }

  // editor
  boxRect.origin.x = 0;
  boxRect.origin.y = browserRect.size.height + [sender dividerThickness];
  boxRect.size.width = hSplitSize.width;
  boxRect.size.height = hSplitSize.height - boxRect.origin.y;
  [customView setFrame:boxRect];

  _splitViewsRestored = YES;
}

@end

